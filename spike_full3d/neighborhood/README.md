# Fork Around — neighborhood foundation (isolated visual prototype)

**Status:** draft, no production registration. This is a separate scene inside the existing 3D project, not a new live starting scene. No gameplay, save, dialogue, combat, economy or release changes. No paid assets or credits used. Branch directly from main; do not stack on the kitchen work.

## Run and inspect

From the repository root (cloud or CI; no desktop setup required of the owner):

```sh
godot --headless --path spike_full3d --import
godot --path spike_full3d res://neighborhood/preview.tscn
godot --headless --path spike_full3d --script neighborhood/smoke.gd
godot --headless --path spike_full3d res://neighborhood/preview.tscn -- --smoke
```

Move with arrows or the large on-screen directional buttons; choose one of four lighting presets. The HUD names the nearest mapped entrance/marker. Doors are deliberately exterior-only markers, not functional teleports or gameplay changes. The preview has no persistence or live clock side effects. Actual engine images and measured software-renderer timing are in [the render report](../../docs/renders/porch3d/neighborhood/README.md).

## Geography and modular kit

`geography.gd` preserves the `scripts/main.gd` building footprints at 0.1 m per map unit, x east, z south. The 64 × 36 m walkable rectangle and road centers (316, 175) come from the existing map and `town_life.gd`. No additional district. The lawn/road backdrop beyond the bounds is decorative only. All 13 original building footprints/entrances plus 8 fixed markers are covered by a route flood-fill test. Story door markers use the original rect-center / bottom+6 formula. HOA and garage share the same footprint marker; the neighbor entrance is a preview location, not an invented quest.

- North: home and porch, neighbor, Seen Cafe, Glasshaus Tower, Iron Temple, plasma, Kwik-N-Go.
- South: HOA HQ, Mining Rig, grocery, pharmacy, Club Cloud 9, the fictional restaurant, back door and bounty board.
- Crossroads: original four bus stops, Waffle Haus sign and existing porch position. Further off-block destinations (gala, dates, arenas, transit) are deferred as existing zone transitions, not relocated into invented buildings.

`kit.gd` provides reusable building types (house, brick shop, diner, club, garage and tower), sidewalks, facades, doors/windows, canopy, roof, foliage and cheap low-poly props. MultiMesh instances batch by material and geometry. Reuses approved porch siding, brick, shingle and cedar textures; new asphalt/concrete and other surfaces are free procedural painterly approximations (not hand-painted bespoke artwork). Same canonical `rig_actor.gd`, GLBs, textures and clips for the three visible character identities; no new people, dialogue, animations or altered bodies. The visual prototype has no character collision beyond footprint/bounds masking; props are decorative and the sidewalk/road ambience is static.

Omaha reference interpretation: porch-lined residential street, broad sidewalks, mature trees, utility poles and wires, curb parking, weathered brick corner shops, a metal canopy/glass diner and warm red nightlife signage. The supplied photographs are references only, not committed or reproduced as exact businesses. Generic fictional public-edition signage only. Evening is the signature warm hour; the existing `porch_daylight.gd` supplies sun, ambient fill and lamp multipliers at 08:00, 13:00, 18:00, 23:00. Two unshadowed street lamps and emissive windows keep night readable without a per-building shadow light.

## Future integration contract (plan, not implemented)

Use the existing 2D authoritative clock, day, residence, eligibility and save/quest state via a read-only adapter; the visual scheduler must never modify the simulation. The preview poses are illustrative, not canonical NPC schedule changes.

| Phase | Partner | Coworker | Street population / rules |
|---|---|---|---|
| Morning 08:00 | Apartment, bed or living room as `madison_spot()` determines | Existing outside bet position (288,140), no new dialogue | Preserve four cosmetic walkers, transit from 05:30, errands and eligible shop entrances |
| Afternoon 13:00 | Apartment per existing life logic | Existing bet position; kitchen appearance only if the shift scene owns it | Work and errands; use the actual calendar and event logic |
| Evening 18:00 | Apartment routines/couch per existing state | Existing bet position until zone/cutscene owns the actor | Warm lamps; shift remains gated by 06:00–22:00, weekend exception and holiday closures |
| Night 23:00 | Apartment/bed via existing bedtime logic | Do not invent absence or availability; read canonical state | Waffle shift only after existing conditions; transit until 23:30; cosmetic walker count falls to one under existing `town_life.gd` rule |

Future scheduler: select actor pose from authoritative zone and time; walking waypoints on existing sidewalk graph, animation speed through `rig_actor.move_at()`, fade or hide on interior entry, never duplicate an actor across loaded zones. Max six animated bodies visible per 3D building guide. NPC schedule must defer to story, active fight, dialogue, quest and shift ownership. No new buffs, rewards, partner lines, fights or NPCs.

Future transition: exterior marker -> existing eligibility check (`interactables`, `story_available`, `fork_open_now`, `Transit.running`, quest context) -> existing fade/loading card -> unload neighborhood visuals -> load canonical interior/arena -> canonical return spawn. No new transition costs or clock advancement. Home/porch must still respect the parcel and fight progression; restaurant must remain gated until kitchen approval. Preserve `Daily`, `Life`, `Shift`, `Transit`, `SaveGame`, `Errands`, `SideQuests`, and existing story gates, seniority/pay, rent, happiness and economy as the sole authorities. Keep the 2D edition unchanged. The prototype does not register `porch_zones.ZONES`, modify `porch.tscn`, edit project settings, add export presets or alter main/release CI.

## Android budget and acceptance

Target 16.67 ms/frame (60 FPS) on owner Android phone. Compatibility renderer, existing 960×540 logical viewport, no additional assets purchased, batched static geometry, two local unshadowed lights, one directional shadow source, up to three preview rigs. No dynamic weather or traffic simulation added. Actual Android FPS, frame-time percentiles, thermal/run stability and touch usability are **not yet measured**. Before production: optimize from device measurements (shadow distance/resolution, material batching/LOD, culling, fewer active rigs); use a representative walk through the crossroads and all four times, record at least 60 seconds per phase at device resolution, and review p50/p95/p99 frame times and thermal stability. Never claim the target from cloud software rendering.

**Hold:** PR #228 owner porch phone acceptance and 60 FPS; PRs #229–230 kitchen visual/production approval; then owner review of this environment, separate gameplay integration design, regression and Android performance gate. Do not merge or release this preview just because desktop smoke passes.
