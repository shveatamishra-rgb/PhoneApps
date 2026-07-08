package app.bhaktiangan.core.panchang

import app.bhaktiangan.core.model.City
import app.bhaktiangan.core.model.Lang
import java.time.Instant

enum class ChoghadiyaQuality {
    GOOD, NEUTRAL, BAD;

    val labelEN: String get() = when (this) { GOOD -> "Auspicious"; BAD -> "Inauspicious"; NEUTRAL -> "Neutral" }
    val labelHI: String get() = when (this) { GOOD -> "शुभ"; BAD -> "अशुभ"; NEUTRAL -> "सामान्य" }
    fun label(l: Lang): String = if (l == Lang.HI) labelHI else labelEN
}

data class Choghadiya(
    val nameEN: String,
    val nameHI: String,
    val start: Instant,
    val end: Instant,
    val quality: ChoghadiyaQuality,
    val isDay: Boolean,
) {
    fun name(l: Lang): String = if (l == Lang.HI) nameHI else nameEN
    fun contains(date: Instant): Boolean = !date.isBefore(start) && date.isBefore(end)
}

data class KaalWindow(
    val nameEN: String,
    val nameHI: String,
    val start: Instant,
    val end: Instant,
) {
    fun name(l: Lang): String = if (l == Lang.HI) nameHI else nameEN
}

/**
 * A Panchang element (tithi/nakshatra/yoga/karana) as of sunrise, with the
 * instant it changes (null if it didn't change within the search window).
 */
data class PanchangElement(
    val nameEN: String,
    val nameHI: String,
    val endsAt: Instant?,
) {
    fun name(l: Lang): String = if (l == Lang.HI) nameHI else nameEN
}

data class PanchangResult(
    val date: Instant,
    val city: City,
    val sunrise: Instant,
    val sunset: Instant,
    val varaEN: String,
    val varaHI: String,
    val tithi: PanchangElement,
    val nakshatra: PanchangElement,
    val yoga: PanchangElement,
    val karana: PanchangElement,
    val dayChoghadiya: List<Choghadiya>,
    val nightChoghadiya: List<Choghadiya>,
    val rahu: KaalWindow,
    val gulika: KaalWindow,
    val yamaganda: KaalWindow,
    val abhijit: KaalWindow,     // auspicious midday muhurta
    val varaVela: KaalWindow,    // inauspicious (day)
    val kalaVela: KaalWindow,    // inauspicious (day)
    val kalaRatri: KaalWindow,   // inauspicious (night)
    val vrat: PanchangElement?,  // today's vrat / parva, if any (e.g. Ekadashi)
) {
    fun vara(l: Lang): String = if (l == Lang.HI) varaHI else varaEN

    fun currentChoghadiya(at: Instant): Choghadiya? =
        (dayChoghadiya + nightChoghadiya).firstOrNull { it.contains(at) }
}
