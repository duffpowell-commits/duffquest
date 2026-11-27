# 3D DuffQuest: handoff log (for whoever builds next, any coding AI)

Update this file as you go, not just at the end. Newest entry first. How the code is wired:
`BUILDING.md` (same folder). Repo rules: `/CLAUDE.md` (public repo, no secrets or personal info).

## Kitchen visual polish (Nov 27, 2026; visual approval pending)

- Dedicated stacked branch `preview/kitchen-visual-polish` from PR #229 (`167e67e`). Preserves all five station transforms, the original five approved character models/textures/rigs/scales/positions and existing collision state (no collision objects in this visual-only preview). Zero paid assets; no gameplay, 2D, zone registration or publication changes.
- Weathered brushed steel and aged ceramic with compact mipmapped albedo/roughness maps; bevel bands, appliance handles/dials/indicators, hood baffles, improved fryer baskets, utensils, plate stacks, tickets, squeeze bottles, prep ingredients, towels, floor mats, subtle steam and warm task lamps/contact shadows. Static kitchen geometry batched into 25 materials; no new model files.
- Actual Godot 4.7.2 Compatibility paired screenshots and details (elevated and lower views, grill, pass, character), plus lower angle and mobile-safe HUD footprint diagnostics: `docs/renders/porch3d/kitchen-polish/README.md`. All paired camera transforms and idle poses match. Lower whole-room overlaps controls; the pulled-back candidate clears the marked controls at 16:9, at the cost of smaller characters. No live HUD added.
- Cloud llvmpipe, 1280×720, MSAA off, 60 frames: before 15.02 FPS / 66.58 ms / 1,171 draws / 139,552 primitives; after 11.95 FPS / 83.66 ms / 75 draws / 166,132 primitives. Draw calls down 93.6%; software frame time increased. No actual Galaxy S26 Ultra available, so 60 FPS phone target is unverified. Remaining: stylized repetitive wear, primitive food/utensils, subtle steam, shadow/lighting limitations and mobile performance/actual touch validation.
- Verification: preview smoke checks 5 unchanged station transforms, 5 approved idle rigs/positions, zero new collision objects and 25 material batches. Porch smoke 159 PASS, no FAIL or SCRIPT ERROR; root `tools/test.sh` 609 PASS, zero failures (existing shutdown resource warnings). Keep the porch acceptance gate in PR #228: no blind score claimed, no approval inferred and no kitchen gameplay integration/merge before phone acceptance and owner approval.

## Kitchen environment preview (Nov 27, 2026; approval pending)

- Branch `preview/kitchen-environment`: isolated, visual-only cutaway of the kitchen. No gameplay, zone registration, combat, move, animation, model, texture or 2D changes; no asset purchases (0 credits). The existing porch main scene remains the entry point.
- Five marked stations: grill, fryer, sauté, cold prep and pass; brushed/scuffed stainless, checkered floor, warm task lighting and a fixed three-quarter view. Existing `rig_actor.gd` loads the canonical `duff`, `sendback`, `camper`, `coupon`, `allergy` GLBs, embedded textures and idle animation libraries; no modifications to character assets.
- Preview explicitly: `godot --path spike_full3d res://kitchen_preview.tscn`. Render both angles: `xvfb-run -a godot --path spike_full3d --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --script tools/kitchen_preview_shot.gd -- /absolute/path/to/duffquest/docs/renders/porch3d`. The actual captures are `docs/renders/porch3d/kitchen-overview.png` and `kitchen-reverse.png` (1280×720).
- Verification: Godot 4.7.2 import and preview smoke (all five stations and five existing idle rigs); porch smoke 159 PASS, no FAIL or SCRIPT ERROR; root `tools/test.sh` passed (609 PASS, zero failures). Existing smoke shutdown resource warnings do not change the pass result. Renders use desktop software OpenGL, not a phone performance benchmark.
- **Gate remains open:** [PR #228](https://github.com/duffpowell-commits/duffquest/pull/228) requires exact-build human phone acceptance, reliable controls and measured 60 FPS before kitchen expansion. No new blind score, no gate approval inferred, no gameplay integration or merge. Review these renders only; save the 8.5 plan and kitchen gameplay for after the porch gate and owner approval.

## Studio mascot (Duff, Nov 26)
- **The three-eyed fox is in every game as a rare cameo, not a pal**: a small event
  that matters but never ruins a run. Duff OKs the fox art on a card before it's built. Rule + this game's idea: `/docs/MASCOT.md`.

## Newest (Nov 26, 2026, 1:40 PM CT)

- **Name:** Fork Around and Find Out (Duff, Nov 26, PR #222 merged). The title card says it; ids and paths keep `duffquest`.
- **Frying pan:** Duff fights with a cast-iron skillet in his LEFT hand (`porch_art.gd` `skillet()`, built
  free from primitives, 0 Meshy credits; held via `rig_actor.attach("LeftHand")`, `SKILLET_GRIP` in
  `fight_core.gd`). The right hand stays free for the Red Right Hand special. A quiet "bonk" rings under every
  landed punch. It's put away while exploring. Render: `docs/renders/porch3d/skillet.jpg`.

## Where it stands (Nov 26, 2026, 1:40 PM CT)

**Goal (Duff):** remake DuffQuest fully in 3D, zone by zone. `spike_full3d/` is the seed: the porch fight
(Porch Pirate, Marketplace Mike, Sir Sends-It-Back), then the walk home to the apartment.

**Reviews are off (Duff, Nov 26, 7:12 AM CT: "We'll build all of the fixes, cancel the reviews").** Build fixes
and merge on green CI. Don't run the blind first-timer or fresh-eyes reviews unless Duff asks for them.

**Live on main** (every push to main ships it):
- Browser: https://duffpowell-commits.github.io/duffquest/porch3d/ (works on iPhone; drawn sideways in a portrait window).
- APK: `duffquest-porch3d.apk` on the `dev` release.
- Merged: #215 (browser build), #216 (fairer pirate + walking fix), #217 (sideways + browser touch buttons),
  #218 (pass 1 + 1b: teach by doing, fill the phone, `fight_core.gd` split, fair Mike, checkpoint at Mike, no void,
  clear screen, damage numbers, Controls card), #219 (this log).

- #221 (the frying pan, above) merged Nov 26.

**Merged:** #222, the rename to "Fork Around and Find Out" (Duff picked it Nov 26).

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
| Nov 26 | PR 218 pass 1b (`e929b6b`) | not run (Duff waived reviews) | |

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
