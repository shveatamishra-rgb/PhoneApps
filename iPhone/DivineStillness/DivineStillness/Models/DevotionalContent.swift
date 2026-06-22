import Foundation

struct DevotionalItem: Identifiable, Hashable {
    let day: Int
    let imageName: String
    let deity: String
    let category: DeityCategory
    let mantra: String
    let meaning: String
    let blessing: String
    let collection: String
    let isPremium: Bool

    var id: String { imageName }

    var shareText: String {
        "\(deity)\n\n\(mantra)\n\n\(blessing)\n\nShared from Bhakti Angan"
    }
}

struct MantraChoice: Identifiable, Hashable {
    let id: String
    let deity: String
    let mantra: String
    let meaning: String
    let isPremium: Bool
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
}
