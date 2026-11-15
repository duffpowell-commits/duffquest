# Handoff: design review fixes (Nov 15, 2026)

Read this first, then CLAUDE.md (the rulebook). Duff is phone-only. Nothing ships to main without his explicit "merge".

## The list
Duff asked for a design review on Nov 15. Ranked fixes:
1. Purple sunburst behind cards: DONE, PR #96 merged (blurred veil over the live scene).
2. Dialogue box: DONE, PR #96 merged (speaker tab, gold keyline, bobbing arrow).
3. Button colours: DONE, PR #97 merged (teal main, plum alt, red exit via `UiStyle.btn_role`).
4. Pasted seams: DONE, PR #98 merged (symphony street backdrop, plasma pouch, steel sushi belt).
5. Placeholder art: IN PROGRESS, see below.
6. HUD clutter and clipped tags: not started.
7. Tiny text: not started.
8. Arena HP plate fighting the touch buttons: not started.

Review sheet: `docs/renders/ui_audit_review_nov15.png`. Before/after renders for each fix sit in `docs/renders/`.

## #5 placeholder art: where it stands
- Branch `claude/project-thread-sm8r6f`, draft PR #99 (CI green).
- Done: **Blackhead Patrol** draws the painted back `bg_blackheads_back` (Duff from behind, both sleeves, neck tattoo;
  Canva master in Drive as `bg_blackheads_back_v1.png`). `blackheads.gd` overrides `_draw_backdrop` and zooms 1.4x on
  his shoulders (`ZOOM_SRC`); blackheads spawn on the bare back (x 112-216, y 64-116). Check: `ui_audit_shot.tscn -- blackheads`.
  Caveat to show Duff: the AI's neck tattoo reads more like a generic piece than a clear fox.
- Left: **Back Walk** (`backwalk.gd`): the bed and Duff are flat rects. Plan: Canva side view of Duff face-down on the
  bed (head on the pillow at the right, flat back), refs = HD portrait (Canva media `MAHbALqqdnU`) + bedroom style
  (`MAHbADb1kl4`), LANDSCAPE_16_9. The first try hit Canva's cooldown at ~16:28 UTC. Import it as `bg_backwalk_bed`
  the same way as `bg_blackheads_back`, drop the drawn bed and body in `_draw_game`, and line Madison's walk
  (`mx`, y 82) up with his back.
- Left: **Stealth** (`stealth.gd`): the floor reads like a board-game grid, the bed is a flat box, and the crib tile is odd.
  The idea is a painted top-down nursery-to-bedroom floor, with the code still drawing the creaky boards and the cats.
- Then run the tests, build a before/after sheet, mark #99 ready, and wait for Duff's "merge".

## Open items (not #5)
- Props repaint: drone, nft, package, van, honeybun, freya_peek, phone icon.
- Back Walk Duff, which is covered above.
- Walgrumps background and Blackheads pitches: these need Duff's yes. Blackheads now has art on #99, so show him the render.
- The hair-copper question: still open with Duff. Confirm the wording with him before you act on it.

## Gotchas
- Adding a backdrop takes four steps:
  1. Add an entry in BOTH `scripts/art_manifest.gd` (1280x720, s 4) and `assets/art/manifest.json`. Copy a neighbour.
  2. Add the glob to the Web preset `exclude_filter` in `export_presets.cfg`, so it ships in extra.pck.
  3. Run `tools/backdrop_import/import_backdrops.py`.
  4. Set `compress/mode=1` in the `.import`, then touch the file and run `--import` again.
- Canva allows about one generate-image per 40 min, and the pipeline goes Canva -> Drive.
  - Lay the art out on a new page of design `DAHajFinSSI`, at 2560x1440 with insert_fill.
  - Export it, upload it to Drive with Zapier (connection `023ae0fb-...`, folder `1kwe88L_...`), then download it.
  - The download lands as a 2560x1440 PNG under the session's tool-results folder.
- After a squash merge, the branch can't fast-forward, and force-push is blocked. Restart the branch from main, then
  `git merge -s ours origin/<branch>` to join the old history without changing files, then push.
- `ui_audit_shot.tscn -- <names>` keeps every step whose name starts with one of the names given. A sub-shot like `akarui_belt`
  needs its parent step too, so run `-- akarui`.
- Local `.godot/imported` can go stale after `git checkout -- .godot`. Touch the files and run `--import`; CI clones fresh and is fine.
- The project-files thread attachment limit was hit, so link renders by path instead of attaching them.
