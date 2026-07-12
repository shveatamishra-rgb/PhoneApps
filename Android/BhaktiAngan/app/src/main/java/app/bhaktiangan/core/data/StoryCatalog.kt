package app.bhaktiangan.core.data

import android.content.Context
import app.bhaktiangan.core.model.Story
import kotlinx.serialization.json.Json

/** Loads the bundled katha (`stories.json`). 1:1 port of iOS `StoryCatalog`. */
class StoryCatalog(context: Context) {
    private val json = Json { ignoreUnknownKeys = true }

    val all: List<Story> = runCatching {
        val text = context.assets.open("stories.json").bufferedReader().use { it.readText() }
        json.decodeFromString<List<Story>>(text)
    }.getOrDefault(emptyList())

    fun story(id: String): Story? = all.firstOrNull { it.id == id }
}
