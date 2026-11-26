# Handoff for ChatGPT (or any AI picking this repo up cold)

Written Nov 26, 2026. This is a project handoff, not a prompt. If anything here disagrees with `CLAUDE.md`
(house rules) or `STATUS.md` (current state), those two win. Check the dates.

## 1. What the game is

**Fork Around and Find Out** (it was called Duff Quest until Nov 26, 2026) is a comedy action game made by
3 Eyed Fox Studios. You play Duff, a line cook in Omaha. You have to pay the rent, work your shifts, keep things
good at home, and beat up porch pirates, bad customers and exes with a cast-iron skillet. The tone is
EarthBound-style satire. Fights feel like the GBA Dragon Ball Z games: combos, specials, big knockouts.

There are two builds in this repo:
- **2D game** (repo root): the full game. It's live on itch and at https://duffpowell-commits.github.io/duffquest/.
- **3D remake** (`spike_full3d/`, a separate Godot project): **this is the current work.** It covers the porch fight
  (Porch Pirate, Marketplace Mike, Sir Sends-It-Back) and the walk home. Try it in a browser at
  https://duffpowell-commits.github.io/duffquest/porch3d/. The plan is to remake the whole game in 3D, one zone
  at a time.

## 2. The rename: what changed and what didn't

Duff picked the name on Nov 26, 2026 (PR #222, merged).
- **Changed:** the title shown to players (title menu, credits, ending, app name, itch copy, the 3D title card).
  It comes from `game_title` in `data/cast.json` and `data/cast_public.json`. Under a phone home-screen icon the
  label is the short **"Fork Around"**.
- **Left alone on purpose:** the GitHub repo name `duffquest`, the Android package id
  `com.duffpowell.duffquest`, the itch slug, save keys and file names like `duffquest-public.apk`.
  Renaming any of these breaks installs, saves, links or the itch upload. Players never see them.
- **The pun is deliberate, and Duff approved it.** The real restaurant must still never be named or shown
  anywhere public. The public edition calls it "The Busted Spatula". A test in `tools/test_daily.gd` guards this.
- Logo and cover art may still say "Duff Quest". New covers are a separate job.

## 3. Stack

- Godot **4.7.2-stable**, GDScript only. No C#, no plugins that need a desktop.
- The 2D game runs at a 640x360 viewport. The 3D project uses a 960x540 landscape viewport (stretch "expand"), the Compatibility renderer and Jolt physics.
- Phones are the target platform (Android APK plus the web build on iPhone).
- CI is GitHub Actions (`.github/workflows/build.yml`). Every push to `main` tests, exports web + APK, updates
  the `dev` release and the github.io pages, and uploads the web build to itch with butler.

## 4. Build and test

Duff works **only from his phone**. Never give him desktop steps. Anything that needs a computer runs in CI
or in a cloud coding session.
- Install Godot 4.7.2 Linux to `/usr/local/bin/godot`, then run `godot --headless --path . --import`.
- 2D tests: `tools/test.sh`. It must print `ALL PASS (0 failed)` and no `SCRIPT ERROR`. Afterwards run
  `git checkout -- .godot/exported`.
- 3D smoke test: `godot --headless --path spike_full3d --script smoke.gd`. Every line must be PASS.
- Screenshots for any visual change: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- title`.
  Save them in `docs/renders/`.

## 5. Rules you must follow (the full list is in `CLAUDE.md`)

- **The repo is public.** Never commit secrets, keys, passwords, AI prompts or persona text, private chat
  logs, or personal or family info. Duff adds secrets himself, as GitHub Actions secrets.
- **Real names and brands** only go through tokens in `data/cast.json` (for example `{fork_nick}`), with public
  versions in `data/cast_public.json`. Never put a bare real brand in a string. The tests check for this.
- **Lines about Duff's partner:** Duff approves every one before it ships.
- **Duff's tattoos:** copy the reference images in `docs/ref/duff/`. Never invent them.
- **Credits never name AI tools.**
- **One signing key for everything** (the "keystone"). Never generate a new key.
- **Flow:** branch, then PR, then green CI, then merge. No force pushes and no direct pushes to `main`. A red CI run means nothing ships.
- **Rule lock:** a PR that changes the rules (`CLAUDE.md` rule sections, `.claude/`, `standards/` and similar)
  stays blocked until Duff adds the `duff-ok` label himself. Never add that label or work around it.
- Run `git fetch` before you start and before you push. Bots also commit to `main`.

## 6. Where things stand (Nov 26, 2026)

- `main` is green and live. PR #222 (the rename) has merged.
- 3D remake: the porch fight and walk home are done. Duff fights with a skillet in his left hand, which keeps
  his right hand free for the Red Right Hand special. It's waiting on Duff's phone check.
- Promo and marketing run outside this repo. 3 Eyed Fox Studios posts to TikTok and YouTube.

## 7. Next steps, in order

1. Get Duff's phone-test notes on the 3D porch and fix what he finds.
2. 3D pass 2, the kitchen shift. Before building it, write a short "what a first-time player needs for 8.5/10"
   list and get Duff's OK. Also state a Meshy (3D model) credit budget up front. Any single job over 50
   credits needs his yes.
3. Studio mascot: a rare three-eyed fox cameo (`docs/MASCOT.md`). Duff approves the fox art first.
4. Itch page: the description source is `docs/itch/page.html`. Duff pastes it in himself.

## 8. Where to read next

`CLAUDE.md`, then `STATUS.md`, then `spike_full3d/HANDOFF.md` (3D state), then `spike_full3d/BUILDING.md`
(how the 3D code is wired), then `TRACKER.md` and `reference.md` (2D systems).
