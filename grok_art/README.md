# grok_art

Duff's Grok designs for DuffQuest, waiting to go in the game. Nothing here ships (`.gdignore`).
Duff designs with Grok, Claude converts and integrates.

**Style + prompts:** Drive doc "DuffQuest — Style bible + Grok prompts"
https://docs.google.com/document/d/1lmADUpw6NO0A_rvmwdox_t2oJoh8yZVLc1AXliRUwnE/edit
(world/sprites = Sea of Stars-style pixel art; portraits = bold Hazbin-style cartoon, humans).
**Capability test:** https://docs.google.com/document/d/1ay5y-iWh__M8sJx4JbcHVWp0WvOMgoi8g2gFnHzAtC4/edit
(results go in Drive: DuffQuest Art Inbox / 99 Grok capability test).

## Getting art here
Send it to Claude in chat, share a Drive link, drop it in the Drive Art Inbox, or upload it here
with the GitHub app (duffquest → grok_art → Add file → Upload). Name it what it is.

## Rules for every image
- **PNG, not JPG** if Grok offers it (JPG leaves a coloured fringe when the background is cut out).
- **Background:** flat magenta `#FF00FF` for sprites. For characters wearing pink/magenta (Duff's
  bandana), ask for flat green `#00FF00` instead, to be safe.
- **Equal cells, nothing touching the edges.** Leave a margin around each pose or expression.
- Original file, not a screenshot.

