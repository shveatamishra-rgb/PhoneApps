package app.bhaktiangan.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.bhaktiangan.designsystem.BhaktiTheme

/** Standard paper card with the app's rounded shape + side margin (mirrors iOS cards). */
@Composable
fun BaCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp),
        color = BhaktiTheme.colors.paper,
        shape = RoundedCornerShape(14.dp),
    ) {
        Column(content = content)
    }
}

@Composable
fun Pill(text: String, color: Color, filled: Boolean = false, small: Boolean = false) {
    Text(
        text = text,
        color = if (filled) Color.White else color,
        fontWeight = FontWeight.Bold,
        style = if (small) MaterialTheme.typography.labelSmall else MaterialTheme.typography.labelMedium,
        modifier = Modifier
            .background(if (filled) color else color.copy(alpha = 0.13f), CircleShape)
            .padding(horizontal = if (small) 7.dp else 10.dp, vertical = if (small) 2.dp else 4.dp),
    )
}

@Composable
fun Stat(title: String, value: String, colors: app.bhaktiangan.designsystem.BhaktiColors) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title, style = MaterialTheme.typography.bodySmall, color = colors.muted)
        Text(value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
    }
}

@Composable
fun RoundIcon(icon: ImageVector, colors: app.bhaktiangan.designsystem.BhaktiColors, onClick: () -> Unit) {
    IconButton(
        onClick = onClick,
        modifier = Modifier.size(40.dp).background(colors.paper, CircleShape),
    ) {
        Icon(icon, null, tint = colors.teal)
    }
}

@Composable
fun FilledPill(text: String, color: Color, onClick: () -> Unit) {
    Surface(color = color, shape = RoundedCornerShape(12.dp), onClick = onClick) {
        Text(
            text, color = Color.White, fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 26.dp, vertical = 13.dp),
        )
    }
}
