package app.bhaktiangan.feature.katha

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.core.model.Story
import app.bhaktiangan.designsystem.BhaktiColors
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

/** Story cover: the ported art (if bundled) over the deity gradient, with a bottom scrim
 *  so overlaid title text stays legible. Drawable name = story id with '-' -> '_'. */
@Composable
private fun StoryCover(story: Story, colors: BhaktiColors, modifier: Modifier, content: @Composable androidx.compose.foundation.layout.BoxScope.() -> Unit) {
    val ctx = LocalContext.current
    val resId = remember(story.id) { ctx.resources.getIdentifier(story.id.replace("-", "_"), "drawable", ctx.packageName) }
    Box(modifier) {
        Box(Modifier.fillMaxSize().background(Brush.linearGradient(deityGradient(story.deity, colors))))
        if (resId != 0) Image(painterResource(resId), story.title(Lang.EN), Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.72f)))))
        content()
    }
}

private fun deityGradient(deity: String, c: BhaktiColors): List<Color> = when (deity) {
    "shiva" -> listOf(c.teal, c.plum)
    "vishnu" -> listOf(c.marigold, c.vermilion)
    "krishna" -> listOf(c.plum, c.teal)
    "devi" -> listOf(c.vermilion, c.plum)
    "ganesha" -> listOf(c.marigold, c.plum)
    "hanuman" -> listOf(c.vermilion, c.marigold)
    else -> listOf(c.plum, c.teal)
}

@Composable
fun KathaScreen(vm: AppViewModel, lang: Lang, onOpenStory: (String) -> Unit, onOpenPaywall: () -> Unit) {
    val colors = BhaktiTheme.colors
    LazyColumn(
        Modifier.fillMaxSize().background(colors.ivory).statusBarsPadding(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Text(s("Katha", "कथा"), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = colors.ink)
            Text(s("Timeless tales of the gods, each with a moral for daily life.", "देवताओं की कालजयी कथाएँ, हर एक में जीवन का एक सार।"),
                style = MaterialTheme.typography.bodyMedium, fontStyle = FontStyle.Italic, color = colors.muted, modifier = Modifier.padding(top = 4.dp))
        }
        items(vm.stories.all, key = { it.id }) { story ->
            val locked = story.isPremium && !vm.hasPro
            StoryCard(story, lang, locked, colors) { if (locked) onOpenPaywall() else onOpenStory(story.id) }
        }
    }
}

@Composable
private fun StoryCard(story: Story, lang: Lang, locked: Boolean, colors: BhaktiColors, onClick: () -> Unit) {
    StoryCover(
        story, colors,
        Modifier.fillMaxWidth().height(190.dp).clip(RoundedCornerShape(16.dp)).clickable(onClick = onClick),
    ) {
        if (locked) Icon(Icons.Filled.Lock, null, tint = Color.White, modifier = Modifier.align(Alignment.TopEnd).padding(14.dp).size(18.dp))
        Column(Modifier.align(Alignment.BottomStart).padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(story.eyebrow(lang).uppercase(), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.88f))
            Text(story.title(lang), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = Color.White)
            Text(story.intro(lang), style = MaterialTheme.typography.bodySmall, color = Color.White.copy(alpha = 0.9f), maxLines = 2)
        }
    }
}

@Composable
fun StoryDetailScreen(vm: AppViewModel, lang: Lang, id: String, onBack: () -> Unit) {
    val colors = BhaktiTheme.colors
    val story = vm.stories.story(id) ?: run { onBack(); return }
    Column(Modifier.fillMaxSize().background(colors.ivory).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clip(CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, s("Back", "वापस"), tint = colors.ink)
            }
        }
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            StoryCover(story, colors, Modifier.fillMaxWidth().height(240.dp).clip(RoundedCornerShape(16.dp))) {
                Column(Modifier.align(Alignment.BottomStart).padding(20.dp)) {
                    Text(story.eyebrow(lang).uppercase(), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.85f))
                    Text(story.title(lang), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = Color.White)
                }
            }
            Text(story.intro(lang), style = MaterialTheme.typography.bodyLarge, fontStyle = FontStyle.Italic, color = colors.muted)
            story.body(lang).forEach { para -> Text(para, style = MaterialTheme.typography.bodyLarge, color = colors.ink, lineHeight = MaterialTheme.typography.bodyLarge.fontSize.times(1.6f)) }
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(colors.teal.copy(alpha = 0.10f)).padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(s("The moral", "सार"), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.marigold)
                Text(story.moral(lang), style = MaterialTheme.typography.bodyLarge, color = colors.ink)
            }
        }
    }
}
