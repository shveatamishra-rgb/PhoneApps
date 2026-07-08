@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package app.bhaktiangan.feature.settings

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.s

@Composable
fun LegalScreen(kind: String, lang: Lang, onBack: () -> Unit) {
    val colors = BhaktiTheme.colors
    val (_, content) = LegalCopy.byKind(kind)
    val title = when (kind) {
        "terms" -> s("Terms of Use", "उपयोग की शर्तें")
        "faith" -> s("Image and Faith Standards", "चित्र और आस्था मानक")
        "ack" -> s("Acknowledgements", "आभार")
        else -> s("Privacy Policy", "गोपनीयता नीति")
    }
    Scaffold(
        containerColor = colors.ivory,
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Back", tint = colors.ink) } },
            )
        },
    ) { pad ->
        Text(
            content,
            color = colors.ink,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
        )
    }
}
