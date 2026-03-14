import XCTest
 import CompAI_Home

final class SolarCalculatorTests: XCTestCase {

    // MARK: - London Summer Solstice (June 21)

    func testSunrise_london_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunrise)

        // Summer solstice in London should have sunrise around 4:45 AM UTC
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise!)
        XCTAssertEqual(sunriseComponents.hour, 4, accuracy: 1)
        XCTAssertGreaterThan(sunriseComponents.minute ?? 0, 30)
    }

    func testSunset_london_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunset)

        // Summer solstice in London should have sunset around 9:20 PM UTC
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunset!)
        XCTAssertEqual(sunsetComponents.hour, 21, accuracy: 1)
        XCTAssertGreaterThan(sunsetComponents.minute ?? 0, 0)
    }

    // MARK: - London Winter Solstice (December 21)

    func testSunrise_london_winterSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunrise)

        // Winter solstice in London should have sunrise around 8:00 AM UTC
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise!)
        XCTAssertEqual(sunriseComponents.hour, 8, accuracy: 1)
    }

    func testSunset_london_winterSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunset)

        // Winter solstice in London should have sunset around 3:53 PM UTC
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunset!)
        XCTAssertEqual(sunsetComponents.hour, 15, accuracy: 1)
    }

    // MARK: - Sunrise Before Sunset

    func testSunrise_beforeSunset_london_summer() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)!
        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)!

        XCTAssertLessThan(sunrise, sunset)
    }

    func testSunrise_beforeSunset_london_winter() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)!
        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)!

        XCTAssertLessThan(sunrise, sunset)
    }

    // MARK: - New York Summer Solstice

    func testSunrise_newYork_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 40.7128, longitude: -74.0060)
        XCTAssertNotNil(sunrise)

        // Summer solstice in New York should have sunrise around 5:30 AM UTC
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise!)
        XCTAssertEqual(sunriseComponents.hour, 5, accuracy: 1)
    }

    func testSunset_newYork_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunset = SolarCalculator.sunset(for: date, latitude: 40.7128, longitude: -74.0060)
        XCTAssertNotNil(sunset)

        // Summer solstice in New York should have sunset around 8:30 PM UTC
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunset!)
        XCTAssertEqual(sunsetComponents.hour, 20, accuracy: 2)
    }

    // MARK: - Sydney Summer Solstice (December 21 in Southern Hemisphere)

    func testSunrise_sydney_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: -33.8688, longitude: 151.2093)
        XCTAssertNotNil(sunrise)

        // Summer solstice in Sydney should have early sunrise
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise!)
        XCTAssertGreaterThan(sunriseComponents.hour ?? 0, 20) // Should be late evening UTC (early morning local)
    }

    // MARK: - Equinoxes (Spring and Fall)

    func testSunrise_london_springEquinox() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 20
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunrise)

        // Spring equinox should have roughly 6 AM sunrise
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise!)
        XCTAssertEqual(sunriseComponents.hour, 6, accuracy: 1)
    }

    func testSunset_london_springEquinox() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 20
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunset)

        // Spring equinox should have roughly 6 PM sunset
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunset!)
        XCTAssertEqual(sunsetComponents.hour, 18, accuracy: 1)
    }

    // MARK: - Polar Regions

    func testSunrise_farNorth_polarNight_returnsNil() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        // North Pole region in winter - polar night
        let sunrise = SolarCalculator.sunrise(for: date, latitude: 85.0, longitude: 0)
        XCTAssertNil(sunrise)
    }

    func testSunset_farNorth_polarNight_returnsNil() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        // North Pole region in winter - polar night
        let sunset = SolarCalculator.sunset(for: date, latitude: 85.0, longitude: 0)
        XCTAssertNil(sunset)
    }

    func testSunrise_farNorth_polarDay_returnsNil() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        // North Pole region in summer - polar day (sun doesn't set)
        let sunrise = SolarCalculator.sunrise(for: date, latitude: 85.0, longitude: 0)
        XCTAssertNil(sunrise) // Should return nil for polar day (sun is always above horizon)
    }

    // MARK: - Sun Times Batch Call

    func testSunTimes_returnsPopulatedTuple() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let (sunrise, sunset) = SolarCalculator.sunTimes(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunrise)
        XCTAssertNotNil(sunset)
        XCTAssertLessThan(sunrise!, sunset!)
    }

    // MARK: - Equator

    func testSunrise_equator_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 0, longitude: 0)
        XCTAssertNotNil(sunrise)

        // At equator, sunrise/sunset are roughly consistent (around 6 AM/6 PM)
        let sunriseComponents = calendar.dateComponents([.hour, .minute], from: sunrise!)
        XCTAssertEqual(sunriseComponents.hour, 6, accuracy: 1)
    }

    func testSunset_equator_summerSolstice() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunset = SolarCalculator.sunset(for: date, latitude: 0, longitude: 0)
        XCTAssertNotNil(sunset)

        // At equator, sunset should be around 6 PM
        let sunsetComponents = calendar.dateComponents([.hour, .minute], from: sunset!)
        XCTAssertEqual(sunsetComponents.hour, 18, accuracy: 1)
    }

    // MARK: - Day Length Variations

    func testDayLength_london_summer_longerThanWinter() {
        let calendar = Calendar(identifier: .gregorian)

        // Summer solstice
        var summerComponents = DateComponents()
        summerComponents.year = 2024
        summerComponents.month = 6
        summerComponents.day = 21
        summerComponents.hour = 12
        summerComponents.minute = 0
        let summerDate = calendar.date(from: summerComponents)!

        let summerSunrise = SolarCalculator.sunrise(for: summerDate, latitude: 51.5, longitude: 0)!
        let summerSunset = SolarCalculator.sunset(for: summerDate, latitude: 51.5, longitude: 0)!
        let summerLength = summerSunset.timeIntervalSince(summerSunrise)

        // Winter solstice
        var winterComponents = DateComponents()
        winterComponents.year = 2024
        winterComponents.month = 12
        winterComponents.day = 21
        winterComponents.hour = 12
        winterComponents.minute = 0
        let winterDate = calendar.date(from: winterComponents)!

        let winterSunrise = SolarCalculator.sunrise(for: winterDate, latitude: 51.5, longitude: 0)!
        let winterSunset = SolarCalculator.sunset(for: winterDate, latitude: 51.5, longitude: 0)!
        let winterLength = winterSunset.timeIntervalSince(winterSunrise)

        XCTAssertGreaterThan(summerLength, winterLength)
    }

    func testDayLength_london_summer_approximately16hours() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)!
        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)!
        let dayLength = sunset.timeIntervalSince(sunrise) / 3600 // Convert to hours

        XCTAssertGreaterThan(dayLength, 15)
        XCTAssertLessThan(dayLength, 17)
    }

    func testDayLength_london_winter_approximately8hours() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)!
        let sunset = SolarCalculator.sunset(for: date, latitude: 51.5, longitude: 0)!
        let dayLength = sunset.timeIntervalSince(sunrise) / 3600 // Convert to hours

        XCTAssertGreaterThan(dayLength, 7)
        XCTAssertLessThan(dayLength, 9)
    }

    // MARK: - UTC Results

    func testSunrise_returnsUTC() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)!

        // Verify the result is a valid Date (UTC-based)
        let components2 = calendar.dateComponents([.year, .month, .day], from: sunrise)
        XCTAssertEqual(components2.year, 2024)
        XCTAssertEqual(components2.month, 6)
    }

    // MARK: - Different Days Same Location

    func testSunrise_sameLocation_differentDays_varies() {
        let calendar = Calendar(identifier: .gregorian)

        let day1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 12, minute: 0))!
        let day2 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1, hour: 12, minute: 0))!

        let sunrise1 = SolarCalculator.sunrise(for: day1, latitude: 51.5, longitude: 0)!
        let sunrise2 = SolarCalculator.sunrise(for: day2, latitude: 51.5, longitude: 0)!

        XCTAssertNotEqual(sunrise1, sunrise2)
    }

    // MARK: - Edge Case: Leap Year

    func testSunrise_leapYear_feb29() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 2
        components.day = 29
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)
        XCTAssertNotNil(sunrise)
    }

    // MARK: - Multiple Longitudes Same Latitude

    func testSunrise_differentLongitudes_differentTimes() {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        let date = calendar.date(from: components)!

        let sunrise1 = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 0)!
        let sunrise2 = SolarCalculator.sunrise(for: date, latitude: 51.5, longitude: 10)!

        // Different longitudes should produce different sunrise times
        XCTAssertNotEqual(sunrise1, sunrise2)
    }
}
