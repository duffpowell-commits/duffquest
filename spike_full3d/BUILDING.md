# Building the 3D DuffQuest: guide for the next coder

Read this before changing `spike_full3d/`. It covers how the slice is wired, how to add a foe, a move or a
zone, what must pass before a push, and the rules that came from real mistakes. The phase plan and the
credit budget live in the full 3D plan doc. The short version is at the bottom of this file.

## What this is

`spike_full3d/` is a standalone Godot 4.7.2 project: one porch, Duff vs the Porch Pirate, then Marketplace
Mike, then Sir Sends-It-Back. It is the seed of the full 3D game, which replaces the 2D game zone by zone. The 2D game at the repo
root stays live on itch until the 3D game covers everything it does. Don't touch the 2D game from here.

- Renderer: Compatibility (`gl_compatibility`, also on mobile). Physics: Jolt.
- 1280x720 landscape. Phone is the target; the APK `duffquest-porch3d.apk` ships on the `dev` release
  from every push to main (`.github/workflows/build.yml`, its own package id, the shared keystone key).
- GDScript only. The owner works from a phone: no desktop-only steps in any workflow.

## Files

| File | Job |
|---|---|
| `porch.gd` | The game: input, Duff, combat rules, specials, meter, grade, win/lose (see "Next refactor") |
| `foe_pirate.gd` | The Porch Pirate: approach, jab wind-up, guard, KO drops the parcel. Same pattern as `foe_mike.gd` |
| `foe_sendback.gd` | Sir Sends-It-Back, the third fight: cloche guard only specials break, 1-star card spread, charge |
| `foe_mike.gd` | Marketplace Mike: his state, AI, sign throw and charge. The pattern for every new foe (made by `porch.gd`, ticked from its physics loop, `game` = porch.gd's shared services) |
| `porch_hud.gd` | HUD strip, buttons, meter ring, callouts, title / pause / settings / KO / win cards |
| `porch_feel.gd` | Hit-stop, shake, knockback, sound pool, music |
| `porch_camera.gd` | Low brawler camera that frames Duff and the current foe |
| `porch_look.gd` | Golden-hour lighting, LITE mode (perf guard) |
| `porch_art.gd`, `porch_kit.gd` | The set: Meshy hero props placed on the old layout, free walls/floors/textures |
| `rig_actor.gd` | Loads `models/<who>.glb` + `models/<who>_clips.res`, picks idle/walk/run by speed, `strike()` one-shots, head-size fit |
| `smoke.gd` | The test: 100+ PASS lines driving real game code. CI fails on any FAIL |
| `tools/` | Clip bakers, render/GIF shots, the play bot, art helpers (each file's header says how to run it) |

## How a fight works

- `_physics_process` ticks Duff, then the current foe (`_tick_pirate`, `_tick_mike`, `rival.tick`), then specials.
  A new foe also needs a line in `_hp_of` / `_model_of` / `_height_of` / `_armoured` (bottom of `porch.gd`).
- A foe's attack is always: red ring (`_tell`) + wind-up clip, then the hit lands unless Duff rolled.
  Unreadable damage is a bug.
- `_damage(foe, amount, stun)` is the single entry for hurting a foe; `_hurt_duff(from)` for Duff.
- Guard: foes block a mashed flurry (`chain`). Specials go through any guard.
- Meter: +14 per landed hit, +10 per hit taken. Full meter + R = Red Right Hand (dash), or Return to
  Sender (grab/throw) when the foe is within `RTS_RANGE`.
- All tuning lives in named constants at the top of `porch.gd`. Change numbers there, never inline.

## Adding a character (foe or talking NPC)

Budget first: each new body costs about **44 Meshy credits**: an A-pose reference image (9), image-to-3d
12k triangles with a 2K texture (30), and a rig (5). Clips are usually free, because every Meshy rig has
the same 24 bones.

1. **Check what exists first.** Kitchen 4 bodies are already here (`sendback`, `camper`, `coupon`,
   `allergy`). Project files: `meshy-backup/`, `duffquest-3d-slice/meshy_source/`. Reuse or reskin
   (`tools/reskin.py`) before paying.
2. State the credit cost and get the owner's OK for any job over 50 credits. Keep a 100-credit reserve.
3. Make the body from the character's existing sprite + portrait, with Mike's reference as the style
   anchor. Record every Meshy task id the moment it exists (README "Meshy record" table, and the
   project-files `meshy-backup/IDS.md`). Meshy can't list old rigs.
4. Add its crown-to-chin to `rig_actor.gd` `HEAD` so its head matches Duff's (owner's rule).
5. `tools/share_clips.gd` gives it Duff's/Mike's clips (hips scaled per body). New clips: animate on
   Duff's rig (`01a2139a-2c8e-704b-b2e6-af6cb09b81f3`, 3 credits each), then bake.
6. Real people (Duff, Madison, Brittany): models come from photos the owner approves, every look shown
   to him before modelling. Their photos never go in this repo.

## Adding a move

- Show the owner a GIF of every new special and every new animation before it ships. He approves one
  step at a time.
- Moves are original. A request phrased like another game's move ("like X's Y") means its feel. Don't copy
  its name, look or inputs.
- Bake new clips with a `tools/bake_*.gd` (examples: `bake_burn.gd` coils a jab, `bake_toss.gd` cuts
  and turns a throw, `bake_victim.gd` shares a victim clip to every foe).
- Every move gets smoke checks: it lands, it whiffs, it can't be cancelled where it shouldn't, and the
  fight ending mid-move leaves no state behind (collision, rotation, `Engine.time_scale`, locks).

## Adding a zone (next phases)

- Zones load one at a time behind a loading card. Keep about 6 animated people on screen at most.
- Build walls, floors and small props free (Godot shapes + seamless textures, `porch_kit.gd` pattern).
  Meshy only for 1-2 hero props a location (60-90 credits).
- Lighting follows the game clock. Golden hour stays the signature look.
- Web: anything a zone needs loads when you walk in, not up front.

## Before every push

```sh
godot --headless --path spike_full3d --import
godot --headless --path spike_full3d --script smoke.gd      # PASS lines only, no FAIL / SCRIPT ERROR
tools/test.sh                                                # repo-wide; prints TESTS PASS
git checkout -- .godot/exported
```

Visual changes also need a real engine render saved in `docs/renders/porch3d/`
(`xvfb-run -a godot --path spike_full3d --rendering-driver opengl3 --resolution 1280x720 --script tools/<shot>.gd -- <outdir>`).

## Rules that came from mistakes

- Godot 4.7.x only. Never downgrade.
- In `spike_full3d/`: no `class_name`, no `preload("res://...")` of main-project scripts (it's a separate project).
- Public repo: no secrets, keys, tokens or `.env`. No family photos, no private chat logs. Real names only
  through the main game's `data/cast.json` tokens.
- One signing key (the keystone) for this game. Never make another.
- Never push straight to main, never force-push. Work on a branch, open a PR, and pass the fresh-eyes
  review (`docs/FRESH_EYES.md`) on the head commit before merging. Rule files are locked (`rule-lock`):
  only the owner unlocks them.
- 60 fps on the owner's phone is the bar. The FPS readout is top right; LITE shows when the perf guard
  stepped down. Nothing scales up until the phone holds 60.
- Credits screens name no AI tools.

## Next refactor (do this before adding a third zone)

Step 1 is done (Nov 25): Mike moved to `foe_mike.gd`, the pirate to `foe_pirate.gd`; `porch.gd` keeps their old variable names as
getters/setters so tests and tools didn't change. Next, before more foes:
1. `fight_core.gd`: Duff's moves, meter, specials, `_damage`/`_hurt_duff`, grade.
2. `foe_brain.gd`: one AI driven by data (HP, attacks with wind-up/damage/range, armour, taunts). Read the
   main game's `scripts/boss.gd` data so the 17 bosses don't get re-written by hand.
3. `zone.gd`: loads a set + its foes, owns the camera mode (explore vs brawler).
Keep `smoke.gd` green through every step. Move code first, then change behaviour in a later PR.

## Phase plan (short)

1. Phone check of the porch APK: the 60 fps gate.
2. 3D core: zone loader, explore + fight camera, clock lighting, data-driven foes (the refactor above).
3. Kitchen slice: one short shift (fryer, sandwich, inspector).
4. Home and the block: apartment, street, Madison and Brittany, a full in-game day.
5. Story: exes, Willnot, the rest of the kitchen.
6. Side content: the remaining bosses, errands, dates. Then the 3D game replaces the 2D one.
