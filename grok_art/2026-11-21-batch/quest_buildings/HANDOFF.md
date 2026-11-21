# New quest buildings (Place, Nov 11 2026): approved by Duff Nov 21 2026

Three **new** overworld exteriors for quests that already exist but have no building on the map.
None of these ids are in `art_manifest` or `main.buildings` yet. Claude has to add all three.
Nothing in `art/overworld_storefronts/` was touched.

| file | image size | world footprint (px/2) | opaque bbox (x0,y0,x1,y1) | door x (px) | sign text (exact) |
|---|---|---|---|---|---|
| sf_waffle.png  | 280x140 | 140x70 | 3,2,277,140  | 140 (center) | WAFFLE HAUS |
| sf_akarui.png  | 220x120 | 110x60 | 3,1,219,120  | 110 (center) | AKARUI (plus a small red sun dot, not text) |
| sf_holland.png | 240x160 | 120x80 | 13,2,233,160 | 120 (center) | HOLLAND CENTER |

- Format: RGBA PNG, hard 0/255 alpha, transparent around the building. No green or magenta fringe (checked).
- Same convention as the Nov 8 importer and the storefront v2 pass: s=2, origin 0,0, building **bottom-aligned
  to the last row**, and the door is at the **horizontal center of the image at the bottom edge**. Hook the door /
  story trigger just below `rect.end` at `rect.position.x + rect.size.x/2`.
- Holland's silhouette is 220 px wide inside a 240 canvas, and it sits 3 px right of center so that the door
  (not the bbox) is centered. Use the opaque-pixel wall code as usual; it will pick up the real outline.
- Other text: none. The posters on the Holland are picture-only (a string instrument and music notes). The
  Waffle Haus newsbox and chalkboard, and the Akarui menu board, are unreadable scribbles at 1x.

## Hooking them up (for Claude)
- **sf_waffle**: today the map only has the `waffle_sign` interact at `WAFFLE_SIGN_PT = (606,150)` (main.gd ~67,
  ~914, ~4399). Either replace the sign with this building (door at `WAFFLE_SIGN_PT`) or put the building just
  beside it and keep the sign as the roadside pole. Its 140x70 world footprint needs a clear lot near the
  interstate.
- **sf_akarui** and **sf_holland**: the sushi (`AkaruiScript`) and symphony dates currently start from the date
  menu (main.gd ~3695), not from a map door. These sprites are ready for a downtown door if you want one; the
  date menu can stay as well. Official names come from data/cast.json: "Akarui" (downtown Omaha) and
  "Holland Performing Arts Center" / "the Holland Center".

## How they were made
- **2 image generations total.**
  1. One sheet of all three on #00FF00, with sf_fork at 3x and home_interior.png as style refs. Waffle Haus and
     Holland come from this one.
  2. Akarui only: the gen-1 sushi spot read as a bakery and was too narrow, so I stretched it to the target
     aspect and re-rendered it as sushi/poke/boba with an indigo awning.
- Keyed, despilled, LANCZOS-downscaled to exact size (light unsharp), quantized to 255 colours with no
  dithering, hard alpha, green-fringe pass on the outline.
- **Waffle Haus was rebuilt by hand at source res** to reach 2:1 with a centered door. A right-side window bay was
  duplicated, the roof was rebuilt with the sign centered over the door, a stray sign shadow was removed, and
  the slight width/height scale difference is about 8%.
- **Hand pixel work at 1x:** all three signs were drawn from a custom bitmap font. WAFFLE HAUS is bold
  black on yellow. HOLLAND CENTER is maroon on a cream marquee. AKARUI is charcoal on a wood board. Also painted
  by hand: the red waffle-grid neon over the Waffle door, the neon-blue coffee cup recolour, brighter diner
  windows, six nigiri (salmon/tuna/tamago on rice), four boba cups (taro/mango/strawberry/matcha), and both
  Holland posters (they replaced "Omaha" text from the gen).
- Scripts are in `_work/` (waffle.py, w_final.py, h_final.py, s_final.py, font.py, preview.py).
  Re-running them reproduces the PNGs.

## Honest weak points
- **Akarui is warm and orange overall.** It reads as golden-hour more than bright midday, and the wood and lamps
  dominate. The blue awning, sushi and boba are what sell it as sushi. It could use a cooler, brighter tone pass.
- **Waffle Haus windows are still dark and busy**, the same as the Fork. The griddle and waffles are there but
  small. The checker strip has a faint seam about 3/4 of the way across, where the bay was duplicated.
- The Waffle roof is a hip roof, so its two short ends slope slightly. Walls, sign and eaves are all
  axis-aligned.
- Holland's left poster instrument reads more like a guitar than a violin at 1x. Its silhouette is a bit narrower
  (220) than the 240 canvas.
- The signs are 9 px tall. They are readable at 1x but smaller than the Fork's sign lettering.
- At 2 px per world unit these are about as detailed as the existing set, not more.
