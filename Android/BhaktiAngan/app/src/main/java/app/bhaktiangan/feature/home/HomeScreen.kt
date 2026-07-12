package app.bhaktiangan.feature.home

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrightnessAuto
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.data.ContentCatalog
import app.bhaktiangan.core.media.saveDarshanWallpaper
import app.bhaktiangan.core.media.shareDarshanText
import app.bhaktiangan.core.model.AppLanguage
import app.bhaktiangan.core.model.AppearanceMode
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.feature.panchang.PanchangCard
import app.bhaktiangan.ui.DarshanImage
import app.bhaktiangan.ui.s
import app.bhaktiangan.ui.tr
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun HomeScreen(
    vm: AppViewModel, lang: Lang,
    onOpenPanchang: () -> Unit,
    onOpenDetail: (String) -> Unit,
    onBeginJapa: () -> Unit,
    onOpenPaywall: () -> Unit,
    onOpenVerses: () -> Unit,
) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    val today = remember(prefs.debugPro) { ContentCatalog.dailyItem(LocalDate.now(), vm.hasPro) }
    val shlok = remember(prefs.debugPro) { vm.verses.verseOfDay(hasPro = vm.hasPro) }
    val isFav = today.imageName in prefs.favorites

    LaunchedEffect(Unit) { vm.recordDailyVisit() }

    Column(
        Modifier.fillMaxSize().background(colors.ivory).statusBarsPadding().verticalScroll(rememberScrollState()).padding(bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        // Header
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(greeting(lang), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = colors.vermilion)
                Text(dateString(lang), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = colors.ink)
                if (prefs.currentStreak > 1) {
                    Text(s("${prefs.currentStreak} day streak", "${prefs.currentStreak} दिन की श्रृंखला"),
                        style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                CircleButton(if (lang == Lang.HI) "हिं" else "EN", colors) {
                    vm.setLanguage(if (lang == Lang.HI) AppLanguage.ENGLISH else AppLanguage.HINDI)
                }
                ThemeButton(prefs.appearance, colors) { vm.setAppearance(it) }
                if (vm.hasPro) {
                    Text("PRO", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Black, color = Color.White,
                        modifier = Modifier.clip(CircleShape).background(colors.vermilion).padding(horizontal = 9.dp, vertical = 6.dp))
                } else {
                    IconCircle(Icons.Outlined.AutoAwesome, colors, onClick = onOpenPaywall)
                }
            }
        }

        PanchangCard(vm, lang, onOpen = onOpenPanchang)

        Text(s("Today's Darshan", "आज का दर्शन"), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = colors.ink, modifier = Modifier.padding(horizontal = 20.dp))

        // Hero
        Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp).height(480.dp).clip(RoundedCornerShape(18.dp))) {
            DarshanImage(today.imageName, Modifier.fillMaxSize())
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.82f)))))
            Column(Modifier.align(Alignment.BottomStart).padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(today.collection(lang).uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
                Text(today.deity(lang), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = Color.White)
                Text(today.mantra(lang), style = MaterialTheme.typography.titleMedium, color = Color.White.copy(alpha = 0.94f))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    HeroAction(if (isFav) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder, s("Favorite", "पसंद")) { vm.toggleFavorite(today.imageName) }
                    HeroAction(Icons.Filled.Share, s("Share", "साझा करें")) { shareDarshanText(ctx, today.shareText(lang)) }
                    HeroAction(Icons.Filled.Download, s("Save", "सहेजें")) {
                        val ok = saveDarshanWallpaper(ctx, today.imageName)
                        Toast.makeText(ctx, tr(lang, if (ok) "Wallpaper saved to Photos" else "Couldn't save", if (ok) "वॉलपेपर सहेजा गया" else "सहेजा नहीं जा सका"), Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }

        // One-minute practice
        Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(14.dp)).background(colors.paper).padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(s("One-minute practice", "एक मिनट का अभ्यास"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
            Text(today.meaning(lang), color = colors.ink)
            Text(today.blessing(lang), color = colors.muted)
            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(colors.teal).clickable(onClick = onBeginJapa).padding(vertical = 13.dp), contentAlignment = Alignment.Center) {
                Text(s("Begin Japa", "जप आरंभ करें"), color = Color.White, fontWeight = FontWeight.Bold)
            }
        }

        // Today's Shlok (Bhagavad Gita) — taps into the verse library
        if (shlok != null) {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(18.dp))
                    .background(Brush.linearGradient(listOf(colors.plum, colors.teal)))
                    .clickable(onClick = onOpenVerses).padding(22.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(s("Today's Shlok", "आज का श्लोक").uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
                Text(shlok.sanskrit.replace("\n", " "), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = Color.White, maxLines = 2)
                Text(shlok.meaning(lang), style = MaterialTheme.typography.bodyMedium, color = Color.White.copy(alpha = 0.92f), maxLines = 3)
                Text(shlok.source(lang), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = colors.marigold)
            }
        }

        // Explore rail
        val pool = if (vm.hasPro) ContentCatalog.items else ContentCatalog.items.take(ContentCatalog.FREE_DARSHAN_COUNT)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(s("Explore darshan", "दर्शन देखें"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink, modifier = Modifier.padding(horizontal = 20.dp))
            LazyRow(contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                items(pool, key = { it.imageName }) { item ->
                    Column(Modifier.width(142.dp).clickable { onOpenDetail(item.imageName) }, verticalArrangement = Arrangement.spacedBy(7.dp)) {
                        DarshanImage(item.imageName, Modifier.width(142.dp).height(205.dp).clip(RoundedCornerShape(12.dp)))
                        Text(item.deity(lang), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = colors.ink, maxLines = 1)
                    }
                }
            }
        }

        if (!vm.hasPro) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp).clip(RoundedCornerShape(14.dp)).background(colors.plum).clickable(onClick = onOpenPaywall).padding(18.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(Icons.Outlined.AutoAwesome, null, tint = colors.marigold)
                Column(Modifier.weight(1f)) {
                    Text(s("Unlock the full darshan library", "संपूर्ण दर्शन संग्रह अनलॉक करें"), color = Color.White, fontWeight = FontWeight.Bold)
                    Text(s("Full library, every mantra, and unlimited saves.", "पूरा संग्रह, हर मंत्र, और असीमित सेव।"), color = Color.White.copy(alpha = 0.76f), style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

@Composable
private fun CircleButton(label: String, colors: app.bhaktiangan.designsystem.BhaktiColors, onClick: () -> Unit) {
    Box(Modifier.size(42.dp).clip(CircleShape).background(colors.paper).clickable(onClick = onClick), contentAlignment = Alignment.Center) {
        Text(label, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.vermilion)
    }
}

@Composable
private fun IconCircle(icon: androidx.compose.ui.graphics.vector.ImageVector, colors: app.bhaktiangan.designsystem.BhaktiColors, onClick: () -> Unit) {
    Box(Modifier.size(42.dp).clip(CircleShape).background(colors.paper).clickable(onClick = onClick), contentAlignment = Alignment.Center) {
        Icon(icon, null, tint = colors.vermilion, modifier = Modifier.size(20.dp))
    }
}

@Composable
private fun ThemeButton(current: AppearanceMode, colors: app.bhaktiangan.designsystem.BhaktiColors, onPick: (AppearanceMode) -> Unit) {
    var open by remember { mutableStateOf(false) }
    val icon = when (current) {
        AppearanceMode.SYSTEM -> Icons.Filled.BrightnessAuto
        AppearanceMode.LIGHT -> Icons.Filled.LightMode
        AppearanceMode.DARK -> Icons.Filled.DarkMode
    }
    Box {
        IconCircle(icon, colors) { open = true }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            DropdownMenuItem(text = { Text(s("System", "सिस्टम")) }, onClick = { open = false; onPick(AppearanceMode.SYSTEM) })
            DropdownMenuItem(text = { Text(s("Light", "उजाला")) }, onClick = { open = false; onPick(AppearanceMode.LIGHT) })
            DropdownMenuItem(text = { Text(s("Dark", "अँधेरा")) }, onClick = { open = false; onPick(AppearanceMode.DARK) })
        }
    }
}

@Composable
private fun HeroAction(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, onClick: () -> Unit) {
    Row(
        Modifier.clip(CircleShape).background(Color.White.copy(alpha = 0.16f)).clickable(onClick = onClick).padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(18.dp))
        Text(label, color = Color.White, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
    }
}

private fun greeting(lang: Lang): String {
    val h = java.time.LocalTime.now().hour
    return when {
        h < 12 -> if (lang == Lang.HI) "सुप्रभात" else "Good morning"
        h < 17 -> if (lang == Lang.HI) "नमस्कार" else "Good afternoon"
        else -> if (lang == Lang.HI) "शुभ संध्या" else "Good evening"
    }
}

private fun dateString(lang: Lang): String {
    val locale = if (lang == Lang.HI) Locale("hi", "IN") else Locale.US
    return LocalDate.now().format(DateTimeFormatter.ofPattern("EEE, MMM d", locale))
}
