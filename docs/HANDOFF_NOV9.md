# DuffQuest handoff, Nov 9 2026, 07:30 CT

Paste this into a new Claude session to pick up the work.

## What this is
DuffQuest is a comedy RPG about Duff's real life in Omaha, built in Godot 4.5 with GDScript and played in landscape.
- **Repo:** private GitLab `dufftkyosht-group/duffquest`, remote name `gitlab`. The GitHub account `duffpowell-commits` is suspended.
- **Duff works phone-only.**
- **Read first:** `CLAUDE.md`, `QUEUE.md`, the JAM PUSH section at the top of `tasks/todo.md`, `tasks/lessons.md`, and `docs/art_rules.md`.

## Status right now
- **The itch page is current:** `https://dufftkyosht.itch.io/duff-quest` (with the hyphen), channel `html`, build `7cd1f78`.
  It includes Duff's tattoos, the art-review fixes, the knockout sound effects and the stat-screen fix. It boots in headless Chromium with no errors (`docs/renders/web_boot.png`).
- **Checks on `main`:** `test_daily` ALL PASS (48 checks), smoke test 601 frames.
- **Jam:** itch "2026 Jam". Submissions close Dec 31; our deadline is Dec 28.
  Duff wants two entries if we can manage it: DuffQuest, plus Chaos Is the Mother of Order (a separate repo and session).

## WARNING: two sessions touched this repo on Nov 9
Session `session_01V3sbxP3j4WYR7ytqqi2uUE` pushed itch build `d49898c` (commit `357f489`) while this session was working.
The house rule is one Claude session per repo. Always run `git fetch` before starting and before pushing.

## Secrets
- `.env` in the repo root holds `BUTLER_API_KEY` (itch) and `GITLAB_TOKEN`. It is gitignored and excluded from exports, and it lives only in that sandbox.
- A fresh clone won't have it. Ask Duff to paste the keys again and recreate `.env` with `umask 077`.
- Load it with: `set -a; . ./.env; set +a`.
- **Duff should revoke and reissue the GitLab token.** It was pasted in chat.
- **Push to GitLab:** temp `/tmp/askpass.sh` (user `oauth2`, prints `$GITLAB_TOKEN`), then `git push gitlab main`, then delete the script. Never put the token in `.git/config`.
- **Push to itch:**
  - butler binary from `https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default`.
  - Command: `butler push build/web dufftkyosht/duff-quest:html --userversion <sha>`.
  - Check: `butler status dufftkyosht/duff-quest`.

## Build the web version
```
godot --headless --path . --import
rm -rf build/web && mkdir -p build/web && touch build/.gdignore
godot --headless --path . --export-release "Web" build/web/index.html   # ~113 MB
```
- **Export templates:** Godot 4.5-stable web templates (official GitHub releases, reachable from the sandbox).
- **Boot test:** serve `build/web` over http, open it in headless Chromium (Playwright, swiftshader), wait 25 s, take a screenshot, check the console.
- **Fallback upload from a phone:** see `docs/itch_deploy.md`.

## Duff's look (HARD: `docs/art_rules.md` D1-D7 + R7, `docs/duff_look.md`)
- **Build:** buff.
- **Left arm:** blackout sleeve that reads as **near-solid black**, with thin skin-coloured geometry. Back of the left hand: an eye in a ring of triangles.
- **Right arm:** grey-wash horns on the upper arm; a dark creature head with orange eyes on the forearm (**NOT a panther, NOT a cat**). Back of the right hand: blackletter script.
- **Neck:** fox on the **left side**, the same side as the sleeve.
- **Canonical image:** `assets/art/portraits_hd/duff.png`.
- **Sides:**
  - Facing the camera, his left arm is on the viewer's right.
  - Side sprites: facing screen-right shows his RIGHT side; facing screen-left shows his LEFT (sleeve and fox).
- **Gore (H2):** cartoon gore is OK (spit, blood, teeth), done in-engine. Canva blocks blood, so never prompt for it.

