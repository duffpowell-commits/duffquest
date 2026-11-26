# Duff Quest status

Short page. Read this first. Details live in `TRACKER.md` and `reference.md`.

## Live
- `main` ships on every green push: parse, `test_daily`, smoke, web export, debug APK, the `dev` release, and itch (`dufftkyosht/duff-quest:html`).
- Web: itch, and the home-screen build at https://duffpowell-commits.github.io/duffquest/ (family copy at `/family/`).
- APKs on the `dev` release: `duffquest-public.apk` (itch edition) and `duffquest.apk` (family edition, never posted in public).
- Eleven side quests. IGN review v7: game 8.9/10, launch 3/10 (`docs/reviews/ign_review_2026-11-19_v7.md`).

## 3D remake (the current work, Nov 26)
- Goal (Duff): remake the whole game in 3D, zone by zone. Seed: `spike_full3d/` (own Godot project).
- Handoff for any AI: **`spike_full3d/HANDOFF.md`** (state, 8.5 scores, next steps, gotchas). Code map: `spike_full3d/BUILDING.md`.
- Live: browser https://duffpowell-commits.github.io/duffquest/porch3d/ and `duffquest-porch3d.apk` on the `dev` release.
- On main: porch fight (Porch Pirate, Marketplace Mike, Sir Sends-It-Back), walk home, pass 1 + 1b of the 8.5 plan (PR #218), mascot rule (#220), cast-iron skillet in Duff's left hand (#221).
- **Name stays DuffQuest.** "Hand Wash Only" and other new names are brainstorming until Duff confirms one. Open draft #222 ("Fork Around and Find Out" rename) waits on Duff's naming call: don't merge it without his yes.
- Next: Duff's phone check, then pass 2 (kitchen shift) with its own 8.5 plan card and Meshy budget card. Reviews are off unless Duff asks.
- Mascot: rare three-eyed fox cameo, plus one among the overworld animals (`docs/MASCOT.md`).

## In progress (2D game)
- Preparing this repo to stay public: secret scan, private handoffs and image prompts removed from the tree, gitleaks on PRs and main. History rewrite is waiting on Duff. Do not change the GitHub visibility from a session.

## Blockers
- Duff and Brittany's phone playtest notes (iPhone and Android) outrank the rest.
- Tilt-shift cost still needs a phone test (`perf_guard` Lite turns it off).
- The itch page bot stays off (Cloudflare check). Duff pastes `docs/itch/page.html` from https://duffpowell-commits.github.io/duffquest/itch/.

## Next
1. Duff rotates anything listed in the public-repo audit, then approves a `git filter-repo` history rewrite if he wants the old vault notes and handoffs gone.
2. Balance re-check after the playtest (gates 45-65, wait drain floor 40).
3. In-app updater, ported from godot-game-starter.

## Art
Place's DuffQuest art work has moved to the bot Quase (Art Team). This repo keeps game art and design docs, not bot prompts.

## Key paths
- `game.tscn` / `main.tscn` → `scripts/main.gd` (overworld, menus, dialogue, arenas).
- `scripts/minigames/`, `scripts/waffle.gd`, `scripts/boss.gd`, `scripts/daily.gd`, `scripts/view3d/`.
- `data/cast.json` (name tokens) and `data/cast_public.json` (public-edition overrides).
- `scripts/art_manifest.gd` sprite and backdrop map.
- `tools/` tests, soak, renders, art import. `docs/renders/` renders. `docs/reviews/` reviews.
- Signing: `signing/unlock.sh` uses the `KEYSTONE_PASS` Actions secret. Never commit a passphrase or a plain keystore.

## History rewrite
History was rewritten on 2026-11-21. Every clone (Blace, Quase, Claude, the local machine) must re-clone or hard-reset to origin. Old commit ids no longer exist on the remote.
