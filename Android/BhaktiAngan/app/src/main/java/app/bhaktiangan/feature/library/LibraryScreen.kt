@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package app.bhaktiangan.feature.library

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.data.ContentCatalog
import app.bhaktiangan.core.model.DeityCategory
import app.bhaktiangan.core.model.DevotionalItem
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.DarshanImage
import app.bhaktiangan.ui.s

@Composable
fun LibraryScreen(vm: AppViewModel, lang: Lang, onOpenDetail: (String) -> Unit, onOpenPaywall: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf(DeityCategory.ALL) }

    val items = remember(query, category) {
        ContentCatalog.items.filter { item ->
            val catOk = category == DeityCategory.ALL || item.category == category
            val q = query.trim()
            val qOk = q.isEmpty() ||
                item.deityEN.contains(q, true) || item.deityHI.contains(q) ||
                item.mantraEN.contains(q, true) || item.mantraHI.contains(q)
            catOk && qOk
        }
    }

    Scaffold(
        containerColor = colors.ivory,
        topBar = { TopAppBar(title = { Text(s("Darshan Library", "दर्शन संग्रह"), fontWeight = FontWeight.SemiBold) }) },
    ) { pad ->
        Column(Modifier.padding(pad).fillMaxSize()) {
            OutlinedTextField(
                value = query, onValueChange = { query = it }, singleLine = true,
                placeholder = { Text(s("Search Shiva, Krishna, Devi…", "शिव, कृष्ण, देवी खोजें…")) },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            )
            LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(DeityCategory.entries.toList()) { c ->
                    val sel = c == category
                    Text(
                        c.label(lang), fontWeight = FontWeight.SemiBold,
                        color = if (sel) Color.White else colors.ink,
                        modifier = Modifier.clip(CircleShape).background(if (sel) colors.vermilion else colors.paper).clickable { category = c }.padding(horizontal = 14.dp, vertical = 9.dp),
                    )
                }
            }
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxSize(),
            ) {
                items(items, key = { it.imageName }) { item ->
                    val locked = item.isPremium && !vm.hasPro
                    LibraryCard(item, lang, colors, locked, isFav = item.imageName in prefs.favorites) {
                        if (locked) onOpenPaywall() else onOpenDetail(item.imageName)
                    }
                }
            }
        }
    }
}

@Composable
private fun LibraryCard(item: DevotionalItem, lang: Lang, colors: app.bhaktiangan.designsystem.BhaktiColors, locked: Boolean, isFav: Boolean, onClick: () -> Unit) {
    Column(Modifier.clickable(onClick = onClick), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.fillMaxWidth().height(245.dp).clip(RoundedCornerShape(12.dp))) {
            DarshanImage(item.imageName, Modifier.fillMaxSize())
            if (locked) {
                Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.48f)), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Icon(Icons.Filled.Lock, null, tint = Color.White)
                        Text("PRO", color = Color.White, fontWeight = FontWeight.Black, style = MaterialTheme.typography.labelSmall, modifier = Modifier.clip(CircleShape).background(colors.vermilion).padding(horizontal = 7.dp, vertical = 3.dp))
                    }
                }
            } else if (isFav) {
                Icon(Icons.Filled.Favorite, null, tint = Color.White, modifier = Modifier.align(Alignment.TopEnd).padding(8.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.38f)).padding(7.dp).size(18.dp))
            }
        }
        Text(item.deity(lang), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = colors.ink, maxLines = 1)
        Text(item.collection(lang), style = MaterialTheme.typography.labelSmall, color = colors.muted)
    }
}
