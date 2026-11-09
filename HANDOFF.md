# DuffQuest — FULL HANDOFF (Nov 9, 2026, 13:40 CT)

Standalone: a cold session needs only this file to pick up. Last commit at writing: see `git log -1`.
Deeper references: `CLAUDE_REFERENCE.md` (stable facts), `CLAUDE.md` (history log, top bullets newest),
`QUEUE.md` (NOW / NEXT / DONE), `tasks/todo.md`, `tasks/lessons.md`, `docs/HANDOFF_NOV9_PM.md` (same-day detail).

---

## 1. What this is
DuffQuest: a comedy action RPG about Duff Powell's real life in Omaha (line cook at "the Twisted Fork", partner
Madison, baby Octavia, three cats). 30-day November calendar, rent/shifts/errands, street fights, 17 bosses with
comic-panel knockout cutscenes. Godot 4.5, GDScript, landscape, 640x360 game + HD overlay layer. Web build on itch.
**Duff works from his phone only** (Godot Android editor). No desktop steps, ever. Automate everything.

## 2. Start of session (no questions for Duff)
1. **Keys** live in the Cloudflare D1 vault `duff-vault` (id `af975dad-2989-45e3-92c9-03caf55f14e3`). Cloudflare MCP:
   `d1_database_query` -> `SELECT name, value FROM secrets` -> `GITLAB_TOKEN`, `BUTLER_API_KEY`.
   Never ask Duff to paste keys. Keys stay in env vars only (never repo, `.git/config`, memory, chat).
   GitLab token **expires 2026-12-08** (remind Duff ~Dec 1; replace the vault row with `INSERT OR REPLACE`).
   It has NO `api` scope (can't set CI variables).
2. **Clone:** `git clone https://oauth2:$GITLAB_TOKEN@gitlab.com/dufftkyosht-group/duffquest.git` then
   `git remote set-url origin https://gitlab.com/dufftkyosht-group/duffquest.git`.
   **Push:** `git push https://oauth2:$GITLAB_TOKEN@gitlab.com/dufftkyosht-group/duffquest.git HEAD:main`.
   GitHub `duffpowell-commits` is suspended (appeal filed); `duffpowell/duffquest` on GitLab is an empty stub.
3. **Ship:** `BUTLER_API_KEY=... tools/ship_itch.sh [--web-check]` installs Godot 4.5 + web templates + butler if
   missing, sets lossy imports, imports, runs test_daily (fails on SCRIPT ERROR too), 600-frame smoke, exports,
   scans for secrets, pushes to **`dufftkyosht/duff-quest:html`** (NOT `html5`). `--no-push` = build only.
   `--web-check` boots it in headless Chrome as a phone.

## 3. State at handoff
- **itch** https://dufftkyosht.itch.io/duff-quest — channel `html` has build **`532e95b`** (everything below).
- **BLOCKER Duff must clear (dashboard, 1 min):** the page's Run-game embed plays OLD upload `20348255`
  `duffquest-web.zip` (manual, Nov 7). Butler updates upload `20362247` `duff-quest-html.zip`, which only shows in
  the download list. Fix: Edit game -> Uploads -> delete `duffquest-web.zip`, tick "This file will be played in the
  browser" on `duff-quest-html.zip`; Embed 1280x720, Mobile friendly (landscape), Fullscreen button.
  Verify: scrape the page rawHtml; iframe must be `html-classic.itch.zone/html/20362247/`. Claude in Chrome is not
  available from Duff's phone, and the itch API can't change this.
- **Page copy + images ready:** `docs/itch/PAGE.md` (Palahniuk-voice description, features, controls, content
  warning, honest AI disclosure, settings checklist), `docs/itch/cover.png`, `logo.png`, `logo_banner.png`,
  `icon_512.png` (built by `tools/make_logo.py`), `screens/`, `knockout.gif`. Duff pastes/uploads them.
- **Game content:** 17/17 bosses with live knockout cutscenes. All HD art in **house style C**. In-engine cartoon gore.
  30-day soak passes (6 seeds). Gala unlocks story **day 24**.
- **Build:** 54-56 MB (38 MB = stock engine wasm). Auto Lite graphics on slow phones.

## 4. Decisions Duff made (Nov 9) — don't relitigate
- Real names (Madison, Octavia, Jen, Brittany) are OK on the public build.
- **Art style C** for every HD image (cards, portraits, KO stills, loading): card-style faces + thick tapered ink +
  flat colour, KO panels keep speed lines + light hatching. `docs/art_direction/STYLE_LOCK.md`, checklist ST1-ST7 in
  `docs/art_rules.md` §7. No image outside the lock.
- Billionaire parody bosses -> **Madison's exes at the gala**: Tyler Pivot (id `husk`, influencer), Grant Gratuity
  (`bozos`, tip-app CEO), Landlord Lance (`fences`, owns their building), Chip Leverage (`donald`, final; bought the
  Fork). Baron Von Trustfund stays as host. Names in `data/cast.json`. Old set saved in `docs/dlc_concepts/billionaires/`.
- Gala opens story day 24 (`GALA_DAY` in `scripts/main.gd`); Octavia's $100k fund is a separate long-term goal.
- **Jams:** itch "2026 Jam" bans AI art -> out. Seasonal RPG Game Jam host (illustrator) signals anti-AI -> skip.
  No email exists for her anyway. Plan = launch DuffQuest on itch as a normal free game. Options ranked in
  `tasks/todo.md` (AI Browser Game Jam #6 in Dec if posted; free listings: 5 Year Long Jam, Best Game of the Year).
- Unreal: not viable (Duff has no PC). Stay on Godot.

## 5. NEXT, in order
1. **Duff:** itch embed fix (section 3), then paste `docs/itch/PAGE.md` + upload images. Get Madison's OK on the
   "settled for a funnier one" line.
2. **Gala exes' in-world sprite sheets** `ch_husk/ch_bozos/ch_fences/ch_donald` still show the OLD billionaire faces
   in town/fights. Make style-C 4x4 sheets (see how other `ch_*` sheets are cut; brief in `docs/gala_exes_art_brief.md`).
3. **Balance (needs Duff's call):** players who skip the evening shower + couch never meet the happiness gates for
   4/5 story bosses (`docs/qa/soak_report.md`). Either teach the routine (prompt/toast) or loosen the gates.
4. Optional art: reframe `assets/art/ko/willnot_b.jpg` (jaw cut by the engine's x-ray crop) and `dasher_b.jpg`, or loosen
   the crop in `scripts/knockout.gd`. `data/loading_screens.json` lists `cat_sacrifice.jpg`, which doesn't exist.
5. First boot on 4G ~60 s: check whether itch serves `index.wasm` compressed (would be ~9 MB); else a custom stripped engine.
6. M7: 16 more backgrounds, now in style C via Canva.
7. Brittany playtest on iPhone; tune pacing (soak bot said gala/happiness balance; rent grind unknown by feel).

## 6. Art pipeline (style C)
- Generator: **Canva `generate-image` + Claude** (code does keying, cutting, recolor, lettering, gore, logo). Grok is out.
- **Only ONE agent may use Canva at a time** (rate limit).
- First reference for any image with Duff: canonical face sheet `docs/art_direction/duff_face_sheet.png`
  = Canva media **`MAHacL92VLk`**. Character face sheets on white + style refs: `docs/reviews/style_c_convert.md`.
- Duff's look (rules D1-D7, `docs/duff_look.md`): near-black blackout sacred-geometry LEFT sleeve, fox on LEFT neck,
  creature head on RIGHT forearm (NOT a panther), eye-in-triangles hand. Give sides from the VIEWER's view.
- Canva gotchas: puts the sleeve on the wrong arm when Duff is chest-on (mirror + targeted edit); paints the fox on
  his RIGHT neck when his head turns viewer-right (edit: "remove the neck tattoo, plain skin"); draws guns in Willnot's
  holster (ask for an empty holster); the game crops the top 13% of intro cards (keep heads low; `tools/letter_card.py --drop`).
- Full-size export via a Canva scratch design: `DAHacBeu8SQ` is at 91 pages -> **start a new one**.
- Names on cards are lettered in code: `tools/letter_card.py`. Portrait halos: `tools/clean_halo.py` (also run by
  `tools/import_portrait.py`).
- KO stills 1280x720 JPG q88; per-boss gore hit point = optional `"impact"` key in `data/knockouts.json`.

## 7. Testing & QA tools
- `godot --headless --path . --script tools/test_daily.gd` -> must print ALL PASS **and** no `SCRIPT ERROR` lines.
- Smoke: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/s/f.png --quit-after 600`.
- Soak: `tools/soak.sh` (30 days, several seeds; checks gala day 24, money/energy never negative, all bosses).
- Web: `tools/web_boot_check.py` (or `ship_itch.sh --web-check`). Perf: `tools/perf_run.tscn`, `docs/qa/perf_report.md`.
- Text fit: `tools/text_fit.gd` -> `docs/text_fit.txt` (0 overflows). Note: it doesn't check `data/knockouts.json`.
- Render tools (save to `docs/renders/`, never paste many images into chat): `ko_shot` (`-- <boss> [gore]`), `qa_shot`,
  `hud_shot`, `gala_shot`, `calendar_shot`, `settings_shot`, `ui_shot`, `barks_shot`, `ysort_shot`, `map_shot`, etc.

## 8. Gotchas (cost real time on Nov 9)
- **Always verify what the public itch page plays**, not just butler status (two HTML uploads; only one embedded).
- test_daily prints ALL PASS even when a script fails to compile -> grep SCRIPT ERROR.
- After merging new art, `touch` the image files before `godot --import`, or the tracked `.godot` cache keeps old art.
- Check `git merge`'s exit code; an untracked file (e.g. an auto-generated `*.gd.uid`) aborts it silently in a pipeline.
- Never glob-delete `tools/*.gd.uid` — many are tracked. Remove only untracked ones (`git ls-files --others`).
- `.godot/editor/` is untracked; `.godot/imported` + `uid_cache.bin` are tracked (merge noise: take either side, reimport).
- Parallel agents: each needs its own `git worktree` AND its own `XDG_DATA_HOME=/tmp/xdg_<name>` (with
  `godot/export_templates` symlinked to `/root/.local/share/godot/export_templates`), or they share user:// saves.
- The 5-hour usage limit hits with ~8 agents running; resume paused agents with SendMessage after the reset.
- Tests must never touch the real user:// save (`tasks/lessons.md`).

## 9. Duff's house rules
Push after every chunk; merge to main at every milestone (never leave work on a branch); keep `CLAUDE.md` + this
handoff current; run tests before every push; real engine renders for visual decisions, saved to the repo; phone-only;
blunt, concise, no fluff; push back if there's a better way; automate instead of handing him steps.
