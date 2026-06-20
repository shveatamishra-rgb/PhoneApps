# Real-device testing

## What is ready

The iOS client now uses HTTPS services, Keychain-backed sessions, official web authentication, StoreKit 2, and real account-deletion requests. The backend includes PostgreSQL persistence, password hashing, rotating refresh tokens, encrypted Meta tokens, signed webhook verification, idempotency, workspace authorization, and a comment-keyword funnel processor.

No fake followers, mass following, scraping, unsolicited bulk DMs, or follow-for-follow behavior is present.

## 1. Deploy the API

The iPhone cannot use `localhost` on your Mac as a production endpoint. Deploy `Backend/` to an HTTPS host with PostgreSQL.

1. Copy `Backend/.env.example` to the hosting provider's secret/environment settings.
2. Generate secrets:

   ```sh
   openssl rand -base64 48
   openssl rand -hex 32
   ```

   Use the first value for `JWT_SECRET` and the 64-character hex value for `TOKEN_ENCRYPTION_KEY`.
3. Run `npm run db:migrate`.
4. Deploy with `npm run build && npm start`, or use the included Dockerfile.
5. Confirm `https://YOUR-API/health` returns `{"status":"ok"}`.
6. Schedule `npm run accounts:delete-due` daily.

## 2. Configure Meta

Create a Meta app with Instagram API using Instagram Login. Add your Instagram professional account as a tester while the Meta app is in development mode.

- OAuth redirect: `https://YOUR-API/v1/social-accounts/instagram/callback`
- Webhook callback: `https://YOUR-API/webhooks/instagram`
- Verify token: the value of `META_WEBHOOK_VERIFY_TOKEN`
- Permissions:
  - `instagram_business_basic`
  - `instagram_business_manage_messages`
  - `instagram_business_manage_comments`
  - `instagram_business_content_publish`

Subscribe the Instagram webhook product to comment events. Put the Meta app ID and secret on the server only. Test comments from a second eligible Instagram account.

## 3. Point the app to the API

Open `CreatorFunnelOS.xcodeproj`, select the app target, and change the `API_BASE_URL` user-defined build setting for Debug and Release from `https://api.creatorfunnelos.com` to your deployed HTTPS URL. Keep `USE_MOCK_SERVICES = NO`.

The current bundle identifier is `com.shveatamishra.creatorfunnelos` and the configured Apple team is `45QWJVLL5D`. Adjust these in Signing & Capabilities if needed.

## 4. Install directly on your iPhone

1. Connect the iPhone and trust the Mac.
2. Choose the iPhone as the Xcode run destination.
3. Choose your Apple Developer team and allow automatic signing.
4. Press Run.

TestFlight is not required for testing on your own registered device.

## 5. Create subscription products

In App Store Connect, create one subscription group containing:

- `com.shveatamishra.creatorfunnelos.pro.monthly`
- `com.shveatamishra.creatorfunnelos.pro.yearly`

Use an App Store sandbox tester. Restore Purchases calls `AppStore.sync()` only after the user taps it.

The backend currently records locally verified StoreKit transactions. Before public release, add App Store Server API verification and App Store Server Notifications so refunds and cross-platform entitlements are server-authoritative.

## End-to-end checklist

### Account and security

- Sign up and force-quit/reopen; the Keychain session should restore.
- Sign out; protected data should disappear.
- Try a wrong password and verify the error is generic.
- Request account deletion and verify the scheduled state.

### Instagram

- Authorize your professional account and return to the dashboard.
- Verify the connected handle appears.
- Confirm the database contains encrypted—not plain-text—Meta tokens.
- Disconnect and reconnect.

### Funnel

- Create an active funnel with a unique keyword, reply, DM, and HTTPS destination.
- Assign a synced post.
- Comment the exact keyword from a second Instagram account.
- Verify one public reply, one private reply, one lead, and lead events.
- Deliver the same webhook twice; it must process once.
- Pause the funnel; it must stop triggering.
- Put the keyword inside a larger word; it must not match.

### StoreKit

- Buy monthly/yearly in sandbox and verify Pro access.
- Cancel the purchase sheet; the app must not grant access.
- Reinstall, tap Restore Purchases, and verify the entitlement returns.
- Open Manage Subscription.

### Failure behavior

- Test no network while saving a funnel; no false success should appear.
- Revoke Meta permissions and verify reconnect is required.
- Test expired access-token refresh and revoked refresh-token sign-out.

## Before App Store submission

Own-account testing can begin after the API and Meta setup above. Public release still requires Meta App Review, final hosted policies, production email delivery, App Store Server verification/notifications, App Privacy answers, subscription metadata, support URL, screenshots, and an App Review demo account or complete demo mode.
