DUFFQUEST — STYLE A CHIBI HD GRAPHICS BUILD

Open project.godot using Godot 4.4.1 stable. Web export preset: "Web HD".
Original gameplay, dialogue, economy, saves, movement, combat, map coordinates,
collision Rect2s and interaction locations are preserved. Only presentation,
texture metadata and textures changed. This is the earlier CHIBI Style A art,
not the rejected taller artwork. The home Duff idle is pixel-identical to the
approved 64px reference.

RECOVERY
GDRE Tools 2.7.4 recovered the uploaded PCK (engine 4.4.1): 514 files verified,
61 scripts decompiled with zero failures, all 250 imported resources converted.
GDRE classified 27 conversions as lossy. Main scene and editable project settings
were recovered. A runtime GDScript art catalog included 14 assets absent from
the JSON catalog; both have been reconciled to retain all 131 runtime assets.

GRAPHICS
110 of 131 catalog assets replaced with ORIGINAL style-matched art:
- 57 humanoid sheets, 64x64 cells, four directions x four existing animation slots.
- Duff work/home variants; Madison, family members, shop staff, enemies and bosses.
- Four family/animal sheets, baby, rolling poses, shades and clothing showcase.
- Three portrait sheets and eight phone avatars.
- All 20 background textures: neighborhood, home, stores, kitchens, date venues,
  gala and combat arenas, rebuilt against original map/collision coordinates.
- 32px ground atlas and original trees, benches, fences, bushes, buildings,
  windows, lamps, furniture, packages, trucks and drone graphics.
Many NPCs deliberately share a chibi base with different original palettes,
headwear and role details; these are not individually hand-animated bespoke NPCs.

Native density increased to 2 pixels per world unit. Internal viewport changed
480x270 -> 640x360 and camera/UI scale 1.5 -> 2.0, preserving the exact logical
field of view and UI geometry. Character frames occupy 32x32 world units;
terrain cells are 16x16 world units (32 native pixels), so a character is roughly
two tiles tall. Doors and furnishings were drawn to fit existing map footprints.
Nearest filtering, screen snapping and integer upscaling retain crisp pixels.
Camera smoothing disabled to avoid subpixel wobble. On a screen smaller than
640x360 only, fractional NEAREST downscaling prevents cropped phone controls.
Landscape is recommended; portrait letterboxes and necessarily loses native pixels.

HD-2D PRESENTATION (ACTUAL ENGINE EFFECTS)
- Art.shadow uses a reusable soft-alpha contact shadow texture.
- CanvasModulate gently warms the world canvas, leaving interface layers legible.
- PointLight2D adds soft warm pools at windows and lamps.
- A lightweight 5-sample screen shader adds gentle highlight bloom, a subtle
  upper-edge focus falloff and vignette behind the HUD.
- Godot 4.4 Web exports require GL Compatibility and cannot use HDR 2D. Therefore
  the shipped web build uses LDR shader bloom, NOT native HDR 2D glow. A separate
  WorldEnvironment enables HDR/glow only if opened with a compatible desktop
  RenderingDevice renderer. No claim of native HDR glow in the web build.

UNCHANGED / NOT FULLY RESKINNED
21 catalog assets remain original: seven buff icons, seven mood icons, five small
HUD glyphs, the tiny phone graphic and unused palette reference. The 22 textures
in assets/iso/ belong to the pre-existing optional isometric experiment and are
unchanged. Procedural UI panels, text, weapon arcs, cooking minigame ingredient
shapes and some other script-drawn effects retain their original geometry.
The Bitter Brew and upright Bin Bandit concept enemies were NOT inserted into
existing gameplay: existing enemy identities/mechanics are preserved. The game's
raccoons were redrawn as quadrupeds. Some costume/pose variations are simplified.

TESTS AND LIMITS
See the included HD_VALIDATION.json for browser and asset test results.
Native smoke test covers movement, attack, dodge roll, home transition, phone,
save/load round trip, and all 131 runtime textures. Chromium uses software
WebGL/SwiftShader for desktop and emulated phone viewport smoke tests.
This is not a complete playthrough or a real-device performance certification.
No physical Android/iPhone, Safari, long-run progression or every quest branch
has been tested. Graphics do not add new gameplay.

WEB BUILD
Extract duffquest_hd_web.zip into a folder and serve it over HTTP(S), e.g.
  python3 -m http.server 8000
then open http://localhost:8000/index.html . Opening index.html directly with
file:// generally cannot load WebAssembly/PCK. All game files are local; no
account, ads, purchase code or new network service was added. This export is
single-threaded to avoid requiring COOP/COEP hosting headers. WebGL 2 is required.
Host at the same origin/path if you want the browser's existing local save to
be available; saves do not automatically migrate across unrelated hosts.

BUILD FROM EDITABLE PROJECT
Install Godot 4.4.1 stable plus its Web export templates. From this directory:
  godot --headless --editor --import --quit
  godot --headless --export-release "Web HD" ../web/index.html
The .godot cache is excluded from the archive and is regenerated on import.
PNG artwork is editable source; all GDScript and map/scene settings are included.
No credentials or user saves are in either archive. Original uploaded ZIP untouched.
