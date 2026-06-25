# Bhakti Angan — App Store submission runbook (v1.0)

Everything needed to submit, in order, with the exact value for every field.
Paste-ready copy (description, keywords, etc.) lives in `APP_STORE_METADATA.md`;
this file is the step-by-step + where each value goes.

**Gate before you start:** `support@bhaktiangan.com` must receive mail, and
`bhaktiangan.com/privacy-policy/`, `/terms-of-use/`, `/contact/` must all load.
All three are live. ✅

---

## 0 · Apple Developer prerequisites (one-time)
- Apple Developer Program membership active (Team `45QWJVLL5D`).
- **Agreements, Tax, and Banking** (App Store Connect → Business): the **Paid
  Apps** agreement must be **Active**, with banking + tax forms complete —
  otherwise the IAPs can't be submitted. Do this first; it can take a day.
- Bundle ID `in.bhaktiangan.app` is registered. ✅

---

## 1 · Create the app record
App Store Connect → **My Apps → + → New App**

| Field | Value |
| --- | --- |
| Platform | iOS |
| Name | `Bhakti Angan: Daily Darshan` |
| Primary language | English (U.S.) |
| Bundle ID | `in.bhaktiangan.app` |
| SKU | `BHAKTI-ANGAN-IOS-001` |
| User access | Full Access |

---

## 2 · In-app purchases (do before submitting the version)
> **Full click-by-click steps (incl. the 7-day free trial) are in
> `IAP_SETUP_STEPS.md`.** The summary below is the overview.

App Store Connect → your app → **Monetization → In-App Purchases** (and
**Subscriptions**).

Create a subscription group: **`Bhakti Angan Pro`**, then:

| Product | Type | Product ID | US price | India price |
| --- | --- | --- | --- | --- |
| Pro Monthly | Auto-renewable subscription | `in.bhaktiangan.app.pro.monthly2` | $4.99 | ₹149 |
| Pro Annual | Auto-renewable subscription | `in.bhaktiangan.app.pro.yearly` | $29.99 | ₹999 |
| Pro Lifetime | Non-consumable | `in.bhaktiangan.app.pro.lifetime` | $39.99 | ₹1,499 |

