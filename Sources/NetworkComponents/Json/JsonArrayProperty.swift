//
//  JsonArrayProperty.swift
//
//
// 
//

import Foundation

/**
 This class is used to define a JsonModel array property that is strongly typed.
 
 - Note: It is highly recommended that NSArray properties are represented by
    this JsonPropertyProtocol implementation if the NSArray contains a single type.
 
 - Parameter TValue: specified the NSObject type of the array property
 */
open class JsonArrayProperty<TValue: NSObject>: BaseJsonProperty<TValue> {

    // MARK: Class Properties

    /// Test if the array is empty
    open var isEmpty: Bool {
        guard let jsArray = self.rawValue as? JsonArrayWrapper<TValue> else {
            return true
        }
        return jsArray.backingArray?.count == 0
    }

    /// Get the array count
    open var count: Int {
        guard let array = self.nativeValue else {
            return 0
        }
        return array.count
    }

    /**
      Get or set the element at the specified index.
      - Parameter atIndex: the index of the element.
 
      - NOTE: when setting to an index that is greater
        then the current array size, the array is automatically
        expanded with nil elements up to the specifed index.
     */
    open subscript(atIndex: Int) -> TValue? {
        get {
            guard let array = self.nativeValue, atIndex >= 0 && atIndex < array.count else {
                // Don't allow out of bounds access
                return nil
            }
            return array[atIndex]
        }
        set {
            guard atIndex >= 0 else {
                // Don't allow negative indexing
                return
            }
            // Auto create, if necessary
            if self.nativeValue == nil {
                self.nativeValue = [TValue?]()
            }
            // Pad with nil, if necessary
            while self.nativeValue?.count ?? 0 <= atIndex {
                self.nativeValue?.append(nil)
            }
            // Store at index
            self.nativeValue?[atIndex] = newValue
        }
    }

    /// Get the element index
    open subscript(anElement: TValue?) -> Int? {
        return self.index(of: anElement)
    }

    /**
     Get or set the native value managed by this property
     */
    open var nativeValue: [TValue?]? {
        get {
            if self.rawValue == nil {
                // Arrays are stored in the dictionary using a special NSArray wrapper
                // of the native array
                if let jsArray = self.createJSArrayWrapper(self.dictionaryValue) {
                    self.dictionaryValue = jsArray
                    self.rawValue = jsArray
                }
            }
            if let jsArray = self.rawValue as? JsonArrayWrapper<TValue> {
                // Always return the backed native array so it can
                // be naturally manipulated by client code
                return jsArray.backingArray
            }
            // Can't convert to array, or not initialized
            return nil
        }
        set {
            if let array = newValue {
                // Update entry in backing dicrtionary with the NSArray wrapper
                let jsArray = JsonArrayWrapper(withBackingArray: array)
                self.dictionaryValue = jsArray
                self.rawValue = jsArray
            } else {
                // Setting value to nil is represented as NSNull in backing dictionary
                self.rawValue = nil
                self.dictionaryValue = JsonConstants.null
            }
        }
    }

    // MARK: Class Methods

    /**
     Construct a new instance
     - Parameter withJsonModel: the JsonModel instance that owns this property
     - Parameter withName: the property name
     */
    public required init(_ withJsonModel: JsonModel, withName: String) {
        super.init(withJsonModel, withName)
    }

    public required init(_ withJsonModel: JsonModel, _ withName: String) {
        fatalError("init has not been implemented")
    }

    /**
     Copy the value of another property, if it is compatible.
     - Parameter other: the other property
     */
    override open func copy(_ other: JsonPropertyProtocol) {
        if let otherProperty = other as? JsonArrayProperty<TValue> {
            self.nativeValue = otherProperty.nativeValue
        }
    }

    /**
      Return the index of an element that may be in the array.
      - Parameter element: the element value, or nil.
      - Parameter startAt: the optional index to start scanning at. Defaults to 0
     */
    open func index(of element: TValue?, startAt: Int = 0) -> Int? {
        if let array = self.nativeValue, startAt < array.count {
            // Use indexing instead of enumeration to optimize scanning at start index
            for index in max(startAt, 0) ..< array.count where array[index] == element {
                return index
            }
        }
        return nil
    }

