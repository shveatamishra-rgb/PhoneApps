import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page = 0

    private let pages = [
        OnboardingPage(
            icon: "point.3.connected.trianglepath.dotted",
            eyebrow: "Welcome",
            title: "A calmer operating system for creators",
            message: "Plan content, deliver requested resources, capture leads, and understand what is working—all in one trustworthy workspace."
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            eyebrow: "Creator workflow",
            title: "Plan content with purpose",
            message: "Keep ideas, drafts, publishing notes, and the funnel connected to each post organized before you publish."
        ),
        OnboardingPage(
            icon: "hand.raised.fill",
            eyebrow: "Clear boundaries",
            title: "Built for authentic engagement",
            message: "Creator Funnel OS does not generate followers, mass-follow accounts, scrape credentials, or manufacture engagement."
        ),
        OnboardingPage(
            icon: "bubble.left.and.text.bubble.right",
            eyebrow: "Compliant DM funnels",
            title: "Respond when someone clearly asks",
            message: "A follower comments a specific keyword, receives an accurate public reply, then gets the resource they requested by DM."
        ),
        OnboardingPage(
            icon: "link.badge.plus",
            eyebrow: "Official connection",
            title: "Connect with platform-approved permissions",
            message: "Production integrations use the official Meta authorization flow. We never ask for or store an Instagram password."
        ),
        OnboardingPage(
            icon: "sparkles",
            eyebrow: "Optional Creator Pro",
            title: "Start free and upgrade when it helps",
            message: "The free plan supports a focused workflow. Creator Pro adds more funnels, deeper reporting, and larger lead capacity."
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            eyebrow: "Ready",
            title: "Build a system your audience can trust",
            message: "Use useful content, clear requests, and honest performance insights to strengthen your creator business."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BrandMark(size: 44)
                Spacer()
                if page < pages.count - 1 {
                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 24) {
                        Spacer(minLength: 20)

                        ZStack {
                            Circle()
                                .fill(AppTheme.brand.opacity(0.08))
                                .frame(width: 218, height: 218)

                            Circle()
                                .fill(AppTheme.accent.opacity(0.11))
                                .frame(width: 154, height: 154)
                                .offset(x: 32, y: -25)

                            Image(systemName: item.icon)
                                .font(.system(size: 68, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.brand, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(spacing: 12) {
                            Text(item.eyebrow.uppercased())
                                .font(.caption.weight(.bold))
                                .tracking(1.2)
                                .foregroundStyle(AppTheme.brand)

                            Text(item.title)
                                .font(.system(size: 29, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(item.message)
                                .font(.body)
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 28)

                        Spacer(minLength: 12)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            PrimaryButton(
                title: page == pages.count - 1 ? "Continue to account setup" : "Continue",
                systemImage: "arrow.right"
            ) {
                if page == pages.count - 1 {
                    appState.completeOnboarding()
                } else {
                    withAnimation(.easeInOut) {
                        page += 1
                    }
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.bottom, 22)
        }
        .appScreenBackground()
    }
}

private struct OnboardingPage {
    let icon: String
    let eyebrow: String
    let title: String
    let message: String
}
