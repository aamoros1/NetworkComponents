//
//  BaseNetworkServiceProvider.swift
//  
//
//
//

import OSLog
import Combine
import Foundation

enum BaseNetworkServiceError: Error {
    case failedToSerializeContentData(eror: String, contentBody: Any)
}

typealias SessionDataHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

open class BaseNetworkServiceProvider: NSObject {
    private lazy var logger = Logger(subsystem: "io.\(String(describing: self))", category: String(describing: self))
    private static let defaultRetryAttemps: UInt = 1

    /// URLSessionConfiguration assigned during initialization
    private var urlSessionConfiguration: URLSessionConfiguration

    /// Synchronization queue for thread safety
    public private(set) lazy var syncQueue: DispatchQueue = DispatchQueue(
        label: "\(type(of: self))#\(hashValue).syncQueue",
        qos: .background)

    /// Callback queue used for dispatching completed network responses to free up the session operation queue.
    /// This is a serial queue so that clients receive responses in the order that they are requested.
    public private(set) lazy var callbackQueue: DispatchQueue = DispatchQueue(
        label: "\(type(of: self))#\(hashValue).callbackQueue",
        qos: .background)

    /// OperationQueue used for processing requests. This operation queue uses it's own managed dispatch queue,
    /// and is not concurrent so that requests are processed in the order received.
    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "\(type(of: self))#\(hashValue).operationQueue"
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    private lazy var urlSession: URLSession = {
        URLSession(
            configuration: urlSessionConfiguration,
            delegate: SessionDataDelegate(provider: self),
            delegateQueue: operationQueue)
    }()

    private var _interceptor: NetworkServiceInterceptor?
    private var _maxRetryAttemps: UInt = defaultRetryAttemps
    private var _headers: [String: String] = [:]

    public required init(config: URLSessionConfiguration) {
        urlSessionConfiguration = config
        super.init()
    }

    private func convertContentData(
        _ content: Any?,
        mimeType: String?,
        encoding: Encoding)
    throws -> Data?
    {
        func convert() throws -> Data? {
            var data: Data?
            
            if let jsonModel = content as? JsonModel {
                if let jsonString = jsonModel.toJsonString(encoding: encoding) {
                    data = jsonString.data(using: encoding)
                }
            } else if let contentString = content as? String {
                data = contentString.data(using: encoding)
            } else if let postParams = content as? [AnyHashable: Any] {
                if MimeType.isJson(mimeType) {
                    do {
                        data = try JSONSerialization.data(withJSONObject: postParams)
                    } catch let error {
                        throw BaseNetworkServiceError.failedToSerializeContentData(
                            eror: error.localizedDescription,
                            contentBody: postParams)
                    }

                } else {
                    let httpBodyString = HttpUtil.buildHttpBodyString(params: postParams)
                    data = httpBodyString.data(using: encoding)
                }
            }
            return data
        }
        guard let data = content as? Data else {
            return try convert()
        }
        return data
    }

    private func parseContentData(
        _ data: Data?,
        contentType: Any.Type?,
        mimeType: String?,
        encoding: Encoding)
    throws -> Any?
    {
        guard let data = data else {
            return nil
        }

        var content: Any? = data

        switch contentType {
        case is NSString.Type, is String.Type:
            content = String(data: data, encoding: encoding)
        case is NSDictionary.Type, is DomainModel.Type:
            var dictionary: NSDictionary?

            if MimeType.isJson(mimeType) {
                dictionary = try JsonModel.parseJsonData(data)
            } else if MimeType.isXml(mimeType) {
                //                let xmlParser = XmlParser()
            }

            if let domainModelType = contentType as? DomainModel.Type {
                content = domainModelType.init(with: dictionary)
            } else {
                content = dictionary
            }

        case let decodableType as Decodable.Type:
            if MimeType.isJson(mimeType) {
                content = try JSONDecoder().decode(decodableType, from: data)
            }
        default:
            content = nil
        }
        return content
    }

    private class SessionDataDelegate: NSObject, URLSessionDataDelegate {

        private weak var provider: NetworkServiceProvider?

        private var interceptor: NetworkServiceInterceptor? {
            provider?.interceptor
        }
        required init(provider: NetworkServiceProvider) {
            self.provider = provider
        }

        public func urlSession(_ session: URLSession,
                               didReceive challenge: URLAuthenticationChallenge,
                               completionHandler: @escaping SessionDataHandler)
        {
            let keyPinned = interceptor?.validatePinning(challenge: challenge) ?? true
            guard keyPinned else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }

            var urlCredential: URLCredential?
            var disposition = URLSession.AuthChallengeDisposition.performDefaultHandling

