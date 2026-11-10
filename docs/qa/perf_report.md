# Phone/web performance report (Nov 9)

## How it was measured

- **`tools/perf_run.tscn`**: runs the real game (`game.tscn`) through 7 scenes, 45 warm-up frames
  and 240 measured frames each: title, town walk, home walk, street fight (4 enemies + swinging),
  boss (Gym Bro, swinging), KO cutscene, fridge calendar. It uses a throwaway save.
  ```
  xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/perf_run.tscn -- [scenes=town,boss] [off=post|lights|hud|touch|fx|overlay] [low]
  ```
- This ran on desktop with **llvmpipe**, which is software OpenGL, in a 1280x720 window, so it stands in for a phone
  GPU's fill rate. The build machine was shared with other agents (load average 9-18 on 2 cores), so wall-clock
  times are noise. The main number is **cpu_ms**: process CPU per frame from `/proc/self/stat`, across all
  threads, including llvmpipe's rasteriser. It barely moves with machine load. "Before" and "after" ran
  side by side under the same load. The before run was a `git archive HEAD` copy with the same harness.
- I also did a headless run with no GPU. GDScript plus engine CPU comes to only **1-2 ms a frame** in every
  scene, so the scripts aren't the bottleneck. Rendering is.
- **`tools/web_boot_check.py`** checks the real web build in headless Chrome, set up like a phone:
  915x412 landscape, DPR 2.625, touch, Android UA, 4x CPU throttle, WebGL2 on SwiftShader.

## Before / after (cpu_ms per frame, llvmpipe; draws = GL draw calls per frame)

| scene    | before cpu_ms | after cpu_ms | change | before draws | after draws | lite mode cpu_ms |
|----------|--------------:|-------------:|-------:|-------------:|------------:|-----------------:|
| title    | 65.7 | 31.1 | **-53%** | 119 | 24  | - |
| town     | 64.4 | 65.9 | ~0       | 163 | 157 | **37.0 (-43%)** |
| home     | 42.9 | 44.1 | ~0 (noise) | 138 | 81 | - |
| fight    | 63.8 | 62.9 | ~0       | 168 | 162 | **42.8 (-33%)** |
| boss     | 42.9 | 40.8 | -5%      | 147 | 83  | 34.3 (-20%) |
| KO       | 91.7 | 70.8 | **-23%** | 150 | 35  | - |
| calendar | 101.5 | 68.1 | **-33%** | 226 | 94 | - |

In Chrome (SwiftShader, 4x throttle, while walking): full graphics averaged a 705 ms frame (p95 1117).
With `#lite` it was 304 ms (p95 367). That's a software-GPU worst case, not a real phone, but the
ratio is the useful part: **lite is about 2.3x faster on fill-bound hardware.** (A rerun under heavier machine load gave 1389 ms for full graphics, so compare runs side by side only.)

## Hot spots found

1. **The world kept rendering under full-screen screens.** Loading screens, the fridge calendar and
   the KO cutscene are opaque HD layers on top. Under them, the 640x360 world still rendered every frame,
   with 9 lights and the HD-2D screen shader. The same happened under every opaque menu and minigame
   (the title, the phone, shop, shift minigames).
2. **`main._draw` drew all four places every frame.** Town, home interior, gala and arena all went into
   one canvas item, even though only one is ever on screen. Godot can't cull inside one item, so the
   commands and texture switches for the other three were submitted anyway.
3. **The soft window lights cost about 15 ms of the 65 ms in town, and the screen shader about 9 ms**
   (`off=lights`, `off=post`). The ground and buildings are one big canvas item, so all 7 town lights
   shade every world pixel. The screen shader forces a full-screen copy (`hint_screen_texture`) plus
   5 texture taps per pixel.
4. **Texture memory grew during KO cutscenes.** `knockout.gd` cached every 1280x720 still forever,
   about 3.7 MB of texture each and about 6 per boss. Across all bosses that could reach 140 MB, which
   is past what iPhone Safari lets a tab keep.
5. Things that were fine: no per-frame allocations worth fixing, no unbounded particles (object and node
   counts stay flat in every scene), and `_process` scripts are cheap (1-2 ms total).

## Fixes (the look doesn't change)

- `scripts/main.gd`: `_draw()` draws only the current location. It redraws on any location change,
  even while busy. `_update_world_cover()` hides the world and its screen shader while an opaque
  `minigame.gd` overlay is up. Every overlay paints its whole 320x180 first.
- `scripts/game.gd`: `WorldGate` stops the SubViewport rendering
  (`render_target_update_mode = DISABLED`) while the loading screen, calendar or KO cutscene fully
  covers it (`covers_screen()` on each). It runs at `process_priority` 1000, so it sees this frame's state.
- `scripts/knockout.gd`: the cutscene's stills are freed when it ends. Sounds stay cached.
- **Lite graphics** (`scripts/perf_guard.gd` + `hd_presentation.set_low`) turns off the HD-2D screen
  shader and the 9 window lights. The pixel art is untouched.
  - It switches on **automatically on web and mobile** if real play (not menus or loading) averages
    under 40 fps for two 3-second windows. It's remembered in `user://perf.cfg`. It never switches
    itself on in desktop or xvfb tool runs, so renders keep full graphics.
  - There's a manual toggle under **Settings → "Graphics: Full / Lite"** (V key). Choosing by hand
    turns the auto switch off. You can force it with the URL hash `#lite`.

## Loading (first boot)

- The build is 54 MB after main's lossy-WebP change: `index.pck` is about 16 MB and **`index.wasm`
  about 38 MB**. The engine binary is now the biggest download.
- Locally (4x CPU), the game reaches the title in **16 s**, most of it wasm compile and engine start.
  With `--net fast4g` (9 Mbps) it takes **63 s**: pck done at 32 s, wasm at 51 s.
  Gzip would shrink the wasm to about 9 MB if the host serves it compressed. Whether itch does that
  for HTML uploads is the next thing to check. It's the biggest remaining first-boot win.
- Nothing big loads eagerly at start. Art (`Art.tex`), KO stills, loading screens and boss cards all
  load when first used. The one boot-time cost is `ground.gd` building the 1344x768 town ground from
  tiles on the first frame: 144 ms on desktop, maybe 0.5-1 s on a phone. That's a one-off, so I left it.
- Emscripten prints "still waiting on run dependencies" via `console.error` every 10 s on slow
  connections. It's harmless, and the boot check counts it as benign.

## Still open

- On town and fight, full graphics is still fill-bound on weak GPUs. Lite mode is the answer there.
  Reproducing the lights inside the screen shader (one pass instead of per-item light shading) could
  make full graphics cheaper too. It needs a careful side-by-side render check, so I didn't do it here.
- About 155 draw calls in town come from per-building and per-prop textures. A texture atlas would cut
  them, but that's asset work, which is the asset agent's area.
