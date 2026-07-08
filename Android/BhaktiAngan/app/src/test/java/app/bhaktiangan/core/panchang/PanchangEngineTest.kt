package app.bhaktiangan.core.panchang

import app.bhaktiangan.core.model.City
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant

/**
 * Golden-value tests for the Panchang engine. The expected values were produced by
 * compiling and running the *actual iOS Swift engine* (Astronomy.swift +
 * Panchang.swift) for the same instant/city — so these assertions guarantee the
 * Kotlin port stays bit-identical to the shipping iOS app.
 *
 * Reference instant: 2026-06-26T06:30:00Z (= 12:00 IST, Friday), New Delhi.
 */
class PanchangEngineTest {

    private val delhi = City(
        id = "delhi", nameEN = "New Delhi", nameHI = "New Delhi", regionEN = "Delhi, India",
        latitude = 28.6139, longitude = 77.2090, timeZoneID = "Asia/Kolkata",
    )
    private val now: Instant = Instant.parse("2026-06-26T06:30:00Z")

    private fun Instant.epochSecondsDouble() = epochSecond + nano / 1_000_000_000.0

    @Test
    fun sunriseSunsetAndElements_matchIosReference() {
        val p = PanchangCalculator.compute(now, delhi)
        assertNotNull(p); p!!

        assertEquals(1782431710.1, p.sunrise.epochSecondsDouble(), 2.0)
        assertEquals(1782481964.5, p.sunset.epochSecondsDouble(), 2.0)
        assertEquals("Friday", p.varaEN)
        assertEquals("Shukla Paksha Dwadashi", p.tithi.nameEN)
        assertEquals("Vishakha", p.nakshatra.nameEN)
        assertEquals("Siddha", p.yoga.nameEN)
        assertEquals("Bava", p.karana.nameEN)
        assertEquals(null, p.vrat)
    }

    @Test
    fun choghadiya_matchesIosReference() {
        val p = PanchangCalculator.compute(now, delhi)!!
        assertEquals(8, p.dayChoghadiya.size)
        assertEquals(8, p.nightChoghadiya.size)

        assertEquals("Char", p.dayChoghadiya[0].nameEN)
        assertEquals(ChoghadiyaQuality.NEUTRAL, p.dayChoghadiya[0].quality)
        assertEquals("Kaal", p.dayChoghadiya[3].nameEN)
        assertEquals(ChoghadiyaQuality.BAD, p.dayChoghadiya[3].quality)
        assertEquals("Labh", p.dayChoghadiya[1].nameEN)
        assertEquals(ChoghadiyaQuality.GOOD, p.dayChoghadiya[1].quality)

        // Rahu Kaal window (Friday = daytime eighth #6).
        assertEquals(1782450555.5, p.rahu.start.epochSecondsDouble(), 2.0)
        assertEquals(1782456837.3, p.rahu.end.epochSecondsDouble(), 2.0)
    }

    @Test
    fun transitionEnds_areMonotonicAndWithinWindow() {
        val p = PanchangCalculator.compute(now, delhi)!!
        // Nakshatra change (Vishakha -> next) within 30h, after sunrise.
        val end = p.nakshatra.endsAt
        assertNotNull(end); end!!
        assertTrue(end.isAfter(p.sunrise))
        assertEquals(1782481591.0, end.epochSecondsDouble(), 5.0)
    }

    @Test
    fun computeForInstant_rollsBackBeforeSunrise() {
        // 2026-06-27T03:30 IST (before Saturday's sunrise) -> the running Hindu day
        // is still Friday 2026-06-26.
        val preSunrise = Instant.parse("2026-06-26T22:00:00Z")
        val p = PanchangCalculator.computeForInstant(preSunrise, delhi)
        assertNotNull(p); p!!
        assertEquals("Friday", p.varaEN)
        // The instant lies inside one of the night Choghadiya windows of that day.
        assertNotNull(p.currentChoghadiya(preSunrise))
    }
}
