//
//  DomainModel.swift
//
//
//
//  

import Foundation

@objc
public protocol DomainModel: NSObjectProtocol {
    init(with dictionary: NSDictionary?)

    func toString() -> String?
    func deserialize(from string: String?) -> Error?
}
