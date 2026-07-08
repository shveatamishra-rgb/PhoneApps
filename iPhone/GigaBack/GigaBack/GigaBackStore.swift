import Foundation
import StoreKit

/// StoreKit 2 storefront for GigaBack Pro.
///
/// Products (must match App Store Connect / GigaBack.storekit):
/// - weekly auto-renewing subscription with a 3-day free trial
/// - annual auto-renewing subscription (the tier the paywall pushes)
/// - lifetime non-consumable (high anchor, also defuses subscription-trap complaints)
@MainActor
final class GigaBackStore: ObservableObject {
    static let shared = GigaBackStore()

    enum ProductID {
        static let weekly = "com.shveatamishra.gigaback.pro.weekly"
        static let annual = "com.shveatamishra.gigaback.pro.annual"
        static let lifetime = "com.shveatamishra.gigaback.pro.lifetime"
        static let all: Set<String> = [weekly, annual, lifetime]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false
    @Published var lastError: String?

    #if DEBUG
    /// Debug builds run as Pro so the full cleanup flow can be tested on device
    /// before the IAPs exist in App Store Connect. Set to false to exercise the
    /// paywall and purchase flow instead. Release builds ignore this entirely.
    static let debugForcePro = true
    #endif

    var isPro: Bool {
        #if DEBUG
        if Self.debugForcePro { return true }
        #endif
        return !purchasedProductIDs.isEmpty
    }

    var weekly: Product? { product(ProductID.weekly) }
    var annual: Product? { product(ProductID.annual) }
    var lifetime: Product? { product(ProductID.lifetime) }

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.verified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    private func product(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: ProductID.all)
            // Stable display order: annual (pushed), weekly, lifetime.
            let order = [ProductID.annual, ProductID.weekly, ProductID.lifetime]
            products = loaded.sorted {
                (order.firstIndex(of: $0.id) ?? .max) < (order.firstIndex(of: $1.id) ?? .max)
            }
        } catch {
            lastError = "Could not load purchase options. Check your connection and try again."
        }
    }

    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? verified(entitlement) else { continue }
            if transaction.revocationDate == nil, ProductID.all.contains(transaction.productID) {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
    }

    /// Returns true when the purchase ends in an active entitlement.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return isPro
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = "Purchase failed. You have not been charged."
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            // Sync failing (e.g. user cancelled sign-in) still allows a local refresh.
        }
        await refreshEntitlements()
        if !isPro {
            lastError = "No previous purchases found for this Apple Account."
        }
    }

    /// True when this user can still claim the weekly plan's 3-day free trial.
    func isTrialAvailable() async -> Bool {
        guard let weekly, let subscription = weekly.subscription,
              subscription.introductoryOffer != nil else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreKitError.notEntitled
        }
    }
}
