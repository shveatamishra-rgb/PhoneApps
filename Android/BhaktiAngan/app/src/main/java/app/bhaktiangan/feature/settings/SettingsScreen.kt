@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package app.bhaktiangan.feature.settings

import android.Manifest
import android.app.TimePickerDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.core.content.ContextCompat
import app.bhaktiangan.core.notify.ReminderScheduler
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.model.AppLanguage
import app.bhaktiangan.core.model.AppearanceMode
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

@Composable
fun SettingsScreen(
    vm: AppViewModel,
    lang: Lang,
    onOpenPaywall: () -> Unit,
    onOpenSupport: () -> Unit,
    onOpenLegal: (String) -> Unit,
) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    fun open(url: String) = ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))

    val notifLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            ReminderScheduler.schedule(ctx, prefs.reminderHour, prefs.reminderMinute)
            vm.setReminder(true, prefs.reminderHour, prefs.reminderMinute)
        } else {
            vm.setReminder(false, prefs.reminderHour, prefs.reminderMinute)
        }
    }
    fun enableReminder() {
        val needsPerm = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (needsPerm) {
            notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            ReminderScheduler.schedule(ctx, prefs.reminderHour, prefs.reminderMinute)
            vm.setReminder(true, prefs.reminderHour, prefs.reminderMinute)
        }
    }

    Scaffold(
        containerColor = colors.ivory,
        topBar = { TopAppBar(title = { Text(s("Settings", "सेटिंग्स"), fontWeight = FontWeight.SemiBold) }) },
    ) { pad ->
        Column(Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(22.dp)) {

            Section(s("Membership", "सदस्यता"), colors) {
                if (vm.hasPro) {
                    Text(s("Bhakti Angan Pro is active", "भक्ति आँगन प्रो सक्रिय है"), color = colors.teal, fontWeight = FontWeight.SemiBold)
                } else {
                    RowItem(s("Unlock Bhakti Angan Pro", "भक्ति आँगन प्रो अनलॉक करें"), colors, onClick = onOpenPaywall)
                }
            }

            Section(s("Appearance & Language", "रूप और भाषा"), colors) {
                LanguagePicker(prefs.language, colors) { vm.setLanguage(it) }
                HorizontalDivider(color = colors.muted.copy(alpha = 0.15f))
                AppearancePicker(prefs.appearance, lang, colors) { vm.setAppearance(it) }
            }

            Section(s("Daily Practice", "दैनिक अभ्यास"), colors) {
                ToggleItem(s("Daily darshan reminder", "दैनिक दर्शन स्मरण"), prefs.reminderEnabled, colors) { on ->
                    if (on) enableReminder() else { ReminderScheduler.cancel(ctx); vm.setReminder(false, prefs.reminderHour, prefs.reminderMinute) }
                }
                if (prefs.reminderEnabled) {
                    Row(Modifier.fillMaxWidth().clickable {
                        TimePickerDialog(ctx, { _, h, m ->
                            vm.setReminder(true, h, m); ReminderScheduler.schedule(ctx, h, m)
                        }, prefs.reminderHour, prefs.reminderMinute, false).show()
                    }.padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(s("Reminder time", "स्मरण का समय"), color = colors.ink, modifier = Modifier.weight(1f))
                        Text(formatTime(prefs.reminderHour, prefs.reminderMinute), color = colors.muted)
                    }
                }
            }

            Section(s("Connect", "जुड़ें"), colors) {
                RowItem("Instagram", colors) { open("https://www.instagram.com/bhaktiangan/") }
                RowItem("YouTube", colors) { open("https://www.youtube.com/@bhaktiangan-om") }
                RowItem("Facebook", colors) { open("https://www.facebook.com/bhaktiangan") }
            }

            Section(s("About", "परिचय"), colors) {
                RowItem(s("Contact Support", "सहायता से संपर्क करें"), colors) { onOpenSupport() }
                RowItem(s("Privacy Policy", "गोपनीयता नीति"), colors) { onOpenLegal("privacy") }
                RowItem(s("Terms of Use", "उपयोग की शर्तें"), colors) { onOpenLegal("terms") }
                RowItem(s("Image and Faith Standards", "चित्र और आस्था मानक"), colors) { onOpenLegal("faith") }
                RowItem(s("Acknowledgements", "आभार"), colors) { onOpenLegal("ack") }
                Row(Modifier.fillMaxWidth().padding(vertical = 12.dp)) {
                    Text(s("Version", "संस्करण"), color = colors.ink, modifier = Modifier.weight(1f))
                    Text("1.0 (1)", color = colors.muted)
                }
            }

            // Dev-only entitlement toggle (stands in for Play Billing during the port).
            Section("Development", colors) {
                ToggleItem("Preview Pro entitlement", prefs.debugPro, colors) { vm.setDebugPro(it) }
            }
        }
    }
}

private fun formatTime(hour: Int, minute: Int): String {
    val cal = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY, hour); set(Calendar.MINUTE, minute) }
    return SimpleDateFormat("h:mm a", Locale.US).format(cal.time)
}

@Composable
private fun Section(title: String, colors: app.bhaktiangan.designsystem.BhaktiColors, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title.uppercase(), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = colors.vermilion, modifier = Modifier.padding(bottom = 6.dp))
        content()
    }
}

@Composable
private fun RowItem(title: String, colors: app.bhaktiangan.designsystem.BhaktiColors, onClick: () -> Unit) {
    Text(title, color = colors.ink, modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp))
}

@Composable
private fun ToggleItem(title: String, checked: Boolean, colors: app.bhaktiangan.designsystem.BhaktiColors, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, color = colors.ink, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChange)
    }
}

@Composable
private fun LanguagePicker(current: AppLanguage, colors: app.bhaktiangan.designsystem.BhaktiColors, onPick: (AppLanguage) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        Row(Modifier.fillMaxWidth().clickable { open = true }.padding(vertical = 12.dp)) {
            Text(s("Language", "भाषा"), color = colors.ink, modifier = Modifier.weight(1f))
            Text(current.label, color = colors.muted)
        }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            AppLanguage.entries.forEach { l -> DropdownMenuItem(text = { Text(l.label) }, onClick = { open = false; onPick(l) }) }
        }
    }
}

@Composable
private fun AppearancePicker(current: AppearanceMode, lang: Lang, colors: app.bhaktiangan.designsystem.BhaktiColors, onPick: (AppearanceMode) -> Unit) {
    var open by remember { mutableStateOf(false) }
    fun label(m: AppearanceMode) = when (m) {
        AppearanceMode.SYSTEM -> if (lang == Lang.HI) "सिस्टम" else "System"
        AppearanceMode.LIGHT -> if (lang == Lang.HI) "उजाला" else "Light"
        AppearanceMode.DARK -> if (lang == Lang.HI) "अँधेरा" else "Dark"
    }
    Box {
        Row(Modifier.fillMaxWidth().clickable { open = true }.padding(vertical = 12.dp)) {
            Text(s("Appearance", "रूप"), color = colors.ink, modifier = Modifier.weight(1f))
            Text(label(current), color = colors.muted)
        }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
            AppearanceMode.entries.forEach { m -> DropdownMenuItem(text = { Text(label(m)) }, onClick = { open = false; onPick(m) }) }
        }
    }
}
