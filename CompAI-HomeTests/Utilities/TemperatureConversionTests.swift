import XCTest
 import CompAI_Home

final class TemperatureConversionTests: XCTestCase {

    // MARK: - Celsius to Fahrenheit

    func testCelsiusToFahrenheit_zero_returns32() {
        let result = TemperatureConversion.celsiusToFahrenheit(0)
        XCTAssertEqual(result, 32.0, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_100_returns212() {
        let result = TemperatureConversion.celsiusToFahrenheit(100)
        XCTAssertEqual(result, 212.0, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_negative40_returnsNegative40() {
        let result = TemperatureConversion.celsiusToFahrenheit(-40)
        XCTAssertEqual(result, -40.0, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_37_returns986() {
        let result = TemperatureConversion.celsiusToFahrenheit(37)
        XCTAssertEqual(result, 98.6, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_negative273_absolute_zero() {
        let result = TemperatureConversion.celsiusToFahrenheit(-273.15)
        XCTAssertEqual(result, -459.67, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_20_returns68() {
        let result = TemperatureConversion.celsiusToFahrenheit(20)
        XCTAssertEqual(result, 68.0, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_negative10_returns14() {
        let result = TemperatureConversion.celsiusToFahrenheit(-10)
        XCTAssertEqual(result, 14.0, accuracy: 0.01)
    }

    func testCelsiusToFahrenheit_fractional_precision() {
        let result = TemperatureConversion.celsiusToFahrenheit(25.5)
        XCTAssertEqual(result, 77.9, accuracy: 0.01)
    }

    // MARK: - Fahrenheit to Celsius

    func testFahrenheitToCelsius_32_returnsZero() {
        let result = TemperatureConversion.fahrenheitToCelsius(32)
        XCTAssertEqual(result, 0.0, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_212_returns100() {
        let result = TemperatureConversion.fahrenheitToCelsius(212)
        XCTAssertEqual(result, 100.0, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_negative40_returnsNegative40() {
        let result = TemperatureConversion.fahrenheitToCelsius(-40)
        XCTAssertEqual(result, -40.0, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_986_returns37() {
        let result = TemperatureConversion.fahrenheitToCelsius(98.6)
        XCTAssertEqual(result, 37.0, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_negative45967_absolute_zero() {
        let result = TemperatureConversion.fahrenheitToCelsius(-459.67)
        XCTAssertEqual(result, -273.15, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_68_returns20() {
        let result = TemperatureConversion.fahrenheitToCelsius(68)
        XCTAssertEqual(result, 20.0, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_14_returnsNegative10() {
        let result = TemperatureConversion.fahrenheitToCelsius(14)
        XCTAssertEqual(result, -10.0, accuracy: 0.01)
    }

    func testFahrenheitToCelsius_fractional_precision() {
        let result = TemperatureConversion.fahrenheitToCelsius(77.9)
        XCTAssertEqual(result, 25.5, accuracy: 0.01)
    }

    // MARK: - Round-Trip Conversions

    func testRoundTrip_celsiusToFahrenheitAndBack_zero() {
        let original = 0.0
        let toF = TemperatureConversion.celsiusToFahrenheit(original)
        let backToC = TemperatureConversion.fahrenheitToCelsius(toF)
        XCTAssertEqual(backToC, original, accuracy: 0.0001)
    }

    func testRoundTrip_celsiusToFahrenheitAndBack_100() {
        let original = 100.0
        let toF = TemperatureConversion.celsiusToFahrenheit(original)
        let backToC = TemperatureConversion.fahrenheitToCelsius(toF)
        XCTAssertEqual(backToC, original, accuracy: 0.0001)
    }

    func testRoundTrip_celsiusToFahrenheitAndBack_37() {
        let original = 37.0
        let toF = TemperatureConversion.celsiusToFahrenheit(original)
        let backToC = TemperatureConversion.fahrenheitToCelsius(toF)
        XCTAssertEqual(backToC, original, accuracy: 0.0001)
    }

    func testRoundTrip_celsiusToFahrenheitAndBack_negative273_15() {
        let original = -273.15
        let toF = TemperatureConversion.celsiusToFahrenheit(original)
        let backToC = TemperatureConversion.fahrenheitToCelsius(toF)
        XCTAssertEqual(backToC, original, accuracy: 0.01)
    }

    func testRoundTrip_celsiusToFahrenheitAndBack_fractional() {
        let original = 25.5
        let toF = TemperatureConversion.celsiusToFahrenheit(original)
        let backToC = TemperatureConversion.fahrenheitToCelsius(toF)
        XCTAssertEqual(backToC, original, accuracy: 0.0001)
    }

    func testRoundTrip_fahrenheitToCelsiusAndBack_32() {
        let original = 32.0
        let toC = TemperatureConversion.fahrenheitToCelsius(original)
        let backToF = TemperatureConversion.celsiusToFahrenheit(toC)
        XCTAssertEqual(backToF, original, accuracy: 0.0001)
    }

    func testRoundTrip_fahrenheitToCelsiusAndBack_212() {
        let original = 212.0
        let toC = TemperatureConversion.fahrenheitToCelsius(original)
        let backToF = TemperatureConversion.celsiusToFahrenheit(toC)
        XCTAssertEqual(backToF, original, accuracy: 0.0001)
    }

    func testRoundTrip_fahrenheitToCelsiusAndBack_68() {
        let original = 68.0
        let toC = TemperatureConversion.fahrenheitToCelsius(original)
        let backToF = TemperatureConversion.celsiusToFahrenheit(toC)
        XCTAssertEqual(backToF, original, accuracy: 0.0001)
    }

    func testRoundTrip_fahrenheitToCelsiusAndBack_fractional() {
        let original = 77.9
        let toC = TemperatureConversion.fahrenheitToCelsius(original)
        let backToF = TemperatureConversion.celsiusToFahrenheit(toC)
        XCTAssertEqual(backToF, original, accuracy: 0.0001)
    }

    // MARK: - Common Reference Points

    func testWaterFreezingPoint_celsius() {
        let result = TemperatureConversion.celsiusToFahrenheit(0)
        XCTAssertEqual(result, 32.0, accuracy: 0.01)
    }

    func testWaterBoilingPoint_celsius() {
        let result = TemperatureConversion.celsiusToFahrenheit(100)
        XCTAssertEqual(result, 212.0, accuracy: 0.01)
    }

    func testHumanBodyTemperature_celsius() {
        let result = TemperatureConversion.celsiusToFahrenheit(37)
        XCTAssertEqual(result, 98.6, accuracy: 0.1)
    }

    func testRoomTemperature_celsius() {
        let result = TemperatureConversion.celsiusToFahrenheit(21)
        XCTAssertEqual(result, 69.8, accuracy: 0.1)
    }

    // MARK: - Extreme Values

    func testExtremeHot_celsius() {
        let result = TemperatureConversion.celsiusToFahrenheit(1000)
        XCTAssertEqual(result, 1832.0, accuracy: 0.01)
    }

    func testExtremeCold_celsius() {
        let result = TemperatureConversion.celsiusToFahrenheit(-1000)
        XCTAssertEqual(result, -1832.0, accuracy: 0.01)
    }

    // MARK: - Zero Kelvin (Absolute Zero)

    func testAbsoluteZero_celsiusToFahrenheit() {
        let kelvinCelsius = -273.15
        let result = TemperatureConversion.celsiusToFahrenheit(kelvinCelsius)
        XCTAssertEqual(result, -459.67, accuracy: 0.01)
    }

    func testAbsoluteZero_fahrenheitToCelsius() {
        let kelvinFahrenheit = -459.67
        let result = TemperatureConversion.fahrenheitToCelsius(kelvinFahrenheit)
        XCTAssertEqual(result, -273.15, accuracy: 0.01)
    }

    // MARK: - Small Differences (Temperature Deltas)

    func testSmallDifference_oneDegree_celsius() {
        let diff1C = TemperatureConversion.celsiusToFahrenheit(1)
        let diff0C = TemperatureConversion.celsiusToFahrenheit(0)
        let deltaF = diff1C - diff0C
        XCTAssertEqual(deltaF, 9.0 / 5.0, accuracy: 0.0001)
    }

    func testSmallDifference_oneDegree_fahrenheit() {
        let diff1F = TemperatureConversion.fahrenheitToCelsius(1)
        let diff0F = TemperatureConversion.fahrenheitToCelsius(0)
        let deltaC = diff0F - diff1F
        XCTAssertEqual(deltaC, 5.0 / 9.0, accuracy: 0.0001)
    }

    // MARK: - Preferred Unit Preference

    func testPreferredUnit_default_celsius() {
        UserDefaults.standard.removeObject(forKey: "temperatureUnit")
        let unit = TemperatureConversion.preferredUnit
        XCTAssertEqual(unit, "celsius")
    }

    func testIsFahrenheit_default_false() {
        UserDefaults.standard.removeObject(forKey: "temperatureUnit")
        let isFahr = TemperatureConversion.isFahrenheit
        XCTAssertFalse(isFahr)
    }

    func testUnitSuffix_celsius() {
        UserDefaults.standard.removeObject(forKey: "temperatureUnit")
        let suffix = TemperatureConversion.unitSuffix
        XCTAssertEqual(suffix, "°C")
    }

    // MARK: - Convert From Celsius (User Preference Dependent)

    func testConvertFromCelsius_fahrenheit_preference() {
        UserDefaults.standard.set("fahrenheit", forKey: "temperatureUnit")
        let result = TemperatureConversion.convertFromCelsius(0)
        XCTAssertEqual(result, 32.0, accuracy: 0.01)
    }

    func testConvertFromCelsius_celsius_preference() {
        UserDefaults.standard.set("celsius", forKey: "temperatureUnit")
        let result = TemperatureConversion.convertFromCelsius(0)
        XCTAssertEqual(result, 0.0, accuracy: 0.01)
    }

    // MARK: - Convert To Celsius (User Preference Dependent)

    func testConvertToCelsius_fahrenheit_preference() {
        UserDefaults.standard.set("fahrenheit", forKey: "temperatureUnit")
        let result = TemperatureConversion.convertToCelsius(32)
        XCTAssertEqual(result, 0.0, accuracy: 0.01)
    }

    func testConvertToCelsius_celsius_preference() {
        UserDefaults.standard.set("celsius", forKey: "temperatureUnit")
        let result = TemperatureConversion.convertToCelsius(0)
        XCTAssertEqual(result, 0.0, accuracy: 0.01)
    }

    // MARK: - Convert Step Values

    func testConvertStepFromCelsius_fahrenheit_preference() {
        UserDefaults.standard.set("fahrenheit", forKey: "temperatureUnit")
        let step = 1.0
        let result = TemperatureConversion.convertStepFromCelsius(step)
        XCTAssertEqual(result, 1.8, accuracy: 0.01)
    }

    func testConvertStepFromCelsius_celsius_preference() {
        UserDefaults.standard.set("celsius", forKey: "temperatureUnit")
        let step = 1.0
        let result = TemperatureConversion.convertStepFromCelsius(step)
        XCTAssertEqual(result, 1.0, accuracy: 0.01)
    }

    func testConvertStepFromCelsius_halfDegree_fahrenheit() {
        UserDefaults.standard.set("fahrenheit", forKey: "temperatureUnit")
        let step = 0.5
        let result = TemperatureConversion.convertStepFromCelsius(step)
        XCTAssertEqual(result, 0.9, accuracy: 0.01)
    }

    // MARK: - Is Temperature Characteristic

    func testIsTemperatureCharacteristic_currentTemperature() {
        let result = TemperatureConversion.isTemperatureCharacteristic("00000011-0000-1000-8000-0026BB765291")
        XCTAssertTrue(result)
    }

    func testIsTemperatureCharacteristic_targetTemperature() {
        let result = TemperatureConversion.isTemperatureCharacteristic("00000035-0000-1000-8000-0026BB765291")
        XCTAssertTrue(result)
    }

    func testIsTemperatureCharacteristic_nonTemperature() {
        let result = TemperatureConversion.isTemperatureCharacteristic("00000025-0000-1000-8000-0026BB765291")
        XCTAssertFalse(result)
    }

    // MARK: - Cleanup

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "temperatureUnit")
        super.tearDown()
    }
}