For **each** product:
- Reference name (internal) + a localized **display name** and **description**
  (e.g. Annual → "Bhakti Angan Pro (Annual)" / "Full darshan library, every mantra,
  unlimited saves, and festival collections.").
- **Availability:** all territories (then set country pricing — see metadata doc).
- Add the **review screenshot**: use `Docs/Screenshots/v1/05-paywall.png`.

**Annual free trial:** on the Annual subscription → **Introductory Offer → Free →
Duration 1 week → Territories: all → New subscribers**. This is what makes the
paywall read "Start Free Trial". Keep it on.

Set **country-specific pricing** (not currency conversion) per the table in
`APP_STORE_METADATA.md` (India + nearby low tiers; Tier-1 at standard pricing).

---

## 3 · Version 1.0 — metadata (paste from `APP_STORE_METADATA.md`)
App Store Connect → your app → **iOS App → 1.0 → (the version page)**

| Field | Value / source |
| --- | --- |
| Promotional text (170) | from metadata doc |
| Description (4000) | from metadata doc |
| Keywords (100) | `choghadiya,muhurat,japa,shiva,krishna,ganesha,ram,hanuman,devi,lakshmi,aarti,puja,wallpaper,temple` |
| Subtitle (30) | `Hindu Gods, Mantra & Panchang` |
| Support URL | `https://bhaktiangan.com/contact/` |
| Marketing URL | `https://bhaktiangan.com/` |
| Version | `1.0` |
| Copyright | `2026 Bhakti Angan` |
| What's New | from metadata doc (only needed for updates; fine to fill now) |
| Sign-in required? | No |

**App information** (left sidebar → App Information):
- Subtitle (if not set on the version page): as above.
- **Category:** Primary **Lifestyle**, Secondary **Health & Fitness** (or Reference).
- **Content rights:** "Does not use third-party content" (artwork is original).
- **Privacy Policy URL:** `https://bhaktiangan.com/privacy-policy/`

---

## 4 · Screenshots
Version page → **Previews and Screenshots → iPhone 6.9"**. Upload from
`Docs/Screenshots/v1/` (all are 1320 × 2868):

`01-today` → `03-japa` → `02-darshan` → `05-paywall` → `06-today-dark` → `04-settings`

(6.9" is the only required size; ASC scales it down for other devices. Captions optional.)

---

## 5 · App Privacy (the nutrition label)
App Store Connect → your app → **App Privacy → Get Started / Edit**
- **"Do you or your third-party partners collect data from this app?"** → **No**.
  - The app stores favorites/japa/streak/reminders **on-device only**; the Panchang
    location is used **on-device only** and never transmitted; purchases are handled
    by Apple. None of this is "collected" under Apple's definition.
  - (Google Analytics named in the privacy policy is the **website**, not the app.)
- Result label: **Data Not Collected**. Matches `PrivacyInfo.xcprivacy`.

---

## 6 · Age rating
App Information → **Age Rating → Edit** → answer all categories **None / No**.
Devotional/religious content carries no rating penalty → **4+**.

---

## 7 · Build — archive & upload (Xcode)
On the Mac with Xcode:
1. Open `iPhone/BhaktiAngan/BhaktiAngan.xcodeproj`.
2. Target → **Signing & Capabilities**: "Automatically manage signing" ON, Team
   = your team (`45QWJVLL5D`). Bundle ID `in.bhaktiangan.app`.
3. Confirm **Version 1.0 / Build 1** (already set).
4. Select destination **Any iOS Device (arm64)**.
5. **Product → Archive**. When it finishes, in the Organizer:
   **Distribute App → App Store Connect → Upload**.
6. Export compliance: the app sets `ITSAppUsesNonExemptEncryption = false`, so
   you won't be asked about encryption.
7. Wait for the build to finish **processing** in App Store Connect (5–30 min).

---

## 8 · Attach build + submit
Version 1.0 page:
1. **Build** section → **+** → select the processed build (1.0 / 1).
2. **App Review Information:**
   - Sign-in required: **No** (no demo account needed).
   - Contact: your name, phone, `support@bhaktiangan.com`.
   - **Notes:** paste the "App Review notes" block from `APP_STORE_METADATA.md`
     (explains Free/Pro, no account, bilingual, on-device Panchang location, original art).
3. **Version Release:** "Automatically release" (or manual — your choice).
4. **Add for Review → Submit**. Submitting the version submits the 3 IAPs with it.

---

## 9 · Pre-submit checklist
- [ ] Paid Apps agreement Active; banking + tax done.
- [ ] 3 IAPs created with the exact product IDs; annual has the 1-week free trial.
- [ ] Country pricing set (India tier + global).
- [ ] Name, subtitle, keywords, promo, description filled.
- [ ] Privacy Policy URL + Support URL set; `support@bhaktiangan.com` monitored.
- [ ] 6.9" screenshots uploaded.
- [ ] App Privacy = Data Not Collected; Age rating 4+.
- [ ] Build 1.0 (1) uploaded, processed, and attached.
- [ ] Review notes pasted.

---

## 10 · Things already handled in the binary (so review goes smoothly)
- Paywall shows plan/price/auto-renew disclosure + **Terms and Privacy links**
  (the #1 subscription-rejection cause — covered).
- `PrivacyInfo.xcprivacy` present (UserDefaults reason declared, no tracking).
- `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryAddUsageDescription`
  usage strings present and honest.
- No account/login; Restore Purchases present; original artwork only.

> After approval: see `POST_LAUNCH_PLAYBOOK.md` for launch-day steps and the
> promo video. v1.1 plan (voice japa) and the rest of the roadmap are in `ROADMAP.md`.
