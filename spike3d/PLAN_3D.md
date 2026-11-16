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
| 1 | 3D web engine | `tools/web_template/custom.py` with 3D on, new release `web-template-3d`; boot test vs the 2D engine; the live build keeps the 2D engine until step 7 | 1-2 |
| 2 | View scaffold | `scripts/view3d/` in the main project, loaded only when the engine has 3D (`ClassDB.class_exists("Node3D")`), so the 2D web build never parses it; Settings toggle; `arena_shot -- at:X,Y,MIN --3d` renders | 1 |
| 3 | Town in 3D | Spike town moved in: ground, storefronts, props, fences, lamps, time-of-day from `hd_presentation.gd` SKY keys; Duff, NPCs, enemies and quest markers mirrored from the 2D nodes | 2 |
| 4 | Combat feel | Slashes, hit sparks, boss telegraphs and the camera in 3D; touch buttons unchanged | 2 |
| 5 | Rest of the walkable world | Home interior, the {fork_nick} exterior, the 9 arenas | 3-4 |
| 6 | Phones | Auto Lite turns shadows and blur off; iPhone + cheap Android perf pass; CrazyGames zip size check | 1 |
| 7 | Default on | Both editions rendered and play-tested, then 3D becomes the default (2D stays as an option) | 1-2 |

Total: about 12-15 sessions.

## Rules that carry over

- No 3D node may be created on the 2D web engine. Until step 1 ships, every 3D script stays under
  `spike3d/` or behind the ClassDB check.
- Public build: "Spatula", never a bare "Fork". Madison scenes: Duff approves every line, as today.
- Duff's look: both sleeves, fox tattoo on the LEFT side of the neck, facing front.
- Tests (`test_daily`, soak) run before every push. The 3D view must not change any sim result.

## Risks

- Web boot gets heavier (roughly +1.5-2 MB, +1-2 s on 4G). Measured in step 1, not guessed.
- Cheap Android browsers may choke on real-time shadows. Step 6 decides the Lite fallback.
- The cards are flat, so the camera can never rotate. That is how HD-2D games work and it stays that way.
