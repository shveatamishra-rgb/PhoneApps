package app.bhaktiangan.core.model

import java.time.Instant
import java.time.ZoneId

/**
 * A city for the Panchang sunrise/sunset calculation (mirrors iOS `City`).
 * Everything is on-device — no network geocoding — so the "Data Not Collected"
 * privacy posture holds.
 */
data class City(
    val id: String,
    val nameEN: String,
    val nameHI: String,
    val regionEN: String,
    val latitude: Double,
    val longitude: Double,
    val timeZoneID: String,
) {
    fun name(l: Lang): String = if (l == Lang.HI) nameHI else nameEN

    /** UTC offset (incl. DST) in seconds for the given instant. */
    fun tzSeconds(at: Instant): Int =
        runCatching { ZoneId.of(timeZoneID) }.getOrDefault(ZoneId.systemDefault())
            .rules.getOffset(at).totalSeconds
}
