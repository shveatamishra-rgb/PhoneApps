import Foundation

enum ContentCatalog {
    private struct Template {
        let deity: String
        let category: DeityCategory
        let mantra: String
        let meaning: String
        let blessing: String
    }

    private static let templates: [String: Template] = [
        "shiv": Template(
            deity: "Lord Shiva",
            category: .shiva,
            mantra: "Om Namah Shivaya",
            meaning: "I bow to the peaceful consciousness within all life.",
            blessing: "May Mahadev bring stillness, courage, and release from inner noise."
        ),
        "ganesh": Template(
            deity: "Lord Ganesha",
            category: .ganesha,
            mantra: "Om Gan Ganapataye Namah",
            meaning: "I bow to Ganesha, guide of auspicious beginnings.",
            blessing: "May Ganpati bring clarity and help you move through every obstacle."
        ),
        "shiv_parivar": Template(
            deity: "Shiv Parivar",
            category: .shiva,
            mantra: "Om Uma Maheshwaraya Namah",
            meaning: "I bow to Shiva and Parvati, the divine harmony of life.",
            blessing: "May your home be filled with harmony, protection, and patient love."
        ),
        "krishna": Template(
            deity: "Lord Krishna",
            category: .krishna,
            mantra: "Hare Krishna Hare Rama",
            meaning: "A remembrance of divine love, joy, and presence.",
            blessing: "May Krishna bring sweetness, wisdom, and joy to your heart."
        ),
        "radha_krishna": Template(
            deity: "Radha Krishna",
            category: .krishna,
            mantra: "Radhe Radhe",
            meaning: "A loving remembrance of Radha and selfless devotion.",
            blessing: "May divine love soften the heart and deepen your devotion."
        ),
        "shri_ram": Template(
            deity: "Shri Ram",
            category: .rama,
            mantra: "Shri Ram Jai Ram Jai Jai Ram",
            meaning: "Victory to the steady, compassionate path of Shri Ram.",
            blessing: "May Shri Ram bring dharma, courage, and steadiness in difficult moments."
        ),
        "shri_ram_parivar": Template(
            deity: "Ram Darbar",
            category: .rama,
            mantra: "Jai Siya Ram",
            meaning: "A remembrance of Sita and Ram in love, duty, and grace.",
            blessing: "May your family be blessed with unity, service, and protection."
        ),
        "shri_hanuman": Template(
            deity: "Shri Hanuman",
            category: .rama,
            mantra: "Om Hanumate Namah",
            meaning: "I bow to Hanuman, embodiment of courage and devotion.",
            blessing: "May Bajrangbali bring fearlessness, strength, and unwavering faith."
        ),
        "vishnu": Template(
            deity: "Lord Vishnu",
            category: .vishnu,
            mantra: "Om Namo Narayanaya",
            meaning: "I bow to Narayana, the sustaining presence in the universe.",
            blessing: "May Vishnu bring balance, protection, and peace to your path."
        ),
        "vishnu_lakshmi": Template(
            deity: "Vishnu Lakshmi",
            category: .vishnu,
            mantra: "Om Lakshmi Narayanaya Namah",
            meaning: "I bow to the divine union of abundance and preservation.",
            blessing: "May your life receive wise abundance, harmony, and contentment."
        ),
        "vaishno_devi": Template(
            deity: "Mata Vaishno Devi",
            category: .shakti,
            mantra: "Jai Mata Di",
            meaning: "A joyful remembrance of the Divine Mother.",
            blessing: "May Mata Rani bring protection, hope, and loving strength."
        ),
        "venkateshwar_swami": Template(
            deity: "Venkateshwar Swami",
            category: .vishnu,
            mantra: "Om Namo Venkatesaya",
            meaning: "I bow to Lord Venkateswara, refuge of devotees.",
            blessing: "May Venkateswara bless your efforts with patience and grace."
        ),
        "balaji": Template(
            deity: "Lord Balaji",
            category: .vishnu,
            mantra: "Govinda Govinda",
            meaning: "A loving call to Govinda, protector and guide.",
            blessing: "May Balaji bring devotion, stability, and blessings to your home."
        ),
        "shiv_ling": Template(
            deity: "Shiv Ling",
            category: .shiva,
            mantra: "Om Namah Shivaya",
            meaning: "I bow to the formless, eternal presence of Shiva.",
            blessing: "May this darshan clear the mind and return you to sacred stillness."
        ),
        "saraswati_mata": Template(
            deity: "Saraswati Mata",
            category: .shakti,
            mantra: "Om Aim Saraswatyai Namah",
            meaning: "I bow to Saraswati, source of learning, music, and wisdom.",
            blessing: "May Saraswati bless your words, creativity, and understanding."
        ),
        "maa_kali": Template(
            deity: "Maa Kali",
            category: .shakti,
            mantra: "Om Krim Kalikayai Namah",
            meaning: "I bow to Kali, who transforms fear and illusion.",
            blessing: "May Maa Kali give you truth, protection, and transformative courage."
        ),
        "brahma": Template(
            deity: "Lord Brahma",
            category: .vishnu,
            mantra: "Om Brahmane Namah",
            meaning: "I bow to Brahma, the creative intelligence of the cosmos.",
            blessing: "May Brahma awaken fresh ideas, perspective, and purposeful beginnings."
        ),
        "narsimha": Template(
            deity: "Lord Narasimha",
            category: .vishnu,
            mantra: "Om Namo Bhagavate Narasimhaya",
            meaning: "I bow to Narasimha, fierce protector of sincere devotion.",
            blessing: "May Narasimha remove fear and protect what is true in your heart."
        ),
        "prahlad_and_narsimha": Template(
            deity: "Prahlad and Narasimha",
            category: .vishnu,
            mantra: "Om Namo Bhagavate Narasimhaya",
            meaning: "A remembrance of fearless faith and divine protection.",
            blessing: "May Prahlad's faith and Narasimha's protection strengthen you."
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
        "day12_venkateshwar_swami" // reported: badly twisted left hand
    ]

    static let items: [DevotionalItem] = slugs.enumerated().compactMap { index, slug in
        guard let template = templates[slug] else { return nil }
        let day = index + 1
        let imageName = "day\(day)_\(slug)"
        guard !removedImageNames.contains(imageName) else { return nil }

        return DevotionalItem(
            day: day,
            imageName: imageName,
            deity: template.deity,
            category: template.category,
            mantra: template.mantra,
            meaning: template.meaning,
            blessing: template.blessing,
            collection: template.category.rawValue,
            isPremium: day > 12
        )
    }

    static let mantraChoices: [MantraChoice] = templates
        .map { key, value in
            MantraChoice(
                id: key,
                deity: value.deity,
                mantra: value.mantra,
                meaning: value.meaning,
                isPremium: !["shiv", "ganesh", "krishna"].contains(key)
            )
        }
        .sorted { $0.deity < $1.deity }

    static func dailyItem(for date: Date = Date()) -> DevotionalItem {
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        return items[(day - 1) % items.count]
    }
}
