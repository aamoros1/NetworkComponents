//
//  JsonModelTest.swift
//  
//
//  
//

import Foundation
import XCTest

@testable import NetworkComponents

/// Person ubclass of JsonModel
/// - Note: JSON properties are defined with private (set) to
/// prevent them from being change outside of this class.
/// Use lazy initialization so that the self.defineProperty
/// method can be called. Plus, if a property is not referenced
/// during the lifetime of the model, it will not be created.
private class JsPersonModel: JsonModel {
    private (set) lazy var firstName: JsonProperty<NSString> = defineProperty("firstName")
    private (set) lazy var lastName: JsonProperty<NSString> = defineProperty("lastName")
    private (set) lazy var age: JsonProperty<NSNumber> = defineProperty("age")
    private (set) lazy var relative: JsonProperty<JsPersonModel> = defineProperty("relative")
    private (set) lazy var children: JsonArrayProperty<JsPersonModel> = defineArrayProperty("children")
}

final class JsonModelTest: XCTestCase {

    var modelDidChangeCount: Int = 0

    /**
      Test identity with JSON serialization and equality
     */
    func testIdentity() throws {
        // Create first person
        let person = JsPersonModel()
        person.firstName.nativeValue = "John"
        person.lastName.nativeValue = "Doe"
        person.age.nativeValue = 21

        // Create second person with same properties
        let person2 = JsPersonModel()
        person2.firstName.nativeValue = person.firstName.nativeValue
        person2.lastName.nativeValue = person.lastName.nativeValue
        person2.age.nativeValue = person.age.nativeValue

        // Person 1 and 2 should be equal
        XCTAssertEqual(person, person2)

        // Build a 3rd person using the JSON from person 1
        let personJson = person.toJsonString()
        XCTAssertNotNil(personJson)

        // The 3rd person properties should be set the same as 1st person
        let person3 = try JsPersonModel(with: personJson)
        XCTAssertEqual(person.firstName.nativeValue, person3.firstName.nativeValue)
        XCTAssertEqual(person.lastName.nativeValue, person3.lastName.nativeValue)
        XCTAssertEqual(person.age.nativeValue, person3.age.nativeValue)

        // They all should be equal
        XCTAssertEqual(person, person3)
        XCTAssertEqual(person2, person3)

        // Equivalent persons should have the same hash
        XCTAssertEqual(person.hash, person2.hash)
        XCTAssertEqual(person2.hash, person3.hash)

        // This verifies that the persons don't share the
        // same backing dictionary
        person.age.nativeValue = 1
        person2.age.nativeValue = 2
        person3.age.nativeValue = 3
        XCTAssertNotEqual(person, person2)
        XCTAssertNotEqual(person, person3)
        XCTAssertNotEqual(person2, person3)
    }

    /**
     Test concentrating on just equality
     */
    func testEquality () throws {
        let john: JsPersonModel = try JsonModel.fromJsonString("{\"firstName\":\"John\", \"lastName\":\"Smith\", " +
            "\"age\":100}")
        let jane: JsPersonModel = try JsonModel.fromJsonString("{\"firstName\":\"Jane\", \"lastName\":\"Doe\", " +
            "\"age\":101}")

        XCTAssertNotEqual(john, jane)

        let someone = JsPersonModel()
        XCTAssertEqual(someone, someone)

        someone.firstName.nativeValue = john.firstName.nativeValue
        someone.lastName.nativeValue = john.lastName.nativeValue
        XCTAssertNotEqual(john, someone)
        XCTAssertNotEqual(john.hash, someone.hash)

        someone.age.nativeValue = john.age.nativeValue
        XCTAssertEqual(john, someone)
        XCTAssertEqual(john.hash, someone.hash)

        someone.relative.nativeValue = jane
        XCTAssertNotEqual(john, someone)

        john.relative.nativeValue = jane
        XCTAssertEqual(john, someone)

        jane.age.nativeValue = 35
        XCTAssertEqual(john, someone)

        john.relative.nativeValue = JsPersonModel(jane)
        XCTAssertFalse(john.relative.nativeValue === jane)
        XCTAssertEqual(john, someone)

        jane.age.nativeValue = 36
        XCTAssertNotEqual(john, someone)
        XCTAssertTrue(someone.relative.nativeValue === jane)
        XCTAssertEqual(john.relative.nativeValue?.age.nativeValue, 35)
        XCTAssertEqual(someone.relative.nativeValue?.age.nativeValue, 36)
    }

