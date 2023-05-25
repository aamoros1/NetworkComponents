//
//  NetworkResponse.swift
//  
//
//
//

import Foundation

/// Network response protocol
open class NetworkResponse: NSObject {
    public let url: URL
    public let method: String
    
    public var statusCode: Int = 0
    public var headers: [String: String]?
    public var mimeType: String?
    public var duration: TimeInterval = 0
    public var error: Error?
    public var content: Any?
    
    public required init(url: URL, method: String) {
        self.url = url
        self.method = method
        
        super.init()
    }
    
    public convenience init(
        for request: NetworkRequest,
        with urlResponse: URLResponse?,
        content: Any?,
        mimeType: String?,
        timeStamp: Date?,
        error: Error?)
    {
        self.init(url: request.url, method: request.method)
        
        self.mimeType = mimeType
        self.content = content
        self.error = error
        
        if let httpUrlResponse = urlResponse as? HTTPURLResponse {
            var headers = [String: String]()
            
            for (key, value) in httpUrlResponse.allHeaderFields {
                if let key = key as? String,
                   let value = value as? String {
                    headers[key] = value
                }
            }
            self.headers = headers
            statusCode = httpUrlResponse.statusCode
        }
        
        if let timeStamp = timeStamp {
            duration = Date().timeIntervalSince(timeStamp)
        }
    }
}
