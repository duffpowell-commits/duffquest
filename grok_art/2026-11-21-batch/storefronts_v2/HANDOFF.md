# Overworld storefronts v2 (Place, Nov 11 2026): approved by Duff Nov 21 2026

Drop-in replacements for `assets/art/sf_*.png`. Each one has the exact manifest size (s=2, origin 0,0),
uses RGBA with hard 0/255 alpha like the current files, and needs no keying. The building sits at the bottom
edge, like the Nov 8 importer output, because doors and story triggers sit just below `rect.end`.

| id | size | sign (copied pixel-for-pixel from the current, already-checked sprite) |
|---|---|---|
| sf_home | 220x140 | none (floating HOME label stays) |
| sf_fork | 300x140 | THE TWISTED FORK |
| sf_hywhee | 220x96 | HY-WHEE MARKET |
| sf_walgrumps | 152x76 | WALGRUMPS (the current sprite has no PHARMACY text) |
| sf_kwik | 260x140 | KWIK-N-GO (matches the current sprite and main.gd) |
| sf_club | 160x104 | CLUB CLOUD 9 |
| sf_mining | 116x84 | MINING RIG |
| sf_neighbor | 160x120 | none |
| sf_hoa | 240x140 | HOA HQ |
| sf_seen | 120x80 | SEEN CAFE |
| sf_iron | 110x100 | IRON TEMPLE |
| sf_plaza | 104x160 | NAKATOMEH PLAZA (the existing parody spelling, kept as-is) |
| sf_plazmart | 144x80 | PLAZMART PLASMA + blood-drop icon |

## How it was made
The current main sprites (unchanged since 2eee984, Nov 8) were laid out at 3x on #00FF00 and re-rendered
with home_interior.png as the style reference. That took **3 image generations** (sheet A: home and Fork;
sheet B: Kwik, Hy-Whee, Club, Walgrumps, Mining; sheet C: the other 6). Each building was then keyed and
despilled, scaled with its aspect ratio kept so its width matches the old opaque bbox, centred on the old
centre, bottom-aligned, and quantized to 64 colours. A light saturation and contrast lift was added for
midday sun. All signs were pasted back from the old sprites, so the spelling is exactly what shipped. A few
hand-placed flower clusters were added to the home's beds.

## Doors / collision
- Each door stays where it was: every door constant is at the footprint's horizontal centre (HOME_DOOR 95 to
  px 110, FORK_DOOR 535 to px 150, GROC 231 to px 110, PHARM 383 to px 76, PLASMA 428 to px 72, story doors at
  rect centre). The new art keeps the old horizontal centre and the old bottom row.
- Some silhouettes are taller or shorter than before because the aspect ratio was kept: hywhee top row 5
  (was 24), club 10 (was 16), walgrumps 8 (was 16), mining 12 (was 16), home 22 (was 16), fork 15 (was 19),
  kwik 19 (was 16). The opaque-pixel wall code (main.gd ~2194) will pick up these new tops. That only affects
  the area behind each building, but re-run the soak / walk test.
- Hywhee has two doors (left and right) with produce in the centre, the same as the old sprite. The door trigger
  is still at the centre.

## Honest weak points
- **This is a refresh, not a transformation.** At 2 px per world unit, a 220x140 building can't hold much more
  detail than the Nov 8 set, and side by side (overworld_storefronts_before_after.png) the change is modest.
  The best gains are the Fork (booth interiors, chalkboard), Hy-Whee (fuller produce, cart, arched facade),
  Walgrumps (striped awning, shelves) and the Plaza and Iron Temple textures. Home, Kwik, Neighbor, HOA and Seen
  are about the same as before.
- Downscaling from a JPG generation gives a slightly softer, noisier texture than the hand-made home_interior.
  Signs are crisp because they are the old pixels.
- The home's porch-front clutter is still a bit muddy brown, even with the added flowers.
- The baked shading was not re-lit per building. The light comes from the top-left everywhere, which matches.


---

# v3 pass (Nov 11 2026, 11:17 PM CST onward): five weakest buildings redrawn by hand

Duff kept v2 for **sf_fork, sf_hywhee, sf_walgrumps, sf_plaza, sf_iron, sf_club, sf_mining, sf_plazmart** (unchanged).
These five were **redrawn from scratch at 1x in code** (pixel-by-pixel, no downscaling, limited palettes, 1px dark outline,
sun from top-left): **sf_home, sf_kwik, sf_neighbor, sf_hoa, sf_seen**. Generator scripts: `_work/v3/*.py`;
v2 versions backed up in `_work/v2_backup/`.

