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
