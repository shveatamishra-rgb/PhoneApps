import Foundation

/// Bilingual (English / Hindi) name tables for the Panchang elements.
enum PanchangNames {
    typealias Bi = (en: String, hi: String)

    // 1..15 within a paksha; index 14 is Purnima (Shukla) / Amavasya (Krishna).
    static let tithi: [Bi] = [
        ("Pratipada", "प्रतिपदा"), ("Dwitiya", "द्वितीया"), ("Tritiya", "तृतीया"),
        ("Chaturthi", "चतुर्थी"), ("Panchami", "पंचमी"), ("Shashthi", "षष्ठी"),
        ("Saptami", "सप्तमी"), ("Ashtami", "अष्टमी"), ("Navami", "नवमी"),
        ("Dashami", "दशमी"), ("Ekadashi", "एकादशी"), ("Dwadashi", "द्वादशी"),
        ("Trayodashi", "त्रयोदशी"), ("Chaturdashi", "चतुर्दशी"), ("Purnima", "पूर्णिमा")
    ]
    static let amavasya: Bi = ("Amavasya", "अमावस्या")
    static let shuklaPaksha: Bi = ("Shukla Paksha", "शुक्ल पक्ष")
    static let krishnaPaksha: Bi = ("Krishna Paksha", "कृष्ण पक्ष")

    static let nakshatra: [Bi] = [
        ("Ashwini", "अश्विनी"), ("Bharani", "भरणी"), ("Krittika", "कृत्तिका"),
        ("Rohini", "रोहिणी"), ("Mrigashira", "मृगशिरा"), ("Ardra", "आर्द्रा"),
        ("Punarvasu", "पुनर्वसु"), ("Pushya", "पुष्य"), ("Ashlesha", "आश्लेषा"),
        ("Magha", "मघा"), ("Purva Phalguni", "पूर्वाफाल्गुनी"), ("Uttara Phalguni", "उत्तराफाल्गुनी"),
        ("Hasta", "हस्त"), ("Chitra", "चित्रा"), ("Swati", "स्वाति"),
        ("Vishakha", "विशाखा"), ("Anuradha", "अनुराधा"), ("Jyeshtha", "ज्येष्ठा"),
        ("Mula", "मूल"), ("Purva Ashadha", "पूर्वाषाढ़ा"), ("Uttara Ashadha", "उत्तराषाढ़ा"),
        ("Shravana", "श्रवण"), ("Dhanishta", "धनिष्ठा"), ("Shatabhisha", "शतभिषा"),
        ("Purva Bhadrapada", "पूर्वाभाद्रपदा"), ("Uttara Bhadrapada", "उत्तराभाद्रपदा"), ("Revati", "रेवती")
    ]

    static let yoga: [Bi] = [
        ("Vishkambha", "विष्कम्भ"), ("Priti", "प्रीति"), ("Ayushman", "आयुष्मान"),
        ("Saubhagya", "सौभाग्य"), ("Shobhana", "शोभन"), ("Atiganda", "अतिगण्ड"),
        ("Sukarma", "सुकर्मा"), ("Dhriti", "धृति"), ("Shula", "शूल"),
        ("Ganda", "गण्ड"), ("Vriddhi", "वृद्धि"), ("Dhruva", "ध्रुव"),
        ("Vyaghata", "व्याघात"), ("Harshana", "हर्षण"), ("Vajra", "वज्र"),
        ("Siddhi", "सिद्धि"), ("Vyatipata", "व्यतीपात"), ("Variyana", "वरीयान"),
        ("Parigha", "परिघ"), ("Shiva", "शिव"), ("Siddha", "सिद्ध"),
        ("Sadhya", "साध्य"), ("Shubha", "शुभ"), ("Shukla", "शुक्ल"),
        ("Brahma", "ब्रह्म"), ("Indra", "इन्द्र"), ("Vaidhriti", "वैधृति")
    ]

    static let karanaMovable: [Bi] = [
        ("Bava", "बव"), ("Balava", "बालव"), ("Kaulava", "कौलव"),
        ("Taitila", "तैतिल"), ("Gara", "गर"), ("Vanija", "वणिज"), ("Vishti", "विष्टि")
    ]
    static let karanaShakuni: Bi = ("Shakuni", "शकुनि")
    static let karanaChatushpada: Bi = ("Chatushpada", "चतुष्पाद")
    static let karanaNaga: Bi = ("Naga", "नाग")
    static let karanaKimstughna: Bi = ("Kimstughna", "किंस्तुघ्न")

    // Cyclic Choghadiya order (planetary). Index used by the weekday rules.
    static let choghadiya: [Bi] = [
        ("Udveg", "उद्वेग"), ("Char", "चर"), ("Labh", "लाभ"), ("Amrit", "अमृत"),
        ("Kaal", "काल"), ("Shubh", "शुभ"), ("Rog", "रोग")
    ]

    static let vara: [Bi] = [
        ("Sunday", "रविवार"), ("Monday", "सोमवार"), ("Tuesday", "मंगलवार"),
        ("Wednesday", "बुधवार"), ("Thursday", "गुरुवार"), ("Friday", "शुक्रवार"),
        ("Saturday", "शनिवार")
    ]

    static let rahuKaal: Bi = ("Rahu Kaal", "राहु काल")
    static let gulikaKaal: Bi = ("Gulika Kaal", "गुलिक काल")
    static let yamaganda: Bi = ("Yamaganda", "यमगण्ड")

    static let abhijit: Bi = ("Abhijit Muhurat", "अभिजीत मुहूर्त")
    static let varaVela: Bi = ("Vara Vela", "वार वेला")
    static let kalaVela: Bi = ("Kala Vela", "काल वेला")
    static let kalaRatri: Bi = ("Kala Ratri", "काल रात्रि")

    /// Monthly vrat / parva keyed by tithi index (0–29: 0–14 = Shukla
    /// Pratipada→Purnima, 15–29 = Krishna Pratipada→Amavasya). These are purely
    /// tithi-derived, so they are exact for any month.
    static let vrat: [Int: Bi] = [
        3:  ("Vinayaka Chaturthi", "विनायक चतुर्थी"),
        7:  ("Durga Ashtami", "दुर्गा अष्टमी"),
        10: ("Ekadashi", "एकादशी"),
        12: ("Pradosh Vrat", "प्रदोष व्रत"),
        14: ("Purnima", "पूर्णिमा"),
        18: ("Sankashti Chaturthi", "संकष्टी चतुर्थी"),
        22: ("Kalashtami", "कालाष्टमी"),
        25: ("Ekadashi", "एकादशी"),
        27: ("Pradosh Vrat", "प्रदोष व्रत"),
        28: ("Masik Shivaratri", "मासिक शिवरात्रि"),
        29: ("Amavasya", "अमावस्या")
    ]
}
