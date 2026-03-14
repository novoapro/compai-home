import XCTest
 import CompAI_Home

final class AutomationModelsTests: XCTestCase {

    // MARK: - ConcurrentExecutionPolicy

    func testConcurrentExecutionPolicy_ignoreNew_rawValue() {
        let policy = ConcurrentExecutionPolicy.ignoreNew
        XCTAssertEqual(policy.rawValue, "ignoreNew")
    }

    func testConcurrentExecutionPolicy_cancelAndRestart_rawValue() {
        let policy = ConcurrentExecutionPolicy.cancelAndRestart
        XCTAssertEqual(policy.rawValue, "cancelAndRestart")
    }

    func testConcurrentExecutionPolicy_queueAndExecute_rawValue() {
        let policy = ConcurrentExecutionPolicy.queueAndExecute
        XCTAssertEqual(policy.rawValue, "queueAndExecute")
    }

    func testConcurrentExecutionPolicy_cancelOnly_rawValue() {
        let policy = ConcurrentExecutionPolicy.cancelOnly
        XCTAssertEqual(policy.rawValue, "cancelOnly")
    }

    func testConcurrentExecutionPolicy_allCasesCount() {
        let allCases = ConcurrentExecutionPolicy.allCases
        XCTAssertEqual(allCases.count, 4)
    }

    func testConcurrentExecutionPolicy_displayNames() {
        XCTAssertEqual(ConcurrentExecutionPolicy.ignoreNew.displayName, "Ignore trigger")
        XCTAssertEqual(ConcurrentExecutionPolicy.cancelAndRestart.displayName, "Restart automation")
        XCTAssertEqual(ConcurrentExecutionPolicy.queueAndExecute.displayName, "Queue new execution")
        XCTAssertEqual(ConcurrentExecutionPolicy.cancelOnly.displayName, "Cancel automation")
    }

    func testConcurrentExecutionPolicy_id() {
        let policy = ConcurrentExecutionPolicy.ignoreNew
        XCTAssertEqual(policy.id, "ignoreNew")
    }

    // MARK: - Automation Codable

    func testAutomation_encodeDecode_roundTrip() throws {
        let automation = Automation(
            id: UUID(),
            name: "Test Automation",
            description: "A test automation",
            isEnabled: true,
            triggers: [],
            conditions: nil,
            blocks: [],
            continueOnError: false,
            retriggerPolicy: .ignoreNew,
            metadata: .empty,
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(automation)

        let decoder = JSONDecoder()
        let decodedAutomation = try decoder.decode(Automation.self, from: data)

        XCTAssertEqual(decodedAutomation.id, automation.id)
        XCTAssertEqual(decodedAutomation.name, automation.name)
        XCTAssertEqual(decodedAutomation.description, automation.description)
        XCTAssertEqual(decodedAutomation.isEnabled, automation.isEnabled)
        XCTAssertEqual(decodedAutomation.continueOnError, automation.continueOnError)
        XCTAssertEqual(decodedAutomation.retriggerPolicy, automation.retriggerPolicy)
    }

    func testAutomation_decodeMissingRetriggerPolicy_defaultsToIgnoreNew() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "Test",
            "isEnabled": true,
            "triggers": [],
            "blocks": [],
            "continueOnError": false,
            "metadata": {},
            "createdAt": "2024-01-01T00:00:00Z",
            "updatedAt": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let automation = try decoder.decode(Automation.self, from: json)

        XCTAssertEqual(automation.retriggerPolicy, .ignoreNew)
    }

    func testAutomation_init_default_retriggerPolicy() {
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: []
        )

