//
//  JsonPropertyProtocol.swift
//
//
//  
//

import Foundation

/// Contractual protocol for a JSON property
/// This contract allows for finer control over JSON properties defined for a
/// JsonModel backed by an NSDictionary.
///
/// JSON serialization currently supports the following native types:
///     -   `NSString`: for string or generic data
///     -   `NSNumber`: for numeric data
///     -   `NSDictionary`: for containment of objects
///     -   `NSArray`: for collections of supported native types
///
/// All other types will require conversion (see #isConversionRequired)
/// from the native to NSString so that it can be stored in the backing
/// NSDictionary. When the NSString value is retreived, it is then
/// converted to the native type by a custom conversion function.

public protocol JsonPropertyProtocol {
    
    /// Get the reference to the owner model the this property was constructed with.
    var jsonModel: JsonModel! { get }
    
    /// Get theproperty native type that this property is specialized for.
    var type: AnyClass { get }
    
    /// Get the property name.
    var name: String { get }
    
    /// Test if the property value requires conversion.
    var isConversionRequired: Bool { get }
    
    /// Test if the property is defined by is null.
    var isNull: Bool { get }
    
    /// Test if the property is undefined.
    var isUndefined: Bool { get }
    
    /// Test if the property is null or undefined.
    var isNullOrUndefined: Bool { get }
    
    /// Null out the property value by setting it to NSNull. If it is not defined,
    ///  then it will be defined as null.
    func null()

    /// Undefine the property value by removing it from the backing store
    func undefine()

    /// Copy the value of another property, if the types are the same
    /// - Parameter other: the json that is to be copied
    func copy(_ other: JsonPropertyProtocol)
}
