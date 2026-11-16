# Duff Quest 3D: build plan (Nov 16, 2026)

Duff's call (Nov 16): "We are gonna make it 3D." This is the plan for doing that without breaking the
2D game that ships today.

## The shape of it

- **2D sim, 3D view.** The game logic stays exactly where it is (main.gd, player, combat maths, saves,
  daily, soak, test_daily). A new 3D view reads positions from the 2D world every frame and draws them
  as an HD-2D diorama, the way `spike3d/town3d.gd` already does with the map data.
- **Toggle first, default later.** Settings gets "3D view: on/off", off by default. It flips to default
  on only after Duff and Brittany have played it on iPhone and Android.
- **Overworld first.** The town is the first thing in 3D. Minigames, phone, menus, dialogue and HUD stay
  2D and draw on top. Home interior, the Fork exterior and the arenas come later.
- **Same art.** Every character, storefront and prop is a painted card. No modelled characters.
- **Each step is its own PR.** Duff says "merge" to ship each one. Nothing merges on its own.

## Steps

| # | Step | What ships | Sessions |
|---|------|-----------|----------|
| 0 | HD Duff sheet | Hi-detail Canva sheet of Duff so close-ups hold up (art job, started Nov 16) | 1 |
| 1 | 3D web engine | `tools/web_template/custom.py` with 3D on, new release `web-template-3d`; boot test vs the 2D engine; the live build keeps the 2D engine until step 7. **Done Nov 16: +0.8 MB, +0.7 s** | 1-2 |
| 2 | View scaffold | `scripts/view3d/` in the main project, loaded only when the engine has 3D (`ClassDB.class_exists("Node3D")`), so the 2D web build never parses it; Settings toggle; `arena_shot -- at:X,Y,MIN --3d` renders | 1 |
| 3 | Town in 3D | Spike town moved in: ground, storefronts, props, fences, lamps, time-of-day from `hd_presentation.gd` SKY keys; Duff, NPCs, enemies and quest markers mirrored from the 2D nodes | 2 |
| 4 | Combat feel | Slashes, hit sparks, boss telegraphs and the camera in 3D; touch buttons unchanged | 2 |
| 5 | Rest of the walkable world | Home interior, the {fork_nick} exterior, the 9 arenas | 3-4 |
| 6 | Phones | Auto Lite turns shadows and blur off; iPhone + cheap Android perf pass; CrazyGames zip size check | 1 |
| 7 | Default on | Both editions rendered and play-tested, then 3D becomes the default (2D stays as an option) | 1-2 |

Total: about 12-15 sessions.

## Step 1 result (Nov 16)

Engine built from `tools/web_template_3d/custom.py` (release `web-template-3d-preview`). Same game, same packs,
throttled 4G, headless Chrome (`tools/web_boot_test.py`):

| | 2D engine (live) | 3D engine | Change |
|---|---|---|---|
| Template zip | 7.3 MB | 8.1 MB | +0.8 MB |
| wasm on the wire (gz) | 7.2 MB | 8.0 MB | +0.8 MB |
| Title screen | 9.9 s | 10.6 s | +0.7 s |
| New Game playable | 17.9 s | 18.4 s | +0.5 s |
| Console errors | none | none | |

The full 2D game runs unchanged on the 3D engine. `spike3d/webcheck/` (ground, shadowed sun, glow + fog, the HD
Duff card) renders in WebGL 2 on it: `docs/renders/spike3d_web_engine_check.png`.

3D physics stays OFF in the profile. The spike's `town3d.gd` and `duff3d.gd` use CharacterBody3D / StaticBody3D
and do NOT parse on this engine. That is fine: the plan is 2D sim, 3D view, so the view never needs 3D physics.
Step 2 ports the view as plain Node3D/Sprite3D/MeshInstance3D driven by 2D positions; walls and movement stay in
the 2D world. Turn physics 3D on only if a later step proves it needs it (and re-measure).

## Rules that carry over

- No 3D node may be created on the 2D web engine. Until step 1 ships, every 3D script stays under
  `spike3d/` or behind the ClassDB check.
- Public build: "Spatula", never a bare "Fork". Madison scenes: Duff approves every line, as today.
- Duff's look: both tattoo sleeves, fox tattoo on the LEFT side of the neck, facing front. His T-shirt sleeves
  are plain black and cover the top of his tattoos (Duff, Nov 16: permanent). The HD sheet is rebuilt only with
  `spike3d/tools/build_duff_hd.sh`, which paints both fixes in and fails if sleeve print is left. When the
  sheet moves into the main game (step 3), test_daily gets the same sleeve check.
- Tests (`test_daily`, soak) run before every push. The 3D view must not change any sim result.

## Risks

- Web boot gets heavier (roughly +1.5-2 MB, +1-2 s on 4G). Measured in step 1, not guessed.
- Cheap Android browsers may choke on real-time shadows. Step 6 decides the Lite fallback.
- The cards are flat, so the camera can never rotate. That is how HD-2D games work and it stays that way.

