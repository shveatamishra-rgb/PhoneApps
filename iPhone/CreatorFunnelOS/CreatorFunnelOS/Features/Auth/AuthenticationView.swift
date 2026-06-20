import SwiftUI

struct AuthenticationView: View {
    enum Mode: String, CaseIterable {
        case signIn = "Sign in"
        case signUp = "Create account"
    }

    @EnvironmentObject private var appState: AppState
    @State private var mode: Mode = .signIn
    @State private var fullName = "Maya Chen"
    @State private var email = "creator@example.com"
    @State private var password = "password"
    @State private var isForgotPasswordPresented = false
    @State private var isVerificationPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                authCard

                Text("Authentication is simulated locally in this beta. The production boundary is isolated behind AuthService for your identity provider.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 34)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $isForgotPasswordPresented) {
            PasswordResetView(email: email)
        }
        .sheet(isPresented: $isVerificationPresented) {
            VerifyEmailView(email: email)
        }
        .appScreenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            BrandMark(size: 54)

            VStack(alignment: .leading, spacing: 8) {
                Text(mode == .signIn ? "Welcome back" : "Create your workspace")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(
                    mode == .signIn
                        ? "Sign in to continue your creator workflow."
                        : "Start with a secure account, then connect your professional Instagram profile."
                )
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(4)
            }
        }
    }

    private var authCard: some View {
        VStack(spacing: 18) {
            Picker("Authentication mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if mode == .signUp {
                VStack(alignment: .leading, spacing: 8) {
                    FormFieldLabel(title: "Full name")
                    TextField("Your name", text: $fullName)
                        .textContentType(.name)
                        .authFieldStyle()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                FormFieldLabel(title: "Email")
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .authFieldStyle()
            }

            VStack(alignment: .leading, spacing: 8) {
                FormFieldLabel(
                    title: "Password",
                    hint: mode == .signUp ? "Use at least eight characters" : nil
                )
                SecureField("Password", text: $password)
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .authFieldStyle()
            }

            if mode == .signIn {
                HStack {
                    Spacer()
                    Button("Forgot password?") {
                        isForgotPasswordPresented = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            PrimaryButton(
                title: mode.rawValue,
                systemImage: "arrow.right",
                isLoading: appState.isLoading,
                isDisabled: !canSubmit
            ) {
                submit()
            }

            HStack(spacing: 4) {
                Text(mode == .signIn ? "New to Creator Funnel OS?" : "Already have an account?")
                    .foregroundStyle(AppTheme.textSecondary)
                Button(mode == .signIn ? "Create one" : "Sign in") {
                    withAnimation {
                        mode = mode == .signIn ? .signUp : .signIn
                    }
                }
                .fontWeight(.semibold)
            }
            .font(.caption)
        }
        .appCard(padding: 20)
    }

    private var canSubmit: Bool {
        email.contains("@")
            && password.count >= (mode == .signUp ? 8 : 6)
            && (mode == .signIn || !fullName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func submit() {
        Task {
            let session = await appState.authenticate(
                fullName: fullName,
                email: email,
                password: password,
                isSignUp: mode == .signUp
            )
            if session?.isEmailVerified == false {
                isVerificationPresented = true
            }
        }
    }
}

private struct PasswordResetView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State var email: String
    @State private var didSend = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: didSend ? "envelope.badge.fill" : "key.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 72, height: 72)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(Circle())

                Text(didSend ? "Check your email" : "Reset your password")
                    .font(.title2.weight(.bold))

                Text(
                    didSend
                        ? "If an account exists for \(email), a secure reset link has been sent."
                        : "Enter the email associated with your account. We will send a time-limited reset link."
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

                if !didSend {
                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .authFieldStyle()

                    PrimaryButton(title: "Send reset link", systemImage: "paperplane") {
                        Task {
                            didSend = await appState.sendPasswordReset(email: email)
                        }
                    }
                } else {
                    PrimaryButton(title: "Done") {
                        dismiss()
                    }
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Password help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .appScreenBackground()
        }
    }
}

private struct VerifyEmailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let email: String
    @State private var resent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "checkmark.message.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 76, height: 76)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(Circle())

                Text("Verify your email")
                    .font(.title2.weight(.bold))

                Text("We sent a verification link to \(email). Verifying helps protect connected accounts and workspace data.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                PrimaryButton(title: "I verified my email", systemImage: "checkmark") {
                    dismiss()
                    appState.completeEmailVerification()
                }

                SecondaryButton(
                    title: resent ? "Verification email sent" : "Resend verification email",
                    systemImage: "arrow.clockwise"
                ) {
                    Task {
                        await appState.resendVerificationEmail()
                        resent = true
                    }
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Email verification")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension View {
    func authFieldStyle() -> some View {
        padding(15)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}
