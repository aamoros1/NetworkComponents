//
//  NetworkRequest.swift
//  
//
//
//

import Foundation

public class NetworkRequest: NSObject {
    let url: URL
    let method: String
    public var headers: [String: String] = [:]
    public var encoding: Encoding = .utf8
    public var cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
    public var timeout: TimeInterval = 0
    
    public var mimeType: String?
    public var queryParams: [String: String]?
    public var responeType: Any.Type?
    public var responseMimeType: String?

    public required init(url: URL, method: String) {
        self.url = url
        self.method = method
        
        super.init()
    }

    open func buildURLRequest(headers: [String: String]) -> URLRequest {
        var urlRequest = URLRequest(url: url.appendingQueryParams(queryParams), cachePolicy: cachePolicy)

        urlRequest.httpMethod = method
        
        if timeout > 0 {
            urlRequest.timeoutInterval = self.timeout
        }

        headers.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        self.headers.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }

        if let mimeType = self.mimeType {
            let mimeFormat = MimeType.format(mimeType, with: HttpUtil.lookupCharset(for: encoding))
            urlRequest.addValue(mimeFormat, forHTTPHeaderField: HttpHeader.contentType)
        }
        print(urlRequest.url)
        return urlRequest
    }
}

