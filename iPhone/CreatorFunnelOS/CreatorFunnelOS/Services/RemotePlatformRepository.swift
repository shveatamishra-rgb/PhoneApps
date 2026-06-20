import Foundation

private struct AuthRequest: Encodable {
    let fullName: String?
    let email: String
    let password: String
}

private struct EmailRequest: Encodable { let email: String }
private struct PasswordRequest: Encodable { let password: String }
private struct StatusRequest: Encodable { let status: FunnelStatus }
private struct PostAssignmentRequest: Encodable { let postIds: [UUID] }
private struct TagRequest: Encodable { let tag: LeadTag }
private struct RecommendationStatusRequest: Encodable { let status: RecommendationStatus }
private struct EventRequest: Encodable { let event: AnalyticsEvent }
private struct URLResponseEnvelope: Decodable { let url: URL }
private struct AccountsEnvelope: Decodable { let accounts: [SocialAccount] }
private struct DeletionEnvelope: Decodable { let deletionRequest: AccountDeletionRequest? }

actor RemotePlatformRepository:
    AuthService,
    WorkspaceService,
    SocialAccountService,
    PlannerService,
    FunnelService,
    LeadService,
    AnalyticsService,
    RecommendationService,
    NotificationService,
    PolicyService,
    AccountService,
    FeatureFlagService
{
    private let client: APIClient
    private let configuration: AppConfiguration
    private let sessionStore: KeychainSessionStore

    init(
        client: APIClient,
        configuration: AppConfiguration,
        sessionStore: KeychainSessionStore
    ) {
        self.client = client
        self.configuration = configuration
        self.sessionStore = sessionStore
    }

    func restoreSession() async -> AuthSession? {
        guard let stored = await client.storedSession() else { return nil }
        return AuthSession(
            user: stored.user,
            accessToken: stored.accessToken,
            refreshToken: stored.refreshToken,
            isEmailVerified: stored.isEmailVerified
        )
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        try await authenticate(
            path: "/v1/auth/signin",
            request: AuthRequest(fullName: nil, email: email, password: password)
        )
    }

    func signUp(fullName: String, email: String, password: String) async throws -> AuthSession {
        try await authenticate(
            path: "/v1/auth/signup",
            request: AuthRequest(fullName: fullName, email: email, password: password)
        )
    }

    func sendPasswordReset(email: String) async throws {
        try await client.sendWithoutResponse(
            "/v1/auth/password-reset/request",
            method: "POST",
            body: EmailRequest(email: email),
            authenticated: false
        )
    }

    func resendVerificationEmail() async throws {
        try await client.sendWithoutResponse(
            "/v1/auth/email-verification/resend",
            method: "POST"
        )
    }

    func signOut() async {
        try? await client.sendWithoutResponse("/v1/auth/signout", method: "POST")
        await client.clearSession()
    }

    func fetchCurrentWorkspace() async throws -> Workspace {
        try await client.send("/v1/workspaces/current")
    }

    func fetchWorkspaceSnapshot() async throws -> WorkspaceSnapshot {
        try await client.send("/v1/workspace/snapshot")
    }

    func fetchAvailableWorkspaces() async throws -> [Workspace] {
        try await client.send("/v1/workspaces")
    }

    func fetchMemberships(workspaceId: UUID) async throws -> [Membership] {
        try await client.send("/v1/workspaces/\(workspaceId)/memberships")
    }

    func fetchConnectedAccounts(workspaceId: UUID) async throws -> [SocialAccount] {
        let response: AccountsEnvelope = try await client.send(
            "/v1/social-accounts?workspaceId=\(workspaceId)"
        )
        return response.accounts
    }

    func instagramAuthorizationURL(workspaceId: UUID) async throws -> URL {
        let response: URLResponseEnvelope = try await client.send(
            "/v1/social-accounts/instagram/authorize?workspaceId=\(workspaceId)"
        )
        return response.url
    }

    func completeInstagramConnection(workspaceId: UUID) async throws -> SocialAccount {
        let accounts = try await fetchConnectedAccounts(workspaceId: workspaceId)
        guard let account = accounts.first(where: { $0.platform == .instagram }) else {
            throw ServiceError.validation("Instagram authorization completed, but no account was returned.")
        }
        return account
    }

    func connectInstagram(handle: String) async throws -> SocialAccount {
        throw ServiceError.configuration("Live accounts must be connected through Meta authorization.")
    }

    func disconnect(accountId: UUID) async throws {
        try await client.sendWithoutResponse(
            "/v1/social-accounts/\(accountId)",
            method: "DELETE"
        )
    }

    func refreshPermissions(accountId: UUID) async throws -> SocialAccount {
        try await client.send(
            "/v1/social-accounts/\(accountId)/refresh",
            method: "POST"
        )
    }

    func fetchPosts(accountId: UUID) async throws -> [SocialPost] {
        try await client.send("/v1/social-accounts/\(accountId)/posts")
    }

    func fetchIdeas(workspaceId: UUID) async throws -> [ContentIdea] {
        try await client.send("/v1/planner/ideas?workspaceId=\(workspaceId)")
    }

    func fetchDrafts(workspaceId: UUID) async throws -> [ContentDraft] {
        try await client.send("/v1/planner/drafts?workspaceId=\(workspaceId)")
    }

    func fetchTemplates() async throws -> [ContentTemplate] {
        try await client.send("/v1/planner/templates")
    }

    func saveIdea(_ idea: ContentIdea) async throws -> ContentIdea {
        try await client.send("/v1/planner/ideas", method: "PUT", body: idea)
    }

    func saveDraft(_ draft: ContentDraft) async throws -> ContentDraft {
        try await client.send("/v1/planner/drafts", method: "PUT", body: draft)
    }

    func fetchFunnels(workspaceId: UUID) async throws -> [Funnel] {
        try await client.send("/v1/funnels?workspaceId=\(workspaceId)")
    }

    func saveFunnel(_ funnel: Funnel) async throws -> Funnel {
        try await client.send("/v1/funnels", method: "PUT", body: funnel)
    }

    func updateStatus(funnelId: UUID, status: FunnelStatus) async throws -> Funnel {
        try await client.send(
            "/v1/funnels/\(funnelId)/status",
            method: "PATCH",
            body: StatusRequest(status: status)
        )
    }

    func assignPosts(funnelId: UUID, postIds: [UUID]) async throws -> Funnel {
        try await client.send(
            "/v1/funnels/\(funnelId)/posts",
            method: "PUT",
            body: PostAssignmentRequest(postIds: postIds)
        )
    }

    func fetchLeads(workspaceId: UUID) async throws -> [LeadContact] {
        try await client.send("/v1/leads?workspaceId=\(workspaceId)")
    }

    func fetchEvents(leadId: UUID) async throws -> [LeadEvent] {
        try await client.send("/v1/leads/\(leadId)/events")
    }

    func addTag(leadId: UUID, tag: LeadTag) async throws {
        try await client.sendWithoutResponse(
            "/v1/leads/\(leadId)/tags",
            method: "POST",
            body: TagRequest(tag: tag)
        )
    }

    func saveNote(_ note: LeadNote) async throws -> LeadNote {
        try await client.send("/v1/leads/\(note.leadId)/notes", method: "POST", body: note)
    }

    func requestExport(_ request: ExportRequest) async throws -> ExportResult {
        try await client.send("/v1/leads/export", method: "POST", body: request)
    }

    func fetchSnapshot(workspaceId: UUID) async throws -> AnalyticsSnapshot {
        try await client.send("/v1/analytics?workspaceId=\(workspaceId)")
    }

    func track(_ event: AnalyticsEvent) async {
        try? await client.sendWithoutResponse(
            "/v1/events",
            method: "POST",
            body: EventRequest(event: event)
        )
    }

    func fetchRecommendations(workspaceId: UUID) async throws -> [Recommendation] {
        try await client.send("/v1/recommendations?workspaceId=\(workspaceId)")
    }

    func fetchProposal(recommendationId: UUID) async throws -> Proposal {
        try await client.send("/v1/recommendations/\(recommendationId)/proposal")
    }

    func updateRecommendation(
        id: UUID,
        status: RecommendationStatus
    ) async throws -> Recommendation {
        try await client.send(
            "/v1/recommendations/\(id)",
            method: "PATCH",
            body: RecommendationStatusRequest(status: status)
        )
    }

    func applyProposal(id: UUID) async throws -> Proposal {
        try await client.send("/v1/proposals/\(id)/apply", method: "POST")
    }

    func fetchPreferences(userId: UUID) async throws -> NotificationPreference {
        try await client.send("/v1/notifications/preferences")
    }

    func savePreferences(
        _ preference: NotificationPreference
    ) async throws -> NotificationPreference {
        try await client.send(
            "/v1/notifications/preferences",
            method: "PUT",
            body: preference
        )
    }

    func privacyPolicy() async throws -> PolicyDocument {
        try await client.send("/v1/policies/privacy", authenticated: false)
    }

    func termsOfService() async throws -> PolicyDocument {
        try await client.send("/v1/policies/terms", authenticated: false)
    }

    func subscriptionTerms() async throws -> PolicyDocument {
        try await client.send("/v1/policies/subscription", authenticated: false)
    }

    func connectedAccountPermissions() async throws -> PolicyDocument {
        try await client.send("/v1/policies/permissions", authenticated: false)
    }

    func requestReauthentication(password: String) async throws {
        try await client.sendWithoutResponse(
            "/v1/account/reauthenticate",
            method: "POST",
            body: PasswordRequest(password: password)
        )
    }

    func requestDeletion(userId: UUID) async throws -> AccountDeletionRequest {
        try await client.send("/v1/account/delete", method: "POST")
    }

    func deletionStatus(userId: UUID) async throws -> AccountDeletionRequest? {
        let response: DeletionEnvelope = try await client.send("/v1/account/deletion-status")
        return response.deletionRequest
    }

    func fetchFlags(workspaceId: UUID) async throws -> [FeatureFlag] {
        try await client.send("/v1/feature-flags?workspaceId=\(workspaceId)")
    }

    func isEnabled(_ key: String, workspaceId: UUID) async -> Bool {
        let flags = try? await fetchFlags(workspaceId: workspaceId)
        return flags?.first(where: { $0.key == key })?.isEnabled == true
    }

    private func authenticate(path: String, request: AuthRequest) async throws -> AuthSession {
        let response: AuthSession = try await client.send(
            path,
            method: "POST",
            body: request,
            authenticated: false
        )
        guard let refreshToken = response.refreshToken else {
            throw ServiceError.validation("The server did not return a refresh token.")
        }
        let stored = StoredSession(
            user: response.user,
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            isEmailVerified: response.isEmailVerified
        )
        try await client.setSession(stored)
        return response
    }
}
