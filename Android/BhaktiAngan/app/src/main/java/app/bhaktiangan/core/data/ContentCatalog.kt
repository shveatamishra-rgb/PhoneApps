package app.bhaktiangan.core.data

import app.bhaktiangan.core.model.DeityCategory
import app.bhaktiangan.core.model.DevotionalItem
import app.bhaktiangan.core.model.MantraChoice
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.WeekFields

/** Static devotional catalog. 1:1 port of iOS `ContentCatalog`. */
object ContentCatalog {

    private data class Template(
        val deityEN: String,
        val deityHI: String,
        val category: DeityCategory,
        val mantraEN: String,
        val mantraHI: String,
        val meaningEN: String,
        val meaningHI: String,
        val blessingEN: String,
        val blessingHI: String,
    )

    // Hindi devotional copy is an authored draft (reviewed before release).
    private val templates: Map<String, Template> = mapOf(
        "shiv" to Template(
            "Lord Shiva", "भगवान शिव", DeityCategory.SHIVA,
            "Om Namah Shivaya", "ॐ नमः शिवाय",
            "I bow to the peaceful consciousness within all life.",
            "समस्त जीवन में व्याप्त शांत चेतना को मेरा प्रणाम।",
            "May Mahadev bring stillness, courage, and release from inner noise.",
            "महादेव आपको शांति, साहस और भीतर के कोलाहल से मुक्ति प्रदान करें।",
        ),
        "ganesh" to Template(
            "Lord Ganesha", "भगवान गणेश", DeityCategory.GANESHA,
            "Om Gan Ganapataye Namah", "ॐ गं गणपतये नमः",
            "I bow to Ganesha, guide of auspicious beginnings.",
            "शुभ आरंभ के स्वामी श्री गणेश को मेरा प्रणाम।",
            "May Ganpati bring clarity and help you move through every obstacle.",
            "गणपति आपको स्पष्टता दें और हर विघ्न को पार करने में सहायता करें।",
        ),
        "shiv_parivar" to Template(
            "Shiv Parivar", "शिव परिवार", DeityCategory.SHIVA,
            "Om Uma Maheshwaraya Namah", "ॐ उमा महेश्वराय नमः",
            "I bow to Shiva and Parvati, the divine harmony of life.",
            "जीवन के दिव्य संतुलन, शिव और पार्वती को मेरा प्रणाम।",
            "May your home be filled with harmony, protection, and patient love.",
            "आपका घर सामंजस्य, रक्षा और धैर्यपूर्ण प्रेम से भरा रहे।",
        ),
        "krishna" to Template(
            "Lord Krishna", "भगवान कृष्ण", DeityCategory.KRISHNA,
            "Hare Krishna Hare Rama", "हरे कृष्ण हरे राम",
            "A remembrance of divine love, joy, and presence.",
            "दिव्य प्रेम, आनंद और उपस्थिति का स्मरण।",
            "May Krishna bring sweetness, wisdom, and joy to your heart.",
            "श्री कृष्ण आपके हृदय में माधुर्य, ज्ञान और आनंद भरें।",
        ),
        "radha_krishna" to Template(
            "Radha Krishna", "राधा कृष्ण", DeityCategory.KRISHNA,
            "Radhe Radhe", "राधे राधे",
            "A loving remembrance of Radha and selfless devotion.",
            "राधा और निःस्वार्थ भक्ति का प्रेममय स्मरण।",
            "May divine love soften the heart and deepen your devotion.",
            "दिव्य प्रेम आपके हृदय को कोमल करे और भक्ति को गहरा बनाए।",
        ),
        "shri_ram" to Template(
            "Shri Ram", "श्री राम", DeityCategory.RAMA,
            "Shri Ram Jai Ram Jai Jai Ram", "श्री राम जय राम जय जय राम",
            "Victory to the steady, compassionate path of Shri Ram.",
            "श्री राम के धैर्यपूर्ण और करुणामय मार्ग की जय।",
            "May Shri Ram bring dharma, courage, and steadiness in difficult moments.",
            "श्री राम कठिन क्षणों में आपको धर्म, साहस और स्थिरता प्रदान करें।",
        ),
        "shri_ram_parivar" to Template(
            "Ram Darbar", "राम दरबार", DeityCategory.RAMA,
            "Jai Siya Ram", "जय सिया राम",
            "A remembrance of Sita and Ram in love, duty, and grace.",
            "प्रेम, कर्तव्य और कृपा में सीता-राम का स्मरण।",
            "May your family be blessed with unity, service, and protection.",
            "आपका परिवार एकता, सेवा और रक्षा से धन्य रहे।",
        ),
        "shri_hanuman" to Template(
            "Shri Hanuman", "श्री हनुमान", DeityCategory.RAMA,
            "Om Hanumate Namah", "ॐ हनुमते नमः",
            "I bow to Hanuman, embodiment of courage and devotion.",
            "साहस और भक्ति के स्वरूप श्री हनुमान को मेरा प्रणाम।",
            "May Bajrangbali bring fearlessness, strength, and unwavering faith.",
            "बजरंगबली आपको निर्भयता, शक्ति और अटूट श्रद्धा प्रदान करें।",
        ),
        "vishnu" to Template(
            "Lord Vishnu", "भगवान विष्णु", DeityCategory.VISHNU,
            "Om Namo Narayanaya", "ॐ नमो नारायणाय",
            "I bow to Narayana, the sustaining presence in the universe.",
            "ब्रह्मांड के पालनकर्ता नारायण को मेरा प्रणाम।",
            "May Vishnu bring balance, protection, and peace to your path.",
            "भगवान विष्णु आपके मार्ग में संतुलन, रक्षा और शांति लाएँ।",
        ),
        "vishnu_lakshmi" to Template(
            "Vishnu Lakshmi", "विष्णु लक्ष्मी", DeityCategory.VISHNU,
            "Om Lakshmi Narayanaya Namah", "ॐ लक्ष्मी नारायणाय नमः",
            "I bow to the divine union of abundance and preservation.",
            "समृद्धि और पालन के दिव्य मिलन को मेरा प्रणाम।",
            "May your life receive wise abundance, harmony, and contentment.",
            "आपके जीवन में विवेकपूर्ण समृद्धि, सामंजस्य और संतोष आए।",
        ),
        "vaishno_devi" to Template(
            "Mata Vaishno Devi", "माता वैष्णो देवी", DeityCategory.SHAKTI,
            "Jai Mata Di", "जय माता दी",
            "A joyful remembrance of the Divine Mother.",
            "जगत जननी माँ का आनंदमय स्मरण।",
            "May Mata Rani bring protection, hope, and loving strength.",
            "माता रानी आपको रक्षा, आशा और स्नेहमयी शक्ति प्रदान करें।",
        ),
        "venkateshwar_swami" to Template(
            "Venkateshwar Swami", "वेंकटेश्वर स्वामी", DeityCategory.VISHNU,
            "Om Namo Venkatesaya", "ॐ नमो वेंकटेशाय",
            "I bow to Lord Venkateswara, refuge of devotees.",
            "भक्तों के आश्रय भगवान वेंकटेश्वर को मेरा प्रणाम।",
            "May Venkateswara bless your efforts with patience and grace.",
            "भगवान वेंकटेश्वर आपके प्रयासों को धैर्य और कृपा से आशीर्वाद दें।",
        ),
        "balaji" to Template(
            "Lord Balaji", "भगवान बालाजी", DeityCategory.VISHNU,
            "Govinda Govinda", "गोविंदा गोविंदा",
            "A loving call to Govinda, protector and guide.",
            "रक्षक और मार्गदर्शक गोविंदा का प्रेममय आह्वान।",
            "May Balaji bring devotion, stability, and blessings to your home.",
            "बालाजी आपके घर में भक्ति, स्थिरता और आशीर्वाद लाएँ।",
        ),
        "shiv_ling" to Template(
            "Shiv Ling", "शिव लिंग", DeityCategory.SHIVA,
            "Om Namah Shivaya", "ॐ नमः शिवाय",
            "I bow to the formless, eternal presence of Shiva.",
            "शिव की निराकार, शाश्वत उपस्थिति को मेरा प्रणाम।",
            "May this darshan clear the mind and return you to sacred stillness.",
            "यह दर्शन आपके मन को निर्मल करे और पवित्र शांति में लौटाए।",
        ),
        "saraswati_mata" to Template(
            "Saraswati Mata", "सरस्वती माता", DeityCategory.SHAKTI,
            "Om Aim Saraswatyai Namah", "ॐ ऐं सरस्वत्यै नमः",
            "I bow to Saraswati, source of learning, music, and wisdom.",
            "विद्या, संगीत और ज्ञान की स्रोत माँ सरस्वती को मेरा प्रणाम।",
            "May Saraswati bless your words, creativity, and understanding.",
            "माँ सरस्वती आपकी वाणी, सृजनशीलता और समझ को आशीर्वाद दें।",
        ),
        "maa_kali" to Template(
            "Maa Kali", "माँ काली", DeityCategory.SHAKTI,
            "Om Krim Kalikayai Namah", "ॐ क्रीं कालिकायै नमः",
            "I bow to Kali, who transforms fear and illusion.",
            "भय और माया का रूपांतर करने वाली माँ काली को मेरा प्रणाम।",
            "May Maa Kali give you truth, protection, and transformative courage.",
            "माँ काली आपको सत्य, रक्षा और परिवर्तनकारी साहस प्रदान करें।",
        ),
        "brahma" to Template(
            "Lord Brahma", "भगवान ब्रह्मा", DeityCategory.VISHNU,
            "Om Brahmane Namah", "ॐ ब्रह्मणे नमः",
            "I bow to Brahma, the creative intelligence of the cosmos.",
            "सृष्टि की रचनात्मक चेतना भगवान ब्रह्मा को मेरा प्रणाम।",
            "May Brahma awaken fresh ideas, perspective, and purposeful beginnings.",
            "ब्रह्मा आपमें नए विचार, नई दृष्टि और सार्थक आरंभ जगाएँ।",
        ),
        "narsimha" to Template(
            "Lord Narasimha", "भगवान नरसिंह", DeityCategory.VISHNU,
            "Om Namo Bhagavate Narasimhaya", "ॐ नमो भगवते नरसिंहाय",
            "I bow to Narasimha, fierce protector of sincere devotion.",
            "सच्ची भक्ति के प्रचंड रक्षक भगवान नरसिंह को मेरा प्रणाम।",
            "May Narasimha remove fear and protect what is true in your heart.",
            "नरसिंह भय का नाश करें और आपके हृदय के सत्य की रक्षा करें।",
        ),
        "prahlad_and_narsimha" to Template(
            "Prahlad and Narasimha", "प्रह्लाद और नरसिंह", DeityCategory.VISHNU,
            "Om Namo Bhagavate Narasimhaya", "ॐ नमो भगवते नरसिंहाय",
            "A remembrance of fearless faith and divine protection.",
            "निर्भय श्रद्धा और दिव्य रक्षा का स्मरण।",
            "May Prahlad's faith and Narasimha's protection strengthen you.",
            "प्रह्लाद की श्रद्धा और नरसिंह की रक्षा आपको शक्ति दें।",
        ),
    )

