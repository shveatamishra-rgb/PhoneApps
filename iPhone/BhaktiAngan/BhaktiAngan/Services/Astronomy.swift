import Foundation

/// On-device astronomical calculations (Meeus / NOAA) backing the Panchang engine.
///
/// Accuracy: Sun/Moon ecliptic longitude to roughly an arc-minute, sunrise/sunset
/// to about a minute. That is good enough for a daily Panchang, but transition
/// *minutes* (e.g. exact tithi/nakshatra change) can differ slightly from a
/// Swiss-Ephemeris reference like DrikPanchang — spot-check before relying on them.
enum Astronomy {
    private static let deg = Double.pi / 180

    static func norm360(_ x: Double) -> Double {
        let r = x.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// Julian Day for an absolute instant.
    static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    /// Julian Day at 0h UT for a Gregorian calendar date.
    static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(Double(y) / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1))
            + Double(day) + b - 1524.5
    }

    static func julianCentury(_ jd: Double) -> Double { (jd - 2451545.0) / 36525.0 }

    /// Sun's apparent geocentric ecliptic longitude (tropical), degrees.
    static func sunLongitude(_ jd: Double) -> Double {
        let t = julianCentury(jd)
        let l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        let m = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) * deg
        let c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(m)
            + (0.019993 - 0.000101 * t) * sin(2 * m)
            + 0.000289 * sin(3 * m)
        let omega = (125.04 - 1934.136 * t) * deg
        return norm360(l0 + c - 0.00569 - 0.00478 * sin(omega))
    }

    /// Moon's apparent geocentric ecliptic longitude (tropical), degrees.
    /// Truncated Meeus (ch. 47) — the main periodic terms of Table 47.A.
    static func moonLongitude(_ jd: Double) -> Double {
        let t = julianCentury(jd)
        let lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t
            + t * t * t / 538841 - t * t * t * t / 65194000
        let d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t
            + t * t * t / 545868 - t * t * t * t / 113065000
        let sunM = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t + t * t * t / 24490000
        let moonM = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t
            + t * t * t / 69699 - t * t * t * t / 14712000
        let f = 93.272095 + 483202.0175233 * t - 0.0036539 * t * t
            - t * t * t / 3526000 + t * t * t * t / 863310000
        let e = 1 - 0.002516 * t - 0.0000074 * t * t

        // (D, M, M', F, coefficient in 1e-6 deg)
        let terms: [(Double, Double, Double, Double, Double)] = [
            (0, 0, 1, 0, 6288774), (2, 0, -1, 0, 1274027), (2, 0, 0, 0, 658314),
            (0, 0, 2, 0, 213618), (0, 1, 0, 0, -185116), (0, 0, 0, 2, -114332),
            (2, 0, -2, 0, 58793), (2, -1, -1, 0, 57066), (2, 0, 1, 0, 53322),
            (2, -1, 0, 0, 45758), (0, 1, -1, 0, -40923), (1, 0, 0, 0, -34720),
            (0, 1, 1, 0, -30383), (2, 0, 0, -2, 15327), (0, 0, 1, 2, -12528),
            (0, 0, 1, -2, 10980), (4, 0, -1, 0, 10675), (0, 0, 3, 0, 10034),
            (4, 0, -2, 0, 8548), (2, 1, -1, 0, -7888), (2, 1, 0, 0, -6766),
            (1, 0, -1, 0, -5163), (1, 1, 0, 0, 4987), (2, -1, 1, 0, 4036),
            (2, 0, 2, 0, 3994), (4, 0, 0, 0, 3861), (2, 0, -3, 0, 3665),
            (0, 1, -2, 0, -2689), (2, 0, -1, 2, -2602), (2, -1, -2, 0, 2390),
            (1, 0, 1, 0, -2348), (2, -2, 0, 0, 2236), (0, 1, 2, 0, -2120),
            (0, 2, 0, 0, -2069), (2, -2, -1, 0, 2048)
        ]
        var sum = 0.0
        for (cd, cm, cmp, cf, coeff) in terms {
            var term = coeff * sin((cd * d + cm * sunM + cmp * moonM + cf * f) * deg)
            if abs(cm) == 1 { term *= e } else if abs(cm) == 2 { term *= e * e }
            sum += term
        }
        return norm360(lp + sum / 1_000_000.0)
    }

    /// Lahiri (Chitrapaksha) ayanamsa, degrees. Approximate to ~arc-minute.
    static func ayanamsaLahiri(_ jd: Double) -> Double {
        let yearsSince2000 = (jd - 2451545.0) / 365.25
        return 23.85 + 0.013972 * yearsSince2000
    }

    /// Sunrise & sunset as absolute instants for a calendar date at a location.
    /// `tzSeconds` is the location's UTC offset (incl. DST) for that date.
    /// Returns nil for polar day/night where the sun doesn't cross the horizon.
    static func sunriseSunset(
        year: Int, month: Int, day: Int,
        latitude lat: Double, longitude lon: Double, tzSeconds: Int
    ) -> (sunrise: Date, sunset: Date)? {
        let jd = julianDay(year: year, month: month, day: day)
        let t = julianCentury(jd)
        let tzHours = Double(tzSeconds) / 3600

        let gmlSun = norm360(280.46646 + t * (36000.76983 + t * 0.0003032))
        let gmaSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let eccent = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let eqCtr = sin(deg * gmaSun) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(deg * 2 * gmaSun) * (0.019993 - 0.000101 * t)
            + sin(deg * 3 * gmaSun) * 0.000289
        let trueLong = gmlSun + eqCtr
        let appLong = trueLong - 0.00569 - 0.00478 * sin(deg * (125.04 - 1934.136 * t))
        let meanObliq = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let obliqCorr = meanObliq + 0.00256 * cos(deg * (125.04 - 1934.136 * t))
        let declin = asin(sin(deg * obliqCorr) * sin(deg * appLong)) / deg
        let varY = tan(deg * obliqCorr / 2) * tan(deg * obliqCorr / 2)
        let eqTime = 4 * (varY * sin(2 * deg * gmlSun)
            - 2 * eccent * sin(deg * gmaSun)
            + 4 * eccent * varY * sin(deg * gmaSun) * cos(2 * deg * gmlSun)
            - 0.5 * varY * varY * sin(4 * deg * gmlSun)
            - 1.25 * eccent * eccent * sin(2 * deg * gmaSun)) / deg

        let cosHA = cos(deg * 90.833) / (cos(deg * lat) * cos(deg * declin))
            - tan(deg * lat) * tan(deg * declin)
        guard cosHA >= -1, cosHA <= 1 else { return nil }
        let ha = acos(cosHA) / deg

        let solarNoonMin = 720 - 4 * lon - eqTime + tzHours * 60
        let sunriseMin = solarNoonMin - ha * 4
        let sunsetMin = solarNoonMin + ha * 4

        guard let sunrise = instant(year: year, month: month, day: day, minutesLocal: sunriseMin, tzSeconds: tzSeconds),
              let sunset = instant(year: year, month: month, day: day, minutesLocal: sunsetMin, tzSeconds: tzSeconds)
        else { return nil }
        return (sunrise, sunset)
    }

    /// Build an absolute Date from a local date + minutes-after-local-midnight.
    private static func instant(year: Int, month: Int, day: Int, minutesLocal: Double, tzSeconds: Int) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        guard let tz = TimeZone(secondsFromGMT: tzSeconds) else { return nil }
        cal.timeZone = tz
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = 0; comps.minute = 0; comps.second = 0
        guard let midnight = cal.date(from: comps) else { return nil }
        return midnight.addingTimeInterval(minutesLocal * 60)
    }
}
