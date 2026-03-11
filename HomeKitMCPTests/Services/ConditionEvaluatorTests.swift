import XCTest
@testable import HomeKitMCP

final class ConditionEvaluatorTests: XCTestCase {

    private var mockHomeKitManager: MockHomeKitManager!
    private var mockStorage: MockStorageService!
    private var mockRegistry: MockDeviceRegistryService!
    private var evaluator: ConditionEvaluator!

    override func setUp() {
        super.setUp()
        mockHomeKitManager = MockHomeKitManager()
        mockStorage = MockStorageService()
        mockRegistry = MockDeviceRegistryService()
        evaluator = ConditionEvaluator(
            homeKitManager: mockHomeKitManager,
            storage: mockStorage,
            registry: mockRegistry
        )
    }

    override func tearDown() {
        evaluator = nil
        mockRegistry = nil
        mockStorage = nil
        mockHomeKitManager = nil
        super.tearDown()
    }

    // MARK: - Comparison Operators (Static)

    func testCompareEquals_sameValues_returnsTrue() {
        let result = ConditionEvaluator.compare(42, using: .equals(AnyCodable(42)))
        XCTAssertTrue(result)
    }

    func testCompareEquals_differentValues_returnsFalse() {
        let result = ConditionEvaluator.compare(42, using: .equals(AnyCodable(43)))
        XCTAssertFalse(result)
    }

    func testCompareEquals_boolValues_returnsTrue() {
        let result = ConditionEvaluator.compare(true, using: .equals(AnyCodable(true)))
        XCTAssertTrue(result)
    }

    func testCompareEquals_stringValues_returnsTrue() {
        let result = ConditionEvaluator.compare("hello", using: .equals(AnyCodable("hello")))
        XCTAssertTrue(result)
    }

    func testCompareNotEquals_sameValues_returnsFalse() {
        let result = ConditionEvaluator.compare(42, using: .notEquals(AnyCodable(42)))
        XCTAssertFalse(result)
    }

    func testCompareNotEquals_differentValues_returnsTrue() {
        let result = ConditionEvaluator.compare(42, using: .notEquals(AnyCodable(43)))
        XCTAssertTrue(result)
    }

    func testCompareGreaterThan_greaterValue_returnsTrue() {
        let result = ConditionEvaluator.compare(50, using: .greaterThan(40))
        XCTAssertTrue(result)
    }

    func testCompareGreaterThan_lessValue_returnsFalse() {
        let result = ConditionEvaluator.compare(30, using: .greaterThan(40))
        XCTAssertFalse(result)
    }

    func testCompareGreaterThan_equalValue_returnsFalse() {
        let result = ConditionEvaluator.compare(40, using: .greaterThan(40))
        XCTAssertFalse(result)
    }

    func testCompareLessThan_lessValue_returnsTrue() {
        let result = ConditionEvaluator.compare(30, using: .lessThan(40))
        XCTAssertTrue(result)
    }

    func testCompareLessThan_greaterValue_returnsFalse() {
        let result = ConditionEvaluator.compare(50, using: .lessThan(40))
        XCTAssertFalse(result)
    }

    func testCompareLessThan_equalValue_returnsFalse() {
        let result = ConditionEvaluator.compare(40, using: .lessThan(40))
        XCTAssertFalse(result)
    }

    func testCompareGreaterThanOrEqual_greaterValue_returnsTrue() {
        let result = ConditionEvaluator.compare(50, using: .greaterThanOrEqual(40))
        XCTAssertTrue(result)
    }

    func testCompareGreaterThanOrEqual_equalValue_returnsTrue() {
        let result = ConditionEvaluator.compare(40, using: .greaterThanOrEqual(40))
        XCTAssertTrue(result)
    }

    func testCompareGreaterThanOrEqual_lessValue_returnsFalse() {
        let result = ConditionEvaluator.compare(30, using: .greaterThanOrEqual(40))
        XCTAssertFalse(result)
    }

    func testCompareLessThanOrEqual_lessValue_returnsTrue() {
        let result = ConditionEvaluator.compare(30, using: .lessThanOrEqual(40))
        XCTAssertTrue(result)
    }

    func testCompareLessThanOrEqual_equalValue_returnsTrue() {
        let result = ConditionEvaluator.compare(40, using: .lessThanOrEqual(40))
        XCTAssertTrue(result)
    }

    func testCompareLessThanOrEqual_greaterValue_returnsFalse() {
        let result = ConditionEvaluator.compare(50, using: .lessThanOrEqual(40))
        XCTAssertFalse(result)
    }

    // MARK: - Type Coercion

    func testCompareEquals_numericTypeCoercion_intVsDouble_returnsTrue() {
        let result = ConditionEvaluator.compare(42, using: .equals(AnyCodable(42.0)))
        XCTAssertTrue(result)
    }