    private val slugs: List<String> = listOf(
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
        "ganesh", "shiv_parivar",
    )

    /** Images pulled after iconography review (skipped when building items). */
    val removedImageNames: Set<String> = setOf(
        "day12_venkateshwar_swami",
        "day16_maa_kali", "day35_maa_kali", "day54_maa_kali",
        "day13_balaji", "day32_balaji", "day51_balaji",
        "day11_vaishno_devi", "day30_vaishno_devi",
    )

    /** Leading darshans that stay free (position-based, not day-number-based). */
    const val FREE_DARSHAN_COUNT = 12

    val items: List<DevotionalItem> = buildList {
        slugs.forEachIndexed { index, slug ->
            val t = templates[slug] ?: return@forEachIndexed
            val day = index + 1
            val imageName = "day${day}_$slug"
            if (imageName in removedImageNames) return@forEachIndexed
            add(
                DevotionalItem(
                    day = day, imageName = imageName,
                    deityEN = t.deityEN, deityHI = t.deityHI, category = t.category,
                    mantraEN = t.mantraEN, mantraHI = t.mantraHI,
                    meaningEN = t.meaningEN, meaningHI = t.meaningHI,
                    blessingEN = t.blessingEN, blessingHI = t.blessingHI,
                    isPremium = size >= FREE_DARSHAN_COUNT,
                ),
            )
        }
    }

