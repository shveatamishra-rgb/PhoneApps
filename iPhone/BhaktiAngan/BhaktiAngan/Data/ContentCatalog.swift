import Foundation

enum ContentCatalog {
    private struct Template {
        let deityEN: String
        let deityHI: String
        let category: DeityCategory
        let mantraEN: String
        let mantraHI: String
        let meaningEN: String
        let meaningHI: String
        let blessingEN: String
        let blessingHI: String
    }

    // NOTE: the Hindi devotional copy (meanings/blessings) is an authored draft —
    // have it reviewed for tone and accuracy before release. Mantras use standard
    // Devanagari; deity names use common Hindi forms.
    private static let templates: [String: Template] = [
        "shiv": Template(
            deityEN: "Lord Shiva", deityHI: "भगवान शिव",
            category: .shiva,
            mantraEN: "Om Namah Shivaya", mantraHI: "ॐ नमः शिवाय",
            meaningEN: "I bow to the peaceful consciousness within all life.",
            meaningHI: "समस्त जीवन में व्याप्त शांत चेतना को मेरा प्रणाम।",
            blessingEN: "May Mahadev bring stillness, courage, and release from inner noise.",
            blessingHI: "महादेव आपको शांति, साहस और भीतर के कोलाहल से मुक्ति प्रदान करें।"
        ),
        "ganesh": Template(
            deityEN: "Lord Ganesha", deityHI: "भगवान गणेश",
            category: .ganesha,
            mantraEN: "Om Gan Ganapataye Namah", mantraHI: "ॐ गं गणपतये नमः",
            meaningEN: "I bow to Ganesha, guide of auspicious beginnings.",
            meaningHI: "शुभ आरंभ के स्वामी श्री गणेश को मेरा प्रणाम।",
            blessingEN: "May Ganpati bring clarity and help you move through every obstacle.",
            blessingHI: "गणपति आपको स्पष्टता दें और हर विघ्न को पार करने में सहायता करें।"
        ),
        "shiv_parivar": Template(
            deityEN: "Shiv Parivar", deityHI: "शिव परिवार",
            category: .shiva,
            mantraEN: "Om Uma Maheshwaraya Namah", mantraHI: "ॐ उमा महेश्वराय नमः",
            meaningEN: "I bow to Shiva and Parvati, the divine harmony of life.",
            meaningHI: "जीवन के दिव्य संतुलन, शिव और पार्वती को मेरा प्रणाम।",
            blessingEN: "May your home be filled with harmony, protection, and patient love.",
            blessingHI: "आपका घर सामंजस्य, रक्षा और धैर्यपूर्ण प्रेम से भरा रहे।"
        ),
        "krishna": Template(
            deityEN: "Lord Krishna", deityHI: "भगवान कृष्ण",
            category: .krishna,
            mantraEN: "Hare Krishna Hare Rama", mantraHI: "हरे कृष्ण हरे राम",
            meaningEN: "A remembrance of divine love, joy, and presence.",
            meaningHI: "दिव्य प्रेम, आनंद और उपस्थिति का स्मरण।",
            blessingEN: "May Krishna bring sweetness, wisdom, and joy to your heart.",
            blessingHI: "श्री कृष्ण आपके हृदय में माधुर्य, ज्ञान और आनंद भरें।"
        ),
        "radha_krishna": Template(
            deityEN: "Radha Krishna", deityHI: "राधा कृष्ण",
            category: .krishna,
            mantraEN: "Radhe Radhe", mantraHI: "राधे राधे",
            meaningEN: "A loving remembrance of Radha and selfless devotion.",
            meaningHI: "राधा और निःस्वार्थ भक्ति का प्रेममय स्मरण।",
            blessingEN: "May divine love soften the heart and deepen your devotion.",
            blessingHI: "दिव्य प्रेम आपके हृदय को कोमल करे और भक्ति को गहरा बनाए।"
        ),
        "shri_ram": Template(
            deityEN: "Shri Ram", deityHI: "श्री राम",
            category: .rama,
            mantraEN: "Shri Ram Jai Ram Jai Jai Ram", mantraHI: "श्री राम जय राम जय जय राम",
            meaningEN: "Victory to the steady, compassionate path of Shri Ram.",
            meaningHI: "श्री राम के धैर्यपूर्ण और करुणामय मार्ग की जय।",
            blessingEN: "May Shri Ram bring dharma, courage, and steadiness in difficult moments.",
            blessingHI: "श्री राम कठिन क्षणों में आपको धर्म, साहस और स्थिरता प्रदान करें।"
        ),
        "shri_ram_parivar": Template(
            deityEN: "Ram Darbar", deityHI: "राम दरबार",
            category: .rama,
            mantraEN: "Jai Siya Ram", mantraHI: "जय सिया राम",
            meaningEN: "A remembrance of Sita and Ram in love, duty, and grace.",
            meaningHI: "प्रेम, कर्तव्य और कृपा में सीता-राम का स्मरण।",
            blessingEN: "May your family be blessed with unity, service, and protection.",
            blessingHI: "आपका परिवार एकता, सेवा और रक्षा से धन्य रहे।"
        ),
        "shri_hanuman": Template(
            deityEN: "Shri Hanuman", deityHI: "श्री हनुमान",
            category: .rama,
            mantraEN: "Om Hanumate Namah", mantraHI: "ॐ हनुमते नमः",
            meaningEN: "I bow to Hanuman, embodiment of courage and devotion.",
            meaningHI: "साहस और भक्ति के स्वरूप श्री हनुमान को मेरा प्रणाम।",
            blessingEN: "May Bajrangbali bring fearlessness, strength, and unwavering faith.",
            blessingHI: "बजरंगबली आपको निर्भयता, शक्ति और अटूट श्रद्धा प्रदान करें।"
        ),
        "vishnu": Template(
            deityEN: "Lord Vishnu", deityHI: "भगवान विष्णु",
            category: .vishnu,
            mantraEN: "Om Namo Narayanaya", mantraHI: "ॐ नमो नारायणाय",
            meaningEN: "I bow to Narayana, the sustaining presence in the universe.",
            meaningHI: "ब्रह्मांड के पालनकर्ता नारायण को मेरा प्रणाम।",
            blessingEN: "May Vishnu bring balance, protection, and peace to your path.",
            blessingHI: "भगवान विष्णु आपके मार्ग में संतुलन, रक्षा और शांति लाएँ।"
        ),
        "vishnu_lakshmi": Template(
            deityEN: "Vishnu Lakshmi", deityHI: "विष्णु लक्ष्मी",
            category: .vishnu,
            mantraEN: "Om Lakshmi Narayanaya Namah", mantraHI: "ॐ लक्ष्मी नारायणाय नमः",
            meaningEN: "I bow to the divine union of abundance and preservation.",
            meaningHI: "समृद्धि और पालन के दिव्य मिलन को मेरा प्रणाम।",
            blessingEN: "May your life receive wise abundance, harmony, and contentment.",
            blessingHI: "आपके जीवन में विवेकपूर्ण समृद्धि, सामंजस्य और संतोष आए।"
        ),
        "vaishno_devi": Template(
            deityEN: "Mata Vaishno Devi", deityHI: "माता वैष्णो देवी",
            category: .shakti,
            mantraEN: "Jai Mata Di", mantraHI: "जय माता दी",
            meaningEN: "A joyful remembrance of the Divine Mother.",
            meaningHI: "जगत जननी माँ का आनंदमय स्मरण।",
            blessingEN: "May Mata Rani bring protection, hope, and loving strength.",
            blessingHI: "माता रानी आपको रक्षा, आशा और स्नेहमयी शक्ति प्रदान करें।"
        ),
        "venkateshwar_swami": Template(
            deityEN: "Venkateshwar Swami", deityHI: "वेंकटेश्वर स्वामी",
            category: .vishnu,
            mantraEN: "Om Namo Venkatesaya", mantraHI: "ॐ नमो वेंकटेशाय",
            meaningEN: "I bow to Lord Venkateswara, refuge of devotees.",
            meaningHI: "भक्तों के आश्रय भगवान वेंकटेश्वर को मेरा प्रणाम।",
            blessingEN: "May Venkateswara bless your efforts with patience and grace.",
            blessingHI: "भगवान वेंकटेश्वर आपके प्रयासों को धैर्य और कृपा से आशीर्वाद दें।"
        ),
        "balaji": Template(
            deityEN: "Lord Balaji", deityHI: "भगवान बालाजी",
            category: .vishnu,
            mantraEN: "Govinda Govinda", mantraHI: "गोविंदा गोविंदा",
            meaningEN: "A loving call to Govinda, protector and guide.",
            meaningHI: "रक्षक और मार्गदर्शक गोविंदा का प्रेममय आह्वान।",
            blessingEN: "May Balaji bring devotion, stability, and blessings to your home.",
            blessingHI: "बालाजी आपके घर में भक्ति, स्थिरता और आशीर्वाद लाएँ।"
        ),
        "shiv_ling": Template(
            deityEN: "Shiv Ling", deityHI: "शिव लिंग",
            category: .shiva,
            mantraEN: "Om Namah Shivaya", mantraHI: "ॐ नमः शिवाय",
            meaningEN: "I bow to the formless, eternal presence of Shiva.",
            meaningHI: "शिव की निराकार, शाश्वत उपस्थिति को मेरा प्रणाम।",
            blessingEN: "May this darshan clear the mind and return you to sacred stillness.",
            blessingHI: "यह दर्शन आपके मन को निर्मल करे और पवित्र शांति में लौटाए।"
        ),
        "saraswati_mata": Template(
            deityEN: "Saraswati Mata", deityHI: "सरस्वती माता",
            category: .shakti,
            mantraEN: "Om Aim Saraswatyai Namah", mantraHI: "ॐ ऐं सरस्वत्यै नमः",
            meaningEN: "I bow to Saraswati, source of learning, music, and wisdom.",
            meaningHI: "विद्या, संगीत और ज्ञान की स्रोत माँ सरस्वती को मेरा प्रणाम।",
            blessingEN: "May Saraswati bless your words, creativity, and understanding.",
            blessingHI: "माँ सरस्वती आपकी वाणी, सृजनशीलता और समझ को आशीर्वाद दें।"
        ),
        "maa_kali": Template(
            deityEN: "Maa Kali", deityHI: "माँ काली",
            category: .shakti,
            mantraEN: "Om Krim Kalikayai Namah", mantraHI: "ॐ क्रीं कालिकायै नमः",
            meaningEN: "I bow to Kali, who transforms fear and illusion.",
            meaningHI: "भय और माया का रूपांतर करने वाली माँ काली को मेरा प्रणाम।",
            blessingEN: "May Maa Kali give you truth, protection, and transformative courage.",
            blessingHI: "माँ काली आपको सत्य, रक्षा और परिवर्तनकारी साहस प्रदान करें।"
        ),
        "brahma": Template(
            deityEN: "Lord Brahma", deityHI: "भगवान ब्रह्मा",
            category: .vishnu,
            mantraEN: "Om Brahmane Namah", mantraHI: "ॐ ब्रह्मणे नमः",
            meaningEN: "I bow to Brahma, the creative intelligence of the cosmos.",
            meaningHI: "सृष्टि की रचनात्मक चेतना भगवान ब्रह्मा को मेरा प्रणाम।",
            blessingEN: "May Brahma awaken fresh ideas, perspective, and purposeful beginnings.",
            blessingHI: "ब्रह्मा आपमें नए विचार, नई दृष्टि और सार्थक आरंभ जगाएँ।"
        ),
        "narsimha": Template(
            deityEN: "Lord Narasimha", deityHI: "भगवान नरसिंह",
            category: .vishnu,
            mantraEN: "Om Namo Bhagavate Narasimhaya", mantraHI: "ॐ नमो भगवते नरसिंहाय",
            meaningEN: "I bow to Narasimha, fierce protector of sincere devotion.",
            meaningHI: "सच्ची भक्ति के प्रचंड रक्षक भगवान नरसिंह को मेरा प्रणाम।",
            blessingEN: "May Narasimha remove fear and protect what is true in your heart.",
            blessingHI: "नरसिंह भय का नाश करें और आपके हृदय के सत्य की रक्षा करें।"
        ),
        "prahlad_and_narsimha": Template(
            deityEN: "Prahlad and Narasimha", deityHI: "प्रह्लाद और नरसिंह",
            category: .vishnu,
            mantraEN: "Om Namo Bhagavate Narasimhaya", mantraHI: "ॐ नमो भगवते नरसिंहाय",
            meaningEN: "A remembrance of fearless faith and divine protection.",
            meaningHI: "निर्भय श्रद्धा और दिव्य रक्षा का स्मरण।",
            blessingEN: "May Prahlad's faith and Narasimha's protection strengthen you.",
            blessingHI: "प्रह्लाद की श्रद्धा और नरसिंह की रक्षा आपको शक्ति दें।"
        )
    ]