    /**
     Test on model relationship with contained models
     */
    func testRelationIdentity() throws {
        let john: JsPersonModel = try JsonModel.fromJsonString("{\"firstName\":\"John\", " +
            "\"lastName\":\"Smith\", \"age\":100}")
        let jane: JsPersonModel = try JsonModel.fromJsonString("{\"firstName\":\"Jane\", \"lastName\":\"Doe\", " +
            "\"age\":101}")

        john.relative.nativeValue = jane

        let johnJson = john.toJsonString()
        XCTAssertNotNil(johnJson)
        guard let aJohnJson = johnJson else {
            XCTFail("johnJson is nil")
            return
        }

        guard let janeJson = jane.toJsonString() else {
            XCTFail("janeJson equals nil")
            return
        }
        XCTAssertNotNil(janeJson)
        guard let containResult = johnJson?.contains(janeJson) else {
            XCTFail("johnJson?.contains(janeJson) equals nil")
            return
        }

        XCTAssertTrue(containResult)

        let johnJane = try JsPersonModel(with: aJohnJson)
        let johnJaneJson = johnJane.toJsonString()
        XCTAssertNotNil(johnJaneJson)
        XCTAssertEqual(johnJaneJson, johnJson)

        XCTAssertNotNil(johnJane.relative.nativeValue)
        let relativeJson = johnJane.relative.nativeValue?.toJsonString()
        XCTAssertNotNil(relativeJson)
        XCTAssertEqual(relativeJson, janeJson)
    }

    /**
     Test on model that owns array of other models
     */
    func testChildren() throws {
        let johnJson = "{\"firstName\":\"John\", \"lastName\":\"Smith\", \"age\":100, " +
            "\"children\":[{\"firstName\":\"Jimmy\", \"lastName\":\"Smith\", \"age\":10}, " +
            "{\"firstName\":\"jenifer\", \"lastName\":\"Smith\", \"age\":15}]}"
        let john: JsPersonModel = try JsonModel.fromJsonString(johnJson)

        // Verify that John's children were deserialized
        XCTAssertNotNil(john.children.nativeValue)
        XCTAssertFalse(john.children.isEmpty)
        XCTAssertEqual(john.children.nativeValue?.count, 2)
        XCTAssertEqual(john.children.count, john.children.nativeValue?.count)

        // Add Jill as another child of John
        let jillJson = "{\"firstName\":\"Jill\", \"lastName\":\"Smith\", \"age\":2}"
        let jill: JsPersonModel = try JsonModel.fromJsonString(jillJson)
        john.children.add(jill)

        // Array count can be access at property (for convenience) or at property value
        XCTAssertEqual(john.children.nativeValue?.count, 3)
        XCTAssertEqual(john.children.count, john.children.nativeValue?.count)

        // JohnClone should be equal to original John
        let johnClone: JsPersonModel = try JsonModel.fromJsonString(john.toJsonString())
        XCTAssertEqual(johnClone, john)
        XCTAssertEqual(johnClone.hash, john.hash)

        // Should beable to remove Jill from John even with a clone of Jill
        let jillClone: JsPersonModel = try JsonModel.fromJsonString(jill.toJsonString())
        XCTAssertEqual(jill, jillClone)
        john.children.remove(jillClone)
        XCTAssertEqual(john.children.nativeValue?.count, 2)
        XCTAssertEqual(john.children.count, john.children.nativeValue?.count)

        // JohnClone is now different from John
        XCTAssertNotEqual(johnClone, john)
    }

