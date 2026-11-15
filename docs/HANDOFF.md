# Handoff: design review fixes (Nov 15, 2026, evening)

## Start here (state at handoff)
- **PR #101** (branch `claude/project-thread-osd9kf`, draft): Blackhead Patrol painted back with Duff's REAL fox neck
  tattoo (from his photo): pale blue rose third eye, blue geometric shards, left side of the neck below the ear, nape
  bare. Tests pass, CI green. **Waiting on Duff:** (1) which way the fox faces, (2) his "merge".
  - Facing: Duff said "the fox faces front" and asked for a flip twice. The PR has version A (same orientation as his
    photo, snout down toward the viewer's left = his throat side). Version B is the mirror. Comparison:
    project files `renders/fox_facing_A_vs_B.png`; a decision card is out in his thread. If he picks B:
    `python3 tools/fox_tattoo_graft.py <base> /tmp/out/bg_blackheads_back.png --mirror` (base = project files
    `renders/bg_blackheads_back_no_tattoo.png`), then `tools/backdrop_import/import_backdrops.py /tmp/out bg_blackheads_back`,
    touch + `--import`, ui_audit `blackheads`, tests, push to the same branch.
  - Canonical tattoo design: `docs/ref/duff/duff_fox_neck_tattoo.png` (also project files
    `renders/duff_fox_neck_tattoo_MASTER.png`). Duff's photo itself stays OUT of the repo.
- **Next, queued by Duff:** after #101 merges, a **consistency audit before publishing to CrazyGames**: hunt leftover
  earlier-build art, UI and text in BOTH editions (public + family), bring stragglers up to the current standard
  (2x sprites, painted backdrops, three button roles, veil not sunburst, tag() labels, `{fork_nick}`/`{coworker}`),
  and flag anything CrazyGames would reject (`docs/portals/SUBMIT.md`, `LISTING.md`). Show Duff a ranked list +
  renders before fixing; one PR per chunk.


Read this first, then CLAUDE.md (the rulebook). Duff is phone-only. Nothing ships to main without his explicit "merge".

## The list
Duff asked for a design review on Nov 15. Ranked fixes:
1. Purple sunburst behind cards: DONE, PR #96 merged (blurred veil over the live scene).
2. Dialogue box: DONE, PR #96 merged (speaker tab, gold keyline, bobbing arrow).
3. Button colours: DONE, PR #97 merged (teal main, plum alt, red exit via `UiStyle.btn_role`).
4. Pasted seams: DONE, PR #98 merged (symphony street backdrop, plasma pouch, steel sushi belt).
5. Placeholder art: Back Walk + Stealth merged (PR #100). Blackhead back: PR #101 (see Start here);
   `blackheads.gd` draws `bg_blackheads_back` zoomed (`ZOOM_SRC`). Back Walk uses `bg_backwalk_bed`, Stealth uses
   `bg_stealth_floor` (crib left, bed right; `stealth._draw_backdrop` stretches the plain middle floor so the bed sits
   under the goal column, `FLOOR_SPLIT`).
6. HUD clutter and clipped tags: DONE on PR #100 (house names clamp below the HUD strip, `main.LABEL_TOP_MARGIN`).
7. Tiny text: DONE on PR #100 (functional size 4-5 text up one size).
8. Arena HP plate vs touch buttons: DONE on PR #100 (boss plate `Rect2(62,156,166,20)`, touch level panel above the buttons).

Review sheet: `docs/renders/ui_audit_review_nov15.png`. Before/after renders for each fix sit in `docs/renders/`
(`blackheads_fox_left_neck.png`, `backwalk_bed_after.png`, `stealth_floor_before_after.png`, `house_tags_after.png`,
`arena_hp_plate_after.png`, `tiny_text_after.png`).

## Open items (not #5)
- Props repaint: drone, nft, package, van, honeybun, freya_peek, phone icon.
- Walgrumps background pitch: needs Duff's yes.
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
