package app.bhaktiangan.feature.panchang

import android.Manifest
import android.location.Location
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.data.AppPrefs
import app.bhaktiangan.core.data.CitiesRepository
import app.bhaktiangan.core.location.LocationController
import app.bhaktiangan.core.model.City
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.core.panchang.Choghadiya
import app.bhaktiangan.core.panchang.ChoghadiyaQuality
import app.bhaktiangan.core.panchang.PanchangCalculator
import app.bhaktiangan.core.panchang.PanchangElement
import app.bhaktiangan.core.panchang.PanchangResult
import app.bhaktiangan.designsystem.BhaktiColors
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.BaCard
import app.bhaktiangan.ui.FilledPill
import app.bhaktiangan.ui.Pill
import app.bhaktiangan.ui.Stat
import app.bhaktiangan.ui.RoundIcon
import app.bhaktiangan.ui.s
import app.bhaktiangan.ui.tr
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.ZoneId
import java.util.TimeZone

internal fun qualityColor(q: ChoghadiyaQuality, c: BhaktiColors): Color = when (q) {
    ChoghadiyaQuality.GOOD -> c.teal
    ChoghadiyaQuality.NEUTRAL -> c.marigold
    ChoghadiyaQuality.BAD -> c.vermilion
}

/** The active City for the engine: GPS fix when on, else the chosen city, else null. */
internal fun activeCity(prefs: AppPrefs, cities: CitiesRepository, gps: Location?): City? {
    if (prefs.useGps && gps != null) {
        return City(
            id = "current", nameEN = "My Location", nameHI = "मेरा स्थान", regionEN = "",
            latitude = gps.latitude, longitude = gps.longitude, timeZoneID = TimeZone.getDefault().id,
        )
    }
    if (prefs.cityId.isNotEmpty()) return cities.byId(prefs.cityId)
    return null
}

// ---------------------------------------------------------------- Home card

@Composable
fun PanchangCard(vm: AppViewModel, lang: Lang, onOpen: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val city = remember(prefs.cityId, prefs.useGps) { activeCity(prefs, vm.cities, null) }
    val result by produceState<PanchangResult?>(null, city) {
        value = city?.let { withContext(Dispatchers.Default) { PanchangCalculator.computeForInstant(Instant.now(), it) } }
    }
    BaCard(modifier = Modifier.clickable(onClick = onOpen)) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(s("Today's Panchang", "आज का पंचांग"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink, modifier = Modifier.weight(1f))
                Text(result?.city?.name(lang) ?: s("Select location", "स्थान चुनें"), style = MaterialTheme.typography.labelMedium, color = colors.muted)
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = colors.muted)
            }
            val r = result
            if (r != null) {
                val cur = r.currentChoghadiya(Instant.now())
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(Modifier.size(10.dp).background(qualityColor(cur?.quality ?: ChoghadiyaQuality.NEUTRAL, colors), CircleShape))
                    Text(s("Now", "अभी") + ": " + (cur?.name(lang) ?: "—"), fontWeight = FontWeight.SemiBold, color = colors.ink, modifier = Modifier.weight(1f))
                    cur?.let { Text(s("until ", "") + clockString(it.end, r.city.timeZoneID) + s("", " तक"), style = MaterialTheme.typography.labelSmall, color = colors.muted) }
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("${r.tithi.name(lang)} · ${r.nakshatra.name(lang)}", style = MaterialTheme.typography.bodySmall, color = colors.muted)
                    r.vrat?.let { Pill(it.name(lang), colors.vermilion) }
                }
            } else {
                Text(s("Tap to set your location", "स्थान चुनने हेतु स्पर्श करें"), color = colors.muted)
            }
        }
    }
}

