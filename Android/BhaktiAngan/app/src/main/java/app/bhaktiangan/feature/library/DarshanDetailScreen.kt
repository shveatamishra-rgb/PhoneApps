package app.bhaktiangan.feature.library

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.data.ContentCatalog
import app.bhaktiangan.core.media.saveDarshanWallpaper
import app.bhaktiangan.core.media.shareDarshanText
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.DarshanImage
import app.bhaktiangan.ui.s
import app.bhaktiangan.ui.tr

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DarshanDetailScreen(vm: AppViewModel, lang: Lang, imageName: String, onBack: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    val item = ContentCatalog.items.firstOrNull { it.imageName == imageName } ?: return
    val isFav = item.imageName in prefs.favorites

    Scaffold(
        containerColor = colors.ivory,
        topBar = {
            TopAppBar(
                title = { Text(item.deity(lang), fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Back", tint = colors.ink) } },
            )
        },
    ) { pad ->
        Column(Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState())) {
            DarshanImage(item.imageName, Modifier.fillMaxWidth().aspectRatio(0.72f).background(Color.Black), contentScale = ContentScale.Fit)
            Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(item.collection(lang).uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.vermilion)
                    Text(item.deity(lang), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = colors.ink)
                }
                Text(item.mantra(lang), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold, color = colors.plum)
                Text(item.meaning(lang), color = colors.muted)
                HorizontalDivider(color = colors.muted.copy(alpha = 0.18f))
                Text(item.blessing(lang), color = colors.ink)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ActionButton(if (isFav) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder, s("Favorite", "पसंद"), colors, Modifier.weight(1f)) { vm.toggleFavorite(item.imageName) }
                    ActionButton(Icons.Filled.Share, s("Share", "साझा करें"), colors, Modifier.weight(1f)) { shareDarshanText(ctx, item.shareText(lang)) }
                    ActionButton(Icons.Filled.Download, s("Save", "सहेजें"), colors, Modifier.weight(1f)) {
                        val ok = saveDarshanWallpaper(ctx, item.imageName)
                        Toast.makeText(ctx, tr(lang, if (ok) "Wallpaper saved to Photos" else "Couldn't save", if (ok) "वॉलपेपर सहेजा गया" else "सहेजा नहीं जा सका"), Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
    }
}

@Composable
private fun ActionButton(icon: ImageVector, label: String, colors: app.bhaktiangan.designsystem.BhaktiColors, modifier: Modifier, onClick: () -> Unit) {
    Column(
        modifier.clip(RoundedCornerShape(10.dp)).background(colors.paper).clickable(onClick = onClick).padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(icon, null, tint = colors.vermilion, modifier = Modifier.size(22.dp))
        Text(label, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = colors.vermilion)
    }
}
