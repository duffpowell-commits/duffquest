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
- **P1** Every boss has a made-up human face. No real person's likeness, and no duck, TV or lightbulb heads.
  Those are Hazbin imitations and belong in the DLC. (Nov 9: the four billionaire parodies are retired to
  `docs/dlc_concepts/billionaires/`; their slots are now Madison's gala exes Tyler Pivot, Grant Gratuity,
  Landlord Lance and Chip Leverage, brief in `docs/gala_exes_art_brief.md`. No public figures anywhere.)

## 4. All HD art (portraits, boss intros, loading screens)
- **H1 One house style.** Human characters in a bold Hazbin-like cartoon look, matched against
  `portraits_hd/` and Ghoster.
- **H2 Cartoon gore OK (Duff, Nov 9).** Allowed: cartoon blood such as spit, a bloody nose or a split
  lip, flying teeth, and bruises. Not allowed: dismemberment, exposed organs, or realistic wounds. The
  itch "2026 Jam" has no content rules beyond itch's own, so the itch page just gets a "blood/violence"
  content tag. Canva's filter blocks blood in generated images, so do NOT prompt for it. Blood gets
  added in-engine instead: spit, blood and teeth in `scripts/ko_gore.gd` on the x-ray and finisher hits
  (Settings "Cartoon gore" toggle, default ON).
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
- **R7 Side-facing sprites (Nov 9 fix).** Facing screen-RIGHT shows his RIGHT side (creature arm near); facing
  screen-LEFT shows his LEFT side (blackout sleeve near + fox). Side rows are inked separately, never mirrored.
  Tool: `tools/tattoo_sprites.py` (reads backups in `grok_art/2026-11-09-sprites-backup/`, safe to rerun).

## 7. House style C (LOCKED Nov 9, every HD image; full spec `docs/art_direction/STYLE_LOCK.md`)
Duff picked option C: boss-card faces and linework everywhere, KO stills keep speed lines and light hatching.
Run D1-D7, K1-K6, P1, H1-H4 as above, plus:
- **ST1 Lines.** Thick, tapered, near-black (#14121A) ink. No sketchy or hairline ink.
- **ST2 Shading.** At most one hard shadow tone per material. No gradients, gloss, grain, paper texture or airbrush.
- **ST3 Hatching.** Only crack-line strokes on a KO still's impact limb / deepest shadow (5-10 max). None on cards,
  portraits or loading screens.
- **ST4 Background.** Flat graphic, 2 tones + 1 accent: speed lines on KO stills, sunburst on cards and portraits,
  a calm flat set or soft sunburst on loading screens (never speed lines there).
- **ST5 Same show.** Pasted side by side with the boss's intro card and `portraits_hd/` sheet, it reads as the same
  show. Check by pasting both into one image, not from memory.
- **ST6 Duff's face** matches `docs/art_direction/duff_face_sheet.png` (jaw, brows, dirty-blond undercut, ponytail,
  plugs, blue eyes, stubble). The face sheet is the FIRST character reference for every Duff image.
- **ST7 Fox side.** Fox on Duff's LEFT neck (viewer's right when he faces camera), or hidden. Zoom in; #1 miss.
Any ST fail = FIX; ST5 or ST6 fail = REDO. No image ships outside the lock.
