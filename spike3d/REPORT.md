# Duff Quest in 3D: spike report (Nov 16, 2026)

Question from Duff: could the game be rewritten in 3D, matching the current style and gameplay?

This folder is a one-session spike to answer that with a real build instead of a guess. It is a
separate Godot project (`spike3d/project.godot`); the shipped game never loads it (Godot skips a
sub-folder that has its own project.godot, and every export preset excludes `spike3d/*`).

## What was built

One playable slice: the real town map in 3D, HD-2D style (Octopath / Sea of Stars "diorama").

- Same map data as the 2D game: building rects copied from `main.gd`, props and fences read straight
  from `data/town_dressing.json`, the painted street (`ground_painted.png`) as the floor.
  2D (x, y) maps to 3D (x * 0.1 m, 0, y * 0.1 m).
- Same art, untouched: every storefront, tree, prop and Duff's 2x `duff_home` sheet stand up as
  painted cards. Buildings get an invisible box behind the facade so they block Duff and throw a
  real shadow.
- Same controls: WASD/arrows walk (8-way, same sheet rows), Space/J bonks with the pan. Touch would
  be unchanged (the touch pad already fires these actions).
- New things 3D gives for free: a real sun with soft shadows from every card, warm lamp pools at
  doors and street lights, fog, bloom, tilt-shift blur at the top and bottom of the frame, drifting
  leaves, fireflies at dusk/night, hit-stop + directional camera shake + spark burst on a bonk.
- Three raccoons to bonk. Dusk, night and day lighting.
- Renderer: Compatibility (WebGL2), the one the web build has to use, so what you see is what a
  phone browser would get.

Run it: `godot --path spike3d -- dusk|night|day` (add `demo` for the scripted walk, `pose` for Duff close-ups, `shots` to save
stills to `/tmp/qa3d/`, `stats` for draw calls). On the Godot Android editor: open `spike3d/` as its
own project.

Renders: `docs/renders/spike3d_2d_vs_3d.png`, `docs/renders/spike3d_dusk_night_day.png`.
Clip (10 s, dusk, walk + two bonks): project files `spike3d/duffquest_3d_spike_dusk.mp4`.

## Measured

- About 100 draw calls, about 14k triangles, about 52 MB of video memory, for the whole town on screen.
  That is light for a phone.
- About 570 lines of new code for the slice, about 3.7 MB of art (copies of existing files).

## What breaks or costs if this went into the real game

1. **The web engine.** The live web build runs a custom 2D-only engine (`tools/web_template/custom.py`,
   `disable_3d = "yes"`). 3D needs a rebuilt template with 3D on. The slim zip is 7.3 MB now; the
   stock engine with 3D is about 9 MB compressed (38 MB raw wasm, from `docs/qa/perf_report.md`).
   Expect roughly +1.5 to 2 MB download and +1 to 2 s boot on 4G. That's an estimate: this spike did not
   build a 3D web template (that runs in CI). CrazyGames' 50 MB cap is not at risk (portal zip is 35 MB).
2. **Phone performance.** Real-time shadows are the cost. Fine on a recent iPhone; risky on cheap
   Android in a browser. It would need the existing Auto Lite to switch shadows and blur off.
3. **Crisp pixels.** The 2D game draws art at integer scale. A perspective camera scales the cards
   by a non-integer amount, so the art is a touch softer (visible in the side-by-side). The painted
   street is only 2 px per unit and looks soft up close.
4. **Cards are flat.** Houses are facades. With a fixed camera angle that reads fine (that's how HD-2D
   games work), but the camera can never rotate, and walking up to a wall looks like walking up to
   a poster. Real 3D buildings would fix that and would mean modelling every building.
5. **Everything that is not the overworld stays 2D.** 62 minigames, the phone, menus, dialogue, HUD,
   the Fork line, the gala: all hand-drawn 2D screens. They would sit on top of the 3D world unchanged.
   That's fine, but it means "the whole game in 3D" really means "the walking-around parts in 3D".

## What a full port costs

Two very different things could be called "3D":

**A. True 3D (modelled characters and buildings).** No. Every one of the ~45 characters and 13+
buildings would need a modelled, rigged, animated 3D version. The art pipeline is Canva/Grok
images; nothing in it makes rigged 3D models, and the Godot Android editor is a poor place to fix
them. On top of that, 18k lines of 2D code (combat, hitboxes, arenas, the soak test) get rewritten.
Months, and it would stop looking like Duff Quest.

**B. HD-2D view (this spike, grown up).** Doable. The smart way keeps the whole game simulation in 2D
(saves, combat maths, tests, soak all untouched) and adds a 3D *view* that mirrors positions into a
diorama, like this spike does with the map data. Rough size, in sessions like the ones so far:

| Piece | Sessions |
| --- | --- |
| Town + streets + all storefronts, NPCs and enemies mirrored | 2-3 |
| Home interior, the Fork exterior, the 9 arenas | 3-4 |
| Combat feel in 3D (slashes, boss telegraphs, camera) | 2 |
| 3D web template, boot test, iPhone + Android perf, Lite mode | 2 |
| Play-test fixes, renders, both editions | 2 |
| **Total** | **about 11-13** |

Behind a Settings toggle ("3D view: on/off") so 2D stays the default until it's proven on phones.

## Recommendation

Don't rewrite the game in 3D. Ship the 2D game to CrazyGames first, get the playtest notes, then
decide on the HD-2D view (option B) as a version 2 feature. Do it as a toggle, the overworld only,
starting with the town, so nothing that works today breaks.
