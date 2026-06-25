# App Store Connect Setup

## App record

- Name (App Store title): `Bhakti Angan: Daily Darshan` (home-screen display name is `Bhakti Angan`)
- Bundle ID: `in.bhaktiangan.app`
- SKU suggestion: `BHAKTI-ANGAN-IOS-001`
- Primary category: Lifestyle
- Secondary category: Health & Fitness
- Age rating: complete the questionnaire; the current content is intended for 4+

The paste-ready name, subtitle, keywords, promotional text, and full description
live in **`Docs/APP_STORE_METADATA.md`** (the single source of truth). In short:

- Subtitle: `Hindu Gods, Mantra & Japa`
- Keywords: deity names + adjacent intents (see metadata doc — don't repeat
  words already in the name/subtitle)

## In-app purchases

Create one subscription group named `Bhakti Angan Pro`.

| Product | Type | Product ID | Suggested US price |
| --- | --- | --- | --- |
| Pro Monthly | Auto-renewable subscription | `in.bhaktiangan.app.pro.monthly` | $4.99 |
| Pro Annual | Auto-renewable subscription | `in.bhaktiangan.app.pro.yearly` | $29.99 |
| Pro Lifetime | Non-consumable | `in.bhaktiangan.app.pro.lifetime` | $39.99 |

Use localized, country-specific pricing rather than currency conversion. Suggested
India launch: ₹149 monthly, ₹999 annual (7-day trial), ₹1,499 lifetime. See the
pricing table in `Docs/APP_STORE_METADATA.md`. Review proceeds, conversion, and
refund behavior before changing pricing.

### Free trial (annual)

The annual product is set up for a **7-day free introductory offer**. The local
`Subscriptions.storekit` file already contains it; in App Store Connect you must
add the matching offer on the annual subscription:

- Introductory Offer → Free → Duration: 1 week → Territories: all.
- New subscribers only (standard).

The paywall reads this automatically: the annual row shows "7-day free trial",
the primary button reads "Start Free Trial", and the disclosure explains that
the trial converts to a paid subscription unless cancelled. If you remove the
offer in App Store Connect, the button falls back to "Continue" with no code
change. This trial is the single biggest conversion lever — keep it on unless
you have a specific reason not to.

### Required paywall disclosures (Guideline 3.1.2)

The paywall already presents, on the purchase screen itself: title and duration
of each plan, price, an auto-renew/trial disclosure, **Terms of Use**, and
**Privacy Policy** links. Do not remove these — missing functional Terms and
Privacy links on the paywall is the most common subscription rejection. The
Privacy Policy link must resolve to your hosted HTTPS page once published.

For each product:

- Add display name and description.
- Add the required review screenshot of the paywall.
- Set availability by territory.
- Finish Paid Apps agreements, banking, and tax information.
- Submit the products with the first app version.

## App privacy

Version 1.0 is designed to declare:

- Data used to track you: No
- Data linked to the user: No
- Data not linked to the user: No developer-collected data

Apple processes purchases. Favorites, japa counts, deity preference, and
reminder settings remain on device. Revisit the declaration before adding
analytics, accounts, advertising, a backend, or cloud sync.

**Location:** the app may request When-In-Use location for the Panchang
(sunrise/sunset). It is used **only on-device** and never reverse-geocoded,
transmitted, or stored — so it is not "collected" under Apple's definition and
the **Data Not Collected** answer still holds. The bundled city list is the
manual fallback. Be ready to explain this on-device use if App Review asks why
location is requested.

Host the privacy policy on `https://bhaktiangan.com/privacy-policy/` and use that
URL in App Store Connect's App Privacy section and the app's Privacy Policy field.
Support URL: `https://bhaktiangan.com/contact/`; support email:
`support@bhaktiangan.com` (both live).

## Review notes

Suggested reviewer note:

`Bhakti Angan includes a Free tier and StoreKit 2 Pro access. The first free
darshans and three japa mantras are free. Pro unlocks the complete darshan
library and all mantras via auto-renewable subscriptions (monthly, annual with a
7-day free trial) and a non-consumable Lifetime. A local StoreKit configuration
is included for development; production products use the identifiers listed above.
The app does not require an account. All artwork is original devotional art.`

## Screenshots

Capture at minimum:

1. Today screen with the full deity image
2. Darshan library
3. Japa counter
4. Pro paywall
5. Reminder/settings screen

Use current App Store Connect screenshot dimensions when uploading. Do not put
pricing into screenshot artwork because localized prices vary.
