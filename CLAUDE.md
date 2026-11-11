# Duff Quest — handoff (read this first)

Comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent, work the line at the Twisted Fork,
fight exes and porch pirates. Godot 4.5, GDScript, 640×360 viewport (1280×720 window). Owner: Duff.

**Read order:** this file → `TRACKER.md` (Built / Next / Could improve) → `reference.md` (how every system works) →
`CLAUDE_REFERENCE.md` (itch target, art tools, key facts). History: `docs/handoffs/SESSION_LOG.md` (old long log)
and `docs/handoffs/*.md`. Work queue detail: `QUEUE.md`.

## Status (Nov 10, 2026 evening)
- **main is green and live.** GitHub `duffpowell-commits/duffquest` is the ONLY home. GitLab is dropped for now
  (Duff, Nov 10): don't push there, don't ask for a GitLab token. `.github/workflows/mirror_gitlab.yml` exists and
  skips cleanly without its secret; leave it or delete it, it does nothing.
- **Every push to main ships:** `.github/workflows/build.yml` parses scripts, runs the smoke test, exports web +
  debug APK, refreshes the `dev` release, and butler-pushes the web build to itch `dufftkyosht/duff-quest:html`
  (secret `BUTLER_API_KEY`, confirmed working Nov 10). A red CI = nothing ships.
- **Done this session (Nov 10):** IGN review fixes (phone wording, gentler week one, gala invite timing); title screen
  shows the real Duff (both sleeves + fox neck tattoo, `tools/title_compose.py`); the six themed boss arenas are real
  painted art (alley, Seen Cafe, Club Cloud 9, crypto garage, tower office, Waffle Haus) with walls fitted to each
  painting. Renders: `docs/renders/arenas_painted_ingame.png`, `docs/renders/title_tattoos_before_after.png`.
- Also Nov 10 (late): interact prompt above Duff's head is now a dark pill with cream text (was illegible on the
  teal rug); barks dodge it. Render: `docs/renders/hint_prompt_pill.png` (render id `hint`).
- Tests: `test_daily` ALL PASS; 30-day soak clean.

## Next (in order; details in TRACKER.md)
1. **Itch page:** CI-build switch DONE (Duff, Nov 10). Still: paste `docs/itch/PAGE.md` + images. Duff's step on the itch dashboard; sessions can't reach itch.io.
2. **Nov 10 Canva drop: DONE** (cat loading screen, 9 scene backdrops, gala floor). Render: `docs/renders/backdrops_nov10.png`.
3. **Brittany playtest** of the gentler first week (iPhone).
4. **Balance:** softened Nov 10 (gates 45-65, slower wait drain with a floor of 40). Re-check after Brittany's playtest.
5. **IGN review v2: 7.1/10** (`docs/reviews/ign_review_2026-11-10_v2.md`). Phone onboarding DONE (Nov 10 night,
   `scripts/touch_tutorial.gd`, render `docs/renders/touch_onboarding.png`). Next milestone = **let the art breathe**:
   translucent bottom-anchored minigame panels so the paintings show + fix sprite-vs-painting scale in arenas.
   Then one signature move per bounty boss; 4G first boot (~60 s, 38 MB wasm).

## Commands (cloud sandbox)
- Godot: 4.5-stable Linux zip from GitHub releases → `/usr/local/bin/godot`. Fresh clone: `godot --headless --path . --import`
- **Tests (before every push):** `XDG_DATA_HOME=/tmp/xdg_x godot --headless --path . --script tools/test_daily.gd`
  must print `ALL PASS (0 failed)` with no `SCRIPT ERROR`; then `git checkout -- .godot/exported`.
- Soak (30 days, every system through real code, ~10+ min):
  `XDG_DATA_HOME=/tmp/xdg godot --headless --path . --fixed-fps 30 --script tools/soak.gd -- --seed=1` (add `--lazy` for the rent/upset paths)
- Smoke (what CI runs): `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
- In-engine renders: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- <id>`
  (ids: a boss arena, `bounty:sendback`, `waffle`, `title`, `home`, `hint`, `at:X,Y`) → `/tmp/qa/`. Copy keepers into `docs/renders/`.
- Phone onboarding render: `res://tools/touch_shot.tscn` + `python3 tools/touch_sheet.py` (forces touch mode).
- Arena walls: `godot --headless --path . res://tools/arena_wall_check.tscn`
- After swapping art: `touch` the files, then `godot --headless --path . --import`.
- CI status: `gh api repos/duffpowell-commits/duffquest/actions/runs?per_page=5` (`gh` GraphQL is blocked; the
  Actions secrets API is blocked too, so secret names can't be listed from a session).

## Art pipeline
- House style C: `docs/art_direction/STYLE_LOCK.md`. Duff always has both tattoo sleeves + fox neck piece (`docs/duff_look.md`).
- **Fully automatic art pipeline (Nov 10), no Duff steps:** Canva `generate-image` -> put each media id full-bleed on
  its own 1920x1080 page of one Canva design (`edit-design` insert_fill, commit) -> `export-design` png -> Zapier
  Google Drive "Upload File" (connection `023ae0fb-19cc-8509-b28e-979de3a98f75`, pass it as connection_id) with the
  export URL into Drive "97 Gemini art drops" (folder id `1kwe88L_hV7qM_-It2I8n6ZRTMchYoFT4`) -> Drive connector
  `download_file_content` (spills to a tool-results JSON file; decode `content` with python, don't read it into
  context). The sandbox itself can't fetch Canva export URLs; Zapier can. Export links expire in hours: re-export.
- Backdrops + loading screens: `tools/backdrop_import/import_backdrops.py <dir>` (1280x720, manifest "s": 4, then set
  `compress/mode=1` in the .import and reimport). Check: `res://tools/backdrop_shot.tscn` + `tools/backdrop_sheet.py`.
- Arenas: `tools/arena_import/import_arenas.py`; title: `tools/title_compose.py`. Big HD art ships lossy (`.import` mode 1).

## House rules
- GitHub main only. Never force push. `git fetch` before starting and before pushing. One session per repo at a time.
- Push after every chunk of work; merge to main at the end of every milestone (no work left on a branch).
- Up to three milestones per session; update this file + `TRACKER.md` after each.
- Run the tests before every push. Show real engine renders for visual decisions; save them in `docs/renders/`,
  don't paste piles of images into chat.
- Duff is phone-only (Godot Android editor): GDScript only, no desktop-only tools or steps.
- No keys or tokens in the repo, commits, logs or chat. Duff sets secrets himself.
- Netlify credits are spent; builds go out via the `dev` release and itch.

## Layout
- `game.tscn`/`main.tscn` → `scripts/main.gd` (overworld, menus, dialogue, arenas; the biggest file).
- `scripts/minigames/`, `scripts/waffle.gd` (Waffle Haus shift), `scripts/boss.gd`, `scripts/daily.gd`.
- `data/cast.json` every real/parody name (`{key}` tokens). `scripts/art_manifest.gd` sprite/backdrop map.
- `tools/` tests, soak, render shots, art importers. `docs/renders/` renders. `docs/reviews/` reviews.