            if let credential = interceptor?.inspect(challenge: challenge) {
                urlCredential = credential
                disposition = .useCredential
            }

            completionHandler(disposition, urlCredential)
        }
    }
    
    private class SessionTaskToken: AsyncToken, URLSessionTaskDelegate  {
        private var task: URLSessionTask!

        required init(_ task: URLSessionTask) {
            self.task = task
            super.init()
        }

        required override init() {
            super.init()
        }

        override func cancel() {
            self.task.cancel()
            super.cancel()
        }

        func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
            self.task = task
        }
    }
}

extension BaseNetworkServiceProvider: Synchronizable {
    /// Uses syncQueue to support synchronization
}

extension BaseNetworkServiceProvider: NetworkServiceProvider {
    public var interceptor: NetworkServiceInterceptor? {
        get {
            synchronized { _interceptor }
        }
        set {
            synchronized { self._interceptor = newValue }
        }
    }

    public var headers: [String : String] {
        get {
            synchronized { _headers}
        }
        set {
            synchronized { self._headers = newValue}
        }
    }

    public func start() {
        operationQueue.isSuspended = false
    }

    public func stop() {
        operationQueue.isSuspended = true
    }

    public func shutdown() {
        stop()
        urlSession.invalidateAndCancel()
    }

    public func process(
        _ request: NetworkRequest,
        content: Any?,
        completionHandler: NetworkResponseHandler?)
    throws -> AsyncToken
    {
        //  TODO:
        .init()
    }

    private func buildURLRequest(_ request: NetworkRequest, _ content: Any?) -> URLRequest {
        var urlRequest = request.buildURLRequest(headers: headers)
        
        if let contentData = try? convertContentData(content, mimeType: request.mimeType, encoding: request.encoding) {
            urlRequest.addValue("\(contentData.count)", forHTTPHeaderField: HttpHeader.contentLength)
            urlRequest.httpBody = contentData
        } else {
            urlRequest.addValue("0", forHTTPHeaderField: HttpHeader.contentLength)
        }
        
        urlRequest.httpShouldHandleCookies = urlSessionConfiguration.httpShouldSetCookies
        
        if urlRequest.cachePolicy == .useProtocolCachePolicy {
            urlRequest.cachePolicy = urlSessionConfiguration.requestCachePolicy
        }
        
        if let securityHeaders = interceptor?.securityHeaders(for: request, containing: urlRequest.httpBody) {
            securityHeaders.forEach { urlRequest.addValue($1, forHTTPHeaderField: $0) }
        }
        return urlRequest
    }

    public func process(
        _ request: NetworkRequest,
        content: Any?)
    async throws -> AsyncToken
    {
        let asyncToken = SessionTaskToken()
        /// Allow for optional preprocessing
        let interceptor = self.interceptor
        interceptor?.inspect(request: request)
        
        Task(priority: .background) {
            let urlRequest = buildURLRequest(request, content)

            do {
                logger.debug("urlRequest: \(urlRequest)")
                let response: (data: Data, urlResponse: URLResponse) = try await urlSession.data(for: urlRequest, delegate: asyncToken)
                var urlResponse: URLResponse?
                urlResponse = response.urlResponse
                let data =  response.data
                let mimeType = request.responseMimeType ?? urlResponse?.mimeType ?? request.headers[HttpHeader.accept] ?? request.mimeType
                let encoding = HttpUtil.lookupEncoding(for: urlResponse?.textEncodingName) ?? request.encoding
                let aContent = try parseContentData(
                    data,
                    contentType: request.responeType,
                    mimeType: mimeType,
                    encoding: encoding)
                let networkResponse = NetworkResponse(
                    for: request,
                    with: urlResponse,
                    content: aContent,
                    mimeType: mimeType,
                    timeStamp: .init(),
                    error: nil)
                self.callbackQueue.async { [weak self] in
                    self?.didCompleteRequest(asyncToken, request: request, response: networkResponse)
                }
            } catch let error {
                let mimeType = request.responseMimeType ?? request.headers[HttpHeader.accept] ?? request.mimeType
                let networkResponse = NetworkResponse(
                    for: request,
                    with: nil,
                    content: content,
                    mimeType: mimeType,
                    timeStamp: .init(),
                    error: error)
                self.callbackQueue.async { [weak self] in
                    self?.didCompleteRequest(asyncToken, request: request, response: networkResponse)
                }
            }
        }
        return asyncToken
    }

    private func didCompleteRequest(
        _ requestToken: SessionTaskToken,
        request: NetworkRequest,
        response: NetworkResponse)
    {
        defer {
            requestToken.complete(with: response)
        }
        interceptor?.inspect(response: response, for: request)
    }
}