// ---------------------------------------------------------------- Full screen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PanchangScreen(vm: AppViewModel, lang: Lang, onBack: () -> Unit) {
    val prefs by vm.prefs.collectAsState()
    val colors = BhaktiTheme.colors
    val ctx = androidx.compose.ui.platform.LocalContext.current
    val scope = rememberCoroutineScope()
    var gpsLoc by remember { mutableStateOf<Location?>(null) }
    var showPicker by remember { mutableStateOf(false) }
    var viewDate by remember { mutableStateOf(Instant.now()) }
    var anchored by remember { mutableStateOf(false) }

    val city = remember(prefs.cityId, prefs.useGps, gpsLoc) { activeCity(prefs, vm.cities, gpsLoc) }

    val result by produceState<PanchangResult?>(null, city, viewDate, anchored) {
        val c = city
        value = if (c == null) null else withContext(Dispatchers.Default) {
            if (!anchored) {
                val today = PanchangCalculator.compute(Instant.now(), c)
                if (today != null && Instant.now().isBefore(today.sunrise)) viewDate = Instant.now().minusSeconds(24 * 3600)
                anchored = true
            }
            PanchangCalculator.compute(viewDate, c)
        }
    }
    val isLive = result?.currentChoghadiya(Instant.now()) != null

    fun shiftDay(days: Int) {
        val tz = result?.let { runCatching { ZoneId.of(it.city.timeZoneID) }.getOrNull() } ?: ZoneId.systemDefault()
        viewDate = viewDate.atZone(tz).plusDays(days.toLong()).toInstant()
    }

    Scaffold(
        containerColor = colors.ivory,
        topBar = {
            TopAppBar(
                title = { Text(s("Panchang", "पंचांग"), fontWeight = FontWeight.SemiBold) },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Back", tint = colors.ink) } },
                actions = { IconButton(onClick = { showPicker = true }) { Icon(Icons.Outlined.LocationOn, s("Location", "स्थान"), tint = colors.vermilion) } },
            )
        },
    ) { pad ->
        val p = result
        if (p == null) {
            EmptyLocation(colors, onChoose = { showPicker = true }, modifier = Modifier.padding(pad))
        } else {
            LazyColumn(
                modifier = Modifier.padding(pad).fillMaxWidth(),
                contentPadding = PaddingValues(vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                item { DateNav(p, lang, isLive, { shiftDay(-1) }, { shiftDay(1) }, { anchored = false; viewDate = Instant.now() }) }
                item { SummaryCard(p, lang, colors) }
                if (isLive) item { NowBanner(p, colors, lang) }
                item { ElementsCard(p, lang, colors) }
                item { ChoghadiyaSection(s("Day Choghadiya", "दिन का चौघड़िया"), p.dayChoghadiya, p.sunrise, p.city.timeZoneID, isLive, lang, colors) }
                item { ChoghadiyaSection(s("Night Choghadiya", "रात्रि का चौघड़िया"), p.nightChoghadiya, p.sunset, p.city.timeZoneID, isLive, lang, colors) }
                item { AuspiciousCard(p, lang, colors) }
                item { InauspiciousCard(p, lang, colors) }
                item {
                    Text(
                        s("Calculated on your device for ${p.city.name(lang)}. For important muhurta, please confirm with your local Panchang.",
                            "${p.city.name(lang)} के लिए आपके डिवाइस पर गणना की गई। महत्वपूर्ण मुहूर्त हेतु कृपया अपने स्थानीय पंचांग से पुष्टि करें।"),
                        style = MaterialTheme.typography.bodySmall, color = colors.muted, textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
                    )
                }
            }
        }
    }

    if (showPicker) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        val permLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                scope.launch {
                    val loc = LocationController(vm.getApplication()).current()
                    if (loc != null) {
                        gpsLoc = loc
                        vm.setUseGps(true)
                        showPicker = false
                    } else {
                        android.widget.Toast.makeText(ctx, tr(lang, "Couldn't get your location. Turn on location, or pick a city.", "स्थान नहीं मिला। लोकेशन चालू करें, या शहर चुनें।"), android.widget.Toast.LENGTH_LONG).show()
                    }
                }
            } else {
                android.widget.Toast.makeText(ctx, tr(lang, "Location permission is needed — or pick a city below.", "स्थान अनुमति आवश्यक है — या नीचे शहर चुनें।"), android.widget.Toast.LENGTH_LONG).show()
            }
        }
        ModalBottomSheet(onDismissRequest = { showPicker = false }, sheetState = sheetState, containerColor = colors.paper) {
            CityPicker(vm, lang, colors,
                onUseGps = { permLauncher.launch(Manifest.permission.ACCESS_COARSE_LOCATION) },
                onPick = { c -> vm.setCity(c.id); showPicker = false })
        }
    }
}

