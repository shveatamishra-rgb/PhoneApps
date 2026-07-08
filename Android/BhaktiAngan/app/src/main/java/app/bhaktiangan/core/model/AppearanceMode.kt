package app.bhaktiangan.core.model

/** User-selectable appearance (mirrors iOS `AppearanceMode`). */
enum class AppearanceMode(val storageValue: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        fun fromStorage(value: String?): AppearanceMode =
            entries.firstOrNull { it.storageValue == value } ?: SYSTEM
    }
}
