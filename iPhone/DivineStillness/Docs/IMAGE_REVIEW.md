# Deity image validation

## The honest truth about "a tool that gives a green signal"

**There is no automated tool or app that can certify Hindu deity iconography as
correct.** Be very skeptical of anything that claims to. Here's the reality:

- **Generic AI artifact / anatomy detectors** exist (they flag extra fingers,
  melted hands, etc.) but they are unreliable and know nothing about iconography.
- **Multimodal AI (including me)** can triage obvious problems — twisted/extra
  hands, wrong number of arms, distorted faces — and check well-known attributes.
  Useful as a *first filter*, but **not authoritative** on religious correctness
  and it can miss subtle defects (exactly like the Venkateshwara left-hand issue,
  which is hard to see at small sizes).
- **No certified "Hindu iconography validator" exists.** The rules (Shilpa/Agama
  Shastra — number of arms, attributes, mudras, vahana, proportions) are precise,
  but no consumer app encodes them.

So the only **foolproof** sign-off is a knowledgeable **human** — ideally a
priest/pandit or an iconography-literate devotee — reviewing each final image at
full resolution against a checklist. That's the green signal.

## The pipeline that actually protects you

1. **AI triage (first pass).** Catch gross anatomical/iconographic errors and
   shortlist anything doubtful. (This doc's status table.)
2. **Full-resolution human review (authoritative).** Zoom into every hand, face,
   foot, and attribute. A priest/pandit sign-off is ideal for a devotional app.
3. **Checklist per deity** (below) — review each image against it.
4. **"When in doubt, cut it out."** The risk is asymmetric: one disrespectful
   image can cause real harm and reviews. Better 40 flawless images than 60 with
   3 questionable ones. The app no longer hardcodes a count, so cutting is free.
5. **In-app report path.** Settings already links the brand email; act on any
   reported concern quickly (the Image & Faith Standards page commits to this).

## Anatomy red-flags (the usual AI failures — check every image)

- Hands & fingers: count, fusing, twisting, unnatural bends (most common defect)
- Number of arms wrong for the deity (e.g. Vishnu must be 4, not 3 or 5)
- Faces: asymmetric/melted eyes, doubled features
- Extra/missing limbs, feet, toes
- Attribute in the wrong hand, or a malformed weapon/object
- Gibberish "script" on books/scrolls/cloth — avoid showing fake scripture text
- Vahana (mount) malformed or wrong

## Per-deity iconography checklist

- **Shiva** — third eye, crescent moon, Ganga in jata, snake, trishul + damaru,
  rudraksha, tiger skin; calm/meditative or Nataraja.
- **Ganesha** — elephant head, broken tusk, big belly, usually 4 arms (ankusha,
  pasha, modak, abhaya), mouse vahana.
- **Krishna / Radha-Krishna** — blue, peacock feather, flute (bansuri), yellow
  pitambar, tribhanga pose, cows.
- **Rama / Ram Darbar** — bow + arrows, princely, dignified; Darbar = Ram, Sita,
  Lakshman, Hanuman.
- **Hanuman** — monkey face, gada (mace), sindoor, devotional; often Ram in heart.
- **Vishnu / Vishnu-Lakshmi** — blue, **4 arms**: shankha, chakra, gada, padma;
  crown; with Lakshmi / on Shesha.
- **Venkateshwara (Balaji)** — dark face, white namam (V) with red, crown,
  4 arms (shankha + chakra above; lower-right varada pointing down to feet,
  lower-left on hip), heavily garlanded. **← reported defect here.**
- **Saraswati** — white sari, veena, swan, lotus, book; serene.
- **Lakshmi** — red/gold, lotuses, gold coins flowing, often with elephants.
- **Durga / Vaishno Devi** — Devi with lion/tiger, multiple arms with weapons.
- **Kali** — fierce; garland of heads, sword; **fierce iconography must be exact
  and respectful** — highest-sensitivity, review hardest.
- **Brahma** — four faces, four arms, vedas, kamandalu, swan, lotus.
- **Narasimha** — lion head + man body; fierce. If shown with Hiranyakashipu the
  scene is intense — **high sensitivity**, review carefully.

## Status (AI triage — first pass only; NOT a final green light)

Legend: ✅ no obvious issue at review size · ⚠️ closer human review · ❌ fix/cut

### Free tier (days 1–12) — most visible, reviewed
| Day | Image | AI triage | Note |
|---|---|---|---|
| 1 | shiv | ✅ | Meditative Shiva; attributes correct |
| 2 | ganesh | ✅ | 4 arms, attributes + mouse correct |
| 3 | shiv_parivar | ⚠️ | Multi-figure (Shiva/Parvati/Ganesha/Kartikeya/Nandi) — zoom all hands |
| 4 | krishna | ✅ | Flute pose; recheck flute fingers at full res |
| 5 | radha_krishna | ✅ | Recheck both pairs of hands at full res |
| 6 | shri_ram | ✅ | Bow + abhaya; clean |
| 7 | shri_ram_parivar | ⚠️ | Multi-figure Darbar — zoom Hanuman/Lakshman hands |
| 8 | shri_hanuman | ✅ | Anjali with Ram in heart; clean, devotional |
| 9 | vishnu | — | pending |
| 10 | vishnu_lakshmi | — | pending |
| 11 | vaishno_devi | — | pending |
| 12 | venkateshwar_swami | ❌ | **Reported: left hand badly twisted. Pull from app until fixed/replaced.** |

### Pro tier (days 13–60) — high-risk forms triaged, rest pending
| Day | Image | AI triage | Note |
|---|---|---|---|
| 13 | balaji | ⚠️ | Venkateshwara; recheck raised hand at full res |
| 16 | maa_kali | ❌ | **Not Kali** — serene blue Devi, lotus, no mundamala/sword/severed head/tongue |
| 18 | narsimha | ✅ | Lion head, 4 arms (chakra/shankha/abhaya); good |
| 19 | prahlad_and_narsimha | ✅ | Narasimha blessing Prahlad; devotional, clean |
| 31 | venkateshwar_swami | ⚠️ | Recheck hands at full res |
| 35 | maa_kali | ❌ | **Not Kali** — seated Devi with trident, no Kali attributes |
| 37 | narsimha | ✅ | Lion head, 4 arms; good |
| 50 | venkateshwar_swami | ⚠️ | Recheck hands at full res |
| 54 | maa_kali | ❌ | **Not Kali** — serene blue Devi on lotus, no Kali attributes |

Still to triage (lower-risk, same checklist): days 9–11, 14–15, 17, 20–30,
32–34, 36, 39–53, 55–60 (Shiva, Ganesha, Krishna, Ram, Hanuman, Vishnu,
Lakshmi, Saraswati, Brahma, Shiv Ling, Vaishno Devi, Balaji repeats).

## Decisions / actions

- ✅ **Done:** `day12_venkateshwar_swami` pulled (removed from `ContentCatalog`
  via `removedImageNames` + asset deleted). Free tier is now days 1–11.
- ⛔ **All three Maa Kali images (16, 35, 54) are mislabeled / iconographically
  wrong.** Recommend **cut all three** (add to `removedImageNames` + delete
  assets) and regenerate proper Kali later, OR drop Kali from v1. Removing them
  drops the "Devi" representation that's actually Kali — Saraswati/Vaishno Devi
  still cover Devi. **Needs your call: cut, or regenerate?**
- ⏭️ Finish AI triage of the remaining ~40, then **human/priest sign-off** on
  survivors before submission. Apply "cut when in doubt."
