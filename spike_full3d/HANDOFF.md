# 3D DuffQuest: handoff log (for whoever builds next, any coding AI)

Update this file as you go, not just at the end. Newest entry first. How the code is wired:
`BUILDING.md` (same folder). Repo rules: `/CLAUDE.md` (public repo, no secrets or personal info).

## Studio mascot (Duff, Nov 26)
- **the three-eyed fox is in every game as a rare cameo, not a pal**: a small event
  that matters but never ruins a run. Duff OKs the fox art on a card before it's built. Rule + this game's idea: `docs/MASCOT.md`.

## Where it stands (Nov 26, 2026, 7 AM CT)

**Resumed (Duff, Nov 26, 7:12 AM CT): "We'll build all of the fixes, cancel the reviews."** The blind
first-timer and fresh-eyes reviews for PR 218 are cancelled by Duff, and PR 218 merges once CI's tests are green.
From here, build the fixes reviews have named without re-running the reviews unless Duff asks for one.

**Goal (Duff):** remake DuffQuest fully in 3D, zone by zone. `spike_full3d/` is the seed: the porch fight
(Porch Pirate, Marketplace Mike, Sir Sends-It-Back), then the walk home to the apartment.

**Live on main** (every push to main ships it):
- Browser: https://duffpowell-commits.github.io/duffquest/porch3d/ (works on iPhone; drawn sideways in a portrait window).
- APK: `duffquest-porch3d.apk` on the `dev` release.
- Last merged PRs: #215 (browser build), #216 (fairer pirate fight + walking fix), #217 (sideways in a
  portrait window + thumb buttons work in the browser).
- #218 merged Nov 26 (squash `6976c6f`, live 7:29 AM CT): pass 1 + 1b below. Reviews waived by Duff.

**Open: PR #218**, branch `claude/project-thread-g0ssf3`, head `e929b6b`. CI is green and smoke has 158 PASS. NOT merged:
- Pass 1 (`64e99eb`, `e746e57`) covers:
  - teach by doing: a ringed button plus one line per new move, and the pirate waits for the first punch;
  - fighters framed clear of the thumb buttons;
  - `expand` aspect so the game fills any phone;
  - `fight_core.gd` split out of `porch.gd`.
  - Fresh-eyes PASS was posted on `e746e57`.
- Pass 1b (`e929b6b`) fixes the five things the blind first-timer named (details in BUILDING.md, "8.5 gate").
- **Needs before merge:**
  1. a fresh-eyes review of `e746e57..e929b6b`, posted as a PR review starting `FRESH-EYES REVIEW: PASS <sha>`;
  2. a blind first-timer re-review scoring 8.5/10 or more (see "The 8.5 gate" below).
  - Both were started on Nov 26 and stopped when the Claude usage limit ran out (resets Mon Nov 30, ~4 PM CT).
  - Any coding AI can run them. Fresh-eyes must come from a session that did not write the code.

## The 8.5 gate (Duff's rule, Nov 26)

Before building a round of changes:
- Write the short list of what a blind first-time player needs for the game to score 8.5/10.
- Get Duff's OK on it once.
- Build it in one pass.
- Have a fresh player run the blind review.
- Only at 8.5+ does it merge and move on. Under 8.5: fix what the review names in one pass, then re-review.

Scores so far:

| Date | Build | First-timer score | Main complaints |
|---|---|---|---|
| Nov 26 | PR 218 pass 1 (`64e99eb`) | **5/10** | Mike too hard, losing replays the pirate, knocked into a void, stick/bubbles/boss bar over the action, no hit feedback, R unexplained |
| (next) | PR 218 pass 1b (`e929b6b`) | not run yet | |

How the blind review is run:
- Export the web pack: `godot --headless --path spike_full3d --export-pack Web <dir>/index.pck` into a copy of a web export.
- Serve that folder with `python3 -m http.server`.
- Play it with Playwright (preinstalled), iPhone 13 profile, touch only (CDP `Input.dispatchTouchEvent`).
- The reviewer must not read the source, docs or earlier reviews.
- Report: a score out of 10, what was confusing, bugs, what covered the action, and the top 5 fixes.
- The cloud sandbox renders at about 3-7 fps, so the reviewer reports lag separately from difficulty.

## Next steps, in order

1. Done: PR 218 merged and live (Nov 26).
2. Reviews are off for now (Duff's call). Run one only if Duff asks.
3. Pass 2 = the kitchen shift (four kitchen bosses, PR 202 planned them). Before building it:
   - write its 8.5 plan and get Duff's OK on one card;
   - state a Meshy credit budget first (about 165 credits estimated). Any single job over 50 credits needs Duff's yes, and you must check existing models in project files first.
4. Duff's note for the overworld: hide the studio mascot (the 3 Eyed Fox) among the animals running
   around, like the trash pandas.

## How to build and test

- Godot 4.7.2-stable Linux at `/usr/local/bin/godot`. First time: `godot --headless --path spike_full3d --import`.
- Smoke: `godot --headless --path spike_full3d --script smoke.gd`. Every line must be PASS, with no FAIL and no SCRIPT ERROR.
- Repo gate before any push: `tools/test.sh` must print TESTS PASS, then run `git checkout -- .godot/exported`.
- Commit and push in separate commands. No force push and no direct push to main.

## Gotchas (each one cost a round)

- No `class_name` in `spike_full3d/`: the root project parse-checks it from its own root.
- Headless smoke runs in a 64x64 window: it pins the KEEP aspect and tests `expand` explicitly.
- TouchScreenButtons miss touches in mobile browsers, so `porch.gd` `_input` backs them up. Keep it.
- `learned` (moves taught) is static, so it survives Retry. The checkpoint survives Retry through
  `Engine.set_meta("porch_checkpoint")`, which is cleared after it is read.
- Duff's hand tattoos, the partner lines and real names have hard rules in `/CLAUDE.md`. Read them before touching art or dialogue.
