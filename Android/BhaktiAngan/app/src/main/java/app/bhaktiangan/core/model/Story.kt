package app.bhaktiangan.core.model

import kotlinx.serialization.Serializable

/**
 * A short katha (story) for the Katha tab, 1:1 port of iOS `Story`. Decoded from the
 * bundled `assets/stories.json`. Text-forward (no bundled art); the list uses a
 * deity-appropriate gradient cover.
 */
@Serializable
data class Story(
    val id: String,
    val deity: String,
    val titleEN: String,
    val titleHI: String,
    val eyebrowEN: String,
    val eyebrowHI: String,
    val introEN: String,
    val introHI: String,
    val bodyEN: List<String>,
    val bodyHI: List<String>,
    val moralEN: String,
    val moralHI: String,
    val isPremium: Boolean,
) {
    fun title(l: Lang) = if (l == Lang.HI) titleHI else titleEN
    fun eyebrow(l: Lang) = if (l == Lang.HI) eyebrowHI else eyebrowEN
    fun intro(l: Lang) = if (l == Lang.HI) introHI else introEN
    fun body(l: Lang) = if (l == Lang.HI) bodyHI else bodyEN
    fun moral(l: Lang) = if (l == Lang.HI) moralHI else moralEN
}