    private static let slugs: [String] = [
        "shiv", "ganesh", "shiv_parivar", "krishna", "radha_krishna",
        "shri_ram", "shri_ram_parivar", "shri_hanuman", "vishnu",
        "vishnu_lakshmi", "vaishno_devi", "venkateshwar_swami", "balaji",
        "shiv_ling", "saraswati_mata", "maa_kali", "brahma", "narsimha",
        "prahlad_and_narsimha", "shiv", "ganesh", "shiv_parivar", "krishna",
        "radha_krishna", "shri_ram", "shri_ram_parivar", "shri_hanuman",
        "vishnu", "vishnu_lakshmi", "vaishno_devi", "venkateshwar_swami",
        "balaji", "shiv_ling", "saraswati_mata", "maa_kali", "brahma",
        "narsimha", "prahlad_and_narsimha", "shiv", "ganesh", "shiv_parivar",
        "krishna", "radha_krishna", "shri_ram", "shri_ram_parivar",
        "shri_hanuman", "vishnu", "vishnu_lakshmi", "vaishno_devi",
        "venkateshwar_swami", "balaji", "shiv_ling", "saraswati_mata",
        "maa_kali", "brahma", "narsimha", "prahlad_and_narsimha", "shiv",
        "ganesh", "shiv_parivar"
    ]

