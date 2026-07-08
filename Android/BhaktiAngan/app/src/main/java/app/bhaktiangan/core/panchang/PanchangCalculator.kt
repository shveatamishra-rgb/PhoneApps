package app.bhaktiangan.core.panchang

import app.bhaktiangan.core.model.Bi
import app.bhaktiangan.core.model.City
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.abs

/** Pure-Kotlin port of iOS `PanchangCalculator`. No platform UI dependencies. */
object PanchangCalculator {
    private val cycle = PanchangNames.choghadiya               // Udveg,Char,Labh,Amrit,Kaal,Shubh,Rog
    private val dayStartIdx = intArrayOf(0, 3, 6, 2, 5, 1, 4)  // Sun..Sat -> index into cycle
    private val nightStartIdx = intArrayOf(5, 1, 4, 0, 3, 6, 2)
    private val rahuSeg = intArrayOf(8, 2, 7, 5, 6, 4, 3)      // 1-based daytime eighth
    private val gulikaSeg = intArrayOf(7, 6, 5, 4, 3, 2, 1)
    private val yamaSeg = intArrayOf(5, 4, 3, 2, 1, 7, 6)
    private val kalaVelaSeg = intArrayOf(5, 2, 6, 3, 7, 4, 1)  // Sun..Sat daytime eighth (Saturn-ruled)
    private val kalaRatriSeg = intArrayOf(7, 5, 8, 6, 6, 4, 7) // verified vs DrikPanchang
    private val goodIdx = setOf(2, 3, 5)                       // Labh, Amrit, Shubh
    private val neutralIdx = setOf(1)                          // Char

    /** Picks the Hindu day (sunrise→sunrise) that `now` falls in. */
    fun computeForInstant(now: Instant, city: City): PanchangResult? {
        val today = compute(now, city) ?: return null
        if (now.isBefore(today.sunrise)) {
            return compute(now.plusSec(-24 * 3600.0), city) ?: today
        }
        return today
    }

    fun compute(date: Instant, city: City): PanchangResult? {
        val zone = runCatching { ZoneId.of(city.timeZoneID) }.getOrDefault(ZoneId.systemDefault())
        val zdt = date.atZone(zone)
        val y = zdt.year
        val m = zdt.monthValue
        val d = zdt.dayOfMonth
        val weekday = zdt.dayOfWeek.value % 7   // 0 = Sunday

        val tzSec = city.tzSeconds(date)
        val today = Astronomy.sunriseSunset(y, m, d, city.latitude, city.longitude, tzSec) ?: return null

        // Next day's sunrise bounds the night Choghadiya.
        val next = LocalDate.of(y, m, d).plusDays(1)
        val nextStart = next.atStartOfDay(zone).toInstant()
        val tomorrow = Astronomy.sunriseSunset(
            next.year, next.monthValue, next.dayOfMonth,
            city.latitude, city.longitude, city.tzSeconds(nextStart),
        )
        val sunrise = today.first
        val sunset = today.second
        val nextSunrise = tomorrow?.first ?: sunset.plusSec(12 * 3600.0)

        // Calendar elements as of sunrise (the conventional reference).
        val jd = Astronomy.julianDay(sunrise)
        val sun = Astronomy.sunLongitude(jd)
        val moon = Astronomy.moonLongitude(jd)
        val ayan = Astronomy.ayanamsaLahiri(jd)
        val diff = Astronomy.norm360(moon - sun)

        val tithiIdx = minOf(29, (diff / 12).toInt())
        val tithiBi = tithiName(diff)
        val tithi = PanchangElement(tithiBi.en, tithiBi.hi, transitionEnd(sunrise, 30.0) { tithiIndex(it) })
        val vrat = PanchangNames.vrat[tithiIdx]?.let { PanchangElement(it.en, it.hi, null) }

        val nIdx = nakshatraIdx(moon, ayan)
        val nakshatra = PanchangElement(
            PanchangNames.nakshatra[nIdx].en, PanchangNames.nakshatra[nIdx].hi,
            transitionEnd(sunrise, 30.0) { nakshatraIndex(it) },
        )
        val yIdx = yogaIdx(sun, moon, ayan)
        val yoga = PanchangElement(
            PanchangNames.yoga[yIdx].en, PanchangNames.yoga[yIdx].hi,
            transitionEnd(sunrise, 30.0) { yogaIndex(it) },
        )
        val karanaBi = karanaName(diff)
        val karana = PanchangElement(karanaBi.en, karanaBi.hi, transitionEnd(sunrise, 18.0) { karanaIndex(it) })

        val dayCho = choghadiya(sunrise, sunset, dayStartIdx[weekday], isDay = true)
        val nightCho = choghadiya(sunset, nextSunrise, nightStartIdx[weekday], isDay = false)

        return PanchangResult(
            date = date, city = city, sunrise = sunrise, sunset = sunset,
            varaEN = PanchangNames.vara[weekday].en, varaHI = PanchangNames.vara[weekday].hi,
            tithi = tithi, nakshatra = nakshatra, yoga = yoga, karana = karana,
            dayChoghadiya = dayCho, nightChoghadiya = nightCho,
            rahu = kaal(PanchangNames.rahuKaal, rahuSeg[weekday], sunrise, sunset),
            gulika = kaal(PanchangNames.gulikaKaal, gulikaSeg[weekday], sunrise, sunset),
            yamaganda = kaal(PanchangNames.yamaganda, yamaSeg[weekday], sunrise, sunset),
            abhijit = segment(PanchangNames.abhijit, sunrise, sunset, parts = 15, seg = 8),
            varaVela = segment(PanchangNames.varaVela, sunrise, sunset, parts = 8, seg = 8),
            kalaVela = segment(PanchangNames.kalaVela, sunrise, sunset, parts = 8, seg = kalaVelaSeg[weekday]),
            kalaRatri = segment(PanchangNames.kalaRatri, sunset, nextSunrise, parts = 8, seg = kalaRatriSeg[weekday]),
            vrat = vrat,
        )
    }