**Image generations this pass: 0** (total for the storefront job: 3).

What changed:
- **sf_home**: readable craftsman porch: 4 cream columns on brick pedestals, white baluster railings, 6 distinct steps
  with brick cheek walls, teal door with lit transom lights + 2 porch lamps, cream lap siding, two windows with warm
  lamp/plant interiors, curtains and craftsman muntins, porch bench and rocker + fern, brick skirt with vents, two
  flower beds (rounded shrubs with red/pink/purple/yellow/white flowers) and stone edging, concrete walk at the steps.
- **sf_kwik**: door moved to the exact centre (x 130 = SHOP_PT); snack-shelf window, neon window (abstract squiggle, no
  text), blue ice machine, two purple pumps on yellow islands with bollards, canopy fascia with stripes + lights,
  roof AC, hatch, vent; sunlit forecourt with joints and oil stains.
- **sf_neighbor**: blue hip roof with chimney + roof vent, grey-blue siding, shuttered windows, red front door + step,
  recessed side porch with the couch, shrubs, lawn strip with red party cups.
- **sf_hoa**: sandstone ashlar office, raised centre parapet carrying the sign, cornice, 4 pilasters, 4 windows with
  half-raised blinds, file cabinets and flower boxes, teal double door with transom and lanterns, hedge, mow-striped
  lawn, path, the HOA tape measure, red lawn-violation flags (no text), curb.
- **sf_seen**: shingle roof + chimney, orange/cream striped awning, warm-lit windows with tables and customers,
  teal door, bistro table, A-frame chalkboard (scribble only), potted plants.

Signs: pixels copied from the current main sprites — KWIK-N-GO (75,40)-(184,65), HOA HQ (90,36)-(149,53),
SEEN CAFE board only (33,33)-(88,44). Home and neighbor have no sign. No other text.

Format / footprint (all checked):
- Exact sizes 220x140, 260x140, 160x120, 240x140, 120x80; RGBA, alpha only 0/255; lowest opaque row = image bottom.
- Horizontal centre of the opaque bbox: home 110.0 (main 109.5), kwik 130.0 (129.5), neighbor 80.0 (79.5),
  hoa 120.0 (119.0), seen 60.0 (59.5) — door points still line up. Home door, Kwik door and Seen door are now
  exactly centred.
- Taller tops (opaque-pixel walls will grow upward, behind the building only): home top row 9 (main 16) from the
  chimney cap; neighbor 27 (main 39) chimney; seen 11 (main 16) chimney; kwik 17, hoa 15 ≈ unchanged.
  Widths within 1 px of main. Re-run Claude's walk test.

Honest weak points (v3):
- **Style gap**: the five redraws are cleaner, brighter and flatter (crisp flat tones like home_interior.png) than the
  kept v2 painterly sprites (Fork, Hy-Whee, Plaza, Iron...), which are darker and grainier. Side by side on the street
  the set is no longer perfectly uniform. A cheap fix if Duff wants it: a light warm-down pass on the five, or
  redraw the others the same way later.
- Hand-drawn shapes are simpler than painted art: shrubs are round blobs, interior figures in Seen are 2-pixel
  silhouettes, the Kwik roof is a big plain gravel slab.
- Kwik layout changed (door now centred between the pumps instead of right of them) — intended, but it is a
  different composition from what Duff has seen in-game.

---

# v4 pass (Nov 11 2026, from 11:26 PM CST): the other eight redrawn by hand, all 13 now one style

Duff approved the v3 look and asked for the rest to match. **sf_home, sf_kwik, sf_neighbor, sf_hoa and sf_seen were not
touched.** These eight were redrawn from scratch at 1x in code with the same approach as v3:
**sf_fork, sf_hywhee, sf_walgrumps, sf_club, sf_mining, sf_plaza, sf_iron, sf_plazmart**.
- Scripts: `_work/v3/<name>.py`, plus the shared helpers in `_work/v3/kit.py` and `px.py`.
- The v2 PNGs are backed up in `_work/v2_backup/`.
- `/workspace/duffquest/art/quest_buildings/` was not touched.

**Image generations in v4: 0.** The whole storefront job used 3, all in v2.

## What changed
- **sf_fork**: a diner with a rounded-corner tan roof, a chrome and cream lip, and a red stripe.
  - Two long windows show 7 booths each: red seat backs, tables with mugs, diners and pendant lamps.
  - Centred red portal with the fork-and-spoon emblem (icon only, no text) and a golden door with a menu-paper pane (lines only).
  - Red brick lower band, sidewalk, four potted shrubs, trash can, and an A-frame chalkboard (coloured scribbles only).
