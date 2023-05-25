//
//  JsonModel.swift
//
//
//
//

import Foundation

/**
    Base class for JSON models that supports property declaration and
    serialization to and from JSON. This model also supports containment
    of other JsonModels, and array of primitives and JsonModels.
 */
@objc
open class JsonModel: NSObject, DomainModel {

    // MARK: Class Constants

    // MARK: Class Properties

    /// Collection of defined properties
    open internal(set) var properties = [String: JsonPropertyProtocol]()

    /// Reference to the backing dictionary where property values are stored
    fileprivate(set) var dictionary: NSMutableDictionary!

    /// Reference to a copy of the backing dictionary before editing begins
    /// - Since: IOS-2797
    fileprivate var beforeEditDictionary: NSDictionary?

    // MARK: Class Methods

    /**
      Initialize a new instance with the current values in the specified dictionary
      used to back the model properties. The current content of the given dictionary
      is copied to an internally maintained dictionary.
      - Parameter withDictionary: the dictionary containing the current property values.
     */
    public required init(with dictionary: NSDictionary?) {
        if let dictionary = dictionary {
            self.dictionary = NSMutableDictionary(dictionary: dictionary)
        } else {
            self.dictionary = NSMutableDictionary()
        }
        super.init()
    }

    /**
      Convenience initailizer for constructing a new uninitialized instance
     */
    public convenience override init() {
        self.init(with: NSMutableDictionary())
    }

    /**
      Copy compatible properties from another model.
      - Parameter other: the other model to copy properties from
     */
    open func copyProperties(_ other: JsonModel) {
        for otherProperty in other.properties.values {
            if let myProperty = self.properties[otherProperty.name] {
                myProperty.copy(otherProperty)
            }
        }
    }

    /**
      Return the JSON representation of this model as an NSData.
     
      - Return: the NSData containing the UTF8 encoding of the
        JSON representation of this model
     */
    open func toJsonData() -> Data? {
        var jsonData: Data?
        guard let jsonDictionary = dictionary else {
            return jsonData
        }

        do {
            jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: JsonSettings.writingOptions)
        } catch {
            //Logger.error("Unable to render JSON Data: \(error.localizedDescription)")
        }
        return jsonData
    }

    /**
      Return the JSON representation of this model as an encoded string.
      - Parameter withEncoding: the optional string encoding, if not specified
        then UTF8 encoding is used
    
      - Return: the string representation of the JSON for this model.
     */
    open func toJsonString(encoding: String.Encoding = String.Encoding.utf8) -> String? {
        var jsonString: String?

        if let jsonData = toJsonData() {
            jsonString = String(data: jsonData, encoding: encoding)
        }
        return jsonString
    }

    /**
      Called change the backing dictionary.
      - Parameter withDictionary: the dictionary that represents the JSON model
     */
    open func setBackingDictionary(_ dictionary: NSDictionary) {
        if self.dictionary !== dictionary {
            for property in self.properties.values {
                // Existing properties must be undefined
                // to clear cached raw values
                property.undefine()
            }
            self.dictionary = NSMutableDictionary(dictionary: dictionary)
        }
    }

    /**
     Called to save the current state in a separate dictionary before editing.
     
     - Since: IOS-2797
     */
    open func beginEdit() {
        self.beforeEditDictionary = JsonModel.dictionaryFromDeepCopy(self.dictionary)
    }

    /**
      Called after editing has completed
      - Parameter commit: true to commit the change, otherwise the previous state is restored if dirty
     
      - Since: IOS-2797
     */
    open func endEdit(_ commit: Bool) {
        // If there is a saved state that is dirty, then do commit logic
        if let savedState = self.beforeEditDictionary, savedState != self.dictionary {
            if commit {
                // Commit changes with existing backing dictionary and keep it
                self.save()

                // IOS-2751: Notify changed setting
                self.postDidChangeNotification()
            } else {
                // Restore the saved dictionary
                self.setBackingDictionary(savedState)
            }
        }
        // Release saved state after edit
        self.beforeEditDictionary = nil
    }

    /**
      Register an observer for change notification.
      - Parameter observer: the observer
      - Parameter hander: the Selector to handler the notificaiton
     
      - Since: IOS-2797
     */
    open func addDidChangeObserver(_ observer: AnyObject, handler: Selector) {
        NotificationCenter.default.addObserver(observer, selector: handler,
                                               name: .jsonModelDidChangeNotification, object: self)
    }

    /**
      Remove a previously added did change observer.
      - Parameter observer: the observer to remove
     
      - Since: IOS-2797
     */
    open func removeDidChangeObserver(_ observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer, name: .jsonModelDidChangeNotification, object: self)
    }

    /**
      Post the did change notifcaiton.
     
      - Since: IOS-2797
     */
    open func postDidChangeNotification() {
        NotificationCenter.default.post(name: .jsonModelDidChangeNotification, object: self)
    }

    /**
     Save the current state regardless of dirty state.
     
     - Since: IOS-2797
     */
    open func save() {
        // Subclass can override to proving save feature
    }

    /**
      Reset the model by setting all properties to undefined
     
     - Since: IOS-2797
     */
    open func reset() {
        for property in self.properties.values {
            property.undefine()
        }
    }

    /// NSObject Overrides

    open override var hash: Int {
        return self.dictionary.hash
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? JsonModel else {
            return false
        }
        if self === other {
            return true
        }
        return type(of: self) === type(of: other) ? self.dictionary.isEqual(other.dictionary) : false
    }

    open func toString() -> String? {
        return toJsonString()
    }

    open func deserialize(from string: String?) -> Error? {
        guard let jsonData = string?.data(using: .utf8) else {
            // Nothing to parse
            return nil
        }
        do {
            if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: JsonSettings.readingOptions) as? NSDictionary {
                self.setBackingDictionary(dictionary)
            }
            return nil
        } catch let error {
            return error
        }
    }
}
