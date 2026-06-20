import SwiftUI

struct ConnectAccountView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    BrandMark(size: 46)
                    Spacer()
                    StatusPill(title: "Secure connection", color: AppTheme.success)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Connect your\nInstagram account")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Connect a professional account through the official Meta authorization flow when the production API is enabled.")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(4)
                }

                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 15) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .pink, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 15))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Instagram Professional")
                                .font(.headline)
                            Text("Business or Creator account")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    PrimaryButton(
                        title: "Connect with Instagram",
                        systemImage: "link",
                        isLoading: appState.isLoading,
                        isDisabled: false
                    ) {
                        Task {
                            await appState.connectAccount()
                        }
                    }
                }
                .appCard(padding: 20)

                VStack(alignment: .leading, spacing: 14) {
                    PermissionRow(icon: "checkmark.shield", title: "Official permissions only", detail: "No passwords, scraping, or unofficial automation.")
                    PermissionRow(icon: "hand.raised", title: "You stay in control", detail: "Pause any funnel or disconnect the account at any time.")
                    PermissionRow(icon: "person.crop.circle.badge.checkmark", title: "Authentic engagement", detail: "Built for requested replies, lead capture, and useful follow-up.")
                }

                if appState.isUsingMockServices {
                    Button("Continue with demo account") {
                        Task {
                            await appState.connectAccount()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .appScreenBackground()
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 34, height: 34)
                .background(AppTheme.brand.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}
