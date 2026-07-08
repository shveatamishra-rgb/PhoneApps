package app.bhaktiangan.core.panchang

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.tan

/** Shifts an [Instant] by a fractional number of seconds (mirrors Swift `addingTimeInterval`). */
internal fun Instant.plusSec(seconds: Double): Instant =
    plusNanos((seconds * 1_000_000_000.0).toLong())

/**
 * On-device astronomical calculations (Meeus / NOAA) backing the Panchang engine.
 * Ported 1:1 from iOS `Astronomy.swift`.
 *
 * Accuracy: Sun/Moon ecliptic longitude to ~arc-minute, sunrise/sunset to ~1 min.
 * Transition *minutes* can differ slightly from a Swiss-Ephemeris reference.
 */
object Astronomy {
    private val deg = Math.PI / 180.0

    fun norm360(x: Double): Double {
        val r = x % 360.0
        return if (r < 0) r + 360.0 else r
    }

    /** Julian Day for an absolute instant. */
    fun julianDay(date: Instant): Double =
        (date.epochSecond.toDouble() + date.nano / 1_000_000_000.0) / 86400.0 + 2440587.5

    /** Julian Day at 0h UT for a Gregorian calendar date. */
    fun julianDay(year: Int, month: Int, day: Int): Double {
        var y = year
        var m = month
        if (m <= 2) { y -= 1; m += 12 }
        val a = floor(y / 100.0)
        val b = 2 - a + floor(a / 4.0)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + day + b - 1524.5
    }

    fun julianCentury(jd: Double): Double = (jd - 2451545.0) / 36525.0

