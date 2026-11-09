# DuffQuest handoff: Nov 9, 2026, 07:00 CT

Paste this into a new Claude session to pick up the work.

## What this is
DuffQuest is a comedy RPG about Duff's real life in Omaha, built in Godot 4.5 with GDScript and played in
landscape. The repo is the private GitLab project `dufftkyosht-group/duffquest`, remote name `gitlab`. GitHub
`duffpowell-commits` is suspended. Duff works from his phone only.
Read `CLAUDE.md` first, then `QUEUE.md`, `tasks/todo.md` (the JAM PUSH section at the top),
`tasks/lessons.md`, and `docs/art_rules.md`.

## Goal and deadline
The target is the itch.io **"2026 Jam"**. Submissions close **Dec 31, 2026**, and our own deadline is
**Dec 28**. Duff wants two entries if we can manage it: **DuffQuest** and **Chaos Is the Mother of Order**,
which lives in a separate repo and session.
DuffQuest already plays and qualifies. Get a current build onto itch, submit it, and keep updating it.

## Itch (top priority)
- The page is `https://dufftkyosht.itch.io/duff-quest`, with a hyphen. It still runs the pre-Nov 7 build
  (2.3 MB, isometric). Auto-upload died along with GitHub CI.
- The current web build boots cleanly in headless Chromium. Screenshots: `docs/renders/web_boot.png` and
  `web_newgame.png`. Rebuild and upload steps are in `docs/itch_deploy.md`.
- Godot 4.5-stable web templates are installed in the sandbox. Export with:
  `godot --headless --path . --export-release "Web" build/web/index.html`, then zip so `index.html` sits at the root.
- The itch API is reachable from the sandbox (tested). **Ask Duff for a butler API key** from itch.io →
  Settings → API keys, then push with butler: `butler push build/web dufftkyosht/duff-quest:html`.
  Keep the key in a temp env var only; never put it in the repo or `.git/config`. If there's no key,
  send Duff the zip and point him to the phone steps in `docs/itch_deploy.md`.
- Rebuild **after** the art fixes, sprite tattoos and KO sound effects land. The 06:51 zip is stale.

## Duff's look (HARD rules: `docs/art_rules.md` D1-D7, `docs/duff_look.md`)
- Keep him buff.
- **Left arm:** blackout sacred-geometry sleeve that reads as **near-solid black** with thin skin-coloured
  geometry (Duff called out "not black enough"). Back of the left hand: an eye in a ring of triangles.
- **Right arm:** grey-wash horns on the upper arm; a dark creature head with orange eyes on the forearm,
  **NOT a panther**. Back of the right hand: blackletter script.
- **Neck:** fox tattoo on the **left side**, the same side as the sleeve.
- The canonical image is the new `assets/art/portraits_hd/duff.png` (render `docs/renders/duff_portrait_v4.png`).
  The old portrait was mirrored, which is why the fox ended up on the wrong side in many KO and loading images.
- Photos in `docs/ref/duff/` win over the fox art wherever they disagree.
- In Canva prompts, give sides from the VIEWER's view. When Duff faces the camera, his left arm is on the viewer's right.

## Gore
Cartoon gore is OK (rule H2): spit, cartoon blood, teeth, bruises. No dismemberment and no organs.
Canva blocks blood, so never prompt for it. Add it in-engine in `scripts/knockout.gd` instead.
The itch page needs a blood/violence content tag.

## Canva workflow
- Duff is on the Business plan, so the rate limit is higher. If it still cools down, wait and retry.
- **Edit flow:** upload with `create-upload-url` (POST raw bytes), then call `generate-image` with the original image as the FIRST reference.
- **Full-size export:** open a transaction on scratch design `DAHaZZaEJBs` (`read-design open_transaction`),
  add the image with `add_page` + `insert_fill`, `commit`, then `export-design png` and curl the URLs.
- Duff's references already in Canva: front photo `MAHabDL4f8M`, side `MAHabLtLOTk`, eye hand `MAHabBgv_Hk`,
  creature forearm `MAHabP7oeP8`.
