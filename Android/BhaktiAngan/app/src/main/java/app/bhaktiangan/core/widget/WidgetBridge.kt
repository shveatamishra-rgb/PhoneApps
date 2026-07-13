package app.bhaktiangan.core.widget

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.glance.appwidget.updateAll
import app.bhaktiangan.core.data.AppPrefs
import app.bhaktiangan.core.data.CitiesRepository
import app.bhaktiangan.core.data.ContentCatalog
import app.bhaktiangan.core.data.VerseCatalog
import app.bhaktiangan.core.model.City
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.core.panchang.PanchangCalculator
import kotlinx.coroutines.flow.first
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/**
 * App-side bridge for the home-screen widgets (mirrors the iOS App-Group bridge). The app
 * computes the current darshan / choghadiya / shlok on foreground and writes rendered,
 * active-language strings to a small DataStore. The Glance widgets only read this store, so
 * they stay light and need no heavy compute in the widget process. No network.
 */
object WidgetBridge {

    private val Context.widgetStore by preferencesDataStore(name = "widget_bridge")

    val DARSHAN_IMG = stringPreferencesKey("darshanImg")
    val DARSHAN_DEITY = stringPreferencesKey("darshanDeity")
    val DARSHAN_MANTRA = stringPreferencesKey("darshanMantra")
    val CHOGH_CITY = stringPreferencesKey("choghCity")
    val CHOGH_TZ = stringPreferencesKey("choghTz")
    // Full day+night periods (today and tomorrow) so the widget can advance the current
    // muhurat itself between app opens: "nameEN|nameHI|QUALITY|startMs|endMs;..."
    val CHOGH_PERIODS = stringPreferencesKey("choghPeriods")
    val SHLOK_SANSKRIT = stringPreferencesKey("shlokSanskrit")
    val SHLOK_MEANING = stringPreferencesKey("shlokMeaning")
    val SHLOK_SOURCE = stringPreferencesKey("shlokSource")

    suspend fun read(context: Context, key: androidx.datastore.preferences.core.Preferences.Key<String>): String =
        context.widgetStore.data.first()[key] ?: ""

    /** Computes today's widget data and refreshes all widgets. Safe to call on every foreground. */
    suspend fun refresh(context: Context, prefs: AppPrefs, cities: CitiesRepository, verses: VerseCatalog, hasPro: Boolean) {
        val lang = if (prefs.language.name == "HINDI" ||
            (prefs.language.name == "SYSTEM" && java.util.Locale.getDefault().language.startsWith("hi"))) Lang.HI else Lang.EN

        val darshan = ContentCatalog.dailyItem(LocalDate.now(), hasPro)
        val shlok = verses.verseOfDay(hasPro = hasPro)

        // Choghadiya: store the full day+night periods for today AND tomorrow (city tz),
        // so the widget can advance the current muhurat itself between app opens.
        var cCity = ""; var cTz = ""; var cPeriods = ""
        runCatching {
            val city: City? = if (prefs.cityId.isNotEmpty()) cities.byId(prefs.cityId) else defaultCity(cities)
            if (city != null) {
                val now = Instant.now()
                val periods = buildList {
                    PanchangCalculator.computeForInstant(now, city)?.let { addAll(it.dayChoghadiya); addAll(it.nightChoghadiya) }
                    PanchangCalculator.computeForInstant(now.plus(java.time.Duration.ofHours(24)), city)?.let { addAll(it.dayChoghadiya); addAll(it.nightChoghadiya) }
                }.distinctBy { it.start }.sortedBy { it.start }
                cCity = if (lang == Lang.HI) city.nameHI else city.nameEN
                cTz = city.timeZoneID
                cPeriods = periods.joinToString(";") {
                    val nm = if (lang == Lang.HI) it.nameHI else it.nameEN
                    "$nm|${it.quality.name}|${it.start.toEpochMilli()}|${it.end.toEpochMilli()}"
                }
            }
        }

        context.widgetStore.edit {
            it[DARSHAN_IMG] = darshan.imageName
            it[DARSHAN_DEITY] = darshan.deity(lang)
            it[DARSHAN_MANTRA] = darshan.mantra(lang)
            it[CHOGH_CITY] = cCity
            it[CHOGH_TZ] = cTz
            it[CHOGH_PERIODS] = cPeriods
            it[SHLOK_SANSKRIT] = shlok?.sanskrit?.replace("\n", " ") ?: ""
            it[SHLOK_MEANING] = shlok?.meaning(lang) ?: ""
            it[SHLOK_SOURCE] = shlok?.source(lang) ?: ""
        }

        runCatching { DarshanWidget().updateAll(context) }
        runCatching { ChoghadiyaWidget().updateAll(context) }
        runCatching { ShlokWidget().updateAll(context) }
    }

    /** A sensible first-paint city (Delhi) when the user has not picked one yet. */
    private fun defaultCity(cities: CitiesRepository): City? =
        cities.byId("1273294") ?: cities.all.firstOrNull { it.nameEN == "Delhi" } ?: cities.all.firstOrNull()
}
