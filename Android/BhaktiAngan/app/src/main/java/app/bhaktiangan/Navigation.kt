package app.bhaktiangan

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Photo
import androidx.compose.material.icons.filled.RadioButtonChecked
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import app.bhaktiangan.core.model.AppearanceMode
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiAnganTheme
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.feature.home.HomeScreen
import app.bhaktiangan.feature.japa.JapaScreen
import app.bhaktiangan.feature.library.DarshanDetailScreen
import app.bhaktiangan.feature.library.LibraryScreen
import app.bhaktiangan.feature.onboarding.OnboardingScreen
import app.bhaktiangan.feature.panchang.PanchangScreen
import app.bhaktiangan.feature.paywall.PaywallScreen
import app.bhaktiangan.feature.settings.LegalScreen
import app.bhaktiangan.feature.settings.SettingsScreen
import app.bhaktiangan.feature.settings.SupportScreen
import app.bhaktiangan.ui.LocalLang

@Composable
fun BhaktiRoot(vm: AppViewModel) {
    val prefs by vm.prefs.collectAsState()
    val lang = resolveLang(prefs.language)
    val dark = when (prefs.appearance) {
        AppearanceMode.SYSTEM -> isSystemInDarkTheme()
        AppearanceMode.LIGHT -> false
        AppearanceMode.DARK -> true
    }
    BhaktiAnganTheme(darkTheme = dark) {
        CompositionLocalProvider(LocalLang provides lang) {
            if (!prefs.onboardingDone) OnboardingScreen(vm, lang) else MainScaffold(vm, lang)
        }
    }
}

private data class Tab(val route: String, val en: String, val hi: String, val icon: ImageVector)

@Composable
private fun MainScaffold(vm: AppViewModel, lang: Lang) {
    val nav = rememberNavController()
    val colors = BhaktiTheme.colors
    val tabs = listOf(
        Tab("today", "Today", "आज", Icons.Filled.WbSunny),
        Tab("darshan", "Darshan", "दर्शन", Icons.Filled.Photo),
        Tab("japa", "Japa", "जप", Icons.Filled.RadioButtonChecked),
        Tab("settings", "Settings", "सेटिंग्स", Icons.Filled.Settings),
    )
    val topRoutes = tabs.map { it.route }.toSet()
    val backStack by nav.currentBackStackEntryAsState()
    val current = backStack?.destination?.route

    fun switchTab(route: String) = nav.navigate(route) {
        popUpTo(nav.graph.findStartDestination().id) { saveState = true }
        launchSingleTop = true
        restoreState = true
    }

    Scaffold(
        containerColor = colors.ivory,
        bottomBar = {
            if (current in topRoutes) {
                NavigationBar(containerColor = colors.paper) {
                    tabs.forEach { t ->
                        NavigationBarItem(
                            selected = current == t.route,
                            onClick = { switchTab(t.route) },
                            icon = { Icon(t.icon, null) },
                            label = { Text(if (lang == Lang.HI) t.hi else t.en) },
                        )
                    }
                }
            }
        },
    ) { pad ->
        NavHost(nav, startDestination = "today", modifier = Modifier.padding(bottom = pad.calculateBottomPadding())) {
            composable("today") {
                HomeScreen(vm, lang,
                    onOpenPanchang = { nav.navigate("panchang") },
                    onOpenDetail = { nav.navigate("detail/$it") },
                    onBeginJapa = { switchTab("japa") },
                    onOpenPaywall = { nav.navigate("paywall") })
            }
            composable("darshan") {
                LibraryScreen(vm, lang, onOpenDetail = { nav.navigate("detail/$it") }, onOpenPaywall = { nav.navigate("paywall") })
            }
            composable("japa") {
                JapaScreen(vm, lang, onLockedMantra = { nav.navigate("paywall") })
            }
            composable("settings") {
                SettingsScreen(
                    vm, lang,
                    onOpenPaywall = { nav.navigate("paywall") },
                    onOpenSupport = { nav.navigate("support") },
                    onOpenLegal = { nav.navigate("legal/$it") },
                )
            }
            composable("support") {
                SupportScreen(lang, onBack = { nav.popBackStack() })
            }
            composable("legal/{kind}") { entry ->
                LegalScreen(entry.arguments?.getString("kind") ?: "privacy", lang, onBack = { nav.popBackStack() })
            }
            composable("panchang") {
                PanchangScreen(vm, lang, onBack = { nav.popBackStack() })
            }
            composable("detail/{name}") { entry ->
                DarshanDetailScreen(vm, lang, entry.arguments?.getString("name") ?: "", onBack = { nav.popBackStack() })
            }
            composable("paywall") {
                PaywallScreen(vm, lang, onClose = { nav.popBackStack() })
            }
        }
    }
}