- One Canva user at a time: parallel agents collide on the limit.

## Done this session (Nov 9)
- `docs/art_rules.md` rulebook (Duff look, KO x-ray-matches-hit, no leaked faces, parody human faces, style, gore, process).
- 3 review agents graded all HD art and sprites. Results in `docs/reviews/`:
  - `ko_stills.md`: 20 pass, 19 fix.
  - `portraits_cards.md`: 33 of 38 pass.
  - `loading_sprites.md`: 21 old-chibi sprite sheets need redoing.
- Tattoos added to 18 HD images (5 shared Duff KO panels, 6 x-ray stills, 7 loading screens). Duff's portrait redone.
- Docs fixed: the panther line in `duff_look.md`; duck/TV/lightbulb heads marked superseded in `knockout_cutscenes.md`.
- Pushes: `dc217e1`, `351f0a0`, `0be8336`. Tests ALL PASS; smoke test 601 frames.

## In flight when this was written (background agents; check their output before redoing anything)
1. **Canva HD fixer:** working through every FIX/REDO row in `docs/reviews/*.md` and appending a "Fix log".
   Masters go to `grok_art/2026-11-09-fixes/`. Contact sheet: `docs/renders/art_fixes_nov9.jpg`. Uncommitted.
2. **Sprite tattoos:** `tools/tattoo_sprites.py` pixel-recolours the `duff_*` sheets and `ch_duff_suit`.
   Backups in `grok_art/2026-11-09-sprites-backup/`, renders in `docs/renders/sprite_tattoos/`. Uncommitted.
3. **KO sound effects + stat screen overflow:** `tools/make_ko_sfx.py` writes `assets/sfx/ko/`, wired in `scripts/knockout.gd`.
   Stat label fix in `scripts/ui_style.gd`, test in `tools/test_daily.gd`, render `docs/renders/stat_screen_fixed.png`.
   Uncommitted.

When they finish:
- Look at the renders.
- Run `godot --headless --path . --import`, then `godot --headless --path . --script tools/test_daily.gd` (must print ALL PASS), then the smoke test (601 frames).
- Commit and push, rebuild the web build, and push it to itch.

## Next, in order
1. Land the 3 agents' work, then rebuild the build and get it on itch.
2. Itch page: screenshots, GIF, controls, AI disclosure, content tag. Submit to the 2026 Jam.
3. In-engine cartoon blood on KO hits.
4. KO stills for coupon, allergy, camper, bdaydad, dasher and baron.
5. Restyle the 21 old chibi sprite sheets. Clean the green halo off the portraits.
6. Shrink the web build (90 MB zipped).
7. M7 backgrounds (QUEUE), Freya's cat scene, Lucifer recolour.
8. Check on Chaos's jam slice (its own repo and session).

## Commands
- Import: `godot --headless --path . --import` (run after any art swap).
- Tests: `godot --headless --path . --script tools/test_daily.gd` (must print ALL PASS).
- Smoke: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
  (expect 601 frames). Delete `~/.local/share/godot/app_userdata/*/save*.json` before rendering.
- KO beats: `tools/ko_shot.tscn -- <boss>`. Portraits: `python3 tools/import_portrait.py <strip> <name> --cell 512`.
- Push: the GitLab PAT goes ONLY through a temp `/tmp/askpass.sh` (`umask 077`, user `oauth2`), which gets deleted after each push.
  Never write it to `.git/config` or any file. **Duff should revoke and reissue the token: it was pasted in chat.**
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` + the session link.

## House rules
- Be blunt and concise. Light profanity is fine. Push back when there's a better way.
- Push after every chunk of work and merge to main.
- Run the tests before every push.
- Keep `CLAUDE.md` updated at each milestone. Up to 3 milestones per session.
- Save renders to `docs/renders/`; show real engine renders for visual calls.
- Automate everything you can. Duff is phone-only.
- Never put Duff's real name or email in API contact fields.
