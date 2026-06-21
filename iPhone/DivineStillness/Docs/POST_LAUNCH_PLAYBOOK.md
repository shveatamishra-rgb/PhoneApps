# Post-launch playbook

What to do once the app is live, plus the promo-video and screenshot recipe.

## Week of launch

1. **Tell your existing audience first.** Your Instagram (`divine.stillness.om`),
   YouTube (`@divinestillnessom`), and Facebook page are your cheapest installs.
   Pin "Download on the App Store" to each bio/About, and post the launch
   reel/video (see below) to all three the same day.
2. **Add the App Store link everywhere:** IG link-in-bio, YouTube channel links
   + video descriptions + pinned comment, Facebook page button ("Use App" / link),
   and the end-card of every existing and future reel.
3. **Ask for the first ratings.** The app already asks for a review after a
   completed mala, but personally ask 10–20 friends/family to download, open it
   a few days, and leave an honest review. Early ratings drive ranking hard.
4. **Turn the daily content engine toward the app.** Every darshan reel you
   already make for IG/YT should end with "Get a new darshan every day — link in
   bio." The app and the content cross-feed each other.

## First 30–60 days (the loop that grows revenue)

- **Keep posting daily darshan content** — it's both audience growth and the
  app's funnel. Consistency is the whole game at 12 followers / 7 subs.
- **Watch three numbers** weekly in App Store Connect: impressions→downloads
  (ASO), downloads→trial starts (paywall), trial→paid (conversion).
- **Tune ASO** if downloads are low: try title `Divine Stillness Om: Darshan`
  vs `Divine Stillness: Hindu Puja`, and rotate screenshot captions. You can
  change these without a new build.
- **Tune pricing per country** after ~200 downloads — India/Nepal/Indonesia
  lower, Tier-1 standard (see `Docs/APP_STORE_METADATA.md`).
- **Add the licensed background-music track** (`Docs/BACKGROUND_MUSIC.md`) and
  ship it as the 1.1 update — a content update is a fresh "Updated" date and a
  reason to re-post.
- **Plan the first festival collection** (e.g. Janmashtami / Navratri / Diwali)
  as a Pro drop timed to the festival — these are natural conversion spikes.

## Ongoing cadence

- Ship a small update every 3–6 weeks (new darshans, a festival pack, the music,
  a bug fix). Regular updates improve ranking and give you content to post.
- Reply to every App Store review (especially critical ones about iconography —
  fix and thank them; it builds trust in this audience).
- Revisit the paywall copy and trial length only after you have real conversion
  data; don't guess-thrash it early.

---

## Promo video (15–20s) — for YouTube / Instagram / Facebook

**Format:** 1080×1920 vertical, 9:16. Works as a Reel / Short / FB video.
**Music:** the same calm instrumental you license for the app (or YT Audio
Library). **Pace:** slow, reverent — let each shot breathe ~2.5–3s.

### Storyboard (screen-recording based, easiest)

| Time | Shot | On-screen text |
| --- | --- | --- |
| 0–3s | Today screen, slow push-in on the deity image | "A quiet moment of devotion" |
| 3–6s | Swipe to a second/third darshan | "A new darshan every day" |
| 6–10s | Japa counter, finger tapping, number rising to 108 | "Chant. Breathe. Be still." |
| 10–13s | Darshan library scrolling | "Shiva · Krishna · Devi · and more" |
| 13–16s | Save-as-wallpaper, then phone lock screen shows it | "Keep your darshan close" |
| 16–20s | App icon + title, App Store badge | "Divine Stillness Om — on the App Store" |

End every cut on a calm beat; finish with "🙏 Link in bio."

### AI video-generation prompt (if you'd rather generate B-roll)

> A serene, cinematic vertical video (9:16) for a Hindu devotional app. Soft
> golden morning light, gentle incense smoke drifting, a warm temple-at-dawn
> mood. Slow, meditative camera moves over glowing brass diya lamps, marigold
> and rose petals, a softly lit murti silhouette, and a calm pair of hands
> holding a rudraksha japa mala, counting beads. Warm ivory-and-saffron palette,
> shallow depth of field, dust motes in light, no text, no faces in close-up,
> respectful and peaceful. 4-second clips, smooth and unhurried.

Generate 3–4 such B-roll clips, then intercut them with the app screen
recordings from the storyboard so viewers see both the feeling and the product.

---

## Screenshots / recordings to capture

Capture on the **6.9" iPhone (iPhone 17 Pro Max), 1290×2796**. Put the phone in a
clean state (your favorite deity selected, a few japa taps done).

**For the App Store (stills):**
1. Today / daily darshan
2. Japa counter (mid-count)
3. Darshan library
4. Pro paywall (no price baked in)
5. Dark-mode Today
6. Settings with the daily reminder on

**For the promo video (screen recordings, iOS Screen Recording):**
- A slow scroll of the Today screen
- Swiping between two darshans in the library / detail
- Tapping the japa circle several times so the number climbs
- Saving a wallpaper and showing it on the lock screen

Capture commands (simulator) for the stills, if you don't want to use a device:

```sh
DEV="iPhone 17 Pro Max"
xcrun simctl boot "$DEV"
# build & install the Release app first, then:
xcrun simctl launch "$DEV" com.shveatamishra.divinestillness --pro-mode
xcrun simctl io "$DEV" screenshot today.png
```

(App Store screenshots must come from a real device or simulator at the exact
6.9" resolution; the simulator output above is already correct for that size.)
