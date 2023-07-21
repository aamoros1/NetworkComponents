//
// NetworkRequestKind.swift
//
//
//

import Foundation

open class NetworkRequestKind: NSObject {
    public let path: String
    public let method: String
    public let mimeType: String?
    public let responseMimeType: String?
    public let responseType: Any.Type?
    public let timeout: TimeInterval?
    
    public required init(
        path: String,
        method: String,
        mimeType: String,
        responseMimeType: String? = nil,
        responseType: Any.Type? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.mimeType = mimeType
        self.responseMimeType = responseMimeType
        self.responseType = responseType
        self.timeout = timeout
        
        super.init()
    }
    
    public convenience init(
        xmlPath: String,
        responseType: Any.Type,
        timeout: TimeInterval
    ) {
        self.init(
            path: xmlPath,
            method: HttpMethod.post,
            mimeType: MimeType.applicationFormUrlEncoded,
            responseMimeType: MimeType.textXml,
            responseType: responseType,
            timeout: timeout
        )
    }
    
    public convenience init(
        xmlPath: String,
        responseType: Any.Type
    ) {
        self.init(path: xmlPath,
                  method: HttpMethod.post,
                  mimeType: MimeType.applicationFormUrlEncoded,
                  responseMimeType: MimeType.textXml,
                  responseType: responseType)
    }
    
    public convenience init(
        jsonPath: String,
        responseType: Any.Type
    ) {
        self.init(path: jsonPath, method: HttpMethod.post, mimeType: MimeType.applicationFormUrlEncoded, responseMimeType: MimeType.textJson, responseType: responseType)
    }
    
    public convenience init(
        appJsonPath: String,
        method: String = HttpMethod.post,
        responseType: Any.Type
    ) {
        self.init(path: appJsonPath,
                  method: method,
                  mimeType: MimeType.applicationJson,
                  responseMimeType: MimeType.applicationJson,
                  responseType: responseType)
    }
    
    public convenience init(
        soapPath: String,
        responseType: Any.Type,
        responseMimeType: String = MimeType.textXml
    ) {
        self.init(path: soapPath,
                  method: HttpMethod.post,
                  mimeType: MimeType.applicationFormUrlEncoded,
                  responseMimeType: responseMimeType,
                  responseType: responseType)
        
    }
    
    open func buildUrl() throws -> URL {
        fatalError("need to implement \(#function)")
    }
    
    /**
     Creates a network request with the given content
     - parameter content: key-value pairs to be used as query parameters for a GET request. This value
     is ignored if `method` is NOT `GET`. Default is `nil`
     */
    final public func buildNetworkRequest(content: [String: String]? = nil) throws -> NetworkRequest {
        let networkRequest = NetworkRequest(url: try buildUrl(), method: self.method)
        if method == HttpMethod.get {
            networkRequest.queryParams = content
        }
        
        networkRequest.mimeType = self.mimeType
        networkRequest.responseMimeType = self.responseMimeType
        networkRequest.responseType = self.responseType
        
        if let timeout = timeout {
            networkRequest.timeout = timeout
        }
        
        return networkRequest
    }
}
