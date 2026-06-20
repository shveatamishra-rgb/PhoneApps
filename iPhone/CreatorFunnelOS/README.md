# Creator Funnel OS

Creator Funnel OS is a production-oriented SwiftUI app and self-hostable API for Instagram creators who want a calm, compliant way to plan content, configure keyword-request DM funnels, capture leads, and review operational analytics.

The product intentionally excludes fake follower generation, follow-for-follow, mass following, scraping, unsolicited messaging, engagement exchanges, and other inauthentic mechanics.

## Run

Open `CreatorFunnelOS.xcodeproj` in Xcode 26.5 or later and run the `CreatorFunnelOS` scheme on iOS 17 or later.

```sh
./build.sh
```

## Included product surface

- Compliance-oriented onboarding and polished loading/empty/error states
- Email authentication, rotating refresh sessions, Keychain storage, and account deletion
- Official Instagram professional-account OAuth handoff
- Signed Meta webhook processing for keyword comments and private replies
- AES-256-GCM encryption for Meta access tokens at rest
- Dashboard analytics, planner, funnels, leads, settings, and legal screens
- StoreKit 2 purchases, current entitlements, Restore Purchases, and subscription management
- A safe sample-data repository that can still be enabled for demos

## Architecture

- `App/`: lifecycle and shared orchestration state
- `Core/`: design system, networking, security, configuration, and web authentication
- `Models/`: Codable platform-neutral entities
- `Services/`: service contracts, live REST adapter, StoreKit 2, and mock repository
- `Features/`: feature-oriented SwiftUI screens
- `Backend/`: Fastify/TypeScript API, PostgreSQL schema, OAuth callback, and webhooks
- `Docs/`: production integration, Android parity, and real-device testing

The checked-in project uses live services (`USE_MOCK_SERVICES = NO`). Set that build setting to `YES` when you want the safe sample-data experience. Never put Meta secrets in the iOS target.

For deployment, credentials, and the end-to-end test checklist, read [REAL_DEVICE_TESTING.md](Docs/REAL_DEVICE_TESTING.md).
