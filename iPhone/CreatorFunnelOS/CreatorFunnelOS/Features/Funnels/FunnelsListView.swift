import SwiftUI

struct FunnelsListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var isCreatingFunnel = false
    @State private var selectedFunnel: Funnel?

    private var filteredFunnels: [Funnel] {
        guard !searchText.isEmpty else { return appState.workspace.funnels }
        return appState.workspace.funnels.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.triggerKeyword.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                complianceBanner

                if filteredFunnels.isEmpty {
                    EmptyStateView(
                        icon: "point.3.connected.trianglepath.dotted",
                        title: searchText.isEmpty ? "Create your first funnel" : "No funnels found",
                        message: searchText.isEmpty
                            ? "Start with one useful keyword response and a destination that matches the promise."
                            : "Try a different name or trigger keyword.",
                        actionTitle: searchText.isEmpty ? "Create funnel" : nil
                    ) {
                        isCreatingFunnel = true
                    }
                } else {
                    ForEach(filteredFunnels) { funnel in
                        FunnelCard(funnel: funnel) {
                            selectedFunnel = funnel
                        } onToggle: {
                            Task {
                                await appState.toggleFunnel(funnel)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .navigationTitle("Funnels")
        .searchable(text: $searchText, prompt: "Search funnels or keywords")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreatingFunnel = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create funnel")
            }
        }
        .navigationDestination(isPresented: $isCreatingFunnel) {
            FunnelEditorView(funnel: .blank)
        }
        .navigationDestination(item: $selectedFunnel) { funnel in
            FunnelDetailView(funnelID: funnel.id)
        }
        .appScreenBackground()
    }

    private var complianceBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(AppTheme.success)
            VStack(alignment: .leading, spacing: 4) {
                Text("Consent-led automation")
                    .font(.subheadline.weight(.semibold))
                Text("Funnel replies should only follow an explicit keyword request and use approved platform APIs.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .appCard()
    }
}

private struct FunnelCard: View {
    let funnel: Funnel
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 5) {
                    Text(funnel.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    HStack(spacing: 5) {
                        Text("Trigger")
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(funnel.triggerKeyword)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.brand)
                    }
                    .font(.caption)
                }

                Spacer()

                if funnel.status == .draft {
                    StatusPill(title: "Draft", color: AppTheme.warning)
                } else {
                    Toggle("", isOn: Binding(
                        get: { funnel.isActive },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                    .accessibilityLabel(funnel.isActive ? "Pause funnel" : "Activate funnel")
                }
            }

            Divider()

            HStack {
                FunnelStat(value: "\(funnel.conversations)", label: "Conversations")
                Spacer()
                FunnelStat(value: "\(funnel.leads)", label: "Leads")
                Spacer()
                FunnelStat(
                    value: funnel.conversations == 0 ? "—" : "\(Int((Double(funnel.leads) / Double(funnel.conversations)) * 100))%",
                    label: "Capture"
                )
            }

            HStack {
                StatusPill(
                    title: funnel.status.title,
                    color: statusColor
                )
                Spacer()
                Text("Updated \(funnel.updatedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                Button(action: onEdit) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 30, height: 30)
                }
                .accessibilityLabel("Edit \(funnel.name)")
            }
        }
        .appCard()
    }

    private var statusColor: Color {
        switch funnel.status {
        case .draft: AppTheme.warning
        case .active: AppTheme.success
        case .paused: AppTheme.textSecondary
        }
    }
}

private struct FunnelStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
