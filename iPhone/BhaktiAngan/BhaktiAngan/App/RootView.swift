import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var audio: AudioManager
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearancePreference") private var appearanceRaw = AppearanceMode.system.rawValue
    @State private var showLaunchPaywall = ProcessInfo.processInfo.arguments
        .contains("--show-paywall")
    @State private var showWelcomePaywall = false

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    // QA screen selector. Reads a launch argument OR the QA_SCREEN env var (the latter
    // is reliable under `SIMCTL_CHILD_QA_SCREEN=... xcrun simctl launch`, since simctl
    // does not forward plain argv to ProcessInfo.arguments). Inert in production.
    private static func qaHook(_ arg: String, _ env: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(arg)
            || ProcessInfo.processInfo.environment["QA_SCREEN"] == env
            || UserDefaults.standard.string(forKey: "qaScreen") == env
    }

    var body: some View {
        Group {
            if Self.qaHook("--open-panchang", "panchang") {
                NavigationStack { PanchangView() }   // QA hook for screenshotting the Panchang screen
            } else if Self.qaHook("--open-verses", "verses") {
                NavigationStack { VerseLibraryView() }   // QA hook for screenshotting the Verse library
            } else if Self.qaHook("--open-voicejapa", "voicejapa") {
                VoiceJapaView(choice: ContentCatalog.mantraChoices.first { $0.id == appState.selectedMantraID }
                              ?? ContentCatalog.mantraChoices[0])   // QA hook for the Voice Japa screen
            } else if Self.qaHook("--preview-sharecard", "sharecard") {
                // QA hook: render the actual share-card image so it can be screenshotted.
                let v = VerseCatalog.verseOfDay(hasPro: true) ?? VerseCatalog.all[0]
                Image(uiImage: VerseShareCard.render(verse: v, lang: .en))
                    .resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .tint(AppTheme.vermilion)
        .preferredColorScheme(appearance.colorScheme)
        .onChange(of: appState.hasCompletedOnboarding) { _, completed in
            // The moment onboarding finishes is the highest-intent point to
            // introduce Pro. Show it once, and never to an existing subscriber.
            if completed && !store.hasPro {
                showWelcomePaywall = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                audio.play()
                appState.refreshJapaForToday()
            } else {
                audio.pause()
            }
        }
        .sheet(isPresented: $showLaunchPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showWelcomePaywall) {
            PaywallView()
        }
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var loc: LocalizationManager

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label(loc.s("Today", "आज"), systemImage: "sun.max.fill") }
                .tag(AppTab.home)

            LibraryView()
                .tabItem { Label(loc.s("Darshan", "दर्शन"), systemImage: "photo.on.rectangle.angled") }
                .tag(AppTab.library)

            KathaView()
                .tabItem { Label(loc.s("Katha", "कथा"), systemImage: "book.closed.fill") }
                .tag(AppTab.katha)

            JapaView()
                .tabItem { Label(loc.s("Japa", "जप"), systemImage: "circle.grid.3x3.fill") }
                .tag(AppTab.japa)

            SettingsView()
                .tabItem { Label(loc.s("Settings", "सेटिंग्स"), systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}
