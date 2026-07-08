package app.bhaktiangan.core.data

import android.content.Context
import app.bhaktiangan.core.model.City
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.double
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive

/**
 * Pure (JVM-testable) parsing + search over the bundled city list. 1:1 port of the
 * iOS `Cities` logic. The data is a compact positional JSON array
 * `[id, name, region, lat, lon, tz]`, sorted by population (largest first).
 */
object Cities {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    fun parse(jsonText: String): List<City> {
        return json.parseToJsonElement(jsonText).jsonArray.map { row ->
            val a = row.jsonArray
            val name = a[1].jsonPrimitive.content
            City(
                id = a[0].jsonPrimitive.content,
                nameEN = name,
                nameHI = name, // place names stay romanized in both languages
                regionEN = a[2].jsonPrimitive.content,
                latitude = a[3].jsonPrimitive.double,
                longitude = a[4].jsonPrimitive.double,
                timeZoneID = a[5].jsonPrimitive.content,
            )
        }
    }

    fun byId(all: List<City>, id: String): City? = all.firstOrNull { it.id == id }

    /** Name-prefix matches first, then name/region "contains", capped at [limit]. */
    fun search(all: List<City>, query: String, limit: Int = 50): List<City> {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return emptyList()
        val prefix = ArrayList<City>()
        val contains = ArrayList<City>()
        for (city in all) {
            val name = city.nameEN.lowercase()
            if (name.startsWith(q)) {
                prefix.add(city)
            } else if (name.contains(q) || city.regionEN.lowercase().contains(q)) {
                contains.add(city)
            }
            if (prefix.size >= limit) break
        }
        return (prefix + contains).take(limit)
    }
}

/**
 * Loads the bundled `assets/cities.json` once. `all` triggers a 5+ MB parse, so
 * access it off the main thread (e.g. `withContext(Dispatchers.Default)`).
 */
class CitiesRepository(private val context: Context) {
    val all: List<City> by lazy {
        context.assets.open("cities.json").bufferedReader().use { Cities.parse(it.readText()) }
    }

    fun byId(id: String): City? = Cities.byId(all, id)
    fun search(query: String, limit: Int = 50): List<City> = Cities.search(all, query, limit)
}
