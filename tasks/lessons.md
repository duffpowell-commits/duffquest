# Lessons
- (Nov 8) Overlays drawn on top of a character sheet (shades) are tied to that sheet's head position. When a sheet is replaced, re-check every overlay in-engine.
- (Nov 8) `main.gd` copies its own `shades` onto the player every frame; test tools must set `m.shades`, not just `player.shades`.
- (Nov 8) Grok's fence sheet was drawn ~2.5x too big for the world (75 units tall vs Duff's 26). Check every new drop's scale against Duff before placing.
- (Nov 8) Run tools/dressing_check.gd after moving props: first layout put a hydrant on Brittany, a bench on the Ensure and a wall on a raccoon spot.
