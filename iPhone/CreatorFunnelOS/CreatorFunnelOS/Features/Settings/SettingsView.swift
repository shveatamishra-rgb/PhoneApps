import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingDisconnectConfirmation = false
    @State private var showingSignOutConfirmation = false
    @State private var restoreMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard

                SettingsGroup(title: "Workspace") {
                    NavigationLink {
                        WorkspaceSettingsView()
                    } label: {
                        SettingsLinkRow(icon: "building.2", title: "Workspace & team")
                    }
                    Divider().padding(.leading, 48)
                    NavigationLink {
                        ConnectedSocialAccountView()
                    } label: {
                        SettingsLinkRow(
                            icon: "camera",
                            title: "Connected Instagram",
                            detail: "@\(appState.workspace.account?.username ?? "not connected")"
                        )
                    }
                    Divider().padding(.leading, 48)
                    NavigationLink {
                        ConnectedAccountPermissionsView()
                    } label: {
                        SettingsLinkRow(icon: "checkmark.shield", title: "Connected account permissions")
                    }
                    Divider().padding(.leading, 48)
                    Button {
                        showingDisconnectConfirmation = true
                    } label: {
                        SettingsLinkRow(
                            icon: "link.circle",
                            title: "Disconnect Instagram",
                            color: AppTheme.danger,
                            isDestructive: true
                        )
                    }
                }

                SettingsGroup(title: "Notifications") {
                    SettingsToggleRow(
                        icon: "bell",
                        title: "Activity notifications",
                        isOn: notificationBinding(\.activityAlerts)
                    )
                    Divider().padding(.leading, 48)
                    SettingsToggleRow(
                        icon: "envelope.badge",
                        title: "Weekly performance digest",
                        isOn: notificationBinding(\.weeklyDigest)
                    )
                    Divider().padding(.leading, 48)
                    SettingsToggleRow(
                        icon: "lightbulb",
                        title: "Recommendation alerts",
                        isOn: notificationBinding(\.recommendationAlerts)
                    )
                }

                FeatureAvailabilityCard(
                    icon: "tray.full",
                    title: "Notifications center",
                    message: "A future inbox will collect permission issues, report delivery, billing notices, and proposal updates."
                )

                subscriptionGroup

                SettingsGroup(title: "Privacy, policies & support") {
                    NavigationLink {
                        LegalDocumentView(document: .privacy)
                    } label: {
                        SettingsLinkRow(icon: "hand.raised", title: "Privacy Policy")
                    }
                    Divider().padding(.leading, 48)
                    NavigationLink {
                        LegalDocumentView(document: .terms)
                    } label: {
                        SettingsLinkRow(icon: "doc.text", title: "Terms of Service")
                    }
                    Divider().padding(.leading, 48)
                    NavigationLink {
                        SubscriptionTermsView()
                    } label: {
                        SettingsLinkRow(icon: "creditcard", title: "Subscription terms")
                    }
                    Divider().padding(.leading, 48)
                    NavigationLink {
                        HelpSupportView()
                    } label: {
                        SettingsLinkRow(icon: "questionmark.circle", title: "Help & support")
                    }
                    Divider().padding(.leading, 48)
                    NavigationLink {
                        AccountDeletionView()
                    } label: {
                        SettingsLinkRow(
                            icon: "trash",
                            title: "Delete account",
                            color: AppTheme.danger,
                            isDestructive: true
                        )
                    }
                }

                SettingsGroup(title: "Session") {
                    Button {
                        showingSignOutConfirmation = true
                    } label: {
                        SettingsLinkRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign out",
                            color: AppTheme.danger,
                            isDestructive: true
                        )
                    }
                }

                Button("Replay onboarding") {
                    appState.resetDemo()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

                Text("Creator Funnel OS 1.0 • iOS")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Disconnect Instagram?",
            isPresented: $showingDisconnectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                Task {
                    await appState.disconnectAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Funnels will pause until an account is connected again.")
        }
        .confirmationDialog(
            "Sign out of Creator Funnel OS?",
            isPresented: $showingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                Task {
                    await appState.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .appScreenBackground()
    }

    private var profileCard: some View {
        NavigationLink {
            ProfileSettingsView()
        } label: {
            HStack(spacing: 13) {
                CreatorAvatar(initials: appState.workspace.account?.initials ?? "MC", size: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser.fullName)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(appState.currentUser.email)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Label("Email verified", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.success)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .appCard()
    }

    private var subscriptionGroup: some View {
        SettingsGroup(title: "Subscription") {
            Button {
                appState.isPaywallPresented = true
            } label: {
                SettingsLinkRow(
                    icon: "sparkles",
                    title: appState.subscription.displayTitle,
                    detail: appState.subscription.status.rawValue.capitalized
                )
            }
            Divider().padding(.leading, 48)
            Button {
                Task {
                    await appState.restorePurchases()
                    restoreMessage = "Purchase history checked"
                }
            } label: {
                SettingsLinkRow(icon: "arrow.clockwise", title: "Restore Purchases")
            }
            Divider().padding(.leading, 48)
            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                SettingsLinkRow(icon: "arrow.up.right.square", title: "Manage Subscription")
            }
            if let restoreMessage {
                Text(restoreMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.success)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            }
        }
    }

    private func notificationBinding(
        _ keyPath: WritableKeyPath<NotificationPreference, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { appState.notificationPreference[keyPath: keyPath] },
            set: { newValue in
                appState.notificationPreference[keyPath: keyPath] = newValue
                let preference = appState.notificationPreference
                Task {
                    await appState.saveNotificationPreference(preference)
                }
            }
        )
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .appCard(padding: 6)
        }
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    var detail: String?
    var color: Color = AppTheme.textPrimary
    var isDestructive = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isDestructive ? color : AppTheme.brand)
                .frame(width: 34, height: 34)
                .background((isDestructive ? color : AppTheme.brand).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.55))
        }
        .padding(10)
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 34, height: 34)
                .background(AppTheme.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(10)
    }
}
