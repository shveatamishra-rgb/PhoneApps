package app.bhaktiangan.core.data

import android.content.Context
import app.bhaktiangan.core.model.Verse
import kotlinx.serialization.json.Json
import java.time.LocalDate
import java.time.temporal.ChronoField

/**
 * Loads the bundled Gita verses and picks the daily shlok. 1:1 port of iOS `VerseCatalog`.
 * Free users draw the daily verse from the free pool (always fully viewable, like the
 * daily darshan); Pro draws from the whole library. Uses a fixed day-of-year so the app
 * card and any widget agree (mirrors the iOS gregorian ordinality fix).
 */
class VerseCatalog(context: Context) {

    private val json = Json { ignoreUnknownKeys = true }

    val all: List<Verse> = runCatching {
        val text = context.assets.open("verses.json").bufferedReader().use { it.readText() }
        json.decodeFromString<List<Verse>>(text)
    }.getOrDefault(emptyList())

    val free: List<Verse> = all.filter { !it.isPremium }

    fun verse(id: String): Verse? = all.firstOrNull { it.id == id }

    /** Deterministic daily shlok; advances by day-of-year. */
    fun verseOfDay(date: LocalDate = LocalDate.now(), hasPro: Boolean = false): Verse? {
        val pool = if (hasPro) all else free
        if (pool.isEmpty()) return null
        val day = date.get(ChronoField.DAY_OF_YEAR)
        return pool[(day - 1).mod(pool.size)]
    }
}
