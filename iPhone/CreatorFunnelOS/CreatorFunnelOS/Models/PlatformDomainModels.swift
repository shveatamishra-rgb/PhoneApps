import Foundation

// MARK: - Shared domain
//
// These Codable, UI-agnostic entities define the contract expected from a
// future backend. Android should mirror these fields and raw enum values.
// SwiftUI-specific state and formatting remain in Features/ and Core/.

struct User: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var fullName: String
    var email: String
    var avatarURL: URL?
    var createdAt: Date
}

enum PlanTier: String, Codable, CaseIterable, Sendable {
    case free
    case pro
    case team

    var title: String {
        switch self {
        case .free: "Free"
        case .pro: "Creator Pro"
        case .team: "Team"
        }
    }
}

struct Workspace: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var planTier: PlanTier
    var createdAt: Date
}

enum MembershipRole: String, Codable, CaseIterable, Sendable {
    case owner
    case admin
    case editor
    case viewer
}

struct Membership: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var workspaceId: UUID
    var role: MembershipRole
    var joinedAt: Date
}

enum SocialPlatform: String, Codable, CaseIterable, Sendable {
    case instagram
}

enum SocialAccountType: String, Codable, CaseIterable, Sendable {
    case creator
    case business
}

struct SocialAccount: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var platform: SocialPlatform
    var handle: String
    var accountType: SocialAccountType
    var isConnected: Bool
    var lastSyncAt: Date?
}

enum SocialPostStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case scheduled
    case published
    case archived
}

struct SocialPost: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var accountId: UUID
    var platformPostId: String?
    var title: String
    var publishedAt: Date?
    var status: SocialPostStatus
}

enum ContentFormat: String, Codable, CaseIterable, Sendable {
    case reel
    case carousel
    case story
    case live
    case staticPost = "static_post"
}

struct ContentIdea: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var title: String
    var summary: String
    var format: ContentFormat
    var tags: [String]
    var createdAt: Date
    var isSaved: Bool
}

enum ContentDraftStatus: String, Codable, CaseIterable, Sendable {
    case idea
    case drafting
    case ready
    case scheduled
    case published
}

struct ContentDraft: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var ideaId: UUID?
    var title: String
    var hook: String
    var caption: String
    var format: ContentFormat
    var status: ContentDraftStatus
    var scheduledAt: Date?
    var postNotes: String
    var createdAt: Date
    var updatedAt: Date
}

struct ContentTemplate: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var category: String
    var description: String
    var prompt: String
    var format: ContentFormat
    var isPro: Bool
}

enum FunnelStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case paused

    var title: String { rawValue.capitalized }
}

enum FunnelTriggerType: String, Codable, Sendable {
    case commentKeyword = "comment_keyword"
}

struct FunnelTrigger: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var funnelId: UUID
    var type: FunnelTriggerType
    var keyword: String
    var isCaseSensitive: Bool
}

enum FunnelMessageKind: String, Codable, Sendable {
    case publicReply = "public_reply"
    case directMessage = "direct_message"
}

struct FunnelMessageTemplate: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var funnelId: UUID
    var kind: FunnelMessageKind
    var body: String
}

struct FunnelAssignment: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var funnelId: UUID
    var postId: UUID
    var assignedAt: Date
}

struct LeadTag: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var colorToken: String
}

struct LeadNote: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var leadId: UUID
    var authorUserId: UUID
    var body: String
    var createdAt: Date
}

enum LeadEventType: String, Codable, Sendable {
    case firstSeen = "first_seen"
    case keywordTriggered = "keyword_triggered"
    case dmSent = "dm_sent"
    case linkClicked = "link_clicked"
    case detailsShared = "details_shared"
    case tagged
    case noteAdded = "note_added"
}

struct LeadEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var leadId: UUID
    var type: LeadEventType
    var detail: String
    var occurredAt: Date
}

struct AnalyticsTrendPoint: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var date: Date
    var value: Double
}

