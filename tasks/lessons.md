# Lessons
- (Nov 8) Overlays drawn on top of a character sheet (shades) are tied to that sheet's head position. When a sheet is replaced, re-check every overlay in-engine.
- (Nov 8) `main.gd` copies its own `shades` onto the player every frame; test tools must set `m.shades`, not just `player.shades`.
- (Nov 8) Grok's fence sheet was drawn ~2.5x too big for the world (75 units tall vs Duff's 26). Check every new drop's scale against Duff before placing.
- (Nov 8) Run tools/dressing_check.gd after moving props: first layout put a hydrant on Brittany, a bench on the Ensure and a wall on a raccoon spot.
- (Nov 8) Don't infer 'heavy hit' from a special name: the starter spatula passes "flip" on every swing. Pass intent explicitly.
- (Nov 8) Camera2D.offset ignores limits; clamp it yourself or a shake shows the void past the arena.

## Nov 8 (M4/M5 session)
- Said M5 was "blocked waiting on art" while the boss drop already sat in `grok_art/2026-11-08-bosses/`.
  Rule: before calling anything blocked on art, `ls grok_art/` and check merged Place PRs (`gh api .../pulls?state=all`).
- Replaced PNGs, rendered, got the old art. Rule: `godot --headless --path . --import` after any asset swap, before renders.
- Burst intro card's letterbox bar covered the dialogue box's last line + prompt; missed because I judged a
  shrunken contact sheet. Rule: for overlay/UI changes, look at one full-size frame per screen, not just the sheet.
