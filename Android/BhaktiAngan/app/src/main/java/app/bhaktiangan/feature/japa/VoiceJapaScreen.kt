package app.bhaktiangan.feature.japa

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.audio.VoiceJapaCounter
import app.bhaktiangan.core.data.ContentCatalog
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

@Composable
fun VoiceJapaScreen(vm: AppViewModel, lang: Lang, onBack: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    val haptics = LocalHapticFeedback.current
    val choice = remember(prefs.selectedMantraId) {
        ContentCatalog.mantraChoices.firstOrNull { it.id == prefs.selectedMantraId } ?: ContentCatalog.mantraChoices[0]
    }

    val counter = remember { VoiceJapaCounter() }
    val count by counter.count.collectAsState()
    val phase by counter.phase.collectAsState()
    val level by counter.level.collectAsState()
    val calibProgress by counter.calibProgress.collectAsState()
    var sensitivity by remember { mutableFloatStateOf(0.55f) }
    var chimeOn by remember { mutableStateOf(true) }
    val goal = prefs.japaGoal

    DisposableEffect(Unit) {
        counter.target = goal
        counter.onCount = { vm.incrementJapa(); haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove) }
        counter.onTargetReached = { if (chimeOn) haptics.performHapticFeedback(HapticFeedbackType.LongPress) }
        onDispose { counter.stop() }
    }
    counter.target = goal
    counter.sensitivity = sensitivity

    val hasMic = ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    val micLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) counter.startListening()
    }
    fun ensureAndStart() {
        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) counter.startListening()
        else micLauncher.launch(Manifest.permission.RECORD_AUDIO)
    }

    val progress = (count.toFloat() / goal.coerceAtLeast(1)).coerceIn(0f, 1f)
    val pulse by animateFloatAsState(1f + level * 0.18f, label = "pulse")

    Column(Modifier.fillMaxSize().background(colors.ivory).statusBarsPadding().padding(horizontal = 22.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(s("Voice Japa", "वाणी जप"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.plum, modifier = Modifier.weight(1f))
            Box(Modifier.size(40.dp).clip(CircleShape).clickable { counter.stop(); onBack() }, contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Close, s("Close", "बंद करें"), tint = colors.muted)
            }
        }

        Spacer(Modifier.size(8.dp))
        Text(choice.mantra(lang), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = colors.plum, textAlign = TextAlign.Center)
        Text(s("Chant aloud. Keep your eyes closed.", "मन से जप करें। आँखें बंद रखें।"), style = MaterialTheme.typography.bodyMedium, color = colors.muted)

        Spacer(Modifier.size(20.dp))
        Box(contentAlignment = Alignment.Center) {
            // level pulse behind the ring
            Box(Modifier.size(250.dp).scale(pulse).clip(CircleShape).background(colors.marigold.copy(alpha = 0.14f)))
            Canvas(Modifier.size(250.dp)) {
                val sw = 15.dp.toPx(); val inset = sw / 2
                val arcSize = Size(size.width - sw, size.height - sw); val topLeft = Offset(inset, inset)
                drawArc(colors.marigold.copy(alpha = 0.2f), -90f, 360f, false, topLeft, arcSize, style = Stroke(sw, cap = StrokeCap.Round))
                drawArc(colors.marigold, -90f, 360f * progress, false, topLeft, arcSize, style = Stroke(sw, cap = StrokeCap.Round))
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("$count", style = MaterialTheme.typography.displayLarge, fontWeight = FontWeight.Bold, color = colors.ink)
                Text(s("of $goal", "$goal में से"), style = MaterialTheme.typography.titleMedium, color = colors.muted)
            }
        }

        Spacer(Modifier.size(16.dp))
        StatusLine(phase, colors)

        Spacer(Modifier.weight(1f))

        // controls: minus / primary / plus
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            StepButton(Icons.Filled.Remove, colors, enabled = count > 0) { counter.adjust(-1) }
            PrimaryButton(phase, colors, lang, Modifier.weight(1f)) {
                when (phase) {
                    VoiceJapaCounter.Phase.LISTENING -> counter.pause()
                    VoiceJapaCounter.Phase.PAUSED -> counter.resume()
                    else -> ensureAndStart()
                }
            }
            StepButton(Icons.Filled.Add, colors, enabled = true) { counter.adjust(1) }
        }

        if (phase == VoiceJapaCounter.Phase.LISTENING || phase == VoiceJapaCounter.Phase.PAUSED) {
            Row(Modifier.clickable { counter.stop(); counter.reset() }.padding(10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(Icons.Filled.Stop, null, tint = colors.muted, modifier = Modifier.size(18.dp))
                Text(s("End session", "सत्र समाप्त करें"), color = colors.muted, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
            }
        }

        // sensitivity + chime
        Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(s("Sensitivity", "संवेदनशीलता"), style = MaterialTheme.typography.labelMedium, color = colors.muted, modifier = Modifier.weight(1f))
                Text(s("Chime at target", "पूर्ण होने पर ध्वनि"), style = MaterialTheme.typography.labelSmall, color = colors.muted)
                Switch(chimeOn, { chimeOn = it }, colors = SwitchDefaults.colors(checkedTrackColor = colors.teal))
            }
            Slider(value = sensitivity, onValueChange = { sensitivity = it }, valueRange = 0f..1f,
                colors = SliderDefaults.colors(thumbColor = colors.marigold, activeTrackColor = colors.marigold))
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text(s("If it miscounts, calibrate or adjust sensitivity.", "गिनती गलत हो तो कैलिब्रेट करें या संवेदनशीलता बदलें।"), style = MaterialTheme.typography.bodySmall, color = colors.muted, modifier = Modifier.weight(1f))
            Text(s("Recalibrate", "पुनः कैलिब्रेट करें"), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold, color = colors.teal,
                modifier = Modifier.clickable {
                    if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) counter.calibrate {}
                    else micLauncher.launch(Manifest.permission.RECORD_AUDIO)
                }.padding(8.dp))
        }
        Spacer(Modifier.size(6.dp))
    }
}

