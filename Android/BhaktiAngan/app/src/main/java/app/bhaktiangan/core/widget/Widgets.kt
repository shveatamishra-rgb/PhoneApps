package app.bhaktiangan.core.widget

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

private val PLUM = Color(0xFF3D1428)
private val TEAL = Color(0xFF0E2F2B)
private val CREAM = Color(0xFFF7F1E6)
private val GOLD = Color(0xFFCDA349)

private fun white(a: Float = 1f) = ColorProvider(Color.White.copy(alpha = a))

// ---------------- Daily Shlok ----------------

class ShlokWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val sanskrit = WidgetBridge.read(context, WidgetBridge.SHLOK_SANSKRIT)
        val meaning = WidgetBridge.read(context, WidgetBridge.SHLOK_MEANING)
        val source = WidgetBridge.read(context, WidgetBridge.SHLOK_SOURCE)
        provideContent {
            Column(GlanceModifier.fillMaxSize().background(TEAL).cornerRadius(16.dp).padding(16.dp)) {
                Text("SHLOK", style = TextStyle(color = ColorProvider(GOLD), fontSize = 9.sp, fontWeight = FontWeight.Bold))
                Spacer(GlanceModifier.height(6.dp))
                Text(sanskrit.ifBlank { "Open Bhakti Angan" }, style = TextStyle(color = white(), fontSize = 15.sp, fontWeight = FontWeight.Medium), maxLines = 3)
                Spacer(GlanceModifier.height(6.dp))
                if (meaning.isNotBlank()) Text(meaning, style = TextStyle(color = white(0.85f), fontSize = 12.sp), maxLines = 2)
                Spacer(GlanceModifier.height(6.dp))
                Text(source, style = TextStyle(color = white(0.8f), fontSize = 10.sp, fontWeight = FontWeight.Medium))
            }
        }
    }
}

class ShlokWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ShlokWidget()
}

// ---------------- Choghadiya ----------------

class ChoghadiyaWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val name = WidgetBridge.read(context, WidgetBridge.CHOGH_NAME)
        val quality = WidgetBridge.read(context, WidgetBridge.CHOGH_QUALITY)
        val time = WidgetBridge.read(context, WidgetBridge.CHOGH_TIME)
        val city = WidgetBridge.read(context, WidgetBridge.CHOGH_CITY)
        provideContent {
            Column(GlanceModifier.fillMaxSize().background(PLUM).cornerRadius(16.dp).padding(16.dp), verticalAlignment = Alignment.Vertical.CenterVertically) {
                if (name.isBlank()) {
                    Text("Open Bhakti Angan once to load today’s muhurat", style = TextStyle(color = white(0.9f), fontSize = 12.sp), maxLines = 3)
                } else {
                    Text(city.uppercase(), style = TextStyle(color = ColorProvider(GOLD), fontSize = 10.sp, fontWeight = FontWeight.Bold))
                    Spacer(GlanceModifier.height(6.dp))
                    Text(name, style = TextStyle(color = white(), fontSize = 26.sp, fontWeight = FontWeight.Bold))
                    Text(quality, style = TextStyle(color = white(0.85f), fontSize = 13.sp, fontWeight = FontWeight.Medium))
                    Spacer(GlanceModifier.height(4.dp))
                    Text(time, style = TextStyle(color = white(0.8f), fontSize = 11.sp))
                }
            }
        }
    }
}

class ChoghadiyaWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ChoghadiyaWidget()
}

// ---------------- Daily Darshan ----------------

class DarshanWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val imageName = WidgetBridge.read(context, WidgetBridge.DARSHAN_IMG)
        val deity = WidgetBridge.read(context, WidgetBridge.DARSHAN_DEITY)
        val mantra = WidgetBridge.read(context, WidgetBridge.DARSHAN_MANTRA)
        val resId = context.resources.getIdentifier(imageName, "drawable", context.packageName)
        provideContent {
            Column(GlanceModifier.fillMaxSize().background(PLUM).cornerRadius(16.dp), verticalAlignment = Alignment.Vertical.Bottom) {
                if (resId != 0) {
                    Image(provider = ImageProvider(resId), contentDescription = deity, contentScale = ContentScale.Crop, modifier = GlanceModifier.fillMaxSize())
                }
                Column(GlanceModifier.fillMaxWidth().background(ColorProvider(Color.Black.copy(alpha = 0.42f))).padding(12.dp)) {
                    Text(deity.ifBlank { "Bhakti Angan" }, style = TextStyle(color = white(), fontSize = 16.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                    if (mantra.isNotBlank()) Text(mantra, style = TextStyle(color = ColorProvider(GOLD), fontSize = 11.sp), maxLines = 1)
                }
            }
        }
    }
}

class DarshanWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = DarshanWidget()
}
