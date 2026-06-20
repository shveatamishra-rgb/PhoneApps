import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: StoreManager
    @State private var selectedProductID = StoreManager.yearlyID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image("BrandMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .padding(.top, 4)

                    VStack(spacing: 8) {
                        Text("Divine Stillness Pro")
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.plum)
                        Text("A deeper daily practice, with the complete sacred collection.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.muted)
                    }

                    VStack(spacing: 14) {
                        feature("photo.stack.fill", "All 60 darshan images")
                        feature("arrow.down.to.line", "Unlimited wallpaper saves")
                        feature("circle.grid.3x3.fill", "All deity mantras for japa")
                        feature("bell.badge.fill", "Custom daily reminders")
                        feature("sparkles", "New festival collections")
                    }
                    .padding(18)
                    .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))

                    productOptions

                    purchaseButton

                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.vermilion)

                    disclosure

                    legalLinks
                }
                .padding(20)
            }
            .devotionalBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert(
                "App Store",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    // MARK: - Purchase

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    private var ctaTitle: String {
        if let product = selectedProduct, store.hasFreeTrial(product) {
            return "Start Free Trial"
        }
        if store.products.isEmpty, selectedProductID == StoreManager.yearlyID {
            return "Start Free Trial"
        }
        if selectedProductID == StoreManager.lifetimeID {
            return "Unlock Lifetime"
        }
        return "Continue"
    }

    private var purchaseButton: some View {
        Button {
            Task {
                guard let product = store.products.first(where: {
                    $0.id == selectedProductID
                }) else {
                    store.errorMessage = "Products are not available yet. Please try again in a moment."
                    return
                }
                if await store.purchase(product) {
                    dismiss()
                }
            }
        } label: {
            Group {
                if store.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaTitle)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(AppTheme.plum, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(store.isLoading)
    }

    // MARK: - Product options

    private var productOptions: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                fallbackOption(
                    id: StoreManager.yearlyID,
                    title: "Annual",
                    price: "$29.99/yr",
                    detail: "7-day free trial, then about $2.50/mo",
                    badge: "BEST VALUE"
                )
                fallbackOption(
                    id: StoreManager.monthlyID,
                    title: "Monthly",
                    price: "$4.99/mo",
                    detail: "Cancel anytime",
                    badge: nil
                )
                fallbackOption(
                    id: StoreManager.lifetimeID,
                    title: "Lifetime",
                    price: "$39.99",
                    detail: "One-time purchase, no subscription",
                    badge: nil
                )
            } else {
                ForEach(store.products, id: \.id) { product in
                    productOption(product)
                }
            }
        }
    }

    private func productOption(_ product: Product) -> some View {
        Button {
            selectedProductID = product.id
        } label: {
            optionContent(
                id: product.id,
                title: title(for: product),
                price: price(for: product),
                detail: detail(for: product),
                badge: product.id == StoreManager.yearlyID ? "BEST VALUE" : nil
            )
        }
        .buttonStyle(.plain)
    }

    private func title(for product: Product) -> String {
        switch product.id {
        case StoreManager.yearlyID: return "Annual"
        case StoreManager.monthlyID: return "Monthly"
        case StoreManager.lifetimeID: return "Lifetime"
        default: return product.displayName
        }
    }

    private func price(for product: Product) -> String {
        switch product.id {
        case StoreManager.yearlyID: return "\(product.displayPrice)/yr"
        case StoreManager.monthlyID: return "\(product.displayPrice)/mo"
        default: return product.displayPrice
        }
    }

    private func detail(for product: Product) -> String {
        if let trial = store.freeTrialText(for: product) {
            var parts = [trial.prefix(1).uppercased() + trial.dropFirst()]
            if let perMonth = store.monthlyEquivalentText(for: product) {
                parts.append("then \(perMonth)")
            }
            if let percent = store.annualSavingsPercent {
                parts.append("save \(percent)%")
            }
            return parts.joined(separator: " · ")
        }
        switch product.id {
        case StoreManager.yearlyID:
            if let perMonth = store.monthlyEquivalentText(for: product) {
                return "Just \(perMonth)"
            }
            return "Best annual value"
        case StoreManager.lifetimeID:
            return "One-time purchase, no subscription"
        default:
            return "Cancel anytime"
        }
    }

    private func fallbackOption(
        id: String,
        title: String,
        price: String,
        detail: String,
        badge: String?
    ) -> some View {
        Button {
            selectedProductID = id
        } label: {
            optionContent(id: id, title: title, price: price, detail: detail, badge: badge)
        }
        .buttonStyle(.plain)
    }

    private func optionContent(
        id: String,
        title: String,
        price: String,
        detail: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedProductID == id
        return HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? AppTheme.vermilion : AppTheme.muted)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title).font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.black))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppTheme.marigold, in: Capsule())
                    }
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Text(price)
                .font(.headline)
        }
        .foregroundStyle(AppTheme.ink)
        .padding(15)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? AppTheme.vermilion : Color.black.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        }
    }

    // MARK: - Legal

    private var disclosure: some View {
        Text("Subscriptions are billed through your Apple account and renew automatically unless cancelled at least 24 hours before the end of the current period. A free trial, if offered, converts to a paid subscription at the listed price unless cancelled before it ends. Manage or cancel anytime in Settings. Lifetime is a one-time purchase.")
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(AppTheme.muted)
    }

    private var legalLinks: some View {
        HStack(spacing: 6) {
            NavigationLink {
                LegalTextView(title: "Terms of Use", content: LegalCopy.terms)
            } label: {
                Text("Terms of Use")
            }
            Text("·").foregroundStyle(AppTheme.muted)
            NavigationLink {
                LegalTextView(title: "Privacy Policy", content: LegalCopy.privacy)
            } label: {
                Text("Privacy Policy")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.vermilion)
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.vermilion)
                .frame(width: 26)
            Text(text)
                .font(.body.weight(.medium))
            Spacer()
        }
        .foregroundStyle(AppTheme.ink)
    }
}
