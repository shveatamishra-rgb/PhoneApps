import SwiftUI

@main
struct CreatorFunnelOSApp: App {
    @StateObject private var appState: AppState

    init() {
        let configuration = AppConfiguration.current
        let services: ServiceContainer = configuration.useMockServices
            ? .mock()
            : .production(configuration: configuration)
        _appState = StateObject(
            wrappedValue: AppState(
                services: services,
                configuration: configuration
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(AppTheme.brand)
                .preferredColorScheme(.light)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
