# Review: loading art + character sprite sheets (Nov 9, 2026)

Graded against `docs/art_rules.md` and `docs/duff_look.md`. Every image was opened at full size; Duff's arms, hands and neck
were checked again in zoomed crops. Reference: `docs/ref/duff/photo_front.jpg` and
`photo_left_shoulder_mandala_full.jpg`. Review sheets are in `docs/renders/review_*.png`.

**Counts.** Loading art (13): 2 PASS, 9 FIX, 2 REDO. Sprites (47 `ch_*` + `av_duff`): 23 PASS, 3 FIX, 22 REDO.

## Systemic finding: the fox is on the wrong side (D5) in every Duff loading image

In `photo_front.jpg` the fox and the blackout sleeve are both on the VIEWER'S RIGHT, which is Duff's LEFT. In all 11 loading
images that show Duff, the fox sits on the VIEWER'S LEFT of his neck when he faces camera, or under the visible ear in a
three-quarter view facing the viewer's right. Both put it on **his right**. The likely cause is `portraits_hd/duff.png`. All
three faces there turn toward the viewer's right with the fox under the near ear, which is his right side, and that portrait
is used as the face reference. In `brunch_atlas` the sleeve is on the correct arm, so the fox ends up on the opposite side from
the sleeve.
- **Cheap fix where no ink is visible:** flip the whole JPG horizontally. None of these images has text in it. That moves the
  fox to his left for free. Do it only after any hand or arm ink is added, or flip first and then add the ink on the correct
  sides.
- **Prompt rule from now on (R3):** "fox neck tattoo on the side of the neck on the VIEWER'S RIGHT when he faces camera; in a
  3/4 view facing the viewer's left it is on the near side."
- Fix `portraits_hd/duff.png` too (out of scope here), or every future prompt will inherit the mistake.

Shorthand used in the fix prompts below: **[TATTOOS]** means paste the TATTOOS block from `docs/duff_look.md` and attach
`photo_front.jpg` + `photo_left_shoulder_mandala_full.jpg`.

## 1. Loading art (`assets/art/loading/*.jpg`, all 1280x720, H4 OK)

