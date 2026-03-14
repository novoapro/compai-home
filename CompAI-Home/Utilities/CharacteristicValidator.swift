import Foundation

/// Validates values against characteristic metadata before writing to HomeKit.
/// Provides clear, human-readable error messages describing what went wrong.
enum CharacteristicValidator {

    struct ValidationError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Validates that `value` is appropriate for the given characteristic.
    /// Throws `ValidationError` with a descriptive message if validation fails.
    static func validate(value: Any, against characteristic: CharacteristicModel) throws {
        let name = CharacteristicTypes.displayName(for: characteristic.type)

        // 1. Check write permission
        guard characteristic.permissions.contains("write") else {
            throw ValidationError(message: "\(name) is read-only")
        }

        // 2. Validate by format
        switch characteristic.format {
        case "bool":
            try validateBool(value, name: name)

        case "int", "uint8", "uint16", "uint32", "uint64":
            let numericValue = try validateInteger(value, name: name)
            try validateValidValues(numericValue, characteristic: characteristic, name: name)
            try validateRange(Double(numericValue), characteristic: characteristic, name: name)

        case "float":
            let numericValue = try validateFloat(value, name: name)
            try validateRange(numericValue, characteristic: characteristic, name: name)

        case "string":
            guard value is String else {
                throw ValidationError(message: "\(name) expects a string value")
            }

        default:
            // Unknown format — skip validation, let HomeKit handle it
            break
        }
    }

    // MARK: - Type Validators

    private static func validateBool(_ value: Any, name: String) throws {
        if value is Bool { return }
        if let num = value as? Int, num == 0 || num == 1 { return }
        if let num = value as? Double, num == 0 || num == 1 { return }
        if let str = value as? String {
            let lower = str.lowercased()
            if lower == "true" || lower == "false" || lower == "0" || lower == "1" { return }
        }
        throw ValidationError(message: "\(name) expects a boolean value (true/false)")
    }

    private static func validateInteger(_ value: Any, name: String) throws -> Int {
        if let intVal = value as? Int { return intVal }
        if let doubleVal = value as? Double {
            guard doubleVal == doubleVal.rounded() else {
                throw ValidationError(message: "\(name) expects an integer value, got \(doubleVal)")
            }
            return Int(doubleVal)
        }
        if let strVal = value as? String, let intVal = Int(strVal) { return intVal }
        throw ValidationError(message: "\(name) expects an integer value")
    }

    private static func validateFloat(_ value: Any, name: String) throws -> Double {
        if let doubleVal = value as? Double { return doubleVal }
        if let intVal = value as? Int { return Double(intVal) }
        if let strVal = value as? String, let doubleVal = Double(strVal) { return doubleVal }
        throw ValidationError(message: "\(name) expects a numeric value")
    }

    // MARK: - Constraint Validators

    private static func validateValidValues(_ value: Int, characteristic: CharacteristicModel, name: String) throws {
        guard let validValues = characteristic.validValues, !validValues.isEmpty else { return }
        guard validValues.contains(value) else {
            let options = CharacteristicInputConfig.buildPickerOptions(for: characteristic.type, values: validValues)
            let optionsList = options.map { "\($0.value) (\($0.label))" }.joined(separator: ", ")
            throw ValidationError(message: "\(name) must be one of: \(optionsList)")
        }
    }

    private static func validateRange(_ value: Double, characteristic: CharacteristicModel, name: String) throws {
        if let min = characteristic.minValue, value < min {
            let minStr = min == min.rounded() ? "\(Int(min))" : "\(min)"
            let maxStr = characteristic.maxValue.map { $0 == $0.rounded() ? "\(Int($0))" : "\($0)" } ?? "?"
            throw ValidationError(message: "\(name) must be between \(minStr) and \(maxStr), got \(value == value.rounded() ? "\(Int(value))" : "\(value)")")
        }
        if let max = characteristic.maxValue, value > max {
            let minStr = characteristic.minValue.map { $0 == $0.rounded() ? "\(Int($0))" : "\($0)" } ?? "?"
            let maxStr = max == max.rounded() ? "\(Int(max))" : "\(max)"
            throw ValidationError(message: "\(name) must be between \(minStr) and \(maxStr), got \(value == value.rounded() ? "\(Int(value))" : "\(value)")")
        }
    }
}
