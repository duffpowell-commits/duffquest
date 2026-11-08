# Duff Quest

Comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent,
work the line at the Twisted Fork, fight exes and porch pirates. Godot 4.5, GDScript, 640×360
landscape (HD chibi pixel art since Nov 7; was 480×270). Owner: Duff. Read this first; it is the handoff between sessions.

## Where things stand
- **Source recovered Nov 7, 2026.** The game was built elsewhere (Grok) and only builds survived
  (Windows zips v0.2–v0.10.1 in Duff's Drive; web build at
  https://lighthearted-custard-a79ec2.netlify.app). This repo was rebuilt from that web build's
  `index.pck` (Godot 4.4.1) with `tools/recovery/`:
  - `detok.py` turns compiled scripts (`.gdc`, binary tokens) back into GDScript. Original
    **comments are gone**; line layout and indentation are rebuilt from the token line/column maps.
  - `recover.gd` (run with `--main-pack`) writes `project.godot`, textures as PNG, music as OGG
    (rebuilt from Godot's packet data), and dumps QOA sounds that `qoa2wav.py` decodes to WAV.
  - `main.tscn` was one node + script, rewritten by hand.
- Proof: all 61 scripts parse; the title screen matches the original pixel for pixel
  (`docs/renders/recovery_title_original_vs_rebuilt.png`); scripted playthrough (new game, intro,
  walk, pick up an Ensure, phone) runs clean (`docs/renders/recovery_smoke_playthrough.png`).
- Original Windows-build version history is not in git (only the final state).
- Lethemoor is Duff's active game; Duff Quest is the side project. Chaos is paused.

- **Dialogue voice done (Nov 7):** 436 narration lines across 31 scripts rewritten as Duff telling
  the story at the bar, **present tense** (Duff's call). Guide: `docs/voice.md`. Left alone on
  purpose: other characters' lines (Madison, bosses, NPCs), combat barks, texts, UI, quiz/word lists,
  Madison's show-and-tell. Applied with `tools/apply_rewrites.py` (rejects changed `{tokens}` /
  `%d` codes, raw quotes, >1.5x length, literals used elsewhere). Render: `docs/renders/dialogue_voice_smoke.png`.
  Unverified: whether any longer toast lines clip on narrow screens. Look for it when playing.
- **Dialogue polish (Nov 7, later):** 117 lines reworked to cut the storyteller tics ("So..."
  68x -> ~10, "goes," / ", right?" / "Then" mostly gone), punchier originals restored for quick
  popups. Rules added to `docs/voice.md` ("Tic budget"). Keep to them.
- **HD art merged (Nov 7):** `duffquest_hd_project.zip` (Duff's Drive; made outside this repo
  from the v0.10 pck) ported onto main without touching gameplay: 110/131 sprites and backdrops
  replaced (chibi Style A), viewport 640×360, `UI_SCALE` 2.0, camera smoothing off, pixel snap,
  `scripts/hd_presentation.gd` + `shaders/hd2d.gdshader` (LDR bloom/vignette, warm tint, window
  and lamp lights), soft contact shadows in `art.gd`. Its notes: `docs/hd/`. Renders:
  `docs/renders/hd_art_merged_smoke.png`, `hd_vs_original_neighborhood.png`.
  Claude's review: much cleaner than the old art but generic. Same cream houses, lollipop trees,
  empty grass, pale low-contrast palette, Seen Cafe reads as a clinic. Smoke only covers
  outdoors + phone; interiors, combat and bosses not eyeballed yet.
- **ART DIRECTION CHANGED (Nov 7, evening): no longer EarthBound.** World + character sprites:
  modern high-detail pixel art like **Sea of Stars** (saturated, warm sun, soft coloured shadows,
  lush detail), same 64 px 4×4 sheet format. Dialogue portraits + boss intros: bold cartoon like
  **Hazbin Hotel** (thick tapered ink lines, angular shapes, exaggerated faces, flat cel shading;
  humans, not demons). Keep it bright and sunny, opposite of Lethemoor. Prompts: Drive doc
  "DuffQuest — Style bible + Grok prompts" (https://docs.google.com/document/d/1lmADUpw6NO0A_rvmwdox_t2oJoh8yZVLc1AXliRUwnE/edit); capability test doc updated to match.
  **Open tech issue:** the game renders at 640×360 (viewport stretch), so cartoon portraits get
  downsampled to ~192 px and lose line quality. Fix options: render the dialogue layer at native
  resolution (stretch mode canvas_items + pixel world in a SubViewport), or bake portraits at the
  displayed size with thick lines. Decide when the first portraits land.
- **Art personality pass (EarthBound-era brief, partly superseded):** Duff makes art with Grok. Brief + prompts:
  `docs/art_brief.md` (also a Google Doc "READ ME FIRST - Grok prompts" in Drive folder
  **DuffQuest Art Inbox**, with `reference_current_HD.png`). One Drive folder per design, three
  options (A/B/C) each: 00 Style board (pick first), 01 Storefronts (13 buildings, one folder
  each), 02 Trees, 03 Street clutter. Duff marks winners with a star in the filename or says so.

- **Grok capability test (Nov 7):** Doc "DuffQuest — Grok capability test" in Drive folder
  DuffQuest Art Inbox (https://docs.google.com/document/d/1ay5y-iWh__M8sJx4JbcHVWp0WvOMgoi8g2gFnHzAtC4/edit).
  Tests D1–D7 (4×4 sheet in the game's exact format, Duff upgrade, DBZ combo, hurt, portraits,
  sign spelling, show-off). Results go in Drive subfolder **99 Grok capability test**
  (`d1_try1.png`...). Attach `reference_duff_sheet.png` (inbox) = `assets/art/duff_home.png` on
  magenta. When Duff says it's in: pull, score (rubric in the doc), make GIFs, fill the doc's
  results table, then write the real design prompts around what passed.
- **Sheet format:** humanoid sheets are 256×256, 4×4 cells of 64; rows down/up/right/left;
  cols stand, step A, step B, attack (`art.gd`: `WALK = [1,0,2,0]`, col 3 = attack).
- **PR #2 (`cursor/add-duffquesthd-7d71`, Cursor):** adds `duffquesthd/` = the HD zip as a
  separate Godot 4.4.1 project + 42 MB web build. Its art is byte-identical to main (131/131);
  its dialogue is the OLD pre-voice text (40/40 sampled lines) and it lacks the walking fix.
  Claude recommends closing it unmerged; Duff said "not yet" (Nov 7). Don't merge without asking.

- **`grok_art/` (Nov 7):** drop folder for Grok designs (never ships), README has rules + log.
  First in: `duff_portraits.jpg` (Duff's cartoon portraits, approved look). **v2 approved** (`duff_portraits_v2.jpg`,
  from his photo: dirty-blond undercut/ponytail, ear spikes, fox neck tattoo, black tee). Cut with
  `tools/import_portrait.py` -> `assets/art/portraits_hd/duff.png` (3×512 cells, transparent).
  **Next:** native-res dialogue layer so these keep their lines, then swap them in for `portrait_duff`.
  The walking sprite should be updated to match (undercut/ponytail, black tee).

## Next (Duff's asks)
- When Grok art lands in the Drive inbox: pull it (subagent; Drive returns big base64), clean
  to the grid (magenta key, nearest downscale, palette quantize), composite storefront facades onto
  `assets/art/map_outside.png` at the `buildings` footprints, swap trees/props, render before/after.
- Graphics update, flesh out the world, possible Google Play release (from Duff's plans).
- Combat goal: action RPG like the GBA Dragon Ball Z games.

## Layout
- `main.tscn` → `scripts/main.gd` (the whole overworld, menus, dialogue; ~the biggest file).
- `scripts/minigames/` fryer, pickles, pharmacy, ending, card, etc.
- `data/cast.json` every real name and parody name (`{key}` tokens in code). `data/*.txt` word lists.
- `assets/art/manifest.json` sprite sheet map; `assets/iso/` iso map + objects; `assets/audio/`.
- `tools/smoke.tscn` scripted playthrough used by CI. `tools/recovery/` the recovery kit.

## Commands
- Godot in the cloud sandbox: download the 4.5-stable Linux zip from GitHub releases with curl,
  move to `/usr/local/bin/godot`. Fresh clone: `godot --headless --path . --import`.
- Parse check: `godot --headless --path . --check-only --script <file>`
- Smoke test (before every push):
  `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
  then look at the frames.
- CI: `.github/workflows/build.yml` parses scripts, runs the smoke test, exports web + debug APK,
  and refreshes the **`dev` release** on every push to `main`:
  https://github.com/duffpowell-commits/duffquest/releases/tag/dev
  `gh` GraphQL is blocked in Claude sessions: use `gh run ...` / `gh api repos/...`.

## House rules
- One Claude session per repo at a time. `git fetch` before starting and before pushing.
- Duff is phone-only (Godot Android editor). GDScript only, no desktop-only tools.
- Push after every chunk of work; merge to `main` at the end of every milestone.
- Up to three milestones per session; update this handoff and merge after each.
- Save renders to `docs/renders/`, don't paste lots of images into chat.
- Netlify free credits are spent (Chaos used them); test builds go out via the `dev` release / itch.
