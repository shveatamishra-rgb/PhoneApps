import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    static let monthlyID = "in.bhaktiangan.app.pro.monthly2"  // .pro.monthly was burned in ASC (created + deleted; Apple reserves IDs permanently)
    static let yearlyID = "in.bhaktiangan.app.pro.yearly"
    static let lifetimeID = "in.bhaktiangan.app.pro.lifetime"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var debugProEnabled = false

    private var updateTask: Task<Void, Never>?
    private let productIDs = [monthlyID, yearlyID, lifetimeID]

    var hasPro: Bool {
        !purchasedProductIDs.isDisjoint(with: productIDs)
            || debugProEnabled
            || ProcessInfo.processInfo.arguments.contains("--pro-mode")
    }

    var annualProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }

    /// "7-day free trial" style copy when a product offers an introductory
    /// free trial, otherwise `nil`.
    func freeTrialText(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let period = offer.period
        let value: Int
        let unit: String
        switch period.unit {
        case .day: value = period.value; unit = "day"
        case .week: value = period.value * 7; unit = "day"
        case .month: value = period.value; unit = "month"
        case .year: value = period.value; unit = "year"
        @unknown default: value = period.value; unit = "day"
        }
        return "\(value)-\(unit) free trial"
    }

    func hasFreeTrial(_ product: Product) -> Bool {
        freeTrialText(for: product) != nil
    }

    /// The free-trial length in whole days, for building localized trial copy in
    /// the view (e.g. "7-day free trial" / "7-दिन का निःशुल्क परीक्षण").
    func freeTrialDays(for product: Product) -> Int? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let period = offer.period
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return period.value
        }
    }

    /// The annual price expressed per month, e.g. "$2.50/mo".
    func monthlyEquivalentText(for product: Product) -> String? {
        guard product.id == Self.yearlyID else { return nil }
        let perMonth = product.price / 12
        return "\(perMonth.formatted(product.priceFormatStyle))/mo"
    }

    /// Percentage the annual plan saves versus paying monthly for a year.
    var annualSavingsPercent: Int? {
        guard let annual = annualProduct?.price,
              let monthly = monthlyProduct?.price,
              monthly > 0 else { return nil }
        let fullYear = monthly * 12
        let saved = (fullYear - annual) / fullYear
        let percent = (saved as NSDecimalNumber).doubleValue * 100
        guard percent > 0 else { return nil }
        return Int(percent.rounded())
    }

    deinit {
        updateTask?.cancel()
    }

    func start() async {
        updateTask = observeTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: productIDs)
                .sorted { rank($0.id) < rank($1.id) }
        } catch {
            errorMessage = "Store products are unavailable. Please try again later."
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                return true
            case .pending:
                errorMessage = "Your purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "The purchase could not be completed."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Purchases could not be restored."
        }
    }

    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.revocationDate == nil else { continue }
            active.insert(transaction.productID)
        }
        purchasedProductIDs = active
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      let transaction = try? self.verified(result) else { continue }
                self.purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    private func rank(_ id: String) -> Int {
        switch id {
        case Self.yearlyID: return 0
        case Self.monthlyID: return 1
        default: return 2
        }
    }
}

private enum StoreError: Error {
    case failedVerification
}
