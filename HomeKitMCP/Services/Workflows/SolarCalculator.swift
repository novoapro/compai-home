import Foundation

/// Pure-Swift sunrise/sunset calculator using the NOAA solar equations (Jean Meeus).
/// No external dependencies required.
struct SolarCalculator {

    /// Calculate sunrise time for a given date and location.
    /// Returns `nil` for polar day/night when sunrise does not occur.
    static func sunrise(for date: Date, latitude: Double, longitude: Double) -> Date? {
        sunTime(for: date, latitude: latitude, longitude: longitude, isSunrise: true)
    }

    /// Calculate sunset time for a given date and location.
    /// Returns `nil` for polar day/night when sunset does not occur.
    static func sunset(for date: Date, latitude: Double, longitude: Double) -> Date? {
        sunTime(for: date, latitude: latitude, longitude: longitude, isSunrise: false)
    }

    /// Calculate both sunrise and sunset.
    static func sunTimes(for date: Date, latitude: Double, longitude: Double) -> (sunrise: Date?, sunset: Date?) {
        let sr = sunrise(for: date, latitude: latitude, longitude: longitude)
        let ss = sunset(for: date, latitude: latitude, longitude: longitude)
        return (sr, ss)
    }

    // MARK: - Private

    /// Standard solar zenith angle for sunrise/sunset (degrees).
    /// 90.833° accounts for atmospheric refraction and solar disc radius.
    private static let solarZenith: Double = 90.833

    private static func sunTime(for date: Date, latitude: Double, longitude: Double, isSunrise: Bool) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }

        // Julian Day Number
        let jd = julianDay(year: year, month: month, day: day)

        // Julian Century
        let t = (jd - 2451545.0) / 36525.0

        // Solar calculations
        let meanLongSun = fmod(280.46646 + t * (36000.76983 + 0.0003032 * t), 360.0)
        let meanAnomSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let eccentEarthOrbit = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        let meanAnomRad = radians(meanAnomSun)
        let sinMeanAnom = sin(meanAnomRad)
        let sin2MeanAnom = sin(2.0 * meanAnomRad)
        let sin3MeanAnom = sin(3.0 * meanAnomRad)

        let equationOfCenter = sinMeanAnom * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin2MeanAnom * (0.019993 - 0.000101 * t)
            + sin3MeanAnom * 0.000289

        let sunTrueLong = meanLongSun + equationOfCenter
        let sunAppLong = sunTrueLong - 0.00569 - 0.00478 * sin(radians(125.04 - 1934.136 * t))

        let meanObliqEcliptic = 23.0 + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0
        let obliqCorr = meanObliqEcliptic + 0.00256 * cos(radians(125.04 - 1934.136 * t))

        let sunDeclination = degrees(asin(sin(radians(obliqCorr)) * sin(radians(sunAppLong))))

        // Equation of Time (minutes)
        let y = tan(radians(obliqCorr / 2.0)) * tan(radians(obliqCorr / 2.0))
        let meanLongRad = radians(meanLongSun)
        let eqOfTime = 4.0 * degrees(
            y * sin(2.0 * meanLongRad)
            - 2.0 * eccentEarthOrbit * sinMeanAnom
            + 4.0 * eccentEarthOrbit * y * sinMeanAnom * cos(2.0 * meanLongRad)
            - 0.5 * y * y * sin(4.0 * meanLongRad)
            - 1.25 * eccentEarthOrbit * eccentEarthOrbit * sin2MeanAnom
        )

        // Hour Angle
        let latRad = radians(latitude)
        let declRad = radians(sunDeclination)
        let zenithRad = radians(solarZenith)

        let cosHourAngle = (cos(zenithRad) / (cos(latRad) * cos(declRad))) - tan(latRad) * tan(declRad)

        // Check for polar day/night
        guard cosHourAngle >= -1.0, cosHourAngle <= 1.0 else { return nil }

        let hourAngle = degrees(acos(cosHourAngle))

        // Sun time in minutes from midnight UTC
        let sunMinutes: Double
        if isSunrise {
            sunMinutes = 720.0 - 4.0 * (longitude + hourAngle) - eqOfTime
        } else {
            sunMinutes = 720.0 - 4.0 * (longitude - hourAngle) - eqOfTime
        }

        // Convert minutes from midnight UTC to a Date
        let startOfDayUTC = calendar.date(from: DateComponents(
            timeZone: TimeZone(identifier: "UTC"),
            year: year, month: month, day: day,
            hour: 0, minute: 0, second: 0
        ))!

        let secondsFromMidnight = sunMinutes * 60.0
        return startOfDayUTC.addingTimeInterval(secondsFromMidnight)
    }

    private static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = floor(y / 100.0)
        let b = 2.0 - a + floor(a / 4.0)
        return floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + Double(day) + b - 1524.5
    }

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    private static func degrees(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }
}
