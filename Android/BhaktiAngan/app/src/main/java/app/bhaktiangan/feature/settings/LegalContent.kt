package app.bhaktiangan.feature.settings

/** In-app legal / informational copy (ported verbatim from iOS `LegalCopy`). */
object LegalCopy {
    const val PRIVACY = """Bhakti Angan stores your favorites, reminder preferences, daily darshan streak, and japa count on your device. The app does not create an account, sign you in, sell personal information, use advertising trackers, or collect analytics.

Purchases are processed by Google through the Play Store. Notification permission is used only for the daily darshan reminder you choose to enable. Photo-library access is used only when you tap Save to keep a wallpaper. Location permission, if you grant it, is used only on your device to calculate Panchang timings (sunrise, sunset, and auspicious periods) and is never transmitted or stored — you can instead pick a city by hand.

Because your data stays on your device, removing the app removes the data. The in-app Contact Support form opens your own mail app to write to us; it does not send anything to our servers automatically. For any question about this policy, use Contact Support in Settings or the support link on our Play Store listing."""

    const val TERMS = """Bhakti Angan provides devotional content for personal reflection. It does not provide religious authority, medical advice, or guarantees of spiritual or material outcomes.

Free content remains available without purchase. Pro unlocks additional darshan images, all mantras, and unlimited wallpaper saves. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period; you can manage or cancel anytime in your Google Play account settings. Lifetime is a one-time purchase. Billing, renewal, cancellation, and refunds are administered by Google Play.

Devotional images are licensed for personal in-app use and personal wallpaper use. Redistribution, resale, or use as a trademark is not permitted."""

    const val FAITH_STANDARDS = """The visual collection is offered as respectful devotional art. Each image is reviewed for recognizable iconography, appropriate sacred objects, and respectful presentation.

The app does not claim that this artwork replaces temple darshan, scripture, lineage, or guidance from a qualified teacher. If a devotee identifies an iconographic concern, we welcome the feedback and correct it promptly."""

    const val ACKNOWLEDGEMENTS = """City names, coordinates, and time zones used for Panchang calculations are derived from the GeoNames geographical database, © GeoNames, licensed under Creative Commons Attribution 4.0 (CC BY 4.0). See https://www.geonames.org and https://creativecommons.org/licenses/by/4.0/.

Panchang timings (sunrise, sunset, tithi, nakshatra, yoga, karana, and Choghadiya) are computed on your device using standard astronomical algorithms."""

    fun byKind(kind: String): Pair<String, String> = when (kind) {
        "terms" -> "Terms of Use" to TERMS
        "faith" -> "Image and Faith Standards" to FAITH_STANDARDS
        "ack" -> "Acknowledgements" to ACKNOWLEDGEMENTS
        else -> "Privacy Policy" to PRIVACY
    }
}
