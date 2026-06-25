# Bhakti Angan — In-App Purchase setup (click-by-click)

How to create the Pro products in App Store Connect, including the 7-day free
trial. The **prices and product IDs below are the exact ones already wired into
the app** — use them verbatim so the paywall matches.

> **Product IDs can never be changed once created. Type them exactly.**

## The three products

| Plan | Where in ASC | Type | Product ID | Price (US) | India |
| --- | --- | --- | --- | --- | --- |
| **Monthly** | Subscriptions | Auto-renewable | `in.bhaktiangan.app.pro.monthly2` | **$4.99 / mo** | ₹149 |
| **Annual** | Subscriptions | Auto-renewable (+ 7-day free trial) | `in.bhaktiangan.app.pro.yearly` | **$29.99 / yr** | ₹999 |
| **Lifetime** | In-App Purchases | Non-Consumable (one-time) | `in.bhaktiangan.app.pro.lifetime` | **$39.99** | ₹1,499 |

Monthly + Annual are **subscriptions** and live together in one **subscription
group**. Lifetime is a **non-consumable** and lives in a *different* part of the
sidebar. That's the one thing people trip on — they're created in two places.

> Prerequisite: **Agreements, Tax, and Banking → Paid Apps agreement = Active**
> (App Store Connect → Business). Until it's Active you can't create paid products.

---

## Part A — Monthly + Annual subscriptions

App Store Connect → **My Apps → Bhakti Angan → Subscriptions** (left sidebar,
under "Monetization").

### A1. Create the subscription group (once)
1. Click **Create** (or the **+**) next to *Subscription Groups*.
2. **Reference Name:** `Bhakti Angan Pro` → **Create**.
   *(The group is what lets a customer move between Monthly and Annual — only one
   is active at a time.)*

### A2. Add the Monthly subscription
1. Inside the `Bhakti Angan Pro` group → **Create Subscription**.
2. **Reference Name:** `Bhakti Angan Pro Monthly`
   **Product ID:** `in.bhaktiangan.app.pro.monthly2` → **Create**.
   > Note: the original `...pro.monthly` was created then deleted, and Apple
   > reserves Product IDs permanently — so we use `...pro.monthly2`. This matches
   > the app code; do not use the old `...pro.monthly`.
3. **Subscription Duration:** `1 Month`.
4. **Subscription Prices** → **Add Subscription Price** →
   - Country: **United States** → price **$4.99** → **Next**.
   - ASC proposes equivalent prices for every other country. Either **Confirm**
     as-is, or set **India = ₹149** (and other low tiers per
     `APP_STORE_METADATA.md`) before confirming.
5. **App Store Localization** (English U.S.):
   - **Display Name:** `Bhakti Angan Pro (Monthly)`
   - **Description (≤55 chars):** `Full darshan library, all mantras, unlimited saves`
6. **Review Information → App Store Promotion / Review Screenshot:** upload
   `Docs/Screenshots/v1/05-paywall.png` (a purchase screenshot is required).
7. **Save.**

### A3. Add the Annual subscription
Same group → **Create Subscription** again:
1. **Reference Name:** `Bhakti Angan Pro Annual`
   **Product ID:** `in.bhaktiangan.app.pro.yearly` → **Create**.
2. **Subscription Duration:** `1 Year`.
3. **Subscription Prices:** United States **$29.99** → Next → confirm worldwide
   (India **₹999**).
4. **Localization (en-US):**
   - **Display Name:** `Bhakti Angan Pro (Annual)`
   - **Description (≤55 chars):** `Best value: full year of darshan, mantras, saves`
5. **Review Screenshot:** `05-paywall.png`.
6. **Save.**

### A4. Group display name + ranking
- In the group, set the **Subscription Group Display Name** (shown on the App
  Store) to `Bhakti Angan Pro` if prompted.
- **Ranking / levels:** put **Annual above Monthly** (higher level). This only
  affects how upgrades/downgrades prorate; it does not change the paywall.

---

## Part B — the 7-day free trial (this is the part to get right)

The free trial is an **Introductory Offer** attached to the **Annual**
subscription. (Introductory Offer = the one-time perk for *new* subscribers.
Don't use "Promotional Offers" — those are for win-back/existing customers.)

1. ASC → **Subscriptions** → group `Bhakti Angan Pro` → click the **Annual**
   subscription (`in.bhaktiangan.app.pro.yearly`).
2. Find the **Introductory Offers** section (under Subscription Prices; may be
   labeled *"View all Subscription Pricing → Introductory Offers"*).
3. Click **Set Up Introductory Offer** (the **+**).
4. Fill in:
   - **Countries or Regions:** *All Countries or Regions.*
   - **Start Date:** today &nbsp;·&nbsp; **End Date:** **None** (run indefinitely).
   - **Type of Offer:** **Free.**
   - **Duration:** **1 Week.**
   *(Eligibility is automatically "new subscribers" — only customers who have
   never had this subscription get the free week.)*
5. **Confirm / Create.**

Result: the in-app paywall shows **"Start Free Trial"** and *"7-day free trial,
then $29.99/yr (≈ $2.50/mo)."* That copy is driven off this offer, so it must
exist for the wording to be truthful at review.

> Monthly has **no** trial by design (keeps it a simple impulse plan and steers
> trials toward the higher-value Annual). Leave Monthly with no introductory offer.

---

## Part C — Lifetime (non-consumable, separate place)

App Store Connect → **My Apps → Bhakti Angan → In-App Purchases** (NOT
Subscriptions).
1. **Create / +** → Type: **Non-Consumable**.
2. **Reference Name:** `Bhakti Angan Pro Lifetime`
   **Product ID:** `in.bhaktiangan.app.pro.lifetime` → **Create**.
3. **Price:** United States **$39.99** → confirm worldwide (India **₹1,499**).
4. **Localization (en-US):**
   - **Display Name:** `Bhakti Angan Pro (Lifetime)`
   - **Description (≤55 chars):** `Unlock the complete collection forever`
5. **Review Screenshot:** `05-paywall.png`.
6. **Save.**

---

## Part D — submit them with the app

The first time, IAPs/subscriptions are reviewed **together with the app version**:
1. Go to the **1.0 version page**.
2. In the **In-App Purchases / Subscriptions** section on that page, make sure all
   three products are added/selected (if there's an "Add" control, add them).
3. When you **Submit for Review**, the three products submit with the build.
   Their status moves *Ready to Submit → Waiting for Review* alongside the app.

### Quick verify
- [ ] Group `Bhakti Angan Pro` exists with Monthly + Annual.
- [ ] Product IDs match exactly (monthly / yearly / lifetime).
- [ ] Annual has a **Free, 1-Week, All Countries** introductory offer.
- [ ] Lifetime exists as a Non-Consumable.
- [ ] Each product has a price, a localized name/description, and the paywall
      review screenshot.
- [ ] All three appear on the 1.0 version page before you submit.
