# DuffQuest handoff — Nov 9, 2026 (afternoon)

Paste-ready for a new session. Read in this order: `CLAUDE_REFERENCE.md` (keys, itch, art tools, decisions),
`CLAUDE.md` "Where things stand" (top bullets), `QUEUE.md` NOW, `tasks/todo.md` top sections, `tasks/lessons.md`,
`docs/art_rules.md` + `docs/art_direction/STYLE_LOCK.md`.

## Start of session (2 minutes, no questions for Duff)
1. Keys: Cloudflare MCP `d1_database_query` on db `af975dad-2989-45e3-92c9-03caf55f14e3` (`duff-vault`):
   `SELECT name, value FROM secrets` -> `GITLAB_TOKEN`, `BUTLER_API_KEY`. Never ask Duff to paste keys.
2. Clone: `git clone https://oauth2:$GITLAB_TOKEN@gitlab.com/dufftkyosht-group/duffquest.git`, then
   `git remote set-url origin https://gitlab.com/dufftkyosht-group/duffquest.git` (keep the token out of .git/config).
   Push with `git push https://oauth2:$GITLAB_TOKEN@gitlab.com/dufftkyosht-group/duffquest.git HEAD:main`.
3. Ship: `BUTLER_API_KEY=... tools/ship_itch.sh [--web-check]` (installs Godot 4.5 + web templates + butler if missing;
   import, test_daily, smoke, export, secret scan, push to `dufftkyosht/duff-quest:html`). `--no-push` = build only.
4. GitLab token expires **2026-12-08**: remind Duff around Dec 1 to make a new one; update the vault row.

## Where the game is (end of Nov 9)
- itch: https://dufftkyosht.itch.io/duff-quest, channel `html`. Build = latest main (see CLAUDE.md top bullet).
- 17/17 bosses with live knockout cutscenes; in-engine cartoon gore (toggle); 30-day soak passes on 6 seeds.
- Gala bosses are **Madison's exes**: Tyler Pivot (id husk), Grant Gratuity (bozos), Landlord Lance (fences),
  Chip Leverage (donald, final). Baron stays host. Gala unlocks **story day 24** (`GALA_DAY`, main.gd).
- HUD: one top strip + Tab/tap drawer. Settings: music/sfx, mute, clean language, cartoon gore, screen shake, graphics Full/Lite.
- Web build 56 MB (38 MB is the stock engine wasm). Auto Lite graphics on slow phones.
- **House art style = C** (locked). Canonical Duff = `docs/art_direction/duff_face_sheet.png` (Canva `MAHacL92VLk`),
  first ref for every Duff image. No images outside STYLE_LOCK.md.

## Decisions Duff made Nov 9
- Real names (Madison, Octavia, Jen, Brittany) are fine on itch.
- Style C. Gala on day 24. Billionaire parodies -> Madison's exes (old set kept in `docs/dlc_concepts/billionaires/`).
- Jams: itch "2026 Jam" bans AI art -> out. Seasonal RPG Game Jam host (Mihaela Erceg / artistotel, illustrator; her
  own site says "There was no AI involved in this, don't worry") -> recommended skip; no email exists (contact form only).
  Ranked AI-friendly options in tasks/todo.md (AI Browser Game Jam #6 in Dec if posted; Slapjam #3 Nov 28-30 needs a new
  portrait game; free listings: 5 Year Long Jam, The Best Game of the Year).

## ITCH PAGE: one manual fix Duff must do (blocks everyone from seeing new builds)
The game page embeds upload **20348255 `duffquest-web.zip`** (manual upload, Nov 7 = OLD build). Every butler push goes
to upload **20362247 `duff-quest-html.zip`** (channel `html`), which only shows in the download list. Only the itch
dashboard can switch it: Edit game -> Uploads -> delete `duffquest-web.zip` (or untick "played in browser") and tick
"This file will be played in the browser" on `duff-quest-html.zip`; Embed: 1280x720, Mobile friendly (landscape),
Fullscreen button. Verify: page HTML iframe should point at `html-classic.itch.zone/html/20362247/`
(firecrawl_scrape the page, rawHtml). Claude in Chrome can't run from Duff's phone. Page copy ready: `docs/itch/PAGE.md`;
logo/banner/icon: `docs/itch/logo*.png`, `icon_512.png` (`tools/make_logo.py`), cover `docs/itch/cover.png`.

## NEXT (in order)
1. ~~Style C conversion~~ DONE Nov 9: all 6 Duff KO frames, 13 loading screens, 51 boss KO stills (grades:
   `docs/reviews/style_c_convert.md`; old art in `grok_art/2026-11-09-style-c-convert/old/`). Optional: reframe
   `willnot_b` (jaw cut off by the x-ray crop) and `dasher_b`, or loosen the engine's x-ray crop. `data/loading_screens.json`
   lists `cat_sacrifice.jpg`, which doesn't exist (pre-existing).
2. Gala exes' in-world sprite sheets `assets/art/characters/ch_{husk,bozos,fences,donald}` still show the OLD faces.
3. Balance (needs Duff's call): happiness gates block 4/5 story bosses for players who skip the evening shower + couch.
4. Itch page: upload `docs/itch/` screenshots/cover/GIF and paste `docs/itch/PAGE.md` (Duff, on phone) — fix its
   [CHECK] items first (real names now OK; parody bosses gone; jam text out of date).
5. First boot on 4G ~60 s: check whether itch serves `index.wasm` compressed.
6. M7 backgrounds (16 left) — now in style C via Canva, not Place/Gemini.

## Canva
Scratch design `DAHacBeu8SQ` is at 91 pages: START A NEW ONE. Canonical Duff face `MAHacL92VLk`. Face sheets on white
(refs for every character) + style refs are listed in `docs/reviews/style_c_convert.md` / CLAUDE_REFERENCE.md.
Canva paints the fox on Duff's RIGHT neck whenever his head turns to the viewer's right: one edit fixes it
("remove the neck tattoo, plain skin"). Ask for an EMPTY holster on Willnot or it draws guns.

## Gotchas learned today
- `test_daily` prints ALL PASS even when a script fails to compile -> always grep SCRIPT ERROR (ship script does).
- After merging new art, `touch` the image files before `godot --import`, or the tracked `.godot` cache keeps old art.
- Untracked `*.gd.uid` files (from imports) silently block `git merge` -> remove them and check merge's exit code.
- `.godot/editor/` is untracked now; `.godot/imported` + `uid_cache.bin` are still tracked (merge noise: take either side, reimport).
- Parallel agents: give each its own git worktree AND its own `XDG_DATA_HOME=/tmp/xdg_<name>` (with
  `godot/export_templates` symlinked to `/root/.local/share/godot/export_templates`), or they share user:// saves.
- Only ONE agent may use Canva at a time. Canva puts Duff's blackout sleeve on the wrong arm when he's chest-on: mirror + targeted edit.
- `rm tools/*.gd.uid` deletes TRACKED uid files too; only remove untracked ones (`git ls-files --others`).
- The 5-hour usage limit hit at ~8:25 with 8 agents running; agents resume with SendMessage after the reset.
