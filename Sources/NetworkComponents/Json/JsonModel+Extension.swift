//
//  JsonModel+Extension.swift
//
//
//
//  

import Foundation

/**
  Define extension methods for JsonModel.
 */
public extension JsonModel {

    /**
     Create a new model from the specified JSON string.
     - Parameter TModel: the JsonModel subclass type
     - Parameter jsonString: the JSON string to deserialize
     
     - Returns: a new model instance of the specified TModel type.
     */
    class func fromJsonString<TModel: JsonModel>(_ jsonString: String?) throws -> TModel {
        return TModel(with: try JsonModel.parseJsonData(jsonString?.data(using: String.Encoding.utf8)) ?? NSDictionary())
    }

    /**
     Create a new model from the specified JSON data.
     - Parameter TModel: the JsonModel subclass type
     - Parameter jsonData: the JSON data to deserialize
     
     - Returns: a new model instance of the specified TModel type.
     */
    class func fromJsonData<TModel: JsonModel>(_ jsonData: Data?) throws -> TModel {
        return TModel(with: try JsonModel.parseJsonData(jsonData) ?? NSDictionary())
    }

    /**
     Create a new model from the specified dictionary.
     - Parameter TModel: the JsonModel subclass type
     - Parameter dictionary: the optional dictionary containing model data

     - Returns: a new model instance of the specified TModel type.
     */
    class func fromDictionary<TModel: JsonModel>(_ dictionary: NSDictionary?) -> TModel {
        return TModel(with: dictionary ?? NSDictionary())
    }

    /**
     Create a new model by loading JSON data from a bundle.
     - Parameter TModel: the JsonModel subclass type
     - Parameter bundle: the optional bundle containing model data. Specify nil
     -                   to load from the class bundle.
     - Parameter json: the name of the json file stored in the bundle

     - Returns: a new TModel if successful, otherwise nil.
     */
    class func fromBundle<TModel: JsonModel>(_ bundle: Bundle = Bundle(for: TModel.self), json: String) -> TModel? {
        var model: TModel?

        do {
            if let dictionary = try parseJson(bundle, json) {
                model = TModel(with: dictionary)
            }
        } catch {
            // nil
        }
        return model
    }

    /**
     Parse the specified JSON string.
     - Parameter jsonString: the JSON string to parse
     - Parameter withEncoding: the encoding of the specified JSON string. Defaults to UTF8
     
     - Returns: the NSDictionary result of the parse, if successful
     */
    static func parseJsonString(_ jsonString: String?, withEncoding: String.Encoding = String.Encoding.utf8) throws -> NSDictionary? {
        let jsonData: Data? = jsonString?.data(using: withEncoding)
        return try parseJsonData(jsonData)
    }

    /**
     Parse the specified JSON data.
     - Parameter jsonData: the JSON string to parse
     
     - Returns: the NSDictionary result of the parse, if successful
     */
    static func parseJsonData(_ jsonData: Data?) throws -> NSDictionary? {
        var dictionary: NSDictionary?

        if let jsonData = jsonData {
            dictionary = try JSONSerialization.jsonObject(with: jsonData,
                                                          options: JsonSettings.readingOptions) as? NSDictionary
        }
        return dictionary
    }

    /**
     Parses a JSON file in a given bundle.
     - Parameter bundle: the bundle that the JSON file exists within. Default is main Bundle.
     - Parameter filename: the name of the JSON file
     - Returns: the NSDictionary result of the parse, if successful
     - Throws: if there is incorrectly formatted JSON data in the file
     */
    static func parseJson(_ bundle: Bundle = .main, _ filename: String) throws -> NSDictionary? {
        guard let path = bundle.path(forResource: filename, ofType: "json") else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        let data = try? Data(contentsOf: url)
        return try parseJsonData(data)
    }

    /**
      Perform a deep copy of the specified dictionary.
      - Parameter source: the dictionary to deep copy
 
      - Returns: a new dictionary that is a deep copy of the given dictionary.
 
      - Since: IOS-2797
     */
    static func dictionaryFromDeepCopy(_ source: NSDictionary) -> NSDictionary {
        var copy = [AnyHashable: Any]()

        for key in source.allKeys {
            if let key = key as? NSObject,
               let value = source.object(forKey: key) as? NSCopying {
                copy[key] = value.copy()
            }
        }
        return NSDictionary(dictionary: copy)
    }

    /**
     Convenience initializer to construct a new JsonModel from a JSON string.
     - Parameter withJsonString: the JSON string
     - Parameter withEncoding: the JSON string encoding. Defaults to UTF8
     */
    convenience init(with jsonString: String?, withEncoding: String.Encoding = String.Encoding.utf8) throws {
        let dictionary = try JsonModel.parseJsonString(jsonString, withEncoding: withEncoding)
        self.init(with: dictionary ?? NSMutableDictionary())
    }

    /**
      Convenience initializer to construct a new JsonModel by copying the
      backing dictionary of the specified model.
      - Parameter withModel: the JsonModel whose backing dictionary is used
        to initialize the new instance
     */
    convenience init(_ model: JsonModel) {
        self.init(with: model.dictionary)
    }

    /**
      Define a JSON model property.
      - Parameter withName: The string representing the name of the JSON property.
     
      - Usage: private(set) var propertyName : JsonProperty<TValue> = self.defineProperty("propertyName")
        where TValue is an NSObject type.
     
      - Return: The instance of JsonProperty<TValue> that is used to manage
        access to the JSON property
     */
    func defineProperty<TValue: NSObject>(_ withName: String, defaultValue: Any? = nil) -> JsonProperty<TValue> {
        let property = JsonProperty<TValue>(self, withName: withName)

        if let defaultValue = defaultValue as? TValue {
            property.nativeValue = defaultValue
        }
        return property
    }

    /**
      Define a JSON model array property.
      - Parameter withName: The string representing the name of the JSON property.
     
      - Usage: private(set) var propertyName : JsonArrayProperty<TValue> = self.defineArrayProperty("propertyName")
      where TValue is an NSObject type.
     
      - Return: The instance of JsonArrayProperty<TValue> that is used to manage
        access to the JSON array property
     */
    func defineArrayProperty<TValue: NSObject>(_ withName: String) -> JsonArrayProperty<TValue> {
        let property = JsonArrayProperty<TValue>(self, withName: withName)
        return property
    }
}
