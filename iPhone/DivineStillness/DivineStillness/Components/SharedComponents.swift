import StoreKit
import SwiftUI
import UIKit

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(AppTheme.vermilion, in: Capsule())
            .accessibilityLabel("Pro content")
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

struct ToastView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(AppTheme.teal.opacity(0.96), in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }
}

// MARK: - Legal content

struct LegalTextView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            Text(content)
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .devotionalBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum LegalCopy {
    static let privacy = """
    Bhakti Angan stores your favorites, reminder preferences, daily darshan streak, and japa count on your device. The app does not create an account, sign you in, sell personal information, use advertising trackers, or collect analytics.

    Purchases are processed by Apple through the App Store. Notification permission is used only for the daily darshan reminder you choose to enable. Photo-library add permission is used only when you tap Save to keep a wallpaper.

    Because your data stays on your device, removing the app removes the data. For any question about this policy, use the support link on our App Store listing.
    """

    static let terms = """
    Bhakti Angan provides devotional content for personal reflection. It does not provide religious authority, medical advice, or guarantees of spiritual or material outcomes.

    Free content remains available without purchase. Pro unlocks additional darshan images, all mantras, and unlimited wallpaper saves. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period; you can manage or cancel anytime in your Apple account settings. Lifetime is a one-time purchase. Billing, renewal, cancellation, and refunds are administered by Apple under the Apple Standard License Agreement.

    Devotional images are licensed for personal in-app use and personal wallpaper use. Redistribution, resale, or use as a trademark is not permitted.
    """

    static let faithStandards = """
    The visual collection is offered as respectful devotional art. Each image is reviewed for recognizable iconography, appropriate sacred objects, and respectful presentation.

    The app does not claim that this artwork replaces temple darshan, scripture, lineage, or guidance from a qualified teacher. If a devotee identifies an iconographic concern, we welcome the feedback and correct it promptly.
    """
}

// MARK: - Ratings

/// Requests an App Store review at most once per app version, so the prompt
/// only ever appears at a genuinely positive moment (a completed mala or a
/// streak milestone) and never nags the devotee.
enum ReviewPrompter {
    private static let key = "lastReviewRequestVersion"

    @MainActor
    static func requestIfAppropriate(
        _ request: RequestReviewAction,
        defaults: UserDefaults = .standard
    ) {
        let version = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        guard defaults.string(forKey: key) != version else { return }
        defaults.set(version, forKey: key)
        request()
    }
}
