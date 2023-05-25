//
//  XmlBodyElement.swift
//  
//
//  
//

import Foundation

public class XmlBodyElement: NSObject {
    fileprivate static let empty = NSDictionary()
    public let name: String
    public let attributes: [String: String]?
    public internal(set) var parent: XmlBodyElement?
    public private(set) var namespaceUri: String?
    public private(set) var content: NSObject?
    public var dictionary: NSDictionary? {
        return content as? NSDictionary
    }
    public var array: NSArray? {
        return content as? NSArray
    }

    required public init(name: String, namespaceUri: String?, attributes: [String: String]?) {
        self.name = name
        self.namespaceUri = namespaceUri
        self.attributes = attributes

        if namespaceUri == nil || namespaceUri?.isEmpty == true {
            var attrName = "xmlns"

            if let delim = name.range(of: ":", options: .literal) {
                let nsPrefix = name.prefix(upTo: delim.lowerBound)
                attrName += ":\(nsPrefix)"
            }
            self.namespaceUri = attributes?[attrName]
        }
        super.init()
    }

    func addChild(element: XmlBodyElement) {
        element.parent = self

        if let dictionary = self.content as? NSMutableDictionary {
            if let sibling = dictionary.object(forKey: element.name) {
                if let array = sibling as? NSMutableArray {
                    array.add(element)
                } else {
                    let array = NSMutableArray(object: sibling)
                    array.add(element)
                    dictionary.setObject(array, forKey: element.name as NSString)
                }
            } else {
                dictionary.setObject(element, forKey: element.name as NSString)
            }
        } else {
            content = NSMutableDictionary(object: element, forKey: element.name as NSString)
        }
    }

    func setContent(string: NSString) {
        if self.content == nil {
            self.content = string.length > 0 ? string : XmlBodyElement.empty
        } else if let dictionary = self.content as? NSMutableDictionary {
            dictionary.setObject(string, forKey: "_content_" as NSString)
        }
    }

    func didEndParse() {
        if content == nil {
            if attributes?.isEmpty == false {
                let dictionary = NSMutableDictionary()
                self.attributes?.forEach {
                    dictionary.setValue($0.1, forKey: "_\($0.0)")
                }
                content = dictionary
            } else {
                content = XmlBodyElement.empty
            }
        } else if let dictionary = content as? NSMutableDictionary {
            dictionary.allKeys.forEach {
                if let key = $0 as? String {
                    if let element = dictionary.value(forKey: key) as? XmlBodyElement {
                        dictionary.setValue(element.content ?? XmlBodyElement.empty, forKey: key)
                    } else if let array = dictionary.value(forKey: key) as? NSMutableArray {
                        XmlBodyElement.flatten(array)
                    }
                }
            }
            self.attributes?.forEach {
                dictionary.setValue($0.1, forKey: "_\($0.0)")
            }
        } else if let array = content as? NSMutableArray {
            XmlBodyElement.flatten(array)
        }
    }

    fileprivate static func flatten(_ array: NSMutableArray) {
        for index in 0..<array.count {
            if let element = array.object(at: index) as? XmlBodyElement {
                array.replaceObject(at: index, with: element.content ?? XmlBodyElement.empty)
            }
        }
    }
}
