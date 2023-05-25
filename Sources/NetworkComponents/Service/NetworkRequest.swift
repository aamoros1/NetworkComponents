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
    var headers: [String: String] = [:]
    public var encoding: String.Encoding = .utf8
    public var cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
    public var timeout: TimeInterval = 0
    
    public var mimeType: String?
    public var queryParams: [String: String]?
    public var responeType: AnyObject.Type?
    public var responseMimeType: String?

    public required init(url: URL, method: String) {
        self.url = url
        self.method = method
        
        super.init()
    }

    func buildURLRequest(headers: [String: String]) -> URLRequest {
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
        
        return urlRequest
    }
}

