import Foundation

@MainActor
final class AppState: ObservableObject {
    enum Phase: Equatable {
        case launching
        case onboarding
        case authentication
        case accountConnection
        case main
        case deletionRequested
    }

    @Published var phase: Phase
    @Published var workspace = WorkspaceSnapshot.empty
    @Published var currentUser = SampleData.user
    @Published var currentWorkspace = SampleData.domainWorkspace
    @Published var subscription = SampleData.subscription
    @Published var notificationPreference = SampleData.notificationPreference
    @Published var billingProducts: [BillingProduct] = []
    @Published var socialPosts: [SocialPost] = []
    @Published var featureFlags: [FeatureFlag] = []
    @Published var deletionRequest: AccountDeletionRequest?
    @Published var isLoading = false
    @Published var isPaywallPresented = false
    @Published var errorMessage: String?

    let services: ServiceContainer
    let configuration: AppConfiguration
    private let defaults: UserDefaults
    private let webAuthentication = WebAuthenticationSession()

    init(
        services: ServiceContainer,
        configuration: AppConfiguration = .current,
        defaults: UserDefaults = .standard
    ) {
        self.services = services
        self.configuration = configuration
        self.defaults = defaults
        phase = .launching
    }

    var isUsingMockServices: Bool {
        configuration.useMockServices
    }

