# Duff Quest — handoff (read this first)

Comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent, work the line at the Twisted Fork,
fight exes and porch pirates. Godot 4.5, GDScript, 640×360 viewport (1280×720 window). Owner: Duff.

**Read order:** this file → `TRACKER.md` (Built / Next / Could improve) → `reference.md` (how every system works) →
`CLAUDE_REFERENCE.md` (itch target, art tools, key facts). History: `docs/handoffs/SESSION_LOG.md` (old long log)
and `docs/handoffs/*.md`. Work queue detail: `QUEUE.md`.

## Status (Nov 11, 2026 morning)
- **main is green and live.** GitHub `duffpowell-commits/duffquest` is the ONLY home (GitLab dropped; the
  `mirror_gitlab.yml` workflow skips cleanly, ignore it).
- **Every push to main ships:** `.github/workflows/build.yml` parses scripts, runs the smoke test, exports web +
  debug APK, refreshes the `dev` release, and butler-pushes the web build to itch `dufftkyosht/duff-quest:html`
  (secret `BUTLER_API_KEY`). A red CI = nothing ships.
- **IGN review v3: 7.9/10** (`docs/reviews/ign_review_2026-11-11_v3.md`). Duff + Brittany played it Nov 11: "it's
  come a long way."
- **Last session's handoff (read it): `docs/handoffs/2026-11-11_painted_minigames_ign_v3.md`.** It covers what
  shipped, the step-by-step prop-art pipeline, the ranked next list and the gotchas.
- Tests: `test_daily` ALL PASS; 30-day soak PASS (seed 1, 0 issues).

- **Side quests (Nov 12):** `scripts/side_quests.gd` + phone Notes journal + `!`/`?` markers + typewriter dialogue.
  New quests: add to `SideQuests.LIST`, wire triggers in main.gd, then flip `ready: true`. Dev: Settings > "Dev:
  quests" (debug builds), `#dq=quest:<id>:<stage>` (web), `arena_shot` ids `quest` / `type` / `notes`.
  **Live: porch mystery** (day 2+, ends fighting Cheeto Chad; `arena_shot` `porch` / `chad`) and **The Grease Trap**
  (day 4+, 86 List after 10 PM, boss `grease` reuses Grill-Boy tinted; `arena_shot` `grease86` / `bounty:grease`).
  Still `ready: false`: Brittany's gig, lost & found.
- **Lighting (Nov 12):** time of day lives in `hd_presentation.gd` (`SKY` keyframes, door pools, sun-driven
  `Art.sun_shift`). Render any hour with `arena_shot -- at:X,Y,MIN`. Grok art scratch goes in `grok_art/<drop>/_work/`
  (ignored); the 674 MB already there stays (no history rewrites).

## Next (in order)
1. **Ask Duff for his and Brittany's playtest notes first** (iPhone + his Android). They outrank the rest.
2. **Itch page:** Duff pastes `docs/itch/PAGE.md` + images (sessions can't reach itch.io).
3. **FULL overworld repaint (Duff's pick):** painted neighborhood, home and Fork exteriors at real footprints, so
   walking around matches the fights and minigames. The ground is already painted (`scripts/ground.gd`). Guard the
   collision and doors.
4. **The last 5 flat screens:** phone, symphony, show & tell, grocery map, wordle keyboard (one props sheet).
5. **Boot under 10 s** (17.0 s now): move the next-biggest chunk of index.pck to `extra.pck`.
6. **Balance re-check** after the playtest (gates 45-65, wait drain floor 40).
History of everything built: `TRACKER.md` (newest first).

## Commands (cloud sandbox)
- Godot: 4.5-stable Linux zip from GitHub releases → `/usr/local/bin/godot`. Fresh clone: `godot --headless --path . --import`
- **Tests (before every push):** `XDG_DATA_HOME=/tmp/xdg_x godot --headless --path . --script tools/test_daily.gd`
  must print `ALL PASS (0 failed)` with no `SCRIPT ERROR`; then `git checkout -- .godot/exported`.
- Soak (30 days, every system through real code, ~10+ min):
  `XDG_DATA_HOME=/tmp/xdg godot --headless --path . --fixed-fps 30 --script tools/soak.gd -- --seed=1` (add `--lazy` for the rent/upset paths)
- Smoke (what CI runs): `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
- In-engine renders: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- <id>`
  (ids: a boss arena, `bounty:sendback`, `gala:husk`, `move:coupon:storm:22`, `waffle`, `title`, `home`, `hint`, `at:X,Y`) → `/tmp/qa/`. Copy keepers into `docs/renders/`.
- Phone onboarding render: `res://tools/touch_shot.tscn` + `python3 tools/touch_sheet.py` (forces touch mode).
- UI audit (every menu + minigame, touch mode): `res://tools/ui_audit_shot.tscn` + `python3 tools/ui_audit_sheet.py <tag>`
  -> `docs/renders/ui_audit_<tag>.png`. Play objects use `prop()` / `prop_circle()` (minigame.gd -> UiStyle), never raw
  `draw_rect` fills.
- Web boot test (needs web export templates in ~/.local/share/godot/export_templates/4.5.stable): export Web to
  /tmp/bw, `tools/make_extra_pack.gd -- /tmp/bw/extra.pck`, `gzip -9 -k -n /tmp/bw/index.wasm`, then
  `python3 tools/web_boot_test.py /tmp/bw 8832 after` (headless Chrome, throttled 4G, prints seconds + bytes).
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
