//
//  BaseJsonProperty.swift
//
//
//
//

import Foundation

open class BaseJsonProperty<TValue: NSObject>: NSObject, JsonPropertyProtocol {

    // MARK: JsonPropertyProtocol

    open fileprivate(set) weak var jsonModel: JsonModel!

    open fileprivate(set) var type: AnyClass = TValue.self

    open fileprivate(set) var name: String

    open fileprivate(set) var isConversionRequired: Bool = JsonProperty<TValue>.isConversionRequired(TValue.self)

    open var isNull: Bool {
        dictionary?[name] is NSNull
    }

    open var isUndefined: Bool {
        dictionary?[name] == nil
    }

    open var isNullOrUndefined: Bool {
        if let value = dictionary?[name] {
            return value is NSNull
        }
        // Undefined
        return true
    }

    open func null() {
        // Set value in backing dictionary to NSNull
        dictionary?[name] = JsonConstants.null
        rawValue = nil
    }

    open func undefine() {
        // Remove the key from the backing dictionary to undefine the property
        dictionary?.removeObject(forKey: name)
        rawValue = nil
    }

    // MARK: Class Properties

    /// Get or set the property value to string converter
    open var convertToString: ((JsonPropertyProtocol, TValue?) -> String?)?

    /// Get or set the property value from string converter
    open var convertToValue: ((JsonPropertyProtocol, NSString?) -> TValue?)?

    /// Get the backing dictionary where JSON compatible values are stored
    internal var dictionary: NSMutableDictionary? {
        jsonModel?.dictionary
    }

    internal var dictionaryValue: Any? {
        get {
            dictionary?.value(forKeyPath: name) ?? dictionary?.value(forKey: name)
        }
        set {
            dictionary?.setValue(newValue, forKeyPath: name)

            if newValue != nil && dictionary?.value(forKeyPath: name) == nil {
                dictionary?.setValue(newValue, forKey: name)
            }
        }
    }

    /// Get or set the raw property value
    internal var rawValue: AnyObject?

    // MARK: Class Methods

    /**
      Initialize a new instance.
      - Parameter withJsonModel: reference to the owner JsonModel
      - Parameter withName: the property name
     */
    public required init(_ withJsonModel: JsonModel, _ withName: String) {
        jsonModel = withJsonModel
        name = withName
        convertToString = BaseJsonProperty.convertToString
        convertToValue = BaseJsonProperty.convertToValue

        super.init()
        jsonModel.properties[withName] = self
    }

    /**
      Copy the value of the specified property
      - Parameter other: the other property
     */
    open func copy(_ other: JsonPropertyProtocol) {
        /// Subclass must override
    }

    /**
      Resolve the specified JSON value to its native representation.
      - Parameter jsonValue: the JSON value as read from the backing dictionary
     
      - Returns: the natve representation of the JSON value
     */
    func resolveJsonValue(_ jsonValue: Any?) -> AnyObject? {
        if let value = jsonValue as? TValue {
            // Return value as is if it is already the correct type
            return value
        }
        if let stringValue = jsonValue as? NSString {
            // NSString values must be converted to desired type
            return convertToValue?(self, stringValue)
        }
        // NSDictionary values must be represented by a JsonModel type
        if let asDictionary = jsonValue as? NSDictionary, let jsonModelType = self.type as? JsonModel.Type {
            return jsonModelType.init(with: asDictionary)
         }
        // The JSON value is null or cannot be resolved
        return nil
    }

    // MARK: NSObject overrides

    open override var hash: Int {
        name.hash
    }

    open override func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? BaseJsonProperty<TValue> {
            if self === obj {
                return true
            }
            // Basic equality is same type and same name.
            // Subclasses will test actual value too.
            return type === obj.type && name == obj.name
        }
        return false
    }
}
