package app.bhaktiangan.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import app.bhaktiangan.designsystem.BhaktiTheme

/** Resolves a bundled darshan drawable by its imageName (e.g. "day1_shiv"). 0 if missing. */
@Composable
fun darshanResId(imageName: String): Int {
    val ctx = LocalContext.current
    return remember(imageName) {
        ctx.resources.getIdentifier(imageName, "drawable", ctx.packageName)
    }
}

/** Shows a darshan image, with a graceful placeholder if the drawable isn't bundled. */
@Composable
fun DarshanImage(
    imageName: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
) {
    val id = darshanResId(imageName)
    if (id != 0) {
        Image(
            painter = painterResource(id),
            contentDescription = null,
            modifier = modifier,
            contentScale = contentScale,
        )
    } else {
        Box(
            modifier.background(BhaktiTheme.colors.muted.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Image, null, tint = BhaktiTheme.colors.muted.copy(alpha = 0.5f))
        }
    }
}
