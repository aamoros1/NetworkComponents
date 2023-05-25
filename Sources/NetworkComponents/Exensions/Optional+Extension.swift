//
//  Optional+Extension.swift
//  
//
//
//

import Foundation

extension Optional where Wrapped: Collection {
    var isEmptyOrNil: Bool {
        self?.isEmpty ?? true
    }
}

extension Optional {
    var isNill: Bool {
        self == nil
    }
}
