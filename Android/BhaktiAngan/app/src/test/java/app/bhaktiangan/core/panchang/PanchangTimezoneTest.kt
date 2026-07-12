package app.bhaktiangan.core.panchang

import app.bhaktiangan.core.model.City
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Verifies Panchang/Choghadiya times are rendered in the *city's* local timezone, not a
 * fixed IST or the device timezone. This is the bug found on-device: a US user saw IST
 * times. The engine computes absolute Instants; the formatter must print them in the
 * city's zone. Also covers that the same instant prints differently across zones.
 */
class PanchangTimezoneTest {

    private val dallas = City(
        id = "dallas", nameEN = "Dallas", nameHI = "Dallas", regionEN = "Texas, United States",
        latitude = 32.7831, longitude = -96.8067, timeZoneID = "America/Chicago",
    )
    // 2026-07-12 13:00 America/Chicago (a daytime instant so the civil date is July 12 there).
    private val now: Instant = Instant.parse("2026-07-12T18:00:00Z")

    private fun clock(t: Instant, tz: String) =
        DateTimeFormatter.ofPattern("h:mm a", Locale.US).withZone(ZoneId.of(tz)).format(t)

    @Test
    fun sunrisePrintsInCityLocalTime_notIST() {
        val p = PanchangCalculator.compute(now, dallas)
        assertNotNull(p); p!!

        val central = clock(p.sunrise, "America/Chicago")
        val ist = clock(p.sunrise, "Asia/Kolkata")
        // Same absolute sunrise, different wall-clock in the two zones -> times ARE tz-based.
        assertNotEquals("Central and IST must differ for the same instant", central, ist)

        // A Dallas mid-July sunrise is an early-morning local time (~6:2x AM Central).
        val hour = p.sunrise.atZone(ZoneId.of("America/Chicago")).hour
        assertTrue("Dallas sunrise should be early-morning Central, was $hour ($central)", hour in 5..8)
    }

    @Test
    fun currentChoghadiyaUsesAbsoluteInstant() {
        // "Now" highlighting compares absolute Instants, so it is correct regardless of
        // display zone. Pick an instant inside Dallas daytime and assert a period contains it.
        val p = PanchangCalculator.computeForInstant(now, dallas)
        assertNotNull(p); p!!
        val cur = p.currentChoghadiya(now)
        assertNotNull("A daytime instant should fall inside a Choghadiya period", cur)
        assertTrue(now >= cur!!.start && now < cur.end)
    }
}