        XCTAssertEqual(automation.retriggerPolicy, .ignoreNew)
    }

    func testAutomation_init_custom_retriggerPolicy() {
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: [],
            retriggerPolicy: .cancelAndRestart
        )

        XCTAssertEqual(automation.retriggerPolicy, .cancelAndRestart)
    }

    // MARK: - Automation Properties

    func testAutomation_identifier() {
        let id = UUID()
        let automation = Automation(
            id: id,
            name: "Test",
            triggers: [],
            blocks: []
        )

        XCTAssertEqual(automation.id, id)
    }

    func testAutomation_name() {
        let automation = Automation(
            name: "My Automation",
            triggers: [],
            blocks: []
        )

        XCTAssertEqual(automation.name, "My Automation")
    }

    func testAutomation_description() {
        let automation = Automation(
            name: "Test",
            description: "A detailed description",
            triggers: [],
            blocks: []
        )

        XCTAssertEqual(automation.description, "A detailed description")
    }

    func testAutomation_isEnabled_default() {
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: []
        )

        XCTAssertTrue(automation.isEnabled)
    }

    func testAutomation_isEnabled_disabled() {
        let automation = Automation(
            name: "Test",
            isEnabled: false,
            triggers: [],
            blocks: []
        )

        XCTAssertFalse(automation.isEnabled)
    }

    func testAutomation_continueOnError_default() {
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: []
        )

        XCTAssertFalse(automation.continueOnError)
    }

    func testAutomation_continueOnError_true() {
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: [],
            continueOnError: true
        )

        XCTAssertTrue(automation.continueOnError)
    }

    // MARK: - Automation Triggers

    func testAutomationTrigger_codable_roundTrip() throws {
        let trigger = AutomationTrigger.manualTrigger(name: "Test Manual")

        let encoder = JSONEncoder()
        let data = try encoder.encode(trigger)

        let decoder = JSONDecoder()
        let decodedTrigger = try decoder.decode(AutomationTrigger.self, from: data)

        // Compare by encoding both
        let reEncodedData = try encoder.encode(decodedTrigger)
        XCTAssertEqual(data, reEncodedData)
    }

    // MARK: - Automation Conditions

    func testAutomationCondition_timeCondition_codable() throws {
        let condition = AutomationCondition.timeCondition(
            TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 9, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 17, minute: 0)))
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(AutomationCondition.self, from: data)

        // Both should encode the same
        let reEncodedData = try encoder.encode(decodedCondition)
        XCTAssertEqual(data, reEncodedData)
    }

    func testAutomationCondition_and_codable() throws {
        let condition = AutomationCondition.and([
            .timeCondition(TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 9, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 17, minute: 0))))
        ])

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(AutomationCondition.self, from: data)

        let reEncodedData = try encoder.encode(decodedCondition)
        XCTAssertEqual(data, reEncodedData)
    }

    func testAutomationCondition_or_codable() throws {
        let condition = AutomationCondition.or([
            .timeCondition(TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 9, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 17, minute: 0))))
        ])

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(AutomationCondition.self, from: data)

        let reEncodedData = try encoder.encode(decodedCondition)
        XCTAssertEqual(data, reEncodedData)
    }

    func testAutomationCondition_not_codable() throws {
        let condition = AutomationCondition.not(
            .timeCondition(TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 9, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 17, minute: 0))))
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(AutomationCondition.self, from: data)

        let reEncodedData = try encoder.encode(decodedCondition)
        XCTAssertEqual(data, reEncodedData)
    }

    // MARK: - Automation Blocks

    func testAutomationBlock_action_codable() throws {
        let action = AutomationAction.delay(delaySeconds: 5)
        let block = AutomationBlock.action(action, blockId: UUID())

        let encoder = JSONEncoder()
        let data = try encoder.encode(block)

        let decoder = JSONDecoder()
        let decodedBlock = try decoder.decode(AutomationBlock.self, from: data)

        let reEncodedData = try encoder.encode(decodedBlock)
        XCTAssertEqual(data, reEncodedData)
    }

    func testAutomationBlock_flowControl_codable() throws {
        let flowControl = FlowControlBlock.delay(delaySeconds: 5, name: "Wait")
        let block = AutomationBlock.flowControl(flowControl, blockId: UUID())

        let encoder = JSONEncoder()
        let data = try encoder.encode(block)

        let decoder = JSONDecoder()
        let decodedBlock = try decoder.decode(AutomationBlock.self, from: data)

        let reEncodedData = try encoder.encode(decodedBlock)
        XCTAssertEqual(data, reEncodedData)
    }

    // MARK: - Comparison Operators

    func testComparisonOperator_equals_codable() throws {
        let comparison = ComparisonOperator.equals(AnyCodable(42))

        let encoder = JSONEncoder()
        let data = try encoder.encode(comparison)

        let decoder = JSONDecoder()
        let decodedComparison = try decoder.decode(ComparisonOperator.self, from: data)

        let reEncodedData = try encoder.encode(decodedComparison)
        XCTAssertEqual(data, reEncodedData)
    }

    func testComparisonOperator_notEquals_codable() throws {
        let comparison = ComparisonOperator.notEquals(AnyCodable("test"))

        let encoder = JSONEncoder()
        let data = try encoder.encode(comparison)

        let decoder = JSONDecoder()
        let decodedComparison = try decoder.decode(ComparisonOperator.self, from: data)

        let reEncodedData = try encoder.encode(decodedComparison)
        XCTAssertEqual(data, reEncodedData)
    }

    func testComparisonOperator_greaterThan_codable() throws {
        let comparison = ComparisonOperator.greaterThan(100.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(comparison)

        let decoder = JSONDecoder()
        let decodedComparison = try decoder.decode(ComparisonOperator.self, from: data)

        let reEncodedData = try encoder.encode(decodedComparison)
        XCTAssertEqual(data, reEncodedData)
    }

    func testComparisonOperator_lessThan_codable() throws {
        let comparison = ComparisonOperator.lessThan(50.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(comparison)

        let decoder = JSONDecoder()
        let decodedComparison = try decoder.decode(ComparisonOperator.self, from: data)

        let reEncodedData = try encoder.encode(decodedComparison)
        XCTAssertEqual(data, reEncodedData)
    }

    func testComparisonOperator_greaterThanOrEqual_codable() throws {
        let comparison = ComparisonOperator.greaterThanOrEqual(75.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(comparison)

        let decoder = JSONDecoder()
        let decodedComparison = try decoder.decode(ComparisonOperator.self, from: data)

        let reEncodedData = try encoder.encode(decodedComparison)
        XCTAssertEqual(data, reEncodedData)
    }

    func testComparisonOperator_lessThanOrEqual_codable() throws {
        let comparison = ComparisonOperator.lessThanOrEqual(25.0)

        let encoder = JSONEncoder()
        let data = try encoder.encode(comparison)

        let decoder = JSONDecoder()
        let decodedComparison = try decoder.decode(ComparisonOperator.self, from: data)

        let reEncodedData = try encoder.encode(decodedComparison)
        XCTAssertEqual(data, reEncodedData)
    }

    // MARK: - Time Condition

    func testTimeCondition_timeRange_codable() throws {
        let condition = TimeCondition(
            mode: .timeRange,
            startTime: TimePoint.fixed(TimeOfDay(hour: 9, minute: 0)),
            endTime: TimePoint.fixed(TimeOfDay(hour: 17, minute: 0))
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(TimeCondition.self, from: data)

        XCTAssertEqual(decodedCondition.mode, condition.mode)
    }

    func testTimeCondition_beforeSunrise() throws {
        let condition = TimeCondition(mode: .beforeSunrise)

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(TimeCondition.self, from: data)

        XCTAssertEqual(decodedCondition.mode, .beforeSunrise)
    }

    func testTimeCondition_daytime() throws {
        let condition = TimeCondition(mode: .daytime)

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)

        let decoder = JSONDecoder()
        let decodedCondition = try decoder.decode(TimeCondition.self, from: data)

        XCTAssertEqual(decodedCondition.mode, .daytime)
    }

    // MARK: - Time Of Day

    func testTimeOfDay_validHour_minute() {
        let tod = TimeOfDay(hour: 14, minute: 30)
        XCTAssertEqual(tod.hour, 14)
        XCTAssertEqual(tod.minute, 30)
    }

    func testTimeOfDay_midnight() {
        let tod = TimeOfDay(hour: 0, minute: 0)
        XCTAssertEqual(tod.hour, 0)
        XCTAssertEqual(tod.minute, 0)
    }

    func testTimeOfDay_endOfDay() {
        let tod = TimeOfDay(hour: 23, minute: 59)
        XCTAssertEqual(tod.hour, 23)
        XCTAssertEqual(tod.minute, 59)
    }

    func testTimeOfDay_totalMinutes() {
        let tod = TimeOfDay(hour: 14, minute: 30)
        XCTAssertEqual(tod.totalMinutes, 14 * 60 + 30)
    }

    func testTimeOfDay_midnight_totalMinutes() {
        let tod = TimeOfDay(hour: 0, minute: 0)
        XCTAssertEqual(tod.totalMinutes, 0)
    }

    func testTimeOfDay_noon_totalMinutes() {
        let tod = TimeOfDay(hour: 12, minute: 0)
        XCTAssertEqual(tod.totalMinutes, 12 * 60)
    }

    // MARK: - AnyCodable (Type Preservation)

    func testAnyCodable_int_preservesType() throws {
        let value = AnyCodable(42)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? Int, 42)
    }

    func testAnyCodable_string_preservesType() throws {
        let value = AnyCodable("test")
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? String, "test")
    }

    func testAnyCodable_double_preservesType() throws {
        let value = AnyCodable(42.5)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? Double, 42.5)
    }

    func testAnyCodable_bool_preservesType() throws {
        let value = AnyCodable(true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? Bool, true)
    }

    // MARK: - Automation Metadata

    func testAutomationMetadata_empty() {
        let metadata = AutomationMetadata.empty
        XCTAssertNotNil(metadata)
    }

    func testAutomationMetadata_codable() throws {
        let metadata = AutomationMetadata.empty

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        let decodedMetadata = try decoder.decode(AutomationMetadata.self, from: data)

        let reEncodedData = try encoder.encode(decodedMetadata)
        XCTAssertEqual(data, reEncodedData)
    }

    // MARK: - Automation Timestamps

    func testAutomation_createdAt_preserved() {
        let now = Date()
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: [],
            createdAt: now
        )

        XCTAssertEqual(automation.createdAt, now)
    }

    func testAutomation_updatedAt_preserved() {
        let now = Date()
        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: [],
            updatedAt: now
        )

        XCTAssertEqual(automation.updatedAt, now)
    }

    func testAutomation_createdAtBeforeUpdatedAt() {
        let created = Date(timeIntervalSince1970: 0)
        let updated = Date(timeIntervalSince1970: 1000)

        let automation = Automation(
            name: "Test",
            triggers: [],
            blocks: [],
            createdAt: created,
            updatedAt: updated
        )

        XCTAssertLessThan(automation.createdAt, automation.updatedAt)
    }
}
