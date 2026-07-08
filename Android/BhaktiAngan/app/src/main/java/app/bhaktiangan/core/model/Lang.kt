package app.bhaktiangan.core.model

/** The two content languages the app ships in (mirrors iOS `Lang`). */
enum class Lang { EN, HI }

/** A bilingual (English / Hindi) string pair — the iOS `PanchangNames.Bi` tuple. */
data class Bi(val en: String, val hi: String) {
    fun get(l: Lang): String = if (l == Lang.HI) hi else en
}

/**
 * User's language preference. `SYSTEM` follows the device language.
 * Resolution to [Lang] lives in the locale repository (needs the device locale).
 */
enum class AppLanguage(val storageValue: String) {
    SYSTEM("system"),
    ENGLISH("english"),
    HINDI("hindi");

    /** Shown in the Settings picker — each label in its own script. */
    val label: String
        get() = when (this) {
            SYSTEM -> "System / सिस्टम"
            ENGLISH -> "English"
            HINDI -> "हिंदी"
        }

    companion object {
        fun fromStorage(value: String?): AppLanguage =
            entries.firstOrNull { it.storageValue == value } ?: SYSTEM
    }
}
