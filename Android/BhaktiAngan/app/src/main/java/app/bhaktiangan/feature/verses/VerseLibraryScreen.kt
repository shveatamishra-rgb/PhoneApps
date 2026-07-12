package app.bhaktiangan.feature.verses

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.core.model.Verse
import app.bhaktiangan.designsystem.BhaktiColors
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

@Composable
fun VerseLibraryScreen(
    vm: AppViewModel, lang: Lang,
    onBack: () -> Unit,
    onOpenDetail: (String) -> Unit,
    onOpenPaywall: () -> Unit,
) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    var query by remember { mutableStateOf("") }
    var theme by remember { mutableStateOf<String?>(null) }
    var savedOnly by remember { mutableStateOf(false) }

    val featured = remember(prefs.debugPro) { vm.verses.verseOfDay(hasPro = vm.hasPro) }
    val filtered = vm.verses.all.filter { v ->
        if (savedOnly && v.id !in prefs.savedVerses) return@filter false
        if (theme != null && v.theme != theme) return@filter false
        if (query.isNotBlank()) {
            val q = query.lowercase()
            val hay = listOf(v.ref, v.meaningEN, v.meaningHI, v.translit, v.themeLabel(Lang.EN), v.themeLabel(Lang.HI))
                .joinToString(" ").lowercase()
            if (!hay.contains(q)) return@filter false
        }
        true
    }

    Column(Modifier.fillMaxSize().background(colors.ivory).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clip(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, s("Back", "वापस"), tint = colors.ink)
            }
            Text(s("Bhagavad Gita", "भगवद्गीता"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
        }
        LazyColumn(
            Modifier.fillMaxSize(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            if (featured != null && query.isBlank() && theme == null && !savedOnly) {
                item {
                    Text(s("Today's Shlok", "आज का श्लोक"), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
                    Box(Modifier.padding(top = 8.dp)) { FeaturedCard(featured, lang, colors) { onOpenDetail(featured.id) } }
                }
            }
            item {
                TextField(
                    value = query, onValueChange = { query = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text(s("Search dharma, peace, karma...", "धर्म, शांति, कर्म खोजें...")) },
                    leadingIcon = { Icon(Icons.Filled.Search, null, tint = colors.muted) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions.Default,
                    shape = RoundedCornerShape(14.dp),
                    colors = TextFieldDefaults.colors(
                        focusedContainerColor = colors.paper, unfocusedContainerColor = colors.paper,
                        focusedIndicatorColor = Color.Transparent, unfocusedIndicatorColor = Color.Transparent,
                    ),
                )
            }
            item {
                Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    ThemeChip(s("Saved", "सहेजे"), savedOnly, colors) { savedOnly = !savedOnly; if (savedOnly) theme = null }
                    ThemeChip(s("All", "सभी"), theme == null && !savedOnly, colors) { theme = null; savedOnly = false }
                    Verse.themeOrder.forEach { t ->
                        val label = Verse.themeLabels[t]!![if (lang == Lang.HI) 1 else 0]
                        ThemeChip(label, theme == t, colors) { theme = if (theme == t) null else t; savedOnly = false }
                    }
                }
            }
            items(filtered, key = { it.id }) { v ->
                VerseRow(v, lang, locked = v.isPremium && !vm.hasPro, saved = v.id in prefs.savedVerses, colors) {
                    if (v.isPremium && !vm.hasPro) onOpenPaywall() else onOpenDetail(v.id)
                }
            }
            if (filtered.isEmpty()) {
                item { Text(s("No verses match your search.", "आपकी खोज से कोई श्लोक मेल नहीं खाता।"), color = colors.muted, modifier = Modifier.padding(top = 24.dp)) }
            }
        }
    }
}

@Composable
private fun FeaturedCard(v: Verse, lang: Lang, colors: BhaktiColors, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp))
            .background(Brush.linearGradient(listOf(colors.plum, colors.teal)))
            .clickable(onClick = onClick).padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("ॐ", color = colors.marigold, style = MaterialTheme.typography.headlineSmall, modifier = Modifier.align(Alignment.CenterHorizontally))
        Text(v.sanskrit.replace("\n", "\n"), color = Color.White, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(v.meaning(lang), color = Color.White.copy(alpha = 0.94f), style = MaterialTheme.typography.bodyMedium)
        Text(v.source(lang).uppercase(), color = colors.marigold, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun VerseRow(v: Verse, lang: Lang, locked: Boolean, saved: Boolean, colors: BhaktiColors, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(colors.paper)
            .clickable(onClick = onClick).padding(14.dp),
        verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(v.source(lang), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = colors.teal)
                Text(v.themeLabel(lang), style = MaterialTheme.typography.labelSmall, color = colors.muted,
                    modifier = Modifier.clip(CircleShape).background(colors.muted.copy(alpha = 0.12f)).padding(horizontal = 7.dp, vertical = 2.dp))
                if (saved) Icon(Icons.Filled.Bookmark, null, tint = colors.marigold, modifier = Modifier.size(14.dp))
            }
            Text(v.sanskrit.replace("\n", " "), style = MaterialTheme.typography.bodyMedium, color = colors.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            // Locked rows blur the meaning so search cannot read Pro translations for free.
            Text(v.meaning(lang), style = MaterialTheme.typography.bodySmall, color = colors.muted, maxLines = 2, overflow = TextOverflow.Ellipsis,
                modifier = if (locked) Modifier.blur(5.dp) else Modifier)
        }
        Icon(if (locked) Icons.Filled.Lock else Icons.Filled.ChevronRight, null, tint = if (locked) colors.marigold else colors.muted, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun ThemeChip(label: String, selected: Boolean, colors: BhaktiColors, onClick: () -> Unit) {
    Text(
        label,
        style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold,
        color = if (selected) Color.White else colors.teal,
        modifier = Modifier.clip(CircleShape)
            .then(if (selected) Modifier.background(colors.teal) else Modifier.border(1.dp, colors.teal.copy(alpha = 0.4f), CircleShape))
            .clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
