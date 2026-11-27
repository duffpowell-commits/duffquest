# Kitchen polish render and performance evidence

Actual Godot 4.7.2 Compatibility renderer captures, 1280×720, software OpenGL (Mesa llvmpipe), MSAA off. These are not concept images. Before = PR #229 (`167e67e`); after = visual-only branch `preview/kitchen-visual-polish`. Each paired view has exactly the same camera transform, orthographic size, aspect, and idle pose sampling (.4s).

| View | Before | After |
|---|---|---|
| Elevated three-quarter | [before](before-elevated.png) | [after](after-elevated.png) |
| Lower whole-room | [before](before-lower.png) | [after](after-lower.png) |
| Grill and fryer | [before](before-grill.png) | [after](after-grill.png) |
| Pass | [before](before-pass.png) | [after](after-pass.png) |
| Character integration | [before](before-character.png) | [after](after-character.png) |

The [lower HUD footprint guide](after-lower-hud-guide.png) overlays the existing porch button/strip positions, not live controls. The full-room lower composition overlaps the right thumb area. The [pulled-back mobile candidate](after-mobile-safe.png) and its [footprint guide](after-mobile-safe-hud-guide.png) keep the five station signs and characters clear of the marked controls at 16:9. Trade-off: characters are smaller; a later approved gameplay camera should frame each active station/character dynamically. Neither candidate has been integrated into gameplay or tested on a real phone.

## Measured performance

60 frame wall-clock timing after eight warmup frames, elevated view, vsync disabled, characters playing idle. Same capture script and display settings. These are cloud software rendering data, **not Android measurements**.

| Metric | Before | After |
|---|---:|---:|
| Cloud FPS | 15.02 | 11.95 |
| Cloud ms/frame | 66.58 | 83.66 |
| Renderer draw calls/frame | 1,171 | 75 |
| Reported primitives/frame | 139,552 | 166,132 |

Static kitchen meshes are consolidated into 25 material batches; 93.6% fewer draw calls overall. Small shared 256×256 mipmapped weathered albedo/roughness maps, bounded bevel bands, 16-segment cylinders, limited transparent wisps and contact shadows; no new paid assets or character modifications. Additional visible detail and shaded geometry increase primitives and software frame time. Target = 60 FPS on Samsung Galaxy S26 Ultra; no Android device available here, so target remains **unverified**. The cloud regression should be investigated before accepting a production kitchen performance budget.

## Limitations and gate

Mottling and tile repetition are still stylized, grease and steam are subtle, and the cutaway and primitive food/utensils retain a diorama look. Compatibility lighting uses broad ambient, warm local lamps, directional shadows and cheap contact patches, not physical GI/SSAO. Character skin and rig assets are unchanged. The lower camera guide does not prove touch usability or actual Android aspect behavior. No new collision objects (the baseline preview had none), geometry layout/actor transforms unchanged, no new gameplay or 2D changes. PR #228 porch exact-build phone acceptance and review requirements still apply. Do not integrate or merge until approved.

Reproduce from repository root with `xvfb-run -a godot --path spike_full3d --audio-driver Dummy --rendering-driver opengl3 --resolution 1280x720 --disable-vsync --script tools/kitchen_polish_shot.gd -- /absolute/output/path after`. For before, run the same tool copied into a checkout of `167e67e` with the last argument `before`.