## Canva
- Duff is on the Business plan. **The scratch design is now `DAHabf2Qa9U`**; the old `DAHaZZaEJBs` hit the 100-page limit.
- **Edit:** `create-upload-url` (POST raw bytes), then `generate-image` with the original as the FIRST reference.
- **Full size:** open a transaction with `read-design` (`open_transaction`), then `add_page` + `insert_fill`, then `commit`, then `export-design` png, then curl the URLs.
- **Duff's refs already in Canva:** front `MAHabDL4f8M`, side `MAHabLtLOTk`, eye hand `MAHabBgv_Hk`, creature `MAHabP7oeP8`.
- Only one Canva user at a time.

## Done Nov 9 (this session)
- **Art rulebook:** `docs/art_rules.md`.
- **3 review agents:** every HD image and sprite graded. Results and fix logs are in `docs/reviews/`.
- **Art fixes:**
  - 19 KO stills, 18 loading/KO tattoo passes and 11 loading screens fixed.
  - Duff's portrait redone.
  - crypto and fences cards fixed.
  - octavia and bdaydad portraits fixed.
  - Masters in `grok_art/2026-11-09-*`; contact sheet `docs/renders/art_fixes_nov9.jpg`.
- **Duff sprite tattoos** on 15 sheets via `tools/tattoo_sprites.py`. It's a pixel recolor, safe to rerun, working from backups in `grok_art/2026-11-09-sprites-backup/`.
- **Knockout SFX:** 9 procedural sounds (`tools/make_ko_sfx.py`, `assets/sfx/ko/`), wired per beat in `scripts/knockout.gd`. Not yet ear-tested on the phone.
- **Button labels** wrap and shrink to fit (`scripts/ui_style.gd`), which fixes the stat screen.
- **itch:** build rebuilt and pushed. `.env` secrets set up.

## Next, in order
1. **Submit DuffQuest to the 2026 Jam.** Set up the itch page:
   - screenshots and a GIF
   - controls
   - an AI-use disclosure
   - a blood/violence content tag
   - viewport 1280x720, mobile friendly, fullscreen button
2. **Title screen** (`assets/art/bg_title.png`): Duff has bare arms. Tattoo him per D1-D7.
3. **In-engine cartoon blood, spit and teeth** on the KO x-ray and finisher hits (`scripts/knockout.gd`).
4. **KO stills for the last 6 bosses:** coupon, allergy, camper, bdaydad, dasher, baron.
5. **Restyle the 21 old chibi sprite sheets** (`docs/reviews/loading_sprites.md`).
   Also: the green-halo cleanup on portraits, and the K6 issue (batch-2 B stills share a layout).
6. **Shrink the web build** (113 MB, mostly the KO and loading JPGs).
7. **M7 backgrounds** (QUEUE), Freya's cat scene, Lucifer recolor.
8. **Chaos Is the Mother of Order:** check its jam slice in its own session.

## Commands
- **Import after art swaps:** `godot --headless --path . --import`
- **Tests:** `godot --headless --path . --script tools/test_daily.gd` (must be ALL PASS).
- **Smoke:** `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600` (expect 601 frames).
- **Delete the sandbox save first:** `rm -f ~/.local/share/godot/app_userdata/*/*save*.json`. The file is `duffquest_save.json`; `save*.json` misses it.
- **Renders:** `tools/ko_shot.tscn -- <boss>`, `tools/stat_shot.tscn`, `tools/qa_shot.tscn`.
- **Portraits:** `python3 tools/import_portrait.py <strip on magenta> <name> --cell 512`.
- **Commit trailer:** `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` plus the session link.

## House rules
- Be blunt and concise; light profanity is fine. Push back when there's a better way.
- Push after every chunk of work, then merge to main.
- Run the tests before every push.
- Keep `CLAUDE.md` updated each milestone; max 3 milestones per session.
- Save renders to `docs/renders/` and show real engine renders.
- Automate everything you can.
- Never put Duff's real name or email in API contact fields.
