import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
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
                practiceSection
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
                "Divine Stillness",
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
                Label("Divine Stillness Pro is active", systemImage: "checkmark.seal.fill")
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
                        Label("Unlock Divine Stillness Pro", systemImage: "sparkles")
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
                Text("1.0 (1)")
                    .foregroundStyle(AppTheme.muted)
            }
        } header: {
            Text("About")
        }
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
