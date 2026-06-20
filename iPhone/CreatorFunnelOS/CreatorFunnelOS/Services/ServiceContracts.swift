import Foundation

// MARK: - Platform-neutral service contracts
//
// These protocols are intentionally free of SwiftUI types. A production iOS
// client, Android client, web admin, or backend test harness can implement the
// same operations and analytics event names.

struct AuthSession: Codable, Hashable, Sendable {
    var user: User
    var accessToken: String
    var refreshToken: String?
    var isEmailVerified: Bool

    init(user: User, accessToken: String, refreshToken: String? = nil, isEmailVerified: Bool) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.isEmailVerified = isEmailVerified
    }
}

struct PolicyDocument: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var title: String
    var body: String
    var updatedAt: Date
    var publicURL: URL?
}

enum ExportFormat: String, Codable, Sendable {
    case csv
    case json
}

struct ExportRequest: Codable, Hashable, Sendable {
    var workspaceId: UUID
    var format: ExportFormat
    var includeNotes: Bool
}

struct ExportResult: Codable, Hashable, Sendable {
    var downloadURL: URL?
    var rowCount: Int
    var expiresAt: Date?
    var isPlaceholder: Bool
}

struct BillingProduct: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let period: BillingPeriod
    let displayPrice: String
    let displayName: String
}

enum ServiceError: LocalizedError, Sendable {
    case invalidCredentials
    case emailNotVerified
    case unavailable
    case validation(String)
    case permissionDenied
    case notAuthenticated
    case configuration(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "The email or password was not accepted."
        case .emailNotVerified:
            "Verify your email before continuing."
        case .unavailable:
            "This feature is not available yet."
        case .validation(let message):
            message
        case .permissionDenied:
            "Your current role does not have permission for this action."
        case .notAuthenticated:
            "Your session expired. Please sign in again."
        case .configuration(let message):
            message
        }
    }
}

protocol AuthService: Sendable {
    func restoreSession() async -> AuthSession?
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(fullName: String, email: String, password: String) async throws -> AuthSession
    func sendPasswordReset(email: String) async throws
    func resendVerificationEmail() async throws
    func signOut() async
}

protocol WorkspaceService: Sendable {
    func fetchCurrentWorkspace() async throws -> Workspace
    func fetchWorkspaceSnapshot() async throws -> WorkspaceSnapshot
    func fetchAvailableWorkspaces() async throws -> [Workspace]
    func fetchMemberships(workspaceId: UUID) async throws -> [Membership]
}

protocol SocialAccountService: Sendable {
    func fetchConnectedAccounts(workspaceId: UUID) async throws -> [SocialAccount]
    func instagramAuthorizationURL(workspaceId: UUID) async throws -> URL
    func completeInstagramConnection(workspaceId: UUID) async throws -> SocialAccount
    func connectInstagram(handle: String) async throws -> SocialAccount
    func disconnect(accountId: UUID) async throws
    func refreshPermissions(accountId: UUID) async throws -> SocialAccount
    func fetchPosts(accountId: UUID) async throws -> [SocialPost]
}

protocol PlannerService: Sendable {
    func fetchIdeas(workspaceId: UUID) async throws -> [ContentIdea]
    func fetchDrafts(workspaceId: UUID) async throws -> [ContentDraft]
    func fetchTemplates() async throws -> [ContentTemplate]
    func saveIdea(_ idea: ContentIdea) async throws -> ContentIdea
    func saveDraft(_ draft: ContentDraft) async throws -> ContentDraft
}

protocol FunnelService: Sendable {
    func fetchFunnels(workspaceId: UUID) async throws -> [Funnel]
    func saveFunnel(_ funnel: Funnel) async throws -> Funnel
    func updateStatus(funnelId: UUID, status: FunnelStatus) async throws -> Funnel
    func assignPosts(funnelId: UUID, postIds: [UUID]) async throws -> Funnel
}

