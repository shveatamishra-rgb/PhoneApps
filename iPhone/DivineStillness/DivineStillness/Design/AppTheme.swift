import SwiftUI
import UIKit

enum AppTheme {
    // Background and surfaces adapt between a warm ivory (light) and a deep
    // temple-night charcoal (dark). Accents stay saturated and devotional in
    // both modes, brightening slightly in the dark so they keep their glow.
    static let ivory = dynamic(light: (0.98, 0.96, 0.91), dark: (0.07, 0.06, 0.08))
    static let paper = dynamic(light: (1.00, 0.99, 0.97), dark: (0.14, 0.12, 0.15))
    static let vermilion = dynamic(light: (0.72, 0.18, 0.08), dark: (0.93, 0.42, 0.28))
    static let marigold = dynamic(light: (0.94, 0.58, 0.10), dark: (0.98, 0.69, 0.24))
    static let plum = dynamic(light: (0.24, 0.08, 0.16), dark: (0.72, 0.34, 0.52))
    static let teal = dynamic(light: (0.08, 0.38, 0.36), dark: (0.26, 0.68, 0.62))
    static let ink = dynamic(light: (0.15, 0.12, 0.10), dark: (0.96, 0.94, 0.90))
    static let muted = dynamic(light: (0.43, 0.39, 0.35), dark: (0.68, 0.64, 0.60))

    private static func dynamic(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

extension View {
    func devotionalBackground() -> some View {
        background(AppTheme.ivory.ignoresSafeArea())
    }
}

/// User-selectable appearance, persisted as a raw string in `@AppStorage`.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// `nil` means follow the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
