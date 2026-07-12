# Ferry — Growth & Monetization Plan (v1)

*Market-researched plan to take Ferry to the next level and maximize Pro revenue.
Based on a deep-research pass (competitor teardown + monetization benchmarks + Apple
rules), July 2026. Direction set by owner: broaden to all file types · keep local-first
by default with optional cloud as premium · pick the best-revenue model.*

Sources are listed at the bottom and cited inline as `[n]`. Claims are graded:
**[verified]** = passed adversarial 3-vote check; **[directional]** = single credible
source, not independently re-verified.

---

## TL;DR — the recommendation

**Go hybrid, and stop underpricing.** The winning structure for this category is a
three-tier model (this is exactly what **PhotoSync**, Ferry's closest analog, runs) [1]:

1. **Free** — genuinely useful local photo/video transfer (must stay good, because the
   free open-source **LocalSend** does cross-platform all-file transfer for $0 [8]).
2. **Ferry Pro (one-time Lifetime)** — raise from **$2.99 → ~$6.99**. Unlocks *all file
   types*, unlimited, folders, no ads ever. A one-time price is correct here because these
   are static, local features with no ongoing cost, and Apple discourages subscriptions
   for static unlocks [11].
3. **Ferry Cloud (subscription)** — **~$2.99/mo or $19.99/yr** with a 7-day trial. Cloud
   backup, remote/off-network transfer, share-links, background auto-backup. A
   subscription is *justified and Apple-compliant* here because cloud/SaaS has genuine
   ongoing value — Apple explicitly lists "cloud support" and "SAAS" as valid subscription
   use cases [12].

**Why hybrid, not one or the other:** subscriptions are only ~4% of apps but ~45% of app
revenue [directional], and one-time purchases are a small (10.3%) but *growing* slice of
sub revenue [3][verified]. A pure subscription on a "transfer files then leave" utility
invites brutal churn (utility/AI apps churn ~16%/mo [directional]) and backlash (LocalSend
is free). A pure one-time unlock leaves the recurring cloud money on the table. Hybrid
captures the "just let me pay once" buyer *and* the recurring cloud power-user.

---

## 1. Market snapshot (who you're up against)

| App | Model | Price (verified where cited) | Notes |
|---|---|---|---|
| **PhotoSync** | 3-tier hybrid | Pro = one-time lifetime; Premium = lifetime **or** monthly/yearly sub + free trial [1] | Closest analog. Free = reduced-quality only; Pro = unlimited full-quality + RAW/HEIC; Premium adds background auto-backup [1][6]. **Copy this structure.** |
| **Simple Transfer** | freemium + IAP tiers | **Yearly $19.99 · Lifetime Premium $49.99 · Lifetime $69.99** [2] | Free = 10 items, then only oldest 50 per album [2]. Proves the market bears **far** more than $2.99, and validates a lifetime-cap free gate like Ferry's. |
| **Send Anywhere** | freemium + ads | Free 10 GB / 48-h links; paid unlocks 50 GB [directional] | Link-with-expiry sharing is a proven paid feature. Free tier is ad-supported. |
| **SHAREit / Xender** | freemium + heavy ads | free | Market-leading reach but a **bloatware/adware** reputation, no E2E encryption [directional]. This is the gap Ferry exploits. |
| **LocalSend / PairDrop** | 100% free, open-source | $0 [8] | The free baseline: cross-platform (5 platforms), all file types, local-only. **Ferry's paid tier must offer what LocalSend can't** — polished native Photos UX + cloud/remote. |
| **AirDrop / Quick Share** | free, OS-native | $0 | Fast and free but single-ecosystem. Ferry's wedge = cross-ecosystem. |

**Strategic read:** the paid opportunity is *not* "charge for basic local transfer"
(LocalSend/AirDrop give that away). It's **(a)** a cleaner, no-ads, privacy-first,
Photos-native experience vs the adware incumbents, and **(b)** cloud/remote/backup
features the free local-only tools don't have.

---

## 2. What users actually pay for (high-demand features)

From competitor gating + review demand:
- **No ads / no bloatware** — the #1 emotional differentiator vs SHAREit/Xender/Send Anywhere [directional].
- **All file types + folders** — table stakes for "real" transfer apps (decided ✓).
- **Unlimited / no item caps** — the classic freemium wall (Simple Transfer, PhotoSync) [1][2].
- **Full quality / metadata preserved** — Ferry already wins here; PhotoSync gates
  full-quality + RAW/HEIC behind Pro [1].
- **Background & automatic backup** — PhotoSync puts auto/background backup behind its
  paid Premium tier [6][verified]. Strong paid signal.
- **Cloud / remote (off-network) transfer + share links** — Send Anywhere's core paid hook.
- **Encryption / security** — incumbents lack E2E; Ferry's PIN + local + (future) E2E is marketable.
- **Speed** — SHAREit markets "60× Bluetooth"; speed is a headline claim users respond to.
- **Device migration / backup** — high-intent, high-willingness-to-pay moment.

---

## 3. Monetization benchmarks (the numbers that matter)

- **Hybrid is now mainstream:** ~35% of apps mix subscriptions with consumables/lifetime
  purchases [4][verified].
- **Subscriptions dominate revenue, one-time is growing:** weekly plans = **55.6%** of all
  in-app subscription revenue (up from 43.3%); one-time purchases = **10.3%** (up from
  6.4% in 2023) [3][verified]. In *Utilities specifically*, weekly grew to ~74% of app
  revenue [5][verified].
- **Utilities economics are attractive:** median 1-year LTV **$46.30**, best-in-class
  annual retention **22.1%**, and Utilities discount the least (1.2%) — pricing power is
  real [3][verified].
- **Funnel:** ~11.2% install-to-trial and ~27.8% trial-to-paid globally; **weekly plans
  convert 2–7× better than annual** [3][verified].
- ⚠️ **Ignore these** (the research *refuted* them): a specific "$7.48 weekly / $12.99
  monthly / $38.42 annual Utilities median" figure and the "hard paywall 12.11% vs 2.18%"
  stat both failed verification — do not price against them.

**Implication:** a weekly plan maximizes raw revenue, but on a trust-first, anti-bloatware
brand like Ferry a predatory weekly-utility price risks the exact reputation you're selling
against. **Recommend monthly + annual (annual anchored, with trial); optionally test a
low weekly for impulse.**

---

## 4. Recommended model & pricing

| Tier | Type | Price | Free-trial |
|---|---|---|---|
| **Free** | — | $0 | — |
| **Ferry Pro** | one-time non-consumable | **$6.99** (from $2.99) | — |
| **Ferry Cloud** | auto-renewable sub | **$2.99/mo** or **$19.99/yr** | 7 days |
| *(optional)* Ferry Cloud Lifetime | one-time | ~$39.99 | — |

- **Raise the lifetime now.** $2.99 is well below what the market bears (Simple Transfer
  lifetime is $49.99–$69.99 [2]). $6.99 is still "cheap/fair" but ~2.3× the ARPU per buyer.
- Keep **Ferry Pro as one-time** (all-file-types + unlimited local = static features →
  Apple prefers non-subscription for these [11][12]).
- Put **only genuinely-recurring-value features in the subscription** (cloud storage,
  relay/remote transfer, share-link hosting, background backup) — this is what makes the
  sub Apple-compliant under 3.1.2(a) [12] and churn-resistant (ongoing value).
- **Bundle:** owning Ferry Pro should discount/credit toward Cloud, or Cloud should
  include Pro — so you never punish an existing lifetime buyer.

---

## 5. Free vs Pro vs Cloud — the split

| Capability | Free | Ferry Pro (one-time) | Ferry Cloud (sub) |
|---|---|---|---|
| Local Wi-Fi transfer, photos & videos | ✅ (generous cap) | ✅ unlimited | ✅ unlimited |
| **All file types** (docs, folders, any file) | — | ✅ | ✅ |
| Full quality + metadata preserved | ✅ | ✅ | ✅ |
| Folder / whole-album transfer | — | ✅ | ✅ |
| No ads, ever | ✅ (Ferry has none) | ✅ | ✅ |
| Priority / max speed | — | ✅ | ✅ |
| **Cloud backup** of received media | — | — | ✅ |
| **Remote / off-network transfer** (relay) | — | — | ✅ |
| **Share links** (password + expiry) | — | — | ✅ |
| **Background / automatic backup** | — | — | ✅ |
| Multi-device / Mac companion | — | ✅ | ✅ |

**Reconsider the free gate.** Today's "50 lifetime transfers" hard-cap on *local* transfer
is risky now that you're competing with free LocalSend [8]. Move the wall: make **local
photo/video transfer generously free**, and gate on **all-file-types + power + cloud**.
That keeps free users (word of mouth, reviews) while the paywall sits on features the free
tools genuinely lack.

---

## 6. Roadmap — tiers

### Quick wins (weeks)
- **All file types** via the Files app / document picker + a share-extension ("Share →
  Ferry"). Biggest scope unlock; matches the decided direction.
- **Folder / multi-album transfer** and a **transfer history** list.
- **Raise price to $6.99**; add the annual/lifetime IAPs in App Store Connect.
- **Rework the free gate** (loosen local cap; paywall all-file-types + power).
- Lead marketing with **"no ads, no account, nothing to the cloud"** — the anti-bloatware
  wedge [directional].

### Next-level (1–3 months) — the revenue engine
- **Ferry Cloud subscription:** cloud backup, **remote/off-network transfer** (a relay
  server so the two phones don't need the same Wi-Fi), **share-links** with expiry +
  password (Send Anywhere's proven hook), **background auto-backup** (PhotoSync's proven
  paid gate [6]).
- **End-to-end encryption** on transfers + marketing it (incumbents lack it).
- **Mac companion** — you already ship **DropBeam** (Mac Wi-Fi transfer); unifying it with
  Ferry (phone ⇄ Mac ⇄ phone) multiplies willingness to pay.

### Moonshots
- **Device migration** ("new phone" full-content mode) — highest-intent paid moment.
- **Continuous folder sync**, team/family plans, a web receiver, an E2E-encrypted cloud
  vault.

---

## 7. Top 5 features most likely to drive Pro revenue

1. **All file types + folders** — converts Ferry from a photo tool into a "real" transfer
   app and unlocks the whole competitive market (and justifies the price raise).
2. **Ferry Cloud subscription** (backup + remote transfer + share links) — the *recurring*
   revenue, and Apple-blessed as a cloud/SaaS subscription [12].
3. **Background / automatic backup** — an independently proven paid gate in this exact
   category [6][verified].
4. **Remote / off-network transfer** — removes Ferry's single biggest limitation (must be
   on the same Wi-Fi) and is inherently subscription-shaped (server cost = ongoing value).
5. **No-ads, privacy-first, E2E positioning** — not a "feature" but the *reason to pay*
   vs free adware incumbents; it's what makes people choose paid Ferry over free LocalSend.

---

## 8. Risks & feasibility

- **Apple 3.1.1** — all unlocks must go through Apple IAP; you may **not** unlock Pro via
  license keys/QR/etc. [11][verified]. (Ferry already uses StoreKit ✓. The QR/PIN is for
  *device pairing*, not feature-unlocking — that's fine, keep it clearly separate.)
- **Apple 3.1.2(a)** — a subscription must deliver *ongoing* value ≥7 days across devices;
  cloud/SaaS qualifies [12][verified]. So never put a *static* unlock (all-file-types)
  behind the sub — keep that in the one-time Pro.
- **Apple 2.3.10** — no Android/other-platform names in metadata [10][verified] (already
  bit you once; keep store copy platform-neutral).
- **LocalSend/AirDrop are free** [8] — do **not** try to charge for bare local transfer;
  differentiate on UX polish + cloud + privacy.
- **Churn** — utility apps churn hard once the job's done. Mitigate: keep the *lifetime*
  option for one-and-done users; reserve the sub for features with continuing value
  (backup that runs monthly, links that stay live, storage).
- **Cloud = new cost + new privacy surface.** The moment you store user files server-side,
  your **App Privacy label stops being "Data Not Collected"** and your privacy policy must
  change. Budget server cost, and keep the *local* path fully offline so the privacy story
  survives for non-Cloud users.
- **iOS background transfer** is limited: sustained background transfers realistically need
  a background `URLSession` (HTTP/S only) and BGTask scheduling — feasible for the cloud
  backup path, but pure peer-to-peer local transfer won't run long in the background
  [directional]. Design the Cloud backup around background `URLSession`.

---

## Sources
1. PhotoSync iOS plans (Pro vs Premium) — https://www.photosync-app.com/support/ios/answers/which-photosync-plan-for-ios-should-i-get **[primary]**
2. Simple Transfer (App Store listing, IAP prices) — https://apps.apple.com/us/app/simple-transfer-photo-video/id420821506 **[primary]**
3. Adapty — State of In-App Subscriptions — https://adapty.io/state-of-in-app-subscriptions-report/ **[primary]**
4. RevenueCat — State of Subscription Apps 2025 — https://www.revenuecat.com/state-of-subscription-apps-2025/ **[primary]**
5. Adapty — Utilities app subscription benchmarks — https://adapty.io/blog/utilities-app-subscription-benchmarks/ **[primary]**
6. PhotoSync Premium (background auto-backup) — https://www.photosync-app.com/premium **[primary]**
8. LocalSend (free, open-source, cross-platform) — https://github.com/localsend/localsend **[primary]**
10. Apple App Review Guidelines (2.3.10) — https://developer.apple.com/app-store/review/guidelines/ **[primary]**
11. Apple Guideline 3.1.1 (IAP required to unlock) — https://developer.apple.com/app-store/review/guidelines/ **[primary]**
12. Apple Guideline 3.1.2(a) (subscriptions need ongoing value; cloud/SaaS valid) — https://developer.apple.com/app-store/review/guidelines/ **[primary]**

*Note: the deep-research run's automated synthesis was cut off by a rate limit; this
report was synthesized by hand from its 14 verified claims + competitor pricing. Claims
about LocalSend specifics and iOS background limits are from primary sources but were not
independently re-verified by the workflow (marked [directional]).*
