package app.bhaktiangan.core.model

import kotlinx.serialization.Serializable

/**
 * A Bhagavad Gita verse (shlok), 1:1 port of iOS `Verse`. Decoded from the bundled
 * `assets/verses.json` (same file the iOS app ships). No network.
 * Sanskrit is public domain; EN/HI meanings + "live it today" lines are an authored
 * draft pending native-speaker review (see the v1.2 checklist).
 */
@Serializable
data class Verse(
    val id: String,
    val ref: String,          // "2.47" for display
    val chapter: Int,
    val verse: Int,
    val theme: String,        // karma, dharma, devotion, peace, self
    val sanskrit: String,     // Devanagari, lines joined with \n
    val translit: String,
    val meaningEN: String,
    val meaningHI: String,
    val liveEN: String,       // one-line "live it today"
    val liveHI: String,
    val isPremium: Boolean,
) {
    fun meaning(l: Lang) = if (l == Lang.HI) meaningHI else meaningEN
    fun live(l: Lang) = if (l == Lang.HI) liveHI else liveEN

    /** Localized source label, e.g. "Bhagavad Gita 2.47" / "भगवद्गीता 2.47". */
    fun source(l: Lang) = (if (l == Lang.HI) "भगवद्गीता " else "Bhagavad Gita ") + ref

    /** Localized theme label for chips/filters. */
    fun themeLabel(l: Lang) =
        themeLabels[theme]?.get(if (l == Lang.HI) 1 else 0) ?: theme.replaceFirstChar { it.uppercase() }

    fun shareText(l: Lang): String {
        val footer = if (l == Lang.HI) "भक्ति आँगन से साझा किया गया" else "Shared from Bhakti Angan"
        return "${sanskrit.replace("\n", " ")}\n\n${meaning(l)}\n\n${source(l)}\n$footer"
    }

    companion object {
        val themeLabels: Map<String, List<String>> = mapOf(
            "karma" to listOf("Action", "कर्म"),
            "dharma" to listOf("Duty", "धर्म"),
            "devotion" to listOf("Devotion", "भक्ति"),
            "peace" to listOf("Peace", "शांति"),
            "self" to listOf("The Self", "आत्मा"),
        )
        val themeOrder = listOf("karma", "dharma", "devotion", "peace", "self")
    }
}
