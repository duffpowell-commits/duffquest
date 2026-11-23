# Duff Quest 3D porch sample

This standalone Godot 4.5 scene tests one porch encounter before integrating the full campaign. Duff and the Porch Pirate use CharacterBody3D, the street uses static 3D colliders, and attacks check facing and obstruction in 3D space. The characters use temporary meshes and do not represent approved production models.

Open this directory as a Godot project and run its main scene. Use WASD or arrows to move, Space to hit, Shift to dodge, and R to retry. The on-screen controls provide the same actions. Defeat the pirate and walk over the parcel.

Run `godot --headless --path . --script smoke.gd` to verify the core encounter.
