package app.bhaktiangan.core.model

/** Library filter categories (mirrors iOS `DeityCategory`). `rawValue` is the EN label. */
enum class DeityCategory(val rawValue: String, private val hindi: String) {
    ALL("All", "सभी"),
    SHIVA("Shiva", "शिव"),
    VISHNU("Vishnu", "विष्णु"),
    SHAKTI("Devi", "देवी"),
    RAMA("Rama", "राम"),
    KRISHNA("Krishna", "कृष्ण"),
    GANESHA("Ganesha", "गणेश");

    fun label(l: Lang): String = if (l == Lang.HI) hindi else rawValue
}
