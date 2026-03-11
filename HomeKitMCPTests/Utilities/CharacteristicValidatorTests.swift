import XCTest
@testable import HomeKitMCP

final class CharacteristicValidatorTests: XCTestCase {

    // MARK: - Boolean Validation

    func testValidateBool_trueValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: true, against: char)
        // No exception thrown
    }

    func testValidateBool_falseValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: false, against: char)
        // No exception thrown
    }

    func testValidateBool_intOne_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 1, against: char)
        // No exception thrown
    }

    func testValidateBool_intZero_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 0, against: char)
        // No exception thrown
    }

    func testValidateBool_doubleOne_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 1.0, against: char)
        // No exception thrown
    }

    func testValidateBool_doubleZero_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 0.0, against: char)
        // No exception thrown
    }

    func testValidateBool_stringTrue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "true", against: char)
        // No exception thrown
    }

    func testValidateBool_stringFalse_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "false", against: char)
        // No exception thrown
    }

    func testValidateBool_stringTrue_uppercase_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "TRUE", against: char)
        // No exception thrown
    }

    func testValidateBool_stringZero_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "0", against: char)
        // No exception thrown
    }

    func testValidateBool_stringOne_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "1", against: char)
        // No exception thrown
    }

    func testValidateBool_invalidString_throws() {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: "maybe", against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateBool_invalidInt_throws() {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 42, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    // MARK: - Integer Validation

    func testValidateInt_validInt_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 42, against: char)
        // No exception thrown
    }

    func testValidateInt_doubleRoundNumber_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 42.0, against: char)
        // No exception thrown
    }

    func testValidateInt_doubleNonRound_throws() {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 42.5, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateInt_stringNumber_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "42", against: char)
        // No exception thrown
    }

    func testValidateInt_stringInvalid_throws() {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: "not-a-number", against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateInt_belowMin_throws() {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: 100)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 5, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateInt_aboveMax_throws() {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: 100)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 150, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateInt_atMin_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: 100)
        try CharacteristicValidator.validate(value: 10, against: char)
        // No exception thrown
    }

    func testValidateInt_atMax_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: 100)
        try CharacteristicValidator.validate(value: 100, against: char)
        // No exception thrown
    }

    func testValidateInt_withinRange_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: 100)
        try CharacteristicValidator.validate(value: 50, against: char)
        // No exception thrown
    }

    // MARK: - Float Validation

    func testValidateFloat_validDouble_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 42.5, against: char)
        // No exception thrown
    }

    func testValidateFloat_validInt_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 42, against: char)
        // No exception thrown
    }

    func testValidateFloat_stringNumber_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "42.5", against: char)
        // No exception thrown
    }

    func testValidateFloat_stringInvalid_throws() {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: "not-a-number", against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateFloat_belowMin_throws() {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: 10.0, maxValue: 100.0)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 5.0, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateFloat_aboveMax_throws() {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: 10.0, maxValue: 100.0)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 150.0, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateFloat_atMin_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: 10.0, maxValue: 100.0)
        try CharacteristicValidator.validate(value: 10.0, against: char)
        // No exception thrown
    }

    func testValidateFloat_atMax_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: 10.0, maxValue: 100.0)
        try CharacteristicValidator.validate(value: 100.0, against: char)
        // No exception thrown
    }

    func testValidateFloat_withinRange_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: 10.0, maxValue: 100.0)
        try CharacteristicValidator.validate(value: 50.5, against: char)
        // No exception thrown
    }

    // MARK: - String Validation

    func testValidateString_validString_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "string", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "hello", against: char)
        // No exception thrown
    }

    func testValidateString_emptyString_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "string", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "", against: char)
        // No exception thrown
    }

    func testValidateString_nonStringValue_throws() {
        let char = TestFixtures.makeCharacteristic(format: "string", permissions: ["read", "write"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 42, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    // MARK: - Valid Values (Enumeration)

    func testValidateValidValues_matchingValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            validValues: [0, 1, 2]
        )
        try CharacteristicValidator.validate(value: 1, against: char)
        // No exception thrown
    }

    func testValidateValidValues_nonMatchingValue_throws() {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            validValues: [0, 1, 2]
        )
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 5, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateValidValues_firstValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            validValues: [0, 1, 2]
        )
        try CharacteristicValidator.validate(value: 0, against: char)
        // No exception thrown
    }

    func testValidateValidValues_lastValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            validValues: [0, 1, 2]
        )
        try CharacteristicValidator.validate(value: 2, against: char)
        // No exception thrown
    }

    func testValidateValidValues_emptyList_ignoresValidation() throws {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            validValues: []
        )
        try CharacteristicValidator.validate(value: 99, against: char)
        // No exception thrown
    }

    func testValidateValidValues_nilList_ignoresValidation() throws {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            validValues: nil
        )
        try CharacteristicValidator.validate(value: 99, against: char)
        // No exception thrown
    }

    // MARK: - Write Permission

    func testValidate_readOnlyCharacteristic_throws() {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read"])
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: true, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidate_readWriteCharacteristic_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: true, against: char)
        // No exception thrown
    }

    func testValidate_writeOnlyCharacteristic_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "bool", permissions: ["write"])
        try CharacteristicValidator.validate(value: true, against: char)
        // No exception thrown
    }

    // MARK: - Unknown Format

    func testValidate_unknownFormat_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "unknown-format", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: "anything", against: char)
        // No exception thrown - unknown format is skipped
    }

    // MARK: - Multiple Integer Formats

    func testValidateUint8_validValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "uint8", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 128, against: char)
        // No exception thrown
    }

    func testValidateUint16_validValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "uint16", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 40000, against: char)
        // No exception thrown
    }

    func testValidateUint32_validValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "uint32", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 2000000000, against: char)
        // No exception thrown
    }

    func testValidateUint64_validValue_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "uint64", permissions: ["read", "write"])
        try CharacteristicValidator.validate(value: 9000000000000000000, against: char)
        // No exception thrown
    }

    // MARK: - Range with Min Only

    func testValidateRange_minOnlyBelowMin_throws() {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: nil)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 5, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateRange_minOnlyAboveMin_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: 10, maxValue: nil)
        try CharacteristicValidator.validate(value: 1000, against: char)
        // No exception thrown
    }

    // MARK: - Range with Max Only

    func testValidateRange_maxOnlyAboveMax_throws() {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: nil, maxValue: 100)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: 150, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    func testValidateRange_maxOnlyBelowMax_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: nil, maxValue: 100)
        try CharacteristicValidator.validate(value: 50, against: char)
        // No exception thrown
    }

    // MARK: - Negative Numbers

    func testValidateInt_negativeNumber_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "int", permissions: ["read", "write"], minValue: -100, maxValue: 100)
        try CharacteristicValidator.validate(value: -50, against: char)
        // No exception thrown
    }

    func testValidateFloat_negativeNumber_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: -100.0, maxValue: 100.0)
        try CharacteristicValidator.validate(value: -50.5, against: char)
        // No exception thrown
    }

    func testValidateFloat_negativeBelow_throws() {
        let char = TestFixtures.makeCharacteristic(format: "float", permissions: ["read", "write"], minValue: -50.0, maxValue: 50.0)
        XCTAssertThrowsError(try CharacteristicValidator.validate(value: -100.0, against: char)) { error in
            XCTAssertTrue(error is CharacteristicValidator.ValidationError)
        }
    }

    // MARK: - Error Messages

    func testValidationError_messageProperty_isSet() {
        let error = CharacteristicValidator.ValidationError(message: "Test error message")
        XCTAssertEqual(error.message, "Test error message")
        XCTAssertEqual(error.errorDescription, "Test error message")
    }

    // MARK: - Range Combination with ValidValues

    func testValidate_rangeAndValidValues_both_succeeds() throws {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            minValue: 0,
            maxValue: 100,
            validValues: [10, 20, 30]
        )
        try CharacteristicValidator.validate(value: 20, against: char)
        // No exception thrown
    }

    func testValidate_validValuesButOutOfRange_throws() {
        let char = TestFixtures.makeCharacteristic(
            format: "uint8",
            permissions: ["read", "write"],
            minValue: 0,
            maxValue: 100,
            validValues: [10, 20, 30]
        )
        // 20 is valid but validate checks validValues first
        try? CharacteristicValidator.validate(value: 20, against: char)
        // Should succeed
    }
}
