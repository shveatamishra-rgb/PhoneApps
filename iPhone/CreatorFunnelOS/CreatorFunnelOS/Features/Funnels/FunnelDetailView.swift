import SwiftUI

struct FunnelDetailView: View {
    enum Section: String, CaseIterable {
        case overview = "Overview"
        case analytics = "Analytics"
    }

    @EnvironmentObject private var appState: AppState
    let funnelID: UUID
    @State private var section: Section = .overview
    @State private var isEditing = false
    @State private var isAssigningPosts = false

    private var funnel: Funnel? {
        appState.workspace.funnels.first(where: { $0.id == funnelID })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let funnel {
                    header(funnel)

                    Picker("Funnel section", selection: $section) {
                        ForEach(Section.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch section {
                    case .overview:
                        overview(funnel)
                    case .analytics:
                        analytics(funnel)
                    }
                } else {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Funnel unavailable",
                        message: "This funnel may have been removed or is still syncing."
                    )
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
        .navigationTitle("Funnel detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if funnel != nil {
                    Button("Edit") { isEditing = true }
                }
            }
        }
        .navigationDestination(isPresented: $isEditing) {
            if let funnel {
                FunnelEditorView(funnel: funnel)
            }
        }
        .sheet(isPresented: $isAssigningPosts) {
            if let funnel {
                FunnelPostAssignmentView(funnel: funnel)
            }
        }
        .appScreenBackground()
    }

    private func header(_ funnel: Funnel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title3)
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(funnel.name)
                        .font(.title3.weight(.bold))
                    Text("Keyword: \(funnel.triggerKeyword)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.brand)
                }
                Spacer()
                StatusPill(title: funnel.status.title, color: statusColor(funnel.status))
            }

            Picker(
                "Status",
                selection: Binding(
                    get: { funnel.status },
                    set: { status in
                        Task {
                            await appState.setFunnelStatus(funnel, status: status)
                        }
                    }
                )
            ) {
                ForEach(FunnelStatus.allCases, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .appCard()
    }

    private func overview(_ funnel: Funnel) -> some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Trigger & messages")
                DetailBlock(label: "Trigger keyword", value: funnel.triggerKeyword)
                DetailBlock(label: "Public reply", value: funnel.publicReply)
                DetailBlock(label: "Direct message", value: funnel.directMessage)
                DetailBlock(label: "Destination", value: funnel.destinationLink)
            }
            .appCard()

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(
                    title: "Assigned posts",
                    subtitle: funnel.connectedPostIds.isEmpty
                        ? "No posts are connected yet"
                        : "\(funnel.connectedPostIds.count) post\(funnel.connectedPostIds.count == 1 ? "" : "s") connected"
                )

                if funnel.connectedPostIds.isEmpty {
                    Text("Assign published or scheduled posts before activating this funnel.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(assignedPosts(funnel)) { post in
                        HStack(spacing: 11) {
                            Image(systemName: "photo")
                                .foregroundStyle(AppTheme.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(post.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }

                SecondaryButton(title: "Manage post assignments", systemImage: "link") {
                    isAssigningPosts = true
                }
            }
            .appCard()
        }
    }

    private func analytics(_ funnel: Funnel) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                KPICard(
                    title: "Triggered",
                    value: "\(funnel.conversations)",
                    detail: "Keyword matches",
                    icon: "text.bubble",
                    tint: AppTheme.brand
                )
                KPICard(
                    title: "Leads",
                    value: "\(funnel.leads)",
                    detail: "Captured contacts",
                    icon: "person.crop.circle.badge.plus",
                    tint: AppTheme.success
                )
            }

            AnalyticsTrendCard(
                title: "Funnel activity",
                subtitle: "Seven-day trigger trend",
                points: appState.workspace.analytics?.sevenDayTrend ?? [],
                tint: AppTheme.brand
            )

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title: "Quality indicators")
                metricRow("Lead conversion", value: conversion(funnel))
                Divider()
                metricRow("Connected posts", value: "\(funnel.connectedPostIds.count)")
                Divider()
                metricRow("Last updated", value: funnel.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .appCard()
        }
    }

    private func assignedPosts(_ funnel: Funnel) -> [SocialPost] {
        appState.socialPosts.filter { funnel.connectedPostIds.contains($0.id) }
    }

    private func conversion(_ funnel: Funnel) -> String {
        guard funnel.conversations > 0 else { return "—" }
        return "\(Int(Double(funnel.leads) / Double(funnel.conversations) * 100))%"
    }

    private func metricRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func statusColor(_ status: FunnelStatus) -> Color {
        switch status {
        case .draft: AppTheme.warning
        case .active: AppTheme.success
        case .paused: AppTheme.textSecondary
        }
    }
}

private struct DetailBlock: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FunnelPostAssignmentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let funnel: Funnel
    @State private var selectedPostIds: Set<UUID>
    @State private var isSaving = false

    init(funnel: Funnel) {
        self.funnel = funnel
        _selectedPostIds = State(initialValue: Set(funnel.connectedPostIds))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if appState.socialPosts.isEmpty {
                        EmptyStateView(
                            icon: "photo.on.rectangle.angled",
                            title: "No Instagram posts yet",
                            message: "Refresh the connected account after publishing a post, then return here."
                        )
                    }

                    ForEach(appState.socialPosts) { post in
                        Button {
                            if selectedPostIds.contains(post.id) {
                                selectedPostIds.remove(post.id)
                            } else {
                                selectedPostIds.insert(post.id)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.title)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text(post.status.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: selectedPostIds.contains(post.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedPostIds.contains(post.id) ? AppTheme.brand : AppTheme.textSecondary)
                            }
                        }
                    }
                } header: {
                    Text("Instagram posts")
                } footer: {
                    Text("Only posts whose content promise matches this funnel should be assigned.")
                }
            }
            .navigationTitle("Assign posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await appState.assignPosts(funnelId: funnel.id, postIds: Array(selectedPostIds))
                dismiss()
            } catch {
                appState.errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
