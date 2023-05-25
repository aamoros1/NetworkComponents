//
//  HttpUtil.swift
//
//
//  
//

import Foundation

/**
 Definition of common HTTP utilities
 */

public typealias Encoding = String.Encoding

@objc
public class HttpUtil: NSObject {
    private static let charsetToStringEncodingMap: [String: Encoding] =
    ["ascii": .ascii,
     "utf-8": .utf8,
     "utf-16": .utf16,
     "utf-32": .utf32,
     "unicode": .unicode]

    private static let queryAllowedCharacterSet: CharacterSet = {
        var urlQueryCharacterSet = CharacterSet.urlQueryAllowed

        // IP-7426: Remove special characters that can affect parsing of the query string
        urlQueryCharacterSet.remove(charactersIn: "&=?:;/!@$()*+,'~")

        return urlQueryCharacterSet
    }()

    public static func lookupEncoding(for charset: String?) -> Encoding? {
        guard let charset = charset else {
            return nil
        }
        return charsetToStringEncodingMap[charset.lowercased()]
    }

    public static func lookupCharset(for encoding: Encoding?) -> String? {
        guard let encoding = encoding, let kvp = charsetToStringEncodingMap
            .first(where: {(_, enc) in enc == encoding}) else {
                return nil
        }
        return kvp.key
    }

    @objc
    public static func percentEncodeQueryPart(_ str: String?) -> String? {
        return str?.addingPercentEncoding(withAllowedCharacters: HttpUtil.queryAllowedCharacterSet)
    }

    public static func buildQueryString(_ queryParams: [String: String]?) -> String? {
        guard let queryParamsString = buildQueryParamsString(queryParams) else {
            return nil
        }
        return "?" + queryParamsString
    }

    public static func buildQueryParamsString(_ queryParams: [String: String]?) -> String? {
        var queryItems: [String] = []

        queryParams?.forEach {(name, value) in
            if let encodedKey = percentEncodeQueryPart(name) {
                let encodedValue = percentEncodeQueryPart(value) ?? ""
                queryItems.append("\(encodedKey)=\(encodedValue)")
            }
        }
        return queryItems.isEmpty ? nil : queryItems.joined(separator: "&")
    }

    @objc
    public static func buildHttpBodyString(params: [AnyHashable: Any]?) -> String {
        var postParams = [String: String]()

        func flatten(_ dictionary: [AnyHashable: Any]?) {
            guard let dictionary = dictionary else {
                return
            }
            for entry in dictionary {
                if let key = entry.key as? String {
                    if let dictionaryValue = entry.value as? [AnyHashable: Any] {
                        flatten(dictionaryValue)
                    } else {
                        postParams[key] = "\(entry.value)"
                    }
                }
            }
        }
        flatten(params)

        return HttpUtil.buildQueryParamsString(postParams) ?? ""
    }
}

public extension URL {
    func appendingQueryParams(_ queryParams: [String: String]?) -> URL {
        guard let queryParams = queryParams else {
            return self
        }

        var queryString: String?
        if query != nil, let additionalQueryString = HttpUtil.buildQueryParamsString(queryParams) {
            queryString = "&\(additionalQueryString)"
        } else {
            queryString = HttpUtil.buildQueryString(queryParams)
        }

        guard let fullQueryString = queryString else {
            return self
        }

        return URL(string: "\(absoluteString)\(fullQueryString)") ?? self
    }

    func isDocumentTypePDF() -> Bool {
        if pathExtension.lowercased() == "pdf" {
            return true
        }
        return false
    }
}
