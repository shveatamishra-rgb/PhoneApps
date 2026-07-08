# v1.2 release checklist (working doc)

Scope source: `ROADMAP_v1.2.md`. Target: first build submitted before Navratri
(Oct 11), so the verse widget rides the year's biggest devotional moment.
Content work starts now; build work starts once v1.1 is approved.

## Stage 1 · Content authoring (start now, no build needed)

- [ ] Gita verse dataset, chapter 1 + 20 "greatest hits" verses (2.47, 2.13,
      4.7-4.8, 9.22, 18.66, etc.): Devanagari + transliteration + EN meaning +
      HI meaning + one-line "live it today". JSON matching stories.json pattern.
- [ ] Native-speaker review pass on all HI verse meanings (same bar as app copy).
- [ ] Long-form Krishna story, Hindi authored version (web + future in-app).
- [ ] Shiva long-form draft (needed on web before Shravan ends anyway).
- [ ] Devi long-form draft (before Navratri).
- [ ] Commission brief for 2-3 owned audio tracks (japa chant + ambient aarti),
      artists in India, full buyout, credits line agreed ("recorded for Bhakti
      Angan").

## Stage 2 · Website (independent of app review)

- [ ] /bhagavad-gita/ pillar page EN + HI (Polylang pair) using the verse dataset.
- [ ] Chapter 1 page + per-verse anchors; "Aaj ka Shlok" block on homepage.
- [ ] Newsletter opt-in block added to story pages + /panchang/.
- [ ] Gallery: Katha tab + auto-fit phone wallpaper downloads.
- [ ] First newsletter when list >= 100 subs (copy in MARKETING_EXECUTION_PACK.md).

## Stage 3 · App build — BUILT 2026-07-07 (local; not submitted)

Order matched review risk, lowest first. All committed to main (bc74837,
0039d74, fae46bc), all 28 tests pass on a clean manifest cache.

- [x] Verse dataset bundled (verses.dataset, 25 famous Gita shlokas, 9 free /
      16 Pro) + `Verse` model (DevotionalContent.swift) + `VerseCatalog`.
      **DRAFT: EN/HI meanings + translit still need scholar/native review.**
- [x] "Today's Shlok" card on Today tab (free daily verse; taps into library).
- [x] Verse library screen (VerseLibraryView: featured today, search, theme
      chips, Saved filter, detail with save + share). Free vs Pro mirrors darshan.
- [x] Daily Shlok widget in DarshanWidgetExtension (small/medium/large + lock
      screen). VerseBridge writes 7 days to App Group. Widget #3 in WidgetBundle.
      Verified: verse_timeline.json written on launch. **On-device check: add the
      widget from the gallery and confirm it renders (text-only, no black-render
      risk).**
- [x] Intent onboarding: "What brings you here" multi-select before the ishta
      grid; stored in AppState.onboardingIntents; personalizes first landing tab.
- [x] "Your Practice" card in Settings (streak, best streak, shloks saved,
      favorites). On-device counters only.
- [x] Settings support row: "Write to us" (EN/HI) + nav title.
- [x] Share-as-card (VerseShareCard, ImageRenderer) — the research growth loop.
- [ ] **Version bump: DO NOT bump to 1.2 yet.** The binary is still 1.1(3) so it
      does not collide with the in-review v1.1 resubmit. Bump to 1.2(1) (both
      targets, widget MARKETING_VERSION matches) only once v1.1 has shipped.

## Stage 4 · Verification (the v1.1 lessons, do not skip)

- [ ] Widget images/data at scale=1; verify no black renders on device.
- [ ] Verse widget visible in widget picker on device (deployment target 17.0).
- [ ] All three widgets correct after 24h without opening the app.
- [ ] EN + HI sweep of every new screen (verse text renders Devanagari
      correctly at all Dynamic Type sizes).
- [ ] Em-dash grep over all new user-facing strings + ASC copy.
- [ ] Iconography/content gate: every verse translation read end-to-end before
      bundling (same bar as the image gate).
- [ ] RemoteCatalogTests + new VerseCatalog tests pass; full sim build clean.

## Stage 5 · App Store Connect

- [ ] New 6.9" screenshots: add ONE new panel (verse widget on home screen +
      Today's Shlok) rather than redoing all; reorder so it's panel 2 or 3.
      EN + HI. Same beautify pipeline (CoreText for HI headlines).
- [ ] What's New 1.2 EN/HI: verse widget + Gita library + practice card lead.
- [ ] Description: add a GITA & SHLOKAS section; promotional text swap.
- [ ] Review notes: verse content is bundled, public-domain scripture with our
      own translations; no network change; privacy label unchanged.
- [ ] Submit with build 1.2 (1); build number is single-use, bump if re-upload.

## Standing gates (every release)

- [ ] No third-party platform names in metadata (2.3.10).
- [ ] No "Allow"-style pre-permission buttons (5.1.1(iv)).
- [ ] No prices baked into screenshots.
- [ ] Privacy label stays "Data Not Collected" (no new SDKs, no identifiers).
- [ ] Paywall terms/legal machinery untouched (3.1.2(c) approved as-is).
