package app.bhaktiangan

import android.app.Activity
import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.bhaktiangan.core.billing.BillingManager
import app.bhaktiangan.core.data.AppPrefs
import app.bhaktiangan.core.data.CitiesRepository
import app.bhaktiangan.core.data.PreferencesRepository
import app.bhaktiangan.core.model.AppLanguage
import app.bhaktiangan.core.model.AppearanceMode
import app.bhaktiangan.core.model.Lang
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Locale

/** Resolves the active content language from the preference + device locale. */
fun resolveLang(pref: AppLanguage): Lang = when (pref) {
    AppLanguage.ENGLISH -> Lang.EN
    AppLanguage.HINDI -> Lang.HI
    AppLanguage.SYSTEM ->
        if (Locale.getDefault().language.lowercase().startsWith("hi")) Lang.HI else Lang.EN
}

/** App-wide state: persistence (favorites, japa, streak, prefs) + entitlement. */
class AppViewModel(app: Application) : AndroidViewModel(app) {
    private val repo = PreferencesRepository(app)
    val cities = CitiesRepository(app)
    val billing = BillingManager(app)

    val prefs: StateFlow<AppPrefs> =
        repo.prefs.stateIn(viewModelScope, SharingStarted.Eagerly, AppPrefs())

    /** Pro entitlement = a real Play purchase OR the debug-preview toggle. */
    val proState: StateFlow<Boolean> =
        combine(prefs, billing.hasPro) { p, b -> p.debugPro || b }
            .stateIn(viewModelScope, SharingStarted.Eagerly, false)
    val hasPro: Boolean get() = proState.value

    init {
        // Decode the ~69k-city dataset off the main thread so the picker opens fast.
        viewModelScope.launch(Dispatchers.IO) { runCatching { cities.all } }
        billing.start()
    }

    fun purchase(activity: Activity, productId: String) = billing.purchase(activity, productId)

    fun completeOnboarding(ishta: String) = launch { repo.setOnboardingDone(ishta) }
    fun setLanguage(v: AppLanguage) = launch { repo.setLanguage(v) }
    fun setAppearance(v: AppearanceMode) = launch { repo.setAppearance(v) }
    fun selectMantra(id: String) = launch { repo.setMantra(id) }
    fun setGoal(goal: Int) = launch { repo.setGoal(goal) }
    fun toggleFavorite(imageName: String) = launch { repo.toggleFavorite(imageName) }
    fun incrementJapa() = launch { repo.incrementJapa() }
    fun resetJapa() = launch { repo.resetJapa() }
    fun recordDailyVisit() = launch { repo.recordDailyVisit() }
    fun setCity(id: String) = launch { repo.setCity(id) }
    fun setUseGps(on: Boolean) = launch { repo.setUseGps(on) }
    fun setDebugPro(on: Boolean) = launch { repo.setDebugPro(on) }
    fun setReminder(enabled: Boolean, hour: Int, minute: Int) =
        launch { repo.setReminder(enabled, hour, minute) }

    private inline fun launch(crossinline block: suspend () -> Unit) {
        viewModelScope.launch { block() }
    }
}
