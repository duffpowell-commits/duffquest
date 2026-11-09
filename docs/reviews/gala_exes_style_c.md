# Gala exes art in house style C (Nov 9, 2026)

All four gala exes now have a style-C HD portrait (`portraits_hd/<id>.png`, 3 cells smug/shocked/enraged), a burst
intro card with the name lettered in code (`boss_intro/<id>.png`, `tools/letter_card.py`, Baloo 2 ExtraBold), and KO
stills a/b/c (`ko/<id>_a|b|c.jpg`, 1280x720 q88). `RETIRED_CARDS` is now empty; all four KO strips are `"live": true`.
Masters (1920x1080 / 2048x1024 Canva exports): `grok_art/2026-11-09-style-c/` (rejects in `rejected/`).
Refs: portraits = `portraits_hd/ghoster.png` on white (style only); cards/KO A/C = the new portrait; KO B = canonical
Duff face sheet (`MAHacL92VLk`) + eye-hand (`MAHabBgv_Hk`) or creature-forearm (`MAHabP7oeP8`) ref + the new portrait.
Renders: `docs/renders/gala_exes_art.png` (setup / intro card / fight for all 4), `docs/renders/ko_<id>_beats.png`.
Graded at full size.

| file | grade | notes |
|---|---|---|
| donald portrait / card / a / c | PASS | Chip: silver hair, veneers, fleece vest, gold pen, red-tape paper walls. Card try 1 rejected (head inside the engine's 13% card lift, cropped in game); try 2 zoomed out. |
| donald_b | PASS | Front-on symmetrical fist-to-fist. Duff faces viewer's left (his LEFT side): blackout sleeve, eye-in-triangles fist, fox on the visible neck. K1: cyan hand x-ray (carpals, metacarpals, phalanges) at the knuckle contact. |
| fences portrait / card / a / c | PASS | Lance: yacht hat, sunburn, salmon polo, navy blazer, keys. Card try 1 rejected (keys/hat in the lift zone); try 2 zoomed out. Portrait: slight green tint on the blazer buttons (despill). |
| fences_b | PASS after 1 fix | Try 1: Duff's far arm bare skin (D3) -> Canva edit added grey-wash/orange ink. K1: full spine x-ray under the palm between the shoulder blades. Soft miss: the far-forearm creature head reads as orange/grey ink, not a clear head. Layout is eye-level, not the brief's high angle. |
| bozos portrait / a / c | PASS | Grant: slicked hair, pencil moustache, tiny glasses, green velvet tux, gold watch, coin-slot drones. Tablet screens show blank pill buttons only. C is on a banquet table (brief) while the closer line says "on the carpet" (text nit). |
| bozos card | PASS (local fix) | Hair was inside the lift zone; `letter_card.py --drop 75` moves the art down and extends the sunburst rays into the top band (seam invisible). Shoe soles slightly cropped. |
| bozos_b | PASS | Floor-level knee to the chin from the viewer's left. Duff faces viewer's right (his RIGHT side): grey-wash + dark creature forearm, blackletter hand, no fox on the visible neck, blackout far arm. K1: skull/jaw x-ray, hinge (TMJ) glowing; only the near hinge is visible in a side view. |
| husk portrait | PASS (minor) | Tyler: curtain bangs, stubble, cream hoodie, mustard blazer, gimbal phone, ring light. Faint olive halo around the pink ring-light glow (green-screen bleed). |
| husk card | PASS (local fix) | `--drop 95`; shoe soles slightly cropped. |
| husk_a / husk_c | PASS | E-scooter joust with phone in teeth; flat on the carpet among shrimp, phone on gimbal, ring light tipped. |
| husk_b | PASS | Over-the-shoulder from behind Duff's LEFT shoulder: blackout sleeve elbow (eye mandala on the elbow), fox on the near neck side. K1: mandible x-ray cracked at the elbow contact. Arm anatomy is chunky but reads. |

K3: no leaked faces (no Ghoster/Coupon face anywhere; style refs carried no characters into cards/KO). K6: four
different B layouts (symmetric fist-to-fist, behind-the-back palm, floor-level knee, over-the-shoulder elbow). P1: all
four faces are made up; none resembles a public figure.

**Open / not done:** sprite sheets `ch_<id>.png` (optional) still show the old placeholder pixel faces, so the small
in-world sprite (and the sprite-based face some HUD shots show) is still the old look.

**Gotchas learned:**
- The engine lifts intro cards by 13% (`CARD_LIFT`); prompt "top of the head about one fifth down from the top" or use
  `letter_card.py --drop N --center x,y`.
- Canva draws thin white dividers between portrait panels even when told not to; `import_portrait.py` needs them
  painted to the key colour first (it found clean panels after that). Use `--min-island 400` for floating props.
- After `git checkout -- .godot` the import cache is stale but Godot's filesystem cache thinks it is current: `touch`
  the changed assets before `--import`, or renders show the old art.
