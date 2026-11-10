# KO stills review (`assets/art/ko/*.jpg`, 39 files), Nov 9 2026

Graded against `docs/art_rules.md` (including the Nov 9 H2 change: cartoon blood is allowed, but fix prompts never ask
for it). Every file was opened at full 1280x720 and the Duff arms, necks and x-ray insets were zoom-cropped. All 39 are
1280x720 (H4 OK). Duff was checked against `docs/ref/duff/photo_front.jpg`, `photo_left_shoulder_mandala_full.jpg` and
`portraits_hd/duff.png`.

**Totals: 20 PASS, 19 FIX, 0 REDO.**

## Problems that show up across many files (read these first)

1. **D5, fox on the wrong side of the neck (14 files).** In `photo_front.jpg` the fox and the blackout sleeve are on
   the same side of his body (his LEFT, the viewer's right when he faces the camera). In almost every KO still Duff
   faces the VIEWER'S RIGHT, so the side of his neck we see is his RIGHT. The fox is drawn there, under the ear we can
   see, which puts it on the opposite side from the blackout arm. **Root cause: `portraits_hd/duff.png` has the same
   mistake**: the head is turned to the viewer's right and the fox sits on the side of the neck we can see. Every
   prompt that attaches that portrait inherits the error. Fix the portrait (or add a line to the prompt) before doing
   more edits, or the error will keep coming back.
   *Rule for prompts:* when Duff faces the viewer's right, the fox is on the FAR side of his neck: just a sliver at the
   edge of the throat, toward the viewer's right, mostly hidden. The arm nearest the viewer is his right arm (grey
   flames, creature head, blackletter hand). The far arm is the blackout sleeve.
2. **Duff's striking hand or arm drawn bare (gymbro_b, djvape_b, crypto_b, sendback_b, duff_walk).** These are the
   stills where the hit is drawn as a pale manga arm or fist. D2 and D4 say a visible bare arm or hand has to show its
   ink.
3. **The creature head drawn as a cat (duff_slip, duff_fin2).** D3 says it must not be a panther or a cat.
4. **`docs/duff_look.md` line 63 contradicts D3.** It still says "panther on the RIGHT forearm". It should say
   "creature head (NOT a panther)". `docs/knockout_cutscenes.md` lines 49-52 also still describe the duck, TV and
   lightbulb heads that P1 now bans. The art itself uses human faces, so the art is right and the docs are stale.
5. **K6 (soft).** The batch-2 B stills (husk_b, bozos_b, fences_b, donald_b, willnot_b) all use the same layout:
   Duff on the viewer's left facing right, the boss on the viewer's right, the impact in the middle. husk_b and
   donald_b are nearly the same composition. This is not a hard fail, so it is noted here and not used to grade them.

## Per-image grades

