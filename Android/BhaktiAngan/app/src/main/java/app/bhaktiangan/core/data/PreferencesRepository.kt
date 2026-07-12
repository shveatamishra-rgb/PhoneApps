package app.bhaktiangan.core.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import app.bhaktiangan.core.model.AppLanguage
import app.bhaktiangan.core.model.AppearanceMode
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.LocalDate

private val Context.dataStore by preferencesDataStore(name = "bhakti_prefs")

/** All persisted user state (mirrors the iOS UserDefaults keys table in the LLD). */
data class AppPrefs(
    val onboardingDone: Boolean = false,
    val language: AppLanguage = AppLanguage.SYSTEM,
    val appearance: AppearanceMode = AppearanceMode.SYSTEM,
    val favorites: Set<String> = emptySet(),
    val savedVerses: Set<String> = emptySet(),
    val selectedMantraId: String = "shiv",
    val japaCount: Int = 0,
    val japaGoal: Int = 108,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val cityId: String = "",
    val useGps: Boolean = false,
    val reminderEnabled: Boolean = false,
    val reminderHour: Int = 7,
    val reminderMinute: Int = 0,
    val debugPro: Boolean = false,
)

class PreferencesRepository(private val context: Context) {

    val prefs: Flow<AppPrefs> = context.dataStore.data.map { p ->
        val today = dayString()
        AppPrefs(
            onboardingDone = p[ONBOARDING] ?: false,
            language = AppLanguage.fromStorage(p[LANGUAGE]),
            appearance = AppearanceMode.fromStorage(p[APPEARANCE]),
            favorites = p[FAVORITES] ?: emptySet(),
            savedVerses = p[SAVED_VERSES] ?: emptySet(),
            selectedMantraId = p[MANTRA] ?: "shiv",
            japaCount = if (p[JAPA_DAY] == today) p[JAPA_COUNT] ?: 0 else 0,
            japaGoal = p[JAPA_GOAL] ?: 108,
            currentStreak = p[CUR_STREAK] ?: 0,
            bestStreak = p[BEST_STREAK] ?: 0,
            cityId = p[CITY_ID] ?: "",
            useGps = p[USE_GPS] ?: false,
            reminderEnabled = p[REMIND_ON] ?: false,
            reminderHour = p[REMIND_H] ?: 7,
            reminderMinute = p[REMIND_M] ?: 0,
            debugPro = p[DEBUG_PRO] ?: false,
        )
    }

    /** One-shot snapshot of the current prefs (for receivers that can't observe). */
    suspend fun current(): AppPrefs = prefs.first()

    suspend fun setOnboardingDone(ishta: String) = context.dataStore.edit {
        it[ONBOARDING] = true; it[MANTRA] = ishta
    }
    suspend fun setLanguage(v: AppLanguage) = context.dataStore.edit { it[LANGUAGE] = v.storageValue }
    suspend fun setAppearance(v: AppearanceMode) = context.dataStore.edit { it[APPEARANCE] = v.storageValue }
    suspend fun setMantra(id: String) = context.dataStore.edit { it[MANTRA] = id }
    suspend fun setGoal(goal: Int) = context.dataStore.edit {
        it[JAPA_GOAL] = goal
        // Keep today's count within the new goal so it never displays more than the target.
        val today = dayString()
        val count = if (it[JAPA_DAY] == today) it[JAPA_COUNT] ?: 0 else 0
        if (count > goal) { it[JAPA_DAY] = today; it[JAPA_COUNT] = goal }
    }
    suspend fun setCity(id: String) = context.dataStore.edit { it[CITY_ID] = id; it[USE_GPS] = false }
    suspend fun setUseGps(on: Boolean) = context.dataStore.edit { it[USE_GPS] = on }
    suspend fun setDebugPro(on: Boolean) = context.dataStore.edit { it[DEBUG_PRO] = on }
    suspend fun setReminder(enabled: Boolean, hour: Int, minute: Int) = context.dataStore.edit {
        it[REMIND_ON] = enabled; it[REMIND_H] = hour; it[REMIND_M] = minute
    }

    suspend fun toggleFavorite(imageName: String) = context.dataStore.edit {
        val cur = it[FAVORITES] ?: emptySet()
        it[FAVORITES] = if (imageName in cur) cur - imageName else cur + imageName
    }

    suspend fun toggleSavedVerse(id: String) = context.dataStore.edit {
        val cur = it[SAVED_VERSES] ?: emptySet()
        it[SAVED_VERSES] = if (id in cur) cur - id else cur + id
    }

    suspend fun incrementJapa() = context.dataStore.edit {
        val today = dayString()
        val count = if (it[JAPA_DAY] == today) it[JAPA_COUNT] ?: 0 else 0
        val goal = it[JAPA_GOAL] ?: 108
        it[JAPA_DAY] = today
        // Cap at the goal: a mala stops at its target (e.g. 108) instead of counting past it.
        it[JAPA_COUNT] = (count + 1).coerceAtMost(goal)
    }

    suspend fun resetJapa() = context.dataStore.edit {
        it[JAPA_DAY] = dayString(); it[JAPA_COUNT] = 0
    }

    /** Records a daily visit and keeps the darshan streak in sync (once per day). */
    suspend fun recordDailyVisit() = context.dataStore.edit {
        val today = dayString()
        if (it[LAST_VISIT] == today) return@edit
        val yesterday = dayString(LocalDate.now().minusDays(1))
        val cur = if (it[LAST_VISIT] == yesterday) (it[CUR_STREAK] ?: 0) + 1 else 1
        it[CUR_STREAK] = cur
        it[BEST_STREAK] = maxOf(it[BEST_STREAK] ?: 0, cur)
        it[LAST_VISIT] = today
    }

    private fun dayString(date: LocalDate = LocalDate.now()) = date.toString() // yyyy-MM-dd

    private companion object {
        val ONBOARDING = booleanPreferencesKey("onboardingDone")
        val LANGUAGE = stringPreferencesKey("appLanguage")
        val APPEARANCE = stringPreferencesKey("appearancePreference")
        val FAVORITES = stringSetPreferencesKey("favoriteImageNames")
        val SAVED_VERSES = stringSetPreferencesKey("savedVerseIDs")
        val MANTRA = stringPreferencesKey("selectedMantraID")
        val JAPA_COUNT = intPreferencesKey("japaCount")
        val JAPA_DAY = stringPreferencesKey("japaDay")
        val JAPA_GOAL = intPreferencesKey("japaGoal")
        val CUR_STREAK = intPreferencesKey("currentStreak")
        val BEST_STREAK = intPreferencesKey("bestStreak")
        val LAST_VISIT = stringPreferencesKey("lastVisitDay")
        val CITY_ID = stringPreferencesKey("panchangCityID")
        val USE_GPS = booleanPreferencesKey("panchangUseGPS")
        val REMIND_ON = booleanPreferencesKey("dailyReminderEnabled")
        val REMIND_H = intPreferencesKey("dailyReminderHour")
        val REMIND_M = intPreferencesKey("dailyReminderMinute")
        val DEBUG_PRO = booleanPreferencesKey("debugProEnabled")
    }
}
