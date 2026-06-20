import SwiftUI

enum AppTheme {
    static let brand = Color(red: 0.16, green: 0.31, blue: 0.78)
    static let brandDark = Color(red: 0.08, green: 0.14, blue: 0.29)
    static let accent = Color(red: 0.14, green: 0.64, blue: 0.58)
    static let background = Color(red: 0.965, green: 0.973, blue: 0.985)
    static let card = Color.white
    static let textPrimary = Color(red: 0.08, green: 0.11, blue: 0.18)
    static let textSecondary = Color(red: 0.38, green: 0.42, blue: 0.50)
    static let border = Color(red: 0.88, green: 0.90, blue: 0.94)
    static let success = Color(red: 0.10, green: 0.58, blue: 0.40)
    static let warning = Color(red: 0.92, green: 0.58, blue: 0.16)
    static let danger = Color(red: 0.82, green: 0.24, blue: 0.29)

    static let horizontalPadding: CGFloat = 20
    static let cardRadius: CGFloat = 20

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 28
        static let section: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 10
        static let control: CGFloat = 14
        static let card: CGFloat = 20
        static let hero: CGFloat = 28
    }

    enum TypeScale {
        static let caption: CGFloat = 12
        static let body: CGFloat = 16
        static let title: CGFloat = 22
        static let hero: CGFloat = 32
    }

    enum Shadow {
        static let cardColor = AppTheme.brandDark.opacity(0.05)
        static let cardRadius: CGFloat = 16
        static let cardY: CGFloat = 7
    }
}

struct AppCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.8), lineWidth: 1)
            }
            .shadow(
                color: AppTheme.Shadow.cardColor,
                radius: AppTheme.Shadow.cardRadius,
                y: AppTheme.Shadow.cardY
            )
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(AppCardModifier(padding: padding))
    }

    func appScreenBackground() -> some View {
        background(AppTheme.background.ignoresSafeArea())
    }
}
