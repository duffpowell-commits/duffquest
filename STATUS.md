# Duff Quest status

Short page. Read this first. Details live in `TRACKER.md` and `reference.md`.

## Live
- `main` ships on every green push: parse, `test_daily`, smoke, web export, debug APK, the `dev` release, and itch (`dufftkyosht/duff-quest:html`).
- Web: itch, and the home-screen build at https://duffpowell-commits.github.io/duffquest/ (family copy at `/family/`).
- APKs on the `dev` release: `duffquest-public.apk` (itch edition) and `duffquest.apk` (family edition, never posted in public).
- Eleven side quests. IGN review v7: game 8.9/10, launch 3/10 (`docs/reviews/ign_review_2026-11-19_v7.md`).

## In progress
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
