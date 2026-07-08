import StoreKit
import SwiftUI

/// GigaBack Pro paywall.
///
/// Guideline 3.1.2 requirements are enforced here by layout, not by copy alone:
/// price and length are the most prominent text after the title, the trial terms
/// are spelled out on the purchase button, and Terms/Privacy/Restore are always
/// visible without scrolling behind the plans.
struct PaywallView: View {
    @ObservedObject private var store = GigaBackStore.shared
    @Environment(\.dismiss) private var dismiss

    /// Real reclaimable bytes from the last scan; 0 hides the line (never fake it).
    let reclaimableBytes: Int64

    @State private var selectedProductID = GigaBackStore.ProductID.annual
    @State private var trialAvailable = false
    @State private var isPurchasing = false

    private static let termsURL = URL(string: "https://shveatamishra-rgb.github.io/gigaback/terms.html")!
    private static let privacyURL = URL(string: "https://shveatamishra-rgb.github.io/gigaback/privacy.html")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    planPicker
                    purchaseButton
                    footerLinks
                }
                .padding()
            }
            .navigationTitle("GigaBack Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if store.products.isEmpty { await store.loadProducts() }
                trialAvailable = await store.isTrialAvailable()
            }
            .onChange(of: store.isPro) { _, nowPro in
                if nowPro { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            if reclaimableBytes > 0 {
                Text("Clean \(ByteCountFormatter.string(fromByteCount: reclaimableBytes, countStyle: .file)) in one tap")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            } else {
                Text("Clean your whole library in one tap")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("wand.and.stars", "Smart Clean: clear every category at once")
            featureRow("photo.on.rectangle.angled", "Similar and burst photo cleanup")
            featureRow("camera.metering.none", "Blurry photo detection")
            featureRow("video", "Large video tools")
            featureRow("hand.draw", "Swipe cleanup in every album")
            featureRow("arrow.uturn.backward.circle", "Everything stays recoverable for 30 days")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureRow(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
        }
        .font(.subheadline)
    }

    private var planPicker: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                if store.isLoadingProducts {
                    ProgressView("Loading plans")
                        .padding(.vertical, 24)
                } else {
                    #if DEBUG
                    // Sim/dev builds without a StoreKit configuration cannot load
                    // live products; render the configured plans so the paywall can
                    // be reviewed and staged. Release builds never take this path.
                    ForEach(Self.previewPlans) { plan in
                        planRow(plan)
                    }
                    #else
                    VStack(spacing: 8) {
                        Text(store.lastError ?? "Purchase options are unavailable right now.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task { await store.loadProducts() }
                        }
                    }
                    .padding(.vertical, 12)
                    #endif
                }
            } else {
                ForEach(store.products, id: \.id) { product in
                    planRow(rowModel(for: product))
                }
            }
        }
    }

    private struct PlanRowModel: Identifiable {
        let id: String
        let title: String
        let detail: String
        let price: String
        let badge: String?
    }

    #if DEBUG
    /// Mirrors the App Store Connect configuration (GigaBack.storekit).
    private static let previewPlans = [
        PlanRowModel(
            id: GigaBackStore.ProductID.annual,
            title: "Annual",
            detail: "Auto-renews yearly until cancelled",
            price: "$29.99/year",
            badge: "BEST VALUE"
        ),
        PlanRowModel(
            id: GigaBackStore.ProductID.weekly,
            title: "Weekly",
            detail: "3 days free, then auto-renews weekly",
            price: "$4.99/week",
            badge: "FREE TRIAL"
        ),
        PlanRowModel(
            id: GigaBackStore.ProductID.lifetime,
            title: "Lifetime",
            detail: "One-time purchase, yours forever",
            price: "$49.99",
            badge: nil
        ),
    ]
    #endif

    private func rowModel(for product: Product) -> PlanRowModel {
        PlanRowModel(
            id: product.id,
            title: planTitle(product),
            detail: planDetail(product),
            price: planPrice(product),
            badge: planBadge(product)
        )
    }

    private func planRow(_ plan: PlanRowModel) -> some View {
        let selected = plan.id == selectedProductID
        return Button {
            selectedProductID = plan.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.headline)
                    Text(plan.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // 3.1.2: price + length, prominent.
                Text(plan.price)
                    .font(.headline)
                if let badge = plan.badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.3),
                            lineWidth: selected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func planTitle(_ product: Product) -> String {
        switch product.id {
        case GigaBackStore.ProductID.weekly: return "Weekly"
        case GigaBackStore.ProductID.annual: return "Annual"
        case GigaBackStore.ProductID.lifetime: return "Lifetime"
        default: return product.displayName
        }
    }

    private func planDetail(_ product: Product) -> String {
        switch product.id {
        case GigaBackStore.ProductID.weekly:
            return trialAvailable
                ? "3 days free, then auto-renews weekly"
                : "Auto-renews weekly until cancelled"
        case GigaBackStore.ProductID.annual:
            return "Auto-renews yearly until cancelled"
        case GigaBackStore.ProductID.lifetime:
            return "One-time purchase, yours forever"
        default:
            return product.description
        }
    }

    private func planPrice(_ product: Product) -> String {
        switch product.id {
        case GigaBackStore.ProductID.weekly: return "\(product.displayPrice)/week"
        case GigaBackStore.ProductID.annual: return "\(product.displayPrice)/year"
        default: return product.displayPrice
        }
    }

    private func planBadge(_ product: Product) -> String? {
        switch product.id {
        case GigaBackStore.ProductID.annual: return "BEST VALUE"
        case GigaBackStore.ProductID.weekly: return trialAvailable ? "FREE TRIAL" : nil
        default: return nil
        }
    }

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
                isPurchasing = true
                Task {
                    await store.purchase(product)
                    isPurchasing = false
                }
            } label: {
                Text(purchaseButtonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing || (store.products.isEmpty && !Self.showsPreviewPlans))

            if let error = store.lastError, !store.products.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    #if DEBUG
    private static let showsPreviewPlans = true
    #else
    private static let showsPreviewPlans = false
    #endif

    // 3.1.2: full billing terms on the button itself.
    private var purchaseButtonTitle: String {
        if let product = store.products.first(where: { $0.id == selectedProductID }) {
            switch product.id {
            case GigaBackStore.ProductID.weekly:
                return trialAvailable
                    ? "Start 3-Day Free Trial, then \(product.displayPrice)/week"
                    : "Subscribe for \(product.displayPrice)/week"
            case GigaBackStore.ProductID.annual:
                return "Subscribe for \(product.displayPrice)/year"
            default:
                return "Buy Lifetime for \(product.displayPrice)"
            }
        }
        #if DEBUG
        switch selectedProductID {
        case GigaBackStore.ProductID.weekly:
            return "Start 3-Day Free Trial, then $4.99/week"
        case GigaBackStore.ProductID.annual:
            return "Subscribe for $29.99/year"
        case GigaBackStore.ProductID.lifetime:
            return "Buy Lifetime for $49.99"
        default:
            break
        }
        #endif
        return "Continue"
    }

    private var footerLinks: some View {
        VStack(spacing: 10) {
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.footnote)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: Self.termsURL)
                Link("Privacy Policy", destination: Self.privacyURL)
            }
            .font(.footnote)

            Text("Subscriptions auto-renew until cancelled in Settings. Cancel anytime.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
