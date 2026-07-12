@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package app.bhaktiangan.feature.japa

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import app.bhaktiangan.core.review.ReviewLauncher
import app.bhaktiangan.ui.findActivity
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.data.ContentCatalog
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.core.model.MantraChoice
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

private val goalPresets = listOf(27, 54, 108, 1008, 10000)

@Composable
fun JapaScreen(vm: AppViewModel, lang: Lang, onLockedMantra: () -> Unit, onOpenVoiceJapa: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val choice = remember(prefs.selectedMantraId) {
        ContentCatalog.mantraChoices.firstOrNull { it.id == prefs.selectedMantraId } ?: ContentCatalog.mantraChoices[0]
    }
    // A finished mala is the most positive moment to ask for a Play rating (fires once per completion).
    val activity = LocalContext.current.findActivity()
    val malaComplete = prefs.japaGoal > 0 && prefs.japaCount >= prefs.japaGoal
    LaunchedEffect(malaComplete) { if (malaComplete && activity != null) ReviewLauncher.launch(activity) }

    Scaffold(
        containerColor = colors.ivory,
        topBar = { TopAppBar(title = { Text(s("Japa", "जप"), fontWeight = FontWeight.SemiBold) }) },
    ) { pad ->
        Column(
            Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp).padding(top = 10.dp, bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            MantraSelector(choice, lang, colors, hasPro = vm.hasPro, onSelect = { vm.selectMantra(it) }, onLocked = onLockedMantra)
            // Voice Japa (Pro): hands-free counting
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                    .background(colors.plum).clickable(onClick = onOpenVoiceJapa).padding(15.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Filled.Mic, null, tint = androidx.compose.ui.graphics.Color.White, modifier = Modifier.size(20.dp))
                Column(Modifier.weight(1f)) {
                    Text(s("Voice Japa", "वाणी जप"), color = androidx.compose.ui.graphics.Color.White, fontWeight = FontWeight.Bold)
                    Text(s("Chant aloud, hands-free", "बोलकर जप करें, बिना छुए"), color = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.78f), style = MaterialTheme.typography.bodySmall)
                }
                if (!vm.hasPro) Icon(Icons.Filled.Lock, null, tint = colors.marigold, modifier = Modifier.size(18.dp))
            }
            JapaPractice(
                choice = choice, lang = lang, colors = colors,
                count = prefs.japaCount, goal = prefs.japaGoal,
                onChant = { vm.incrementJapa() }, onReset = { vm.resetJapa() }, onGoal = { vm.setGoal(it) },
            )
        }
    }
}

@Composable
private fun MantraSelector(
    choice: MantraChoice, lang: Lang, colors: app.bhaktiangan.designsystem.BhaktiColors,
    hasPro: Boolean, onSelect: (String) -> Unit, onLocked: () -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(colors.paper).clickable { expanded = true }.padding(15.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(s("CURRENT MANTRA", "वर्तमान मंत्र"), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold, color = colors.vermilion)
                Text(choice.deity(lang), style = MaterialTheme.typography.titleMedium, color = colors.ink)
            }
            Icon(Icons.Filled.ExpandMore, null, tint = colors.muted)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            ContentCatalog.mantraChoices.forEach { mc ->
                val locked = mc.isPremium && !hasPro
                DropdownMenuItem(
                    text = { Text(mc.deity(lang)) },
                    leadingIcon = if (locked) { { Icon(Icons.Filled.Lock, null) } } else null,
                    onClick = { expanded = false; if (locked) onLocked() else onSelect(mc.id) },
                )
            }
        }
    }
}

@Composable
private fun JapaPractice(
    choice: MantraChoice, lang: Lang, colors: app.bhaktiangan.designsystem.BhaktiColors,
    count: Int, goal: Int, onChant: () -> Unit, onReset: () -> Unit, onGoal: (Int) -> Unit,
) {
    val haptics = LocalHapticFeedback.current
    val complete = count >= goal
    val progress = (count.toFloat() / goal).coerceIn(0f, 1f)

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(choice.mantra(lang), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = colors.plum, textAlign = TextAlign.Center)
            Text(choice.meaning(lang), style = MaterialTheme.typography.bodyMedium, color = colors.muted, textAlign = TextAlign.Center)
        }

        Box(contentAlignment = Alignment.Center) {
            Canvas(Modifier.size(220.dp)) {
                val sw = 15.dp.toPx()
                val inset = sw / 2
                val arcSize = Size(size.width - sw, size.height - sw)
                val topLeft = Offset(inset, inset)
                drawArc(colors.marigold.copy(alpha = 0.2f), -90f, 360f, false, topLeft, arcSize, style = Stroke(sw, cap = StrokeCap.Round))
                drawArc(colors.marigold, -90f, 360f * progress, false, topLeft, arcSize, style = Stroke(sw, cap = StrokeCap.Round))
            }
            Column(
                Modifier.size(180.dp).clip(CircleShape).background(colors.paper)
                    .clickable {
                        onChant()
                        haptics.performHapticFeedback(if (count + 1 == goal) HapticFeedbackType.LongPress else HapticFeedbackType.TextHandleMove)
                    },
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
            ) {
                Text("$count", style = MaterialTheme.typography.displayMedium, fontWeight = FontWeight.Bold, color = colors.ink)
                Text(s("of $goal", "$goal में से"), style = MaterialTheme.typography.titleMedium, color = colors.muted)
                Text(
                    if (complete) s("Mala complete", "माला पूर्ण") else s("Tap to chant", "जप हेतु स्पर्श करें"),
                    style = MaterialTheme.typography.bodySmall, color = if (complete) colors.teal else colors.vermilion,
                )
            }
        }

        Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            goalPresets.forEach { g ->
                val sel = g == goal
                Text(
                    "$g", fontWeight = FontWeight.Bold, color = if (sel) androidx.compose.ui.graphics.Color.White else colors.vermilion,
                    modifier = Modifier.clip(CircleShape).background(if (sel) colors.vermilion else colors.paper).clickable { onGoal(g) }.padding(horizontal = 16.dp, vertical = 9.dp),
                )
            }
        }

        Row(Modifier.clickable { onReset() }.padding(8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Outlined.Refresh, null, tint = colors.vermilion, modifier = Modifier.size(18.dp))
            Text(s("Reset today's count", "आज की गिनती रीसेट करें"), color = colors.vermilion, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
        }
    }
}
