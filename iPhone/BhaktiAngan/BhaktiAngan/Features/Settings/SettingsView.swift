import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var audio: AudioManager
    @EnvironmentObject private var loc: LocalizationManager
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
            .navigationTitle(loc.s("Settings", "सेटिंग्स"))
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
                Button(loc.s("OK", "ठीक है"), role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var proSection: some View {
        Section {
            if store.hasPro {
                Label(loc.s("Bhakti Angan Pro is active", "भक्ति आँगन प्रो सक्रिय है"), systemImage: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.teal)

                Button(loc.s("Manage Subscription", "सदस्यता प्रबंधित करें")) {
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
                        Label(loc.s("Unlock Bhakti Angan Pro", "भक्ति आँगन प्रो अनलॉक करें"), systemImage: "sparkles")
                        Spacer()
                        ProBadge()
                    }
                }
            }

            Button(loc.s("Restore Purchases", "खरीद पुनर्स्थापित करें")) {
                Task {
                    await store.restore()
                    alertMessage = store.hasPro
                        ? loc.s("Your Pro access has been restored.", "आपकी प्रो पहुँच पुनर्स्थापित कर दी गई है।")
                        : loc.s("No previous Pro purchase was found.", "कोई पिछली प्रो खरीद नहीं मिली।")
                }
            }
        } header: {
            Text(loc.s("Membership", "सदस्यता"))
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(loc.s("Language", "भाषा"), selection: $loc.preference) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.label).tag(language)
                }
            }

            Picker(loc.s("Appearance", "रूप"), selection: Binding(
                get: { AppearanceMode(rawValue: appearanceRaw) ?? .system },
                set: { appearanceRaw = $0.rawValue }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(appearanceLabel(mode)).tag(mode)
                }
            }

            if audio.isAvailable {
                Toggle(loc.s("Background music", "पृष्ठभूमि संगीत"), isOn: $audio.isEnabled)
            }
        } header: {
            Text(loc.s("Appearance & Language", "रूप और भाषा"))
        }
    }

    private func appearanceLabel(_ mode: AppearanceMode) -> String {
        switch mode {
        case .system: return loc.s("System", "सिस्टम")
        case .light: return loc.s("Light", "उजाला")
        case .dark: return loc.s("Dark", "अँधेरा")
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
        } header: {
            Text(loc.s("Connect", "जुड़ें"))
        } footer: {
            Text(loc.s(
                "Follow Bhakti Angan for new darshans, mantras, and festival collections.",
                "नए दर्शन, मंत्र और पर्व संग्रह के लिए भक्ति आँगन को फ़ॉलो करें।"
            ))
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
            Toggle(loc.s("Daily darshan reminder", "दैनिक दर्शन स्मरण"), isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { _, enabled in
                    updateReminder(enabled: enabled)
                }

            if reminderEnabled {
                DatePicker(
                    loc.s("Reminder time", "स्मरण का समय"),
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

            Picker(loc.s("Preferred deity", "पसंदीदा देवता"), selection: Binding(
                get: { appState.selectedMantraID },
                set: { appState.selectMantra($0) }
            )) {
                ForEach(ContentCatalog.mantraChoices.filter {
                    ["shiv", "ganesh", "krishna"].contains($0.id)
                }) { choice in
                    Text(choice.deity(loc.lang)).tag(choice.id)
                }
            }
        } header: {
            Text(loc.s("Daily Practice", "दैनिक अभ्यास"))
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink(loc.s("Contact Support", "सहायता से संपर्क करें")) {
                SupportView()
            }
            NavigationLink(loc.s("Privacy Policy", "गोपनीयता नीति")) {
                LegalTextView(title: loc.s("Privacy Policy", "गोपनीयता नीति"), content: LegalCopy.privacy)
            }
            NavigationLink(loc.s("Terms of Use", "उपयोग की शर्तें")) {
                LegalTextView(title: loc.s("Terms of Use", "उपयोग की शर्तें"), content: LegalCopy.terms)
            }
            NavigationLink(loc.s("Image and Faith Standards", "चित्र और आस्था मानक")) {
                LegalTextView(
                    title: loc.s("Image and Faith Standards", "चित्र और आस्था मानक"),
                    content: LegalCopy.faithStandards
                )
            }
            NavigationLink(loc.s("Acknowledgements", "आभार")) {
                LegalTextView(
                    title: loc.s("Acknowledgements", "आभार"),
                    content: LegalCopy.acknowledgements
                )
            }
            Link(
                "Apple Standard License Agreement",
                destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
            )

            HStack {
                Text(loc.s("Version", "संस्करण"))
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(AppTheme.muted)
            }
        } header: {
            Text(loc.s("About", "परिचय"))
        } footer: {
            Text(loc.s("Privacy and terms are shown in English.", "गोपनीयता और शर्तें अंग्रेज़ी में दिखाई जाती हैं।"))
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
                    minute: reminderMinute,
                    title: loc.s("Your daily darshan is ready", "आपका दैनिक दर्शन तैयार है"),
                    body: loc.s(
                        "Take one quiet minute for mantra, prayer, and stillness.",
                        "मंत्र, प्रार्थना और शांति के लिए एक शांत मिनट निकालें।"
                    )
                )
            } catch {
                reminderEnabled = false
                alertMessage = error.localizedDescription
            }
        }
    }
}
