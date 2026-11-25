# Duff Quest 3D porch encounter

A standalone Godot 4.7.2 vertical slice, fully 3D. Duff and the Porch Pirate are Meshy models on a real
24-bone humanoid skeleton (glTF), driven by real clips: idle, walk, run, jab, hook, dodge, hit and KO
(the pirate has idle, walk, run, jab, hit and KO). The frontage, stoop, fence, yard and planter from the
first pass (`porch_art.gd`) stay on the world collision layer; every fighter uses it to check strike
obstruction. The parcel rides against the pirate's chest until he drops it.

Grab the parcel and **Marketplace Mike** (boss `mike` in `scripts/boss.gd`, 6 HP, easy on purpose) walks
in from the street. Up close he jabs. From range he alternates two specials, each with a wind-up and a
HUD line: posting (throws his OBO sign, dodge through it) and the charge ("Cash only! No lowballers!", a
straight rush; a miss or a fence leaves him dizzy for free hits). At half health he rages (chest-pound
taunt, faster, shorter cooldown). His KO secures the porch. Numbers are the `MIKE_*` / `SIGN_*` /
`CHARGE_*` constants in `porch.gd`.

Nov 24, 2026: the hand-coded block people were replaced with Meshy models (Duff asked for a small, fully 3D
slice to see how it feels). Duff's model comes from his own approved turnaround
(`docs/art/duff-3d-turnaround.png`); the pirate from the approved Porch Pirate render
(`docs/art/3d-character-standard.jpg`), re-posed to an A-pose without the parcel before modelling.

## Play

Phone: Releases -> `dev` -> `duffquest-porch3d.apk` (built on every push to main, own package id so it sits
next to the real game). Desktop: open this folder as a Godot project. Arrows/WASD move, Space hits (jab
then hook), Shift dodges, R retries; the on-screen buttons do the same. Beat the pirate, walk over the
parcel, then beat Marketplace Mike. The top-right counter shows FPS: the bar is 60 on Duff's phone.

## Look: golden hour (Duff's pick, Nov 25 2026)

`porch_look.gd` restyles the scene after it is built: low warm sun with long shadows, cool sky fill,
a brighter porch lamp, glow, a soft vignette, MSAA, a deeper lawn, and fighters that pop (thin ink outline
from `ink_outline.gdshader`, soft warm rim, a contact shadow under the feet). On the phone, if FPS stays
under 50 for 3 s it drops glow and MSAA ("LITE" shows next to the FPS counter). `--lite` starts lite,
`--plain` keeps the old daylight look. Picked from three looks on one frame: `docs/renders/porch3d/look_compare.jpg`.
Don't use `Environment.adjustment_*` here: in Compatibility it washes the whole frame milky.

## Camera: fight camera (Nov 25 2026)

`porch_camera.gd` frames Duff and the foe he is fighting (pirate, then Mike) and pulls back as they
separate, smoothed. Default `low` = low beat-'em-up angle with the house as the backdrop; `frame` = higher
tilted view; `close` = the old top-down orthographic view, closer. Change `MODE` there or pass `--cam=<mode>`.
Options compared in `docs/renders/porch3d/camera_compare.jpg` (`tools/cam_shots.gd`).

## Reskins: new characters for 0 credits (Nov 25 2026)

`tools/reskin.py <body.glb> <body texture> <recipe> <out.jpg>` repaints a rigged body's texture by body region
and colour class, keeping the shading; `tools/reskin_shot.gd` renders base and reskin side by side. First test:
Mike's body as Sir Sends-It-Back (`tools/reskins/sendback_Image_0.jpg`, `docs/renders/porch3d/reskin_sendback.png`).
Same body shape, so it suits minor bosses; story bosses stay custom. Free Meshy community bodies + a 5-credit rig
+ the shared clips are the other cheap route (pick list: project files `meshy-backup/community_picks.md`).

## Kitchen 4: own bodies, shared clips (Nov 25 2026)

Sir Sends-It-Back, the Four-Hour Camper, Coupon Carol and the Allergy Liar each have their own Meshy body
(`models/<who>.glb`). Every Meshy rig has the same 24 bones, so they play Duff's and Mike's clips: no clip
credits. `tools/share_clips.gd` builds `models/<who>_clips.res` from those clips (hips scaled to each body's
height) plus each rig's free walk and run (`models/clips/<who>_walking|running.glb`, kept out of git like the
other clip sources; copies in project files `meshy-backup/duffquest/animations/`). Each body cost 44 credits:
A-pose reference from the sprite sheet + portrait with Mike's reference as the style anchor (9), image-to-3d
12k tris 2K (30), rig (5). Total 176. Line-up: `docs/renders/porch3d/12_kitchen4_cast.jpg` (`tools/cast_shot.gd`).
Not in the porch yet, so the export presets leave them out of the porch APK until the kitchen uses them.

