//
//  JsonArrayPropertyTest.swift
//  
//
//
//

import XCTest
import NetworkComponents

final class JsonArrayPropertyTest: XCTestCase {
    
    /**
     Test JsonArrayProperty general use cases
     */
    // swiftlint:disable:Body_length
    func testJsonArrayProperty() {
        // Create an empty model
        let model = JsonModel()
        XCTAssertEqual(model.toJsonString(), "{}")
        XCTAssertTrue(model.properties.isEmpty)

        // Create dynamic array property
        let children = JsonArrayProperty<NSString>(model, withName: "children")
        XCTAssertEqual(model.properties.count, 1)
        XCTAssertFalse(children.isNull)
        XCTAssertTrue(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertNil(children.nativeValue)
        XCTAssertTrue(children.isEmpty)
        XCTAssertEqual(children.count, 0)
        XCTAssertEqual(children.index(of: ""), nil)
        XCTAssertFalse(children.contains(""))
        XCTAssertEqual(model.toJsonString(), "{}")

        // Initialize with empty array
        var array = [NSString]()
        children.nativeValue = array
        XCTAssertNotNil(children.nativeValue)
        XCTAssertFalse(children.isNull)
        XCTAssertFalse(children.isUndefined)
        XCTAssertFalse(children.isNullOrUndefined)
        XCTAssertTrue(children.isEmpty)
        XCTAssertEqual(children.count, 0)
        XCTAssertEqual(children.index(of: ""), nil)
        XCTAssertFalse(children.contains(""))
        XCTAssertEqual(model.toJsonString(), "{\"children\":[]}")

        // The array was assignd by value, so the property now
        // maintains its own copy. Modifying the original
        // array has no effect on the property
        array.append("Jim")
        XCTAssertTrue(children.isEmpty)
        XCTAssertEqual(children.count, 0)

        // The property array can be accessed by value to
        // manipulate the array directly
        children.nativeValue?.append("Joe")
        XCTAssertFalse(children.isEmpty)
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.index(of: "Joe"), 0)
        XCTAssertEqual(children.index(of: "Joe", startAt: -100), 0)   // Test negative start index
        XCTAssertTrue(children.contains("Joe"))
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Joe\"]}")