| file | grade | rules failed | what is wrong (specific) | image-edit prompt (FIX/REDO) |
|---|---|---|---|---|
| duff_stance.jpg | FIX | D2, D5 | The forearm on the VIEWER'S RIGHT (his left) is orange skin with thin mandala line art, not a heavy blackout sleeve. The fox is on the viewer's LEFT side of his neck, the side opposite the sleeve. The eye on the raised hand and the dark patch on the extended forearm are fine. The top-left inset portrait is OK. | Edit the main standing figure only. Make the forearm on the VIEWER'S RIGHT (the raised hand) a heavy blackout tattoo sleeve: solid black ink from the T-shirt sleeve to the wrist, with a big star mandala and chevron/triangle bands cut out in skin-tone negative space. Keep the eye-in-triangles on the back of that hand. Move the fox neck tattoo from the viewer's left side of his neck to the viewer's RIGHT side of his neck, on the same side as the black sleeve. Change nothing else. |
| duff_slip.jpg | FIX | D5, D3 | The whole Duff is mirrored: the blackout arm is on the viewer's LEFT and the fox is on the viewer's left side of the neck, so both are on his RIGHT side. Both should be on his left. The creature head on the lower forearm (viewer's right) is a pointy-eared cat face. | Step 1: flip the whole image horizontally. Step 2, on the flipped image: on the forearm now on the VIEWER'S LEFT, replace the cat-like head with a dark creature head that is not a cat, panther or lion: a broad snout with a nose and freckle dots, several small glowing orange eyes, a pink tongue curling out, framed by orange-gold leaves, in grey-wash ink. Keep everything else. |
| duff_fin1.jpg | FIX | D5 | The arms are correct: grey-wash horns, a creature head and a blackletter hand on the viewer's left; a blackout sleeve and an eye fist on the viewer's right. But the fox sits on the viewer's left side of his neck (his right), the side we see. | Move the fox neck tattoo off the side of his neck facing the viewer. Put it on the far side of his neck, toward the VIEWER'S RIGHT (the same side as the black-sleeved raised fist), with only a sliver showing at the edge of the throat. Change nothing else. |
| duff_fin2.jpg | FIX | D5, D3 | The fox is under the ear we can see (his right). The creature head on the forearm on the VIEWER'S LEFT is a black cat face with pointed ears. The blackout kicking-side arm and the script hand are fine. | Move the fox neck tattoo to the far side of his neck (toward the VIEWER'S RIGHT, the black-sleeve side), with only a sliver showing. On the forearm on the VIEWER'S LEFT, replace the black cat face with a dark creature head that is not a cat or panther: a broad snout with nose and freckle dots, several small glowing orange eyes, a curling pink tongue, framed by orange-gold leaves, in grey-wash ink. Change nothing else. |
| duff_fin3.jpg | FIX | D5 | The arms are correct and the eye fist is excellent. The fox is large and on the viewer's left of his neck (his right side). | Move the fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT (the side of the big black-sleeved fist), mostly hidden behind the jaw. Change nothing else. |
| duff_walk.jpg | FIX | D2, D3 | Back view, and the fox side is correct. But both bare wrists and forearms under the rolled sleeves have no ink. The red smear under the downed boss is fine under the new H2. | Edit only Duff's two visible wrists and forearms, below the rolled black shirt sleeves. Make the one on the VIEWER'S LEFT solid blackout tattoo ink with thin skin-tone triangle and chevron cut-outs. Give the one on the VIEWER'S RIGHT grey-wash tattoo ink with a thin black bracelet at the wrist. Keep the hands in the pockets and change nothing else. |
| gymbro_a.jpg | PASS | none | Gritted-teeth wind-up, his own face, neon palette, no text. | none |
| gymbro_b.jpg | FIX | D2, D4, D5 | x-ray: line "a bicep is just a tendon with a marketing budget. Mine finds the tendon." The strike lands on the bicep and the inset shows a tendon tearing, so K1 passes. But Duff's striking forearm and fist below the black jacket cuff are bare pale skin with no ink, and the fox is on the side of his neck we see. | On Duff (viewer's left), make the bare forearm and fist coming out of the black jacket cuff a solid blackout tattoo sleeve with skin-tone geometric cut-outs, with an eye inside a ring of sharp triangles on the back of the fist, in the same monochrome manga ink. Move the fox neck tattoo to the far side of his neck (toward the VIEWER'S RIGHT), mostly hidden. Keep the boss, the impact ring and the x-ray inset unchanged. |
| gymbro_c.jpg | PASS | none | Down, crying, with a selfie phone. Distinct, and the phone screen is blank. (C is "down", not out cold, but it reads as a defeat.) | none |
| ghoster_a.jpg | PASS | none | Smug phone-flick wind-up. | none |
| ghoster_b.jpg | FIX | D2, D3, D5 | x-ray: line "There's a nerve in the ribs called the intercostal." The palm lands on his side ribs and the inset shows the ribcage, so K1 passes. But Duff's punching arm mixes both arms: grey-wash flame shapes on skin on the upper arm, a blackout sleeve on the forearm. The fox is on the side of his neck we see (bottom-left inset too). The bottom-middle face is Ghoster's own, so there is no K3 leak. | On the top-left Duff, make the whole punching arm, shoulder to wrist, one solid blackout sacred-geometry sleeve: remove the grey flame shapes on the bare skin of the upper arm and replace them with black ink and a flower-of-life net in thin skin-tone lines. Keep the eye-in-triangles hand. On both Duff faces (top-left and bottom-left), move the fox neck tattoo to the far side of the neck, toward the VIEWER'S RIGHT. Change nothing else. |
| ghoster_c.jpg | PASS | none | Ghosting away against a wall. The "..." bubble is dots, not text. | none |
| djvape_a.jpg | PASS | none | Smug vape wind-up. | none |
| djvape_b.jpg | FIX | D2, D3, D5 | x-ray: line "The inner ear is three tiny bones and a lot of fluid. One open palm". The palm lands on her ear and the inset shows the ear and cochlea, so K1 passes. But Duff's huge open-palm arm is bare grey skin with no ink, and there is a red fox mark on the side of his neck we see. The red flying bits are headphone shards, which are fine now. | Duff is on the viewer's left. Make his bare striking arm, from the black sleeve to the open palm, a solid blackout tattoo sleeve with skin-tone geometric cut-outs: flower-of-life circles above the elbow, triangle bands on the forearm. Keep the monochrome manga shading. Move the fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT. Keep the woman, the headphones and the ear x-ray unchanged. |
| djvape_c.jpg | PASS | none | Spiral-eye KO on the dance floor, tangled in cables. | none |
| crypto_a.jpg | PASS | none | Smirking NFT card flick. | none |
| crypto_b.jpg | FIX | D4, D5 | x-ray: line "There's a ligament in the ankle that holds up a man's entire belief system. I sweep it." The sweep lands at the ankle and the inset shows the ankle bones, so K1 passes. But both of Duff's visible hands (on the floor and raised) have bare backs with no ink, and the fox is on the side of his neck we see. | On Duff (viewer's left): put bold illegible blackletter tattoo script across the back of the hand resting on the floor (VIEWER'S LEFT). Put a solid black eye-in-a-ring-of-triangles tattoo on the back of the raised hand (VIEWER'S RIGHT), with black ink continuing up the wrist into the jacket sleeve. Move the fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT. Change nothing else. |
| crypto_c.jpg | PASS | none | Down with a smug thumbs-up and a red crash arrow. The coin logos are symbols, not text. | none |
| regular_a.jpg | PASS | none | Grumpy wind-up punch, coffee spilling. | none |
| regular_b.jpg | FIX | K1, D6 | x-ray: line "I don't hit it. I hit everything around it". The inset (fist on the ribcage) matches the line. But in the main panel neither visible fist is Duff's: both are the boss's, and the impact burst sits on the boss's forearm at the bottom-left, not on his chest. Duff's face is generic: darker hair, no ponytail visible. | In the main panel, add Duff's fist (a black-sleeved forearm, with a black eye-in-triangles tattoo on the back of the fist) driving into the boss's chest just below the suspender buckle on the VIEWER'S LEFT, and move the white impact burst onto that spot. Give Duff dirty-blond hair tied back in a ponytail and a ginger-blond stubble beard. Keep the coffee-mug and rib x-ray insets. |
| regular_c.jpg | FIX | K5, H3 | Lovely closer. But the dollar bills (main panel and inset) have a realistic portrait and fake micro-text. | Simplify both dollar bills on the table into plain green cartoon bills with no portrait and no lettering, just a plain oval and border shapes. Change nothing else. |
| sendback_a.jpg | PASS | none | Angry plate-shove with pointing. | none |
| sendback_b.jpg | FIX | D4, D5 | x-ray: line "One uppercut and he tries something new." The uppercut lands under the chin and the inset shows the skull and jaw, so K1 passes (mouth area). But Duff's uppercut fist is bare and pale, and the fox is on the side of the neck we see on both Duff faces. | Put a solid black eye-inside-a-ring-of-sharp-triangles tattoo on the back of Duff's uppercut fist (center), with black ink continuing into his sleeve. On both Duff faces (top-left inset and middle-left), move the fox neck tattoo to the far side of the neck, toward the VIEWER'S RIGHT. Change nothing else. |
| sendback_c.jpg | PASS | none | Face-down in the plate. | none |
| husk_a.jpg | PASS | none | Grinning jetpack punch. Original face (P1 OK). | none |
| husk_b.jpg | FIX | D5, D4 | x-ray: line "The jaw is the only bone in the skull that moves. My elbow shows it somewhere new to go." The elbow lands on the jaw and the glowing skull and jaw show through, so K1 passes. The blackout elbow is good. But the fox is on the side of the neck we see, and the near hand (viewer's left) has a round sigil instead of bold blackletter lines. | Move Duff's fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT. On the back of the hand at the bottom-left (VIEWER'S LEFT), replace the round emblem with several lines of bold illegible gothic blackletter script running from the knuckles to the wrist. Change nothing else. |
| husk_c.jpg | FIX | K5, H3 | Spiral-eye KO is good. But the phone on the right shows red blocky fake letters under the crash chart. | On the cracked phone at the right, remove the red letter-like blocks at the bottom of the screen, leaving only the red falling zig-zag chart line on black. Change nothing else. |
| bozos_a.jpg | PASS | none | Smug buck-tooth wind-up in a box mech. | none |
| bozos_b.jpg | FIX | D5 | x-ray: line "Two hinges hold a jaw on... My knee comes up from below, and both hinges quit". The knee lands under the jaw, and the jaw x-ray glows at both hinges. K1 is excellent. The arms are correct. Only the small fox/pink mark is on the side of the neck we see. | Move the small fox neck tattoo to the far side of Duff's neck, toward the VIEWER'S RIGHT, mostly hidden. Change nothing else. |
| bozos_c.jpg | PASS | none | Spiral-eye KO in a busted box. The forehead shipping label is illegible smudge, which is acceptable. | none |
| fences_a.jpg | PASS | none | Smug laptop swing. Human face (P1 OK). | none |
| fences_b.jpg | FIX | D5 | x-ray: line "The spine is thirty-three vertebrae stacked like dirty plates. I clear the stack. Top to bottom." The palm lands on his back and the whole spine shows through, so K1 passes. The arms are correct. Only the fox is wrong: it is on the side of the neck we see. | Move Duff's fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT, mostly hidden. Change nothing else. |
| fences_c.jpg | PASS | none | Spiral-eye face-plant on the desk. The paper has lines only. | none |
| donald_a.jpg | PASS | none | Angry pointing wind-up. Human face, and a duck only as the tie pin (P1 OK). | none |
| donald_b.jpg | FIX | D5, D3 | x-ray: line "The human hand has twenty-seven bones... My fist says so the loudest." The fist meets his hand and the hand bones x-ray, so K1 passes. But the fox is on the side of the neck we see, and the near forearm (bottom-left) shows a skull and flower instead of the creature head. | Move Duff's fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT. On the forearm at the bottom-left (VIEWER'S LEFT), replace the skull with a dark creature head: broad snout with nose and freckle dots, several small glowing orange eyes, a curling pink tongue, framed by orange-gold leaves, in grey-wash ink, NOT a cat or panther. Change nothing else. |
| donald_c.jpg | PASS | none | Spiral-eye KO with a tie in his mouth. (Note: the thumbs-up pose repeats crypto_c, but the face is different, so K2 is OK.) | none |
| willnot_a.jpg | PASS | none | Grinning barefoot wind-up. Foot cuts and glass are OK under the new H2. | none |
| willnot_b.jpg | FIX | D5 | x-ray: line "I'm not cruel. I aim higher. The jaw goes up." The eye-fist uppercut lands on the jaw and the jaw glows, so K1 passes. The arms are correct. Only the fox is on the side of the neck we see. | Move Duff's fox neck tattoo to the far side of his neck, toward the VIEWER'S RIGHT, mostly hidden. Change nothing else. |
| willnot_c.jpg | PASS | none | Dazed, flat on the wet floor. | none |

K2 check: all 13 bosses have their own A, B and C faces, and none copies Ghoster. K3 check: no leaked or duplicated
faces in any panel. The only extra faces are the bosses' own insets and Dolores in regular_c, who is the scripted crowd
speaker. K1: 12 of the 13 B stills are correct. regular_b's main panel does not show the strike landing on the chest.
K5: no move names or captions anywhere. The only text-like marks are husk_c's phone and regular_c's bills.

## Priority list: worst 10

1. **regular_b.jpg**: the only K1 (HARD) failure. The main panel never shows Duff landing the chest hit, and his face is generic.
2. **duff_slip.jpg**: the whole Duff is mirrored (sleeve and fox on his right) and the creature is a cat. Used in every KO.
3. **duff_fin2.jpg**: the creature is a black cat (D3), plus the fox side. Used in every KO.
4. **duff_walk.jpg**: bare, uninked forearms on the closing shot of every KO.
5. **duff_stance.jpg**: thin line-art forearm instead of blackout, plus the fox side. It opens every KO.
6. **ghoster_b.jpg**: the punching arm mixes the flame arm and the blackout arm. It is also the layout ref the other B stills were built from.
7. **djvape_b.jpg**: a huge bare, uninked striking arm fills a third of the frame.
8. **gymbro_b.jpg**: bare striking forearm and fist on the pilot boss.
9. **donald_b.jpg**: a skull on the forearm instead of the creature head, plus the fox side.
10. **sendback_b.jpg**: bare uppercut fist, and the fox side twice.

After those: crypto_b, husk_b, husk_c, regular_c, then the fox-only fixes (duff_fin1, duff_fin3, bozos_b, fences_b,
willnot_b). Fix `portraits_hd/duff.png` and the stale line in `duff_look.md` first, or the D5 error will come back.

## Fix log (Nov 9, HD art fixer pass)

I re-checked every FIX row against the current file before acting, because several stills had already been edited today. They
still failed the same rules. Masters: `grok_art/2026-11-09-fixes/ko_<name>.png` (1920x1080 Canva exports). The originals as they
stood before this pass: `grok_art/2026-11-09-fixes/before/`. Before/after sheet: `docs/renders/art_fixes_nov9.jpg`. I judged
every result at full size and zoomed into the arms, neck and x-ray.

| file | what changed | how |
|---|---|---|
| duff_stance | The raised forearm on the viewer's right is now near-solid black with skin-line mandala and chevrons (it was line art on skin). The wrong-side fox under the visible ear is removed. The inset face's neck is cleaned up. | Canva edit x2, then a local PIL patch for the fox (Canva would not move it) |
| duff_slip | The whole image is flipped, so the sleeve and fox are now on his left. The cat-eared forearm head is replaced with a round, ear-less creature (orange eyes, tongue, leaves). | PIL flip, then Canva edit |
| duff_fin1 | Wrong-side fox removed. The raised fist sleeve is darkened to blackout. | Canva edit |
| duff_fin2 | Wrong-side fox removed. The kick-side arm is blackout. The cat head is replaced with a round creature (orange eyes, tongue, leaves). | Canva edit x3 (2nd try rejected: grey blob) |
| duff_fin3 | Wrong-side fox removed. | Canva edit |
| duff_walk | Flipped. Both bare forearms are inked: blackout on his left, grey-wash and a bracelet on his right. | PIL flip, then Canva edit |
| regular_b | K1 fixed: Duff's black-sleeved eye-fist now lands under the suspender buckle, and the burst is moved there. Duff has the blond ponytail and stubble. | Canva edit |
| regular_c | Bills are plain green with an empty oval (no portrait, no micro-text). | Canva edit |
| gymbro_b, djvape_b | The striking arm is a solid blackout sleeve with an eye-in-triangles hand. Wrong-side fox removed. | Canva edit |
| ghoster_b | The punching arm is one blackout sleeve from shoulder to wrist (the flame shapes are gone). Fox removed on both Duff faces. | Canva edit |
| crypto_b | Eye-in-triangles on Duff's floor fist with black ink up the wrist. Script on the other hand. The stray eye the 1st try put on the boss's hand is removed. Fox removed. | Canva edit x2 |
| sendback_b | Eye-in-triangles on the uppercut fist. Fox removed on both faces. | Canva edit |
| husk_b | Fox removed. The round sigil on the near hand is replaced by blackletter. | Canva edit |
| husk_c | The fake red letters on the phone are gone; only the chart line is left. | Canva edit |
| donald_b | Fox removed. The forearm skull is replaced by the round creature head. | Canva edit |
| bozos_b, fences_b, willnot_b | Wrong-side neck mark removed. | Canva edit |

K1 and K3 were re-checked on every B still. All x-ray insets are unchanged, and no new faces leaked in. Nothing is left failing in this set.
Still open (not in my scope): K6, the soft layout sameness of the batch-2 B stills.

## Last 6 bosses (Nov 9, ko-last6): coupon, allergy, camper, bdaydad, dasher, baron

18 new stills, all opened at full size (1920x1080 masters in `grok_art/2026-11-09-ko-last6/`, game files 1280x720 q88).
Refs per still: boss face sheet (`portraits_hd/<boss>.png` on white) + `ko/willnot_a.jpg` as style-only for A/C;
`ko/duff_stance.jpg` + `portraits_hd/duff.png` + boss face sheet for B. Scratch export design: `DAHabdund5o` (the old
`DAHaZZaEJBs` hit Canva's 102-page edit limit).

| file | grade | notes |
|---|---|---|
| coupon_a/c, allergy_a/c, camper_a/c, bdaydad_a/c, dasher_a, baron_a/c | PASS | own faces, neon palettes, no text |
| coupon_b | PASS after 2 fixes | try 1: one arm had TWO hands (H3). Try 2 (removed it) put the sleeve on his RIGHT (D5). Fixed by mirroring + Canva edit: fox removed from the visible neck side, grey-wash ink on the far arm. K1: knuckles into the forearm flexor, x-ray shows radius/ulna at the contact point. |
| allergy_b | PASS | over-the-shoulder; blackout left jab into the solar plexus, x-ray shows breastbone tip, lower ribs, diaphragm |
| camper_b | PASS after 2 edits | grabbing (right) arm was bare -> grey-wash + creature forearm; eye on that hand -> blackletter. Knee into the hip, x-ray shows pelvis/femur head. |
| bdaydad_b | PASS | low shin kick into the knee, knee joint x-ray; blackout left arm with eye hand on the floor |
| dasher_b | PASS after 1 fix | xray line names no bone, so the hit is a stiff-arm across the collarbones (x-ray: both clavicles). Same D5 mirror problem as coupon_b, same fix. |
| dasher_c | PASS after fix | try 1 tripped Canva's safety filter ("cherry filling oozing" read as blood); try 2 drew swoosh-like logos on the sneakers, Canva edit only faded them, finished with a local PIL recolor (faint outline left, unreadable at 1280). |
| baron_b | PASS after 1 fix | kidney shot to the lower back, x-ray shows lumbar spine + floating ribs. Same D5 mirror fix; far arm now grey-wash, creature, blackletter hand. |

**Gotcha (new):** "Duff on the viewer's right, facing the viewer's left" makes Canva draw him chest-on, so the arm on the
viewer's LEFT of his torso is his RIGHT arm, and it put the blackout sleeve there with the fox on his left neck (D5). Prompt
that worked (allergy_b, camper_b, bdaydad_b): blackout arm explicitly on the VIEWER'S RIGHT side of his torso, or an
over-the-shoulder shot from behind his LEFT shoulder. Cheap fix: mirror the image, then a Canva edit that removes the
visible-side fox and inks the far arm grey-wash. K3: no leaked faces in any B still (style ref had no characters in the B
prompts). K6: the six B layouts all differ.
