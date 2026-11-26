# Building the 3D DuffQuest: guide for the next coder

**Picking up the build? Start with `HANDOFF.md` in this folder (current state, open PR, next steps).**

Read this before changing `spike_full3d/`. It covers how the slice is wired, how to add a foe, a move or a
zone, what must pass before a push, and the rules that came from real mistakes. The phase plan and the
credit budget live in the full 3D plan doc. The short version is at the bottom of this file.

## What this is

`spike_full3d/` is a standalone Godot 4.7.2 project: one porch, Duff vs the Porch Pirate, then Marketplace
Mike, then Sir Sends-It-Back. It is the seed of the full 3D game, which replaces the 2D game zone by zone. The 2D game at the repo
root stays live on itch until the 3D game covers everything it does. Don't touch the 2D game from here.

- Renderer: Compatibility (`gl_compatibility`, also on mobile). Physics: Jolt.
- 960x540 landscape viewport, stretch "expand" (fills any phone shape). Phone is the target; the APK `duffquest-porch3d.apk` ships on the `dev` release
  from every push to main (`.github/workflows/build.yml`, its own package id, the shared keystone key).
- GDScript only. The owner works from a phone: no desktop-only steps in any workflow.

## Files

| File | Job |
|---|---|
| `fight_core.gd` | The fight engine: every tuning constant, shared state, Duff's moves, hits, meter, Red Right Hand, Return to Sender, teach-by-doing (`teach()`/`_learn()`). Hooks a scene fills in at the bottom (`_say`, `_update_hud`, `_foe_down`, `_send_parcel_home`) |
| `porch.gd` | The porch scene, `extends "fight_core.gd"`: set, HUD and thumb buttons, input loop, bubbles, grade, win/lose, zones and walking home |
| `foe_data.gd` | Every foe as data: HP, speed, reach, jab, throw (one prop or a fan), charge, rage, shield, armour, lines. A new foe is an entry here |
| `foe_brain.gd` | The one AI that runs any `foe_data.gd` entry (walk in, red-ring jab, alternate throw / charge, rage, shield only specials break). Made by `porch.gd`, ticked from its physics loop, `game` = porch.gd's shared services |
| `porch_hud.gd` | HUD strip, buttons, meter ring, callouts, title / pause / settings / KO / win cards |
| `porch_feel.gd` | Hit-stop, shake, knockback, sound pool, music |
| `porch_camera.gd` | Low brawler camera that frames Duff and the current foe |
| `porch_look.gd` | Golden-hour look, clock-driven light (`daylight()`), LITE mode (perf guard) |
| `porch_daylight.gd` | Light keys for every time of day; the HUD clock drives them |
| `porch_zones.gd` | Zone loader: one root per place, doors, fade card, `--zone=` |
| `zone_apartment.gd` | Duff's apartment, built free; `spots` for people at home |
| `porch_art.gd`, `porch_kit.gd` | The set: Meshy hero props placed on the old layout, free walls/floors/textures |
| `rig_actor.gd` | Loads `models/<who>.glb` + `models/<who>_clips.res`, picks idle/walk/run by speed, `strike()` one-shots, head-size fit |
| `smoke.gd` | The test: 100+ PASS lines driving real game code. CI fails on any FAIL |
| `tools/` | Clip bakers, render/GIF shots, the play bot, art helpers (each file's header says how to run it) |

## How a fight works

- `_physics_process` ticks Duff, then the current foe (`_now()`: the first one in the zone's `FIGHTS` order
  who isn't down), then every foe's thrown props. Each foe body carries its brain (`_brain(body)`).
- Who you fight and when they come in: `porch_zones.gd` `FIGHTS` (`"start"`, `"parcel"`, or seconds after
  the one before drops). Whoever holds the parcel drops it on KO; the last KO wins the zone.
- A new foe: an entry in `foe_data.gd` (copy the closest one), a line in a zone's `FIGHTS`, and a model
  (below). Only a new kind of move needs code in `foe_brain.gd`.
- A foe's attack is always: red ring (`_tell`) + wind-up clip, then the hit lands unless Duff rolled.
  Unreadable damage is a bug.
- `_damage(foe, amount, stun)` is the single entry for hurting a foe; `_hurt_duff(from)` for Duff.
- Guard: foes block a mashed flurry (`chain`). Specials go through any guard.
- Meter: +14 per landed hit, +10 per hit taken. Full meter + R = Red Right Hand (dash), or Return to
  Sender (grab/throw) when the foe is within `RTS_RANGE`.
- All tuning lives in named constants at the top of `fight_core.gd`. Change numbers there, never inline.

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
- Lighting follows the game clock (`porch_daylight.gd`). Golden hour stays the signature look.
- A new zone: a `zone_<name>.gd` with `static func build(zones, root)` that adds its set under `root`,
  colliders via `game._collider(..., root)`, lamps in group `zone_lamp` (meta `base_energy`), windows in
  `zone_window`, doors into `zones.doors`, and named `zones.spots`. Add it to `ZONES` in `porch_zones.gd`.
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

## Refactor (done; how the code is split)

Step 1 is done (Nov 25): the foes moved out of `porch.gd`; it keeps their old variable names as
getters/setters so tests and tools didn't change. Next, before more foes:
1. Done (Nov 26): `fight_core.gd` holds the fight; `porch.gd` extends it. A new fight scene (the kitchen) extends
   `fight_core.gd` the same way and fills in the hooks.
2. Done (Nov 26): `foe_brain.gd` runs every foe from `foe_data.gd` (the three porch foes were three copies of
   one fight). For the kitchen bosses, start each entry from the main game's `scripts/boss.gd` (name, lines).
3. Done (Nov 25-26): `porch_zones.gd` loads one place at a time, owns the camera mode (explore vs brawler)
   and says who you fight there (`FIGHTS`).
Keep `smoke.gd` green through every step. Move code first, then change behaviour in a later PR.

## Phase plan (short)

1. Phone check of the porch APK: the 60 fps gate.
2. 3D core: zone loader, explore + fight camera, clock lighting, data-driven foes (the refactor above).
3. Kitchen slice: one short shift (fryer, sandwich, inspector).
4. Home and the block: apartment, street, Madison and Brittany, a full in-game day.
5. Story: exes, Willnot, the rest of the kitchen.
6. Side content: the remaining bosses, errands, dates. Then the 3D game replaces the 2D one.

## The 8.5 gate (Duff, Nov 26)

Before building the next round, write an "8.5 plan" (what a blind first-time player needs to score it 8.5),
get Duff's OK on one card, build it in one pass, then re-run a blind first-timer review on the web build.
Shared rules from pass 1, for every zone: teach by doing (`foe_data` `teach` + `waits`, one ringed button and
one line per new move), fighters framed left of the thumb buttons (`porch_camera.gd` SHIFT/RIGHT_EDGE),
bubbles left of the buttons, `expand` aspect with right-hand controls sliding to the real edge (`porch_hud.gd`
`spare`). The web shell turns the game sideways in a portrait window, and `_input` backs up the
TouchScreenButtons (they missed touches in the browser).

Pass 1 scored 5/10 with the first-timer (Nov 26: Mike too hard, knocked into the void, HUD over the action).
Pass 1b rules, for every fight: nobody leaves the yard (`fight_core.gd` `_keep_in_yard`, YARD_X/YARD_Z per
fight), Retry starts at the foe you lost to (`checkpoint`), every hit and block pops a number or word
(`_pop`), a strike the planter stops says "IN THE WAY!", Duff gets HURT_GRACE after a hit, counters wind up
COUNTER_TELE, a charge keeps its red ring until it ends, the camera keeps fighters above the bottom quarter
(BOTTOM_EDGE: stick + foe bar), other people's bubbles never sit on Duff, and the title and pause have a
one-screen Controls card.