| file | grade | rules failed | specific problem | fix prompt / method |
|---|---|---|---|---|
| brunch_atlas.jpg | FIX | D3, D5 | Closest to correct. The blackout sacred-geometry sleeve is on the arm on the viewer's right (his left, correct), there is script on the back of the fist on the viewer's left (D4 OK), and the build is good. But the forearm on the viewer's left is grey-wash line work with no creature head, and the fox is on the viewer's left of his neck (his right). | Canva edit: "On the forearm of the arm on the VIEWER'S LEFT, add a dark creature head with glowing orange eyes, a snout and a pink tongue, framed by orange-gold leaves. It is NOT a panther, lion or cat. Keep the grey-wash horns above it. Move the fox neck tattoo from the viewer's-left side of his neck to the VIEWER'S RIGHT side. Change nothing else." |
| fryer_nap.jpg | REDO | D1, D2, D3, D5 | Confirmed: both arms bare (short-sleeve tee and apron). The arms are thin, hairy and soft, not buff, and the fox is on his right. A tattoo edit alone won't fix the build. | Regenerate: "Duff asleep standing at the fryer, head back and drooling, black tee and stained black apron, towel on shoulder. Dolores pours coffee beside him. **BUFF**: thick muscular arms, broad shoulders. [TATTOOS] Arm on the VIEWER'S RIGHT is a near-solid black blackout sleeve from the tee hem to the wrist, with pale flower-of-life circles and a star mandala on the forearm. Back of that hand: an eye inside a ring of black triangles. Arm on the VIEWER'S LEFT: grey-wash horn shapes under the sleeve hem; on the forearm a dark creature head with orange eyes (not a panther); blackletter script on the back of that hand. Fox tattoo on the VIEWER'S RIGHT side of his neck. Hazbin-style bold cartoon, warm diner light, 16:9, no text." |
| goose_bet.jpg | FIX | D2, D3, D4, D5 | Confirmed: rolled sleeves leave both forearms bare, the back of the hand on the viewer's left is bare, the fox is on his right, and the arms are slim. | Easiest, in this order: (1) Canva edit "Unroll his black overshirt sleeves all the way to the wrists on both arms. Change nothing else." (2) **Flip the JPG horizontally**, which moves the fox to his left (D5). (3) Canva edit on the flipped image: "On the back of the hand on the SAME side of the image as the fox tattoo, add a black eye inside a ring of sharp triangles; on the back of the other hand, add bold illegible blackletter script." The alternative is the full ink edit with [TATTOOS] on bare forearms. |
| gym_spot.jpg | FIX | D2, D3, D4, D5 | Confirmed: a perfect buff build (D1 PASS), but both arms are fully bare in a sleeveless tank. This is the most visible miss in the set. The backs of the hands on the bar are bare, and the fox is on the viewer's left (his right). | Canva edit: "[TATTOOS] Arm on the VIEWER'S RIGHT: heavy blackout sacred-geometry sleeve from shoulder to wrist, mostly solid black with skin-tone flower-of-life circles on the upper arm, a petal mandala on the elbow and a star mandala on the forearm; eye inside a ring of triangles on the back of that hand. Arm on the VIEWER'S LEFT: grey-wash biomechanical horn/flame shapes on the upper arm; a dark creature head with orange eyes and leaves on the forearm (NOT a panther); blackletter script on the back of that hand. Keep the black wristbands. Move the fox neck tattoo to the VIEWER'S RIGHT side of his neck. Keep the face, pose and spotter unchanged." |
| octavia_fund.jpg | FIX | D4, D5 | Long sleeves cover the arms (D7 OK), but the backs of both hands and both wrists are clearly bare, and the fox is on his right. | Flip the JPG horizontally first (moves the fox to his left; there is no text in the image). Then Canva edit: "On the back of Duff's hand on the VIEWER'S RIGHT, add a large black eye inside a ring of sharp black triangles that blends into black ink at the wrist cuff. On the back of his hand on the VIEWER'S LEFT, add bold illegible blackletter script running onto the wrist. Change nothing else." |
| omaha_winter.jpg | FIX | D3 (minor), D5, + content | Hoodie and gloves cover him (D7 OK), but a strip of bare forearm on the near arm (his right) shows between cuff and glove with no ink. The fox is on his right. **The skyline is New York (Empire State Building), not Omaha.** | Canva edit: "Close the gap between the hoodie cuff and the glove on the arm on the VIEWER'S LEFT so no skin shows. Replace the city skyline with a smaller Midwestern skyline (one tall dark glass tower with a stepped top, a few mid-rise buildings); no Empire State Building." Then flip horizontally for D5. |
| one_trip.jpg | FIX | D2/D3, D1 (marginal), D5 | Confirmed: the only visible forearm (the one wrapped around the bags) is bare, veiny and thin, with no ink. The fox is on his right. | Canva edit: "Make the forearm wrapped around the grocery bags thick and muscular. [TATTOOS] If it is the arm on the VIEWER'S LEFT: dark creature head with orange eyes and leaves on the forearm (NOT a panther), blackletter script on the back of the hand. Move the fox neck tattoo to the VIEWER'S RIGHT side of his neck." (He faces the viewer's right, so the near arm is his right.) |
| plasma_day.jpg | FIX | D2, D3, D4, D5 | Confirmed: the IV arm (viewer's right, his left) is fully bare, and it is the focal point of the image. The thumbs-up hand shows no script, and the fox is on his right. H2 OK: the bag is yellow plasma, and the red bit is just a tube connector. | Canva edit: "[TATTOOS] The extended arm on the VIEWER'S RIGHT (with the IV needle and tape) becomes a heavy blackout sacred-geometry sleeve: mostly solid black from the rolled shirt cuff to the wrist, with skin-tone star mandala and chevron bands on the forearm. Keep the needle, tape and tubing on top of the ink. The thumbs-up hand on the VIEWER'S LEFT gets blackletter script on its back and a thin black bracelet at the wrist. Move the fox to the VIEWER'S RIGHT side of his neck." |
| raccoon_break.jpg | FIX | D2, D3, D5 | Partly confirmed. It is **not** bare: the arm on the viewer's left (his right) has grey-wash flame ink on the upper arm and forearm. But the arm on the viewer's right (his left) is bare skin except a small patch at the wrist (no blackout sleeve), the right forearm has flames instead of the creature head, and the fox is on his right. | Canva edit: "[TATTOOS] Arm on the VIEWER'S RIGHT (holding the plate): heavy blackout sacred-geometry sleeve, mostly solid black from the tee sleeve to the wrist, skin-tone star mandala on the forearm, eye in a triangle ring on the back of the hand. Arm on the VIEWER'S LEFT: keep the grey-wash horns on the upper arm, but replace the forearm flames with a dark creature head with orange eyes and leaves (NOT a panther). Move the fox to the VIEWER'S RIGHT side of his neck. Keep the raccoon unchanged." |
| regular_5am.jpg | PASS | — | No Duff. Earl and Dolores are on-model, the mug pyramid is clean, and there is no garbled text. | — |
| rent_slot.jpg | FIX | D2/D3, D4, D5, H3 | The forearm below the rolled cuff on the jar arm is bare, the backs of both hands are bare, and the fox is on his right. **H3:** the neck is malformed, with a second jaw-like bulge under the ear where the fox sits. | Canva edit: "Fix the neck anatomy: one clean neck line from jaw to collar, no bulge under the ear. Roll the shirt sleeve down to the wrist on the jar arm. On the back of the hand cupped at his ear (VIEWER'S RIGHT), add blackletter script; on the back of the jar hand (VIEWER'S LEFT), add a black eye inside a ring of triangles." Then flip horizontally for D5 (after the flip, recheck that the eye hand is the one on the viewer's right). If the neck won't fix cleanly, REDO. |
| waffle_showoff.jpg | REDO | H1, D2, D3 | This is pixel art, not the Hazbin cartoon style that `data/loading_screens.json` says loading screens use, so it is the odd one out in the rotation. It is also AI pseudo-pixel art with mixed pixel sizes and soft edges (not crisp S1 quality either). Duff's arms are bare skin at a readable size. | Either regenerate in house style: "Duff in black tee and stained apron swings a cast-iron skillet at a car-sized angry waffle monster in a 24h diner at night, BUFF, [TATTOOS] (blackout sleeve on the arm on the VIEWER'S RIGHT when he faces camera), fox on the VIEWER'S RIGHT of his neck, Hazbin-style bold cartoon, 16:9, the neon '24h' sign is the only text". Or, if Duff wants a pixel "gameplay" card on purpose, keep it and just ink the arms: one dark arm, one lighter arm with a dark forearm patch. |
| witnesses.jpg | PASS | — | No Duff, clean style, no text. Optional, not a rule failure: the three porch cats are tuxedo, orange-and-white and purple-grey. In the game, Alastor and Lucifer are near-identical orange/cream brothers and Freya is a long-haired tabby (`scripts/main.gd` CAT3 text), so these don't read as Duff's cats if they're meant to be. | Optional Canva edit: "Make the left and middle cats two near-identical orange-and-cream cats; make the right cat a long-haired brown tabby with glasses and the notepad." |

## 2. Sprite sheets

The grid was measured with PIL on every sheet. All `ch_*` sheets are **256x256 PNG RGBA, 4x4 cells of 64x64**, origin
(32,60), `s: 2` (so 32x32 logical units per cell). Rows are down / up / right / left; columns are idle / walk / walk /
action. There are no semi-transparent pixels anywhere, so nothing is blurred. Scale is measured as the opaque height in a cell
divided by 2: Duff is **26 units**.

Two styles are mixed across the sheets:
- **New detailed style** (Sea of Stars-like, 26 units, outlined): matches S1.
- **Old procedural chibi** (26-29 colours, giant square head, wedge "beak" nose in profile, **29-30 units, taller than Duff**):
  fails S1 and S3. Most of these are clones of the same template with a different palette.

The high-colour new sheets (8,000-12,600 colours, from AI downscaling) look slightly noisy next to the 200-450-colour ones,
but they read fine at game scale. Optional: quantize them to 64 colours.

| file | grade | rules failed | specific problem | fix prompt / method |
|---|---|---|---|---|
| ch_allergy.png | PASS | — | New style, 26u, grid intact | — |
| ch_baron.png | PASS | — | New style, 26u | — |
| ch_bdaydad.png | PASS | — | New style, 26u | — |
| ch_bozos.png | PASS | — | 27u; P1 OK (made-up face) | optional quantize |
| ch_brittany.png | PASS | — | 26u, on-model | optional quantize |
| ch_butler.png | REDO | S1, S3 | Old chibi, 30u | regenerate in new style at 26u, same 4x4 layout |
| ch_camper.png | PASS | — | 26u | — |
| ch_cashier.png | REDO | S1, S3 | Old chibi, 30u (pharmacy minigame) | regenerate |
| ch_chef.png | REDO | S1, S3 | Old chibi, 30u (phone minigame) | regenerate |
| ch_coupon.png | PASS | — | 26u | — |
| ch_crypto.png | PASS | — | 26u | — |
| ch_dasher.png | PASS | — | 26u | — |
| ch_djvape.png | PASS | — | 26u | — |
| ch_dolores.png | PASS | — | 26u; the attack frame's coffee splash is dark red-brown (reads as coffee at game scale) | — |
| ch_donald.png | PASS | — | 26u; P1 OK (no real likeness) | — |
| ch_drunk.png | REDO | S1, S3 | Old chibi, 30u; a common enemy, so seen a lot | regenerate (high priority among NPCs) |
| ch_duff_suit.png | FIX | S4 (minor), D5 | 256x256, 4x4@64, 26u. The tux covers the arms (D7 OK), but both hands are plain skin, and the neck mark appears in BOTH profile rows (rows 2 and 3 are near-mirrors), so the fox shows on his right side in the left-facing row. Pink/cyan fringe pixels on the hair outline (downscale artifact). Build reads only medium at chibi scale. | Programmatic, not Canva (see §4). Darken 2-3 px on the back of his LEFT hand and 1 row on his RIGHT hand. Recolour the neck-mark pixels to skin in row 3. Snap the fringe pixels to the outline colour. |
| ch_fences.png | PASS | — | 26u; P1 OK | optional quantize |
| ch_ghoster.png | PASS | — | 26u | — |
| ch_grillboy.png | REDO | S1, S3 | Old chibi, 30u. Only referenced in the art manifest (probably unused) | regenerate or delete; lowest priority |
| ch_gymbro.png | PASS | — | 28u (a big guy, so the extra height is in character) | — |
| ch_heckler.png | REDO | S1, S3 | Old chibi, 30u; common enemy | regenerate (high priority) |
| ch_hoa.png | REDO | S1, S3 | Old chibi, 30u; enemy | regenerate |
| ch_husk.png | PASS | — | 26u; P1 OK | optional quantize |
| ch_hustler.png | REDO | S1, S3 | Old chibi, 30u; enemy | regenerate |
| ch_inspector.png | REDO | S1, S3 | Old chibi, 30u; daily event | regenerate |
| ch_jen.png | PASS | — | 26u | — |
| ch_karen.png | REDO | S1, S3 | Old chibi, 29u; enemy | regenerate (high priority) |
| ch_karen_buddy.png | REDO | S1, S3 | Old chibi, 29u; enemy | regenerate |
| ch_kid.png | REDO | S1 | Old chibi (22u is the right scale for a kid) | regenerate at ~20-22u |
| ch_madison.png | PASS | — | 26u, on-model (striped top, teal-tipped hair) | — |
| ch_madison_dress.png | REDO | S1, S3 | Old chibi, 29u, generic brown hair. **Madison looks like two different people** depending on the outfit (symphony minigame). | regenerate from ch_madison in a dress, 26u (high priority) |
| ch_pete.png | REDO | S1, S3 | Old chibi, 30u; enemy | regenerate |
| ch_pharmacist.png | REDO | S1, S3 | Old chibi, 29u; in cast.json | regenerate |
| ch_phlebotomist.png | REDO | S1, S3 | Old chibi, 30u; doesn't match the plasma nurse in plasma_day | regenerate to match the loading-art nurse |
| ch_pirate0.png | FIX | S2 (minor) | 26u. In row 2 col 3 the thrown box is clipped at the cell's right edge (x=63). Byte-identical to pirate2. | Shift the box 3 px left inside that cell, or accept it. Make pirate2 a real variant (hood colour). |
| ch_pirate1.png | PASS | — | 26u. Byte-identical to pirate3 | optional recolor variant |
| ch_pirate2.png | FIX | S2 (minor) | Same file as pirate0, same clipped box | same as pirate0 |
| ch_pirate3.png | PASS | — | Same file as pirate1 | — |
| ch_regular.png | PASS | — | 28u (big guy, fine) | — |
| ch_scammer.png | REDO | S1, S3 | Old chibi, 30u; enemy | regenerate |
| ch_sendback.png | PASS | — | 26u | — |
| ch_sitter.png | REDO | S1, S3 | Old chibi, 29u; used in dates/phone | regenerate |
| ch_sushi_chef.png | REDO | S1, S3 | Old chibi, 30u; manifest only (probably unused) | regenerate or delete; lowest priority |
| ch_usher.png | REDO | S1, S3 | Old chibi, 30u | regenerate |
| ch_waitress.png | REDO | S1, S3 | Old chibi, 29u; manifest only and superseded by ch_dolores | delete, or point at ch_dolores |
| ch_willnot.png | PASS | — | 26u; P1 OK | optional quantize |
| av_duff.png | REDO | S1, D6, D5 | **48x48**, single cell (not a grid). Old chibi style: cream tee with a green tag, no undercut, no ponytail, no plugs, no fox. Duff's own HUD avatar doesn't look like Duff. | Rebuild it programmatically from the head and shoulders of `duff_apron_black` row 0 col 0 (crop x16-48, y8-40 → 32x32, then pad/compose to 48x48 with no rescale), or regenerate: "48x48 pixel avatar, Sea of Stars style, dirty-blond undercut with ponytail, ginger stubble, black plugs, black tee, 2-3 px dark fox mark on the VIEWER'S RIGHT of the neck". |

## 3. Priority list (worst 10)

1. **fryer_nap.jpg**: REDO. Bare arms, not buff, wrong-side fox.
2. **gym_spot.jpg**: fully bare, center-frame buff arms; the most visible miss.
3. **plasma_day.jpg**: the focal IV arm should be the blackout sleeve and is bare.
4. **av_duff.png**: Duff's own HUD face doesn't look like him (old style, no hair/plugs/fox).
5. **waffle_showoff.jpg**: wrong style for loading art (H1), plus bare arms.
6. **raccoon_break.jpg**: no blackout sleeve; flames where the creature head should be.
7. **one_trip.jpg**: bare, thin, veiny forearm.
8. **ch_madison_dress.png**: Madison changes into a different, older-style person in a dress.
9. **rent_slot.jpg**: malformed neck, bare hands and forearm.
10. **goose_bet.jpg**: bare forearms under rolled sleeves.

Next in line: the old-chibi enemy batch, most-seen first: ch_drunk, ch_heckler, ch_karen, ch_karen_buddy, ch_hoa, ch_hustler,
ch_pete, ch_scammer, ch_kid, ch_butler. Then flip all D5 images (octavia_fund, omaha_winter, and the others after their ink is added).

## 4. Recommendation: tattooing the Duff sprite sheets

**Scope.** `ch_duff_suit.png` is the only `ch_duff*` sheet. The sprites actually on screen most are the `duff_*` outfit
sheets, which have the same format:
- 13 sheets at **256x256 = 4x4 @ 64x64**: apron, clogs, coat, dad, sleeves (black/red variants of each), home, suit.
- `duff_roll_*` at **256x64 = 1x4**.
- `duff_dress` at **384x192 = 6x3**.

All use origin (32,60), `s: 2`, binary alpha, and about 2,000 colours. In **every `duff_*` sheet, row 3 (facing left) is a
byte-exact mirror of row 2 (facing right)**. The flip shows his right side but keeps the left-side ink. As a result, a
left-arm sleeve and the fox would appear on his right side in every left-facing frame, unless row 3 is inked separately.

**Do not use a Canva image edit.** A generative edit re-renders the whole raster. It will:
- resample away from 256x256,
- add anti-aliased and semi-transparent edges (alpha is binary now),
- shift figures off the 64-px cells and the (32,60) origin,
- invent palette colours, and
- probably redraw frames differently from each other.

Any one of those breaks S2. With tiny arms (a 6x9 px forearm and hand), a prompt can't control which pixels change anyway.

**Do a programmatic pixel recolor instead.** Claude can run this in the sandbox; Duff only has to approve a before/after image.
1. **Find arm pixels per cell.** Take skin pixels by HSV (hue 0.02-0.11, S>0.25, V>0.45, alpha 255) below the neck line
   (cell y ≥ 38). Group them into connected blobs, and use the blob centroid against the torso centre x≈32 to decide which arm
   each blob is. Measured regions (cell-local, apron frame 0):
   - **Row 0 (front):** his RIGHT arm is the viewer-left blob, x≈18-24, y≈44-52 (forearm y44-48, hand y48-52). His LEFT arm is
     the viewer-right blob, x≈40-46, y≈44-52. Tee sleeves cover y≈38-44.
   - **Row 1 (back):** sides swap. His LEFT arm is on the viewer's left.
   - **Row 2 (faces right):** the visible arm is his LEFT, x≈23-30, y≈40-51. The neck mark at x≈28-34, y≈30-35 is correct.
   - **Row 3 (faces left):** the visible arm is his RIGHT. Ink it separately, and recolour the mirrored neck mark to skin.
   - **Col 3 (swing):** arms cross the body, so the blob/centroid assignment matters here. Spot-check these 4 frames by eye.

   Measured skin below the neck: about 80 px per arm in apron/tee outfits (forearm + hand), and 35-45 px (hands only) in
   sleeves/coat/suit/clogs.
2. **LEFT arm (blackout).** Map each skin pixel to an ink ramp by its original brightness tier: #3b3946, #2a2832, #1b1a20. Then
   restore 1 skin-highlight pixel every 2-3 rows on the forearm as negative-space geometry. On the back of the hand, use a 2x2
   dark block with 1 pale centre pixel (the eye in the triangle ring). Leave fingertips and outline pixels untouched.
3. **RIGHT arm.** On the forearm, place a 3x3 patch of #2b2530 with 1 orange #ff8c1a pixel (creature eyes), plus 1 dark pixel
   row at the wrist (bracelet). On the back of the hand, 1 row of 2-3 dark pixels (script). Where the upper arm is bare (roll
   frames, any sleeveless frame), blend 40% toward #77737d for the grey-wash.
4. **Neck.**
   - Row 0: put a 2x3 fox mark (#6b4a2e plus 1 px #9fd3ff) on the viewer-right side of the neck.
   - Row 1: 1-2 px on the viewer-left.
   - Row 2: keep.
   - Row 3: remove.
5. **Guardrails.**
   - Assert the image size and the full alpha channel are identical before and after.
   - Assert only opaque pixels that started as skin changed.
   - Add only these ~8 ink colours.
   - Run it on all 16 Duff sheets in one pass.
   - Keep the masters in `grok_art/2026-11-09-sprite-ink/` (R5).
   - Save a before/after sheet at 1x and 4x to `docs/renders/`.
   - Run `godot --headless --path . --import` (R1).
   - Render one in-game frame per outfit to confirm "dark arm + lighter inked arm" reads at real scale.
6. **Build (S4/D1).** Recolouring can't add muscle. The chibi body is medium-built. If Duff wants him to read buffer, that needs
   a 1-px wider shoulder and arm outline pass. That is a separate, hand-checked change, not part of the ink script.
