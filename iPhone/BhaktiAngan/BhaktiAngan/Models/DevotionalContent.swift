import Foundation

struct DevotionalItem: Identifiable, Hashable {
    let day: Int
    let imageName: String
    let deityEN: String
    let deityHI: String
    let category: DeityCategory
    let mantraEN: String
    let mantraHI: String
    let meaningEN: String
    let meaningHI: String
    let blessingEN: String
    let blessingHI: String
    let isPremium: Bool

    var id: String { imageName }

    func deity(_ l: Lang) -> String { l == .hi ? deityHI : deityEN }
    func mantra(_ l: Lang) -> String { l == .hi ? mantraHI : mantraEN }
    func meaning(_ l: Lang) -> String { l == .hi ? meaningHI : meaningEN }
    func blessing(_ l: Lang) -> String { l == .hi ? blessingHI : blessingEN }
    func collection(_ l: Lang) -> String { category.label(l) }

    func shareText(_ l: Lang) -> String {
        let footer = l == .hi ? "भक्ति आँगन से साझा किया गया" : "Shared from Bhakti Angan"
        return "\(deity(l))\n\n\(mantra(l))\n\n\(blessing(l))\n\n\(footer)"
    }
}

struct MantraChoice: Identifiable, Hashable {
    let id: String
    let deityEN: String
    let deityHI: String
    let mantraEN: String
    let mantraHI: String
    let meaningEN: String
    let meaningHI: String
    let isPremium: Bool

    func deity(_ l: Lang) -> String { l == .hi ? deityHI : deityEN }
    func mantra(_ l: Lang) -> String { l == .hi ? mantraHI : mantraEN }
    func meaning(_ l: Lang) -> String { l == .hi ? meaningHI : meaningEN }
}

enum DeityCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case shiva = "Shiva"
    case vishnu = "Vishnu"
    case shakti = "Devi"
    case rama = "Rama"
    case krishna = "Krishna"
    case ganesha = "Ganesha"

    var id: String { rawValue }

    private var hindi: String {
        switch self {
        case .all: return "सभी"
        case .shiva: return "शिव"
        case .vishnu: return "विष्णु"
        case .shakti: return "देवी"
        case .rama: return "राम"
        case .krishna: return "कृष्ण"
        case .ganesha: return "गणेश"
        }
    }

    func label(_ l: Lang) -> String { l == .hi ? hindi : rawValue }
}

/// A short katha for the Katha tab. Decoded from the bundled `stories.json`
/// (extracted from the website's hindu-stories builders, EN + HI). No network.
struct Story: Identifiable, Hashable, Codable {
    let id: String
    let deity: String
    let titleEN: String
    let titleHI: String
    let eyebrowEN: String
    let eyebrowHI: String
    let introEN: String
    let introHI: String
    let bodyEN: [String]
    let bodyHI: [String]
    let moralEN: String
    let moralHI: String
    let isPremium: Bool

    func title(_ l: Lang) -> String { l == .hi ? titleHI : titleEN }
    func eyebrow(_ l: Lang) -> String { l == .hi ? eyebrowHI : eyebrowEN }
    func intro(_ l: Lang) -> String { l == .hi ? introHI : introEN }
    func body(_ l: Lang) -> [String] { l == .hi ? bodyHI : bodyEN }
    func moral(_ l: Lang) -> String { l == .hi ? moralHI : moralEN }
}

/// A Bhagavad Gita verse (shlok) for the Verse library + Today's Shlok card +
/// the Daily Verse widget. Decoded from the bundled `verses.json`. No network.
/// NOTE: Sanskrit is public-domain; EN/HI meanings + "live it today" lines are an
/// authored draft pending native-speaker / scholar review (see RELEASE_v1.2_CHECKLIST).
struct Verse: Identifiable, Hashable, Codable {
    let id: String
    let ref: String          // "2.47" for display
    let chapter: Int
    let verse: Int
    let theme: String        // karma, dharma, devotion, peace, self
    let sanskrit: String     // Devanagari, lines joined with \n
    let translit: String
    let meaningEN: String
    let meaningHI: String
    let liveEN: String       // one-line "live it today"
    let liveHI: String
    let isPremium: Bool

    func meaning(_ l: Lang) -> String { l == .hi ? meaningHI : meaningEN }
    func live(_ l: Lang) -> String { l == .hi ? liveHI : liveEN }

    /// Localized source label, e.g. "Bhagavad Gita 2.47" / "भगवद्गीता 2.47".
    func source(_ l: Lang) -> String {
        (l == .hi ? "भगवद्गीता " : "Bhagavad Gita ") + ref
    }

    /// Localized theme label for chips/filters.
    func themeLabel(_ l: Lang) -> String {
        Verse.themeLabels[theme]?[l == .hi ? 1 : 0] ?? theme.capitalized
    }

    static let themeLabels: [String: [String]] = [
        "karma":    ["Action", "कर्म"],
        "dharma":   ["Duty", "धर्म"],
        "devotion": ["Devotion", "भक्ति"],
        "peace":    ["Peace", "शांति"],
        "self":     ["The Self", "आत्मा"],
    ]

    static let themeOrder = ["karma", "dharma", "devotion", "peace", "self"]
}
