import SwiftUI

@main
struct DivineStillnessApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var store = StoreManager()
    @StateObject private var audio = AudioManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .environmentObject(audio)
                .task {
                    await store.start()
                }
        }
    }
}
