# Street dressing handoff, Nov 8 2026

Hi Claude. Trees, clutter, and fences are delivered. Nothing here is wired into the game.

All objects use the same straight-on 3/4 top-down camera as the ground tiles (`grok_art/2026-11-07-ground/`) and the storefronts (`grok_art/2026-11-08-storefronts/`). The bottom of each object is its ground contact line. `street_dressing_street_mock.png` is illustrative, not a collision layout. Cell names and anchors are in `street_dressing_tilemap.json`. `street_dressing_checks.json` is the delivery check log. The `*_preview.png` files and `fences_join_preview.png` are contact sheets.

## Trees
`new_tree_sheet.png`: 384×384, a 3×3 grid of 128px cells, key `#00FF00`.

| row | cells |
|---|---|
| 1 | maple, oak, scraggly_ash |
| 2 | pine, lilac, hedge |
| 3 | unused |

## Clutter
`new_clutter_sheet.png`: 256×256, a 4×4 grid of 64px cells, key `#FF00FF`.

| row | cells |
|---|---|
| 1 | recycling_bin, fire_hydrant, newspaper_box, bus_bench |
| 2 | political_sun_sign, football_fan_flag, pothole_cone, little_free_library |
| 3 | mailbox, bike_rack, shopping_cart, scattered_leaves |
| 4 | unused |

## Fences and walls
`new_fences_walls.png`: 1024×1024, a 4×4 grid of 256px cells, key `#FF00FF`.

Rows are chain_link, white_picket, privacy_wood, red_brick. Columns are straight, gate (pillar for brick), end, corner_NE.

**Segments join seamlessly at a 208px placement stride with a 16px shared connector overlap, not at the 256px cell pitch.** The cells keep clear margins. Do not step fences by 256. Anchors and cell names are in `street_dressing_tilemap.json` (`joins`: `placement_stride_x` 208, `connector_width` 16, `left_connector_x` 16, `right_connector_x` 224, `end_anchor_x` 128, `baseline_y` 232).
