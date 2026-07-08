@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package app.bhaktiangan.feature.settings

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

private const val SUPPORT_EMAIL = "support@bhaktiangan.com"

private data class Topic(val en: String, val hi: String)

private val topics = listOf(
    Topic("Question", "प्रश्न"),
    Topic("Report an image", "चित्र की शिकायत"),
    Topic("Subscription & billing", "सदस्यता और बिलिंग"),
    Topic("Feedback & ideas", "सुझाव और विचार"),
    Topic("Something else", "अन्य"),
)

@Composable
fun SupportScreen(lang: Lang, onBack: () -> Unit) {
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    var topic by remember { mutableStateOf(topics[0]) }
    var message by remember { mutableStateOf("") }
    var menuOpen by remember { mutableStateOf(false) }

    fun send() {
        val diagnostics = "App 1.0 (1) · Android ${Build.VERSION.RELEASE} · ${Build.MODEL}"
        val body = "$message\n\n——————————————\nSent from Bhakti Angan\n$diagnostics"
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:$SUPPORT_EMAIL")
            putExtra(Intent.EXTRA_SUBJECT, "[Bhakti Angan] ${topic.en}")
            putExtra(Intent.EXTRA_TEXT, body)
        }
        runCatching { ctx.startActivity(intent) }
    }

    Scaffold(
        containerColor = colors.ivory,
        topBar = {
            TopAppBar(
                title = { Text(s("Contact Support", "सहायता से संपर्क करें"), fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Back", tint = colors.ink) } },
            )
        },
    ) { pad ->
        Column(Modifier.padding(pad).fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(s("How can we help?", "हम कैसे सहायता करें?"), style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold, color = colors.vermilion)
            Box {
                Row(
                    Modifier.fillMaxWidth().clickable { menuOpen = true }.padding(vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(if (lang == Lang.HI) topic.hi else topic.en, color = colors.ink, modifier = Modifier.weight(1f))
                    Icon(Icons.Filled.ExpandMore, null, tint = colors.muted)
                }
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                    topics.forEach { t ->
                        DropdownMenuItem(text = { Text(if (lang == Lang.HI) t.hi else t.en) }, onClick = { topic = t; menuOpen = false })
                    }
                }
            }
            OutlinedTextField(
                value = message, onValueChange = { message = it },
                placeholder = { Text(s("Write your message here…", "अपना संदेश यहाँ लिखें…")) },
                modifier = Modifier.fillMaxWidth().heightIn(min = 160.dp),
            )
            Text(
                s("This opens your mail app, ready to send to $SUPPORT_EMAIL. We usually reply within 2–3 days.",
                    "यह आपके मेल ऐप को खोलता है, $SUPPORT_EMAIL पर भेजने के लिए तैयार। हम आमतौर पर 2–3 दिनों में उत्तर देते हैं।"),
                style = MaterialTheme.typography.bodySmall, color = colors.muted,
            )
            Box(
                Modifier.fillMaxWidth().clickable(enabled = message.isNotBlank()) { send() }
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(Icons.AutoMirrored.Filled.Send, null, tint = if (message.isNotBlank()) colors.vermilion else colors.muted)
                    Text(s("Compose email", "ईमेल लिखें"), color = if (message.isNotBlank()) colors.vermilion else colors.muted, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
