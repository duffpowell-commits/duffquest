# DuffQuest HD style lock (DRAFT, Nov 9 2026)

Status: **draft, waiting on Duff's pick** from `docs/art_direction/compare_ABC.jpg` (A = current gritty anime KO look,
B = flat cartoon in the boss-card style, C = B's characters plus KO speed lines). Claude recommends **C** (see the
bottom). Rules marked **[B/C]** apply if B or C wins. If Duff picks A, see "If A wins" at the end.

Pixel sprites are NOT covered here. They stay as they are (`docs/art_rules.md` section 5).

Masters for the sheet: `grok_art/2026-11-09-art-direction/` (rejects in `rejected/`). Sheet builder:
`tools/art_compare_sheet.py`.

## 1. Style definition (one paragraph)

Every HD image in DuffQuest (boss intro cards, dialogue portraits, KO stills, loading screens) is a **bold flat
cartoon**: thick black ink outlines that taper at the ends, flat solid colour fills with at most ONE hard cel-shadow
tone, clean simple shapes, expressive rubbery faces, and no painterly texture, paper grit, gloss or airbrush. Characters
look exactly like their `portraits_hd/` face and the boss card. Backgrounds are flat graphics, not scenery paintings:
a two-tone sunburst for cards, portraits and calm loading screens, and (option C only) radiating flat speed lines for
KO stills. Energy comes from pose, expression and the background, never from rendering detail.

## 2. Palette

- **Characters:** flat local colour, one shadow tone about 20-25% darker in the same hue. Skin is warm and saturated
  (Duff: warm tan-orange). No gradients on skin or clothes.
