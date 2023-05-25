//
//  JsonModelWrapper.swift
//  
//
//
//

import Foundation

class JsonModelWrapper<TValue: NSObject>: NSDictionary {
    /// Reference to the wrapped JsonModel
    weak var jsonModel: JsonModel!

    /**
      Return the number of entries in the dictionary
     */
    override var count: Int {
        guard let dictionary = self.jsonModel?.dictionary else {
            return 0
        }
        return dictionary.count
    }

    /**
      Lookup the object for the specified key, if present.
      - Parameter aKey: the key to look
    
      - Returns: the object assigned to the key, or nil
     */
    override func object(forKey aKey: Any) -> Any? {
        return self.jsonModel?.dictionary.object(forKey: aKey)
    }

    override func value(forKey key: String) -> Any? {
        return self.jsonModel?.dictionary.value(forKey: key)
    }

    override func value(forUndefinedKey key: String) -> Any? {
        return self.jsonModel?.dictionary.value(forKey: key)
    }

    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        self.jsonModel?.dictionary.setValue(value, forKey: key)
    }

    override func setValue(_ value: Any?, forKey key: String) {
        self.jsonModel?.dictionary.setValue(value, forKey: key)
    }

    /**
      Return the enumerator used to iterate of the dictionary keys.
     
      - Returns: the keys enumerator
     */
    override func keyEnumerator() -> NSEnumerator {
        return self.jsonModel?.dictionary.keyEnumerator() ?? NSEnumerator()
    }

    // MARK: Instance initialization

    /**
      Initialize a new instance that wraps the specified JsonModel.
     - Parameter withJsonModel: the JsonModel to wrap
     */
    convenience init(withJsonModel: JsonModel) {
        self.init()
        self.jsonModel = withJsonModel
    }

    // MARK: NSObject Overrides

    override var hash: Int {
        guard let dictionary = self.jsonModel?.dictionary else {
            return 0
        }
        return dictionary.hash
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let thisDictionary = self.jsonModel?.dictionary, let otherDictionary = object as? NSDictionary else {
            return false
        }
        if thisDictionary === otherDictionary {
            return true
        }
        return thisDictionary.isEqual(otherDictionary)
    }

    /**
     Return a copy of the backing dictionary
     
     - Returns: a copy the backing dictionary
     
     - Since: IOS-2797
     */
    override func copy(with zone: NSZone?) -> Any {
        var copy = [AnyHashable: Any]()

        if let source = self.jsonModel?.dictionary {
            for key in source.allKeys {
                if let key = key as? NSObject {
                    var value = source.object(forKey: key)

                    // Dictionaries and arrays should be copied since they
                    // respresent models that may change
                    if let dictionary = value as? NSDictionary {
                        value = dictionary.copy()
                    } else if let array = value as? NSArray {
                        value = array.copy()
                    }
                    copy[key] = value
                }
            }
        }
        return NSDictionary(dictionary: copy)
    }
}

