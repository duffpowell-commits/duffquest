# Lessons
- (Nov 8) Overlays drawn on top of a character sheet (shades) are tied to that sheet's head position. When a sheet is replaced, re-check every overlay in-engine.
- (Nov 8) `main.gd` copies its own `shades` onto the player every frame; test tools must set `m.shades`, not just `player.shades`.
