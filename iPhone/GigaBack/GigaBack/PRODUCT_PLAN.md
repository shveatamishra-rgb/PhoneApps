# Photo Cleaner Overhaul — Product & Revenue Plan

> Research-backed plan to turn the existing on-device duplicate scanner into a revenue-maximizing
> iOS photo/storage cleaner. Deep-research run 2026-07-05 (5 angles, 21 sources, 25 claims verified
> adversarially, 16 confirmed). Citations inline; killed claims noted so we don't act on them.

## 1. The market is real and large (act on this)

- The **top 10 storage-cleaner apps grossed ~$197M in 2024** and were on track to roughly double in
  2025 (already >half by month 5). [Appfigures, 2025-06](https://appfigures.com/resources/insights/20250606?f=1) — *confirmed 3-0.*
- Consumers spent **~$40M in a single recent month**; **161 cleaner apps grossed >$1K/mo, 42 >$100K, 7 >$1M.** Same source — *confirmed 3-0.* This is a long tail: you do not need to be #1 to make real money.
- **>95% of category revenue is on the App Store** (~1,500 cleaner apps across both stores). *Confirmed 3-0.* iOS-first is correct.
- Top 10 earners: **Cleanup, Cleaner Guru, AI Cleaner, Cleaner Kit, Swipewipe, Phone Cleaner, Powerful Cleaner, Cleanup App, Cleaner, Cleaner AI.** *Confirmed 3-0.* Note the naming pattern — every winner is literally named "Cleaner/Cleanup," not "Duplicate Finder."

**Implication:** the current name *Duplicate Image Finder* is a niche feature name in a category that sells on the word **"Cleaner."** Rename.

## 2. What the winners actually are

- **Cleanup: Phone Storage Cleaner** — category leader, **4.7★ across 676K ratings.** *Confirmed 3-0.* Feature set (from its own listing, confirmed 3-0): duplicate photo/video removal, look-alike/similar detection, large-video cleanup, plus swipe review. Subscription: **$7.99/week or $29.99/year, 7-day trial** (extractor-level; the specific weekly figure was killed only on wording, the sub-not-lifetime model is solid).
- **Swipewipe** — the **swipe-to-keep/delete triage** pattern (Tinder-for-photos). Live listing shows **multiple weekly tiers from $4.99 + a premium tier.** *Confirmed.* (Its $400K/mo revenue + "rank 15" stat was **killed 0-3** — do not cite it.)
- **Gemini Photos / CleanMy Phone (MacPaw)** — free tier only *monitors* (screenshots, blurred, notes); the actual **dedupe is paywalled at ~$5/mo.** The **dominant 1-star theme across the category is the hard paywall / subscription trap.** *Confirmed 3-0.*
- **Clever Cleaner** — the cautionary contrast: **completely free, no ads, no IAP, and rated 4.8★ / 74K** — *higher than the paid leader.* *Confirmed 3-0.* A fully-free competitor exists and users love it; our paid tier has to feel genuinely worth it, not extractive.

## 3. Monetization — what the evidence supports

- **Model: auto-renewing subscription is the category default and earns the most.** Every top-10 earner monetizes via subscription; lifetime exists only as a high-anchor secondary option.
- **Price points (from a 1,200-paywall teardown, confirmed 2-1):** weekly clusters at **$4.99 / $5.99 / $6.99 / $9.99**; annual ranges **$35.99–$99.99** with no consensus. [PaywallPro](https://dev.to/paywallpro/subscription-pricing-in-photo-video-apps-what-1200-paywalls-reveal-3ok9)
- **Free trials are typically 3-day.** *Confirmed 2-1.*
- **The "moment of success" paywall claim was killed 0-3** — meaning in *cleaners* specifically the **hard paywall after the first scan (show "X GB reclaimable", gate the delete)** is the norm, not the moment-of-export pattern from photo-editor apps. That is the pattern to copy, but softened (see §4).

**Recommended pricing ladder:**
| Tier | Price | Role |
|---|---|---|
| Weekly | $4.99 (3-day free trial) | Impulse / low-commitment entry |
| Annual | $29.99 | The value anchor we actually push |
| Lifetime | $49.99 | High anchor that makes annual look cheap; also de-risks "subscription trap" 1-stars |

## 4. Free-vs-Pro split — earn without tanking ratings

The category's 1-star reviews punish exactly one thing: **paying and getting nothing, or being tricked into a weekly charge.** Clever Cleaner proves a generous free tier can still hit 4.8★. So: **give away enough that the app is genuinely useful and clearly works, gate the bulk/convenience.**

**Free (must feel complete):**
- Full scan of the whole library (never fake the count).
- See *all* duplicate/similar groups and the total reclaimable GB.
- Delete duplicates **manually, one group at a time** (proves the app works — this is what earns the good rating).
- Swipe triage on **screenshots** (one free category).

**Pro (the convenience + scale):**
- **One-tap "Smart Clean"** / bulk delete across all groups at once.
- Similar/burst photo sets, blurry-photo detection, large-video cleanup, live-photo compression.
- Swipe triage on all albums, not just screenshots.
- Monthly auto-scan reminder + storage widget.

This mirrors Gemini's split (free = surface the problem, pay = fix it at scale) but **without hiding that the free tier can delete** — that single concession is the difference between 4.7★ and the 1-star pile.

## 5. Feature roadmap

**v1 (ship the rename + paywall on top of what exists):**
1. Duplicate + pixel-identical + look-alike (already built).
2. Screenshot detection & swipe triage (high perceived value, easy — screenshots are already flagged in the scanner).
3. Large-video finder (PhotoKit gives byte sizes cheaply).
4. Reclaimable-GB meter + scan-progress theatre + before/after storage bar.
5. Paywall after first scan (hard-gate bulk delete, free single-group delete).

**v1.1–v2 (drive upgrades):**
- Blurry-photo detection (reuse the luma signature already in `ImageFingerprint`).
- Similar/burst grouping surfaced as its own tab.
- Live-photo → still and video compression (real storage wins, strong Pro hook).
- Auto-scan + Home Screen storage widget (retention → renewal).

**Later / evaluate:** contact dedupe, secret vault. These are cross-sell gimmicks in most cleaners; add only if reviews ask. Email/calendar spam is out of scope (different app).

## 6. Naming & ASO

- Title cap **30 chars**, subtitle **30**, keyword field **100.** *Confirmed 3-0* (Apple docs). (The "title keyword = 2.4x rank / highest-weighted signal" claim was **killed** — real, but don't quote the multiplier.)
- Winners rank on multi-word **"X cleaner"** phrases (photo cleaner, storage cleaner, gallery cleaner, photo library cleaner). The word **"Cleaner"** in the title is table stakes.

**Name availability check (iTunes Search API, 2026-07-05):** the category is a copycat farm.
Every generic pattern is claimed multiple times, mostly by zero-rating clones: SwipeClean (x5),
PhotoSweep (x4), CleanSweep (x3), TidyPix (x3), DupeSweep, Pixelbroom, Declutterly, FreeUp: Photo
Cleaner, Photo Purge, SnapTidy, "Reclaim: Phone Storage Cleaner" (1 rating). Naming into those
clusters means drowning among clones and risking 4.1 copycat friction.

**Verified unclaimed as of 2026-07-05:** `GigaBack` (zero App Store hits in any category) and
`PhotoVac` (unclaimed within the cleaner category).

**Recommended name:**
- **Title:** `GigaBack: Photo Cleaner` (23 chars; distinctive brand + the category's core keyword).
- **Subtitle:** `Delete Duplicates, Free Space` (29 chars).
- **Tagline / listing hook:** "Get your gigabytes back."
- **Keywords field:** storage,duplicate,similar,screenshot,blurry,swipe,compress,video,gallery,space
- Runner-up if GigaBack is taken by launch time: `PhotoVac: Storage Cleaner`.

## 7. Premium-feel UX

- **Onboarding:** 2-3 slides framing the pain ("You have 3,412 duplicates"), permission primer *before* the system prompt (already a known App Store gotcha — no "Allow" on the pre-prompt button).
- **Scan theatre:** animated progress + live running "GB reclaimable" counter as groups are found. This is the emotional hook the paywall converts on.
- **Before/after storage bar** post-clean.
- **Swipe triage** for the Tinder-for-photos crowd (Swipewipe's whole business).

## 8. App Store review risk (Guideline 3.1.2)

- 3.1.2 is App Review's **catch-all for paywall design.** *Confirmed 3-0.* Enforcement is inconsistent.
- **To pass:** subscription **price + length must be prominent** (contrast/font size), with functional **Terms + Privacy** links on the paywall *and* in metadata. *Confirmed 3-0.*
- **Never overstate reclaimable storage** — misleading "X GB" claims draw both rejections and 1-stars. Show the real number only.
- **No external payment links** (Stripe-in-Safari = rejection). StoreKit only — which we already use.
- Keep a genuinely useful free tier: it defuses "does nothing without paying" 3.1.2 rejections *and* the 1-star trap complaints simultaneously.

## Open questions / caveats
- Revenue figures are single-vendor (Appfigures) estimates; treat as directional.
- No confirmed per-app revenue for a *pure* photo cleaner (vs. general storage cleaner).
- Sensor Tower pages returned no usable data this run.