        // The property array can be appened to by accessing the value
        children.nativeValue?.append("Scott")
        XCTAssertEqual(children.count, 2)
        XCTAssertEqual(children.nativeValue?.count, children.count)
        XCTAssertEqual(children.index(of: "Scott"), 1)
        XCTAssertEqual(children.index(of: "Scott", startAt: -100), 1)   // Test negative start index
        XCTAssertEqual(children["Scott"], 1)  // Shorthand for indexOf
        XCTAssertTrue(children.contains("Scott"))
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Joe\",\"Scott\"]}")

        children.nativeValue?.append("Julie")
        XCTAssertEqual(children.count, 3)
        XCTAssertEqual(children.nativeValue?.count, children.count)
        XCTAssertEqual(children.index(of: "Julie"), 2)
        XCTAssertTrue(children.contains("Julie"))
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Joe\",\"Scott\",\"Julie\"]}")

        // Insertion
        children.nativeValue?.insert("Bob", at: 1)
        XCTAssertEqual(children.count, 4)
        XCTAssertEqual(children.nativeValue?.count, children.count)
        XCTAssertEqual(children.index(of: "Bob"), 1)
        XCTAssertEqual(children["Bob"], 1)  // Shorthand for indexOf
        XCTAssertTrue(children.contains("Bob"))
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Joe\",\"Bob\",\"Scott\",\"Julie\"]}")

        // Initialize to null
        children.null()
        XCTAssertEqual(model.properties.count, 1)
        XCTAssertTrue(children.isNull)
        XCTAssertFalse(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertNil(children.nativeValue)
        XCTAssertTrue(children.isEmpty)
        XCTAssertEqual(children.count, 0)
        XCTAssertEqual(children.index(of: ""), nil)
        XCTAssertFalse(children.contains(""))
        XCTAssertEqual(model.toJsonString(), "{\"children\":null}")

        // Undefine the property
        children.undefine()
        XCTAssertEqual(model.properties.count, 1)
        XCTAssertFalse(children.isNull)
        XCTAssertTrue(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertNil(children.nativeValue)
        XCTAssertTrue(children.isEmpty)
        XCTAssertEqual(children.count, 0)
        XCTAssertEqual(children.index(of: ""), nil)
        XCTAssertFalse(children.contains(""))
        XCTAssertEqual(model.toJsonString(), "{}")
    }

    /**
     Test JsonArrayProperty copy feature
     */
    func testJsonArrayPropertyCopy() {
        // Create an empty model
        let model = JsonModel()

        // Create dynamic properties
        let children = JsonArrayProperty<NSString>(model, withName: "children")
        XCTAssertNil(children.nativeValue)
        let friends = JsonArrayProperty<NSString>(model, withName: "friends")
        XCTAssertNil(friends.nativeValue)

        // Array properties can be initialized with static arrays.
        children.nativeValue = ["John", "James", "Jill", "Jenifer"]
        friends.nativeValue = ["Janet", "Julie", "Jacky"]

        // Create a second model to test the copy
        let model2 = JsonModel()
        XCTAssertNotEqual(model, model2)

        let children2 = JsonArrayProperty<NSString>(model2, withName: "children")
        XCTAssertNil(children2.nativeValue)
        XCTAssertNotEqual(children2, children)
        let friends2 = JsonArrayProperty<NSString>(model2, withName: "friends")
        XCTAssertNil(friends2.nativeValue)
        XCTAssertNotEqual(friends2, friends)

        // Copy properties from model to model2
        model2.copyProperties(model)
        XCTAssertEqual(model, model2)
        XCTAssertNotNil(children2.nativeValue)
        XCTAssertNotNil(friends2.nativeValue)
        XCTAssertEqual(children2, children)
        XCTAssertEqual(friends2, friends)

        /// Makesure that arrays are copied my mutating the original array
        children.nativeValue?.removeFirst()
        XCTAssertNotEqual(children2, children)
        XCTAssertNotEqual(model, model2)
        XCTAssertEqual(friends2, friends)
    }

    /**
     Test JsonArrayProperty prepend operator >>=
     */
    func testJsonArrayPrependOperator() {
        // Create an empty model
        let model = JsonModel()

        // Create dynamic property
        let children = JsonArrayProperty<NSString>(model, withName: "children")
        XCTAssertTrue(children.isUndefined)

        // Operator can be used to initialize the property
        children.push("one", "two", "three")
        XCTAssertFalse(children.isUndefined)
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\"]}")
        children.undefine()
        XCTAssertTrue(children.isUndefined)

        // Add some children one at a time
        //swiftlint:disable:next identifier_name
        for i in 1...3 {
            children.push("Child #\(i)" as NSString)
            XCTAssertEqual(children.count, i)
        }
        // Prepending will result is reversed ordinal
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Child #3\",\"Child #2\",\"Child #1\"]}")

        // Add multi children from another array. The array will be prepended
        // to the value array
        children.push("Tom", "Tony", "Todd")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Tom\",\"Tony\",\"Todd\",\"Child #3\"," +
            "\"Child #2\",\"Child #1\"]}")

        // Add one child
        children.push("Terry")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Terry\",\"Tom\",\"Tony\",\"Todd\"," +
            "\"Child #3\",\"Child #2\",\"Child #1\"]}")
    }

    /**
     Test JsonArrayProperty append operator <<=
     */
    func testJsonArrayAppendOperator() {
        // Create an empty model
        let model = JsonModel()

        // Create dynamic property
        let children = JsonArrayProperty<NSString>(model, withName: "children")
        XCTAssertTrue(children.isUndefined)

        // Operator can be used to initialize the property
        children.push("one", "two", "three")
        XCTAssertFalse(children.isUndefined)
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\"]}")
        children.undefine()
        XCTAssertTrue(children.isUndefined)

        // Add some children one at a time
        //swiftlint:disable:next identifier_name
        for i in 1...3 {
            children.add("Child #\(i)" as NSString)
            XCTAssertEqual(children.count, i)
        }
        // Appended children in ordinal order
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Child #1\",\"Child #2\",\"Child #3\"]}")

        // Add multi children
        children.add("Tom", "Tony", "Todd")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Child #1\",\"Child #2\",\"Child #3\"," +
                                             "\"Tom\",\"Tony\",\"Todd\"]}")

        // Add one child
        children.add("Terry")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"Child #1\",\"Child #2\",\"Child #3\"," +
                                             "\"Tom\",\"Tony\",\"Todd\",\"Terry\"]}")
    }

    /**
     Test JsonArrayProperty remove operator -=
     */
    func testJsonArrayRemoveOperator() {
        // Create an empty model
        let model = JsonModel()

        // Create dynamic property
        let children = JsonArrayProperty<NSString>(model, withName: "children")
        XCTAssertTrue(children.isUndefined)

        // Operator has no effect on undefined property
        children.remove("nothing")
        XCTAssertTrue(children.isUndefined)

        // Populate two children for each iteration to create
        // a duplicate for each entry
        //swiftlint:disable:next identifier_name
        for i in 1...10 {
            children.add("Child \(i)" as NSString)
            children.add("Child \(i)" as NSString)
            XCTAssertEqual(children.count, i*2)
        }

        // Each iteration will remove all occurrances of the element (two at a time)
        //swiftlint:disable:next identifier_name
        for i in (1...10).reversed() {
            children.remove("Child \(i)" as NSString)
            XCTAssertEqual(children.count, 2*(i-1))
        }

        // Undefine
        children.undefine()
        XCTAssertTrue(children.isUndefined)
    }

    /**
     Test JsonArrayProperty union operator |=
     */
    func testJsonArrayUnionOperator() {
        // Create an empty model
        let model = JsonModel()

        // Create dynamic property. Use var so that the property can be mutated
        let children = JsonArrayProperty<NSString>(model, withName: "children")
        XCTAssertTrue(children.isUndefined)

        // Union can be used to initialize the property
        children.union("one", "two", "three")
        XCTAssertFalse(children.isUndefined)
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\"]}")

        // Union another array. Duplicates are ignored
        children.union("one", "four", "two", "five", "three", "six")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\",\"four\",\"five\",\"six\"]}")

        // Union can add nil, but only one.
        let nilEntry: NSString? = nil
        children.union(nilEntry)
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\",\"four\"," +
            "\"five\",\"six\",null]}")
        children.union(nilEntry)
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\",\"four\"," +
            "\"five\",\"six\",null]}")

        // Union can add a single element, but no duplicates
        children.union("seven")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\",\"four\"," +
            "\"five\",\"six\",null,\"seven\"]}")
        children.union("seven")
        XCTAssertEqual(model.toJsonString(), "{\"children\":[\"one\",\"two\",\"three\",\"four\"," +
            "\"five\",\"six\",null,\"seven\"]}")
    }

    /// Test the JsonArrayProperty Subscript feature
    // swiftlint:disable:Body_length
    func testJsonArrayPropertySubscript() {
        // Create an empty model
        let model = JsonModel()

        // Create dynamic property. Use var so that the property can be mutated
        let children = JsonArrayProperty<NSString>(model, withName: "children")

        // Verify undefined state
        XCTAssertTrue(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertFalse(children.isNull)
        XCTAssertEqual(children.count, 0)
        XCTAssertTrue(children.isEmpty)
        XCTAssertNil(children[0])
        XCTAssertNil(children[-1])
        XCTAssertNil(children[1])

        // Verify null state
        children.null()
        XCTAssertFalse(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertTrue(children.isNull)
        XCTAssertEqual(children.count, 0)
        XCTAssertTrue(children.isEmpty)
        XCTAssertNil(children[0])
        XCTAssertNil(children[-1])
        XCTAssertNil(children[1])

        // Auto init array with first insert
        children[0] = "Tom"
        XCTAssertFalse(children.isUndefined)
        XCTAssertFalse(children.isNullOrUndefined)
        XCTAssertFalse(children.isNull)
        XCTAssertEqual(children.count, 1)
        XCTAssertFalse(children.isEmpty)
        XCTAssertEqual(children[0], "Tom")
        XCTAssertNil(children[-1])
        XCTAssertNil(children[1])

        // Auto full array with nill when inserting beyond length
        children[11] = "Terry"
        XCTAssertEqual(children.count, 12)
        XCTAssertEqual(children[0], "Tom")
        XCTAssertEqual(children[11], "Terry")
        XCTAssertNil(children[-1])
        XCTAssertNil(children[12])

        // Array gap should be padded with nil
        //swiftlint:disable:next identifier_name
        for i in 1...10 {
            XCTAssertNil(children[i])
        }
        // Test reassignment
        //swiftlint:disable:next identifier_name
        for i in 1...10 {
            children[i] = "Joe"
            XCTAssertEqual(children[i], "Joe")
        }

        // Special operator to remove all occurrences of a value
        children.remove("Joe")
        XCTAssertEqual(children.count, 2)
        XCTAssertEqual(children[0], "Tom")
        XCTAssertEqual(children[1], "Terry")
        XCTAssertNil(children[-1])
        XCTAssertNil(children[2])

        // Re-verify null state
        children.null()
        XCTAssertFalse(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertTrue(children.isNull)
        XCTAssertEqual(children.count, 0)
        XCTAssertTrue(children.isEmpty)
        XCTAssertNil(children[0])
        XCTAssertNil(children[-1])
        XCTAssertNil(children[1])

        // Reverify undefined state
        children.undefine()
        XCTAssertTrue(children.isUndefined)
        XCTAssertTrue(children.isNullOrUndefined)
        XCTAssertFalse(children.isNull)
        XCTAssertEqual(children.count, 0)
        XCTAssertTrue(children.isEmpty)
        XCTAssertNil(children[0])
        XCTAssertNil(children[-1])
        XCTAssertNil(children[1])
    }
}
