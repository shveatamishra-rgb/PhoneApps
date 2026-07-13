package app.bhaktiangan.core.widget

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import app.bhaktiangan.MainActivity
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

private val GOOD_BG = Color(0xFF15653D)   // green: auspicious (Amrit, Shubh, Labh, Char)
private val BAD_BG = Color(0xFF6E1B24)    // red: inauspicious (Rog, Kaal, Udveg)
private val NEUTRAL_BG = Color(0xFF123F3A) // teal: neutral

private data class ChoghPeriod(val name: String, val quality: String, val start: Long, val end: Long)

private fun parsePeriods(raw: String): List<ChoghPeriod> = raw.split(";").mapNotNull { seg ->
    val p = seg.split("|"); if (p.size < 4) null else runCatching { ChoghPeriod(p[0], p[1], p[2].toLong(), p[3].toLong()) }.getOrNull()
}

class ChoghadiyaWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val city = WidgetBridge.read(context, WidgetBridge.CHOGH_CITY)
        val tz = WidgetBridge.read(context, WidgetBridge.CHOGH_TZ)
        val periods = parsePeriods(WidgetBridge.read(context, WidgetBridge.CHOGH_PERIODS))
        val now = System.currentTimeMillis()
        val cur = periods.firstOrNull { now >= it.start && now < it.end }
        val zone = runCatching { java.time.ZoneId.of(tz) }.getOrDefault(java.time.ZoneId.systemDefault())
        val fmt = java.time.format.DateTimeFormatter.ofPattern("h:mm a").withZone(zone)
        val bg = when (cur?.quality) { "GOOD" -> GOOD_BG; "BAD" -> BAD_BG; else -> NEUTRAL_BG }

        provideContent {
            Column(
                GlanceModifier.fillMaxSize().background(bg).cornerRadius(16.dp).padding(16.dp)
                    .clickable(actionStartActivity(openPanchangIntent(context))),
                verticalAlignment = Alignment.Vertical.CenterVertically,
            ) {
                if (cur == null) {
                    Text("Open Bhakti Angan once to load today’s muhurat", style = TextStyle(color = white(0.9f), fontSize = 12.sp), maxLines = 3)
                } else {
                    Text(city.uppercase(), style = TextStyle(color = ColorProvider(GOLD), fontSize = 10.sp, fontWeight = FontWeight.Bold))
                    Spacer(GlanceModifier.height(6.dp))
                    Text(cur.name, style = TextStyle(color = white(), fontSize = 26.sp, fontWeight = FontWeight.Bold))
                    Text(qualityLabel(cur.quality), style = TextStyle(color = white(0.9f), fontSize = 13.sp, fontWeight = FontWeight.Medium))
                    Spacer(GlanceModifier.height(4.dp))
                    Text("${fmt.format(java.time.Instant.ofEpochMilli(cur.start))} - ${fmt.format(java.time.Instant.ofEpochMilli(cur.end))}",
                        style = TextStyle(color = white(0.85f), fontSize = 11.sp))
                }
            }
        }
    }

    private fun qualityLabel(q: String) = when (q) { "GOOD" -> "Auspicious"; "BAD" -> "Inauspicious"; else -> "Neutral" }
}

private fun openPanchangIntent(context: Context): android.content.Intent =
    android.content.Intent(context, MainActivity::class.java).apply {
        action = android.content.Intent.ACTION_VIEW
        putExtra("open", "panchang")
        addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP)
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
