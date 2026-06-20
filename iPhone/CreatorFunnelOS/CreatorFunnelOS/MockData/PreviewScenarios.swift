import Foundation

// Reusable state fixtures for SwiftUI previews, UI tests, and product review.
// They make loading/empty/disconnected/expired/trial behavior intentional.
enum PreviewScenarios {
    static let populatedWorkspace = SampleData.workspace

    static var emptyWorkspace: WorkspaceSnapshot {
        .empty
    }

    static var disconnectedWorkspace: WorkspaceSnapshot {
        var snapshot = SampleData.workspace
        snapshot.account?.isConnected = false
        return snapshot
    }

    static let trialSubscription = Subscription(
        id: UUID(),
        tier: .pro,
        status: .trial,
        renewalDate: Calendar.current.date(byAdding: .day, value: 7, to: .now),
        billingPeriod: .monthly,
        isTrial: true,
        canRestore: true
    )

    static let expiredSubscription = Subscription(
        id: UUID(),
        tier: .pro,
        status: .expired,
        renewalDate: Date().addingTimeInterval(-86_400),
        billingPeriod: .yearly,
        isTrial: false,
        canRestore: true
    )

    static let unavailableFeatureMessage =
        "This feature is unavailable for the current plan or connected-account permissions."

    static let sampleErrorMessage =
        "The workspace could not refresh. Your existing local data is still available."
}