## HANDOFF (Nov 16, 04:15Z) - read this first in the next thread

**State.** Branch `claude/project-thread-pilmt3`, draft PR #106 (umbrella for the whole 3D track; sessions can only
push to this branch, so each step is its own commit and its own "merge" ask). Nothing is merged; the live game
(itch, Pages, APKs) still runs the 2D engine. Done: step 0 (HD Duff sheet, real fox, sleeves fix) and step 1 (3D
web engine, numbers above). test_daily ALL PASS at dd67396.

**Duff's authorization (Nov 16 04:10Z).** Continue steps 2 through 6 without asking, show renders after EACH step,
then STOP before step 7 (3D as the default). Nothing merges until Duff says "merge".

**Permanent rules.** T-shirt sleeves are plain black and cover the top of his tattoos, no print (rebuild the HD sheet
only with `spike3d/tools/build_duff_hd.sh`; step 3 adds its sleeve check to test_daily). Fox tattoo on the LEFT side
of the neck, facing front. Public build: "Spatula", never a bare "Fork". Madison lines: Duff approves each one.

**Step 2: design settled, no code written yet.** Findings from reading the code:
- `scripts/game.gd` renders main.tscn in a 640x360 SubViewport `vp`, nearest-scaled. Put the 3D view in its OWN
  full-resolution SubViewport (own_world_3d) in a SubViewportContainer added BEFORE `box` (so it sits underneath),
  created only when `ClassDB.class_exists("Node3D")`, script loaded with `load("res://scripts/view3d/view3d.gd")`
  (never preload: the 2D web engine must never parse it).
- While 3D is live (setting on + `main.location == "outside"`): `vp.transparent_bg = true`, main's world hidden the
  same way `main._update_world_cover()` already does (`visible = false` + `HD2DPresentation.set_world_shown(false)`;
  CanvasLayers like the HUD/dialogue keep drawing). Fold the 3D flag into `_update_world_cover` so the two don't fight.
  Also add the 3D viewport to `WorldGate` (game.gd) so opaque overlays pause it.
- Setting: `audio.gd` gets `view3d` (default false) in `to_dict()`/`load_settings()` + `set_view3d()`. Settings screen
  (`scripts/minigames/settings.gd`): button "3D view: OFF (3)" at Rect2(110, 22, 100, 13), only when Node3D exists;
  add it to `_tint_toggles`.
- View contents for step 2: ground plane from `Ground.texture()` (drawn at `Rect2(Ground.origin()/2, size/2)` world
  units), sun + ambient tinted from `HdPresentation.SKY` by `main.clock`, Duff as a Sprite3D card mirroring
  `main.player`: sheet `player.sheet_name()`, frame col `Art.walk_col(anim_t, moving)` (3 when swinging), row
  `Art.row_for(facing)`, cell/origin/density from `Art.info()` (2x sheets: cell 128, origin [64,120], s 4 ->
  pixel_size = U / s). Billboard FIXED_Y, alpha cut, cast shadow. Mapping 2D (x,y) -> 3D (x*U, 0, y*U), U = 0.1;
  camera offset like the spike, `CAM_OFF = (0, 12.5, 16)`. Reuse code from `spike3d/town3d.gd` but no 3D physics
  (the 3D engine has none; the 2D sim owns movement and walls).
- Render: `arena_shot.tscn -- at:X,Y,MIN --3d` (turn the setting on in `_ready`, shoot at frame ~230). Save to
  `docs/renders/view3d_step2.png`, then post it to Duff.
- Step 3 then moves the spike's buildings/dressing/lamps in and mirrors NPCs/enemies/markers; the HD Duff sheet
  moves from `spike3d/art/` into `assets/art/` with the sleeve check in test_daily.

**Tools that work in this sandbox.** Release assets: curl REST `releases/assets/<id>` with
`Accept: application/octet-stream` (`gh release download` is blocked). Boot test needs `pip install playwright` and
Chrome at `/usr/bin/google-chrome`. To boot-test the 3D engine, swap
`~/.local/share/godot/export_templates/4.5.stable/web_nothreads_release.zip` and put the 2D one back afterwards.

## HANDOFF 2 (Nov 16, 12:00Z) - steps 2-6 done
Branch `claude/project-thread-fhx6e4`, draft PR #109 (supersedes #106). Nothing merged. Steps 2-5: town, combat FX
overlay, rooms, native-res render. Step 6: `View3D.set_low()` driven by `perf_guard.gd` (Lite = 1.5x render, no
MSAA, shadows or glow; full caps at 3x). Ground: the branch has an AI 2x upscale; the Canva repaint lands on main from
the HD thread, take main's `ground_painted.png` + `ground.gd` when merging main in. Open before step 7: a real-phone
test (iPhone Safari + cheap Android) of the 3D view, and Duff's go for 3D as the default.