    /**
     Remove an element at the specified index.
     - Parameter atIndex: the index of the element to remove
 
     - Returns: the element that was at the specified index.
        This can be nil if the element was nil or the index
        is out of bounds.
     */
    @discardableResult
    open func remove(at index: Int) -> TValue? {
        let arrayCount = self.nativeValue?.count ?? 0
        var result: TValue?

        if 0..<arrayCount ~= index {
            result = self.nativeValue?.remove(at: index)
        }
        return result
    }

    /**
     Remove all elements.
     */
    public func removeAll() {
        self.nativeValue?.removeAll()
    }

    /**
     Remove all occurrences of the specified elements from the array
     */
    @discardableResult
    public func remove(_ elements: TValue?...) -> JsonArrayProperty<TValue> {
        if !isNullOrUndefined {
            elements.forEach {element in
                var startAt = 0
                while let index = index(of: element, startAt: startAt) {
                    remove(at: index)
                    startAt = index
                }
            }
        }
        return self
    }

    /**
     Add the specified element to the end of the array
     */
    @discardableResult
    public func add(_ elements: TValue?...) -> JsonArrayProperty<TValue> {
        if self.isNullOrUndefined {
            self.nativeValue = elements
        } else {
            elements.forEach {element in
                self.nativeValue?.append(element)
            }
        }
        return self
    }

    /**
     Push the specified elements on the top of array
     */
    @discardableResult
    public func push(_ elements: TValue?...) -> JsonArrayProperty<TValue> {
        if self.isNullOrUndefined {
            self.nativeValue = elements
        } else {
            var index = 0
            elements.forEach {element in
                self.nativeValue?.insert(element, at: index)
                index += 1
            }
        }
        return self
    }

    /**
     Union the specified elements to the array
     */
    @discardableResult
    public func union(_ elements: TValue?...) -> JsonArrayProperty<TValue> {
        if isNullOrUndefined {
            self.nativeValue = elements
        } else {
            elements.forEach {element in
                if !self.contains(element) {
                    self.nativeValue?.append(element)
                }
            }
        }
        return self
    }

    /**
     Test if the array contains an element for scanning
     for the first occurrance of the element.
     - Parameter element: the element to test for, or nil
     */
    open func contains(_ element: TValue?) -> Bool {
        guard let index = self.index(of: element) else {
            return false
        }
        return index >= 0
    }

    /**
     Create the JSArrayWrapper for a JSON value retrieved from the backing dictionary.
     - Parameter jsonValue: the value to wrap
     
     - Reeturns: a new JSArrayWrapper instance
     */
    func createJSArrayWrapper(_ jsonValue: Any?) -> JsonArrayWrapper<TValue>? {
        if let alreadyWrapped = jsonValue as? JsonArrayWrapper<TValue> {
            // Just as a precaution, if the value is already a wrapper
            // then nothing needs to be done.
            return alreadyWrapped
        }

        // This is the native array to wrap
        var array: [TValue?]?

        if let valueArray = jsonValue as? [TValue?] {
            // The value is already compatible array
            array = valueArray
        } else if let nsArray = jsonValue as? NSArray {
            // Convert the NSArray to a native array
            array = [TValue?]()

            for element in nsArray {
                if element is NSNull {
                    array?.append(nil)
                } else if let value = self.resolveJsonValue(element as AnyObject?) as? TValue {
                    array?.append(value)
                }
            }
        } else {
            // For the case where the JSON value is an object or primative
            // value, then convert to an array of that value
            if let value = super.resolveJsonValue(jsonValue) as? TValue {
                array = [value]
            }
        }
        if array != nil {
            let jsArray = JsonArrayWrapper<TValue>(withBackingArray: array)

            // Assign string conversion function if required
            if let convertToString = self.convertToString, self.isConversionRequired {
                jsArray.convertToString = { [unowned self] value in
                    convertToString(self, value) as NSString?
                }
            }
            return jsArray
        }
        return nil
    }

    // MARK: NSObject overrides

    open override func isEqual(_ object: Any?) -> Bool {
        if super.isEqual(object) {
            if let other = object as? JsonArrayProperty<TValue> {
                // IOS:2797 - Refactored original logic to reusable method in JSArrayWrapper
                return JsonArrayWrapper.isEqual(self.nativeValue, otherArray: other.nativeValue)
            }
        }
        return false
    }
}
