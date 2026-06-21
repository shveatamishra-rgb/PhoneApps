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

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
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
            if phase == .active { audio.play() } else { audio.pause() }
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

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(AppTab.home)

            LibraryView()
                .tabItem { Label("Darshan", systemImage: "photo.on.rectangle.angled") }
                .tag(AppTab.library)

            JapaView()
                .tabItem { Label("Japa", systemImage: "circle.grid.3x3.fill") }
                .tag(AppTab.japa)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
    }
}