@Composable
private fun EmptyLocation(colors: BhaktiColors, onChoose: () -> Unit, modifier: Modifier) {
    Column(modifier.fillMaxWidth().padding(34.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Spacer(Modifier.height(40.dp))
        Icon(Icons.Filled.LocationOn, null, tint = colors.vermilion, modifier = Modifier.size(44.dp))
        Text(s("Choose your location", "अपना स्थान चुनें"), style = MaterialTheme.typography.titleLarge, color = colors.ink)
        Text(s("Panchang timings depend on your sunrise. Use your location, or pick your city.",
            "पंचांग का समय आपके सूर्योदय पर निर्भर करता है। अपना स्थान उपयोग करें या अपना शहर चुनें।"),
            color = colors.muted, textAlign = TextAlign.Center)
        FilledPill(s("Choose location", "स्थान चुनें"), colors.teal, onChoose)
    }
}

@Composable
private fun DateNav(p: PanchangResult, lang: Lang, isLive: Boolean, onPrev: () -> Unit, onNext: () -> Unit, onToday: () -> Unit) {
    val colors = BhaktiTheme.colors
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            RoundIcon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, colors, onPrev)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                Icon(Icons.Outlined.CalendarMonth, null, tint = colors.plum, modifier = Modifier.size(18.dp))
                Text(dayString(p.sunrise, p.city.timeZoneID, lang), color = colors.plum, fontWeight = FontWeight.SemiBold)
            }
            RoundIcon(Icons.AutoMirrored.Filled.KeyboardArrowRight, colors, onNext)
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(top = 4.dp)) {
            Text(s("Panchang day · sunrise to sunrise", "पंचांग दिवस · सूर्योदय से सूर्योदय"), style = MaterialTheme.typography.labelSmall, color = colors.muted)
            if (!isLive) Text(s("Today", "आज"), color = colors.vermilion, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelSmall, modifier = Modifier.clickable(onClick = onToday))
        }
    }
}

@Composable
private fun SummaryCard(p: PanchangResult, lang: Lang, colors: BhaktiColors) {
    BaCard {
        Column(Modifier.fillMaxWidth().padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            p.vrat?.let { Pill(it.name(lang), colors.vermilion) }
            Row(horizontalArrangement = Arrangement.spacedBy(22.dp)) {
                Stat(s("Sunrise", "सूर्योदय"), clockString(p.sunrise, p.city.timeZoneID), colors)
                Stat(s("Sunset", "सूर्यास्त"), clockString(p.sunset, p.city.timeZoneID), colors)
            }
        }
    }
}

@Composable
private fun NowBanner(p: PanchangResult, colors: BhaktiColors, lang: Lang) {
    val cur = p.currentChoghadiya(Instant.now())
    val qc = qualityColor(cur?.quality ?: ChoghadiyaQuality.NEUTRAL, colors)
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp).background(qc.copy(alpha = 0.12f), RoundedCornerShape(14.dp)).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(14.dp).background(qc, CircleShape))
        Column(Modifier.weight(1f)) {
            Text(s("Right now", "इस समय"), style = MaterialTheme.typography.bodySmall, color = colors.muted)
            Text(cur?.name(lang) ?: "—", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
        }
        cur?.let {
            Column(horizontalAlignment = Alignment.End) {
                Text(it.quality.label(lang), color = qc, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodySmall)
                Text(clockString(it.start, p.city.timeZoneID) + " – " + clockString(it.end, p.city.timeZoneID), style = MaterialTheme.typography.labelSmall, color = colors.muted)
            }
        }
    }
}

@Composable
private fun ElementsCard(p: PanchangResult, lang: Lang, colors: BhaktiColors) {
    BaCard {
        ElementRow(s("Tithi", "तिथि"), p.tithi, p.city.timeZoneID, lang, colors)
        HorizontalDivider(color = colors.muted.copy(alpha = 0.18f))
        ElementRow(s("Nakshatra", "नक्षत्र"), p.nakshatra, p.city.timeZoneID, lang, colors)
        HorizontalDivider(color = colors.muted.copy(alpha = 0.18f))
        ElementRow(s("Yoga", "योग"), p.yoga, p.city.timeZoneID, lang, colors)
        HorizontalDivider(color = colors.muted.copy(alpha = 0.18f))
        ElementRow(s("Karana", "करण"), p.karana, p.city.timeZoneID, lang, colors)
    }
}

@Composable
private fun ElementRow(label: String, e: PanchangElement, tz: String, lang: Lang, colors: BhaktiColors) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = colors.muted, modifier = Modifier.weight(1f))
        Column(horizontalAlignment = Alignment.End) {
            Text(e.name(lang), fontWeight = FontWeight.SemiBold, color = colors.ink)
            e.endsAt?.let { Text(s("until ", "") + clockString(it, tz) + s("", " तक"), style = MaterialTheme.typography.labelSmall, color = colors.muted) }
        }
    }
}

