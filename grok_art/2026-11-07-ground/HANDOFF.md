# Ground tiles v2 handoff, Nov 7 2026

Hi Claude. Duff approved these and wants you to start coding the town map from tiles. Do not wait on more ground art.

The drop is `grok_art/2026-11-07-ground/`. Nothing here is wired into the game. `batch1_v2_README.txt` was written before approval and still says "awaiting Duff review". Ignore that line. This file is the one to follow.

## Camera and style
- The camera is straight-on 3/4 top-down, the camera the game already uses. Board 2's diagonal is not the target.
- Match the board 2 palette (`grok_art/2026-11-07/style_board_2.png`).
- This is the map decision in CLAUDE.md: rebuild the outdoor map as a TileMap and keep the building footprints, doors, and collisions. Isometric stays rejected.

## Sheets
- `new_ground_textures.png`: 1536×1024, a 3×2 grid of 512px cells. Grass, sidewalk, and asphalt on the top row. Brick, dirt, and gravel on the bottom row. Each 512px swatch holds four 256px variants that share borders.
- `new_ground_edges.png`: 1024×1024, a 4×4 grid of 256px cells. Road markings, fixtures, and straight transitions. Markings and fixtures in the JSON: `line_H`, `line_V`, `crosswalk`, `storm_drain`, `manhole`, `oil_stain`, `puddle`, `driveway_apron`.
- `new_ground_corners.png`: 2048×1280, an 8×5 grid of 256px cells.
  - Four transition pairs: sidewalk/asphalt (with curb), grass/sidewalk, grass/asphalt, and dirt/grass.
  - Each pair has 4 straight edges, 4 outer corners, and 4 inner corners.
- `ground_tilemap.json`: the full cell map and the orientation conventions for autotiling. Rows and columns in the JSON are 1-based. Pixel rects are 0-based.
- Previews, assembled only from these sheets: `batch1_v2_town_mock.png` (640×360), `batch1_v2_preview.png`, `batch1_v2_board_comparison.png` (board 2 on the left, the mock on the right).

## How to cut them
- Cells are high-res (256 and 512). Downscale with nearest-neighbour to the game's tile size, 32px or 16px, whichever fits 640×360.
- Textures wrap seamlessly as whole swatches. Keep the motif phase. Arbitrary 32px slices are not guaranteed seamless. Preserve coordinates and phase, or use the full 256px cells as terrain tiles.
- The four 256px variants inside a material can swap at that size. They are not four copies of one interior.

## What this set is not
- This is not a 47-tile blob set.
- There are no three-material junctions.
- If the map needs either, ask Grok via Duff. Do not invent the missing tiles.

## Orientation (JSON `autotile`)
- Straight N/E/S/W names the half occupied by material A. N is the top half, E the right, S the bottom, W the left.
- Outer is a convex corner of A. `outer_NW` is a quarter-disc of A anchored SE, with B outside the NW. NE/SE/SW rotate that.
- Inner is a concave notch in A. `inner_NW` is all A except a quarter-disc of B anchored NW. NE/SE/SW rotate that.
- Only sidewalk/asphalt has a curb.

## Sheet row 225
- Row 225's old parking wording is superseded by the JSON.
- V2 materials are grass, sidewalk, asphalt, brick, dirt, and gravel. Dirt and gravel are separate. Gravel replaces the old parking slot.

## After this
- Storefronts are coming next. KWIK-N-GO and the home bungalow are first, recreated from board 2.
- Integrate Duff's player sprite first (`grok_art/2026-11-07/duff_sheet_sos_256.png`). This ground drop is the task after that. See `grok_art/NEXT_STEPS_FROM_GROK.md`.
