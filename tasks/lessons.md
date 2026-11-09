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

## Nov 9 (M10-M12 session)
- Patched a "reset" line into what I thought was new-game but was `from_dict`: it wiped `station_best` on every load. Rule: `new_game()` is `from_dict({})`; put defaults in the `d.get(key, default)`, never a separate reset.
- A headless test called `_wake()` -> `save_game()` on the real `user://` save; the next render hit Continue and loaded the test's state. Rule: tests set `main.save_path` to a throwaway path and erase it; delete the sandbox save before renders.
- Duff on parody bosses: the duck/TV/lightbulb heads read as Hazbin imitation. Made-up HUMAN faces against the house portrait (Ghoster) as style ref; cartoony versions are DLC.
- Sad scenes don't get the party burst: give the card a quiet `backdrop` + dim.

## Nov 9 (M13 session)
- AI image refs leak their characters: a B still built from Ghoster's still kept Ghoster's face in a side panel on 3 of 5. Rule: when a reference image has a character in it, check every panel of the output for that character.
- A QA tool that silently shoots the wrong screen is worse than none: qa_shot's boss shots had been shift cards/loading screens since M10. Rule: after a feature adds a new overlay (shift card, loading screen), rerun qa_shot and LOOK at a full-size boss frame.
- Using one finished still as the layout reference for five others cloned its composition AND Duff's faces into all five. Rule: style refs carry style only when they contain no characters; give characters their own refs and describe the composition per image.
- Checked faces, missed anatomy: the x-ray inset showed a different bone than the hit on 4 of 5. Rule: grade every impact still on 'is the x-ray where the hit is, and is it the bone the narration names'.


## Nov 8 night (restore + Canva session; full log docs/handoffs/2026-11-08_night_restore_gitlab_canva.md)
- The sandbox died and took 6 unpushed commits and every chat-only image. Rule: push every chunk; every AI image goes to Drive `geminiart` or the repo, never only the chat.
- Canva drew Earl as a stranger because the R6 brief never described him. Rule: every character prompt carries the look in words + the HD portrait attached.
- Graded R6 from Canva's 200 px preview and got a row wrong. Rule: grade only full-size images.
- `git stash` around before/after renders aborts on pop (`.godot/editor/filesystem_cache10` is tracked and rewritten by every import). Rule: `git worktree add /tmp/before HEAD` for the "before" render.

## Nov 9 (multi-agent day)
- Verify what the PUBLIC page actually plays, not just what butler reports: itch can have several HTML uploads and only one is embedded. Check the page's iframe upload id after the first push.
- test_daily can print ALL PASS on a compile error: gate on "SCRIPT ERROR" too.
- Check `git merge` exit codes; an untracked file silently aborts a merge mid-pipeline.
- Never glob-delete `*.gd.uid`; many are tracked.
- Parallel agents need separate worktrees AND separate XDG_DATA_HOME; only one Canva agent at a time.
