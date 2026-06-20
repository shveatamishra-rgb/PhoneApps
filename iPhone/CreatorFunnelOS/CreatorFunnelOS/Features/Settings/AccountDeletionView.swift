import SwiftUI

struct AccountDeletionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var password = ""
    @State private var understandsConsequences = false
    @State private var isConfirmationPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                warningHeader
                consequencesCard
                subscriptionCard
                reauthenticationCard

                PrimaryButton(
                    title: "Continue to deletion",
                    systemImage: "trash",
                    isLoading: appState.isLoading,
                    isDisabled: password.count < 6 || !understandsConsequences
                ) {
                    isConfirmationPresented = true
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 34)
        }
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Permanently delete your account?",
            isPresented: $isConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Request account deletion", role: .destructive) {
                Task {
                    _ = await appState.requestAccountDeletion(password: password)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The deletion request starts a 30-day processing period. This action signs you out.")
        }
        .appScreenBackground()
    }

    private var warningHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.danger)
            Text("Delete Creator Funnel OS account")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("This is different from disconnecting Instagram or canceling a subscription.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var consequencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "What will be deleted")
            consequence("Profile and authentication record")
            consequence("Workspace content, funnel configuration, and lead records")
            consequence("Analytics history, recommendations, notes, and audit metadata")
            consequence("Connected-account tokens held by the service")

            Toggle(
                "I understand that deleted workspace data cannot be recovered after processing completes.",
                isOn: $understandsConsequences
            )
            .font(.subheadline)
            .tint(AppTheme.danger)
        }
        .appCard()
    }

    private var subscriptionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .foregroundStyle(AppTheme.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("App Store subscriptions require separate action")
                    .font(.subheadline.weight(.semibold))
                Text("Deleting your account does not automatically cancel an Apple subscription. Manage or cancel it in Apple ID subscription settings.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(2)
                Link("Open subscription settings", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    .font(.caption.weight(.semibold))
            }
        }
        .appCard()
    }

    private var reauthenticationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormFieldLabel(
                title: "Confirm your password",
                hint: "Production builds should use recent authentication or Sign in with Apple reauthorization."
            )
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding(14)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .appCard()
    }

    private func consequence(_ text: String) -> some View {
        Label(text, systemImage: "minus.circle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
    }
}

struct AccountDeletionRequestedView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.success)

            Text("Deletion requested")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("Your account deletion request has been recorded. Production processing completes within 30 days unless legal or security obligations require a different timeline.")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if let date = appState.deletionRequest?.scheduledDeletionDate {
                VStack(spacing: 4) {
                    Text("Scheduled completion")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.headline)
                }
                .appCard()
            }

            Label(
                "Remember to cancel any active App Store subscription separately.",
                systemImage: "creditcard"
            )
            .font(.subheadline)
            .foregroundStyle(AppTheme.warning)
            .appCard()

            PrimaryButton(title: "Return to signed-out state") {
                Task {
                    await appState.signOut()
                }
            }
        }
        .padding(24)
        .appScreenBackground()
    }
}
