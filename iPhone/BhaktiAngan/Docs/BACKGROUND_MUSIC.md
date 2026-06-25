# Background music — plan & integration

Yes, soft instrumental ambience suits this app well. The engine is already
built and shipping **dormant**: `Services/AudioManager.swift` handles a looping,
fading, polite-mixing track, and Settings shows a "Background music" toggle the
moment a track is bundled. Until then the feature is invisible and no audio
session is ever touched, so the app is safe to submit as-is.

## How it behaves (already implemented)

- One looping track, gentle fade-in on start, played at ~55% volume.
- Category `.playback` with `.mixWithOthers` — if the devotee is already playing
  a bhajan or podcast, we layer under it instead of stopping it.
- Plays only while the app is in the foreground; pauses on background (no
  background-audio entitlement needed, which keeps App Review simple).
- Preference persists across launches. Off by default.

## To turn it on (one-time, ~10 minutes)

1. **Get a licensed, royalty-free track.** It must be cleared for commercial app
   use. Good sources:
   - Your own/commissioned instrumental (best — fully yours).
   - Pixabay Music, Uppbeat, or YouTube Audio Library "no attribution" tracks.
   - Soft tanpura/flute/santoor/bansuri ambience, no vocals, loops cleanly.
   - Target: 60–120s seamless loop, calm, no sudden swells.
2. **Encode** to `.m4a` (AAC, ~128 kbps mono is plenty) to keep the binary small.
   Name it exactly `ambient_darshan.m4a`.
3. **Add to the app target** in Xcode: drag the file into the `Resources` group,
   check "Copy items if needed" and the BhaktiAngan target. (This auto-edits
   the project file's Resources build phase.)
4. Build and run → a "Background music" toggle now appears under
   **Settings ▸ Appearance & Sound**. No code change required.

## Optional polish (future)

- A quick speaker toggle on the Today hero for one-tap control.
- A small set of selectable ambiences (tanpura / flute / om) — extend
  `AudioManager` with a track list and a Settings picker.
- Per-track attribution screen if a source requires credit.

## Licensing reminder

Keep proof of license (receipt / "no attribution required" page) with your
records. Do **not** use temple-recording rips, copyrighted bhajans, or
film/TV devotional tracks — those will draw takedowns and App Review issues.
