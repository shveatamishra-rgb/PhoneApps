# App Store Connect Setup

## App record

- Name: `Divine Stillness Om`
- Bundle ID: `com.shveatamishra.divinestillness`
- SKU suggestion: `DIVINE-STILLNESS-OM-IOS-001`
- Primary category: Lifestyle
- Secondary category: Health & Fitness
- Age rating: complete the questionnaire; the current content is intended for 4+

Suggested subtitle:

`Daily Darshan, Mantra & Japa`

Suggested promotional text:

`Begin each day with a peaceful darshan, a simple mantra, and one quiet minute
of devotion. Explore Shiva, Ganesha, Krishna, Ram, Devi, Vishnu, and more.`

Suggested keywords:

`hindu,gods,darshan,mantra,japa,shiva,krishna,ganesha,ram,hanuman,puja,bhakti`

## In-app purchases

Create one subscription group named `Divine Stillness Pro`.

| Product | Type | Product ID | Suggested US price |
| --- | --- | --- | --- |
| Pro Monthly | Auto-renewable subscription | `com.shveatamishra.divinestillness.pro.monthly` | $4.99 |
| Pro Annual | Auto-renewable subscription | `com.shveatamishra.divinestillness.pro.yearly` | $29.99 |
| Pro Lifetime | Non-consumable | `com.shveatamishra.divinestillness.pro.lifetime` | $39.99 |

Use localized India pricing rather than a direct currency conversion. A starting
test is INR 99 monthly, INR 599 annual, and INR 999 lifetime. Review proceeds,
conversion, and refund behavior before changing pricing.

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

Host `Docs/PRIVACY_POLICY.md` on a public HTTPS page and use that URL in App
Store Connect. Add a real support URL and support email before submission.

## Review notes

Suggested reviewer note:

`The app includes a Free tier and StoreKit 2 Pro access. The first 12 darshan
images and three japa mantras are free. Pro unlocks the complete 60-image
library and all mantras. A local StoreKit configuration is included for
development; production products use the identifiers listed above. The app
does not require an account.`

## Screenshots

Capture at minimum:

1. Today screen with the full deity image
2. Darshan library
3. Japa counter
4. Pro paywall
5. Reminder/settings screen

Use current App Store Connect screenshot dimensions when uploading. Do not put
pricing into screenshot artwork because localized prices vary.