@Composable
private fun StatusLine(phase: VoiceJapaCounter.Phase, colors: app.bhaktiangan.designsystem.BhaktiColors) {
    when (phase) {
        VoiceJapaCounter.Phase.DENIED -> Text(s("Microphone is off. Enable it in Settings to use Voice Japa.", "माइक्रोफ़ोन बंद है। वाणी जप हेतु सेटिंग्स में चालू करें।"), color = colors.vermilion, textAlign = TextAlign.Center, style = MaterialTheme.typography.bodySmall)
        VoiceJapaCounter.Phase.CALIBRATING -> Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) { Icon(Icons.Filled.GraphicEq, null, tint = colors.teal, modifier = Modifier.size(18.dp)); Text(s("Calibrating, chant a few times...", "कैलिब्रेट हो रहा है, कुछ बार जप करें..."), color = colors.teal, fontWeight = FontWeight.SemiBold) }
        VoiceJapaCounter.Phase.LISTENING -> Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) { Icon(Icons.Filled.GraphicEq, null, tint = colors.teal, modifier = Modifier.size(18.dp)); Text(s("Listening...", "सुन रहे हैं..."), color = colors.teal, fontWeight = FontWeight.SemiBold) }
        VoiceJapaCounter.Phase.PAUSED -> Text(s("Paused", "रुका हुआ"), color = colors.muted)
        VoiceJapaCounter.Phase.IDLE -> Text(s("Press start, then begin chanting.", "आरंभ दबाएँ, फिर जप शुरू करें।"), color = colors.muted)
    }
}

@Composable
private fun StepButton(icon: ImageVector, colors: app.bhaktiangan.designsystem.BhaktiColors, enabled: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.size(56.dp).clip(CircleShape).border(1.dp, colors.marigold.copy(alpha = if (enabled) 0.5f else 0.2f), CircleShape)
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, null, tint = if (enabled) colors.ink else colors.muted.copy(alpha = 0.4f)) }
}

@Composable
private fun PrimaryButton(phase: VoiceJapaCounter.Phase, colors: app.bhaktiangan.designsystem.BhaktiColors, lang: Lang, modifier: Modifier, onClick: () -> Unit) {
    val (icon, label) = when (phase) {
        VoiceJapaCounter.Phase.LISTENING -> Icons.Filled.Pause to s("Pause", "रोकें")
        VoiceJapaCounter.Phase.PAUSED -> Icons.Filled.PlayArrow to s("Resume", "जारी रखें")
        else -> Icons.Filled.PlayArrow to s("Start", "आरंभ")
    }
    Row(
        modifier.clip(CircleShape).background(colors.plum).clickable(onClick = onClick).padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp))
        Text("  $label", color = Color.White, fontWeight = FontWeight.Bold)
    }
}
