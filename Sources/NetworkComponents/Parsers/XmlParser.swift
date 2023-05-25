//
//  XmlParser.swift
//  
//
//  
//

import Foundation

@objc
/// XML Parser used for deserialization.
/// This class implements NSXMLParserDelegate and uses NSXMLParser
/// to do the heavy lifting.
public class XmlParser: NSObject {
    @objc
    public private(set) var document: XmlElement?

    @objc
    public private(set) var isSoapEnvelope: Bool = false

    @objc
    public private(set) var soapHeader: XmlElement?

    @objc
    public private(set) var soapBody: XmlElement?

    private var currentElement: XmlElement?
    private var currentContent: NSMutableString?

    @objc
    /// Parse the specified XML UTF8 string into the given model instance
    /// - Parameter xmlString: The XML string to parse
    /// - throws: error code
    public func parse(xmlString: String) throws {
        guard let data = xmlString.data(using: .utf8, allowLossyConversion: true) else {
            return
        }
        try self.parse(xmlData: data)
    }

    @objc
    /// Parse the specified XML data into the given model instance
    /// - Parameter xmlData: the data to parse
    /// - throws: error code
    public func parse(xmlData: Data) throws {
        let parser = XMLParser(data: xmlData)

        parser.shouldProcessNamespaces = true
        parser.shouldResolveExternalEntities = false
        parser.delegate = self

        if !parser.parse() {
            if let error = parser.parserError {
                throw error
            }
        }
    }
}

extension XmlParser: XMLParserDelegate {
    public func parserDidStartDocument(_ parser: XMLParser) {
        document = nil
        isSoapEnvelope = false
        soapHeader = nil
        soapBody = nil
        currentElement = nil
        currentContent = nil
    }

    public func parserDidEndDocument(_ parser: XMLParser) {
        // NOP
    }

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        let element = XmlElement(name: elementName, namespaceUri: namespaceURI, attributes: attributeDict)

        if document == nil {
            document = element
            isSoapEnvelope = namespaceURI?.hasPrefix("http://schemas.xmlsoap.org/soap/envelope") == true
        }
        currentElement?.addChild(element: element)
        currentElement = element
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentContent == nil {
            currentContent = NSMutableString()
        }
        currentContent?.append(string)
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let currentContent = self.currentContent {
            currentElement?.setContent(string: currentContent.trimmingCharacters(in: .whitespacesAndNewlines) as NSString)
            self.currentContent = nil
        }
        if currentElement?.parent === document && isSoapEnvelope {
            if currentElement?.name == "Header" {
                soapHeader = currentElement
            } else if currentElement?.name == "Body" {
                soapBody = currentElement
            }
        }
        currentElement?.didEndParse()
        currentElement = currentElement?.parent
    }
}
