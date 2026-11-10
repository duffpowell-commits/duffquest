# Putting Duff Quest on itch.io (web build)

Page: https://dufftkyosht.itch.io/duff-quest (note the hyphen. `duffquest` without one is not the page.)

## What was broken (Nov 9)

- **The itch page hasn't been updated since before Nov 7.** The handoff records the build there as 2.3 MB,
  from the old isometric version. The current game exports to about 115 MB.
  Builds came from the GitHub Actions workflow (`.github/workflows/build.yml`). Its itch step only ran
  if a `BUTLER_API_KEY` secret was set, and otherwise logged "skipping". Since GitHub suspended the
  account on Nov 8, no CI runs at all, and GitLab has no CI. Anything the page linked to on GitHub
  (the `dev` release zip) or Netlify (credits used up) is dead as well.
- **The export settings were fine.** No `export_presets.cfg` or `project.godot` changes were needed:
  - Renderer is `gl_compatibility` (also the `.mobile` override). Web needs that.
  - `thread_support=false` → single-threaded build, so it runs on itch without SharedArrayBuffer/COOP/COEP.
  - `include_filter="data/*, *.json, *.txt"` covers every file the scripts open with `FileAccess`
    (all 12 files in `data/` are packed). Everything else is loaded as an imported resource.
  - `tools/` and `docs/` are excluded. `grok_art/` has a `.gdignore`. `duffquesthd/` is skipped
    automatically because it is a separate Godot project.
  - All textures are imported lossless (no VRAM compression), so iPhone Safari can load them.

## The fix

The build was rebuilt from the current source with the official Godot **4.5-stable** web templates
(the same version CI used), then tested:

- Headless Chromium (WebGL2, **not** cross-origin isolated, the same as itch with SAB off) boots to the title
  screen and loads New Game with **zero console errors**. Screenshots: `docs/renders/web_boot.png`
  and `docs/renders/web_newgame.png`.
- Output: `build/duffquest_web.zip`, about 90 MB zipped (115 MB unzipped). It has 9 files with
  `index.html` at the zip root. That is well under itch's limits (500 MB, 1000 files).

To rebuild it yourself (needs a machine with Godot 4.5 and its web templates):

```
godot --headless --path . --import
mkdir -p build/web && touch build/.gdignore
godot --headless --path . --export-release "Web" build/web/index.html
(cd build/web && zip -9 -r ../duffquest_web.zip .)
```

## Uploading from your phone

1. Get `duffquest_web.zip` onto the phone (Drive, or whatever Claude sends it through). **Don't unzip it.**
2. In Chrome go to itch.io and log in. Tap ⋮ → **Desktop site**, because the edit page is cramped otherwise.
3. Open **Dashboard** → Duff Quest → **Edit game**.
4. **Kind of project** → **HTML**.
5. Under **Uploads**: delete the old HTML file with the trash icon, tap **Upload files**, and choose `duffquest_web.zip`.
   Wait until it finishes processing.
6. On the new upload, tick **This file will be played in the browser**.
7. Under **Embed options**:
   - Viewport dimensions: **1280 × 720** (the game is 640×360 scaled ×2).
   - Tick **Mobile friendly** and set orientation to **Landscape**.
   - Tick **Fullscreen button**.
   - Leave **SharedArrayBuffer support** off. The build doesn't use it.
   - Leave **Automatically start on page load** off. Click-to-play lets sound start on phones.
8. **Save**. Then open the page (and on an iPhone, ask Brittany), tap Run, and check it reaches the title screen.
   The first load is about 90 MB, so it takes a while on mobile data.

## Automated pushes later (butler)

This lets a future CI (or a Claude session) push new builds without you uploading anything.

1. On itch.io go to **Settings → API keys** (itch.io/user/settings/api-keys) → **Generate new API key**.
2. Store the key **only** in the CI system's secret settings:
   GitLab → `dufftkyosht-group/duffquest` → Settings → CI/CD → Variables → add `BUTLER_API_KEY`
   with **Masked** and **Protected** ticked. Don't paste it in chat, in an issue or in any repo file.
   Claude should never ask for it or store it.
3. A CI job then runs: `butler push build/web dufftkyosht/duff-quest:html --userversion <commit>`.
   The old GitHub workflow's last step shows the full recipe, which is easy to port to `.gitlab-ci.yml`.
