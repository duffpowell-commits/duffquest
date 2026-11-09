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

## Batch 3: Gym Bro, Ghoster, DJ Vape KO a/b/c

Refs: A/C = old still (composition) + the boss's `portraits_hd/` sheet on white + `ko/husk_a.jpg` (`MAHacVuZoNU`) as
the style ref. B = face sheet `MAHacL92VLk` + old still + boss sheet + `ko/donald_b.jpg` (`MAHacWboDx8`) as the
style ref. Each boss keeps its card's two sunburst tones for the speed lines (Gym Bro browns + hot pink, Ghoster
slate/teal + cyan, DJ Vape charcoal-purple/slate + magenta).
Renders: `docs/renders/style_c_convert_boss_first3.jpg` (old vs new), `docs/renders/style_c_convert_ko_<boss>_beats.jpg`,
`docs/renders/style_c_convert_ko_<boss>_gore.jpg` (in-engine x-ray/finisher blood frames).

| file | grade | notes |
|---|---|---|
| gymbro_a | PASS | Low-angle curl, browns + pink lines, flat muscles, no veins. |
| gymbro_b | PASS | Straight punch into the inner elbow; x-ray of upper-arm + forearm bones with the bicep tendon snapping, plus a close-up inset (K1 = "bicep tendon"). Blackout sleeve + eye-in-triangles fist, grey-wash near arm, neck clean. |
| gymbro_c | PASS | Flat on his back, crying selfie, torn tank, blank phone, crying inset. |
| ghoster_a | PASS | Smug reach + phone, body dissolving into flat smoke; teal lines. |
| ghoster_b | PASS | Rib punch; ribcage x-ray with one glowing nerve along a rib (K1 = intercostal nerve) + close-up inset; two face insets kept. Blackout + eye fist, neck clean. Cracked phone screen has no text. |
| ghoster_c | PASS | Fading into cyan wisps, spiral eyes, "..." bubble (dots only), phone insets. |
| djvape_a | PASS | Vape cloud as flat puffs over the deck, magenta/cyan accents. |
| djvape_b | PASS | Open palm on the ear/headphone; x-ray of the inner ear (ossicles + cochlea) at the contact (K1 = "three tiny bones"). Blackout + eye-in-triangles on the back of the palm, neck clean. |
| djvape_c | PASS | Tangled in cables, spiral eyes, vapes puffing, disco ball, face inset. |

Data: the new B layouts moved the hit and the faces, so `data/knockouts.json` `impact.xray` was retuned for gymbro
and ghoster (contact + mouth) and an override added for djvape (it had none and used the defaults). Checked in the
gore renders: the splat lands on the contact point and the tooth/spit leaves from the mouth.
K3: no leaked faces (style refs husk_a/donald_b carry no characters into A/C; donald_b's Chip face did not leak into
any B). K6: three different B layouts (elbow jab with inset, rib punch with two face insets, open palm to the ear).

## Batch 4: crypto, sendback, regular, coupon, allergy, camper KO a/b/c

Same refs as batch 3 (A/C: old still + boss sheet + `husk_a` style ref; B: face sheet + old still + boss sheet +
`donald_b` style ref). Renders: `docs/renders/style_c_convert_ko_mid6.jpg` (all 18 new),
`docs/renders/style_c_convert_ko_mid6_gore.jpg` (engine x-ray + finisher beats with blood/teeth).

| file | grade | notes |
|---|---|---|
| crypto_a / crypto_c | PASS | NFT-cat tablet push; flat on coins with thumbs-up and spiral eyes, red crash arrow. Coins are plain discs. |
| crypto_b | PASS after 1 fix | Leg sweep, ankle x-ray (bones + torn ligament) + inset (K1 = ankle ligament). Try 1 put the eye hand on BOTH hands (D4). Edit: floor arm is now grey-wash + creature forearm + blackletter hand; the thigh hand keeps the eye. Soft: that eye arm's upper sleeve reads as dark chevrons rather than full blackout. |
| sendback_a / sendback_c | PASS | Finger jab over the steak; face-down in the plate with fork raised, furious inset. |
| sendback_b | PASS | Uppercut, skull/jaw x-ray with the tongue glowing (K1 = taste buds), Duff grin + customer insets. Blackout + eye fist, neck clean. |
| regular_a / regular_c | PASS | Haymaker over the coffee; black eye, Dolores pours, exact-change tip (plain coins and a blank green bill). |
| regular_b | PASS | Duff ducks under the haymaker, punch under the suspender buckle; inset x-ray of the ribcage cracking around a calm whole heart (K1 = "hit everything around it"). Blackout + eye fist. |
| coupon_a / coupon_c | PASS | Binder wind-up; down on the coupons, spiral eyes, coupon on the forehead. Coupons blank. |
| coupon_b | PASS (no new gen) | The approved style-pick master `grok_art/2026-11-09-art-direction/coupon_C.png` (already C, D1-D7 + K1 graded Nov 9) shipped as-is. |
| allergy_a / allergy_c | PASS | Throat-clutch accusation; down in the rolls, free cake on the table. |
| allergy_b | PASS | Over Duff's LEFT shoulder: blackout + eye fist into the solar plexus, fox on the visible (left) neck = correct. X-ray ribs, breastbone tip, diaphragm. |
| camper_a / camper_c | PASS | Patched laptop-bag swing; KO on the floor, laptop on his chest, blank screen. |
| camper_b | PASS | Knee to the hip, pelvis + femur-head x-ray (K1). Grabbing arm (viewer's left) creature forearm + blackletter hand; far arm blackout + eye hand; fox on viewer's right neck = correct. |

Data: all six had no `impact` override; added one per boss in `data/knockouts.json` so the engine splat sits on the
new contact points (checked in the gore render).
K3: no leaked faces. K6: six different B layouts (sweep, uppercut, duck-under body shot, forearm tap, over-shoulder
jab, knee).
