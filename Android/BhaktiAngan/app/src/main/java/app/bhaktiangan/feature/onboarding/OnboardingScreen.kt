package app.bhaktiangan.feature.onboarding

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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.DarshanImage
import app.bhaktiangan.ui.s
import kotlinx.coroutines.launch

@Composable
fun OnboardingScreen(vm: AppViewModel, lang: Lang) {
    val colors = BhaktiTheme.colors
    val pager = rememberPagerState(pageCount = { 3 })
    val scope = rememberCoroutineScope()
    var ishta by remember { mutableStateOf("shiv") }

    Box(Modifier.fillMaxSize().background(colors.ivory)) {
        HorizontalPager(state = pager, modifier = Modifier.fillMaxSize()) { page ->
            when (page) {
                0 -> Welcome(colors) { scope.launch { pager.animateScrollToPage(1) } }
                1 -> Ritual(colors) { scope.launch { pager.animateScrollToPage(2) } }
                else -> Preference(colors, ishta, onPick = { ishta = it }) { vm.completeOnboarding(ishta) }
            }
        }
    }
}

@Composable
private fun Welcome(colors: app.bhaktiangan.designsystem.BhaktiColors, onNext: () -> Unit) {
    PageColumn {
        DarshanImage("day1_shiv", Modifier.size(250.dp, 360.dp).clip(RoundedCornerShape(18.dp)))
        Text("Bhakti Angan", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold, color = colors.plum)
        Text(s("Sacred images, simple mantras, and a daily pause for devotion.", "पावन चित्र, सरल मंत्र, और भक्ति के लिए एक दैनिक ठहराव।"),
            color = colors.muted, textAlign = TextAlign.Center)
        PrimaryButton(s("Continue", "आगे बढ़ें"), colors, onNext)
    }
}

@Composable
private fun Ritual(colors: app.bhaktiangan.designsystem.BhaktiColors, onNext: () -> Unit) {
    PageColumn {
        Text("🌅", style = MaterialTheme.typography.displayLarge)
        Text(s("Make devotion a gentle habit", "भक्ति को एक सहज आदत बनाएँ"), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = colors.plum, textAlign = TextAlign.Center)
        Benefit(s("Daily Darshan", "दैनिक दर्शन"), s("A new sacred image and blessing each day.", "हर दिन एक नया पावन चित्र और आशीर्वाद।"), colors)
        Benefit(s("Japa Counter", "जप गणक"), s("Keep a calm 108-name practice.", "शांत 108-नाम का अभ्यास करें।"), colors)
        Benefit(s("Panchang", "पंचांग"), s("Sunrise, tithi, and auspicious times for your city.", "आपके शहर के लिए सूर्योदय, तिथि और शुभ समय।"), colors)
        PrimaryButton(s("Choose My Deity", "अपना इष्ट चुनें"), colors, onNext)
    }
}

@Composable
private fun Preference(colors: app.bhaktiangan.designsystem.BhaktiColors, ishta: String, onPick: (String) -> Unit, onDone: () -> Unit) {
    PageColumn {
        Text(s("Who would you like to begin with?", "आप किसके साथ आरंभ करना चाहेंगे?"), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = colors.plum, textAlign = TextAlign.Center)
        IshtaRow("shiv", s("Lord Shiva", "भगवान शिव"), s("Om Namah Shivaya", "ॐ नमः शिवाय"), ishta, colors, onPick)
        IshtaRow("ganesh", s("Lord Ganesha", "भगवान गणेश"), s("Om Gan Ganapataye Namah", "ॐ गं गणपतये नमः"), ishta, colors, onPick)
        IshtaRow("krishna", s("Lord Krishna", "भगवान कृष्ण"), s("Hare Krishna Hare Rama", "हरे कृष्ण हरे राम"), ishta, colors, onPick)
        PrimaryButton(s("Begin My Daily Darshan", "मेरा दैनिक दर्शन आरंभ करें"), colors, onDone)
    }
}

@Composable
private fun PageColumn(content: @Composable () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp, Alignment.CenterVertically),
    ) { content() }
}

@Composable
private fun Benefit(title: String, detail: String, colors: app.bhaktiangan.designsystem.BhaktiColors) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.CheckCircle, null, tint = colors.vermilion)
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = colors.ink)
            Text(detail, style = MaterialTheme.typography.bodyMedium, color = colors.muted)
        }
    }
}

@Composable
private fun IshtaRow(id: String, name: String, mantra: String, selected: String, colors: app.bhaktiangan.designsystem.BhaktiColors, onPick: (String) -> Unit) {
    val sel = id == selected
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(colors.paper)
            .border(if (sel) 2.dp else 1.dp, if (sel) colors.vermilion else colors.muted.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
            .clickable { onPick(id) }.padding(16.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(if (sel) Icons.Filled.CheckCircle else Icons.Outlined.Circle, null, tint = if (sel) colors.vermilion else colors.muted)
        Column {
            Text(name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = colors.ink)
            Text(mantra, style = MaterialTheme.typography.bodyMedium, color = colors.muted)
        }
    }
}

@Composable
private fun PrimaryButton(text: String, colors: app.bhaktiangan.designsystem.BhaktiColors, onClick: () -> Unit) {
    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(colors.plum).clickable(onClick = onClick).padding(vertical = 15.dp), contentAlignment = Alignment.Center) {
        Text(text, color = Color.White, fontWeight = FontWeight.Bold)
    }
    Spacer(Modifier.height(4.dp))
}
