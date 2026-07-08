package app.bhaktiangan.feature.paywall

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.bhaktiangan.AppViewModel
import app.bhaktiangan.core.billing.BillingManager
import app.bhaktiangan.core.model.Lang
import app.bhaktiangan.designsystem.BhaktiTheme
import app.bhaktiangan.ui.DarshanImage
import app.bhaktiangan.ui.findActivity
import app.bhaktiangan.ui.s
import app.bhaktiangan.ui.tr

private data class Plan(val id: String, val title: String, val detail: String, val badge: String?, val fallback: String)

@Composable
fun PaywallScreen(vm: AppViewModel, lang: Lang, onClose: () -> Unit) {
    val colors = BhaktiTheme.colors
    val ctx = LocalContext.current
    val products by vm.billing.products.collectAsState()
    var selected by remember { mutableStateOf(BillingManager.YEARLY) }

    val plans = listOf(
        Plan(BillingManager.YEARLY, s("Annual", "वार्षिक"), s("7-day free trial, then about \$2.50/mo", "7-दिन का निःशुल्क परीक्षण, फिर लगभग \$2.50/माह"), s("BEST VALUE", "सर्वोत्तम"), "\$29.99/yr"),
        Plan(BillingManager.MONTHLY, s("Monthly", "मासिक"), s("Cancel anytime", "कभी भी रद्द करें"), null, "\$4.99/mo"),
        Plan(BillingManager.LIFETIME, s("Lifetime", "लाइफटाइम"), s("One-time purchase, no subscription", "एकमुश्त खरीद, कोई सदस्यता नहीं"), null, "\$39.99"),
    )

    fun priceOf(plan: Plan): String {
        val pd = products[plan.id] ?: return plan.fallback
        val raw = if (plan.id == BillingManager.LIFETIME) {
            pd.oneTimePurchaseOfferDetails?.formattedPrice
        } else {
            pd.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.lastOrNull()?.formattedPrice
        } ?: return plan.fallback
        return when (plan.id) {
            BillingManager.YEARLY -> "$raw/yr"
            BillingManager.MONTHLY -> "$raw/mo"
            else -> raw
        }
    }

    Scaffold(containerColor = colors.ivory) { pad ->
        Column(Modifier.padding(pad).fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                IconButton(onClick = onClose) { Icon(Icons.Filled.Close, s("Close", "बंद करें"), tint = colors.muted) }
            }
            DarshanImage("brandmark", Modifier.size(88.dp).clip(CircleShape))
            Text("Bhakti Angan Pro", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = colors.plum)
            Text(s("A deeper daily practice, with the complete sacred collection.", "एक गहरा दैनिक अभ्यास, संपूर्ण पावन संग्रह के साथ।"), color = colors.muted, textAlign = TextAlign.Center)

            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(colors.paper).padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Feature(s("The complete darshan library", "संपूर्ण दर्शन संग्रह"), colors)
                Feature(s("Unlimited wallpaper saves", "असीमित वॉलपेपर सहेजें"), colors)
                Feature(s("All deity mantras for japa", "जप के लिए सभी देवताओं के मंत्र"), colors)
                Feature(s("Custom daily reminders", "अनुकूलित दैनिक स्मरण"), colors)
                Feature(s("New festival collections", "नए पर्व संग्रह"), colors)
            }

            plans.forEach { plan -> PlanCard(plan.title, priceOf(plan), plan.detail, plan.badge, selected == plan.id, colors) { selected = plan.id } }

            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(colors.plum).clickable {
                val activity = ctx.findActivity()
                if (products[selected] != null && activity != null) {
                    vm.purchase(activity, selected)
                } else {
                    Toast.makeText(ctx, tr(lang, "In-app purchases arrive with the store release.", "इन-ऐप खरीद स्टोर रिलीज़ के साथ आएगी।"), Toast.LENGTH_LONG).show()
                }
            }.padding(vertical = 15.dp), contentAlignment = Alignment.Center) {
                Text(if (selected == BillingManager.LIFETIME) s("Unlock Lifetime", "लाइफटाइम अनलॉक करें") else s("Start Free Trial", "निःशुल्क परीक्षण शुरू करें"), color = Color.White, fontWeight = FontWeight.Bold)
            }

            Text(s("Restore Purchases", "खरीद पुनर्स्थापित करें"), color = colors.vermilion, fontWeight = FontWeight.SemiBold, modifier = Modifier.clickable {
                vm.billing.refresh()
                Toast.makeText(ctx, tr(lang, "Checking your purchases…", "आपकी खरीद जाँची जा रही है…"), Toast.LENGTH_SHORT).show()
            })

            Text(
                s("Subscriptions renew automatically unless cancelled at least 24 hours before the period ends. A free trial, if offered, converts to a paid subscription unless cancelled before it ends. Lifetime is a one-time purchase. Billing is handled by Google Play.",
                    "सदस्यता स्वतः नवीनीकृत होती है, जब तक कि अवधि समाप्त होने से कम से कम 24 घंटे पहले रद्द न की जाए। निःशुल्क परीक्षण, यदि उपलब्ध हो, रद्द न करने पर सशुल्क सदस्यता में बदल जाता है। लाइफटाइम एकमुश्त खरीद है। बिलिंग Google Play द्वारा की जाती है।"),
                style = MaterialTheme.typography.bodySmall, color = colors.muted, textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun Feature(text: String, colors: app.bhaktiangan.designsystem.BhaktiColors) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(Icons.Filled.Check, null, tint = colors.vermilion, modifier = Modifier.size(20.dp))
        Text(text, color = colors.ink, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun PlanCard(title: String, price: String, detail: String, badge: String?, selected: Boolean, colors: app.bhaktiangan.designsystem.BhaktiColors, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(colors.paper)
            .border(if (selected) 2.dp else 1.dp, if (selected) colors.vermilion else colors.muted.copy(alpha = 0.25f), RoundedCornerShape(12.dp))
            .clickable(onClick = onClick).padding(15.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(if (selected) Icons.Filled.Check else Icons.Filled.Close, null, tint = if (selected) colors.vermilion else Color.Transparent, modifier = Modifier.size(22.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
                badge?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = Color.White, fontWeight = FontWeight.Black, modifier = Modifier.clip(CircleShape).background(colors.marigold).padding(horizontal = 7.dp, vertical = 3.dp)) }
            }
            Text(detail, style = MaterialTheme.typography.bodySmall, color = colors.muted)
        }
        Text(price, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.ink)
    }
}
