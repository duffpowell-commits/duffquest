# Handoff: design review fixes (Nov 15, 2026)

Read this first, then CLAUDE.md (the rulebook). Duff is phone-only. Nothing ships to main without his explicit "merge".

## The list
Duff asked for a design review on Nov 15. Ranked fixes:
1. Purple sunburst behind cards: DONE, PR #96 merged (blurred veil over the live scene).
2. Dialogue box: DONE, PR #96 merged (speaker tab, gold keyline, bobbing arrow).
3. Button colours: DONE, PR #97 merged (teal main, plum alt, red exit via `UiStyle.btn_role`).
4. Pasted seams: DONE, PR #98 merged (symphony street backdrop, plasma pouch, steel sushi belt).
5. Placeholder art: Back Walk + Stealth merged (PR #100). Blackhead back: follow-up PR moves the fox to the LEFT side
   of his neck below the ear (viewer's left from behind), nape bare; `blackheads.gd` draws `bg_blackheads_back` zoomed. Back Walk uses `bg_backwalk_bed`, Stealth uses
   `bg_stealth_floor` (crib left, bed right; `stealth._draw_backdrop` stretches the plain middle floor so the bed sits
   under the goal column, `FLOOR_SPLIT`).
6. HUD clutter and clipped tags: DONE on PR #100 (house names clamp below the HUD strip, `main.LABEL_TOP_MARGIN`).
7. Tiny text: DONE on PR #100 (functional size 4-5 text up one size).
8. Arena HP plate vs touch buttons: DONE on PR #100 (boss plate `Rect2(62,156,166,20)`, touch level panel above the buttons).

Review sheet: `docs/renders/ui_audit_review_nov15.png`. Before/after renders for each fix sit in `docs/renders/`
(`blackheads_fox_redo.png`, `backwalk_bed_after.png`, `stealth_floor_before_after.png`, `house_tags_after.png`,
`arena_hp_plate_after.png`, `tiny_text_after.png`).

## Open items (not #5)
- Props repaint: drone, nft, package, van, honeybun, freya_peek, phone icon.
- Walgrumps background and Blackheads pitches: these need Duff's yes. Blackheads art is done (Duff liked it).
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
