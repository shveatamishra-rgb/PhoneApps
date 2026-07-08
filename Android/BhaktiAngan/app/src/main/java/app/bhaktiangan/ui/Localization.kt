package app.bhaktiangan.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import app.bhaktiangan.core.model.Lang

/** Active content language, provided at the app root from the saved preference. */
val LocalLang = staticCompositionLocalOf { Lang.EN }

/** Bilingual string helper (mirrors iOS `loc.s(en, hi)`). */
@Composable
@ReadOnlyComposable
fun s(en: String, hi: String): String = if (LocalLang.current == Lang.HI) hi else en

/** Non-composable variant for use inside callbacks/lambdas where [lang] is in scope. */
fun tr(lang: Lang, en: String, hi: String): String = if (lang == Lang.HI) hi else en
