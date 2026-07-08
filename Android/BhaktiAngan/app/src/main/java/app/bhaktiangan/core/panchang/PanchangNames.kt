package app.bhaktiangan.core.panchang

import app.bhaktiangan.core.model.Bi

/** Bilingual (English / Hindi) name tables for the Panchang elements. Verbatim port. */
object PanchangNames {

    // 1..15 within a paksha; index 14 is Purnima (Shukla) / Amavasya (Krishna).
    val tithi: List<Bi> = listOf(
        Bi("Pratipada", "प्रतिपदा"), Bi("Dwitiya", "द्वितीया"), Bi("Tritiya", "तृतीया"),
        Bi("Chaturthi", "चतुर्थी"), Bi("Panchami", "पंचमी"), Bi("Shashthi", "षष्ठी"),
        Bi("Saptami", "सप्तमी"), Bi("Ashtami", "अष्टमी"), Bi("Navami", "नवमी"),
        Bi("Dashami", "दशमी"), Bi("Ekadashi", "एकादशी"), Bi("Dwadashi", "द्वादशी"),
        Bi("Trayodashi", "त्रयोदशी"), Bi("Chaturdashi", "चतुर्दशी"), Bi("Purnima", "पूर्णिमा"),
    )
    val amavasya = Bi("Amavasya", "अमावस्या")
    val shuklaPaksha = Bi("Shukla Paksha", "शुक्ल पक्ष")
    val krishnaPaksha = Bi("Krishna Paksha", "कृष्ण पक्ष")

    val nakshatra: List<Bi> = listOf(
        Bi("Ashwini", "अश्विनी"), Bi("Bharani", "भरणी"), Bi("Krittika", "कृत्तिका"),
        Bi("Rohini", "रोहिणी"), Bi("Mrigashira", "मृगशिरा"), Bi("Ardra", "आर्द्रा"),
        Bi("Punarvasu", "पुनर्वसु"), Bi("Pushya", "पुष्य"), Bi("Ashlesha", "आश्लेषा"),
        Bi("Magha", "मघा"), Bi("Purva Phalguni", "पूर्वाफाल्गुनी"), Bi("Uttara Phalguni", "उत्तराफाल्गुनी"),
        Bi("Hasta", "हस्त"), Bi("Chitra", "चित्रा"), Bi("Swati", "स्वाति"),
        Bi("Vishakha", "विशाखा"), Bi("Anuradha", "अनुराधा"), Bi("Jyeshtha", "ज्येष्ठा"),
        Bi("Mula", "मूल"), Bi("Purva Ashadha", "पूर्वाषाढ़ा"), Bi("Uttara Ashadha", "उत्तराषाढ़ा"),
        Bi("Shravana", "श्रवण"), Bi("Dhanishta", "धनिष्ठा"), Bi("Shatabhisha", "शतभिषा"),
        Bi("Purva Bhadrapada", "पूर्वाभाद्रपदा"), Bi("Uttara Bhadrapada", "उत्तराभाद्रपदा"), Bi("Revati", "रेवती"),
    )

    val yoga: List<Bi> = listOf(
        Bi("Vishkambha", "विष्कम्भ"), Bi("Priti", "प्रीति"), Bi("Ayushman", "आयुष्मान"),
        Bi("Saubhagya", "सौभाग्य"), Bi("Shobhana", "शोभन"), Bi("Atiganda", "अतिगण्ड"),
        Bi("Sukarma", "सुकर्मा"), Bi("Dhriti", "धृति"), Bi("Shula", "शूल"),
        Bi("Ganda", "गण्ड"), Bi("Vriddhi", "वृद्धि"), Bi("Dhruva", "ध्रुव"),
        Bi("Vyaghata", "व्याघात"), Bi("Harshana", "हर्षण"), Bi("Vajra", "वज्र"),
        Bi("Siddhi", "सिद्धि"), Bi("Vyatipata", "व्यतीपात"), Bi("Variyana", "वरीयान"),
        Bi("Parigha", "परिघ"), Bi("Shiva", "शिव"), Bi("Siddha", "सिद्ध"),
        Bi("Sadhya", "साध्य"), Bi("Shubha", "शुभ"), Bi("Shukla", "शुक्ल"),
        Bi("Brahma", "ब्रह्म"), Bi("Indra", "इन्द्र"), Bi("Vaidhriti", "वैधृति"),
    )

    val karanaMovable: List<Bi> = listOf(
        Bi("Bava", "बव"), Bi("Balava", "बालव"), Bi("Kaulava", "कौलव"),
        Bi("Taitila", "तैतिल"), Bi("Gara", "गर"), Bi("Vanija", "वणिज"), Bi("Vishti", "विष्टि"),
    )
    val karanaShakuni = Bi("Shakuni", "शकुनि")
    val karanaChatushpada = Bi("Chatushpada", "चतुष्पाद")
    val karanaNaga = Bi("Naga", "नाग")
    val karanaKimstughna = Bi("Kimstughna", "किंस्तुघ्न")

    // Cyclic Choghadiya order (planetary). Index used by the weekday rules.
    val choghadiya: List<Bi> = listOf(
        Bi("Udveg", "उद्वेग"), Bi("Char", "चर"), Bi("Labh", "लाभ"), Bi("Amrit", "अमृत"),
        Bi("Kaal", "काल"), Bi("Shubh", "शुभ"), Bi("Rog", "रोग"),
    )

    val vara: List<Bi> = listOf(
        Bi("Sunday", "रविवार"), Bi("Monday", "सोमवार"), Bi("Tuesday", "मंगलवार"),
        Bi("Wednesday", "बुधवार"), Bi("Thursday", "गुरुवार"), Bi("Friday", "शुक्रवार"),
        Bi("Saturday", "शनिवार"),
    )

    val rahuKaal = Bi("Rahu Kaal", "राहु काल")
    val gulikaKaal = Bi("Gulika Kaal", "गुलिक काल")
    val yamaganda = Bi("Yamaganda", "यमगण्ड")

    val abhijit = Bi("Abhijit Muhurat", "अभिजीत मुहूर्त")
    val varaVela = Bi("Vara Vela", "वार वेला")
    val kalaVela = Bi("Kala Vela", "काल वेला")
    val kalaRatri = Bi("Kala Ratri", "काल रात्रि")

    /**
     * Monthly vrat / parva keyed by tithi index (0–29: 0–14 = Shukla
     * Pratipada→Purnima, 15–29 = Krishna Pratipada→Amavasya). Purely tithi-derived.
     */
    val vrat: Map<Int, Bi> = mapOf(
        3 to Bi("Vinayaka Chaturthi", "विनायक चतुर्थी"),
        7 to Bi("Durga Ashtami", "दुर्गा अष्टमी"),
        10 to Bi("Ekadashi", "एकादशी"),
        12 to Bi("Pradosh Vrat", "प्रदोष व्रत"),
        14 to Bi("Purnima", "पूर्णिमा"),
        18 to Bi("Sankashti Chaturthi", "संकष्टी चतुर्थी"),
        22 to Bi("Kalashtami", "कालाष्टमी"),
        25 to Bi("Ekadashi", "एकादशी"),
        27 to Bi("Pradosh Vrat", "प्रदोष व्रत"),
        28 to Bi("Masik Shivaratri", "मासिक शिवरात्रि"),
        29 to Bi("Amavasya", "अमावस्या"),
    )
}