- **Ink:** near-black (#14121A), never pure grey lines.
- **Backgrounds, 2 tones plus 1 accent:**
  - Duff-only frames: navy #0E1A33 + teal-navy #1E4A66, amber accent #E0A030 (matches today's stance still).
  - Boss frames: take the boss card's 2 sunburst tones (e.g. Coupon Carol: dark teal + slate), add that boss's neon
    accent on the impact burst (magenta, lime, cyan...).
  - Loading screens: the scene's own flat colours, with the sky/back wall as a single flat tone or a soft sunburst.
- **X-ray:** cyan #3FF2E6 glow bones on a darker cyan limb silhouette, the same in every still.
- **Never:** sepia paper tint, brown grime, glossy specular highlights, film grain.

## 3. Line and shading rules

- L1 Outline weight: thick on the silhouette (about 1/150 of image height), thinner inside. Lines taper at both ends.
- L2 ONE hard shadow tone per material. No soft shading, no rim-light gradient (C allows a thin flat cyan rim line on Duff).
- L3 Hatching: **B: none. C: only crack-line hatching on the impact limb and the deepest shadow, 5-10 strokes max.**
- L4 Muscles are shapes plus one shadow, not hatched anatomy.
- L5 Tattoos are flat: the blackout sleeve is a solid black fill with skin-colour negative shapes. Grey-wash pieces use
  one flat grey.
- L6 Faces: big readable expressions, eyebrows and mouth do the work. No realistic wrinkles except age lines on older
  bosses (one or two lines, like the Coupon Carol card).

## 4. Composition rules per asset type

| Asset | Size | Composition |
|---|---|---|
| Boss intro card | 960x540 PNG (current size) | Boss full-body on the left half, mid-action, on the boss's 2-tone sunburst. Right half empty for the engine name text (the art has no text). |
| Dialogue portrait | keep current `portraits_hd/` sizes | Chest-up, 3 moods (calm / happy / angry) side by side on transparent, same framing in every mood. |
| KO still A (wind-up) | 1280x720 JPG q88 (master 1920x1080) | Boss alone, wind-up face, flat background (C: speed lines toward the boss). |
| KO still B (impact + x-ray) | same | Duff's strike lands; impact burst at the contact point; x-ray of the bone named in `data/knockouts.json`. Duff's striking arm is the blackout arm unless the beat says otherwise. Every B still gets its own layout (K6). |
| KO still C (knocked out) | same | Boss down, spiral eyes or similar, flat background. |
| Duff KO frames (stance/slip/fin1-3/walk) | same | Duff alone, 3/4 or chest-on; close-up inset panels allowed; navy/amber palette. |
| Loading screen | 1280x720 JPG q88 | One readable gag, 1-3 characters, flat simple set, a quiet area (lower third) for the caption the engine draws. |

Shared: no text in art (K5), nothing important cropped, faces at least 1/6 of image height on KO and loading so
they read on a phone.

## 5. Canva prompt templates

Always: upload refs with `create-upload-url` + `curl --data-binary`; pass the image being redrawn (if any) as the FIRST
reference, then the character's `portraits_hd/` sheet on white, then (Duff only) the canonical Duff face sheet once it
exists. Never name shows or studios in prompts (it pulls in their characters). Give sides from the VIEWER's view.

**STYLE block (paste into every prompt):**
> Bold flat cartoon TV-animation style: thick tapered black ink outlines, flat solid colour fills with one hard
> cel-shadow tone, clean simple shapes, expressive face, no painterly texture, no grit, no glossy highlights, no
> cross-hatching. [C only: bold radiating flat speed lines behind the subject and a few crisp crack-line hatching strokes
> only on the impact limb.] No text, no letters, no watermark.

**DUFF block (paste whenever Duff is in frame):** the TATTOOS block from `docs/duff_look.md`, plus for chest-on shots:
> His LEFT arm is on the VIEWER'S RIGHT: a near-solid BLACK blackout sleeve shoulder to wrist with skin-tone
> sacred-geometry negative space and an eye inside a ring of triangles on that hand. The arm on the VIEWER'S LEFT is skin
> with grey-wash horn/flame shapes on the upper arm, a dark creature head with small orange eyes and orange-gold leaves
> on the forearm (NOT a cat, NOT a panther) and blackletter script on that hand. Fox neck tattoo only on the VIEWER'S
> RIGHT side of his neck. Buff build.

For 3/4 shots where his RIGHT side faces camera: "NO tattoo on the visible side of his neck" (this worked in coupon_B/C).

**T1 Boss intro card**
> Full-body [BOSS DESCRIPTION, from portraits_hd/<boss>] striking a cocky [ACTION] pose on the left half of the frame,
> on a flat two-tone [TONE1] and [TONE2] sunburst background, right half empty. Same face as the reference. [STYLE]. 16:9.

**T2 Dialogue portrait sheet**
> Three chest-up portraits of the character in the reference, side by side on a plain white background, identical
> framing: calm, big happy grin, furious shout. Same face, hair and outfit as the reference. [STYLE] [DUFF if Duff]. 3:1.

**T3 KO still restyle (converting an existing still)**
> Redraw the FIRST reference with the exact same composition, poses, camera [and x-ray inset], in the style of the
> SECOND reference. [STYLE]. Background: [sunburst in TONE1/TONE2 | C: flat speed lines in TONE1/TONE2 with an ACCENT
> impact burst]. [BOSS] must look exactly like the second reference, now with a [wind-up / pained / knocked-out] face.
> Keep the cyan x-ray of the [BONE] at the contact point. [DUFF]. 16:9.

**T4 KO still from scratch**
> [BEAT from data/knockouts.json, describing who is where from the VIEWER's view]. [STYLE]. [background as T3]. [DUFF]. 16:9.

**T5 Loading screen**
> [GAG in one sentence]. [Who is where, from the VIEWER's view]. Simple flat set: [3-5 props]. Keep the lower third
> calm and empty-ish for a caption. [STYLE]. [DUFF if Duff]. 16:9.

## 6. Pass/fail checklist (add to `docs/art_rules.md` once a style wins)

Run `docs/art_rules.md` D1-D7, K1-K6, P1, H1-H4 as today, plus:

- [ ] ST1 Lines are thick, tapered, near-black. No sketchy or hairline ink.
- [ ] ST2 Max one hard shadow tone per material. No gradients, gloss, grain or paper texture.
- [ ] ST3 Hatching: B none; C only on the impact limb / deepest shadow.
- [ ] ST4 Background is flat graphic (sunburst or speed lines), 2 tones + 1 accent.
- [ ] ST5 Side-by-side with the boss's intro card (and `portraits_hd/`) it reads as the same show. Check by pasting
  both into one image, not from memory.
- [ ] ST6 Duff's face matches the canonical face sheet (shape of jaw, brows, undercut, ponytail, plugs, blue eyes).
- [ ] ST7 Fox on the correct neck side, or hidden (zoom in; this is the #1 miss).
Any ST fail = FIX; ST5 or ST6 fail = REDO.

## 7. Plan

1. **Duff picks** A/B/C from `compare_ABC.jpg`.
2. **Canonical Duff sheet** in the winning style: front, 3/4, profile, 3 expressions, both arms bare enough to show the
   tattoos. Draft (B style) is `docs/art_direction/duff_face_sheet_draft.png`; see its known issue below. Lock it as
   `docs/ref/duff/duff_canon_sheet.png` and upload it once to Canva; it becomes the first character ref for every
   future Duff image (after the image being redrawn). Budget: 2-4 generations + 1-2 edits.
3. **Convert KO and loading stills**, most-seen first. Masters to `grok_art/<date>-style-lock/`, game files swapped
   only after review.

| Order | Batch | Images | Why first |
|---|---|---|---|
| 1 | Duff KO frames: duff_stance, duff_slip, duff_fin1-3, duff_walk | 6 | play in EVERY knockout |
| 2 | Loading screens (`assets/art/loading/`) | 13 | shown on every wake, shift and fight |
| 3 | Gym Bro, Ghoster, DJ Vape KO a/b/c | 9 | first bosses most players reach |
| 4 | crypto, sendback, regular, coupon, allergy, camper KO | 18 | mid game |
| 5 | bdaydad, dasher, baron, willnot, husk, bozos, fences, donald KO | 24 | late game / parody slots (the 4 gala-ex slots may get new bosses anyway; do them last or skip) |

Counts: 57 KO stills (6 Duff + 17 bosses x 3) + 13 loading = **70 images**. Brief said ~51 + ~14; the repo has 57 + 13.
Expected Canva work at the hit rates seen today (about 1 in 3 Duff images needs a fix edit, usually the fox side):

| | images | gens | fix edits | total calls |
|---|---|---|---|---|
| Canon Duff sheet | 1 | 3 | 2 | 5 |
| Duff KO frames | 6 | 6 | 4 | 10 |
| Boss KO stills | 51 | 51 | 15 | 66 |
| Loading | 13 | 13 | 5 | 18 |
| **Total** | **71** | **73** | **26** | **~100** |

At about 1 call per minute (one agent at a time, Canva rate limit) that is roughly 2-3 agent sessions. Boss cards and
portraits need no work if B or C wins (they already are this style). Full-size export pages: about 100, so start a
new scratch design (the current `DAHabdund5o` is at 34 pages).

## Known issues in this draft's images

- **duff_face_sheet_draft.png:** front and 3/4 views pass (blackout on the viewer's right, creature arm and blackletter
  hand on the viewer's left, fox on the viewer's right). The **profile facing the viewer's left fails D5**: it shows the
  grey-wash arm with an eye-in-triangles hand, when that view should show the blackout sleeve. The 3 head close-ups put
  the fox correctly. Hair reads a bit more ginger-brown than `portraits_hd/duff.png`. Try 1 (arms swapped in every
  view) is in `rejected/`. Fix this before locking it as canon.
- **stance_B / stance_C:** Canva kept drawing the fox under his visible RIGHT ear even after an explicit edit, so it was
  removed with a local pixel patch (a faint ghost is visible only at full zoom on stance_B). Same gotcha as
  `docs/reviews/ko_stills.md`. Raw Canva output is in `rejected/`.
- coupon_B / coupon_C pass D1-D7 and K1 (radius/ulna x-ray at the contact point). The far arm's grey-wash piece reads
  as a horned face; acceptable as "grey-wash horns" but worth a look.

## Recommendation: C (Claude)

- B and C draw the characters the same way; that is what fixes the clash. Next to the Coupon Carol card both read as
  the same show, A clearly does not.
- C keeps the speed lines that make a knockout feel like a hit. Pure B stills (sunburst behind a punch) look like a
  second boss card, so KOs lose their punch and become harder to tell apart from intros.
- Cost is the same for B and C (cards and portraits already match; only KO + loading convert). Loading screens should
  use the B background (calm sunburst or flat set) even under C; speed lines are for KO stills only.

## If A wins

A would mean re-drawing the 17 boss cards and 22 portraits into the gritty look instead (about 39 images, fewer than
70), but the gritty style drifts Duff's face the most, its hatching turns to mush at phone and portrait size, and the
small dialogue portraits would clash with the pixel sprites. If Duff still prefers it, swap the STYLE block for the
"style-fusion prompt" in `docs/knockout_cutscenes.md` and invert section 7 (convert cards + portraits).
