# Style C conversion (Nov 9, 2026, branch `style-c-convert`)

Old anime-style HD art redrawn in locked house style C (`docs/art_direction/STYLE_LOCK.md`), same file names, sizes and
formats (1280x720 JPG q88), so no code changed. Old files: `grok_art/2026-11-09-style-c-convert/old/`. Masters
(1920x1080 Canva exports): `grok_art/2026-11-09-style-c-convert/` (rejects in `rejected/`).
Refs for every Duff image: canonical face sheet `MAHacL92VLk` FIRST, then the old still (composition), then the
approved style-C stance master (`MAHacddYdLM`, = `grok_art/2026-11-09-art-direction/stance_C.png`) as the style ref.
Scratch export design `DAHacBeu8SQ` (pages 25+). Every image graded at full size against ST1-ST7 + D1-D7.

## Batch 1: Duff's 6 shared KO frames

Renders: `docs/renders/style_c_convert_duff_ko.jpg` (old vs new), `docs/renders/style_c_convert_ko_gymbro_beats.jpg`
(engine, all beats of one KO).

| file | grade | notes |
|---|---|---|
| duff_stance | PASS | The approved `stance_C` master from the style pick (fox already fixed there), shipped as-is. |
| duff_slip | PASS after 1 fix | Try 1 put the fox on the visible neck side, which is his RIGHT (D5/ST7). Canva edit removed it on him and the afterimages. Blackout sleeve on his left (viewer's right), creature forearm + blackletter hand on the near arm. |
| duff_fin1 | PASS after 1 fix | Same fox miss as slip (head turned to the viewer's right shows his right neck). Edit removed it. Eye-in-triangles on the blackout fist. Knee has no crack hatching (ST3 allows none). |
| duff_fin2 | PASS | Flying kick, no city/smoke now. Blackout upper arm with eye hand, grey-wash + creature + script on the other arm, no neck ink on the visible (right) side. |
| duff_fin3 | PASS | Eye-in-triangles blackout fist through a flat white/amber ring, creature forearm on the other arm, visible neck clean. Light grain on the sleeve and burst, reads flat at 1280. |
| duff_walk | PASS (soft) | From behind: blackout forearm on his left, grey-wash + bracelet on his right, visible neck clean. Soft note: the lamp cone is a soft gradient (ST2 nit, background only). |

Gotcha (again): any time Duff's head turns toward the viewer's right, the visible neck is his RIGHT side and Canva
still paints the fox there even when the prompt says "only on the viewer's right". One cheap edit fixes it ("remove the
neck tattoo, plain skin"); with the face sheet as the first ref the edit kept everything else.

## Batch 2: the 13 loading screens (`assets/art/loading/`)

Refs: face sheet `MAHacL92VLk` first whenever Duff is in it, then the old screen (gag and layout), then the
character's `portraits_hd/` sheet for Madison (`MAHacYhIu5c`), Brittany (`MAHacQ_ShTE`), Octavia (`MAHacZsntEg`), then
the left half of the Coupon Carol card (`MAHacUbzTKs`, flat sunburst, no lettering) as the style ref. Prompts asked
for a flat simple set, a calm lower third, no hatching and no speed lines (ST3/ST4).
Renders: `docs/renders/style_c_convert_loading.jpg` (old vs new, all 13), `docs/renders/style_c_convert_loading_engine.png`
(engine loading screen with the caption bar).

| file | grade | notes |
|---|---|---|
| brunch_atlas | PASS after 1 fix | Try 1 put the fox on his RIGHT neck (face turned to the viewer's right). Edit removed it. Blackout + eye fist on his left, creature/grey-wash + script on the other. |
| fryer_nap | PASS | Dolores pours coffee at sleeping Duff. Blackout + eye hand, creature forearm, script hand all right. Visible neck is his left (fox hidden under the jaw). Name badge blank. |
| goose_bet | PASS after 1 fix | Try 1 had blackwork flowers on the creature forearm and script on the raised palm (D3/D4). Edit: creature head + leaves on the near forearm, script fist, plain palm. Brittany matches her sheet. Duff's face slightly narrower than the sheet (soft). |
| gym_spot | PASS | Gym Bro spots a rolling-pin bench with waffle-iron plates. Eye hand + blackout on his left, script hand, grey-wash upper arm, neck clean. |
| octavia_fund | PASS | Octavia hugs the coin jar; Madison matches her sheet. Duff: blackout + eye hand on his left, grey-wash arm, neck clean. Calm table for the caption. |
| omaha_winter | PASS | Hoodie + gloves cover the arms (D7). Flat sky/sunburst, skyline. |
| one_trip | PASS after 1 fix + local patch | Try 1 had the eye-in-triangles on BOTH hands. The edit added blackletter but left a small eye in the middle of it; finished with a local PIL patch (script strip pasted over the eye, feathered). Fox is on his visible LEFT neck (correct). |
| plasma_day | PASS | Blackout thumbs-up with the eye on the back of the hand, creature arm with the needle, script hand. No blood. |
| raccoon_break | PASS | Raccoon in a hairnet; fox on his visible LEFT neck (correct); blackout + eye hand on his left. |
| regular_5am | PASS | Earl + mug pyramid + Dolores, flat sunrise sunburst. No Duff. |
| rent_slot | PASS (soft) | Side view of his RIGHT side: creature forearm + script hand on the jar, blackout far arm on the floor (reads a bit like a dangling tie). Neck clean. |
| waffle_showoff | PASS | Blackout + eye fist on the pan, grey-wash back arm, red shoes, neck clean. Neon cup glow is the only soft gradient. |
| witnesses | PASS | Porch pirate + the three cats; no Duff, no text. |

Notes: ST3/ST4 hold on all 13 (no hatching, no speed lines, flat sets with a soft sunburst or flat wall). Every
lower third is simpler than the old art; the engine caption bar sits over it fine.
