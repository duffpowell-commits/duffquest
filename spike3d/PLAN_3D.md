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