    /// Images pulled from the catalog after iconography review — anatomy
    /// defects or deity-correctness concerns. Add an imageName here to remove
    /// it everywhere without breaking other entries. See Docs/IMAGE_REVIEW.md.
    static let removedImageNames: Set<String> = [
        "day12_venkateshwar_swami", // reported: badly twisted left hand
        "day16_maa_kali",           // not Kali iconography (serene blue Devi)
        "day35_maa_kali",           // not Kali iconography
        "day54_maa_kali",           // not Kali iconography
        "day13_balaji",             // malformed fingers (bust form); standing Venkateshwara kept
        "day32_balaji",             // malformed fingers (bust form)
        "day51_balaji",             // malformed fingers (bust form)
        "day11_vaishno_devi",       // lion hind-leg anatomy incorrect
        "day30_vaishno_devi"        // lion leg anatomy incorrect; day49 (correct) kept
    ]

    /// How many leading darshans stay free. Position-based (not tied to a day
    /// number), so pulling an image never silently changes how many are free or
    /// leaves a locked tile under the "always free" strip on Home.
    static let freeDarshanCount = 12

    static let items: [DevotionalItem] = {
        var result: [DevotionalItem] = []
        for (index, slug) in slugs.enumerated() {
            guard let template = templates[slug] else { continue }
            let day = index + 1
            let imageName = "day\(day)_\(slug)"
            guard !removedImageNames.contains(imageName) else { continue }

            result.append(
                DevotionalItem(
                    day: day,
                    imageName: imageName,
                    deityEN: template.deityEN,
                    deityHI: template.deityHI,
                    category: template.category,
                    mantraEN: template.mantraEN,
                    mantraHI: template.mantraHI,
                    meaningEN: template.meaningEN,
                    meaningHI: template.meaningHI,
                    blessingEN: template.blessingEN,
                    blessingHI: template.blessingHI,
                    isPremium: result.count >= freeDarshanCount
                )
            )
        }
        return result
    }()

