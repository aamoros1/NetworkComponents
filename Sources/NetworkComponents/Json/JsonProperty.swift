//
//  JsonProperty.swift
//
//
//
//

import Foundation

open class JsonProperty<TValue: NSObject>: BaseJsonProperty<TValue> {

    // MARK: Class Properties

    open var nativeValue: TValue? {
        get {
            if self.rawValue == nil {
                // The value in the dictionary is converted to the rawValue
                self.rawValue = self.resolveJsonValue(dictionaryValue)

                if let jsonModel = self.rawValue as? JsonModel {
                    // IOS-2797: Wrap the JsonModel in a NSDictionary fascade
                    self.dictionaryValue = JsonModelWrapper(withJsonModel: jsonModel)
                }
            }
            // Always return rawValue of the property type
            return self.rawValue as? TValue
        }
        set {
            if let jsonModel = newValue as? JsonModel {
                // If the value is a model, then store its backing dictionary
                self.rawValue = jsonModel

                // IOS-2797: Wrap the JsonModel in a NSDictionary fascade
                self.dictionaryValue = JsonModelWrapper(withJsonModel: jsonModel)
            } else {
                // Reset the rawValue so it is resolved on get
                self.rawValue = nil

                if newValue == nil {
                    // NSNull is stored when the value is set to nil.
                    self.dictionaryValue = JsonConstants.null
                } else {
                    // Store the value in the backing dictionary, converting to NSString if needed
                    self.dictionaryValue = JsonProperty<TValue>.isConversionRequired(newValue)
                        ? self.convertToString?(self, newValue) : newValue
                }
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
        if let otherProperty = other as? JsonProperty<TValue> {
            self.nativeValue = otherProperty.nativeValue
        }
    }

    // MARK: NSObject Overrides

    open override func isEqual(_ object: Any?) -> Bool {
        if super.isEqual(object) {
            if let other = object as? JsonProperty<TValue> {
                // Compare actual value
                return self.nativeValue == other.nativeValue
            }
        }
        return false
    }
}
