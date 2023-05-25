//
//  HttpHeader.swift
//  
//
//
//

import Foundation

/**
 Definition of common HTTP header keys
 */
@objc
public class HttpHeader: NSObject {
    @objc public static let userAgent = "User-Agent"
    @objc public static let accept = "Accept"
    @objc public static let acceptCharset = "Accept-Charset"
    @objc public static let acceptEncoding = "Accept-Encoding"
    @objc public static let authorization = "Authorization"
    @objc public static let contentType = "Content-Type"
    @objc public static let contentLength = "Content-Length"
    @objc public static let cookie = "Cookie"
}
