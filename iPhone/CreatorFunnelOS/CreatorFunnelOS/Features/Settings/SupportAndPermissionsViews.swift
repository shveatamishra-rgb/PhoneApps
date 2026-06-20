import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var fullName = ""
    @State private var email = ""
    @State private var didSave = false

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Full name", text: $fullName)
                    .textContentType(.name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section {
                Label("Email verified", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
            } footer: {
                Text("Changing a production account email should require verification before it becomes the sign-in address.")
            }

            Section {
                Button("Save profile") {
                    appState.currentUser.fullName = fullName
                    appState.currentUser.email = email
                    didSave = true
                }
                if didSave {
                    Text("Profile saved locally")
                        .foregroundStyle(AppTheme.success)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fullName = appState.currentUser.fullName
            email = appState.currentUser.email
        }
    }
}

struct ConnectedSocialAccountView: View {
    @EnvironmentObject private var appState: AppState
    @State private var didRefresh = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                    Text("@\(appState.workspace.account?.username ?? "not-connected")")
                        .font(.title3.weight(.bold))
                    StatusPill(
                        title: appState.workspace.account?.isConnected == true ? "Connected" : "Disconnected",
                        color: appState.workspace.account?.isConnected == true ? AppTheme.success : AppTheme.danger
                    )
                }
                .frame(maxWidth: .infinity)
                .appCard()

                VStack(spacing: 0) {
                    accountValue("Platform", "Instagram")
                    Divider()
                    accountValue("Account type", "Creator")
                    Divider()
                    accountValue("Last sync", didRefresh ? "Just now" : "7 minutes ago")
                }
                .appCard(padding: 8)

                SecondaryButton(title: "Refresh permissions", systemImage: "arrow.clockwise") {
                    Task {
                        didRefresh = await appState.refreshConnectedAccount()
                    }
                }

                NavigationLink {
                    ConnectedAccountPermissionsView()
                } label: {
                    SettingsLinkRow(icon: "checkmark.shield", title: "Review permissions")
                }
                .buttonStyle(.plain)
                .appCard(padding: 6)
            }
            .padding(20)
        }
        .navigationTitle("Connected account")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func accountValue(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(10)
    }
}

struct WorkspaceSettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: appState.currentWorkspace.name, subtitle: "Current workspace")
                    settingsValue("Plan", appState.subscription.displayTitle)
                    settingsValue("Your role", "Owner")
                    settingsValue("Members", "1")
                }
                .appCard()

                FeatureAvailabilityCard(
                    icon: "rectangle.2.swap",
                    title: "Multiple workspaces",
                    message: "The domain and service contracts support workspace switching. The beta exposes one workspace."
                )
                FeatureAvailabilityCard(
                    icon: "person.badge.shield.checkmark",
                    title: "Team members & roles",
                    message: "Owner, admin, editor, and viewer roles are modeled for a future Team plan."
                )
                FeatureAvailabilityCard(
                    icon: "chart.bar.doc.horizontal",
                    title: "Scheduled reporting",
                    message: "Reporting and export hooks are ready for backend jobs and secure download links."
                )
                FeatureAvailabilityCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Background API sync",
                    message: "A future sync coordinator will reconcile posts, permissions, analytics, and audit logs across clients."
                )
            }
            .padding(20)
        }
        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func settingsValue(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct ConnectedAccountPermissionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.success)
                    Text("Official permissions, clearly explained")
                        .font(.title2.weight(.bold))
                    Text("Production Instagram access must use Meta’s official authorization flow. Creator Funnel OS never asks for your Instagram password.")
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(4)
                }

                permission("Read professional account profile", "Shows the connected handle and account type.")
                permission("Read eligible post metadata", "Lets you assign a funnel to a post you manage.")
                permission("Respond to qualifying interactions", "Sends the configured reply only after a matching keyword request, subject to platform permissions.")
                permission("Read delivery and click events", "Builds operational analytics and recommendations.")

                Label(
                    "Permissions can be revoked by disconnecting the account. Funnels stop when required access is unavailable.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .appCard()
            }
            .padding(20)
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func permission(_ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .appCard()
    }
}

struct HelpSupportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AppTheme.brand)
                    Text("How can we help?")
                        .font(.title2.weight(.bold))
                    Text("Use the topics below for beta guidance. Production support can connect these routes to a help center and authenticated support ticket service.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .appCard()

                SettingsGroup(title: "Popular topics") {
                    SettingsLinkRow(icon: "link", title: "Connecting Instagram")
                    Divider().padding(.leading, 48)
                    SettingsLinkRow(icon: "arrow.triangle.branch", title: "Building a compliant funnel")
                    Divider().padding(.leading, 48)
                    SettingsLinkRow(icon: "creditcard", title: "Billing & subscription")
                    Divider().padding(.leading, 48)
                    SettingsLinkRow(icon: "lock.shield", title: "Privacy & data")
                }

                FeatureAvailabilityCard(
                    icon: "envelope",
                    title: "Contact support",
                    message: "Production builds should show the verified support email and an authenticated ticket form.",
                    badge: "Beta"
                )
            }
            .padding(20)
        }
        .navigationTitle("Help & support")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
