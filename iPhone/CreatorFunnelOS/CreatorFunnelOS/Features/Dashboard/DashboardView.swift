import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedProposal: Proposal?
    @State private var isLoadingProposal = false

    private let metricColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                accountStatusCard
                subscriptionStatusCard

                if appState.isLoading && appState.workspace.metrics.isEmpty {
                    loadingState
                } else {
                    kpiSection
                    bestPerformingFunnel
                    bestPerformingPost
                    trendSection
                    recommendationSection
                    recentActivity
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 34)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.isPaywallPresented = true
                } label: {
                    Image(systemName: "sparkles")
                }
                .accessibilityLabel("View Creator Pro")
            }
        }
        .overlay {
            if isLoadingProposal {
                ProgressView("Preparing proposal…")
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .sheet(item: $selectedProposal) { proposal in
            ProposalPreviewView(proposal: proposal)
        }
        .refreshable {
            await appState.refreshWorkspace()
        }
        .appScreenBackground()
    }

    private var accountStatusCard: some View {
        HStack(spacing: 13) {
            CreatorAvatar(initials: appState.workspace.account?.initials ?? "CF", size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(appState.workspace.account?.displayName ?? "Connect your creator account")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                if let handle = appState.workspace.account?.username {
                    Text("@\(handle)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            StatusPill(
                title: appState.workspace.account?.isConnected == true ? "Connected" : "Disconnected",
                color: appState.workspace.account?.isConnected == true ? AppTheme.success : AppTheme.danger
            )
        }
        .appCard(padding: 14)
    }

    private var subscriptionStatusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: appState.subscription.hasProAccess ? "sparkles" : "checkmark.seal")
                .foregroundStyle(appState.subscription.hasProAccess ? AppTheme.warning : AppTheme.brand)
                .frame(width: 40, height: 40)
                .background(
                    (appState.subscription.hasProAccess ? AppTheme.warning : AppTheme.brand).opacity(0.09)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(appState.subscription.displayTitle)
                    .font(.subheadline.weight(.semibold))
                Text(subscriptionDetail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if !appState.subscription.hasProAccess {
                Button("View plans") {
                    appState.isPaywallPresented = true
                }
                .font(.caption.weight(.semibold))
            }
        }
        .appCard(padding: 14)
    }

    private var loadingState: some View {
        LazyVGrid(columns: metricColumns, spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                LoadingCard()
            }
        }
    }

    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Performance insights", subtitle: "Event-based creator operations • last 30 days")

            LazyVGrid(columns: metricColumns, spacing: 12) {
                ForEach(appState.workspace.metrics) { metric in
                    KPICard(
                        title: metric.title,
                        value: metric.value,
                        detail: metric.change,
                        icon: metric.kind.icon,
                        tint: tint(for: metric.kind)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var bestPerformingFunnel: some View {
        if let funnel = bestFunnel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Best-performing funnel")
                            .font(.headline)
                        Text(funnel.name)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    StatusPill(title: funnel.triggerKeyword, color: AppTheme.brand)
                }

                HStack {
                    compactStat(value: "\(funnel.conversations)", label: "Triggers")
                    Spacer()
                    compactStat(value: "\(funnel.leads)", label: "Leads")
                    Spacer()
                    compactStat(
                        value: funnel.conversations == 0
                            ? "—"
                            : "\(Int(Double(funnel.leads) / Double(funnel.conversations) * 100))%",
                        label: "Conversion"
                    )
                }
            }
            .appCard()
        }
    }

    @ViewBuilder
    private var bestPerformingPost: some View {
        if
            let id = appState.workspace.analytics?.bestPerformingPostId,
            let post = SampleData.socialPosts.first(where: { $0.id == id })
        {
            HStack(spacing: 13) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .frame(width: 48, height: 48)
                    .background(Color.purple.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best-performing post")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(post.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(2)
                    Text("Highest requested-resource conversion this month")
                        .font(.caption)
                        .foregroundStyle(AppTheme.success)
                }
                Spacer()
            }
            .appCard()
        }
    }

    @ViewBuilder
    private var trendSection: some View {
        if let analytics = appState.workspace.analytics {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Trends", subtitle: "Requested interactions, not vanity metrics")
                AnalyticsTrendCard(
                    title: "7-day trigger volume",
                    subtitle: "Comments that matched an active keyword",
                    points: analytics.sevenDayTrend,
                    tint: AppTheme.brand
                )
                AnalyticsTrendCard(
                    title: "30-day funnel activity",
                    subtitle: "A longer view of requested conversations",
                    points: analytics.thirtyDayTrend,
                    tint: AppTheme.accent
                )
            }
        }
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(
                title: "Recommendations",
                subtitle: "Evidence-based proposals you review before anything changes"
            )

            let visible = appState.workspace.recommendations.filter { $0.status != .dismissed }
            if visible.isEmpty {
                EmptyStateView(
                    icon: "checkmark.seal",
                    title: "Nothing needs attention",
                    message: "New proposals will appear when there is enough performance evidence to suggest a useful next step."
                )
            } else {
                ForEach(visible) { recommendation in
                    RecommendationCard(recommendation: recommendation) {
                        open(recommendation)
                    } onDismiss: {
                        Task {
                            await appState.dismissRecommendation(recommendation)
                        }
                    }
                }
            }
        }
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Recent activity", subtitle: "What people chose to do")

            if appState.workspace.activity.isEmpty {
                EmptyStateView(
                    icon: "waveform.path.ecg",
                    title: "No activity yet",
                    message: "Once a follower requests a reply or opens a destination, it will appear here."
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.workspace.activity.enumerated()), id: \.element.id) { index, event in
                        ActivityRow(event: event)
                        if index < appState.workspace.activity.count - 1 {
                            Divider()
                                .padding(.leading, 50)
                        }
                    }
                }
                .appCard(padding: 8)
            }
        }
    }

    private var bestFunnel: Funnel? {
        guard let id = appState.workspace.analytics?.bestPerformingFunnelId else {
            return appState.workspace.funnels.max(by: { $0.leads < $1.leads })
        }
        return appState.workspace.funnels.first(where: { $0.id == id })
    }

    private var subscriptionDetail: String {
        switch appState.subscription.status {
        case .active:
            appState.subscription.tier == .free
                ? "A focused workflow with one active-funnel allowance."
                : "Renews \(appState.subscription.renewalDate?.formatted(date: .abbreviated, time: .omitted) ?? "automatically")."
        case .trial:
            "Trial access is active. Review renewal details before the trial ends."
        case .expired:
            "Paid features are unavailable until the plan is renewed."
        case .canceled:
            "Access continues until the current billing period ends."
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func compactStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func tint(for kind: DashboardMetric.Kind) -> Color {
        switch kind {
        case .conversations, .triggeredComments: AppTheme.brand
        case .successfulDMs: AppTheme.accent
        case .leads, .leadConversion: AppTheme.success
        case .clickRate: .purple
        case .activeFunnels: AppTheme.warning
        }
    }

    private func open(_ recommendation: Recommendation) {
        isLoadingProposal = true
        Task {
            selectedProposal = await appState.proposal(for: recommendation)
            isLoadingProposal = false
        }
    }
}

private struct ActivityRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.kind.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 38, height: 38)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(event.detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(event.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(10)
    }
}
