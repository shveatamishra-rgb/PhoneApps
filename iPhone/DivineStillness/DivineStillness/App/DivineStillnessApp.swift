import SwiftUI

@main
struct DivineStillnessApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .task {
                    await store.start()
                }
        }
    }
}
