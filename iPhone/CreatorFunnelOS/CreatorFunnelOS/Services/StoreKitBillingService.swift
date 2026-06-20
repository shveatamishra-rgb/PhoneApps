import Foundation
import StoreKit

private struct StoreTransactionRequest: Encodable {
    let transactionId: String
    let originalTransactionId: String
    let productId: String
}

actor StoreKitBillingService: BillingService {
    private let configuration: AppConfiguration
    private let client: APIClient

    init(configuration: AppConfiguration, client: APIClient) {
        self.configuration = configuration
        self.client = client
    }

    func availableProducts() async throws -> [BillingProduct] {
        try await Product.products(for: configuration.productIDs)
            .map { product in
                BillingProduct(
                    id: product.id,
                    period: product.id == configuration.yearlyProductID ? .yearly : .monthly,
                    displayPrice: product.displayPrice,
                    displayName: product.displayName
                )
            }
            .sorted { $0.period == .monthly && $1.period == .yearly }
    }

    func currentSubscription(workspaceId: UUID) async -> Subscription {
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  configuration.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            return subscription(from: transaction)
        }
        return freeSubscription
    }

    func purchase(tier: PlanTier, period: BillingPeriod) async throws -> Subscription {
        let productID = period == .yearly
            ? configuration.yearlyProductID
            : configuration.monthlyProductID
        guard let product = try await Product.products(for: [productID]).first else {
            throw ServiceError.configuration(
                "This subscription product is not available in App Store Connect yet."
            )
        }

        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw ServiceError.validation("The App Store transaction could not be verified.")
            }
            await sync(transaction)
            await transaction.finish()
            return subscription(from: transaction)
        case .pending:
            throw ServiceError.validation("The purchase is pending approval.")
        case .userCancelled:
            throw CancellationError()
        @unknown default:
            throw ServiceError.unavailable
        }
    }

    func restorePurchases() async throws -> Subscription {
        try await AppStore.sync()
        return await currentSubscription(workspaceId: SampleData.workspaceId)
    }

    func manageSubscriptionURL() async -> URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    private func sync(_ transaction: Transaction) async {
        try? await client.sendWithoutResponse(
            "/v1/billing/transactions",
            method: "POST",
            body: StoreTransactionRequest(
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                productId: transaction.productID
            )
        )
    }

    private func subscription(from transaction: Transaction) -> Subscription {
        Subscription(
            id: UUID(),
            tier: .pro,
            status: .active,
            renewalDate: transaction.expirationDate,
            billingPeriod: transaction.productID == configuration.yearlyProductID ? .yearly : .monthly,
            isTrial: false,
            canRestore: true
        )
    }

    private var freeSubscription: Subscription {
        Subscription(
            id: UUID(),
            tier: .free,
            status: .active,
            renewalDate: nil,
            billingPeriod: .none,
            isTrial: false,
            canRestore: true
        )
    }
}
