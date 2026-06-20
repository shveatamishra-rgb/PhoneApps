import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var didRestore = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    currentPlanCard
                    benefits
                    plans
                    teamPlaceholder
                    billingActions
                    legalCopy
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 34)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .appScreenBackground()
        }
        .task {
            await appState.loadBillingProducts()
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            BrandMark(size: 66)
            VStack(spacing: 8) {
                Text("Build a system that scales\nwithout losing trust")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Start free. Upgrade for more active funnels, deeper analytics, and larger lead capacity.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }

    private var currentPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Current plan")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(appState.subscription.displayTitle)
                        .font(.title3.weight(.bold))
                }
                Spacer()
                StatusPill(title: statusTitle, color: statusColor)
            }

            Text(currentPlanDetail)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .appCard()
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Compare features")
            FeatureComparisonRow(title: "Content planner", free: "Included", pro: "Included")
            FeatureComparisonRow(title: "Active funnels", free: "1", pro: "Unlimited")
            FeatureComparisonRow(title: "Analytics history", free: "7 days", pro: "90 days")
            FeatureComparisonRow(title: "Lead capacity", free: "100", pro: "Unlimited")
            FeatureComparisonRow(title: "CSV export", free: "—", pro: "Included")
        }
        .appCard()
    }

    private var plans: some View {
        VStack(spacing: 12) {
            PricingCard(
                title: "Free",
                price: "$0",
                cadence: "no renewal",
                detail: "Core planning and one active-funnel allowance",
                isSelected: appState.subscription.tier == .free
            ) {}

            PricingCard(
                title: "Pro Monthly",
                price: appState.price(for: .monthly),
                cadence: "per month",
                detail: "Flexible, cancel anytime",
                isSelected: selectedPlan == .monthly
            ) {
                selectedPlan = .monthly
            }

            PricingCard(
                title: "Pro Yearly",
                price: appState.price(for: .yearly),
                cadence: "per year",
                detail: "Save 33% compared with monthly",
                badge: "Best value",
                isSelected: selectedPlan == .yearly
            ) {
                selectedPlan = .yearly
            }

            PrimaryButton(
                title: appState.subscription.hasProAccess ? "Change plan" : "Start Creator Pro",
                systemImage: "sparkles",
                isLoading: appState.isLoading
            ) {
                Task {
                    await appState.purchase(selectedPlan)
                }
            }

            Text("Purchases are securely processed by the App Store. Your plan becomes active after Apple verifies the transaction.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var teamPlaceholder: some View {
        FeatureAvailabilityCard(
            icon: "person.3",
            title: "Team workspace",
            message: "Future support for multiple members, role permissions, shared templates, and workspace reporting.",
            badge: "Planned"
        )
    }

    private var billingActions: some View {
        VStack(spacing: 8) {
            SecondaryButton(title: "Restore Purchases", systemImage: "arrow.clockwise") {
                Task {
                    await appState.restorePurchases()
                    didRestore = true
                }
            }

            if didRestore {
                Text("Purchase history checked. Your current entitlement is shown above.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.success)
                    .multilineTextAlignment(.center)
            }

            Link(
                destination: URL(string: "https://apps.apple.com/account/subscriptions")!
            ) {
                Label("Manage Subscription", systemImage: "arrow.up.right.square")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }

            Text("Purchases are restored only when you choose Restore Purchases. The app does not auto-restore on launch.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var legalCopy: some View {
        VStack(spacing: 12) {
            Text("Payment will be charged through the App Store. Paid plans renew automatically unless canceled at least 24 hours before the end of the current period. Trials convert to the selected paid plan unless canceled before the trial ends.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            HStack(spacing: 18) {
                NavigationLink("Privacy") {
                    LegalDocumentView(document: .privacy)
                }
                NavigationLink("Terms") {
                    LegalDocumentView(document: .terms)
                }
                NavigationLink("Subscription terms") {
                    SubscriptionTermsView()
                }
            }
            .font(.caption.weight(.semibold))
        }
    }

    private var statusTitle: String {
        switch appState.subscription.status {
        case .active: "Active"
        case .trial: "Trial"
        case .expired: "Expired"
        case .canceled: "Canceled"
        }
    }

    private var statusColor: Color {
        switch appState.subscription.status {
        case .active, .trial: AppTheme.success
        case .expired: AppTheme.danger
        case .canceled: AppTheme.warning
        }
    }

    private var currentPlanDetail: String {
        switch appState.subscription.status {
        case .active:
            if let renewalDate = appState.subscription.renewalDate {
                return "Renews \(renewalDate.formatted(date: .long, time: .omitted)). You can manage renewal in your App Store subscriptions."
            }
            return "No paid renewal is scheduled on the Free plan."
        case .trial:
            return "Trial access is active. The renewal date and selected plan should be shown before purchase confirmation."
        case .expired:
            return "Paid features are unavailable. Your workspace data remains intact while you choose what to do next."
        case .canceled:
            return "The plan will not renew. Access continues through the current paid period."
        }
    }
}

private struct FeatureComparisonRow: View {
    let title: String
    let free: String
    let pro: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(free)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 62)
            Text(pro)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 72)
        }
    }
}

struct SubscriptionTermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Subscription terms")
                    .font(.title2.weight(.bold))
                Text("Creator Pro is offered as an auto-renewable subscription through the App Store. The exact localized price and purchase confirmation are shown by Apple before payment.")
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
                Text("Managing or canceling")
                    .font(.headline)
                Text("Subscriptions are managed through the Apple ID used for purchase. Deleting a Creator Funnel OS account does not automatically cancel an App Store subscription; the user must manage that subscription separately.")
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(4)
            }
            .padding(24)
        }
        .navigationTitle("Subscription terms")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