    func bootstrap() async {
        guard phase == .launching else { return }
        guard defaults.bool(forKey: StorageKey.completedOnboarding) else {
            phase = .onboarding
            return
        }
        guard let session = await services.auth.restoreSession() else {
            phase = .authentication
            return
        }

        currentUser = session.user
        isLoading = true
        defer { isLoading = false }
        do {
            currentWorkspace = try await services.workspaces.fetchCurrentWorkspace()
            let accounts = try await services.socialAccounts.fetchConnectedAccounts(
                workspaceId: currentWorkspace.id
            )
            phase = accounts.isEmpty ? .accountConnection : .main
            if let account = accounts.first {
                workspace.account = CreatorAccount(
                    id: account.id,
                    username: account.handle,
                    displayName: account.handle,
                    followerCount: 0,
                    isConnected: account.isConnected
                )
            }
            if phase == .main {
                await refreshWorkspace()
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .authentication
        }
    }

    func completeOnboarding() {
        defaults.set(true, forKey: StorageKey.completedOnboarding)
        phase = .authentication
    }

    func authenticate(
        fullName: String? = nil,
        email: String,
        password: String,
        isSignUp: Bool
    ) async -> AuthSession? {
        isLoading = true
        defer { isLoading = false }

        do {
            let session: AuthSession
            if isSignUp {
                session = try await services.auth.signUp(
                    fullName: fullName ?? "",
                    email: email,
                    password: password
                )
            } else {
                session = try await services.auth.signIn(email: email, password: password)
            }
            currentUser = session.user
            if session.isEmailVerified {
                phase = .accountConnection
            }
            return session
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // Retained as a lightweight preview/demo shortcut.
    func signIn() {
        phase = .accountConnection
    }

    func sendPasswordReset(email: String) async -> Bool {
        do {
            try await services.auth.sendPasswordReset(email: email)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func resendVerificationEmail() async {
        do {
            try await services.auth.resendVerificationEmail()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeEmailVerification() {
        phase = .accountConnection
    }

    func connectAccount() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if currentWorkspace.id == SampleData.workspaceId {
                currentWorkspace = try await services.workspaces.fetchCurrentWorkspace()
            }
            let authorizationURL = try await services.socialAccounts.instagramAuthorizationURL(
                workspaceId: currentWorkspace.id
            )
            if authorizationURL.scheme != "creatorfunnelmock" {
                let callback = try await webAuthentication.authenticate(
                    url: authorizationURL,
                    callbackScheme: configuration.callbackScheme
                )
                let status = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "status" })?.value
                guard status == nil || status == "success" else {
                    throw ServiceError.validation("Instagram did not authorize the connection.")
                }
            }
            let connected = try await services.socialAccounts.completeInstagramConnection(
                workspaceId: currentWorkspace.id
            )
            workspace.account = CreatorAccount(
                id: connected.id,
                username: connected.handle,
                displayName: connected.handle,
                followerCount: 0,
                isConnected: connected.isConnected
            )
            phase = .main
            await refreshWorkspace()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshWorkspace() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let snapshotRequest = services.workspaces.fetchWorkspaceSnapshot()
            async let workspaceRequest = services.workspaces.fetchCurrentWorkspace()
            async let flagsRequest = services.featureFlags.fetchFlags(workspaceId: currentWorkspace.id)
            async let preferencesRequest = services.notifications.fetchPreferences(userId: currentUser.id)

            workspace = try await snapshotRequest
            currentWorkspace = try await workspaceRequest
            featureFlags = try await flagsRequest
            notificationPreference = try await preferencesRequest
            subscription = await services.billing.currentSubscription(workspaceId: currentWorkspace.id)
            let accounts = try await services.socialAccounts.fetchConnectedAccounts(
                workspaceId: currentWorkspace.id
            )
            if let account = accounts.first {
                socialPosts = try await services.socialAccounts.fetchPosts(accountId: account.id)
            } else {
                socialPosts = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveFunnel(_ funnel: Funnel) async throws {
        let saved = try await services.funnels.saveFunnel(funnel)
        upsert(saved)
    }

    func setFunnelStatus(_ funnel: Funnel, status: FunnelStatus) async {
        do {
            let saved = try await services.funnels.updateStatus(funnelId: funnel.id, status: status)
            upsert(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFunnel(_ funnel: Funnel) async {
        await setFunnelStatus(funnel, status: funnel.status == .active ? .paused : .active)
    }

    func assignPosts(funnelId: UUID, postIds: [UUID]) async throws {
        let saved = try await services.funnels.assignPosts(funnelId: funnelId, postIds: postIds)
        upsert(saved)
    }

    func saveDraft(_ draft: ContentDraft) async throws {
        let saved = try await services.planner.saveDraft(draft)
        if let index = workspace.contentDrafts.firstIndex(where: { $0.id == saved.id }) {
            workspace.contentDrafts[index] = saved
        } else {
            workspace.contentDrafts.insert(saved, at: 0)
        }
    }

    func purchase(_ plan: SubscriptionPlan) async {
        isLoading = true
        defer { isLoading = false }

        do {
            subscription = try await services.billing.purchase(
                tier: .pro,
                period: plan == .yearly ? .yearly : .monthly
            )
            isPaywallPresented = false
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBillingProducts() async {
        do {
            billingProducts = try await services.billing.availableProducts()
        } catch {
            // The purchase sheet remains unavailable until App Store Connect
            // returns the configured products; the rest of the app still works.
            billingProducts = []
        }
    }

    func price(for plan: SubscriptionPlan) -> String {
        let period: BillingPeriod = plan == .yearly ? .yearly : .monthly
        return billingProducts.first(where: { $0.period == period })?.displayPrice ?? plan.price
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            subscription = try await services.billing.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func proposal(for recommendation: Recommendation) async -> Proposal? {
        do {
            let proposal = try await services.recommendations.fetchProposal(
                recommendationId: recommendation.id
            )
            await updateRecommendation(recommendation, status: .viewed)
            return proposal
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func applyProposal(_ proposal: Proposal) async -> Bool {
        do {
            _ = try await services.recommendations.applyProposal(id: proposal.id)
            if let index = workspace.recommendations.firstIndex(where: {
                $0.id == proposal.recommendationId
            }) {
                workspace.recommendations[index].status = .applied
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func dismissRecommendation(_ recommendation: Recommendation) async {
        await updateRecommendation(recommendation, status: .dismissed)
    }

    func saveNotificationPreference(_ preference: NotificationPreference) async {
        do {
            notificationPreference = try await services.notifications.savePreferences(preference)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestAccountDeletion(password: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await services.account.requestReauthentication(password: password)
            deletionRequest = try await services.account.requestDeletion(userId: currentUser.id)
            phase = .deletionRequested
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func disconnectAccount() async {
        do {
            guard let accountId = workspace.account?.id else { return }
            try await services.socialAccounts.disconnect(accountId: accountId)
            workspace = .empty
            phase = .accountConnection
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshConnectedAccount() async -> Bool {
        guard let accountId = workspace.account?.id else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await services.socialAccounts.refreshPermissions(accountId: accountId)
            socialPosts = try await services.socialAccounts.fetchPosts(accountId: accountId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        await services.auth.signOut()
        workspace = .empty
        socialPosts = []
        phase = .authentication
    }

    func resetDemo() {
        defaults.removeObject(forKey: StorageKey.completedOnboarding)
        workspace = .empty
        socialPosts = []
        deletionRequest = nil
        phase = .onboarding
    }

    func isFeatureEnabled(_ key: String) -> Bool {
        featureFlags.first(where: { $0.key == key })?.isEnabled == true
    }

    private func updateRecommendation(
        _ recommendation: Recommendation,
        status: RecommendationStatus
    ) async {
        do {
            let saved = try await services.recommendations.updateRecommendation(
                id: recommendation.id,
                status: status
            )
            if let index = workspace.recommendations.firstIndex(where: { $0.id == saved.id }) {
                workspace.recommendations[index] = saved
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func upsert(_ funnel: Funnel) {
        if let index = workspace.funnels.firstIndex(where: { $0.id == funnel.id }) {
            workspace.funnels[index] = funnel
        } else {
            workspace.funnels.insert(funnel, at: 0)
        }

        if let metricIndex = workspace.metrics.firstIndex(where: { $0.kind == .activeFunnels }) {
            workspace.metrics[metricIndex].value = String(
                workspace.funnels.filter { $0.status == .active }.count
            )
        }
    }
}

private enum StorageKey {
    static let completedOnboarding = "creatorFunnelOS.completedOnboarding"
}
