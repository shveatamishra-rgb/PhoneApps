package app.bhaktiangan.designsystem

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/** Exact brand tokens, used directly by screens (mirrors how iOS uses AppTheme.*). */
@Immutable
data class BhaktiColors(
    val ivory: Color,
    val paper: Color,
    val vermilion: Color,
    val marigold: Color,
    val plum: Color,
    val teal: Color,
    val ink: Color,
    val muted: Color,
)

private val LightBhakti = BhaktiColors(
    ivory = IvoryLight, paper = PaperLight, vermilion = VermilionLight, marigold = MarigoldLight,
    plum = PlumLight, teal = TealLight, ink = InkLight, muted = MutedLight,
)
private val DarkBhakti = BhaktiColors(
    ivory = IvoryDark, paper = PaperDark, vermilion = VermilionDark, marigold = MarigoldDark,
    plum = PlumDark, teal = TealDark, ink = InkDark, muted = MutedDark,
)

val LocalBhaktiColors = staticCompositionLocalOf { LightBhakti }

/** `BhaktiTheme.colors.vermilion` etc. — the app's palette accessor. */
object BhaktiTheme {
    val colors: BhaktiColors
        @Composable @ReadOnlyComposable get() = LocalBhaktiColors.current
}

@Composable
fun BhaktiAnganTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val bhakti = if (darkTheme) DarkBhakti else LightBhakti
    val scheme = if (darkTheme) {
        darkColorScheme(
            primary = bhakti.vermilion, secondary = bhakti.teal, tertiary = bhakti.marigold,
            background = bhakti.ivory, surface = bhakti.paper, onPrimary = Color.White,
            onBackground = bhakti.ink, onSurface = bhakti.ink, onSurfaceVariant = bhakti.muted,
        )
    } else {
        lightColorScheme(
            primary = bhakti.vermilion, secondary = bhakti.teal, tertiary = bhakti.marigold,
            background = bhakti.ivory, surface = bhakti.paper, onPrimary = Color.White,
            onBackground = bhakti.ink, onSurface = bhakti.ink, onSurfaceVariant = bhakti.muted,
        )
    }
    CompositionLocalProvider(LocalBhaktiColors provides bhakti) {
        MaterialTheme(colorScheme = scheme, content = content)
    }
}
