import SwiftUI

enum AppTheme {
    static let ivory = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let paper = Color(red: 1.00, green: 0.99, blue: 0.97)
    static let vermilion = Color(red: 0.72, green: 0.18, blue: 0.08)
    static let marigold = Color(red: 0.94, green: 0.58, blue: 0.10)
    static let plum = Color(red: 0.24, green: 0.08, blue: 0.16)
    static let teal = Color(red: 0.08, green: 0.38, blue: 0.36)
    static let ink = Color(red: 0.15, green: 0.12, blue: 0.10)
    static let muted = Color(red: 0.43, green: 0.39, blue: 0.35)
}

extension View {
    func devotionalBackground() -> some View {
        background(AppTheme.ivory.ignoresSafeArea())
    }
}
