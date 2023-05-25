//
//  MimeType.swift
//
//  
//
//


import Foundation

/**
 Definition of common MIME Types
 */
@objc
public class MimeType: NSObject {
    @objc public static let applicationJson = "application/json"
    @objc public static let applicationXml = "application/xml"
    @objc public static let applicationFormUrlEncoded = "application/x-www-form-urlencoded"

    @objc public static let textHtml = "text/html"
    @objc public static let textPlain = "text/plain"
    @objc public static let textXml = "text/xml"
    @objc public static let textJson = "text/json"

    @objc
    public static func format(_ mimeType: String, with charset: String?) -> String {
        guard let charset = charset, !charset.isEmpty else {
            return mimeType
        }
        return "\(mimeType); charset=\(charset)"
    }

    @objc
    public static func isJson(_ mimeType: String?) -> Bool {
        return mimeType?.contains("/json") == true
    }

    @objc
    public static func isXml(_ mimeType: String?) -> Bool {
        return mimeType?.contains("/xml") == true
    }

    @objc
    public static func isPlain( _ mimeType: String?) -> Bool {
        return mimeType?.contains("/plain") == true
    }
}
