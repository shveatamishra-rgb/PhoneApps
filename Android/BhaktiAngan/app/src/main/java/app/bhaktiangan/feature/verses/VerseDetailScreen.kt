package app.bhaktiangan.feature.verses

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.media.VerseShareCard
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

@Composable
fun VerseDetailScreen(vm: AppViewModel, lang: Lang, id: String, onBack: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    val verse = vm.verses.verse(id) ?: run { onBack(); return }
    val saved = verse.id in prefs.savedVerses

    Column(Modifier.fillMaxSize().background(colors.ivory).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clip(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, s("Back", "वापस"), tint = colors.ink)
            }
            Text(verse.ref, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Text(verse.source(lang).uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
            Text(verse.sanskrit, style = MaterialTheme.typography.headlineSmall, color = colors.ink, lineHeight = MaterialTheme.typography.headlineSmall.fontSize.times(1.5f))
            Text(verse.translit, style = MaterialTheme.typography.bodyMedium, fontStyle = FontStyle.Italic, color = colors.muted)
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(colors.teal.copy(alpha = 0.10f)).padding(16.dp)) {
                Text(verse.meaning(lang), style = MaterialTheme.typography.bodyLarge, color = colors.ink)
            }
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(colors.paper).padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(s("Live it today", "आज इसे जिएँ"), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
                Text(verse.live(lang), style = MaterialTheme.typography.bodyLarge, fontStyle = FontStyle.Italic, color = colors.ink)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                ActionButton(if (saved) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                    if (saved) s("Saved", "सहेजा") else s("Save", "सहेजें"), colors, Modifier.weight(1f)) { vm.toggleSavedVerse(verse.id) }
                ActionButton(Icons.Filled.Share, s("Share", "साझा करें"), colors, Modifier.weight(1f)) { VerseShareCard.share(ctx, verse, lang) }
            }
        }
    }
}

@Composable
private fun ActionButton(icon: ImageVector, label: String, colors: app.bhaktiangan.designsystem.BhaktiColors, modifier: Modifier, onClick: () -> Unit) {
    Row(
        modifier.clip(RoundedCornerShape(12.dp)).background(colors.teal.copy(alpha = 0.12f)).clickable(onClick = onClick).padding(vertical = 13.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = colors.teal, modifier = Modifier.size(18.dp))
        Text("  $label", color = colors.teal, fontWeight = FontWeight.SemiBold)
    }
}