    /** Sun's apparent geocentric ecliptic longitude (tropical), degrees. */
    fun sunLongitude(jd: Double): Double {
        val t = julianCentury(jd)
        val l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t
        val m = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) * deg
        val c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(m) +
            (0.019993 - 0.000101 * t) * sin(2 * m) +
            0.000289 * sin(3 * m)
        val omega = (125.04 - 1934.136 * t) * deg
        return norm360(l0 + c - 0.00569 - 0.00478 * sin(omega))
    }

    // (D, M, M', F, coefficient in 1e-6 deg) — Meeus Table 47.A (truncated, 35 terms).
    private val moonTerms: Array<DoubleArray> = arrayOf(
        doubleArrayOf(0.0, 0.0, 1.0, 0.0, 6288774.0), doubleArrayOf(2.0, 0.0, -1.0, 0.0, 1274027.0), doubleArrayOf(2.0, 0.0, 0.0, 0.0, 658314.0),
        doubleArrayOf(0.0, 0.0, 2.0, 0.0, 213618.0), doubleArrayOf(0.0, 1.0, 0.0, 0.0, -185116.0), doubleArrayOf(0.0, 0.0, 0.0, 2.0, -114332.0),
        doubleArrayOf(2.0, 0.0, -2.0, 0.0, 58793.0), doubleArrayOf(2.0, -1.0, -1.0, 0.0, 57066.0), doubleArrayOf(2.0, 0.0, 1.0, 0.0, 53322.0),
        doubleArrayOf(2.0, -1.0, 0.0, 0.0, 45758.0), doubleArrayOf(0.0, 1.0, -1.0, 0.0, -40923.0), doubleArrayOf(1.0, 0.0, 0.0, 0.0, -34720.0),
        doubleArrayOf(0.0, 1.0, 1.0, 0.0, -30383.0), doubleArrayOf(2.0, 0.0, 0.0, -2.0, 15327.0), doubleArrayOf(0.0, 0.0, 1.0, 2.0, -12528.0),
        doubleArrayOf(0.0, 0.0, 1.0, -2.0, 10980.0), doubleArrayOf(4.0, 0.0, -1.0, 0.0, 10675.0), doubleArrayOf(0.0, 0.0, 3.0, 0.0, 10034.0),
        doubleArrayOf(4.0, 0.0, -2.0, 0.0, 8548.0), doubleArrayOf(2.0, 1.0, -1.0, 0.0, -7888.0), doubleArrayOf(2.0, 1.0, 0.0, 0.0, -6766.0),
        doubleArrayOf(1.0, 0.0, -1.0, 0.0, -5163.0), doubleArrayOf(1.0, 1.0, 0.0, 0.0, 4987.0), doubleArrayOf(2.0, -1.0, 1.0, 0.0, 4036.0),
        doubleArrayOf(2.0, 0.0, 2.0, 0.0, 3994.0), doubleArrayOf(4.0, 0.0, 0.0, 0.0, 3861.0), doubleArrayOf(2.0, 0.0, -3.0, 0.0, 3665.0),
        doubleArrayOf(0.0, 1.0, -2.0, 0.0, -2689.0), doubleArrayOf(2.0, 0.0, -1.0, 2.0, -2602.0), doubleArrayOf(2.0, -1.0, -2.0, 0.0, 2390.0),
        doubleArrayOf(1.0, 0.0, 1.0, 0.0, -2348.0), doubleArrayOf(2.0, -2.0, 0.0, 0.0, 2236.0), doubleArrayOf(0.0, 1.0, 2.0, 0.0, -2120.0),
        doubleArrayOf(0.0, 2.0, 0.0, 0.0, -2069.0), doubleArrayOf(2.0, -2.0, -1.0, 0.0, 2048.0),
    )

    /** Moon's apparent geocentric ecliptic longitude (tropical), degrees. */
    fun moonLongitude(jd: Double): Double {
        val t = julianCentury(jd)
        val lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t * t +
            t * t * t / 538841.0 - t * t * t * t / 65194000.0
        val d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t * t +
            t * t * t / 545868.0 - t * t * t * t / 113065000.0
        val sunM = 357.5291092 + 35999.0502909 * t - 0.0001536 * t * t + t * t * t / 24490000.0
        val moonM = 134.9633964 + 477198.8675055 * t + 0.0087414 * t * t +
            t * t * t / 69699.0 - t * t * t * t / 14712000.0
        val f = 93.272095 + 483202.0175233 * t - 0.0036539 * t * t -
            t * t * t / 3526000.0 + t * t * t * t / 863310000.0
        val e = 1 - 0.002516 * t - 0.0000074 * t * t

        var sum = 0.0
        for (term in moonTerms) {
            val (cd, cm, cmp, cf, coeff) = term
            var v = coeff * sin((cd * d + cm * sunM + cmp * moonM + cf * f) * deg)
            if (kotlin.math.abs(cm) == 1.0) v *= e else if (kotlin.math.abs(cm) == 2.0) v *= e * e
            sum += v
        }
        return norm360(lp + sum / 1_000_000.0)
    }

    /** Lahiri (Chitrapaksha) ayanamsa, degrees. Approximate to ~arc-minute. */
    fun ayanamsaLahiri(jd: Double): Double {
        val yearsSince2000 = (jd - 2451545.0) / 365.25
        return 23.85 + 0.013972 * yearsSince2000
    }

    /**
     * Sunrise & sunset as absolute instants for a calendar date at a location.
     * `tzSeconds` is the location's UTC offset (incl. DST) for that date.
     * Returns null for polar day/night where the sun doesn't cross the horizon.
     */
    fun sunriseSunset(
        year: Int, month: Int, day: Int,
        latitude: Double, longitude: Double, tzSeconds: Int,
    ): Pair<Instant, Instant>? {
        val lat = latitude
        val lon = longitude
        val jd = julianDay(year, month, day)
        val t = julianCentury(jd)
        val tzHours = tzSeconds / 3600.0

        val gmlSun = norm360(280.46646 + t * (36000.76983 + t * 0.0003032))
        val gmaSun = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        val eccent = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        val eqCtr = sin(deg * gmaSun) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
            sin(deg * 2 * gmaSun) * (0.019993 - 0.000101 * t) +
            sin(deg * 3 * gmaSun) * 0.000289
        val trueLong = gmlSun + eqCtr
        val appLong = trueLong - 0.00569 - 0.00478 * sin(deg * (125.04 - 1934.136 * t))
        val meanObliq = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        val obliqCorr = meanObliq + 0.00256 * cos(deg * (125.04 - 1934.136 * t))
        val declin = asin(sin(deg * obliqCorr) * sin(deg * appLong)) / deg
        val varY = tan(deg * obliqCorr / 2) * tan(deg * obliqCorr / 2)
        val eqTime = 4 * (
            varY * sin(2 * deg * gmlSun) -
                2 * eccent * sin(deg * gmaSun) +
                4 * eccent * varY * sin(deg * gmaSun) * cos(2 * deg * gmlSun) -
                0.5 * varY * varY * sin(4 * deg * gmlSun) -
                1.25 * eccent * eccent * sin(2 * deg * gmaSun)
            ) / deg

        val cosHA = cos(deg * 90.833) / (cos(deg * lat) * cos(deg * declin)) -
            tan(deg * lat) * tan(deg * declin)
        if (cosHA < -1 || cosHA > 1) return null
        val ha = acos(cosHA) / deg

        val solarNoonMin = 720 - 4 * lon - eqTime + tzHours * 60
        val sunriseMin = solarNoonMin - ha * 4
        val sunsetMin = solarNoonMin + ha * 4

        val sunrise = instant(year, month, day, sunriseMin, tzSeconds) ?: return null
        val sunset = instant(year, month, day, sunsetMin, tzSeconds) ?: return null
        return sunrise to sunset
    }

    /** Build an absolute Instant from a local date + minutes-after-local-midnight. */
    private fun instant(year: Int, month: Int, day: Int, minutesLocal: Double, tzSeconds: Int): Instant? {
        val zone = runCatching { ZoneOffset.ofTotalSeconds(tzSeconds) }.getOrNull() ?: return null
        val midnight = LocalDate.of(year, month, day).atStartOfDay(zone).toInstant()
        return midnight.plusSec(minutesLocal * 60.0)
    }
}
