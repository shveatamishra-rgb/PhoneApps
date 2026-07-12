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
    val CHOGH_NAME = stringPreferencesKey("choghName")
    val CHOGH_QUALITY = stringPreferencesKey("choghQuality")
    val CHOGH_TIME = stringPreferencesKey("choghTime")
    val CHOGH_CITY = stringPreferencesKey("choghCity")
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

        // Choghadiya (best-effort; needs a city). Never throws into the widget.
        var cName = ""; var cQual = ""; var cTime = ""; var cCity = ""
        runCatching {
            val city: City? = if (prefs.cityId.isNotEmpty()) cities.byId(prefs.cityId) else defaultCity(cities)
            if (city != null) {
                val now = Instant.now()
                val r = PanchangCalculator.computeForInstant(now, city)
                val cur = r?.currentChoghadiya(now)
                if (cur != null) {
                    cName = if (lang == Lang.HI) cur.nameHI else cur.nameEN
                    cQual = if (lang == Lang.HI) cur.quality.labelHI else cur.quality.labelEN
                    val fmt = DateTimeFormatter.ofPattern("h:mm a").withZone(ZoneId.systemDefault())
                    cTime = "${fmt.format(cur.start)} - ${fmt.format(cur.end)}"
                    cCity = if (lang == Lang.HI) city.nameHI else city.nameEN
                }
            }
        }

        context.widgetStore.edit {
            it[DARSHAN_IMG] = darshan.imageName
            it[DARSHAN_DEITY] = darshan.deity(lang)
            it[DARSHAN_MANTRA] = darshan.mantra(lang)
            it[CHOGH_NAME] = cName
            it[CHOGH_QUALITY] = cQual
            it[CHOGH_TIME] = cTime
            it[CHOGH_CITY] = cCity
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