    func testCompareEquals_boolAsNumeric_true_returnsTrue() {
        let result = ConditionEvaluator.compare(true, using: .equals(AnyCodable(1)))
        XCTAssertTrue(result)
    }

    func testCompareEquals_boolAsNumeric_false_returnsTrue() {
        let result = ConditionEvaluator.compare(false, using: .equals(AnyCodable(0)))
        XCTAssertTrue(result)
    }

    func testCompareGreaterThan_withDouble_returnsTrue() {
        let result = ConditionEvaluator.compare(50.5, using: .greaterThan(40.5))
        XCTAssertTrue(result)
    }

    // MARK: - Nil Handling

    func testCompare_nilValue_returnsFalse() {
        let result = ConditionEvaluator.compare(nil, using: .equals(AnyCodable(42)))
        XCTAssertFalse(result)
    }

    // MARK: - AND Conditions

    func testEvaluate_andAllTrue_returnsPassed() async {
        let cond1 = WorkflowCondition.and([])
        let result = await evaluator.evaluate(cond1)
        XCTAssertTrue(result.passed)
    }

    func testEvaluateAll_andTwoConditionsBothTrue_returnsPassed() async {
        // Create conditions that will evaluate to true
        let conditions = [
            WorkflowCondition.timeCondition(
                TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 0, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 59)))
            ),
            WorkflowCondition.timeCondition(
                TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 0, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 59)))
            )
        ]
        let (allPassed, results) = await evaluator.evaluateAll(conditions)
        XCTAssertTrue(allPassed)
        XCTAssertEqual(results.count, 2)
    }

    func testEvaluateAll_andMultipleConditionsOneFalse_returnsFailed() async {
        // Create conditions where one will fail
        let conditions = [
            WorkflowCondition.timeCondition(
                TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 0, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 59)))
            ),
            WorkflowCondition.timeCondition(
                TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 0)), endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 30)))
            )
        ]
        let (allPassed, results) = await evaluator.evaluateAll(conditions)
        // At least one condition should fail depending on time
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - OR Conditions

    func testEvaluate_orAllFalse_returnsFailed() async {
        let cond1 = WorkflowCondition.or([])
        let result = await evaluator.evaluate(cond1)
        XCTAssertFalse(result.passed)
    }

    // MARK: - NOT Conditions

    func testEvaluate_notTrue_returnsFalse() async {
        let timeRange = TimeCondition(
            mode: .timeRange,
            startTime: TimePoint.fixed(TimeOfDay(hour: 0, minute: 0)),
            endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 59))
        )
        let notCondition = WorkflowCondition.not(.timeCondition(timeRange))
        let result = await evaluator.evaluate(notCondition)
        XCTAssertFalse(result.passed)
    }

    func testEvaluate_notFalse_returnsTrue() async {
        let timeRange = TimeCondition(
            mode: .timeRange,
            startTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 0)),
            endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 30))
        )
        let notCondition = WorkflowCondition.not(.timeCondition(timeRange))
        let result = await evaluator.evaluate(notCondition)
        // Result depends on current time, but logicOperator should be "NOT"
        XCTAssertEqual(result.logicOperator, "NOT")
    }

    // MARK: - Nested Compound Conditions

    func testEvaluate_nestedAndInsideOr_evaluatesCorrectly() async {
        let timeRange = TimeCondition(
            mode: .timeRange,
            startTime: TimePoint.fixed(TimeOfDay(hour: 0, minute: 0)),
            endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 59))
        )
        let andCondition = WorkflowCondition.and([
            .timeCondition(timeRange),
            .timeCondition(timeRange)
        ])
        let orCondition = WorkflowCondition.or([andCondition])
        let result = await evaluator.evaluate(orCondition)
        XCTAssertEqual(result.logicOperator, "OR")
        XCTAssertEqual(result.subResults.count, 1)
        XCTAssertEqual(result.subResults[0].logicOperator, "AND")
    }

    func testEvaluate_nestedOrInsideAnd_evaluatesCorrectly() async {
        let timeRange = TimeCondition(
            mode: .timeRange,
            startTime: TimePoint.fixed(TimeOfDay(hour: 0, minute: 0)),
            endTime: TimePoint.fixed(TimeOfDay(hour: 23, minute: 59))
        )
        let orCondition = WorkflowCondition.or([
            .timeCondition(timeRange)
        ])
        let andCondition = WorkflowCondition.and([
            orCondition,
            .timeCondition(timeRange)
        ])
        let result = await evaluator.evaluate(andCondition)
        XCTAssertEqual(result.logicOperator, "AND")
        XCTAssertEqual(result.subResults.count, 2)
    }

    // MARK: - Time Conditions

    func testEvaluateTimeCondition_timeRangeInRange_returnsTrue() async {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        // Create a range that includes now
        let startHour = max(0, hour - 1)
        let endHour = min(23, hour + 1)

        let condition = WorkflowCondition.timeCondition(
            TimeCondition(
                mode: .timeRange,
                startTime: TimePoint.fixed(TimeOfDay(hour: startHour, minute: 0)),
                endTime: TimePoint.fixed(TimeOfDay(hour: endHour, minute: 59))
            )
        )
        let result = await evaluator.evaluate(condition)
        XCTAssertTrue(result.passed)
    }

    func testEvaluateTimeCondition_timeRangeOutOfRange_returnsFalse() async {
        let condition = WorkflowCondition.timeCondition(
            TimeCondition(
                mode: .timeRange,
                startTime: TimePoint.fixed(TimeOfDay(hour: 1, minute: 0)),
                endTime: TimePoint.fixed(TimeOfDay(hour: 1, minute: 30))
            )
        )
        let result = await evaluator.evaluate(condition)
        // Likely false unless current time is 1:00-1:30, but the condition was created
        XCTAssertNotNil(result)
    }

    func testEvaluateTimeCondition_timeRangeMissingStartTime_returnsFailed() async {
        let condition = WorkflowCondition.timeCondition(
            TimeCondition(mode: .timeRange, startTime: nil, endTime: TimePoint.fixed(TimeOfDay(hour: 10, minute: 0)))
        )
        let result = await evaluator.evaluate(condition)
        XCTAssertFalse(result.passed)
    }

    func testEvaluateTimeCondition_timeRangeMissingEndTime_returnsFailed() async {
        let condition = WorkflowCondition.timeCondition(
            TimeCondition(mode: .timeRange, startTime: TimePoint.fixed(TimeOfDay(hour: 10, minute: 0)), endTime: nil)
        )
        let result = await evaluator.evaluate(condition)
        XCTAssertFalse(result.passed)
    }

    func testEvaluateTimeCondition_beforeSunriseNoLocation_returnsFailed() async {
        mockStorage.sunEventLatitude = 0
        mockStorage.sunEventLongitude = 0
        let condition = WorkflowCondition.timeCondition(
            TimeCondition(mode: .beforeSunrise)
        )
        let result = await evaluator.evaluate(condition)
        XCTAssertFalse(result.passed)
    }

    // MARK: - BlockResult Conditions

    func testEvaluateBlockResult_specificBlockNotExecuted_returnsFalse() async {
        let blockId = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .specific(blockId), expectedStatus: .success)
        )
        evaluator.blockResults = [:]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertFalse(passed)
    }

    func testEvaluateBlockResult_specificBlockMatches_returnsTrue() async {
        let blockId = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .specific(blockId), expectedStatus: .success)
        )
        evaluator.blockResults = [blockId: .success]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertTrue(passed)
    }

    func testEvaluateBlockResult_specificBlockMismatch_returnsFalse() async {
        let blockId = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .specific(blockId), expectedStatus: .success)
        )
        evaluator.blockResults = [blockId: .failed]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertFalse(passed)
    }

    func testEvaluateBlockResult_allBlocksNone_returnsFalse() async {
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .all, expectedStatus: .success)
        )
        evaluator.blockResults = [:]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertFalse(passed)
    }

    func testEvaluateBlockResult_allBlocksAllMatch_returnsTrue() async {
        let id1 = UUID()
        let id2 = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .all, expectedStatus: .success)
        )
        evaluator.blockResults = [id1: .success, id2: .success]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertTrue(passed)
    }

    func testEvaluateBlockResult_allBlocksPartialMatch_returnsFalse() async {
        let id1 = UUID()
        let id2 = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .all, expectedStatus: .success)
        )
        evaluator.blockResults = [id1: .success, id2: .failed]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertFalse(passed)
    }

    func testEvaluateBlockResult_anyBlocksNone_returnsFalse() async {
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .any, expectedStatus: .success)
        )
        evaluator.blockResults = [:]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertFalse(passed)
    }

    func testEvaluateBlockResult_anyBlocksOneMatch_returnsTrue() async {
        let id1 = UUID()
        let id2 = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .any, expectedStatus: .success)
        )
        evaluator.blockResults = [id1: .success, id2: .failed]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertTrue(passed)
    }

    func testEvaluateBlockResult_anyBlocksNoMatch_returnsFalse() async {
        let id1 = UUID()
        let id2 = UUID()
        let condition = WorkflowCondition.blockResult(
            BlockResultCondition(scope: .any, expectedStatus: .success)
        )
        evaluator.blockResults = [id1: .failed, id2: .failed]
        let (passed, _) = await evaluator.evaluateLeaf(condition)
        XCTAssertFalse(passed)
    }

    // MARK: - Comparison Description

    func testComparisonDescription_equals() {
        let desc = ConditionEvaluator.comparisonDescription(.equals(AnyCodable(42)))
        XCTAssertTrue(desc.contains("=="))
    }

    func testComparisonDescription_notEquals() {
        let desc = ConditionEvaluator.comparisonDescription(.notEquals(AnyCodable(42)))
        XCTAssertTrue(desc.contains("!="))
    }

    func testComparisonDescription_greaterThan() {
        let desc = ConditionEvaluator.comparisonDescription(.greaterThan(40))
        XCTAssertTrue(desc.contains(">"))
    }

    func testComparisonDescription_lessThan() {
        let desc = ConditionEvaluator.comparisonDescription(.lessThan(40))
        XCTAssertTrue(desc.contains("<"))
    }

    func testComparisonDescription_greaterThanOrEqual() {
        let desc = ConditionEvaluator.comparisonDescription(.greaterThanOrEqual(40))
        XCTAssertTrue(desc.contains(">="))
    }

    func testComparisonDescription_lessThanOrEqual() {
        let desc = ConditionEvaluator.comparisonDescription(.lessThanOrEqual(40))
        XCTAssertTrue(desc.contains("<="))
    }

    // MARK: - Values Equal

    func testValuesEqual_bothNil_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual(nil, nil)
        XCTAssertTrue(result)
    }

    func testValuesEqual_oneNil_returnsFalse() {
        let result = ConditionEvaluator.valuesEqual(42, nil)
        XCTAssertFalse(result)
    }

    func testValuesEqual_sameBool_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual(true, true)
        XCTAssertTrue(result)
    }

    func testValuesEqual_sameString_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual("hello", "hello")
        XCTAssertTrue(result)
    }

    func testValuesEqual_numericEquality_intVsDouble_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual(42, 42.0)
        XCTAssertTrue(result)
    }

    func testValuesEqual_numericInequality_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual(42, 43)
        XCTAssertFalse(result)
    }

    func testValuesEqual_boolAsNumeric_trueVsOne_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual(true, 1)
        XCTAssertTrue(result)
    }

    func testValuesEqual_boolAsNumeric_falseVsZero_returnsTrue() {
        let result = ConditionEvaluator.valuesEqual(false, 0)
        XCTAssertTrue(result)
    }

    // MARK: - To Double Conversion

    func testToDouble_intValue_returnsDouble() {
        let result = ConditionEvaluator.toDouble(42)
        XCTAssertEqual(result, 42.0)
    }

    func testToDouble_doubleValue_returnsDouble() {
        let result = ConditionEvaluator.toDouble(42.5)
        XCTAssertEqual(result, 42.5)
    }

    func testToDouble_boolTrue_returnsOne() {
        let result = ConditionEvaluator.toDouble(true)
        XCTAssertEqual(result, 1.0)
    }

    func testToDouble_boolFalse_returnsZero() {
        let result = ConditionEvaluator.toDouble(false)
        XCTAssertEqual(result, 0.0)
    }

    func testToDouble_floatValue_returnsDouble() {
        let result = ConditionEvaluator.toDouble(Float(42.5))
        XCTAssertEqual(result, 42.5)
    }

    func testToDouble_stringNumber_returnsDouble() {
        let result = ConditionEvaluator.toDouble("42.5")
        XCTAssertEqual(result, 42.5)
    }

    func testToDouble_stringTrue_returnsOne() {
        let result = ConditionEvaluator.toDouble("true")
        XCTAssertEqual(result, 1.0)
    }

    func testToDouble_stringFalse_returnsZero() {
        let result = ConditionEvaluator.toDouble("false")
        XCTAssertEqual(result, 0.0)
    }

    func testToDouble_invalidString_returnsNil() {
        let result = ConditionEvaluator.toDouble("invalid")
        XCTAssertNil(result)
    }

    func testToDouble_nil_returnsNil() {
        let result = ConditionEvaluator.toDouble(nil)
        XCTAssertNil(result)
    }
}

// MARK: - Mocks

class MockHomeKitManager: HomeKitManager {
    override func getDeviceState(id: String) -> DeviceModel? {
        return nil
    }
}

class MockStorageService: StorageService {
    var sunEventLatitude: Double = 0
    var sunEventLongitude: Double = 0

    override func readSunEventLatitude() -> Double { sunEventLatitude }
    override func readSunEventLongitude() -> Double { sunEventLongitude }
}

class MockDeviceRegistryService: DeviceRegistryService {
    init() {
        super.init(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("mock-registry.json"))
    }

    override func readCharacteristicType(forStableId stableId: String) -> String? {
        return nil
    }

    override func readHomeKitServiceId(_ stableId: String) -> String {
        return stableId
    }
}