protocol LeadService: Sendable {
    func fetchLeads(workspaceId: UUID) async throws -> [LeadContact]
    func fetchEvents(leadId: UUID) async throws -> [LeadEvent]
    func addTag(leadId: UUID, tag: LeadTag) async throws
    func saveNote(_ note: LeadNote) async throws -> LeadNote
    func requestExport(_ request: ExportRequest) async throws -> ExportResult
}

protocol AnalyticsService: Sendable {
    func fetchSnapshot(workspaceId: UUID) async throws -> AnalyticsSnapshot
    func track(_ event: AnalyticsEvent) async
}

protocol RecommendationService: Sendable {
    func fetchRecommendations(workspaceId: UUID) async throws -> [Recommendation]
    func fetchProposal(recommendationId: UUID) async throws -> Proposal
    func updateRecommendation(id: UUID, status: RecommendationStatus) async throws -> Recommendation
    func applyProposal(id: UUID) async throws -> Proposal
}

protocol BillingService: Sendable {
    func availableProducts() async throws -> [BillingProduct]
    func currentSubscription(workspaceId: UUID) async -> Subscription
    func purchase(tier: PlanTier, period: BillingPeriod) async throws -> Subscription
    func restorePurchases() async throws -> Subscription
    func manageSubscriptionURL() async -> URL?
}

protocol NotificationService: Sendable {
    func fetchPreferences(userId: UUID) async throws -> NotificationPreference
    func savePreferences(_ preference: NotificationPreference) async throws -> NotificationPreference
}

protocol PolicyService: Sendable {
    func privacyPolicy() async throws -> PolicyDocument
    func termsOfService() async throws -> PolicyDocument
    func subscriptionTerms() async throws -> PolicyDocument
    func connectedAccountPermissions() async throws -> PolicyDocument
}

protocol AccountService: Sendable {
    func requestReauthentication(password: String) async throws
    func requestDeletion(userId: UUID) async throws -> AccountDeletionRequest
    func deletionStatus(userId: UUID) async throws -> AccountDeletionRequest?
}

protocol FeatureFlagService: Sendable {
    func fetchFlags(workspaceId: UUID) async throws -> [FeatureFlag]
    func isEnabled(_ key: String, workspaceId: UUID) async -> Bool
}

struct ServiceContainer: Sendable {
    let auth: any AuthService
    let workspaces: any WorkspaceService
    let socialAccounts: any SocialAccountService
    let planner: any PlannerService
    let funnels: any FunnelService
    let leads: any LeadService
    let analytics: any AnalyticsService
    let recommendations: any RecommendationService
    let billing: any BillingService
    let notifications: any NotificationService
    let policies: any PolicyService
    let account: any AccountService
    let featureFlags: any FeatureFlagService

    static func mock() -> ServiceContainer {
        let repository = MockPlatformRepository()
        return ServiceContainer(
            auth: repository,
            workspaces: repository,
            socialAccounts: repository,
            planner: repository,
            funnels: repository,
            leads: repository,
            analytics: repository,
            recommendations: repository,
            billing: repository,
            notifications: repository,
            policies: repository,
            account: repository,
            featureFlags: repository
        )
    }

    static func production(configuration: AppConfiguration = .current) -> ServiceContainer {
        let sessionStore = KeychainSessionStore()
        let client = APIClient(configuration: configuration, sessionStore: sessionStore)
        let repository = RemotePlatformRepository(
            client: client,
            configuration: configuration,
            sessionStore: sessionStore
        )
        let billing = StoreKitBillingService(
            configuration: configuration,
            client: client
        )
        return ServiceContainer(
            auth: repository,
            workspaces: repository,
            socialAccounts: repository,
            planner: repository,
            funnels: repository,
            leads: repository,
            analytics: repository,
            recommendations: repository,
            billing: billing,
            notifications: repository,
            policies: repository,
            account: repository,
            featureFlags: repository
        )
    }
}
