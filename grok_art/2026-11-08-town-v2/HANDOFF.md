# Town v2 handoff, Nov 8 2026

Hi Claude. Duff approved this batch. Nothing here is wired into the game, and nothing has been tested in Godot yet. `town_v2_preview.png` is the contact sheet (grass, asphalt, and an occlusion illustration). It is not a Godot screenshot. `town_v2_import_manifest.json` is a proposal, not a manifest patch. Full notes are in `town_v2_README.txt`.

Straight-on 3/4 camera. Opaque RGB on a flat key. Key to transparency, and do not filter the key. Pink (flamingo, cat ears and noses, flowering canopy) is `#00FF00`. Everything else is `#FF00FF`.

## 1. Fixes from the town notes

- `waffle_sign.png` is 48×64, key `#FF00FF`, origin 24,60. New-style **WAFFLE HAUS** sign, exact spelling, two lines of native 5×7 letters. No I-80, no arrow, no extra text.
- `bus_sign.png` is 32×40, key `#FF00FF`, origin 16,38. New-style **BUS** stop sign, exact spelling, 3×5 letters plus a bus pictogram.
- The three cats are redrawn in the new style, same grid and frame layout as the legacy cat sheets. Each is 192×64, 4×2 cells of 48×32, origin 24,28, key `#00FF00` (pink ears and noses). Columns: walk A, walk B, hungry/alert idle, fed/settled idle. Only columns 0 and 1 are the walk loop. Coats: Alastor ginger tabby, Freya silver-grey, Lucifer dark slate-black. `cat_alastor.png`, `cat_freya.png`, `cat_lucifer.png`.
- Seven lawn props for the empty right-side lawns. Do not paste extra grass over the sidewalks. Keep doors, paths, and collision clearance.
  - `lawn_mailbox.png` 32×40, `#FF00FF`, origin 16,38
  - `lawn_flamingo.png` 32×40, `#00FF00`, origin 16,38
  - `lawn_sprinkler.png` 32×32, `#FF00FF`, origin 16,30
  - `lawn_bush.png` 32×32, `#FF00FF`, origin 16,30
  - `lawn_gnome.png` 32×32, `#FF00FF`, origin 16,30
  - `lawn_kiddie_pool.png` 64×40, `#FF00FF`, origin 32,38
  - `lawn_trash_can.png` 32×40, `#FF00FF`, origin 16,38

## 2. Cat row direction

The legacy cat sheets have the top row facing **left** and the bottom row facing **right**. These new cats keep that order. That conflicts with `cat.gd`, which picks row 0 when `velocity.x >= 0`, and with Sheet column F, which assumes row 0 faces right. Either swap the rows on import, or fix the lookup. No second art variant is included. The bottom row is a per-cell mirror of the top row, not a reversed atlas.

## 3. Occlusion

`town_tree_trunks.png` and `town_tree_canopies.png` are optional. Together they reconstruct the current 384×384, 3×3 tree sheet exactly (128px cells, origin 64,120). Cell order matches the dressing sheet: maple, oak, scraggly ash / pine, lilac, hedge / unused. Trunks are `#FF00FF`. Canopies are `#00FF00` because of the flowers. Hedge has no trunk. Key both, then composite. Y-sort the trunks with the actors and draw the canopies above them, with a fade. Fade only the canopy. Proper per-actor y-sorting is still a code fix. M4's see-through pass still keys off Duff's feet, so another actor in front of a tree can draw under it. Do not double-apply that fade.

## 4. Sign integration

From `town_v2_README.txt`. Not applied, and not tested in Godot.

- `waffle_sign` is a new asset. `main.gd` `_draw_waffle_sign_and_board` still draws the sign procedurally. Replace only the pole and sign. Keep the bounty board and its story interactions. The PNG is only the words WAFFLE HAUS.
- `bus_sign` replaces the legacy 32×40 asset, but the visible old bus sign is still baked into `map_objects.png`. Swapping `bus_sign.png` alone will not remove that baked cutout. Clear or cover the old one, then place the new sprite once.
- Register the `lawn_*` props in `town_dressing.json` or the dressing importer, on the empty right-side lawns.
- After import, refresh Godot's texture cache. View the tiny BUS letters at native size or a nearest-integer scale.
