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
                .task {
                    // Publish immediately too, independent of StoreKit, so the widget
                    // still gets data if store.start() is slow on first launch.
                    WidgetBridge.publish(hasPro: store.hasPro, lang: loc.lang)
                    ChoghadiyaBridge.publish()
                    VerseBridge.publish(hasPro: store.hasPro, lang: loc.lang)
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
                    // Keep the widgets in sync with what the app shows.
                    if phase == .active {
                        WidgetBridge.publish(hasPro: store.hasPro, lang: loc.lang)
                        ChoghadiyaBridge.publish()
                        VerseBridge.publish(hasPro: store.hasPro, lang: loc.lang)
                    }
                }
                .onOpenURL { url in
                    // Deep links from the widgets: bhaktiangan://today | ://panchang | ://verse
                    if url.host == "today" || url.host == "home" || url.host == "panchang"
                        || url.host == "verse" {
                        appState.selectedTab = .home
                    }
                }
        }
    }
}
