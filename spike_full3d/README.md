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
| Pirate A-pose reference from the approved render | image-to-image 01a20f81-9222… | 9 |
| Pirate model, 12k tris, 2K texture | image-to-3d 01a20f81-fc3a… | 30 |
| Pirate rig + 4 clips (idle 0, jab 191, hit 178, KO 187) | rigging 01a20f83-e400… | 5 + 12 |

| Mike A-pose reference from his sprite sheet (`assets/art/ch_mike.png`) | image-to-image 01a20fc2-6e22… | 9 |
| Mike model, 12k tris, 2K texture | image-to-3d 01a20fc3-6c02… | 30 |
| Mike rig + 7 clips (idle 0, jab 191, over-shoulder throw 421, head-down charge 512, chest-pound taunt 88, hit 178, KO 187) | rigging 01a20fc5-226f… | 5 + 21 |

| Porch set references in the characters' style: house front, fence, planter, tree, bush, mailbox | image-to-image ×6, Nov 24 | 54 |
| Grass + sidewalk tiling textures | image-to-image ×2 | 18 |
| Set props: house 12k tris, fence 2k, planter 5k, tree 5k, bush 6k, mailbox 2k (bush took a free retry: the first try failed and was refunded) | image-to-3d ×6 | 180 |

Walk and run come free with each rig. Total about 465 credits (Mike: 65, porch set: 252).

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
