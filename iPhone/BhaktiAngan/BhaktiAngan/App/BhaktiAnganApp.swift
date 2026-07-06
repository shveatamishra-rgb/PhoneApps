import SwiftUI

@main
struct BhaktiAnganApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = StoreManager()
    @StateObject private var audio = AudioManager.shared
    @StateObject private var loc = LocalizationManager()
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .environmentObject(audio)
                .environmentObject(loc)
                .environmentObject(locationManager)
                .task {
                    await store.start()
                    WidgetBridge.publish(hasPro: store.hasPro, lang: loc.lang)
                }
                .task(priority: .background) {
                    // Decode the ~69k-city dataset off the main thread so the
                    // location picker opens instantly later.
                    _ = Cities.all
                }
                .task(priority: .background) {
                    // Remote content pipeline: pick up new/replaced/pulled
                    // darshans (at most one fetch per 12h; offline-safe).
                    await RemoteCatalog.shared.refreshIfStale()
                }
                .task(priority: .background) {
                    // Public gallery like counts (bare GET, no identifiers; read-only
                    // social proof). Same 12h cadence; offline-safe.
                    await LikeCounts.shared.refreshIfStale()
                }
                .onChange(of: scenePhase) { _, phase in
                    // Keep the Daily Darshan widget in sync with what the app shows.
                    if phase == .active {
                        WidgetBridge.publish(hasPro: store.hasPro, lang: loc.lang)
                    }
                }
                .onOpenURL { url in
                    // Deep link from the widget: bhaktiangan://today
                    if url.host == "today" || url.host == "home" {
                        appState.selectedTab = .home
                    }
                }
        }
    }
}
