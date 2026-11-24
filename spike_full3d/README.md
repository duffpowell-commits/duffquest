# Duff Quest 3D porch encounter

A standalone Godot 4.7.2 vertical slice, fully 3D. Duff and the Porch Pirate are Meshy models on a real
24-bone humanoid skeleton (glTF), driven by real clips: idle, walk, run, jab, hook, dodge, hit and KO
(the pirate has idle, walk, run, jab, hit and KO). The frontage, stoop, fence, yard and planter from the
first pass (`porch_art.gd`) stay on the world collision layer; both fighters use it to check strike
obstruction. The parcel rides against the pirate's chest until he drops it.

Nov 24, 2026: the hand-coded block people were replaced with Meshy models (Duff asked for a small, fully 3D
slice to see how it feels). Duff's model comes from his own approved turnaround
(`docs/art/duff-3d-turnaround.png`); the pirate from the approved Porch Pirate render
(`docs/art/3d-character-standard.jpg`), re-posed to an A-pose without the parcel before modelling.

## Play

Phone: Releases -> `dev` -> `duffquest-porch3d.apk` (built on every push to main, own package id so it sits
next to the real game). Desktop: open this folder as a Godot project. Arrows/WASD move, Space hits (jab
then hook), Shift dodges, R retries; the on-screen buttons do the same. Beat the pirate, walk over the
parcel. The top-right counter shows FPS: the bar is 60 on Duff's phone.

## Files

- `rig_actor.gd` loads `models/<who>.glb` + `models/<who>_clips.res` and picks idle/walk/run from speed;
  one-shots (`strike`) are squeezed into the gameplay timing in `porch.gd` (`ATTACK_ANIM` etc.).
- `models/duff.glb`, `models/pirate.glb`: rigged Meshy meshes (~14.5k / ~12.3k triangles, one 2K texture).
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

Walk and run come free with each rig. Total about 148 credits.

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
