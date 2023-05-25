//
//  Extension+JsonPropertyProtocol.swift
//
//
//
//

import Foundation

extension JsonPropertyProtocol {
    
    static func convertToString<TValue: NSObject>(
        _ propertyDescriptor: JsonPropertyProtocol,
        value: TValue?)
    -> String
    {
        guard !value.isNill else {
            return JsonConstants.null.description
        }
        return value!.description
    }

    static func convertToValue<TValue: NSObject>(
        _ propertyDescriptor: JsonPropertyProtocol,
        stringValue: NSString?)
    -> TValue?
    {
        guard let stringValue = stringValue as String?, JsonConstants.null.description != stringValue else {
            return nil
        }
        
        var value: TValue?
        
        switch value.self {
        case is NSDecimalNumber:
            value = NSDecimalNumber(string: stringValue) as? TValue
        case is Decimal:
            value = Decimal(string: stringValue) as? TValue
        case is NSInteger:
            value = NSInteger(stringValue) as? TValue
        case is Bool:
            value = Bool(stringValue) as? TValue
        case is NSNumber:
            if let index = [false.description, true.description].firstIndex(of: stringValue)
                ?? ["N", "Y"].firstIndex(of: stringValue)
                ?? ["OFF", "ON"].firstIndex(of: stringValue)
                ?? ["NO", "YES"].firstIndex(of: stringValue) {
                value = NSNumber(value: index == 1) as? TValue
            } else if let intValue = Int(stringValue) {
                value = NSNumber(value: intValue) as? TValue
            }
        default:
            value = nil
        }
        
        if TValue.self == NSDecimalNumber.self {
            value = NSDecimalNumber(string: stringValue) as? TValue
        }
        
        return value
    }

    static func isConversionRequired(_ forType: AnyClass) -> Bool {
        return !(forType === NSString.self
                 || forType.isSubclass(of: NSNumber.self)
                 || forType.isSubclass(of: NSDictionary.self)
                 || forType.isSubclass(of: NSArray.self))
    }

    static func isConversionRequired(_ forValue: Any?) -> Bool {
        guard let value = forValue else {
            return false
        }
        return !( value is NSNull
        || value is NSString
        || value is NSNumber
        || value is NSDictionary
        || value is NSArray)
    }
}

extension NSString {
    static func onoffString(_ boolValue: Bool) -> NSString {
        boolValue ? "ON" : "OFF"
    }

    static func ynString(_ boolValue: Bool) -> NSString {
        boolValue ? "Y" : "N"
    }
    
    var ynBool: Bool {
        self == "Y"
    }
    
    var onoffBool: Bool {
        self == "ON"
    }
}

extension String {
    static func onoffString(_ boolValue: Bool) -> NSString {
        boolValue ? "ON" : "OFF"
    }

    static func ynString(_ boolValue: Bool) -> NSString {
        boolValue ? "Y" : "N"
    }
    
    var ynBool: Bool {
        self == "Y"
    }
    
    var onoffBool: Bool {
        self == "ON"
    }
}
