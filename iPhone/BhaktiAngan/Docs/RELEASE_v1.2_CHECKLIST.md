# v1.2 release checklist (working doc)

Scope source: `ROADMAP_v1.2.md`. Target: first build submitted before Navratri
(Oct 11), so the verse widget rides the year's biggest devotional moment.
Content work starts now; build work starts once v1.1 is approved.

## Stage 1 · Content authoring (start now, no build needed)

- [ ] Gita verse dataset, chapter 1 + 20 "greatest hits" verses (2.47, 2.13,
      4.7-4.8, 9.22, 18.66, etc.): Devanagari + transliteration + EN meaning +
      HI meaning + one-line "live it today". JSON matching stories.json pattern.
- [ ] Native-speaker review pass on all HI verse meanings (same bar as app copy).
- [x] Long-form deity journeys: ALREADY DONE in EN+HI (discovered 2026-07-07, built
      earlier). Krishna (1080/1327), Shiva (1328/1347), Durga/Devi (1340/1348),
      Ganesha (1349/1372), Rama (1362/1417), Hanuman (1361/HI). Each ~3200-4000
      words: "Who is X" + chapters + glossary + shloka. The old "Shiva/Devi draft"
      lines here were stale.
- [x] **Vishnu long-form ADDED 2026-07-07** (the one missing major deity):
      EN /vishnu/ (1511) + HI /hi/bhagwan-vishnu/ (1512), Polylang-linked. 8
      chapters (Anantashayana, Samudra Manthan/Kurma, Varaha, Narasimha, Vamana,
      Rama/Krishna, Lakshmi-Narayana, the Dashavatar) + glossary + Vishnu dhyana
      shloka + breadcrumbs + related cross-links (Krishna/Rama/Gita/Gallery) +
      app CTA. Builder `112-vishnu.mjs`. Live + verified, 0 em dashes.
- [ ] (optional) Retrofit breadcrumbs + related modules onto the older six
      long-forms for full knowledge-graph parity (site-review ask). Vishnu already
      has them; the others predate that pattern.
- [ ] Commission brief for 2-3 owned audio tracks (japa chant + ambient aarti),
      artists in India, full buyout, credits line agreed ("recorded for Bhakti
      Angan").

## Stage 2 · Website (independent of app review)

- [x] /bhagavad-gita/ pillar EN + /hi/shrimad-bhagavad-gita/ HI (Polylang-linked,
      pages 1503/1504), built from the SAME app verses.json. Hub: breadcrumbs,
      Shlok-of-the-day (client JS), browse-by-theme cards, FAQ, related modules,
      app CTA, JSON-LD. Builder `bhaktiangan-site/110-bhagavad-gita.mjs`. LIVE +
      verified (25 cards, base64 JS parses live, full HI labels).
- [x] "Aaj Ka Shlok" block on homepage (EN page 15 + HI page 383), links to the
      pillar. Builder `111-home-shlok.mjs`, idempotent marker, try/catch-safe.
- [x] "Gita" added to header + footer nav (EN + HI) in the snippet files.
      **OWNER MUST RE-PASTE `site_wide_header_bhaktiangan.php` +
      `site_wide_footer_bhaktiangan.php` into WPCode for the nav to update.**
- [x] Newsletter opt-in block added to 18 pages (7 deity long-forms EN+HI, Gita
      EN+HI, Panchang EN+HI): self-contained `.ba-nl` card, posts to the existing
      Brevo `/gallery-optin` endpoint, honeypot + email validation, lang detected
      by URL `/hi/` prefix (theme sets html lang=en on all pages, so URL is the
      reliable signal). Builder `113-newsletter-optin.mjs`, idempotent marker.
      Also fixed the same lang-detection bug in `111-home-shlok.mjs` (HI homepage
      block now shows Hindi). Serves the 100-subs-before-Shravan goal.
- [x] Breadcrumbs + "Continue your reading" related module retrofitted onto the
      six older long-forms EN+HI (Krishna/Shiva/Durga/Ganesha/Rama/Hanuman), the
      knowledge-graph the site review asked for. Self-contained styles, idempotent.
      Builder `114-retrofit-crosslinks.mjs`. Vishnu + Gita already had them.
- [ ] Gallery: Katha tab + auto-fit phone wallpaper downloads.
- [ ] First newsletter when list >= 100 subs (copy in MARKETING_EXECUTION_PACK.md).
- [ ] **Scholar/native review of the verse translations** (EN + HI) before treating
      the Gita content as final; currently published as index (draft-quality but
      conservative). Flip to noindex if the owner prefers to review first.

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
      UPGRADED 2026-07-07: renders the verse over the Gita Updesh artwork
      (r_krishna_gita, bundled-Krishna fallback) behind a legibility scrim + gold
      frame. Verified in sim (--preview-sharecard hook). Reading surfaces stay
      text-only (correct); only the shareable hero is pictorial.
- [x] Gita website POLISH 2026-07-07: Shlok-of-the-day anchored with an ornament
      divider + inner gold frame + radial glow + Om; verse cards rebuilt as
      illuminated-manuscript style (gold top rule, Om, tinted scripture panel
      with gold spine, floral "Live it today" takeaway). Homepage block elevated
      to match. Live + verified EN+HI (110/111 rebuilt).
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