@Composable
private fun ChoghadiyaSection(title: String, list: List<Choghadiya>, ref: Instant, tz: String, live: Boolean, lang: Lang, colors: BhaktiColors) {
    val now = Instant.now()
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink, modifier = Modifier.padding(horizontal = 20.dp))
        BaCard {
            list.forEachIndexed { i, c ->
                val isNow = live && c.contains(now)
                val qc = qualityColor(c.quality, colors)
                if (i > 0) HorizontalDivider(color = colors.muted.copy(alpha = 0.15f))
                Row(
                    Modifier.fillMaxWidth().background(qc.copy(alpha = if (isNow) 0.20f else 0.06f)).padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Box(Modifier.size(9.dp).background(qc, CircleShape))
                    Text(c.name(lang), fontWeight = if (isNow) FontWeight.Bold else FontWeight.Medium, color = colors.ink)
                    if (isNow) Pill(s("NOW", "अभी"), qc, filled = true, small = true)
                    Spacer(Modifier.weight(1f))
                    Text(rangeString(c.start, c.end, ref, tz), style = MaterialTheme.typography.labelSmall, color = colors.muted)
                }
            }
        }
    }
}

@Composable
private fun AuspiciousCard(p: PanchangResult, lang: Lang, colors: BhaktiColors) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(s("Auspicious period", "शुभ काल"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink, modifier = Modifier.padding(horizontal = 20.dp))
        BaCard {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(p.abhijit.name(lang), fontWeight = FontWeight.Medium, color = colors.ink, modifier = Modifier.weight(1f))
                Text(clockString(p.abhijit.start, p.city.timeZoneID) + " – " + clockString(p.abhijit.end, p.city.timeZoneID), style = MaterialTheme.typography.labelSmall, color = colors.teal)
            }
        }
    }
}

@Composable
private fun InauspiciousCard(p: PanchangResult, lang: Lang, colors: BhaktiColors) {
    val windows = listOf(p.rahu, p.gulika, p.yamaganda, p.varaVela, p.kalaVela, p.kalaRatri)
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(s("Inauspicious periods", "अशुभ काल"), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink, modifier = Modifier.padding(horizontal = 20.dp))
        BaCard {
            windows.forEachIndexed { i, w ->
                if (i > 0) HorizontalDivider(color = colors.muted.copy(alpha = 0.15f))
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(w.name(lang), fontWeight = FontWeight.Medium, color = colors.ink, modifier = Modifier.weight(1f))
                    Text(rangeString(w.start, w.end, p.sunrise, p.city.timeZoneID), style = MaterialTheme.typography.labelSmall, color = colors.vermilion)
                }
            }
        }
    }
}

// ---------------------------------------------------------------- City picker

@Composable
private fun CityPicker(vm: AppViewModel, lang: Lang, colors: BhaktiColors, onUseGps: () -> Unit, onPick: (City) -> Unit) {
    var query by remember { mutableStateOf("") }
    val results by produceState(initialValue = emptyList<City>(), query) {
        value = if (query.isBlank()) emptyList() else withContext(Dispatchers.Default) { vm.cities.search(query) }
    }
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(bottom = 24.dp)) {
        Text(s("Choose location", "स्थान चुनें"), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold, color = colors.ink, modifier = Modifier.padding(vertical = 8.dp))
        Row(
            Modifier.fillMaxWidth().clickable(onClick = onUseGps).padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(Icons.Filled.LocationOn, null, tint = colors.vermilion)
            Text(s("Use my location", "मेरा स्थान उपयोग करें"), color = colors.ink, fontWeight = FontWeight.Medium)
        }
        HorizontalDivider(color = colors.muted.copy(alpha = 0.15f))
        OutlinedTextField(
            value = query, onValueChange = { query = it },
            placeholder = { Text(s("Search city", "शहर खोजें")) },
            singleLine = true, modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
        )
        if (query.isBlank()) {
            Text(s("Start typing your city — over 10,000 cities worldwide.", "अपना शहर टाइप करें — दुनिया भर के 10,000+ शहर।"),
                style = MaterialTheme.typography.bodySmall, color = colors.muted)
        }
        LazyColumn(Modifier.fillMaxWidth().height(360.dp)) {
            items(results, key = { it.id }) { c ->
                Column(Modifier.fillMaxWidth().clickable { onPick(c) }.padding(vertical = 11.dp)) {
                    Text(c.name(lang), color = colors.ink)
                    Text(c.regionEN, style = MaterialTheme.typography.labelSmall, color = colors.muted)
                }
                HorizontalDivider(color = colors.muted.copy(alpha = 0.1f))
            }
        }
    }
}
