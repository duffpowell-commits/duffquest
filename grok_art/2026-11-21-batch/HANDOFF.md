# Art batch handoff, Nov 21 2026

Hi Claude. Duff approved this batch. Nothing here is wired into the game, and nothing has been tested in Godot. Four folders:

## 1. `storefronts_v2/`
13 drop-in replacements for `assets/art/sf_*.png`. Exact manifest sizes, RGBA with hard 0/255 alpha, bottom-aligned, no keying. Doors stay at the old horizontal centre, on the bottom edge. The size and sign table is in `storefronts_v2/HANDOFF.md`. Also there: `overworld_storefronts_preview.png` and `overworld_storefronts_before_after.png`. Re-run the walk test. Some building tops moved by a pixel or two, and the opaque-pixel walls will follow them.

## 2. `quest_buildings/`
Three new exteriors for quests that have no building on the map yet: `sf_waffle.png` (WAFFLE HAUS), `sf_akarui.png` (AKARUI), `sf_holland.png` (HOLLAND CENTER). They need `art_manifest` and `main.buildings` entries. Same convention as the storefronts: RGBA, hard alpha, bottom-aligned, door at the bottom centre. Details, footprints, and where to hook each door are in `quest_buildings/HANDOFF.md`. Preview: `quest_buildings_preview.png`.

## 3. `enemy_redraws/`
`tracksuit_sword.png` and `vape_girl.png`. Each is 1024×1024, a 4×4 sheet of 256px cells, flat `#FF00FF`, RGB. Key it. Rows are front, back, left, right. Columns 1–3 are the walk, column 4 is the attack. These are painted-HD redraws to match the gym bro style.

## 4. `title_screen/title_porch_golden_hour.png`
Duff's chosen new title screen. 1280×720, the porch at golden hour, colours matched to `sf_home`. The logo and the menu words (Continue, New Game, Settings, How to Play) are painted into the image. Use it as the `bg_title` art behind `show_title()`. Either line the real menu up with the painted sign, or say so and a no-text version can be made.

## 5. Not tested
None of this has been run in Godot.
