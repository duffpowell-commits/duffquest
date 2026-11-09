# DuffQuest art rules (Nov 9, 2026)

The single checklist every image gets graded against before it ships. Each rule has a reason, because
every one of these was learned by getting it wrong once. Source docs: `docs/duff_look.md` (Duff),
`docs/knockout_cutscenes.md` (KO beats and the style-fusion prompt), `tasks/lessons.md` (the scars).

Grades: **PASS** ships. **FIX** means one targeted edit will fix it. **REDO** means regenerate from scratch.
Any **HARD** rule failure is an automatic FIX or REDO.

## 1. Duff (HARD, every image he appears in)
- **D1 Buff.** Thick arms, broad chest and shoulders. Never skinny, never dad-bod.
- **D2 Sleeves.** Heavy blackout sacred-geometry sleeve on ONE arm, from shoulder to wrist: flower of life,
  shoulder mandala, star mandala on the forearm, eye at the wrist. If his arms are visible and bare, the
  sleeve must be there.
- **D3 Other arm.** Grey-wash horns or flames on the upper arm. On the forearm: a dark creature head with
  orange eyes. It is **not a panther**, and it is not a lion or a cat.
- **D4 Hands.** Back of the blackout-arm hand: an eye inside a ring of triangles. Back of the other hand:
  bold blackletter script.
- **D5 Sides stay consistent.** The fox neck tattoo sits on Duff's left side of the neck. Use it to check
  which arm is which.
- **D6 Face.** He must match `portraits_hd/duff.png` and the photos in `docs/ref/duff/`. Wherever the
  photos and the fox art disagree, the photos win.
- **D7 Clothes can cover.** Long sleeves, a coat or an apron over his arms is fine. A tattoo drawn ON TOP
  of his clothes fails.

## 2. Knockout stills (`assets/art/ko/`, 16:9, 1280x720)
- **K1 X-ray matches the hit (HARD).** The x-ray inset shows the spot where the strike lands, and the bone
  it shows is the one the `xray` line in `data/knockouts.json` names.
- **K2 Expressions.** Each boss gets its own reaction: A = wind-up face, B = pain at impact, C = knocked
  out. No two bosses share a face, and no boss gets Ghoster's face.
- **K3 No leaked characters (HARD).** Check EVERY panel for faces copied from the reference image.
- **K4 Style.** Thick tapered ink lines, flat cel shading, crack-line muscle hatching on impact frames, and
  speed lines over one flat colour. Duff's frames use navy, amber and grey. Bosses use saturated neon.
- **K5 No text** in the art. The engine stamps the move names itself.
- **K6 Composition per image.** No two B stills share a layout. A finished still never doubles as the
  layout reference for the others.

## 3. Parody bosses (HARD)
- **P1** Husk, Bozos, Fences, The Donald and Willnot have made-up human faces. No real person's likeness,
  and no duck, TV or lightbulb heads. Those are Hazbin imitations and belong in the DLC.

## 4. All HD art (portraits, boss intros, loading screens)
- **H1 One house style.** Human characters in a bold Hazbin-like cartoon look, matched against
  `portraits_hd/` and Ghoster.
- **H2 Cartoon gore OK (Duff, Nov 9).** Allowed: cartoon blood such as spit, a bloody nose or a split
  lip, flying teeth, and bruises. Not allowed: dismemberment, exposed organs, or realistic wounds. The
  itch "2026 Jam" has no content rules beyond itch's own, so the itch page just gets a "blood/violence"
  content tag. Canva's filter blocks blood in generated images, so do NOT prompt for it. Blood gets
  added in-engine instead: spit and blood particles in `knockout.gd` on the x-ray and finisher hits.
  Missing blood is never a reason to fail an image.
- **H3 Clean output.** Nothing cropped off the important parts, no watermark, no garbled fake text, no
  extra fingers or limbs.
- **H4 Size.** KO and loading art are 1280x720 JPG at quality 88. Portraits and cards keep the sizes the
  existing files already have.

## 5. Pixel sprites (world, `ch_*.png` sheets)
- **S1** Modern high-detail pixel art in the style of *Sea of Stars*, with crisp outlines and no blur.
- **S2** The sheet's grid and frame count must not change, and the sheet must stay readable at game scale.
- **S3** Scale is checked against Duff, who is about 26 units tall.
- **S4** Duff sprites still pass D1 to D3 at whatever detail the sprite size allows: a dark arm, a lighter
  inked arm, and a buff build.

## 6. Process
- **R1** Before any render, run `godot --headless --path . --import` after swapping art.
- **R2** Judge from full-size frames, not a shrunk contact sheet.
- **R3** Write prompt sides from the viewer's view ("the arm on the VIEWER'S RIGHT").
- **R4** Style references must not contain any characters. Characters get their own separate references.
- **R5** Keep masters in `grok_art/<date>-<set>/` and save review sheets to `docs/renders/`.
- **R6** Write reviews to `docs/reviews/`, one line per image: grade, the rule IDs it failed, and the fix
  prompt.
