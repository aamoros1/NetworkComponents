//
//  JsonSettings.swift
//
//
//  
//

import Foundation

/// Global configuration settings
struct JsonSettings {
    
    /// The JSONSerialization writing options
    static var writingOptions = JSONSerialization.WritingOptions(rawValue: 0)
    
    /// The JSONSerialization reading options
    static var readingOptions = JSONSerialization.ReadingOptions.mutableContainers
}