- **sf_hywhee**: brick market with an arched centre parapet and medallion, side wings with flat roofs, and a green striped awning.
  - **Two teal doors (left and right), with produce in the centre**: 4 crates in front of a stocked window, plus a front table of fruit.
  - Stocked wing windows, lanterns, shopping cart, bench and flower pots.
- **sf_walgrumps**:
  - Flat roof with an AC unit and a brick front.
  - Blue and white striped awning over a glass storefront with coloured shelf rows, and a glass door at the exact centre.
  - Side windows, a small green-cross icon (no text) and planters.
- **sf_club**:
  - Purple brick with a stepped cream-capped parapet and a pink neon cloud outline.
  - Teal double doors with pink porthole lights, a cyan neon window, an abstract poster (no text), and gold rope posts with a red velvet rope, plus steps.
- **sf_mining**: wood-plank garage with two rooftop fan units.
  - Half-raised roll door over 5 server racks with green, blue and amber LEDs and cables.
  - Electrical boxes with status lights, a red fuel can, a crate and a concrete apron.
- **sf_plaza**: the bronze and glass tower with rooftop machinery, crown band, a setback ledge and a gold reflection column.
  - Lit windows, a lobby with an entrance canopy and glass doors, planters and plinth steps.
- **sf_iron**: corrugated quonset hut with a ribbed arch rim, a louvred vent and rust streaks.
  - Raised roll door shows a squat rack with a red-plate barbell, a mirror, a dumbbell rack, kettlebells and a blue bench on rubber flooring.
  - Red side door with a lamp, and a tire out front.
- **sf_plazmart**: standing-seam blue roof with an AC unit, white panel front, and blue and red stripes.
  - Glass door on the left (same as before), bench, water cooler, a window with blinds, a blue brick base and plants.

## Signs
All are copied pixel for pixel from the current GitHub main sprites. Each board rectangle was measured at 8 to 9x zoom:
- THE TWISTED FORK (59,30)-(241,61)
- HY-WHEE MARKET (69,42)-(151,58)
- WALGRUMPS (45,32)-(102,43); there's no PHARMACY text anywhere
- CLUB CLOUD 9 (45,49)-(114,65)
- MINING RIG (31,33)-(84,44)
- NAKATOMEH PLAZA (30,40)-(73,55); the joke spelling is unchanged
- IRON TEMPLE (23,52)-(86,63)
- PLAZMART PLASMA (42,29)-(102,48), with the existing blood-drop icon, which is part of that sign

There is no other text.

## Format, footprint and doors (all checked)
- Sizes are exact, the PNGs are RGBA with alpha only 0 or 255, and the lowest opaque row is the bottom row of the image.
- Horizontal centre of the opaque bounding box, v4 vs GitHub main:

  | id | v4 centre | main centre |
  |---|---|---|
  | fork | 149.5 | 149.5 |
  | hywhee | 109.5 | 109.5 |
  | walgrumps | 75.0 | 75.0 |
  | club | 79.0 | 79.0 |
  | mining | 57.0 | 57.0 |
  | plaza | 51.5 | 51.5 |
  | iron | 54.0 | 54.0 |
  | plazmart | 71.0 | 71.0 |

  All match exactly, so FORK_DOOR, GROC_DOOR, PHARM_DOOR, PLASMA_DOOR and the story doors still line up.
- The bounding boxes are within 1 to 2 px of main on every side. The tops are 1 px higher (2 px for mining, from the fans). Widths are ±1 px from the outline. That's negligible for the visible-pixel walls, but Claude should still rerun the walk test.

## Honest weak points (v4)
- **The town now reads as one set**: same outline, flat tones, sun from the top-left and crisp 1x pixels across all 13.
- Some places changed character more than others:
  - **Plaza** is now a straight glass tower instead of the darker, ornate art-deco silhouette.
  - **Club** went from a shingled gable roof to a flat roof with a stepped parapet.
  - **Fork** is paler (cream and tan) than the old warm-brown diner.
  - The colours and sign positions are the same, so each place is still recognisable, but Duff may notice.
- Hand drawing gives simpler forms than painted art. The plants are round blobs, the diners and crowds are 2 to 3 px figures, and the Fork's brick band and roof are large flat areas.
- Plaza's lit windows are a stylised "busy office" touch at midday rather than strictly realistic.