Head size (Duff, Nov 25: "resize the models to match one head size"): every body keeps its height and
`rig_actor.gd` `fit_head_bone()` scales its Head bone so the head (crown to chin, measured per model in
`HEAD`) is Duff's size. Meshy clips have no scale tracks, so it holds while clips play. `fit_body_to_head()`
is the other option (whole body scaled; small heads make tall bodies). Compare:
`docs/renders/porch3d/13_head_size_options.jpg`.

## Feel: hits that land (Nov 25 2026)

`porch_feel.gd`: hit sound, a 0.07 s hit-stop (0.16 s on a KO), camera shake (trauma squared, on the camera's
h/v offset so it never fights the fight camera), knockback on both sides, swing/whoosh/dodge/tell/KO sounds,
and music (neighbourhood, then the boss track when Mike walks in). Fighters are wider (`*_RADIUS`) and foes
fight from beside Duff on his depth line (`_side_spot()`), so they face off left/right at arm's length
instead of standing inside each other. `tools/play_bot.gd` plays the porch with real key presses
(`good` or `mash`) and saves frames + a log. Before/after: `docs/renders/porch3d/14_hits_before_after.jpg`.

## Real fight: skill matters (Nov 25 2026)

- Every melee swing has a wind-up with a red ring under the foe (pirate 0.4 s, Mike 0.38 s). Wind-ups have
  armour: hitting into one still lands, but so does his jab. Dodge it, then punish while he recovers.
- Flurries get read: the hit after two in a row (0.9 s apart or less) is blocked (bonk) and he counters in 0.18 s,
  too fast to dodge. Raged Mike blocks after one. A dizzy Mike (after a dodged charge) can't block; a taunting one
  blocks everything.
- Up close, Mike's jab is a shove (7.5 m/s) that throws Duff out to sign/charge range, and his next special
  comes 0.35 s later. Specials fire from 2.2 m.
- HP: pirate 5, Mike 8 (rages at 4). Duff 5, refilled when Mike walks in.
- Bot check (`tools/play_bot.gd`, game time, 0.25 s reactions): `good` wins at 5/5 HP in 13 s; `mash` is KO'd
  with Mike on 3. Frames: `docs/renders/porch3d/15_real_fight.jpg`.

## Phone controls (Nov 25 2026)

- Left half of the screen: Godot 4.7's built-in `VirtualJoystick`, dynamic (it appears where the thumb lands),
  analog, driving `ui_left/right/up/down`. `_movement()` reads `Input.get_vector` plus WASD.
- Right thumb: round HIT (128 px, red) and DODGE (96 px, blue), 20 px apart. The four arrow buttons are gone, and so is the
  keyboard hint on touch screens.
- Mike talks in a speech bubble over his head (`_say()`). When the camera keeps his head near the top, the bubble sits
  beside it. The top line keeps only the objective. Frames: `docs/renders/porch3d/16_phone_controls.jpg`.

## Godot 4.7 extras (Nov 25 2026)

- Physics runs on Jolt (`physics/3d/physics_engine`, stable since 4.6). Smoke (62 checks) and both bot runs give the same
  results as Godot Physics: careful wins at 5/5, the masher is KO'd.
- Lite (the auto fallback under 50 FPS) also draws the 3D at 3/4 size and scales it up with 4.7's nearest filter,
  about 44% fewer pixels. Full vs lite: `docs/renders/porch3d/17_lite_nearest.jpg`.

## Kick, combos (Nov 25 2026)

