import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            Group {
                switch appState.phase {
                case .launching:
                    VStack(spacing: 18) {
                        BrandMark(size: 64)
                        ProgressView()
                        Text("Preparing your workspace…")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                case .onboarding:
                    OnboardingView()
                case .authentication:
                    AuthenticationView()
                case .accountConnection:
                    ConnectAccountView()
                case .main:
                    MainTabView()
                case .deletionRequested:
                    AccountDeletionRequestedView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .animation(.easeInOut(duration: 0.28), value: appState.phase)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { appState.errorMessage != nil },
                set: { if !$0 { appState.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "Please try again.")
        }
    }
}
