package app.bhaktiangan.core.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CitiesTest {
    private val sample = """
        [["1","Delhi","Delhi, India",28.6139,77.209,"Asia/Kolkata"],
         ["2","Mumbai","Maharashtra, India",19.076,72.8777,"Asia/Kolkata"],
         ["3","Bengaluru","Karnataka, India",12.9716,77.5946,"Asia/Kolkata"],
         ["4","Delhi Cantonment","Delhi, India",28.59,77.13,"Asia/Kolkata"]]
    """.trimIndent()

    private val cities = Cities.parse(sample)

    @Test
    fun parse_readsPositionalFields() {
        assertEquals(4, cities.size)
        val delhi = cities[0]
        assertEquals("1", delhi.id)
        assertEquals("Delhi", delhi.nameEN)
        assertEquals("Delhi, India", delhi.regionEN)
        assertEquals(28.6139, delhi.latitude, 1e-6)
        assertEquals(77.209, delhi.longitude, 1e-6)
        assertEquals("Asia/Kolkata", delhi.timeZoneID)
    }

    @Test
    fun search_prefixBeatsContains() {
        val r = Cities.search(cities, "del")
        // Both "Delhi" and "Delhi Cantonment" prefix-match; they come before any contains match.
        assertEquals("Delhi", r[0].nameEN)
        assertTrue(r.any { it.nameEN == "Delhi Cantonment" })
    }

    @Test
    fun search_matchesRegion() {
        val r = Cities.search(cities, "karnataka")
        assertEquals(1, r.size)
        assertEquals("Bengaluru", r[0].nameEN)
    }

    @Test
    fun search_emptyQueryReturnsNothing_andByIdWorks() {
        assertTrue(Cities.search(cities, "   ").isEmpty())
        assertEquals("Mumbai", Cities.byId(cities, "2")?.nameEN)
        assertNull(Cities.byId(cities, "999"))
    }
}