Duff: "add a kick button" and "lets discuss specials and combos". He picked the push kick from four Meshy clips.
- **K** (round orange button above A, or K/C): push kick. Longer reach (2.05) than a punch, goes through a guard
  (not Mike's rant), shoves the foe back.
- **Rhythm combos**: press again after the swing and within `COMBO_GAP` (.7 s). A press mid-swing is mashing and
  drops the combo (mashed hits still get guarded). A A A = knockdown (2 damage, big shove, stun). A A K = launcher
  (2 damage, bigger shove); a launched foe that hits the fence, planter or a wall within .5 s takes 1 more (a thud and shake, no callout: Duff's call).
- **Roll → A** within .55 s: homing dash hook (reach 2.6). **Roll through a hit → K** within .6 s: counter kick
  in slow motion for 2.
- Gold callouts under the strip (2 HIT, KNOCKDOWN!, LAUNCHER!, DASH HOOK!, PERFECT!, COUNTER KICK!), .75 s of real time.
- Kicks have a .9 s cooldown and a plain kick only staggers (HIT_ANIM); only the launcher arms the wall +1.
- Bot: careful wins; the masher (taps again mid-swing) and the kick spammer (`kickmash`) are KO'd. Preview: `tools/combo_shots.gd`.

## Red Right Hand, the first special (Nov 25 2026)

Duff wanted a dashing fire-fist special ("burn knuckle" feel; ours is original: name from his own right-hand tattoo).
- **Meter**: +14 per landed hit, +10 per hit taken. The red **R** button (or E/V) shows it as a ring and pulses when full.
- **R** with a full meter: .9 s wind-up: crouch, big twist, the burning fist held cocked (untouchable), then a 4 m dash in .4 s with the fist frozen fully out, fire and a
  red trail coming off the right hand. Contact does 3 through any guard (even Mike's rant), big shove, red flash. A whiff
  skids to a stop in a .45 s recovery with no protection.
- Swing: Duff's own right straight (`jab`) with a big coil baked in by `tools/bake_burn.gd` (hips -32 deg, chest -62 deg, a 9 cm crouch, a .3 s hold,
  fist cocked behind the shoulder, released into the punch); `RRH_PEAK` (.76) is where the fist is fully out. Duff turned
  down the Meshy "Kung Fu Punch" (96) cut ("doesn't look like a punch at all"); that clip is a spinning routine. Bigger
  wind-up, then even bigger, were his calls.
- Preview: `tools/rrh_shots.gd`. Smoke is 90 checks.

## HUD and menus (Nov 25 2026)

Duff: "get the slice closer to the original hud and menus ... improve them". `porch_hud.gd` draws the main game's
look (`scripts/ui_style.gd` + `hud.gd` colours and fonts, numbers x3 for the 960-wide view):
- Phone status strip: clock from 7:00 AM, "Wed Day 1", Duff's HP as hearts, green cash pill. Objective line under it
  with the gold "!" badge. Foe name plate + bar at the bottom (Porch Pirate, then Marketplace Mike).
- Round A (bonk) and B (roll) buttons like the main game's; the TouchScreenButtons under them are invisible.
  The VirtualJoystick is a faint cream ring with an ink-rimmed tip.
- Speech bubbles in the dialogue look: plum panel, cream text, pink name tag. Duff opens with a line, the pirate answers.
- Menus (pill buttons, MAIN teal / ALT plum / EXIT red): title card (APK only, or `-- --title`), pause sheet
  (Resume, Retry, Graphics Full/Lite, Sound On/Off, Quit to title) from the pause button, Esc/P or Android back,
  and on losing focus; KNOCKED OUT and PORCH SECURED cards with Retry / Play again. Retry skips the title.
- Fonts Baloo 2 + Nunito (OFL, licences in `fonts/`), heart icon from the main game's `assets/art/ic_heart.png`.
- Render: `docs/renders/porch3d/18_hud_menus.jpg` (`tools/hud_shots.gd`). Smoke is 68 checks.

## Files

- `porch_art.gd` `meshy_set()`: the porch set is Meshy props (`models/set/*.glb`) made from references in the
  same render style as the characters, fitted by `place()` onto the old layout, plus tiling grass and
  sidewalk textures. Collision is still the simple boxes in `porch.gd`. AgX tonemapping keeps the
  textures and the set in one colour response. Props went through `tools/strip_pbr.py ... <max px>`
  (2K house, 1K/512 small props) to keep phone VRAM down.

- `rig_actor.gd` loads `models/<who>.glb` + `models/<who>_clips.res` and picks idle/walk/run from speed;
  one-shots (`strike`) are squeezed into the gameplay timing in `porch.gd` (`ATTACK_ANIM` etc.).
- `models/duff.glb`, `models/pirate.glb`, `models/mike.glb`: rigged Meshy meshes (~12-14.5k triangles, one
  2K base-colour texture each). Meshy gave Mike normal + metal/rough maps too; `tools/strip_pbr.py`
  drops them (phone fill rate, same look under the porch lighting).
- `tools/clip_sheet.gd <who> <outdir>`: one frame per clip at 0/33/66 %, to eyeball a new character.
- `models/*_clips.res`: the clips, baked by `tools/bake_clips.gd` from the Meshy clip GLBs. The clip GLBs
  are not in git (each carries a full mesh copy): they live in the project files folder
  `duffquest-3d-slice/meshy_source/`. Copy them into `models/clips/` to re-bake.
- `tools/paint_hands.py`: paints Duff's REAL hand tattoos from the masters in `docs/ref/duff/` onto the
  backs of his hands (LEFT eye mandala with spikes onto the fingers + knuckle dots, black; RIGHT "This Red
  Right Hand Points Me South", red; no ring). Meshy garbles the script, so this always runs on a new Duff:
  `python3 tools/paint_hands.py <meshy duff.glb> models/duff.glb`.

## Test and renders

```sh
godot --headless --path . --import
godot --headless --path . --script smoke.gd                       # PASS lines, no FAIL
xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/shots.gd -- /tmp/porch_shots
xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/hands_shot.gd -- /tmp/porch_shots
xvfb-run -a godot --path . --rendering-driver opengl3 --write-movie /tmp/porch.avi --fixed-fps 30 --script tools/demo.gd
```

Renders: `docs/renders/porch3d/`. The sandbox renders on a software GPU (~78 ms a frame), so speed is only
judged on the phone.

## Meshy record (Nov 24, 2026; 1120 credits at the start)

| What | Task | Credits |
|---|---|---|
| Duff, first try from the in-game sprite views (not used: Duff wanted his own reference) | multi-image-to-3d 01a20f81-46f7… | 30 |
| Duff concept from his photos (not used; superseded by his turnaround) | image-to-image 01a20f83-096d… | 9 |
| Duff from his turnaround (front, left, back), A-pose, 14k tris, 2K texture | multi-image-to-3d 01a20f83-8061… | 30 |
| Duff rig + 6 clips (idle 0, jab 192, hook 193, dodge 156, hit 178, KO 187) | rigging 01a20f85… | 5 + 18 |
| Duff re-rig (Nov 25; the first rig's full id wasn't recorded and Meshy can't list rigs) | rigging 01a2139a-2c8e-704b-b2e6-af6cb09b81f3 | 5 |
| Duff push kick (Spartan Kick, 206), on that rig; baked into `duff_clips.res` as `kick` | animate 01a2139a-82d8-72a3-b49b-0f65e56136a8 | 3 |
| Duff Red Right Hand swing (Kung Fu Punch, 96), cut by `tools/bake_burn.gd` into `burn` | animate 01a213c7-dde8-76e2-aa4d-ed471a567610 | 3 |
| Pirate A-pose reference from the approved render | image-to-image 01a20f81-9222… | 9 |
| Pirate model, 12k tris, 2K texture | image-to-3d 01a20f81-fc3a… | 30 |
| Pirate rig + 4 clips (idle 0, jab 191, hit 178, KO 187) | rigging 01a20f83-e400… | 5 + 12 |

| Mike A-pose reference from his sprite sheet (`assets/art/ch_mike.png`) | image-to-image 01a20fc2-6e22… | 9 |
| Mike model, 12k tris, 2K texture | image-to-3d 01a20fc3-6c02… | 30 |
| Mike rig + 7 clips (idle 0, jab 191, over-shoulder throw 421, head-down charge 512, chest-pound taunt 88, hit 178, KO 187) | rigging 01a20fc5-226f… | 5 + 21 |

| Porch set references in the characters' style: house front, fence, planter, tree, bush, mailbox | image-to-image ×6, Nov 24 | 54 |
| Grass + sidewalk tiling textures | image-to-image ×2 | 18 |
| Set props: house 12k tris, fence 2k, planter 5k, tree 5k, bush 6k, mailbox 2k (bush took a free retry: the first try failed and was refunded) | image-to-3d ×6 | 180 |

Walk and run come free with each rig. Total about 641 credits (Mike: 65, porch set: 252, kitchen 4: 176).

| What | Task | Credits |
|---|---|---|
| Kitchen 4 A-pose references (Sends-It-Back, Camper, Carol, Allergy Liar), Nov 25 | image-to-image ×4 | 36 |
| Kitchen 4 models, 12k tris, 2K | image-to-3d ×4 | 120 |
| Kitchen 4 rigs (walk + run free) | rigging ×4 | 20 |

## Merge gate

This slice is opt-in (its own project and APK); it does not change the main game. ChatGPT's earlier rule
(merge only once the whole campaign runs in 3D) applied to converting the main game and still does for
that. The conversion order below is unchanged.

## Conversion order (from the first pass)

1. Finish the porch and Marketplace Mike as one playable 3D opening; verify movement, attacks, dodge,
   hit feedback and camera visibility on a phone.
2. Convert the first kitchen shift and home interiors, then each arena and street NPC.
3. Move navigation, collisions and combat placement to 3D coordinates per converted area. Check input,
   save migration and web/mobile performance before making that path the default. HUD and dialogue stay
   screen-space.

## Our own set (free, no Meshy)
`porch_kit.gd` builds the same porch from plain Godot shapes dressed in free seamless textures
(`models/kit/*.jpg`, made with Foxboard Forge, toned in PIL). Same footprint as the Meshy set, so the
colliders fit both. Off by default; run with `-- --kit` (e.g. `tools/shots.gd -- /tmp/out --kit`).
Comparison: `docs/renders/porch3d/set_meshy_vs_kit.jpg` (top Meshy, bottom ours).
