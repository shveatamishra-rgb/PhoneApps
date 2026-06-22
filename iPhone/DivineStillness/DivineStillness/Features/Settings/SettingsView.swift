import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var audio: AudioManager
    @AppStorage("appearancePreference") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("dailyReminderEnabled") private var reminderEnabled = false
    @AppStorage("dailyReminderHour") private var reminderHour = 7
    @AppStorage("dailyReminderMinute") private var reminderMinute = 0
    @State private var reminderDate = Date()
    @State private var showPaywall = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                practiceSection
                connectSection
                supportSection

#if DEBUG
                Section("Development") {
                    Toggle("Preview Pro entitlement", isOn: $store.debugProEnabled)
                }
#endif
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.ivory)
            .navigationTitle("Settings")
            .onAppear {
                reminderDate = Calendar.current.date(
                    bySettingHour: reminderHour,
                    minute: reminderMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert(
                "Bhakti Angan",
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var proSection: some View {
        Section {
            if store.hasPro {
                Label("Bhakti Angan Pro is active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.teal)

                Button("Manage Subscription") {
                    Task {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            try? await AppStore.showManageSubscriptions(in: scene)
                        }
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Bhakti Angan Pro", systemImage: "sparkles")
                        Spacer()
                        ProBadge()
                    }
                }
            }

            Button("Restore Purchases") {
                Task {
                    await store.restore()
                    alertMessage = store.hasPro
                        ? "Your Pro access has been restored."
                        : "No previous Pro purchase was found."
                }
            }
        } header: {
            Text("Membership")
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { AppearanceMode(rawValue: appearanceRaw) ?? .system },
                set: { appearanceRaw = $0.rawValue }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }

            if audio.isAvailable {
                Toggle("Background music", isOn: $audio.isEnabled)
            }
        } header: {
            Text("Appearance & Sound")
        }
    }

    private var connectSection: some View {
        Section {
            socialLink(
                "Instagram",
                systemImage: "camera.fill",
                url: "https://www.instagram.com/bhaktiangan/"
            )
            socialLink(
                "YouTube",
                systemImage: "play.rectangle.fill",
                url: "https://www.youtube.com/@bhaktiangan-om"
            )
            socialLink(
                "Facebook",
                systemImage: "hand.thumbsup.fill",
                url: "https://www.facebook.com/profile.php?id=61591060441988"
            )
            socialLink(
                "Email us",
                systemImage: "envelope.fill",
                url: "mailto:support@bhaktiangan.in"
            )
        } header: {
            Text("Connect")
        } footer: {
            Text("Follow Bhakti Angan for new darshans, mantras, and festival collections.")
        }
    }

    private func socialLink(
        _ title: String,
        systemImage: String,
        url: String
    ) -> some View {
        Link(destination: URL(string: url)!) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(AppTheme.ink)
        }
    }

    private var practiceSection: some View {
        Section {
            Toggle("Daily darshan reminder", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { _, enabled in
                    updateReminder(enabled: enabled)
                }

            if reminderEnabled {
                DatePicker(
                    "Reminder time",
                    selection: $reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: reminderDate) { _, date in
                    let components = Calendar.current.dateComponents(
                        [.hour, .minute],
                        from: date
                    )
                    reminderHour = components.hour ?? 7
                    reminderMinute = components.minute ?? 0
                    updateReminder(enabled: true)
                }
            }

            Picker("Preferred deity", selection: Binding(
                get: { appState.selectedMantraID },
                set: { appState.selectMantra($0) }
            )) {
                ForEach(ContentCatalog.mantraChoices.filter {
                    ["shiv", "ganesh", "krishna"].contains($0.id)
                }) { choice in
                    Text(choice.deity).tag(choice.id)
                }
            }
        } header: {
            Text("Daily Practice")
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink("Privacy Policy") {
                LegalTextView(title: "Privacy Policy", content: LegalCopy.privacy)
            }
            NavigationLink("Terms of Use") {
                LegalTextView(title: "Terms of Use", content: LegalCopy.terms)
            }
            NavigationLink("Image and Faith Standards") {
                LegalTextView(
                    title: "Image and Faith Standards",
                    content: LegalCopy.faithStandards
                )
            }
            Link(
                "Apple Standard License Agreement",
                destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
            )

            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(AppTheme.muted)
            }
        } header: {
            Text("About")
        }
    }

    private var appVersionString: String {
        let version = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func updateReminder(enabled: Bool) {
        if !enabled {
            NotificationManager.disableDailyReminder()
            return
        }

        Task {
            do {
                try await NotificationManager.requestAndSchedule(
                    hour: reminderHour,
                    minute: reminderMinute
                )
            } catch {
                reminderEnabled = false
                alertMessage = error.localizedDescription
            }
        }
    }
}