struct AnalyticsSnapshot: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var periodStart: Date
    var periodEnd: Date
    var activeFunnelCount: Int
    var triggerVolume: Int
    var successfulDMs: Int
    var dmSuccessRate: Double
    var linkClickThroughRate: Double
    var leadConversionRate: Double
    var leadsCaptured: Int
    var bestPerformingFunnelId: UUID?
    var bestPerformingPostId: UUID?
    var sevenDayTrend: [AnalyticsTrendPoint]
    var thirtyDayTrend: [AnalyticsTrendPoint]
}

enum RecommendationType: String, Codable, Sendable {
    case reuseTemplate = "reuse_template"
    case pauseFunnel = "pause_funnel"
    case shortenCTA = "shorten_cta"
    case reconnectPermissions = "reconnect_permissions"
    case upgradePlan = "upgrade_plan"
}

enum RecommendationStatus: String, Codable, CaseIterable, Sendable {
    case new
    case viewed
    case applied
    case dismissed
}

struct Recommendation: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var type: RecommendationType
    var title: String
    var summary: String
    var rationale: String
    var projectedBenefit: String
    var actionLabel: String
    var status: RecommendationStatus
    var createdAt: Date
}

enum ProposalState: String, Codable, Sendable {
    case preview
    case applied
    case dismissed
}

struct Proposal: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var recommendationId: UUID
    var title: String
    var overview: String
    var expectedImpact: String
    var suggestedSteps: [String]
    var ctaPrimary: String
    var ctaSecondary: String
    var state: ProposalState
}

enum SubscriptionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case trial
    case expired
    case canceled
}

enum BillingPeriod: String, Codable, CaseIterable, Sendable {
    case monthly
    case yearly
    case none
}

struct Subscription: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var tier: PlanTier
    var status: SubscriptionStatus
    var renewalDate: Date?
    var billingPeriod: BillingPeriod
    var isTrial: Bool
    var canRestore: Bool

    var displayTitle: String {
        if status == .trial { return "\(tier.title) trial" }
        if status == .expired { return "Expired \(tier.title)" }
        return tier.title
    }

    var hasProAccess: Bool {
        tier != .free && (status == .active || status == .trial)
    }
}

struct NotificationPreference: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var activityAlerts: Bool
    var weeklyDigest: Bool
    var recommendationAlerts: Bool
}

struct AuditLog: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var actorUserId: UUID?
    var action: String
    var entityType: String
    var entityId: UUID?
    var metadata: [String: String]
    var createdAt: Date
}

struct FeatureFlag: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var key: String
    var isEnabled: Bool
    var rolloutPercentage: Int
    var variant: String?
}

enum AnalyticsEventName: String, Codable, CaseIterable, Sendable {
    case accountConnected = "account_connected"
    case accountDisconnected = "account_disconnected"
    case postAssignedToFunnel = "post_assigned_to_funnel"
    case funnelCreated = "funnel_created"
    case funnelActivated = "funnel_activated"
    case funnelPaused = "funnel_paused"
    case commentTriggered = "comment_triggered"
    case dmAttempted = "dm_attempted"
    case dmSent = "dm_sent"
    case dmFailed = "dm_failed"
    case linkClicked = "link_clicked"
    case leadCaptured = "lead_captured"
    case leadTagged = "lead_tagged"
    case recommendationGenerated = "recommendation_generated"
    case proposalViewed = "proposal_viewed"
    case proposalApplied = "proposal_applied"
    case subscriptionStarted = "subscription_started"
    case subscriptionRenewed = "subscription_renewed"
    case subscriptionCanceled = "subscription_canceled"
    case accountDeletionRequested = "account_deletion_requested"
}

struct AnalyticsEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: AnalyticsEventName
    var workspaceId: UUID?
    var userId: UUID?
    var properties: [String: String]
    var occurredAt: Date
}

enum AccountDeletionState: String, Codable, Sendable {
    case idle
    case reauthenticationRequired = "reauthentication_required"
    case confirmed
    case requested
}

struct AccountDeletionRequest: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var userId: UUID
    var requestedAt: Date
    var scheduledDeletionDate: Date
    var state: AccountDeletionState
}

enum LoadableState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(String)
    case unavailable(String)
}
