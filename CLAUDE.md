# Duff Quest

EarthBound-style comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent,
work the line at the Twisted Fork, fight exes and porch pirates. Godot 4.5, GDScript, 480×270
landscape, pixel art. Owner: Duff. Read this first; it is the handoff between sessions.

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

## Next (Duff's asks)
- **Dialogue rewrite: "as if Duff were telling a story"**, i.e. Duff at the bar after a shift
  ("so I walk in, right, and..."). Narration, home, errands and quest setups get the story voice;
  **combat barks stay short and punchy** (Claude's pushback, Nov 7). Open: present tense
  ("so I walk in") vs past ("so I walked in"). ~900 lines, mostly in `scripts/main.gd`, then
  `boss.gd`, `enemy.gd`, `errands.gd`, `life.gd`, `shift.gd`, `moods.gd`, `data/*.json`.
  Keep `{partner}`, `{baby}`, `{cat1}` etc. tokens: names live in `data/cast.json`.
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
