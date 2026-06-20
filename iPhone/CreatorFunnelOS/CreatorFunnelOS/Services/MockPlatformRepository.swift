import Foundation

actor MockPlatformRepository:
    AuthService,
    WorkspaceService,
    SocialAccountService,
    PlannerService,
    FunnelService,
    LeadService,
    AnalyticsService,
    RecommendationService,
    BillingService,
    NotificationService,
    PolicyService,
    AccountService,
    FeatureFlagService
{
    private var snapshot = SampleData.workspace
    private var socialAccount = SampleData.socialAccount
    private var subscription = SampleData.subscription
    private var notificationPreference = SampleData.notificationPreference
    private var featureFlags = SampleData.featureFlags
    private var proposals = SampleData.proposals
    private var trackedEvents: [AnalyticsEvent] = []
    private var deletionRequest: AccountDeletionRequest?

    func restoreSession() async -> AuthSession? {
        nil
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        try await latency()
        guard email.contains("@"), password.count >= 6 else {
            throw ServiceError.invalidCredentials
        }
        return AuthSession(user: SampleData.user, accessToken: "mock-access-token", isEmailVerified: true)
    }

    func signUp(fullName: String, email: String, password: String) async throws -> AuthSession {
        try await latency()
        guard !fullName.isEmpty, email.contains("@"), password.count >= 8 else {
            throw ServiceError.validation("Use a name, valid email, and password with at least eight characters.")
        }
        var user = SampleData.user
        user.fullName = fullName
        user.email = email
        return AuthSession(user: user, accessToken: "mock-unverified-token", isEmailVerified: false)
    }

    func sendPasswordReset(email: String) async throws {
        try await latency(short: true)
        guard email.contains("@") else {
            throw ServiceError.validation("Enter a valid email address.")
        }
    }

    func resendVerificationEmail() async throws {
        try await latency(short: true)
    }

    func signOut() async {}

    func fetchCurrentWorkspace() async throws -> Workspace {
        try await latency(short: true)
        return SampleData.domainWorkspace
    }

    func fetchWorkspaceSnapshot() async throws -> WorkspaceSnapshot {
        try await latency()
        return snapshot
    }

    func fetchAvailableWorkspaces() async throws -> [Workspace] {
        try await latency(short: true)
        return [SampleData.domainWorkspace]
    }

    func fetchMemberships(workspaceId: UUID) async throws -> [Membership] {
        try await latency(short: true)
        return [SampleData.membership]
    }

    func fetchConnectedAccounts(workspaceId: UUID) async throws -> [SocialAccount] {
        try await latency(short: true)
        return socialAccount.isConnected ? [socialAccount] : []
    }

    func instagramAuthorizationURL(workspaceId: UUID) async throws -> URL {
        URL(string: "creatorfunnelmock://instagram")!
    }

    func completeInstagramConnection(workspaceId: UUID) async throws -> SocialAccount {
        try await connectInstagram(handle: "demo.creator")
    }

    func connectInstagram(handle: String) async throws -> SocialAccount {
        try await latency()
        let normalized = handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")

        guard !normalized.isEmpty else {
            throw ServiceError.validation("Enter the professional account handle you want to connect.")
        }

        socialAccount.handle = normalized
        socialAccount.isConnected = true
        socialAccount.lastSyncAt = .now
        var account = SampleData.account
        account.username = normalized
        snapshot.account = account
        await track(event(.accountConnected, properties: ["platform": "instagram"]))
        return socialAccount
    }

    func disconnect(accountId: UUID) async throws {
        try await latency(short: true)
        socialAccount.isConnected = false
        snapshot.account?.isConnected = false
        await track(event(.accountDisconnected, properties: ["platform": "instagram"]))
    }

    func refreshPermissions(accountId: UUID) async throws -> SocialAccount {
        try await latency()
        guard socialAccount.isConnected else { throw ServiceError.permissionDenied }
        socialAccount.lastSyncAt = .now
        return socialAccount
    }

    func fetchPosts(accountId: UUID) async throws -> [SocialPost] {
        try await latency(short: true)
        return SampleData.socialPosts
    }

    func fetchIdeas(workspaceId: UUID) async throws -> [ContentIdea] {
        try await latency(short: true)
        return snapshot.contentIdeas
    }

    func fetchDrafts(workspaceId: UUID) async throws -> [ContentDraft] {
        try await latency(short: true)
        return snapshot.contentDrafts
    }

    func fetchTemplates() async throws -> [ContentTemplate] {
        try await latency(short: true)
        return snapshot.contentTemplates
    }

    func saveIdea(_ idea: ContentIdea) async throws -> ContentIdea {
        try await latency(short: true)
        if let index = snapshot.contentIdeas.firstIndex(where: { $0.id == idea.id }) {
            snapshot.contentIdeas[index] = idea
        } else {
            snapshot.contentIdeas.insert(idea, at: 0)
        }
        return idea
    }

    func saveDraft(_ draft: ContentDraft) async throws -> ContentDraft {
        try await latency(short: true)
        if let index = snapshot.contentDrafts.firstIndex(where: { $0.id == draft.id }) {
            snapshot.contentDrafts[index] = draft
        } else {
            snapshot.contentDrafts.insert(draft, at: 0)
        }
        return draft
    }

    func fetchFunnels(workspaceId: UUID) async throws -> [Funnel] {
        try await latency(short: true)
        return snapshot.funnels
    }

    func saveFunnel(_ funnel: Funnel) async throws -> Funnel {
        try await latency(short: true)
        guard
            !funnel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !funnel.triggerKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ServiceError.validation("A funnel needs a name and trigger keyword.")
        }

        var saved = funnel
        saved.triggerKeyword = funnel.triggerKeyword.uppercased()
        saved.updatedAt = .now

        if let index = snapshot.funnels.firstIndex(where: { $0.id == saved.id }) {
            snapshot.funnels[index] = saved
        } else {
            snapshot.funnels.insert(saved, at: 0)
            await track(event(.funnelCreated, properties: ["funnel_id": saved.id.uuidString]))
        }
        refreshActiveFunnelMetric()
        return saved
    }

    func updateStatus(funnelId: UUID, status: FunnelStatus) async throws -> Funnel {
        try await latency(short: true)
        guard let index = snapshot.funnels.firstIndex(where: { $0.id == funnelId }) else {
            throw ServiceError.validation("That funnel could not be found.")
        }
        snapshot.funnels[index].status = status
        snapshot.funnels[index].updatedAt = .now
        refreshActiveFunnelMetric()
        if status == .active {
            await track(event(.funnelActivated, properties: ["funnel_id": funnelId.uuidString]))
        } else if status == .paused {
            await track(event(.funnelPaused, properties: ["funnel_id": funnelId.uuidString]))
        }
        return snapshot.funnels[index]
    }

    func assignPosts(funnelId: UUID, postIds: [UUID]) async throws -> Funnel {
        try await latency(short: true)
        guard let index = snapshot.funnels.firstIndex(where: { $0.id == funnelId }) else {
            throw ServiceError.validation("That funnel could not be found.")
        }
        snapshot.funnels[index].connectedPostIds = postIds
        snapshot.funnels[index].updatedAt = .now
        await track(event(.postAssignedToFunnel, properties: [
            "funnel_id": funnelId.uuidString,
            "post_count": String(postIds.count)
        ]))
        return snapshot.funnels[index]
    }

    func fetchLeads(workspaceId: UUID) async throws -> [LeadContact] {
        try await latency(short: true)
        return snapshot.contacts
    }

    func fetchEvents(leadId: UUID) async throws -> [LeadEvent] {
        try await latency(short: true)
        return [
            LeadEvent(id: UUID(), leadId: leadId, type: .keywordTriggered, detail: "Requested the resource using a comment keyword.", occurredAt: Date().addingTimeInterval(-8_000)),
            LeadEvent(id: UUID(), leadId: leadId, type: .dmSent, detail: "The requested resource message was delivered.", occurredAt: Date().addingTimeInterval(-7_900)),
            LeadEvent(id: UUID(), leadId: leadId, type: .detailsShared, detail: "Shared contact details on the destination page.", occurredAt: Date().addingTimeInterval(-7_200))
        ]
    }

    func addTag(leadId: UUID, tag: LeadTag) async throws {
        try await latency(short: true)
        guard let index = snapshot.contacts.firstIndex(where: { $0.id == leadId }) else { return }
        if !snapshot.contacts[index].tags.contains(tag.name) {
            snapshot.contacts[index].tags.append(tag.name)
        }
        await track(event(.leadTagged, properties: ["lead_id": leadId.uuidString, "tag": tag.name]))
    }

    func saveNote(_ note: LeadNote) async throws -> LeadNote {
        try await latency(short: true)
        guard let index = snapshot.contacts.firstIndex(where: { $0.id == note.leadId }) else {
            throw ServiceError.validation("That lead could not be found.")
        }
        snapshot.contacts[index].notes = note.body
        return note
    }

    func requestExport(_ request: ExportRequest) async throws -> ExportResult {
        try await latency()
        return ExportResult(downloadURL: nil, rowCount: snapshot.contacts.count, expiresAt: nil, isPlaceholder: true)
    }

    func fetchSnapshot(workspaceId: UUID) async throws -> AnalyticsSnapshot {
        try await latency(short: true)
        guard let analytics = snapshot.analytics else { throw ServiceError.unavailable }
        return analytics
    }

    func track(_ event: AnalyticsEvent) async {
        trackedEvents.append(event)
    }

    func fetchRecommendations(workspaceId: UUID) async throws -> [Recommendation] {
        try await latency(short: true)
        return snapshot.recommendations
    }

    func fetchProposal(recommendationId: UUID) async throws -> Proposal {
        try await latency(short: true)
        guard let proposal = proposals.first(where: { $0.recommendationId == recommendationId }) else {
            throw ServiceError.unavailable
        }
        await track(event(.proposalViewed, properties: ["recommendation_id": recommendationId.uuidString]))
        return proposal
    }

    func updateRecommendation(id: UUID, status: RecommendationStatus) async throws -> Recommendation {
        try await latency(short: true)
        guard let index = snapshot.recommendations.firstIndex(where: { $0.id == id }) else {
            throw ServiceError.unavailable
        }
        snapshot.recommendations[index].status = status
        return snapshot.recommendations[index]
    }

    func applyProposal(id: UUID) async throws -> Proposal {
        try await latency()
        guard let index = proposals.firstIndex(where: { $0.id == id }) else {
            throw ServiceError.unavailable
        }
        proposals[index].state = .applied
        if let recommendationIndex = snapshot.recommendations.firstIndex(where: {
            $0.id == proposals[index].recommendationId
        }) {
            snapshot.recommendations[recommendationIndex].status = .applied
        }
        await track(event(.proposalApplied, properties: ["proposal_id": id.uuidString]))
        return proposals[index]
    }

    func currentSubscription(workspaceId: UUID) async -> Subscription {
        subscription
    }

    func availableProducts() async throws -> [BillingProduct] {
        [
            BillingProduct(id: "mock.monthly", period: .monthly, displayPrice: "$9.99", displayName: "Creator Pro Monthly"),
            BillingProduct(id: "mock.yearly", period: .yearly, displayPrice: "$79.99", displayName: "Creator Pro Yearly")
        ]
    }

    func purchase(tier: PlanTier, period: BillingPeriod) async throws -> Subscription {
        try await latency()
        subscription.tier = tier
        subscription.status = .active
        subscription.billingPeriod = period
        subscription.isTrial = false
        subscription.renewalDate = Calendar.current.date(
            byAdding: period == .yearly ? .year : .month,
            value: 1,
            to: .now
        )
        await track(event(.subscriptionStarted, properties: [
            "tier": tier.rawValue,
            "period": period.rawValue
        ]))
        return subscription
    }

    func restorePurchases() async throws -> Subscription {
        try await latency()
        return subscription
    }

    func manageSubscriptionURL() async -> URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    func fetchPreferences(userId: UUID) async throws -> NotificationPreference {
        try await latency(short: true)
        return notificationPreference
    }

    func savePreferences(_ preference: NotificationPreference) async throws -> NotificationPreference {
        try await latency(short: true)
        notificationPreference = preference
        return preference
    }

    func privacyPolicy() async throws -> PolicyDocument {
        policy(id: "privacy", title: "Privacy Policy")
    }

    func termsOfService() async throws -> PolicyDocument {
        policy(id: "terms", title: "Terms of Service")
    }

    func subscriptionTerms() async throws -> PolicyDocument {
        policy(id: "subscription", title: "Subscription Terms")
    }

    func connectedAccountPermissions() async throws -> PolicyDocument {
        policy(id: "permissions", title: "Connected Account Permissions")
    }

    func requestReauthentication(password: String) async throws {
        try await latency(short: true)
        guard password.count >= 6 else { throw ServiceError.invalidCredentials }
    }

    func requestDeletion(userId: UUID) async throws -> AccountDeletionRequest {
        try await latency()
        let request = AccountDeletionRequest(
            id: UUID(),
            userId: userId,
            requestedAt: .now,
            scheduledDeletionDate: Calendar.current.date(byAdding: .day, value: 30, to: .now)!,
            state: .requested
        )
        deletionRequest = request
        await track(event(.accountDeletionRequested, properties: ["user_id": userId.uuidString]))
        return request
    }

    func deletionStatus(userId: UUID) async throws -> AccountDeletionRequest? {
        try await latency(short: true)
        return deletionRequest
    }

    func fetchFlags(workspaceId: UUID) async throws -> [FeatureFlag] {
        try await latency(short: true)
        return featureFlags
    }

    func isEnabled(_ key: String, workspaceId: UUID) async -> Bool {
        featureFlags.first(where: { $0.key == key })?.isEnabled == true
    }

    private func refreshActiveFunnelMetric() {
        guard let index = snapshot.metrics.firstIndex(where: { $0.kind == .activeFunnels }) else { return }
        let count = snapshot.funnels.filter { $0.status == .active }.count
        snapshot.metrics[index].value = String(count)
        snapshot.analytics?.activeFunnelCount = count
    }

    private func latency(short: Bool = false) async throws {
        try await Task.sleep(for: short ? .milliseconds(220) : .milliseconds(550))
    }

    private func event(
        _ name: AnalyticsEventName,
        properties: [String: String] = [:]
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            id: UUID(),
            name: name,
            workspaceId: SampleData.workspaceId,
            userId: SampleData.userId,
            properties: properties,
            occurredAt: .now
        )
    }

    private func policy(id: String, title: String) -> PolicyDocument {
        PolicyDocument(
            id: id,
            title: title,
            body: "This mock document is replaced by a versioned policy from the production policy service.",
            updatedAt: .now,
            publicURL: URL(string: "https://example.com/\(id)")
        )
    }
}