    val mantraChoices: List<MantraChoice> = templates
        .map { (key, t) ->
            MantraChoice(
                id = key,
                deityEN = t.deityEN, deityHI = t.deityHI,
                mantraEN = t.mantraEN, mantraHI = t.mantraHI,
                meaningEN = t.meaningEN, meaningHI = t.meaningHI,
                isPremium = key !in setOf("shiv", "ganesh", "krishna"),
            )
        }
        .sortedBy { it.deityEN }

    /** Weekday (0 = Sunday) -> deity keyword(s), matched against the image-name slug. */
    private val weekdayDeity: Map<Int, List<String>> = mapOf(
        0 to listOf("shri_ram"),                  // Sunday — Shri Ram
        1 to listOf("shiv"),                      // Monday — Shiva
        2 to listOf("hanuman"),                   // Tuesday — Hanuman
        3 to listOf("ganesh"),                    // Wednesday — Ganesha
        4 to listOf("vishnu"),                    // Thursday — Vishnu
        5 to listOf("vaishno_devi", "saraswati"), // Friday — Devi
        6 to listOf("hanuman"),                   // Saturday — Hanuman
    )

    // US-style week (Sunday start) to mirror Apple's default Calendar ordinality.
    private val weekField = WeekFields.of(DayOfWeek.SUNDAY, 1)

    /**
     * Today's featured darshan, aligned to the weekday's deity. Free users draw
     * only from the free darshans; within a weekday the image advances each week.
     */
    fun dailyItem(date: LocalDate = LocalDate.now(), hasPro: Boolean = false): DevotionalItem {
        val pool = if (hasPro) items else items.take(FREE_DARSHAN_COUNT)
        val weekday = date.dayOfWeek.value % 7 // 0 = Sunday
        val keywords = weekdayDeity[weekday].orEmpty()
        val matches = pool.filter { item -> keywords.any { item.imageName.contains(it) } }
        if (matches.isNotEmpty()) {
            val week = date.get(weekField.weekOfWeekBasedYear())
            return matches[(week - 1).mod(matches.size)]
        }
        val day = date.dayOfYear
        return pool[(day - 1).mod(pool.size)]
    }
}
