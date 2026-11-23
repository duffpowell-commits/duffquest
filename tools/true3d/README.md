# True 3D models (test slice, `#true3d`)

The opening preview uses Duff’s authored mesh and rigged low-poly porch pirate stand-ins when authored pirate meshes are unavailable. The preview is opt-in via `#true3d` on web or `DQ_TRUE3D=1` for a local run. Web Duff may appear as a sprite until his model pack mounts.

## Porch Pirate 0 art review

[Concept sheet](../../docs/art/porch-pirate-0-concepts.jpg) based on the approved Porch Pirate 0 sprite. A keeps the sprite’s compact proportions. B uses longer limbs and a leaner silhouette. The first block model was declined. The concept choice is pending.

After Duff approves A or B, hand-model that direction and review the still pose in Godot at the gameplay camera before rigging the walk and throw. Keep the parcel against the chest and preserve the hood silhouette and forward lean.

## Merge gate

Keep PR #186 in draft during the conversion. Merge only after the full campaign runs in 3D and the branch passes gameplay, save migration, and phone/browser checks. The opening preview alone does not satisfy the merge gate.

## Conversion order

1. Finish the porch and Marketplace Mike as one playable 3D opening. Replace the pirate stand-ins with textured models and verify movement, attacks, dodge, hit feedback and camera visibility on a phone.
2. Convert the first kitchen shift and home interiors, then cover each arena and street NPC. Use the existing art and room layouts as references.
3. Move navigation, collisions and combat placement to 3D scene coordinates in each converted area. Check input, save migration, and web/mobile performance before making that path the default. Keep HUD and dialogue as screen-space interfaces.

The opening preview currently uses the game's existing 2D simulation for positions and combat. Audit ideas are tracked in #185.

Turns a 2D character sheet into a rigged 3D model for `scripts/view3d/true3d.gd`. Free, CPU only, no accounts.

1. Python deps (fresh container): `pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu`,
   then `pip install hy3dgen==2.0.2 transformers==4.49.0 diffusers==0.31.0 trimesh scipy accelerate fast-simplification`.
2. Inputs: the sheet's idle column (col 0) cut per row into `/tmp/h3d/in/<name>_{front,back,right,left}.png`
   (row 0 front, 1 back, 2 faces screen-right, 3 faces screen-left), cropped to the figure, centred on a
   transparent square at ~82% fill, 1024 px. Small 1x/2x sheets: upscale with NEAREST (LANCZOS blur made
   Hunyuan return a flat slab for the porch pirates).
3. Shape (~7 min each on 4 CPU threads, first run downloads ~5 GB of weights from Hugging Face):
   `python3 tools/true3d/shape.py <name>[,<name>...] [front,back[,left,right]]` -> `/tmp/h3d/out/<name>_shape.glb`.
4. Rig + texture: `python3 tools/true3d/rig.py <key> /tmp/h3d/out/<name>_shape.glb /tmp/h3d/rig [faces] [<name>]`
   (decimates to ~5-7k faces, projects the four views into a 1024 atlas, weights 7 bones from the front silhouette).
5. Into the game: copy `/tmp/h3d/rig/<key>_atlas.png` to `assets/model3d/`, set its `.import` to
   `compress/mode=1` + `mipmaps/generate=true`, `godot --headless --path . --import`, then
   `godot --headless --path . --script tools/true3d/build_mesh.gd -- /tmp/h3d/rig <key>` -> `assets/model3d/<key>.res`.
6. Check: `xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/true3d/model_shot.gd -- <key>`
   (turnaround: front, 3/4, side, back, stride, swing) and in game
   `DQ_TRUE3D=1 xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn --fixed-fps 30 -- cold`.

Known limits of the CPU path: no texture model (the art is projected flat, so arm sides smear), faces at
3/4 angles stretch, magenta key fringe gets masked out but a few flecks survive. A GPU textured pass
(Hunyuan3D-2 paint, needs Kaggle or HF_TOKEN) would fix the texture; the rig and game code stay the same.
