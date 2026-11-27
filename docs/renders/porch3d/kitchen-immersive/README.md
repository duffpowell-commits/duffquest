# Kitchen immersive preview — visual review

These are actual 1280×720 Godot 4.7.2 OpenGL Compatibility screenshots (Mesa llvmpipe software renderer), not concept art or composited mockups. No HUD was attached. The comparison only places the earlier engine screenshot beside the new gameplay camera screenshot; the camera angles differ intentionally.

| Capture | Purpose |
|---|---|
| [full.png](full.png) | Whole kitchen and adjoining booth room |
| [gameplay.png](gameplay.png) | Default closer perspective camera; original cast and station locations |
| [grill.png](grill.png) | Equipment and cooking surface close-up |
| [dining.png](dining.png) | Kitchen-to-dining sightline, pass, booths and ceiling |
| [character.png](character.png) | Original Duff under practical lighting and cast shadow |
| [before-after.png](before-after.png) | Prior preview vs new interior |

## Against concept

- **Space:** strong improvement; continuous red/cream floor, walls, ceiling, booth seating, pass opening and service door remove the floating platform. The existing linear hot line remains, unlike the reference's aisle flanked by equipment. Stations are intentionally not relocated.
- **Camera:** the default perspective is inside the room and establishes scale. The grill is near the edge and the pass is seen mostly side-on. Readable mobile interactions and HUD clearance are not demonstrated by this visual-only slice.
- **Materials:** subtler brushed wear, stainless splashback, red/cream ceramic and dark grout, rubber mats, warm red vinyl and painted walls. The concept's convincing reflective steel, varied edge wear, grease, patina, and detailed hand-painted surface variation are not achieved. Some surfaces still show repeated texture and the window panes are solid stand-ins.
- **Equipment and storytelling:** existing beveled cabinets, controls, fryer baskets, cookware, tickets, utensils, condiment bottles and towel remain; added service door, duct, stacks, layered burgers, pendant lamps, booth and table detail. Food and utensils still look stylized and geometric; grill close-up needs bespoke food and appliance meshes, stronger steam, and more authentic hood geometry.
- **Lighting:** warm fixtures and cool ambient, visible directional/cast and contact shadows. Some highlights are overbright and shadows too hard. The concept's atmospheric bounce/specular detail and lived-in mood remain beyond this pass.
- **Cast:** unchanged original model files, rigs, animation and original positions; shadows improve grounding. No new assets or purchases.

**Assessment:** substantially improved in enclosure and camera; still below the approved concept's visual fidelity. Keep this as a reviewable preview, not a finished milestone or production kitchen.

## Reproduce

From `spike_full3d` with Godot 4.7.2 and a graphics display:

```sh
godot --path . --resolution 1280x720 --script tools/kitchen_immersive_shot.gd -- /absolute/output/folder
godot --headless --path . --script tools/kitchen_immersive_smoke.gd
```

The capture tool also reports 60-frame elapsed time and rendering counters. This run: **5.91 FPS, 206 draw calls, 472,943 primitives** on the software rasterizer. This is not an Android benchmark and does not verify 60 FPS. Existing rig meshes account for much of the geometry; the architecture is batched by material with visibility groups kept separate. Device profiling and LOD/lighting tuning remain necessary before production.

## Regression checks

- Focused kitchen smoke: PASS (station and character origins, perspective, visibility and preview isolation).
- Existing 3D porch smoke: 159 PASS lines, no FAIL or SCRIPT ERROR; resource leak diagnostics on shutdown.
- Root `tools/test.sh`: ALL PASS (0 failed), TESTS PASS; ObjectDB leak warning on shutdown.
