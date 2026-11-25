# Duff Quest — handoff (read this first)

Comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent, work the line at the Twisted Fork,
fight exes and porch pirates. Godot 4.7.2, GDScript, 640×360 viewport (1280×720 window), 3D view by default. Owner: Duff.

**Read order:** this file -> `STATUS.md` -> `TRACKER.md` (Built / Next / Could improve) -> `reference.md` (how every system works).
**Every system's details, re-import steps and gotchas: `docs/HANDOFF_LOG.md`** (moved out of this file Nov 21 to keep
it short). Search it before touching a system. Also `QUEUE.md`.

## Public repo rules
This repo is public.
- Never commit secrets, passwords, keys, tokens, keystore passphrases, or `.env` files. Secrets go only in GitHub Actions secrets added by Duff.
- Never commit AI prompts, bot instructions, persona text, or private chat handoffs.
- Never commit personal or family info.
- Never copy code, data, signals, or results from swinglifeaway or other private trading repos.
- Game art, code, and design docs are fine.

## Where things stand (Nov 21)
- Nov 24: fully 3D porch slice in `spike_full3d/` (own Godot project + APK `duffquest-porch3d.apk` on the
  `dev` release): Meshy models of Duff and the Porch Pirate on a real skeleton with real clips, Duff's real
  hand tattoos painted from the masters. Marketplace Mike (OBO sign throw, charge, rage) follows the pirate (Nov 24).
  Nov 25: hits land (hit-stop, shake, knockback, sound, music), real fight (red-ring wind-ups, guard + counter,
  Mike's shove), phone controls (4.7 VirtualJoystick, big HIT/DODGE, speech bubbles). Waits on Duff's phone check. README there.
- The approved 3 Eyed Fox Studios publisher card appears before the title. Settings, ending credits, and itch copy credit the studio.
- This repo is public. Secrets, prompts, private handoffs, and personal details stay out. See Public repo rules.
- main is green and live. Every push to main ships: CI parses, runs test_daily + smoke, exports web + APK, refreshes
  the `dev` release and pushes the web build to itch (`dufftkyosht/duff-quest:html`). Red CI = nothing ships.
- Web: itch + PWA at https://duffpowell-commits.github.io/duffquest/ (family copy at `/family/`). APKs: `dev` release
  (`duffquest-public.apk` = itch edition, `duffquest.apk` = family edition with real names, never public).
- IGN review v7: game 8.9/10, launch 3/10 (`docs/reviews/ign_review_2026-11-19_v7.md`). Eleven side quests live.

## Next (in order)
1. **Ask Duff for his and Brittany's playtest notes first** (iPhone + Android). They outrank the rest.
2. Visual plan (Nov 17) needs Duff's phone test, mainly tilt-shift cost (perf_guard Lite turns it off).
3. Itch page: source `docs/itch/page.html`; Duff pastes it from https://duffpowell-commits.github.io/duffquest/itch/.
   The itch page bot stays off (Cloudflare bot check; we don't get around bot checks).
4. Balance re-check after the playtest (gates 45-65, wait drain floor 40).
5. In-app updater: port godot-game-starter's (gap report `/mnt/project-files/game-starter/gap_report_2026-11-19.md`).

## Hard rules (Duff's; each one exists because it went wrong before)
- **Partner lines:** Duff approves every line about his partner before it ships, one pitch at a time. No partner lines on fail screens.
- **Duff's hands:** copy the masters in `docs/ref/duff/hand_*.png`, never invent. LEFT = eye mandala, NO RING; RIGHT =
  red calligraphy "This Red Right Hand Points Me South". New Duff sheet: `tools/hand_tattoos/stamp.py` then `atlas.py`.
  Fox neck tattoo master: `docs/ref/duff/duff_fox_neck_tattoo.png` (`docs/duff_look.md`).
- **Editions:** real names/brands only via `data/cast.json` tokens (`{coworker}`, `{fork_nick}`, `{chad}`...), public
  names in `cast_public.json`; never a bare "Fork" or real brand in a string (test_daily fails). `#dq=` links only in
  the family copy / debug builds. New real person or brand: cast.json + cast_public.json + a test_daily leak word.
- Credits name no AI tools (Duff's call). Keep Settings > Credits & legal, `docs/itch/PAGE.md` and end credits in sync.
- Text over painted art goes through `UiStyle.tag()`. Buttons use the three roles (MAIN teal, ALT plum, EXIT red).
  Touch buttons keep >= 8 units clear (test_daily checks). No small explanatory text on play screens.
- Web: anything new under `assets/` that the title doesn't need goes in the Web preset `exclude_filter` + the right pack
  list in `tools/make_extra_pack.gd`. Audio buses only in `default_bus_layout.tres`. Outside `scripts/view3d/` keep to
  2D nodes. New big sprite sheets import lossy 0.8.
- **Signing:** the keystone (one key for every game but Lethemoor). Never generate another key.
- Phone-only Duff: GDScript only, no desktop steps. No keys or tokens in the repo, logs or chat; Duff sets secrets.
- `git fetch` before starting and before pushing (bots commit to main and `stats`). Netlify credits are spent;
  builds go out via the `dev` release and itch.
- One session per repo. Push after every chunk; merge to main after every milestone (up to three per session;
  no work left on a branch);
  update this file + `TRACKER.md` after each. Real engine renders for visual calls, saved in `docs/renders/`.

## Guards (enforced)
- `.claude/hooks/guard.py` blocks force push, direct push to main, pushing code the tests didn't pass on, writing or
  generating signing keys and committing secret files (.env, keystores, secrets.*; names only, not contents). Run `tools/test.sh` before a push.
- PRs: the `fresh-eyes` status stays pending until a fresh-context review posts `FRESH-EYES REVIEW: PASS` on the head
  commit (`docs/FRESH_EYES.md`). Pending is not green: sessions check the combined status and don't merge
  (GitHub itself doesn't block it).
- Rule lock (Nov 24, 2026, from godot-game-starter): a PR that changes the rules (this file's rules, AGENTS.md, `standards/`, `.claude/`, `.githooks/`, `fresh_eyes.yml`, `rule_lock.yml`; list in `tools/rule_lock.py`) gets a failing `rule-lock` status until Duff adds the `duff-ok` label. **Agents never add, ask a tool to add, or work around that label.** Put rule changes in their own PR and tell Duff it needs his tap. Self-test `tools/test_rule_lock.sh`.

## Commands (cloud sandbox; the rest are in docs/HANDOFF_LOG.md)
- Godot: 4.7.2-stable Linux zip from GitHub releases -> `/usr/local/bin/godot`. Fresh clone: `godot --headless --path . --import`.
- Tests: `tools/test.sh` (test_daily; must print `ALL PASS (0 failed)` with no `SCRIPT ERROR`), then
  `git checkout -- .godot/exported`.
- Stale imports: changed `.import` params don't re-import on their own. `rm .godot/editor/filesystem_cache10`, delete
  `.godot/imported/<file>-*`, `--import`, commit the new `.godot/imported` files.
- Renders: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- <id>` -> `/tmp/qa/`.
- CI: `gh api repos/duffpowell-commits/duffquest/actions/runs?per_page=5` (gh GraphQL and the secrets API are blocked).

## Layout
- `game.tscn`/`main.tscn` -> `scripts/main.gd` (overworld, menus, dialogue, arenas; the biggest file).
- `scripts/minigames/`, `scripts/waffle.gd`, `scripts/boss.gd`, `scripts/daily.gd`, `scripts/view3d/` (3D view).
- `data/cast.json` every real/parody name (`{key}` tokens). `scripts/art_manifest.gd` sprite/backdrop map.
- `tools/` tests, soak, render shots, art importers. `docs/renders/` renders. `docs/reviews/` reviews.