## Log
| file | what | status | notes |
|---|---|---|---|
| `duff_portraits.jpg` | Duff portraits: happy / deadpan / furious (1280×720, 3 panels) | **approved look** (Nov 7) | Great expressions + line work. Issues: JPG; panels touch the frame edges and the cells aren't equal (gaps at x≈407 and ≈822); hair: Duff chose **blond** (Nov 7), redo from his photo; magenta bandana keys fine with a tuned key but use green next time. Portraits need the native-res dialogue layer to keep their lines (see CLAUDE.md "Open tech issue"). |
| `duff_portraits_v2.jpg` | Duff portraits v2 from his photo: happy / deadpan / furious | **APPROVED** (Nov 7) | Looks like Duff: dirty-blond undercut + ponytail, ear spikes and gauge, fox neck tattoo, black tee (chef coat + bandana dropped). Equal-ish cells with margins (good). Still JPG on purple-magenta, but keys clean, the fox tattoo's pink stripe survives. Processed: `tools/import_portrait.py` -> `assets/art/portraits_hd/duff.png` (3 cells of 512, transparent, bottom-aligned). Not wired into the game yet. Superseded by `2026-11-07/duff_portraits_hazbin.png`. |
| `2026-11-07/style_board_1.png` | Style bible prompt B, option 1 (1280×720) | approved option (Nov 7) | Duff reviewed boards 1–3 and picked board 2. Concept art, not a production tileset. |
| `2026-11-07/style_board_2.png` | Style bible prompt B, option 2 (1280×720) | **PICKED** (Nov 7) | World style reference for every world asset from now on. Concept art, not a production tileset. |
| `2026-11-07/style_board_3.png` | Style bible prompt B, option 3 (1280×720) | approved option (Nov 7) | Not the pick. Use board 2. |
| `2026-11-07/duff_sheet_sos_256.png` | Duff overworld 4×4 sheet (256×256) | **APPROVED** (Nov 7) | Only playable character. 4×4 cells of 64; rows down/up/right/left; cols stand, step A, step B, attack. 52px tall on a shared baseline. Exact `#00FF00` (pink accents). Attack lunges or swings a frying pan. Left row is mirrored from the right. Look: dirty-blond undercut and ponytail, no bandana, ginger-blond stubble, black-and-gold spiky ear hoops, fox neck tattoo, black tee. Use this sheet to update his walking sprite. `duff_sheet_sos.png` is the same art at 1024 (nearest-neighbour 4×). Not tested in Godot. Hand-drawn limbs are plainer than the generated heads and torsos. |
| `2026-11-07/madison_sheet_sos_256.png` | Madison overworld 4×4 sheet (256×256) | **APPROVED** (Nov 7) | NPC / party guest, not playable. Walk sheet is for overworld and cutscenes; the attack column (a shove) is for scripted moments only. Exact `#00FF00`. `madison_sheet_sos.png` is the 1024 nearest-neighbour copy. |
| `2026-11-07/brittany_sheet_sos_256.png` | Brittany overworld 4×4 sheet (256×256) | **APPROVED** (Nov 7) | NPC, not playable. Attack is a slap, scripted moments only. Exact `#00FF00`. `brittany_sheet_sos.png` is the 1024 nearest-neighbour copy. |
| `2026-11-07/jen_sheet_sos_256.png` | Jen overworld 4×4 sheet (256×256) | **APPROVED** (Nov 7) | NPC, not playable. Duff's sister: Wordle texts and Octavia's babysitter. Attack is a jab, scripted moments only. Exact `#FF00FF`. This sheet was traced from her old sprite and is not a likeness lock; design her from scratch, no photo. `jen_sheet_sos.png` is the 1024 nearest-neighbour copy. |
| `2026-11-07/duff_portraits_hazbin.png` | Duff Hazbin portraits: happy / deadpan / furious | **APPROVED** (Nov 7) | 1280×720 on exact `#00FF00`. Supersedes `duff_portraits_v2.jpg`. Same files were merged earlier to `duffquesthd/portraits/` (PR #3). Still needs the native-res dialogue layer (640×360 downsamples the lines). |
| `2026-11-07/madison_portraits_hazbin.png` | Madison Hazbin portraits: happy / deadpan / furious | **APPROVED**, one nit (Nov 7) | 1280×720 on exact `#00FF00`. Rounder face, side bangs, brown eyes, labret. Middle-panel eyes came out teal; they should be brown. |
| `2026-11-07/brittany_portraits_hazbin.png` | Brittany Hazbin portraits: happy / deadpan / furious | **APPROVED** (Nov 7) | 1280×720 on exact `#00FF00`. Longer oval face, side part, teal eyes, stronger eyeliner. Faces were pushed apart from Madison on purpose (`madison_vs_brittany.png`). |
| `2026-11-07/octavia_portraits_hazbin.png` | Octavia Hazbin portraits: happy / deadpan / furious | **APPROVED**, may redo (Nov 7) | 1280×720 on exact `#00FF00`. This set uses adult moods. The style bible suggests giggling, curious, and wailing, so she may get redone. |
| `2026-11-07/sos_cast_inspection.png` | All 4 overworld sheets side by side | reference (Nov 7) | QA still for the walk sheets. |
| `2026-11-07/sos_walk_inspection.gif` | Walk-cycle preview of the 4 sheets | reference (Nov 7) | QA still. |
| `2026-11-07/madison_vs_brittany.png` | Madison vs Brittany face comparison | reference (Nov 7) | Shows the deliberate face split. |
| `2026-11-07/full_sprite_list.csv` | Full sprite list (223 assets) | **APPROVED** reference (Nov 7) | Header plus 223 rows: the 131 manifest ids plus 92 new ones the new direction needs. Each row has a priority and a ready-to-paste Grok prompt. Live copy: https://docs.google.com/spreadsheets/d/1nQ9h_KqccoSbITQw3A6a8Oh5zX7YyHh33gvkr1L62Aw/edit |
| `2026-11-07/HANDOFF.md` | Grok's notes for this batch | note (Nov 7) | Duff approved the batch, with the caveats in that file. Current tasks live in `grok_art/NEXT_STEPS_FROM_GROK.md`. Claude integrates; nothing here is wired into the game. |
| `2026-11-07-ground/` | v2 ground tiles for the town TileMap | **APPROVED** (Nov 7) | Duff wants Claude to start coding the town map from these, after Duff's player sprite. Straight-on 3/4 camera, board 2 palette. `new_ground_textures.png` is 1536×1024, 3×2 of 512 (grass, sidewalk, asphalt / brick, dirt, gravel). `new_ground_edges.png` is 1024×1024, 4×4 of 256 (markings, fixtures, straight transitions). `new_ground_corners.png` is 2048×1280, 8×5 of 256: sidewalk/asphalt (with curb), grass/sidewalk, grass/asphalt, dirt/grass, each with 4 straights, 4 outer corners, and 4 inner corners. `ground_tilemap.json` is the cell map. Downscale nearest-neighbour; keep the swatch phase. Not a 47-tile blob set. Row 225's old parking wording is superseded by the JSON. See `HANDOFF.md`. Previews: `batch1_v2_town_mock.png`, `batch1_v2_preview.png`, `batch1_v2_board_comparison.png`. |
| `2026-11-08-storefronts/` | All 13 storefronts, one building per PNG | **delivered** (Nov 8) | Complete set, together. Straight-on 3/4, same camera as the ground tiles. Flat key (`#00FF00` or `#FF00FF`; pink buildings use green), 8px margin, bottom edge is the footprint. Sizes match sprite-list column C. Signs: KWIK-N-GO, THE TWISTED FORK, HOA HQ, SEEN CAFE, IRON TEMPLE, CLUB CLOUD 9, MINING RIG, NAKATOMEH PLAZA, WALGRUMPS, HY-WHEE MARKET, PLAZMART PLASMA. Home and the neighbor have no sign. `storefronts_street_mock.png` is illustrative only, not a collision layout. See `HANDOFF.md`. |
| `2026-11-08-street-dressing/` | Trees, street clutter, fences and walls | **delivered** (Nov 8) | Same straight-on 3/4 camera. Bottom of each object is the ground contact. `new_tree_sheet.png` 384×384, 3×3 of 128, key `#00FF00` (maple, oak, scraggly_ash / pine, lilac, hedge; row 3 unused). `new_clutter_sheet.png` 256×256, 4×4 of 64, key `#FF00FF` (row 4 unused). `new_fences_walls.png` 1024×1024, 4×4 of 256, key `#FF00FF`: rows chain_link, white_picket, privacy_wood, red_brick; columns straight, gate (pillar for brick), end, corner_NE. Fence segments join at a 208px stride with a 16px connector overlap, not at the 256px cell pitch. Anchors in `street_dressing_tilemap.json`. `street_dressing_street_mock.png` is illustrative, not a collision layout. See `HANDOFF.md`. |