    /**
      Test model did change notification
     */
    func testModelDidChangeNOtification() {
        let person = JsPersonModel()

        person.addDidChangeObserver(self, handler: #selector(modelDidChange))
        modelDidChangeCount = 0

        person.firstName.nativeValue = "John"
        person.lastName.nativeValue = "Doe"

        // beginEdit will cache a copy of the model current backing dictionary
        person.beginEdit()
        XCTAssertEqual(modelDidChangeCount, 0)
        person.firstName.nativeValue = "Jane"
        person.lastName.nativeValue = "Smith"

        // endEdit with no commit will restore the cached dictionary and
        // throw away the modified backing dictionary
        person.endEdit(false)
        XCTAssertEqual(modelDidChangeCount, 0)
        XCTAssertEqual(person.firstName.nativeValue, "John")
        XCTAssertEqual(person.lastName.nativeValue, "Doe")

        // beginedit
        person.beginEdit()
        XCTAssertEqual(modelDidChangeCount, 0)
        person.firstName.nativeValue = "Jane"
        person.lastName.nativeValue = "Smith"

        // endEdit with commit will keep the modified original backing
        // dictionary and throw away the saved copy
        person.endEdit(true)
        XCTAssertEqual(modelDidChangeCount, 1)
        XCTAssertEqual(person.firstName.nativeValue, "Jane")
        XCTAssertEqual(person.lastName.nativeValue, "Smith")

        // Test removing a previously added observer
        modelDidChangeCount = 0
        person.removeDidChangeObserver(self)

        person.beginEdit()
        XCTAssertEqual(modelDidChangeCount, 0)
        person.firstName.nativeValue = "John"
        person.lastName.nativeValue = "Doe"
        XCTAssertEqual(modelDidChangeCount, 0)

        // Committing the change will not result in a notiication
        person.endEdit(true)
        XCTAssertEqual(modelDidChangeCount, 0)
        XCTAssertEqual(person.firstName.nativeValue, "John")
        XCTAssertEqual(person.lastName.nativeValue, "Doe")
    }

    /**
     * Test multi-level edit behavior
     */
    // swiftlint:disable:Body_length
    func testModelRelativeDidChangeNOtification() {
        let john = createPerson(first: "John", last: "Doe")
        let jane = createPerson(first: "Jane", last: "Smith")

        john.addDidChangeObserver(self, handler: #selector(modelDidChange))
        modelDidChangeCount = 0
        john.beginEdit()

        // John is modified by committing the edit
        john.relative.nativeValue = jane
        john.endEdit(true)
        XCTAssertEqual(modelDidChangeCount, 1)
        XCTAssertEqual(john.relative.nativeValue, jane)

        // The instance of jane is referenced by the relative
        // property of John
        jane.lastName.nativeValue = "Doe"
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Doe")
        john.relative.nativeValue?.lastName.nativeValue = "Smith"
        XCTAssertEqual(jane.lastName.nativeValue, "Smith")

        // Editing the instance of Jane is the same as
        // editing John.relative. They are still the same instance
        jane.addDidChangeObserver(self, handler: #selector(modelDidChange))
        jane.beginEdit()
        jane.lastName.nativeValue = "Doe"
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Doe")

        jane.endEdit(true)
        XCTAssertEqual(modelDidChangeCount, 2)
        john.relative.nativeValue?.lastName.nativeValue = "Smith"
        XCTAssertEqual(jane.lastName.nativeValue, "Smith")

        // edit but not commit Jane does not affect John's reference to Jane
        modelDidChangeCount = 0
        jane.beginEdit()
        jane.lastName.nativeValue = "Doe"
        jane.endEdit(false)
        XCTAssertEqual(modelDidChangeCount, 0)
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Smith")
        XCTAssertEqual(john.relative.nativeValue, jane)

        // John still is referencing Jane
        jane.lastName.nativeValue = "Doe"
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Doe")

        john.beginEdit()
        jane.beginEdit()
        jane.lastName.nativeValue = "Smith"
        jane.endEdit(true)
        XCTAssertEqual(modelDidChangeCount, 1)
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Smith")
        XCTAssertEqual(john.relative.nativeValue, jane)

        // By not committing the edit for John, Jane is now orphaned
        // and John holds a new instance of person with the old
        // property values for Jane
        john.endEdit(false)
        XCTAssertEqual(modelDidChangeCount, 1)
        XCTAssertEqual(jane.lastName.nativeValue, "Smith")
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Doe")
        XCTAssertNotEqual(john.relative.nativeValue, jane)

        modelDidChangeCount = 0
        john.relative.nativeValue?.addDidChangeObserver(self, handler: #selector(modelDidChange))
        john.beginEdit()
        john.relative.nativeValue?.beginEdit()

        john.relative.nativeValue?.lastName.nativeValue = "Smith"
        john.relative.nativeValue?.endEdit(true)
        john.endEdit(true)
        XCTAssertEqual(modelDidChangeCount, 2)
        XCTAssertEqual(jane.lastName.nativeValue, "Smith")
        XCTAssertEqual(john.relative.nativeValue?.lastName.nativeValue, "Smith")
        XCTAssertEqual(john.relative.nativeValue, jane)
    }

    func testJsonDictionaryProperty() throws {
        let model: JsPersonModel = try JsonModel.fromJsonString("{\"child\": {}, \"dictionary\": {}}")

        XCTAssertTrue(model.dictionary.value(forKeyPath: "child") is NSDictionary)
        XCTAssertTrue(model.dictionary.value(forKeyPath: "dictionary") is NSDictionary)

        // Dictionary entry can be mapped to JsonModel
        let child: JsonProperty<JsonModel> = model.defineProperty("child")

        if let childName: JsonProperty<NSString> = child.nativeValue?.defineProperty("name") {
            childName.nativeValue = "child name"

            // Dynamically add child name property
            XCTAssertEqual(childName.dictionary?.value(forKeyPath: "name") as? NSString, "child name")
            XCTAssertEqual(model.dictionary?.value(forKeyPath: "child.name") as? NSString, "child name")
        } else {
            XCTFail("Failed to create child.name")
        }
        // Dictionary can be access natively too
        let dictionary: JsonProperty<NSDictionary> = model.defineProperty("dictionary")
        XCTAssertNotNil(dictionary.nativeValue)
    }

    fileprivate func createPerson(first: NSString, last: NSString) -> JsPersonModel {
        let person = JsPersonModel()

        person.firstName.nativeValue = first
        person.lastName.nativeValue = last

        return person
    }

    func modelDidChange() {
        self.modelDidChangeCount += 1
    }
}

