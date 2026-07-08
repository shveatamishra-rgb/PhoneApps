package app.bhaktiangan.feature.panchang

import app.bhaktiangan.core.model.Lang
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private fun zone(id: String): ZoneId = runCatching { ZoneId.of(id) }.getOrDefault(ZoneId.systemDefault())
private val US = Locale.US

fun clockString(t: Instant, tz: String): String =
    DateTimeFormatter.ofPattern("h:mm a", US).withZone(zone(tz)).format(t)

private fun dateSuffix(t: Instant, tz: String): String =
    DateTimeFormatter.ofPattern("MMM d", US).withZone(zone(tz)).format(t)

private fun sameDay(a: Instant, b: Instant, tz: String): Boolean =
    a.atZone(zone(tz)).toLocalDate() == b.atZone(zone(tz)).toLocalDate()

/** "h:mm a", plus " MMM d" when [t] is a different civil day than [ref]. */
fun clockWithDate(t: Instant, ref: Instant, tz: String): String =
    if (sameDay(t, ref, tz)) clockString(t, tz) else clockString(t, tz) + " " + dateSuffix(t, tz)

/** A "start – end" range that prints the date whenever it crosses midnight. */
fun rangeString(start: Instant, end: Instant, ref: Instant, tz: String): String =
    clockWithDate(start, ref, tz) + " – " + clockWithDate(end, start, tz)

/** Full weekday + date for the Panchang (Hindu) day, e.g. "Wednesday, Jun 24". */
fun dayString(t: Instant, tz: String, lang: Lang): String {
    val locale = if (lang == Lang.HI) Locale("hi", "IN") else US
    return DateTimeFormatter.ofPattern("EEEE, MMM d", locale).withZone(zone(tz)).format(t)
}
