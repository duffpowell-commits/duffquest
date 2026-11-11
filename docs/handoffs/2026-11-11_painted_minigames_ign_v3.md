# Handoff — Nov 10 night to Nov 11 morning, 2026

main = `da83d63`, CI green, the web build is live on itch (`dufftkyosht/duff-quest:html`) and in the `dev` release.
`test_daily` ALL PASS; 30-day soak PASS (seed 1, 0 issues).
Duff + Brittany played it Nov 11 morning: "it's come a long way."

## What shipped (newest first)
| Area | What | Where to look |
|---|---|---|
| IGN review v3 | **7.9/10** (v2 7.1, v1 6.4). All three v2 fixes landed | `docs/reviews/ign_review_2026-11-11_v3.md` |
| Last teal slabs | K6 props sheet: Kwik-N-Go shelf tiles, raw cut on the temp-check grill that browns with core temp (`temp_check._meat()`), baby FEED/CHANGE icons, ROCK gets a "Z" badge | `docs/renders/shop_baby_temp_after.png` |
| Street ground | Canva repaint fitted onto the road layout by `tools/import_street.py` -> `assets/art/ground_painted.png`; `scripts/ground.gd` falls back to tiles if the painting is missing | `docs/renders/street_ground_before_after.png` |
| Boss taunts | 12 rewritten; `test_daily` caps "I'm not X, I'm Y" at 2 and bans shared 3-word openers across bosses | `scripts/boss.gd` |
| Slab screens | Gear rows get item icons (`kf_gear_*`, crate when locked), the hustler NOPE is a door that swings shut, breading has real hands | `docs/renders/slab_screens_after.png` |
| Fork kitchen | 47 props in all six stations; ingredient buttons are picture tiles | `docs/renders/fork_kitchen_before_after.png` |
| "Heard." | Only in kitchens (waffle.gd, shift.gd, sandwich); a test enforces it | `tools/test_daily.gd` `_heard_checks` |
| 4G boot | 55.5 s -> 17.0 s (extra.pck streams after boot, gzipped wasm) | `docs/renders/web_boot_4g_after.png` |
| Bounty moves | Coupon storm, charger-cord lasso, gluten shout ring | `docs/renders/bounty_signature_moves.png` |
| Arena scale | Duff 1.45x, enemies 1.3x on painted floors (visual only) | `docs/renders/arena_scale_before_after.png` |

## How the prop art works (reuse this for anything new)
1. Canva `generate-image`: a 4x4 sheet of 16 props on flat magenta #FF00FF, house style C (`docs/art_direction/STYLE_LOCK.md`).
2. Scratch Canva design `DAHabdund5o` (41 pages so far): `read-design` with a transaction, `add_page`, `insert_fill`
   the media at left 420, top 0, 1080x1080 (square sheet), `commit`.
3. `export-design` png for that page -> Zapier Google Drive upload (see CLAUDE.md Art pipeline) -> Drive
   `download_file_content` spills to a tool-results file; base64-decode `content` with python into
   `grok_art/2026-11-10-kitchen-props/kN_sheet.png`.
4. Add the sheet + 16 names to `SHEETS` in `tools/import_kitchen_props.py`, run it. It writes `assets/art/kf_<name>.png`
   and registers each in `assets/art/manifest.json` + `scripts/art_manifest.gd`. Re-running is byte-identical for old sheets.
5. In a minigame: `pic("kf_x", center, height)` draws it (returns false if missing, so keep the old shape as a fallback);
   on buttons set `b["icon"] = "kf_x"` (picture tile) or `b["badge"] = "A"`.
6. `godot --headless --path . --import`, render the UI audit, test, soak, then commit the `.godot/imported/kf_*` files
   too (the repo tracks them).

## Next, ranked (from IGN v3)
1. **Duff/Brittany: a real phone playtest.** They've started (Nov 11). Ask what they hit: thumb reach, the tutorial
   cards, how hard week one is, anything confusing. Their notes outrank everything below.
2. **Duff: paste the itch page** (`docs/itch/PAGE.md` + 4-5 renders). Sessions can't reach itch.io.
3. **Overworld repaint (Duff's pick).** The 13 storefronts are small pixel sprites on small footprints; this is the
   last style seam. Painted neighborhood, home and Fork exteriors at real footprints. Plan it before cutting art.
   Pre-mortem: the painting gets fitted onto existing collision and doors break. Check walls and doors with the
   arena/home renders and the soak before calling it done. The ground is already painted (`ground.gd`).
4. **The last 5 flat screens:** phone, symphony, show & tell, grocery aisle map, wordle keyboard. One K7 props sheet,
   wired like the shop was.
5. **Boot under 10 s:** measure what's left in the 8.3 MB index.pck and move the next-biggest chunk (likely music)
   to extra.pck. Re-run `tools/web_boot_test.py`.
6. **Balance re-check** once the playtest notes are in (gates 45-65, wait drain floor 40).

## Gotchas
- `kf_salt` is skipped on purpose: the generated tub carried a religious symbol. Check every new sheet by eye before wiring it.
- The magenta key only drops true magenta (`r>190, b>190, g<110`); purple food survives. Wire baskets go in `MESH`.
- `card_button` stacks the icon above the label when the text area is < 17 px wide.
- Render tool ids: `tools/arena_shot.tscn` (`at:X,Y`, `home`, `gala:<boss>`...); UI audit -> `/tmp/ui_audit/NN_name.png`.
- After `test_daily`: `git checkout -- .godot/exported .godot/uid_cache.bin`.