    static let mantraChoices: [MantraChoice] = templates
        .map { key, value in
            MantraChoice(
                id: key,
                deityEN: value.deityEN,
                deityHI: value.deityHI,
                mantraEN: value.mantraEN,
                mantraHI: value.mantraHI,
                meaningEN: value.meaningEN,
                meaningHI: value.meaningHI,
                isPremium: !["shiv", "ganesh", "krishna"].contains(key)
            )
        }
        .sorted { $0.deityEN < $1.deityEN }

    /// Today's featured darshan, aligned to the weekday's deity (Mon Shiva,
    /// Tue/Sat Hanuman, Wed Ganesha, Thu Vishnu, Fri Devi, Sun Ram). Free users
    /// draw only from the free darshans — so the daily hero never reveals Pro
    /// art — while Pro users draw from the whole library. Within a weekday's
    /// deity the image advances each week, so the same weekday stays fresh.
    static func dailyItem(for date: Date = Date(), hasPro: Bool = false) -> DevotionalItem {
        let pool = hasPro ? items : Array(items.prefix(freeDarshanCount))
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1   // 0 = Sunday
        let keywords = weekdayDeity[weekday] ?? []
        let matches = pool.filter { item in keywords.contains { item.imageName.contains($0) } }
        if !matches.isEmpty {
            let week = calendar.ordinality(of: .weekOfYear, in: .year, for: date) ?? 1
            return matches[(week - 1) % matches.count]
        }
        // Defensive fallback (every weekday deity is present in the free pool).
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return pool[(day - 1) % pool.count]
    }

    /// Weekday (0 = Sunday) → deity, matched against the image-name slug.
    private static let weekdayDeity: [Int: [String]] = [
        0: ["shri_ram"],                  // Sunday — Shri Ram (Suryavanshi)
        1: ["shiv"],                      // Monday — Shiva
        2: ["hanuman"],                   // Tuesday — Hanuman
        3: ["ganesh"],                    // Wednesday — Ganesha
        4: ["vishnu"],                    // Thursday — Vishnu
        5: ["vaishno_devi", "saraswati"], // Friday — Devi
        6: ["hanuman"]                    // Saturday — Hanuman (Shani's day)
    ]
}
