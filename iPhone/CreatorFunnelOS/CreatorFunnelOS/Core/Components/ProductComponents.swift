import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? AppTheme.brand : AppTheme.card)
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(isSelected ? .clear : AppTheme.border, lineWidth: 1)
            }
    }
}

struct GhostButton: View {
    let title: String
    var systemImage: String?
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? AppTheme.danger : AppTheme.textSecondary)
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    var tint: Color = AppTheme.brand

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)

            Text(detail)
                .font(.caption2.weight(.medium))
                .foregroundStyle(detail.hasPrefix("+") ? AppTheme.success : AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(padding: 14)
    }
}

struct AnalyticsTrendCard: View {
    let title: String
    let subtitle: String
    let points: [AnalyticsTrendPoint]
    var tint: Color = AppTheme.brand

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            GeometryReader { geometry in
                let values = points.map(\.value)
                let minimum = values.min() ?? 0
                let maximum = values.max() ?? 1
                let range = max(1, maximum - minimum)

                ZStack(alignment: .bottom) {
                    Path { path in
                        guard points.count > 1 else { return }
                        for index in points.indices {
                            let x = geometry.size.width * CGFloat(index) / CGFloat(points.count - 1)
                            let normalized = (points[index].value - minimum) / range
                            let y = geometry.size.height * (1 - CGFloat(normalized))
                            if index == points.startIndex {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    LinearGradient(
                        colors: [tint.opacity(0.22), tint.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .mask {
                        Path { path in
                            guard points.count > 1 else { return }
                            path.move(to: CGPoint(x: 0, y: geometry.size.height))
                            for index in points.indices {
                                let x = geometry.size.width * CGFloat(index) / CGFloat(points.count - 1)
                                let normalized = (points[index].value - minimum) / range
                                let y = geometry.size.height * (1 - CGFloat(normalized))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                            path.closeSubpath()
                        }
                    }
                }
            }
            .frame(height: 92)

            HStack {
                Text(points.first?.date.formatted(.dateTime.month(.abbreviated).day()) ?? "—")
                Spacer()
                Text(points.last?.date.formatted(.dateTime.month(.abbreviated).day()) ?? "—")
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(recommendation.summary)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: 8)

                StatusPill(
                    title: recommendation.status.rawValue.capitalized,
                    color: recommendation.status == .applied ? AppTheme.success : AppTheme.brand
                )
            }

            HStack {
                Label(recommendation.projectedBenefit, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.success)
                Spacer()
            }

            HStack(spacing: 10) {
                Button(recommendation.actionLabel, action: onOpen)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                Button("Dismiss", action: onDismiss)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .appCard()
    }

    private var icon: String {
        switch recommendation.type {
        case .reuseTemplate: "doc.on.doc"
        case .pauseFunnel: "pause.circle"
        case .shortenCTA: "text.badge.minus"
        case .reconnectPermissions: "arrow.triangle.2.circlepath"
        case .upgradePlan: "sparkles"
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let cadence: String
    let detail: String
    var badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppTheme.brand : AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            StatusPill(title: badge, color: AppTheme.success)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.headline)
                    Text(cadence)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
            .padding(16)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? AppTheme.brand : AppTheme.border, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FeatureAvailabilityCard: View {
    let icon: String
    let title: String
    let message: String
    var badge = "Coming soon"

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 40, height: 40)
                .background(AppTheme.brand.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    StatusPill(title: badge, color: AppTheme.textSecondary)
                }
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .appCard()
    }
}
