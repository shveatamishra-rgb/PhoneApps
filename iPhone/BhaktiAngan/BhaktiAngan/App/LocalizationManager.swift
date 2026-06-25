import Foundation
import SwiftUI

/// The two content languages the app ships in.
enum Lang { case en, hi }

/// User's language preference. `system` follows the device language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case hindi

    var id: String { rawValue }

    /// Shown in the Settings picker — each in its own script so it's recognizable
    /// regardless of the currently active language.
    var label: String {
        switch self {
        case .system: return "System / सिस्टम"
        case .english: return "English"
        case .hindi: return "हिंदी"
        }
    }
}

/// Drives an in-app English/Hindi toggle that switches instantly, independent of
/// the device's system language and without an app restart. Views observe this
/// as an `@EnvironmentObject`, so changing `preference` re-renders the UI, and
/// read strings via `s(_:_:)` or content via the model's `…(lang)` accessors.
@MainActor
final class LocalizationManager: ObservableObject {
    @Published var preference: AppLanguage {
        didSet { defaults.set(preference.rawValue, forKey: Self.key) }
    }

    private let defaults: UserDefaults
    private static let key = "appLanguage"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Self.key) ?? AppLanguage.system.rawValue
        preference = AppLanguage(rawValue: raw) ?? .system
    }

    /// The resolved content language for the active preference.
    var lang: Lang {
        switch preference {
        case .english: return .en
        case .hindi: return .hi
        case .system:
            let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
            return code.hasPrefix("hi") ? .hi : .en
        }
    }

    var isHindi: Bool { lang == .hi }

    /// Returns the right string for the active language. Keeps both translations
    /// at the call site so UI copy stays readable and reviewable.
    func s(_ en: String, _ hi: String) -> String { lang == .hi ? hi : en }
}
