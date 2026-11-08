# Grok art handoff, Nov 7 2026

Hi Claude, these are from Duff's Grok art assistant. Duff approved everything in this batch, with the caveats listed below.

> Only Duff, Madison, Brittany and Octavia are based on real people's photos. Every other character, including Jen, Brenda, Theo, the pirates, NPCs and bosses, should be designed from scratch with no photos needed. Grok will design their looks; Claude only needs to flag gameplay or role constraints.

## Important: Duff is the only playable character right now
- Duff is the only playable character. Madison, Brittany and Jen are NPCs or party guests.
- Their walk sheets are for overworld and cutscene use. Don't wire them into player control.
- Their attack column is for scripted moments only.

## What's in this drop (grok_art/2026-11-07/)
### World style (the new direction: modern high-detail pixel art, bright sunny Omaha)
- `style_board_1.png`, `style_board_2.png` and `style_board_3.png`: Style bible prompt B, run 3 times.
- **Duff picked `style_board_2.png`.** It's the style reference for every world asset from now on.
- It's concept art, not a production tileset.

### Overworld sprite sheets (style bible prompt C)
- `duff_sheet_sos_256.png` and the 1024px `duff_sheet_sos.png` (the same art enlarged 4x with nearest-neighbour).
- `madison_sheet_sos(_256).png`, `brittany_sheet_sos(_256).png` and `jen_sheet_sos(_256).png`.
- Format:
  - 256x256, 4x4 grid of 64px cells.
  - Rows top to bottom: down, up, right, left.
  - Columns left to right: stand, stepA, stepB, attack.
  - Every character is 52px tall on a shared baseline.
- Key colours:
  - Duff, Madison and Brittany are on exact #00FF00 green, because they have pink accents.
  - Jen is on exact #FF00FF magenta.
- Attacks: Duff lunges or swings a frying pan, Madison shoves, Brittany slaps, Jen jabs.
- The left-facing rows are mirrored from the right-facing rows.
- Not yet tested in Godot.
- The hand-drawn limbs are plainer than the generated heads and torsos.
- Jen's sheet in this drop was traced from her old sprite. That is not a likeness lock. Design her from scratch; no photo.
- Duff's look:
  - Dirty-blond undercut, tied back in a ponytail. NO bandana.
  - Ginger-blond stubble.
  - Black and gold spiky ear hoops.
  - Fox neck tattoo.
  - Black tee.
  - Use this sheet to update his walking sprite (the CLAUDE.md TODO).

### Dialogue portraits (Hazbin-style cartoon, style bible prompt D)
- `duff_portraits_hazbin.png`, `madison_portraits_hazbin.png`, `brittany_portraits_hazbin.png` and `octavia_portraits_hazbin.png`.
- Each is 1280x720 on exact #00FF00 green, with 3 expressions: happy, deadpan, furious.
- The same files were also merged earlier to `duffquesthd/portraits/` (PR #3).
- They supersede the earlier duff_portraits v2.
- The open tech issue still applies: portraits need a native-resolution dialogue layer, because 640x360 downsamples them.
- Known nits:
  - Madison's middle-panel eyes are teal. They should be brown.
  - Octavia's set uses adult moods. The style bible suggests giggling, curious and wailing, so she may get redone.

### Reference and QA
- `sos_cast_inspection.png`: all 4 sheets side by side.
- `sos_walk_inspection.gif`: a walk preview.
- `madison_vs_brittany.png`: the two faces were deliberately pushed apart.
  - Madison has a rounder face, side bangs, brown eyes and a labret piercing.
  - Brittany has a longer oval face, a side part, teal eyes and stronger eyeliner.
- `full_sprite_list.csv`:
  - All 223 assets: the 131 in the manifest plus 92 new ones the new direction needs.
  - Each has a priority and a ready-to-paste Grok prompt.
  - Live copy: https://docs.google.com/spreadsheets/d/1nQ9h_KqccoSbITQw3A6a8Oh5zX7YyHh33gvkr1L62Aw/edit

## What's next (suggested)
1. Integrate `duff_sheet_sos_256.png` as Duff's player sprite in duffquesthd. Key the green, keep the 32,60 origin, and check the walk cycle in Godot. Report any cell that pops or jitters so Grok can redo it.
2. **Current task, after that sprite:** code the town map from `grok_art/2026-11-07-ground/`. Duff approved the v2 ground tiles. Read `HANDOFF.md` in that folder. Straight-on 3/4 camera, board 2 palette. Downscale with nearest-neighbour to 32px or 16px. Whole swatches wrap; arbitrary 32px slices do not. This is not a 47-tile blob set, and there are no three-material junctions.
3. Build the native-resolution dialogue portrait layer, then hook up the 4 Hazbin portraits.
4. Tell Grok (via Duff) what you need next, in priority order.
   - Storefronts are delivered: all 13 in `grok_art/2026-11-08-storefronts/`. Read `HANDOFF.md` there. The street mock is illustrative only, not a collision layout.
   - Trees, clutter, and fences are delivered: `grok_art/2026-11-08-street-dressing/`. Read `HANDOFF.md` there. Fence segments join at a 208px stride with a 16px overlap, not at the 256px cell pitch. The street mock is illustrative, not a collision layout.
   - Next art from Grok: Duff's outfit sheets (matching the `duff_sheet_sos_256` format), then the 17 bosses.
   - Then the P2 NPCs and backdrops, then P3 icons and props.
5. Flag any format changes you want (cell size, key colour, frame count) before Grok makes more sheets.
6. Open questions for Duff (also noted in the sheet). Looks are not questions. See the note at the top.
   - Jen's role is clear: Duff's sister. She sends the Wordle texts and babysits Octavia. Do not ask what she looks like.
   - Brenda's role is clear: a human on the Blue Crossword insurance phone tree in the pharmacy minigame (`pharmacy.gd`). She is not Pharmacist Deb, and she has no sprite id. Do not ask what she looks like.
   - Theo is a fictional quest-giver NPC. He gives quests. Design him from scratch; no photo. He is not the Akarui sushi chef.
   - Porch pirates are not a question. Six names share four sheets on purpose: `enemy.gd` picks `ch_pirate0`–`ch_pirate3` with `absi(hash(pname)) % 4`.
   - `duff_dress` is not a question. `symphony.gd` `dress_cell()` maps the 6×3 sheet. Column is the outfit top times 2, plus 1 unless the extra is the tie. Row is the shoes: dress shoes, work clogs, Crocs.
   - The old `tiles` atlas question is closed. Use `grok_art/2026-11-07-ground/` instead of the unused 192×96 manifest atlas.
