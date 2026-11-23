# Duff Quest 3D porch encounter

A standalone Godot 4.5 vertical slice. Duff and the Porch Pirate move as 3D character bodies, with the frontage, stoop, fence, yard and planter on the world collision layer. Both combatants use that layer to check strike obstruction. The parcel is a separate mesh carried against the pirate’s chest until it drops.

The low-poly scene and actors in `porch_art.gd` are modeled from the approved look and concept references. Each prop and articulated actor part uses one indexed, vertex-colored mesh. The campaign’s existing Duff model uses the earlier outfit, and the old Porch Pirate review mesh was superseded.

## Play

Open this directory as a Godot 4.5 project and run the main scene. Use WASD or arrows to move, Space to hit, Shift to dodge and R to retry. The on-screen controls support simultaneous movement and actions. Defeat the pirate and walk over the parcel.

## Test and export

Run these from this directory with Godot 4.5 and its export templates installed.

```sh
godot --headless --path . --script smoke.gd
mkdir -p /tmp/duff-porch-web
godot --headless --path . --export-release Web /tmp/duff-porch-web/index.html
python3 -m http.server 8000 --directory /tmp/duff-porch-web
```

Open `http://localhost:8000` in a WebGL 2 browser and select Play. If using a downloaded build ZIP, extract it and serve the extracted directory over HTTP.

Keep PR #186 in draft until the full campaign runs in 3D and passes gameplay, save migration, and phone/browser checks.
