//
//  JsonArrayWrapper.swift
//  
//
//
//

import Foundation

/**
 This class is used to wrap a native array as an NSArray
 to support JSON serialization. As well as, allow the
 owner JsonArrayProperty to access the native array
 as its value.
 */
class JsonArrayWrapper<TValue: NSObject>: NSArray {
    /**
     Optional converter used to convert native values
     to NSString for JSON representation
     */
    var convertToString: ((TValue?) -> NSString?)?

    /// Reference to the native backing array
    var backingArray: [TValue?]?

    /**
     Return the number of elements in the array
     */
    override var count: Int {
        guard let backingArray = self.backingArray else {
            return 0
        }
        return backingArray.count
    }

    override func object(at index: Int) -> Any {
        return getObject(at: index) ?? JsonConstants.null
    }

    /**
     Return the JSON compatible object at the specified index.
     - Parameter index: the index of the element to retrieve
     */
    func getObject(at index: Int) -> Any? {
        guard let element = self.backingArray?[index], let jsonModel = element as? JsonModel else {
            if let element = self.backingArray?[index] {
                // Perform to string conversion if needed
                if let convertToString = self.convertToString, JsonProperty<TValue>.isConversionRequired(element) {
                    if let stringValue = convertToString(element) {
                        return stringValue
                    }
                }
                // Return element as is
                return element
            }
            // Nil entries are mapped to NSNull
            return JsonConstants.null
        }
        // Return backing dictionary for JsonModels
        return jsonModel.dictionary
    }

    // MARK: Instance initialization

    /**
     Initialize a new instance that wraps the specified native array.
     - Parameter withBackingArray: the native array to wrap
     */
    convenience init(withBackingArray: [TValue?]?) {
        self.init()
        self.backingArray = withBackingArray
    }

    // MARK: NSObject Overrides

    override var hash: Int {
        guard let backingArray: AnyObject = self.backingArray as AnyObject? else {
            return 0
        }
        return backingArray.hash
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? JsonArrayWrapper<TValue> else {
            return false
        }
        if self === other {
            return true
        }
        return JsonArrayWrapper.isEqual(self.backingArray, otherArray: other.backingArray)
    }

    /**
     Return a copy of the backing array
     
     - Returns: a copy the backing array
     */
    override func copy(with zone: NSZone?) -> Any {
        var copy = [NSObject]()
        //swiftlint:disable:next identifier_name
        for i in 0 ..< self.count {
            if let element = getObject(at: i) as? NSObject {
                if element === JsonConstants.null {
                    copy.append(JsonConstants.null)
                } else if let element = element.copy() as? NSObject {
                    copy.append(element)
                }
            }
        }
        return NSArray(array: copy)
    }

    // MARK: Utility methods

    /**
     Test if two arrays are equal.
     - Parameter thisArray: the first array in the comparason
     - Parameter otherArray: the second array in the comparason
     
     - Returns: true if both are nil or both contains the same contents
     */
    class func isEqual(_ thisArray: [TValue?]?, otherArray: [TValue?]?) -> Bool {
        if let thisArray = thisArray {
            if let otherArray = otherArray, thisArray.count == otherArray.count {
                for (index, element) in thisArray.enumerated() where otherArray[index] != element {
                    // Found mismatch
                    return false
                }
                // All elements matched
                return true
            }
        }
        // If this array is nil and the other is nil, then consider it equal
        return otherArray == nil
    }
}
