# Duff Quest HD

HD-2D graphics version of Duff Quest (Style A, 64px chibi). This folder is its own Godot project. The game at the repository root is unchanged.

Gameplay, dialogue, economy, saves, movement, combat, map coordinates, collision, and interaction spots are the same. What changed is presentation: textures, texture metadata, viewport density, and lighting.

**Engine:** Godot **4.4.1** stable, GL Compatibility.

## Open it

1. Install [Godot 4.4.1 stable](https://godotengine.org/download/archive/4.4.1-stable/).
2. Import `duffquesthd/project.godot`.
3. Press Play. The game viewport is 640×360, shown in a 1280×720 window.

`.godot/` is gitignored and is rebuilt the first time the project is imported.

## Web build

`web/` is a **Web HD** release export made with Godot 4.4.1.stable (`49a5bc7b6`, the engine named in the notes). It is single-threaded and needs WebGL 2. The prebuilt `duffquest_hd_web.zip` on Drive is 11.3 MB, which is over the 10 MB download cap used here, so this folder is that same preset exported again rather than an unzip of that archive. Serve it over HTTP. Opening `index.html` with `file://` will not load the package:

```bash
cd duffquesthd/web
python3 -m http.server 8000
```

Then open http://localhost:8000/ .

To export again, install the 4.4.1 web export templates and from this folder run:

```bash
godot --headless --editor --import --quit
godot --headless --export-release "Web HD" web/index.html
```

On the web, bloom is an LDR screen shader. Native HDR glow is only used if the project is opened with a desktop renderer that supports it.

## Known gaps

Full notes are in `HD_NOTES.txt`.

- 21 catalog images are still the original art: seven buff icons, seven mood icons, five small HUD glyphs, the phone graphic, and the unused palette.
- The 22 textures in `assets/iso/` (optional isometric experiment) are unchanged.
- Procedural UI, text, weapon arcs, cooking-minigame shapes, and some script-drawn effects keep their original geometry.
- Concept enemies (Bitter Brew, upright Bin Bandit) were not added. Existing enemies keep their mechanics. Some costumes and poses are simplified. Many NPCs share one chibi base with different palettes and role details, rather than unique hand animation.
- Portrait screens under 640px wide use nearest-neighbor downscaling so controls are not cropped, which drops some pixels. Landscape is the intended layout.
- Checked with a native smoke pass (move, attack, roll, home, phone, save/load, all 131 textures) and Chromium software WebGL, including an emulated phone. Not covered: a full campaign, Safari, a physical Android or iPhone, long sessions, or every quest branch.
- Recovery marked 27 resource conversions as lossy.