    // MARK: - Element names

    private fun tithiName(diff: Double): Bi {
        val idx = minOf(29, (diff / 12).toInt())
        if (idx == 14) return PanchangNames.tithi[14]        // Purnima
        if (idx == 29) return PanchangNames.amavasya         // Amavasya
        val paksha = if (idx < 15) PanchangNames.shuklaPaksha else PanchangNames.krishnaPaksha
        val t = PanchangNames.tithi[idx % 15]
        return Bi("${paksha.en} ${t.en}", "${paksha.hi} ${t.hi}")
    }

    private fun karanaName(diff: Double): Bi {
        val idx = minOf(59, (diff / 6).toInt())
        return when (idx) {
            0 -> PanchangNames.karanaKimstughna
            57 -> PanchangNames.karanaShakuni
            58 -> PanchangNames.karanaChatushpada
            59 -> PanchangNames.karanaNaga
            else -> PanchangNames.karanaMovable[(idx - 1) % 7]
        }
    }

    private fun nakshatraIdx(moon: Double, ayan: Double): Int =
        minOf(26, (Astronomy.norm360(moon - ayan) / (360.0 / 27)).toInt())

    private fun yogaIdx(sun: Double, moon: Double, ayan: Double): Int =
        minOf(26, (Astronomy.norm360(sun + moon - 2 * ayan) / (360.0 / 27)).toInt())

    // MARK: - Transition root-finding (index increments are monotonic in time)

    private fun tithiIndex(date: Instant): Int {
        val jd = Astronomy.julianDay(date)
        return (Astronomy.norm360(Astronomy.moonLongitude(jd) - Astronomy.sunLongitude(jd)) / 12).toInt()
    }
    private fun karanaIndex(date: Instant): Int {
        val jd = Astronomy.julianDay(date)
        return (Astronomy.norm360(Astronomy.moonLongitude(jd) - Astronomy.sunLongitude(jd)) / 6).toInt()
    }
    private fun nakshatraIndex(date: Instant): Int {
        val jd = Astronomy.julianDay(date)
        return (Astronomy.norm360(Astronomy.moonLongitude(jd) - Astronomy.ayanamsaLahiri(jd)) / (360.0 / 27)).toInt()
    }
    private fun yogaIndex(date: Instant): Int {
        val jd = Astronomy.julianDay(date)
        return (Astronomy.norm360(Astronomy.sunLongitude(jd) + Astronomy.moonLongitude(jd) - 2 * Astronomy.ayanamsaLahiri(jd)) / (360.0 / 27)).toInt()
    }

    private fun transitionEnd(start: Instant, hours: Double, index: (Instant) -> Int): Instant? {
        val startIdx = index(start)
        val step = 600.0
        val limit = start.plusSec(hours * 3600)
        var prev = start
        var t = start.plusSec(step)
        while (!t.isAfter(limit)) {
            if (index(t) != startIdx) {
                var lo = prev
                var hi = t
                repeat(24) {
                    val mid = lo.plusSec(secondsBetween(lo, hi) / 2)
                    if (index(mid) == startIdx) lo = mid else hi = mid
                }
                return hi
            }
            prev = t
            t = t.plusSec(step)
        }
        return null
    }

    // MARK: - Choghadiya & Kaal windows

    private fun choghadiya(start: Instant, end: Instant, startIdx: Int, isDay: Boolean): List<Choghadiya> {
        val dur = secondsBetween(start, end) / 8.0
        // Day advances +1 through the cycle; night advances -2 (≡ +5 mod 7).
        val step = if (isDay) 1 else 5
        return (0 until 8).map { i ->
            val idx = (startIdx + step * i) % 7
            val quality = if (idx in goodIdx) ChoghadiyaQuality.GOOD
            else if (idx in neutralIdx) ChoghadiyaQuality.NEUTRAL else ChoghadiyaQuality.BAD
            val s = start.plusSec(i * dur)
            Choghadiya(cycle[idx].en, cycle[idx].hi, s, s.plusSec(dur), quality, isDay)
        }
    }

    private fun kaal(name: Bi, seg: Int, sunrise: Instant, sunset: Instant): KaalWindow {
        val part = secondsBetween(sunrise, sunset) / 8.0
        val start = sunrise.plusSec((seg - 1) * part)
        return KaalWindow(name.en, name.hi, start, start.plusSec(part))
    }

    /** The `seg`-th (1-based) slice when `from`→`to` is split into `parts` equal windows. */
    private fun segment(name: Bi, from: Instant, to: Instant, parts: Int, seg: Int): KaalWindow {
        val part = secondsBetween(from, to) / parts
        val start = from.plusSec((seg - 1) * part)
        return KaalWindow(name.en, name.hi, start, start.plusSec(part))
    }

    private fun secondsBetween(a: Instant, b: Instant): Double =
        (b.epochSecond - a.epochSecond) + (b.nano - a.nano) / 1_000_000_000.0
}
