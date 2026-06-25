import SwiftUI

@main
struct BhaktiAnganApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = StoreManager()
    @StateObject private var audio = AudioManager.shared
    @StateObject private var loc = LocalizationManager()
    @StateObject private var locationManager = LocationManager.shared

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
                }
                .task(priority: .background) {
                    // Decode the ~69k-city dataset off the main thread so the
                    // location picker opens instantly later.
                    _ = Cities.all
                }
        }
    }
}
