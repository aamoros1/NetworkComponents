//
//  HttpMethod.swift
//  
//
//
//

import Foundation

/**
 Definition of common HTTP methods
 */
@objc
public class HttpMethod: NSObject {
    @objc public static let get = "GET"
    @objc public static let post = "POST"
    @objc public static let put = "PUT"
    @objc public static let delete = "DELETE"
    @objc public static let head = "HEAD"
    @objc public static let options = "OPTIONS"
    @objc public static let trace = "TRACE"
    @objc public static let patch = "PATCH"
}
