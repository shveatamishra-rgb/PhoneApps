import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brand, Color(red: 0.36, green: 0.27, blue: 0.84)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: AppTheme.brand.opacity(0.22), radius: 12, y: 6)
        .accessibilityHidden(true)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(isDisabled ? AppTheme.textSecondary.opacity(0.45) : AppTheme.brand)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .disabled(isDisabled || isLoading)
        .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.brand)
        .background(AppTheme.brand.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

struct StatusPill: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }
}

struct CreatorAvatar: View {
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(AppTheme.brand)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [AppTheme.brand.opacity(0.16), AppTheme.accent.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
            .overlay {
                Circle().stroke(AppTheme.brand.opacity(0.12), lineWidth: 1)
            }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 62, height: 62)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(Circle())

            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .appCard()
    }
}

struct LoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(AppTheme.border)
                .frame(width: 120, height: 15)
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.border.opacity(0.8))
                .frame(height: 30)
            RoundedRectangle(cornerRadius: 6)
                .fill(AppTheme.border.opacity(0.65))
                .frame(width: 170, height: 13)
        }
        .redacted(reason: .placeholder)
        .appCard()
        .accessibilityLabel("Loading")
    }
}

struct FormFieldLabel: View {
    let title: String
    var hint: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}
