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
- **iPhone full screen:** iPhone Safari has no fullscreen API, and itch's iframe can't be installed. CI also exports a
  PWA copy (`build/pages`) and deploys it to https://duffpowell-commits.github.io/duffquest/ (job `pages`, main only;
  needs Settings > Pages > Source: GitHub Actions). Players open it in Safari, Share > Add to Home Screen, then launch
  from the icon: no Safari bars. Native iOS builds are out (no Mac, no Apple developer account).
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
  **Brittany's Side Gig** (day 5+, cover-or-rat choice card, payoff next day; `arena_shot` `gig`).
  **Lost & Found, Omaha** (day 3+, flyer at the home mail table, 3 glinting finds outside, return to the Seen Cafe
  paper box; `arena_shot` `lost`). All four quests are live.
- **Storefronts (Nov 12):** all 13 exteriors repainted at 4x density (`sf_*`, manifest "s": 4). Re-import one with
  `python3 tools/import_storefront_hd.py grok_art/2026-11-12-storefronts/_work/<name>_v1.png <name> [--up N]` (masters: Drive "97 Gemini art drops", `sf_<name>_v1.png`), then touch +
  `--import`. Keep each lot's bottom edge and door x; check doors with the before/after map render.
- **Street props (Nov 12):** 17 trees/clutter (`sd_*`, not fences) repainted at 4x density, same footprints. Re-import
  with `python3 tools/import_dressing_hd.py grok_art/2026-11-12-props/_work [name ...]` (masters: Drive "97 Gemini art
  drops", `sd_<name>_v1.png`; `BOX` in the script = max world size). `Dressing.art_rect()` honours density + origin.
- **Fences + flat screens (Nov 12):** the 4 fence kinds are painted at 4x (`sd_<kind>_straight`, each segment carries
  both posts, 39 units post to post, no end piece). Re-import: `python3 tools/import_fence_hd.py
  grok_art/2026-11-12-props/_work` (masters `sd_fence_<kind>_v1.png` in Drive). Don't re-run `tools/import_dressing.py`
  (it rewrites the old fences). Phone app icons, Wordle tiles, grocery goods/kiosks/people, symphony mirror/bus/notes/snacks
  and show & tell pillows come from the `k7_sheet` (`kf_*`, `tools/import_kitchen_props.py`). Cards: `b["stack"] = true`
  puts an icon above the label. UI audit now has `symphony_bus/_concert/_snacks` shots.
- **Characters (Nov 12):** all 20 v1 chibi walk sheets (inspector, pete, karen + buddy, hoa, butler, drunk, heckler,
  kid, hustler, scammer, cashier, chef, pharmacist, sushi chef, phlebotomist, sitter, usher, waitress, madison_dress)
  repainted in the Sea of Stars style of `ch_brittany`; the Grease Trap boss has its own `ch_grease` (no tint).
  Phone avatars (`av_*`) are head crops of the new sheets. Re-do one: Canva sheet (4x4, magenta) ->
  `tools/fix_sheet_cells.py` for backwards frames -> `tools/prep_canva_sheet.py SRC OUT --mirror-left` (strips grid
  lines, row 4 = mirrored row 3) -> `tools/import_big_sheet.py OUT ch_<name>`. Masters: Drive "97 Gemini art drops",
  `ch_<name>_v1.png`. Old `ch_grillboy` is unused. HD dialogue portraits were already current.
- **Lighting (Nov 12):** time of day lives in `hd_presentation.gd` (`SKY` keyframes, door pools, sun-driven
  `Art.sun_shift`). Render any hour with `arena_shot -- at:X,Y,MIN`. Grok art scratch goes in `grok_art/<drop>/_work/`
  (ignored); the 674 MB already there stays (no history rewrites).
- **Web packs + slim engine (Nov 13):** web boot 19.9 s -> 9.3 s (title, throttled 4G). Three packs: `index.pck`
  (1.8 MB: scripts, data, fonts, sfx, small UI), `world.pck` (10 MB, fetched first after boot; characters, portraits,
  music, storefronts, props, kitchen/home/gala/arena art) and `extra.pck` (late art). Both built by
  `tools/make_extra_pack.gd -- OUT world|late`; `scripts/extra_pack.gd` mounts them. Continue/New Game wait on a
  "Loading Omaha..." card until world.pck lands (~23 s cold, cached after). Anything new under `assets/` that the
  title doesn't need: add its glob to the Web preset `exclude_filter` and to `WORLD` in make_extra_pack.gd.
  The engine is a trimmed 2D-only Godot 4.5 web template (`tools/web_template/custom.py`, built by
  `.github/workflows/web_template.yml` into release `web-template-2d`; branches use `web-template-2d-preview`).
  No 3D nodes, no `Image.create` (use `create_empty`), WorldEnvironment via ClassDB only. Changed the profile? Run
  that workflow and play-test the build. Storefront/prop sizes are baked in `data/art_rects.json`
  (`tools/bake_art_rects.gd`, test_daily checks it): re-run the bake after re-importing sf_/sd_ art.
  Branch builds publish to the `web-preview` release (sessions can't download Actions artifacts).

- **Cold open (Nov 13):** new game = porch-pirate fight first, rules after (`main.gd cold_open()`, flag
  `story.cold_open`). Web packs are now street -> world -> extra: `street.pck` (STREET globs in
  `tools/make_extra_pack.gd`, 2.9 MB) gates New Game; world.pck gates Continue and, via `_world_gate`, the Fork,
  arenas, gala and minigames. New outdoor art a day-1 player sees: add its glob to STREET. Render:
  `arena_shot.tscn -- cold` with `--fixed-fps 30`. Browser timing: `tools/web_boot_test.py` reports all three packs.

- **Raccoon + Jen (Nov 13):** `raccoon` re-import: `python3 tools/import_critter_strip.py <strip.png> raccoon`
  (4 frames facing right on a key colour; row 1 is the mirror). `ch_jen` re-import: prep_canva_sheet (no mirror) ->
  `import_big_sheet.py OUT ch_jen --tol 70` (grey hair on Canva's purple key needs the low tolerance).
- **Hy-Whee floor (Nov 13):** top-down store, shelves baked into `bg_grocery` on the `SHELVES` rects by
  `python3 tools/grocery_floor_compose.py <old bg_grocery from git 88c80a8> assets/art/bg_grocery.png`. Move a shelf
  in grocery.gd -> re-run it. Items sit on the shelf top (`SPOTS` y = shelf y - 3), grabbed from the lane above.

- **Labels (Nov 13):** any text over painted art goes through `UiStyle.tag()` (minigames: `tag()`), never bare dark
  `txt()`. Audit + open list in `TRACKER.md` (PRs #48, #49).
- **Combat (Nov 13):** Searing Spatter cut; S + swap hide until the first special (Pinwheel Lv 2). Duff said combat
  was easy: `main.DMG_TAKEN` 1.25, story exes +20% HP (`boss.STORY_HP_MULT`, Willnot timer 250 s), night spawn cap +3.

- **Legal (Nov 13):** ranked risks in `docs/legal/RISK_AUDIT.md` (not legal advice). In-game Settings > Credits &
  legal carries the parody notice + Godot/OFL licenses; keep it, `docs/itch/PAGE.md` Legal and the end credits in
  sync. Privacy policy: `docs/legal/PRIVACY.md`.
- **Editions (Nov 13):** public = default export (itch, Pages root, `duffquest-public.apk`): `data/cast_public.json`
  overrides cast.json and `Art.pub()` loads `<name>_pub.<ext>` art. Family = feature tag `family` (Pages
  `/family/`, `duffquest.apk`, same package id as before): real names, real Fork, Bruce Willnot, Brittany (public: Mazikeen; write `{coworker}`, never her name, in new lines). New real brand or
  real person? Put the family name in cast.json, the public one in cast_public.json, add a test_daily leak word.
  Re-make the `_pub` art with `python3 tools/make_public_art.py` (keeps sizes; set big ones to lossy in .import).
  Render either edition: `arena_shot.tscn -- <id> --family`.

- **Madison's mornings (Nov 13):** EDS slow / migraine / good mornings, `scripts/mornings.gd` (see reference.md).
  Madison is a real person: Duff approves EVERY line about her EDS, autism and ADHD before it ships. One pitch at a
  time. Off-limits: the mess of her stuff, and that she's on disability.
- **Portal fit (Nov 13 late):** windows where integer scaling wastes >10% now scale fractionally (`HdPresentation.use_fractional`), so CrazyGames' 907x510 iframe is filled. Touch pad on the web shows up front only on iOS/Android browsers, else on the first real touch (`TouchControls.default_visible()/real_touch()`; mouse-emulated touches have device -1). Listing copy: `docs/portals/LISTING.md`.
- **Portal polish (Nov 14):** keyboard/mouse players: the cold-open line says "WASD or arrows to walk, Space to bonk"; the level/heat panel sits bottom-right (`combat_ui.PANEL_R_KEYS`) instead of floating where the touch buttons would be; enemy name + Lv labels are on ink plates. The sandwich ticket's house item is `{house_sandwich}` (public: Spatula Classic). Renders in keyboard mode: add `--keys` after the id (xvfb reports a touchscreen).
- **Web portals (Nov 13):** `duffquest-crazygames.zip` in the dev release is the CrazyGames upload (no plain
  index.wasm; `window.DQ_PORTAL` = clean + gore off for new players). Checklist: `docs/portals/SUBMIT.md`.
- **Marketing footage (Nov 13):** `tools/promo_shot.tscn` plays scripted takes (`fight:<boss>`, `walk:X,Y,MIN,DX`,
  `still:gala|madison|at:X,Y,MIN`) with fake input, no damage, KO beats on a timer, touch UI hidden. Record with
  `--fixed-fps 30 --resolution 1920x1080 --write-movie DIR/f.png` (1080p is native, integer 3x). Point XDG_DATA_HOME at
  a folder whose `godot/app_userdata/Duff Quest/settings.json` says `{"clean":true,"gore":false}`. Outputs live in
  `docs/portals/preview/` (CrazyGames clips) and `docs/itch/` (GIFs, 1080p screens). ~3 fps under llvmpipe.
  GameDistribution: Duff registered as "Wild Dreams" (Nov 13), gameId after review.

## Next (in order)
1. **Ask Duff for his and Brittany's playtest notes first** (iPhone + his Android). They outrank the rest.
2. **Itch page:** Duff pastes `docs/itch/PAGE.md` + images (sessions can't reach itch.io).
3. **Grease boss art:** done Nov 12 (own sprite `ch_grease`, alley arena already its own). Left: nothing unless Duff asks.
4. **Boot:** done Nov 13 (title in 9.3 s on throttled 4G, was 19.9 s). See the Web packs note above.
5. **Balance re-check** after the playtest (gates 45-65, wait drain floor 40).
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
