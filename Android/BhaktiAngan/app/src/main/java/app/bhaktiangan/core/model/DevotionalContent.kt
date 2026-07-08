package app.bhaktiangan.core.model

/** A daily darshan entry (mirrors iOS `DevotionalItem`). `imageName` is the id. */
data class DevotionalItem(
    val day: Int,
    val imageName: String,
    val deityEN: String,
    val deityHI: String,
    val category: DeityCategory,
    val mantraEN: String,
    val mantraHI: String,
    val meaningEN: String,
    val meaningHI: String,
    val blessingEN: String,
    val blessingHI: String,
    val isPremium: Boolean,
) {
    val id: String get() = imageName

    fun deity(l: Lang) = if (l == Lang.HI) deityHI else deityEN
    fun mantra(l: Lang) = if (l == Lang.HI) mantraHI else mantraEN
    fun meaning(l: Lang) = if (l == Lang.HI) meaningHI else meaningEN
    fun blessing(l: Lang) = if (l == Lang.HI) blessingHI else blessingEN
    fun collection(l: Lang) = category.label(l)

    fun shareText(l: Lang): String {
        val footer = if (l == Lang.HI) "भक्ति आँगन से साझा किया गया" else "Shared from Bhakti Angan"
        return "${deity(l)}\n\n${mantra(l)}\n\n${blessing(l)}\n\n$footer"
    }
}

/** A selectable japa mantra (mirrors iOS `MantraChoice`). */
data class MantraChoice(
    val id: String,
    val deityEN: String,
    val deityHI: String,
    val mantraEN: String,
    val mantraHI: String,
    val meaningEN: String,
    val meaningHI: String,
    val isPremium: Boolean,
) {
    fun deity(l: Lang) = if (l == Lang.HI) deityHI else deityEN
    fun mantra(l: Lang) = if (l == Lang.HI) mantraHI else mantraEN
    fun meaning(l: Lang) = if (l == Lang.HI) meaningHI else meaningEN
}
