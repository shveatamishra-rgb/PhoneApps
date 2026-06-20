# Future API integration

## Composition

`ServiceContainer` is the only dependency bundle passed into `AppState`. Replace `MockPlatformRepository` with production implementations while keeping the protocol signatures stable.

Suggested production adapters:

- `RemoteAuthService`: identity provider, passkeys/Sign in with Apple, token refresh
- `RemoteWorkspaceService`: user/workspace bootstrap response
- `MetaSocialAccountService`: OAuth authorization, token health, eligible post sync
- `RemotePlannerService`: ideas, drafts, templates, scheduling notes
- `RemoteFunnelService`: funnel validation, assignments, status transitions
- `RemoteLeadService`: consent-based lead records, notes, tags, export jobs
- `RemoteAnalyticsService`: immutable event ingestion and aggregate snapshots
- `RemoteRecommendationService`: recommendation rules/model output and proposal lifecycle
- `StoreKitBillingService`: StoreKit 2 products, transactions, restore, entitlement status
- `RemoteNotificationService`: push preferences and weekly digest settings
- `RemotePolicyService`: versioned hosted policies
- `RemoteAccountService`: recent authentication and deletion-request lifecycle
- `RemoteFeatureFlagService`: workspace-scoped rollout configuration

## Suggested bootstrap response

A single authenticated bootstrap endpoint can return:

- user
- active workspace and membership
- connected social accounts
- subscription
- feature flags
- notification preferences
- first dashboard analytics snapshot

That avoids a waterfall while retaining independent service contracts for later refreshes.

## Safety and compliance

- Never collect Instagram credentials.
- Encrypt platform tokens and isolate them from client-readable storage.
- Validate funnel status transitions and message eligibility on the server.
- Record an audit log for account connection, permission changes, funnel activation, exports, and deletion requests.
- Treat analytics ingestion as append-only and idempotent.
- Make lead export links short-lived and authorization-scoped.
- Keep account deletion and App Store subscription cancellation as clearly separate operations.

## Billing

The current app never auto-restores purchases. Preserve that behavior: load cached/server entitlement state at launch and perform App Store restore only after an explicit user action.
