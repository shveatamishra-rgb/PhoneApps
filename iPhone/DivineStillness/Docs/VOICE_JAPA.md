# Voice Japa — hands-free counting (plan)

**The idea (yours):** record your mantra in your own voice, then during jaap you
just chant — the counter ticks on its own, no tapping, and beeps when you hit the
target. Close your eyes, recite, and open them when it's done. No tension about
keeping count.

**Verdict:** this is a real differentiator and a strong Pro/USP feature. Most
japa apps are tap-counters or assume a physical mala. "Hands-free voice japa" is
rare, demos beautifully in a 15-second reel, and is exactly the kind of thing
people subscribe for. Worth building — with eyes open about the accuracy work.

## How it can actually work (3 approaches)

### 1. Rhythmic onset counting — recommended for v1
Tap the microphone with `AVAudioEngine`, measure short-time loudness, and count
each *utterance burst* (one mantra repetition = one burst separated by a breath/
pause). A refractory window (~400–600 ms between counts) prevents double-counting
syllables. A one-time "chant 3 times" calibration learns your rhythm and volume.
- ✅ On-device, real-time, language-agnostic, works for soft murmured japa, no
  audio ever leaves the phone (great privacy story, fits this app).
- ✅ Light on battery; feasible for long 1,008 / 10,000 sessions.
- ⚠️ Needs tuning; noisy rooms or very irregular cadence cause miscounts →
  mitigate with calibration, a sensitivity slider, and easy +1/−1 correction.

### 2. On-device speech recognition (`SFSpeechRecognizer`)
Transcribe and count the mantra phrase.
- ⚠️ Recognizers collapse repeated identical phrases, struggle with Sanskrit/
  whispered chanting, and have session-length/battery limits. **Not reliable for
  counting 108–10,000 reps.** Not the core; maybe a future "smart" assist.

### 3. Voice template matching — the "magic" v2
Record your mantra once → a voice template (MFCC features). Stream the mic and
match each repetition against *your* template (DTW / cross-correlation, or a tiny
Core ML model).
- ✅ Most accurate and most on-brand — it literally counts *your* mantra in *your*
  voice, which is exactly your vision.
- ⚠️ More engineering. Best as a v2 once v1 proves the UX.

**Plan: ship v1 on approach 1 (onset counting + voice calibration), evolve to
approach 3 for accuracy.**

## UX

- New **Voice Japa** mode on the Japa screen, **Pro-gated** (this is a headline
  paywall feature).
- Flow: choose mantra → set target (108 / 1,008 / 10,000 / custom) → **Start** →
  the count ticks up as you chant, ring fills → at target: gentle chime + haptic
  + "Mala complete," continue or stop.
- First run: "Chant your mantra 3 times so I can learn your rhythm" (calibration;
  doubles as the optional voice recording you described).
- Controls: pause/resume, manual +1 / −1, sensitivity slider, "chime at target"
  toggle, and **keep-screen-awake** (disable idle timer) so it won't lock while
  your eyes are closed. A soft pulse on each detected rep gives sighted feedback.

## Permissions, privacy, review

- Requires `NSMicrophoneUsageDescription` ("Count your japa as you chant —
  audio is processed on your device and never recorded or sent anywhere").
- Audio is processed live and **never stored or transmitted** (except the short
  on-device calibration sample). Add one line to the privacy policy. This is a
  clean, trust-building story consistent with the app's no-tracking stance.
- App Review: mic-for-counting is fine; foreground-only (you're actively
  chanting), so **no background-audio entitlement** needed.

## Monetization

Make Voice Japa the flagship Pro feature and lead the paywall with it:
"Hands-free Voice Japa — close your eyes, we'll keep count." It's a stronger
subscription driver than the image library alone, and a perfect promo-video hook.

## Honest caveats & sequencing

- **Accuracy must be tuned on a real device** with real chanting — the iOS
  Simulator can't validate microphone counting. This is a "build + test on your
  iPhone" feature; it can't be fully verified in a sandbox.
- It's the most complex feature so far. Two sensible paths:
  - **A (recommended): ship the current app now** (it's submission-ready) and
    release Voice Japa as the **1.1 flagship update** — gets you to revenue now
    and gives you a big "new feature" marketing beat.
  - **B: hold v1** and build Voice Japa first if you'd rather launch with the
    differentiator already in.

## Build outline (when we start)

1. `Services/VoiceJapaCounter.swift` — `AVAudioEngine` mic tap, RMS framing,
   adaptive-threshold onset detection with refractory window; publishes a live
   count. Feature-flagged.
2. Calibration step (measure avg rep duration + level; store locally).
3. `Features/Japa/VoiceJapaView.swift` — eyes-closed UI, controls, completion
   chime/haptic, keep-awake.
4. Pro gate + paywall feature line + privacy line + mic usage string.
5. Real-device tuning pass (the important part).
6. Later: approach 3 template matching for accuracy.
