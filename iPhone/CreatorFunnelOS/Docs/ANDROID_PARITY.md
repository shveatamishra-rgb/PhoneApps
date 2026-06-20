# Android and shared-backend parity

The files in `Models/PlatformDomainModels.swift`, `Services/ServiceContracts.swift`, and `Resources/analytics-event-taxonomy.json` define shared-domain concepts. They should be mirrored in Kotlin without carrying SwiftUI presentation details across platforms.

## Keep identical across iOS and Android

- Entity field meanings and UUID identifiers
- Enum raw values
- ISO-8601 date serialization
- Analytics event names and property keys
- Funnel status transition rules
- Recommendation and proposal lifecycle states
- Subscription tier/status/billing-period values
- Feature-flag keys and variants
- Workspace membership roles
- Account deletion request states

## Keep platform-specific

- SwiftUI/Jetpack Compose views and navigation
- Apple/Google billing adapters
- Secure credential storage APIs
- Push notification registration
- Deep-link routing
- Accessibility implementation details
- Local cache technology

## Suggested Android modules

- `domain`: entities, enums, repository interfaces
- `data`: network DTOs, persistence, repository implementations
- `analytics`: event builder and ingestion client
- `billing`: Google Play Billing adapter
- `feature-*`: Home, Planner, Funnels, Leads, Settings
- `design-system`: Compose tokens and reusable components

The backend should remain authoritative for subscription entitlements, platform-token health, funnel eligibility, analytics aggregation, and account deletion.
