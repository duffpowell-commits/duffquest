# Duff Quest — handoff (read this first)

Comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent, work the line at the Twisted Fork,
fight exes and porch pirates. Godot 4.5, GDScript, 640×360 viewport (1280×720 window). Owner: Duff.

**Read order:** this file → `TRACKER.md` (Built / Next / Could improve) → `reference.md` (how every system works) →
`CLAUDE_REFERENCE.md` (itch target, art tools, key facts). History: `docs/handoffs/SESSION_LOG.md` (old long log)
and `docs/handoffs/*.md`. Work queue detail: `QUEUE.md`.

## Status (Nov 11, 2026 morning)
- **main is green and live.** GitHub `duffpowell-commits/duffquest` is the ONLY home (GitLab dropped; the
  `mirror_gitlab.yml` workflow skips cleanly, ignore it).
- **Every push to main ships:** `.github/workflows/build.yml` parses scripts, runs the smoke test, exports web +
  debug APK, refreshes the `dev` release, and butler-pushes the web build to itch `dufftkyosht/duff-quest:html`
  (secret `BUTLER_API_KEY`). A red CI = nothing ships.
- **iPhone full screen:** iPhone Safari has no fullscreen API, and itch's iframe can't be installed. CI also exports a
  PWA copy (`build/pages`) and deploys it to https://duffpowell-commits.github.io/duffquest/ (job `pages`, main only;
  needs Settings > Pages > Source: GitHub Actions). Players open it in Safari, Share > Add to Home Screen, then launch
  from the icon: no Safari bars. Native iOS builds are out (no Mac, no Apple developer account).
  Godot's service worker is cache-first, so CI injects `tools/web_shell/pwa_autoupdate.html` into the Pages
  `index.html`: at boot a waiting new build takes over and reloads once (Nov 16: Brittany saw a stale "Mazikeen").
- **IGN review v7: game 8.9/10, launch 3/10** (`docs/reviews/ign_review_2026-11-19_v7.md`). First Reddit posts (r/playmygame + 2 crossposts, bare "Duff Quest" title, logo first) moved itch views 25 -> 27. Next: a fresh r/WebGames post with a hook title + knockout GIF first; Duff + Brittany playtest. Duff + Brittany played it Nov 11: "it's
  come a long way."
- **Last session's handoff (read it): `docs/handoffs/2026-11-11_painted_minigames_ign_v3.md`.** It covers what
  shipped, the step-by-step prop-art pipeline, the ranked next list and the gotchas.
- Tests: `test_daily` ALL PASS; 30-day soak PASS (seed 1, 0 issues).

- **Side quests (Nov 12):** `scripts/side_quests.gd` + phone Notes journal + `!`/`?` markers + typewriter dialogue.
  New quests: add to `SideQuests.LIST`, wire triggers in main.gd, then flip `ready: true`. Dev: Settings > "Dev:
  quests" (debug builds), `#dq=quest:<id>:<stage>` (web; since Nov 19 a `#dq=` link saves to its own slot `DEV_LINK_SAVE`, never the player's save), `arena_shot` ids `quest` / `type` / `notes`.
  **Live: porch mystery** (day 2+, ends fighting Cheeto Chad; `arena_shot` `porch` / `chad`) and **The Grease Trap**
  (day 4+, 86 List after 10 PM, boss `grease` reuses Grill-Boy tinted; `arena_shot` `grease86` / `bounty:grease`).
  **Brittany's Side Gig** (day 5+, cover-or-rat choice card, payoff next day; `arena_shot` `gig`).
  **Lost & Found, Omaha** (day 3+, flyer at the home mail table, 3 glinting finds outside, return to the Seen Cafe
  paper box; `arena_shot` `lost`). **{coworker} round two (Nov 19):** Who Ate {coworker}'s Lunch? (day 7+, after gig; side door
  `BACKDOOR_PT`, night fight `brayden`), Double or Nothing (after 3 bets won; fight `earljr`, stake $50/$100), Cover My Shift
  (day 9+, after lunch; work any shift that day -> $40 + IOU refunding the next lost bet, `story.britt_iou`). LIST keys
  `"after"` / `"needs_bets"` gate them (`quest_ctx()`). Fights: arena_mode `quest`, `start_quest_fight(kind)`. `arena_shot`
  `backdoor` / `lunch_pick` / `cover` / `double` / `qfight:<kind>`.
  **Nov 19 content batch:** Dolores's book (Waffle Haus side bet at clock-in after the first graveyard, `DOLORES_BETS`,
  settled by `dolores_settle` in end_waffle; record `story.dolores_w/_l`). Chef's Bad Week (quest `chef`, day 10+, the Fork
  door; `chef_force()` sets shift.gd force keys inspector / eighty_six / grill_boy, `chef_shift_done(r)` grades it).
  The Cats' Heist (quest `cats`, day 6+, starts at the bowls, played at "freya" after 9 PM; `minigames/cat_heist.gd`
  extends stealth.gd). Porch Pirate King (quest `king`, after porch; Chad's door, 3 fleeing runners at `KING_SPOTS`, boss
  `king` in `KING_GARAGE`). Trivia night (Thursdays 6-10 PM at `TRIVIA_DOOR`, `minigames/trivia.gd` = quiz.gd with its own
  bank; `story.trivia_w/_l`, 4 wins = season). Neighborhood Watch (after porch: one `WATCH` request a day in the morning
  lines, spot `quest_watch`; `story.watch_n`, 7 = Block Captain). `arena_shot` `dolores_book` / `chef_day` / `heist` /
  `trivia` / `watch` / `king_boxes` / `qfight:king`. Eleven side quests live.
- **Storefronts (Nov 12):** all 13 exteriors repainted at 4x density (`sf_*`, manifest "s": 4). Re-import one with
  `python3 tools/import_storefront_hd.py grok_art/2026-11-12-storefronts/_work/<name>_v1.png <name> [--up N]` (masters: Drive "97 Gemini art drops", `sf_<name>_v1.png`), then touch +
  `--import`. Keep each lot's bottom edge and door x; check doors with the before/after map render.
- **Street props (Nov 12):** 17 trees/clutter (`sd_*`, not fences) repainted at 4x density, same footprints. Re-import
  with `python3 tools/import_dressing_hd.py grok_art/2026-11-12-props/_work [name ...]` (masters: Drive "97 Gemini art
  drops", `sd_<name>_v1.png`; `BOX` in the script = max world size). `Dressing.art_rect()` honours density + origin.
- **Fences + flat screens (Nov 12):** the 4 fence kinds are painted at 4x (`sd_<kind>_straight`, each segment carries
  both posts, 39 units post to post, no end piece). Re-import: `python3 tools/import_fence_hd.py
  grok_art/2026-11-12-props/_work` (masters `sd_fence_<kind>_v1.png` in Drive). Don't re-run `tools/import_dressing.py`
  (it rewrites the old fences). Phone app icons, Wordle tiles, grocery goods/kiosks/people, symphony mirror/bus/notes/snacks
  and show & tell pillows come from the `k7_sheet` (`kf_*`, `tools/import_kitchen_props.py`). Cards: `b["stack"] = true`
  puts an icon above the label. UI audit now has `symphony_bus/_concert/_snacks` shots.
- **Characters (Nov 12):** all 20 v1 chibi walk sheets (inspector, pete, karen + buddy, hoa, butler, drunk, heckler,
  kid, hustler, scammer, cashier, chef, pharmacist, sushi chef, phlebotomist, sitter, usher, waitress, madison_dress)
  repainted in the Sea of Stars style of `ch_brittany`; the Grease Trap boss has its own `ch_grease` (no tint).
  Phone avatars (`av_*`) are head crops of the new sheets. Re-do one: Canva sheet (4x4, magenta) ->
  `tools/fix_sheet_cells.py` for backwards frames -> `tools/prep_canva_sheet.py SRC OUT --mirror-left` (strips grid
  lines, row 4 = mirrored row 3) -> `tools/import_big_sheet.py OUT ch_<name>`. Masters: Drive "97 Gemini art drops",
  `ch_<name>_v1.png`. Old `ch_grillboy` is unused. HD dialogue portraits were already current.
- **Lighting (Nov 12):** time of day lives in `hd_presentation.gd` (`SKY` keyframes, door pools, sun-driven
  `Art.sun_shift`). Render any hour with `arena_shot -- at:X,Y,MIN`. Grok art scratch goes in `grok_art/<drop>/_work/`
  (ignored); the 674 MB already there stays (no history rewrites).
- **Web packs + slim engine (Nov 13):** web boot 19.9 s -> 9.3 s (title, throttled 4G). Three packs: `index.pck`
  (1.8 MB: scripts, data, fonts, sfx, small UI), `world.pck` (10 MB, fetched first after boot; characters, portraits,
  music, storefronts, props, kitchen/home/gala/arena art) and `extra.pck` (late art). Both built by
  `tools/make_extra_pack.gd -- OUT world|late`; `scripts/extra_pack.gd` mounts them. Continue/New Game wait on a
  "Loading Omaha..." card until world.pck lands (~23 s cold, cached after). Anything new under `assets/` that the
  title doesn't need: add its glob to the Web preset `exclude_filter` and to `WORLD` in make_extra_pack.gd.
  The engine was a trimmed 2D-only Godot 4.5 web template (`tools/web_template/custom.py`, release `web-template-2d`);
  since the 3D view went default it is the trimmed 3D one (`tools/web_template_3d/custom.py`, `web_template_3d.yml`,
  release `web-template-3d`, branches `-preview`; 3D physics off). Outside `scripts/view3d/` keep to 2D nodes, no
  `Image.create` (use `create_empty`), WorldEnvironment via ClassDB only. Changed the profile? Run
  that workflow and play-test the build. Storefront/prop sizes are baked in `data/art_rects.json`
  (`tools/bake_art_rects.gd`, test_daily checks it): re-run the bake after re-importing sf_/sd_ art.
  **Per-edition packs (Nov 19):** `make_extra_pack.gd -- OUT tier public|family`: CI ships public packs (itch, portals, Pages
  root; no originals that have a `_pub` copy) and family packs (Pages /family/, own packs.json; no `_pub`). `#dq=` links
  only work in the family copy / debug builds.
  **Pack cache (Nov 18):** CI writes `packs.json` (md5 per pack) beside the packs; `extra_pack.gd` re-mounts a pack already in
  browser storage (user://) when its md5 matches, so a code-only deploy costs returning players no pack download. Keep packs
  deterministic (no timestamps) and keep packs.json next to them in every web copy.
  Branch builds publish to the `web-preview` release (sessions can't download Actions artifacts).
  **Lossy sprites (Nov 17):** every `ch_*`, `duff_*`, `kf_*`, `sf_*`, `sd_*` sheet imports lossy 0.8 (`compress/mode=1`):
  street.pck 4.8 -> 2.0 MB, world.pck 12.8 -> 6.0 MB, so Continue downloads 8 MB instead of 17.6. No visible change
  (`docs/renders/lossy_sprites_before_after.png`). A NEW sheet imports lossless by default: set mode 1 / 0.8 in its .import.

- **Cold open (Nov 13):** new game = porch-pirate fight first, rules after (`main.gd cold_open()`, flag
  `story.cold_open`). Web packs are now street -> world -> extra: `street.pck` (STREET globs in
  `tools/make_extra_pack.gd`, 2.9 MB) gates New Game; world.pck gates Continue and, via `_world_gate`, the Fork,
  arenas, gala and minigames. New outdoor art a day-1 player sees: add its glob to STREET. Render:
  `arena_shot.tscn -- cold` with `--fixed-fps 30`. Browser timing: `tools/web_boot_test.py` reports all three packs.

- **Raccoon + Jen (Nov 13):** `raccoon` re-import: `python3 tools/import_critter_strip.py <strip.png> raccoon`
  (4 frames facing right on a key colour; row 1 is the mirror). `ch_jen` re-import: prep_canva_sheet (no mirror) ->
  `import_big_sheet.py OUT ch_jen --tol 70` (grey hair on Canva's purple key needs the low tolerance).
- **Hy-Whee floor (Nov 13):** top-down store, shelves baked into `bg_grocery` on the `SHELVES` rects by
  `python3 tools/grocery_floor_compose.py <old bg_grocery from git 88c80a8> assets/art/bg_grocery.png`. Move a shelf
  in grocery.gd -> re-run it. Items sit on the shelf top (`SPOTS` y = shelf y - 3), grabbed from the lane above.

- **Labels (Nov 13):** any text over painted art goes through `UiStyle.tag()` (minigames: `tag()`), never bare dark
  `txt()`. Audit + open list in `TRACKER.md` (PRs #48, #49).
- **Combat (Nov 13):** Searing Spatter cut; S + swap hide until the first special (Pinwheel Lv 2). Duff said combat
  was easy, then (Nov 17) "too tough": dialled halfway back. `main.DMG_TAKEN` 1.1, story exes in `boss.STORY_TUNE` (early four 43/80/98/117 HP, x1.1 dmg, attacks every 2.0 s, light lead aim; Willnot 220 HP, timer 230 s), night spawn cap +2. 3D is render-only: same hitboxes and timings as 2D.

- **Legal (Nov 13):** ranked risks in `docs/legal/RISK_AUDIT.md` (not legal advice). In-game Settings > Credits &
  legal carries the parody notice + Godot/OFL licenses; keep it, `docs/itch/PAGE.md` Legal and the end credits in
  sync. Privacy policy: `docs/legal/PRIVACY.md`.
- **Editions (Nov 13):** public = default export (itch, Pages root, `duffquest-public.apk`): `data/cast_public.json`
  overrides cast.json and `Art.pub()` loads `<name>_pub.<ext>` art. Family = feature tag `family` (Pages
  `/family/`, `duffquest.apk`, same package id as before): real names, real Fork, Bruce Willnot, Brittany (both editions since Nov 16: she OKed her real name and asked for redder hair; still write `{coworker}`, not her name, in new lines). Snack/chain brands are tokens too (`{chad}`, `{hot_chips}`, `{chain_grill}`, Nov 19). The kitchen's nickname is `{fork_nick}` (family Fork, public Spatula; test_daily fails on a bare "Fork" in any string). New real brand or
  real person? Put the family name in cast.json, the public one in cast_public.json, add a test_daily leak word.
  Re-make the `_pub` art with `python3 tools/make_public_art.py` (keeps sizes; set big ones to lossy in .import).
  The `_pub` set: Fork + Walgrumps signs, the alley dumpster (`arena_alley`), the pharmacy shelves (`bg_pharmacy`: no real
  cold-medicine brands), the tower sign (`sf_plaza`: GLASSHAUS TOWER), every Willnot image. Re-audit Nov 15 in RISK_AUDIT.md;
  the credits name no AI tools (Duff's call) but itch's AI-generation disclosure stays on. test_daily fails if a
  `_pub` file is a byte copy of its original (redraw the original -> re-run the script).
  Render either edition: `arena_shot.tscn -- <id> --family`.

- **Madison's mornings (Nov 13):** EDS slow / migraine / good mornings, `scripts/mornings.gd` (see reference.md).
  Madison is a real person: Duff approves EVERY line about her EDS, autism and ADHD before it ships. One pitch at a
  time. Off-limits: the mess of her stuff, and that she's on disability.
  Her diagnosis story "The Zebra" is `scripts/zebra.gd` (same approval rule). Her autism: "Too Loud"
  (`scripts/too_loud.gd` + `minigames/noise.gd`): first Saturday grocery trip from day 6, noise overload, her headphones,
  home crash. Facts from Duff: noise is the trigger, headphones help, she masks then crashes, she info-dumps about herself.
  Her ADHD: "Look At This" (`scripts/look_at_this.gd`, same approval rule): talking to her at home from day 3, once, she
  cuts into his story with a reel and a text; `hud.gd _draw_her_screen` draws the phone over the dialogue. Facts: she
  shows him her phone screen constantly (reels, texts) and finds it hard to let him finish. `arena_shot` `look` / `look_text`.
- **Portal fit (Nov 13 late):** windows where integer scaling wastes >10% now scale fractionally (`HdPresentation.use_fractional`), so CrazyGames' 907x510 iframe is filled. Touch pad on the web shows up front only on iOS/Android browsers, else on the first real touch (`TouchControls.default_visible()/real_touch()`; mouse-emulated touches have device -1). Listing copy: `docs/portals/LISTING.md`.
- **Portal polish (Nov 14):** keyboard/mouse players: the cold-open line says "WASD or arrows to walk, Space to bonk"; the level/heat panel sits bottom-right (`combat_ui.PANEL_R_KEYS`) instead of floating where the touch buttons would be; enemy name + Lv labels are on ink plates. The sandwich ticket's house item is `{house_sandwich}` (public: Spatula Classic). Renders in keyboard mode: add `--keys` after the id (xvfb reports a touchscreen).
- **First bet (Nov 14):** the cold-open pirate's KO/escape -> `main.first_bet_pitch()` -> {coworker}'s bet card ->
  `start_first_bet()` (arena_mode `firstbet`, alley, boss `mike`) -> +$`FIRST_BET_PAY` -> the rules. Pitched once
  (`story.first_bet`); a loss costs nothing. Needs world.pck like every arena (web shows the loading card if it isn't in).
- **Web portals (Nov 13):** `duffquest-crazygames.zip` in the dev release is the CrazyGames upload (no plain
  index.wasm; `window.DQ_PORTAL` = clean + gore off for new players). Checklist: `docs/portals/SUBMIT.md`.
- **Marketing footage (Nov 13):** `tools/promo_shot.tscn` plays scripted takes (`fight:<boss>`, `walk:X,Y,MIN,DX`,
  `still:gala|madison|at:X,Y,MIN`) with fake input, no damage, KO beats on a timer, touch UI hidden. Record with
  `--fixed-fps 30 --resolution 1920x1080 --write-movie DIR/f.png` (1080p is native, integer 3x). Point XDG_DATA_HOME at
  a folder whose `godot/app_userdata/Duff Quest/settings.json` says `{"clean":true,"gore":false}`. Outputs live in
  `docs/portals/preview/` (CrazyGames clips) and `docs/itch/` (GIFs, 1080p screens). ~3 fps under llvmpipe.
  GameDistribution: Duff registered as "Wild Dreams" (Nov 13), gameId after review.

- **Duff in HD (Nov 13-14, PR #58 open, not merged):** every Duff sheet is 2x (512x512, 128 cells, manifest "s": 4,
  origin [64,120]; same world size and hitbox): `duff_apron/clogs/sleeves/coat/dad_red|black`, `duff_home` +
  `duff_home_black`, `duff_roll_*` (512x128, origin [64,88], rotations of the casual idle). The apron is work clothes:
  `player.sheet_name()` shows the casual tee (`duff_home*`) for apron armour off the line and at home; minigame
  `work_duff` (the kitchen line) still uses `duff_<armor>_black`. Shades: one overlay per outfit (`duff_shades` = apron,
  `duff_shades_<outfit>`), built from each sheet's face positions. Masters: Drive "97 Gemini art drops",
  `ch_duff_<outfit>_hd_v1.png` (apron v2). Rebuild: Canva generate-image with the HD apron sheet + old outfit sheet +
  HD portrait as references -> `import_big_sheet.py SRC <id> --cell 128 --height 104 --feet 120 --smooth --auto-grid
  --row-feet`, recolour magenta fringe to brown, row 1 col 2 = col 1's legs mirrored (the AI draws walk-away B like
  idle), black shoes by recolouring red in the bottom 24 px, then `python3 tools/duff_eyes_narrow.py SHEET SHEET` once and `... SHEET SHEET --brow` once (hooded, dark-lidded eyes; Duff asked Nov 14). The dad jacket skips `--brow`: Duff called it perfect as is. Then `python3 tools/duff_smirk.py SHEET SHEET` once (cocked screen-left brow + lopsided smirk on the front walk frames; Duff asked for "more smug" Nov 14, all outfits). Before/after: `tools/outfit_shot.tscn -- OLD_DIR`.
  Rim light: `shaders/sprite_rim.gdshader` via `Art.rim_material()` on player + bosses, per room in
  `hd_presentation._update_rim()`. `Art.shadow()` adds a contact core under every character.

- **Cast 2x overhaul (Nov 14, DONE: every used `ch_*` sheet is 2x; last was `ch_duff_suit`, PR #92; `ch_grillboy` is unused and stays 1x. Final review stills: `docs/renders/screens_final_2x.png` + `ui_audit_final_2x.png`):** every `ch_*` sheet moves to 2x like Duff (512x512, cell 128,
  origin [64,120], s 4 in manifest.json AND art_manifest.gd). Batches of four, before/after via
  `res://tools/cast_shot.tscn -- OLD_DIR id[:Label] ...` (old PNGs from git in OLD_DIR) -> `/tmp/qa/cast.png`. Batch 1
  (home crew): `ch_madison` done (8% slimmer per Duff; AI ghost/beard frames replaced by mirrors); dress, Brittany
  (`ch_brittany`), Lance (`ch_fences`) done too (PRs #62, #66, #67 merged). Batch 1 complete. Batch 2 (story exes: Ghoster, Gym Bro, DJ Vape, Crypto) done on branch `claude/project-thread-i5tf4g`, draft PR for Duff's yes (render `docs/renders/cast_batch2_exes_before_after.png`). DJ Vape + Crypto came from Grok (Duff ran it; prompt + refs in project files `renders/grok/`). Sheet row 3 faces RIGHT, row 4 LEFT: check against cast_shot, AI sheets often come swapped. Canva allows about one generation per 40 min. Import with `--tol 90` (reds survive the key) and `--fit-action` (keeps attack swings inside the cell). Action-frame FX trails (purple) get purged and small islands dropped after import. Batch 3 (Willnot, Grease, Husk, Baron, Marketplace Mike as his own `ch_mike`, no tint) done on branch `claude/project-thread-sm8r6f`, draft PR for Duff's yes (render `docs/renders/cast_batch3_bosses_before_after.png`). Canva takes TWO characters per shot (LANDSCAPE_2_1, 8x4 sheet, split into two 2048 halves before import). Batch 4 (porch pirates 0-3) done, render `docs/renders/cast_batch4_pirates_before_after.png`. Order after: Fork customers, then street, Fork customers, errand NPCs. Duff approves Marketplace Mike (first-bet boss) borrows `ch_hustler` tinted today; Duff wants him in the 2x pass as his own `ch_mike` with `"sprite": "mike"` in boss.gd and no tint.
  every batch before merge.

- **Play stats (Nov 14):** `play_stats.yml` snapshots itch counts every 3 h into the `stats` branch; alerts (GitHub
  issues @mentioning Duff) start when `.github/play_alerts.json` says `"armed": true` (armed Nov 19).
  itch's API gives views/downloads/purchases, not browser plays. CrazyGames/GameDistribution have no stats API.

- **Menu backdrop + dialogue (Nov 15):** the purple sunburst behind cards/settings/credits/phone is gone: `main.open_overlay` lays a blurred, darkened snapshot of the last world frame (`_veil_snapshot`, CPU blur, world still stops drawing) under any overlay and sets `veiled` on it; minigames with painted art cover it; no snapshot (shifts, cold boot) = old burst. Dialogue box: speaker name tab (`hud.speaker()` splits "Name: line"; Duff's lines get his name), gold keyline, bobbing next arrow.

- **Buttons (Nov 15):** three roles only, applied in `UiStyle.button` via `btn_role()`: `BTN_MAIN` teal (do the thing), `BTN_ALT` plum (options/toggles; any low-saturation colour), `BTN_EXIT` red for labels starting back/close/leave/done/stop/quit/cancel/give up/nope/exit. Callers' own colours collapse into these; cards: first option MAIN, rest ALT.

- **Seams (Nov 15):** symphony bus run draws `bg_symphony_street` (Canva, master Drive `bg_symphony_street_v1.png`) cropped 30 units from the top so its asphalt sits on the run lane (y 84-118); it ships in extra.pck like `bg_holland`. Plasma bag is a drawn pouch (`plasma._draw_bag`); the Akarui belt is steel slats between wood lips. Render: `docs/renders/seams_before_after.png`; ui audit has `akarui_belt`.
- **Placeholder art + HUD (Nov 15, PR #100):** painted backdrops `bg_backwalk_bed` (Madison walks `BACK_X0..BACK_X1` on his painted back) and `bg_stealth_floor` (`stealth.FLOOR_SPLIT` stretches the mid floor so the painted bed sits under the goal column; code still draws creaky boards, cats, Duff). Masters in Drive "97 Gemini art drops". House name tags clamp under the HUD (`main.LABEL_TOP_MARGIN`), boss plate and touch level panel clear the buttons, size 4-5 UI text up one size. Blackhead Patrol draws `bg_blackheads_back` zoomed (`blackheads.ZOOM_SRC`); the neck tattoo on the LEFT side below the ear matches Duff's real one (realistic fox, pale blue rose third eye, blue geometric shards behind; lifted from his photo Nov 15, Duff picked the MIRROR of the photo crop: 'the fox faces front'; rebuild with `--mirror`). Nape bare; v2 had a cartoon fox on the nape and Duff rejected it; the tattoo design master is `docs/ref/duff/duff_fox_neck_tattoo.png` (canonical, see duff_look.md); re-graft with `python3 tools/fox_tattoo_graft.py BASE OUT --mirror` on the bare-neck base in project files `renders/bg_blackheads_back_no_tattoo.png`.
- **Consistency audit (Nov 15):** ranked leftovers in `docs/reviews/consistency_audit_2026-11-15.md` (marketing re-shoot, cover fox placement, kitchen centrepieces, props, sunburst fallback). Boot splash `splash.png` + app icon `icon.png` (project.godot). Phone avatars: `python3 tools/make_avatars.py` after any `ch_*` re-import. Listing assets re-shot Nov 15 (previews, GIFs, screens, covers = porch title art + logo); re-shoot again after any big art or UI change.

- **HD audit (Nov 16):** every sprite is s:4 now. Street ground = Canva repaint in 4 tiles: `python3 tools/ground_repaint_tiles.py split` -> repaint each `src_RC.png` in Canva -> `tile_RC.png` -> `... merge DIR` (aligns, colour-matches, min-cost seams; masters Drive `ground_tile_RC_v1.png`). Street odds + HUD icons (drone, nft, package, truck_h/v, honeybun, freya_peek, bus_sign, phone, ic_*) come from one 4x4 Canva sheet: `python3 tools/import_hud_icons.py [sheet]` (master Drive `hud_icons_sheet_v1.png`; keeps each asset's world size + anchor, rewrites both manifests).
- **Fail states (Nov 16):** `scripts/minigames/fail_screen.gd` (extends card.gd). Eviction = `EVICT_STRIKES` (3) short
  Mondays in a row (`rent_strikes`; a strike = couldn't cover the week's base, back rent alone carries over) -> roll back
  to last Monday. Story/gala KO -> game over, roll back to this morning, but the first such KO each day is a free get-up (`getup_day`, Duff Nov 16). `save_game()` keeps two snapshots next to the
  save (`snap_path("morning"|"week")`, first save of each day / each Monday); `fail_screen()` writes the rollback over the
  main save as it opens, so Quit to title = retry too. New game erases them. No snapshot = old soft landing.
  Render: `arena_shot -- evicted|gameover`. No Madison lines on either screen.

- **3D view (Nov 16, PR #109 MERGED, 3D is the default):** steps 2-6 of
  `spike3d/PLAN_3D.md` done (town, fights, rooms, native res, Lite via perf_guard). Render with `arena_shot -- <id> --3d
  [--lite]`. Duff phone-tested it Nov 16 ("looks great, controls feel better") and said go: step 7 shipped (devlog `docs/itch/devlog_2026-11-16_3d.md`).
  3D is the default (`audio.view3d` true; settings saved before carry `view3d_v` < 2 and flip to 3D once; Settings > 3D
  view still turns it off; web `#3d` / `#2d` in the URL force it). Web exports use the 3D engine (`web-template-3d`, falls
  back to `-preview`). Building signs (CLOSED, CLEARED, errand/story `!`, NOW HIRING, quest markers, house names,
  Lost & Found glints) are Label3Ds pinned to their facade (`view3d._sync_labels`); main's flat WorldLabels layer hides
  in 3D because the overlay map only lines up near the camera target. Phone-test link: memory `duffquest-3d-phone-test`.
  Plain draw_rect/draw_string art in the town (signs, boards) drifts in 3D the same way: give it a
  `draw_x(ci, o, k)` function and stand it up with `view3d._sign()` (own 4x viewport on a card), or use a Label3D.
  Bus stop signs are dressing items. Duff's 3D sheet is the HD `assets/art3d/duff_home_hd3d.png` (2x sheet if it
  isn't in the build); his shades over it are `duff_shades_home_hd3d.png` from
  `tools/duff_hd3d/shades_hd.py` (eye centres measured per frame: re-measure if the HD sheet is rebuilt). Render: `--shades`. Renders: `arena_shot -- at:X,Y[,MIN] --3d` / `--2d`.
  Low-end phones (Nov 17): `perf_guard.gd` steps 3D down in order: Lite, then 640x360, then the flat 2D view with a
  toast (Settings > 3D view switches back). Profile with `tools/perf_run.tscn -- view=3d|2d [low]`. Store screens in
  `docs/itch/screens/` are 3D shots on the Duffphone UI (re-shot Nov 17 late, `docs/renders/store_screens_phone_ui_before_after.jpg`).
  Re-shoot: `XDG_DATA_HOME=<fresh dir with settings.json {"clean":true,"gore":false}> xvfb-run -a godot --path . --rendering-driver opengl3
  --resolution 1920x1080 --fixed-fps 30 res://tools/arena_shot.tscn -- <id>`, one fresh XDG dir per run (a leftover save makes `cold`
  stop at "Start over?"). Ids: 01 `at:540,150,720 --3d`, 06 `ask --3d`, 07 `gala_say:fences --3d`, 08 `at:300,215,1260 --3d`,
  10/11/12 `cold` (cold_1/3/4), 13 `notes`, 14 `gig`, 15 `evicted`.

- **Depth pass (Nov 19, PR #161 MERGED, Duff said merge):** six 3D-view tweaks, all
  in `scripts/view3d/view3d.gd`, all off in Lite except the eaves. (1) Camera sway: yaw follows Duff off centre (`YAW_MAX` 7°,
  rooms `YAW_ROOM` 4°, `YAW_LEAD` toward his walk); actor + dressing cards turn with it (group `view3d_face`); a fight
  opens with a 10% push-in (`_push`, `PUSH_T`). (2) Round cut-outs: `shaders/card3d.gdshader` on character sheet frames
  and dressing (not facades, vans, plain images or fading cards): normals from the art's own alpha at mip 2, no extra
  textures. Sprite3D won't bind its texture under a material_override: `tex` is set by hand (`_round_mat`/`_round_pool`).
  (3) Contact shadows: `shaders/ao_blob.gdshader` (`_ao`) under every building box, prop/tree and along a room's back
  wall (stands in for SSAO, which Compatibility lacks). Raised curbs were dropped: the street is one painting with no
  curb data. (4) Trees bend from the crown in the shader (`sway`), gustier in rain/snow (`wind`). (5) Haze = depth fog
  (`FOG_MODE_DEPTH`, starts 19 m by day, 6 m at night: the old flat fog lifted Duff's black shirt at night, keep that).
  (6) Eaves: a thin lip along each building box top (`_box`). Render `docs/renders/depth_pass_before_after.jpg`. Noon (IGN v5): midday runs darker (`noon` factor in `_sync_sky`: sun -0.1, `tonemap_exposure` 0.92, glow -0.15, haze -0.08; rooms reset exposure to 1) and the tilt-shift band is wider/softer (0.28, radius 1.7). Render `docs/renders/noon_3d_before_after.jpg`.
- **True 3D slice (Nov 17, test only, OFF for players):** web link `#true3d` (or env `DQ_TRUE3D=1` for renders) swaps
  Duff from a painted card to a real 3D model in the 3D view (porch pirate entries exist but have no model yet:
  their 1x art gave Hunyuan a slab/box, so they stay cards) (`scripts/view3d/true3d.gd`; view3d
  hands each captured sheet frame to `true3d.claim()` first). Nothing else changes; never saved, not in Settings.
  Models: `assets/model3d/<key>.res` (skinned ArrayMesh, 7 bones in its "bones" metadata) + `<key>_atlas.png`
  (front/back/left/right tiles of the sheet's idle frames, projected on). Excluded from every export preset except
  the web's late `extra.pck` (cards until it lands). Animation is code: walk swing from ground speed, idle breathing,
  facing from movement, sheet column 3 = attack swing (Duff gets a 3D skillet), roll = tumble, KO tilt follows the 2D
  rotation. His shades overlay is dropped (not on the model yet). Rebuild a model (CPU, ~7 min shape): see
  `tools/true3d/README.md`. Turnaround render: `tools/true3d/model_shot.gd -- <key>`.

- **HUD = Duff's phone (Nov 17):** `hud.gd` draws the strip as his status bar (clock, heart + signal bars = {partner},
  battery = Energy, cash pill, chevron), the drawer as a notification shade (`ROW_APPS` tile per `drawer_lines` tag),
  peeks/toasts as banners. New drawer row? Give it a tag + a `ROW_APPS` entry. Rects in `layout()` unchanged.
  Render: `res://tools/hud_shot.tscn -- DIR` (town/fight/drawer/peek/rent_due).
  UI language (Nov 17): menus are glass sheets (`card.gd`), buttons there are pills (`minigame.pill_buttons`,
  `UiStyle.pill_button`), panels use `UiStyle.glass`. Settings = phone Settings app, Gear = icon grid; rows/tiles are
  buttons with `"hide": true` (drawn by the screen, still tappable + key-bound). Minigame play screens keep the chunky
  key-cap buttons on purpose (big thumb targets on the line).
  Loading screens double as wallpapers (`scripts/wallpaper.gd`): phone home = one per day, menus with no world
  frame = a blurred one. Draw them via ImageTexture (sandbox GL renders the lossy CompressedTexture white).

- **Living town + motion (Nov 17):** `scripts/town_life.gd` (child of main, y-sorted entity nodes, own RNG, nothing
  collides): vans, walkers, pigeons, roof steam, screen-space weather. New ambient thing? Add an `Ent` kind and draw it
  with `Art.*` so 3D mirrors it. Tilt-shift: `shaders/tilt_shift.gdshader` on View3D (`tilt_mat`, null in Lite).
  Vans: 2D draws top-down `truck_h`/`truck_v`; 3D swaps in standing `van_side`/`van_front`/`van_back` (`view3d._van`; re-cut with
  `python3 tools/import_vans.py grok_art/2026-11-17-vans/_work/vans_v1.png`). A mirrored 2D draw shows as get_scale().y < 0, not x.
  Squash: `juice.squash(node, big)`. Swing smear / roll dust: `combat_fx.swing()` / `dust()`. Wipe: `hud.wipe_t`.

- **Music (Nov 18):** `mus_<name>.ogg` in assets/audio (mono 22 kHz Vorbis, ~25 s loops, RMS ~0.17), picked by `main.music_track()`, listed in `assets/audio/manifest.json`. DJ Vape's arena plays `club` (dubstep, `python3 tools/synth_dubstep.py assets/audio/mus_club.ogg` regenerates it). Keep the credits line in credits.gd + PAGE.md + manifest in sync.
  EDM soundtrack (Settings toggle `audio.edm`; batch 2 Nov 18 covers every music id: neighborhood, night, kitchen, boss, home, gala, willnot, date, credits; club stays dubstep): `mus_edm_<name>.ogg` beats `mus_<name>.ogg` (`audio._music_candidates`, `MUSIC_FALLBACK` for ids only the EDM set has, e.g. `night`). Regenerate with `python3 tools/edm/make.py [names] [--preview DIR]`; new tracks go in `make.py TRACKS` + the test_daily list. Stings (EDM on only, else the old sfx): `AudioScript.sting(name, fallback)` plays `sting_<name>.wav` (ko, rent, levelup, tapestop; `make.py --stings`).
- **Web audio buses (Nov 19):** buses must exist at boot: `default_bus_layout.tres` (Master/Music/SFX). Web sample playback ignores buses added at runtime (the whole web game was silent). New bus? Add it to that file, not `AudioServer.add_bus`. CI now runs `tools/web_audio_check.py build/web` after the web export (headless Chrome, analyser on the speakers, title music must peak > 0.05): a silent build goes red and never ships.
- **iPhone hardening (Nov 18):** iPhones start Lite once (`perf_guard` cfg `ios_lite`). Big one-off art is dropped from `Art._tex` on room change (`Art.drop_big`, prefixes `bg_ arena_ gala`); never hold a 1280x720 texture forever in a cache. `main._watchdog` frees a stuck loading screen (10 s) or a dead menu. A tap anywhere advances dialogue. Bug reports: Settings > Send a bug report (`main.bug_report()`); ask testers for one before guessing.
- **Thumb buttons (Nov 18, Duff: fat fingers):** touch pad buttons are radius 12 (A 14) with >= 8 units clear between any two; taps go to the nearest button within `REACH` (touch_controls `_hit`), menu/minigame buttons the same via `minigame._button_at`. test_daily enforces the gap. Moving a button? Keep it off the boss bar (x <= 228, y >= 156) and the level panel (y <= 98). Render: `arena_shot -- <id> --3d --maxpad` (every button showing).
- **Kitchen tickets (Nov 17):** spec lines are picture tiles (`minigame.ticket_spec()`), the fryer is a colour gauge (`fryer._draw_gauge`). Don't add small explanatory text to play screens; put it on the how-to card.
- **Mini-game coach (Nov 16):** first-time HOW TO PLAY card + slow first go (0.7, then 0.85, then 1.0) for every
  action mini-game. New mini-game: add `func howto() -> Array` (1-3 steps `{"i": kf_ art or "", "v": tap|drag|hold|beat|mash|read, "s": <= 80 chars}`;
  test_daily checks it). Multi-phase games override `coach_key()` and call `coach_start()` / `coach_done()` per phase
  (see prep.gd). `coach_pace = false` in `_setup` = card only. Renders: `ui_audit_shot.tscn -- coach`.

## Next (in order)
0. **Visual plan built Nov 17** (living town, UI motion, diorama 3D, fight impact; TRACKER entry): needs Duff's
   phone test, mainly the tilt-shift cost on his Android (perf_guard Lite turns it off). Store screens re-shot Nov 17 late.
1. **Ask Duff for his and Brittany's playtest notes first** (iPhone + his Android). They outrank the rest.
2. **Itch page:** source is `docs/itch/page.html`; Duff pastes it from https://duffpowell-commits.github.io/duffquest/itch/ (Copy button). Footage = `docs/itch/slots/slotN.*` (replace the file, keep the name, no paste needed). The itch page bot is disabled: itch's Cloudflare bot check blocks GitHub runners, and we don't get around bot checks.
3. **Grease boss art:** done Nov 12 (own sprite `ch_grease`, alley arena already its own). Left: nothing unless Duff asks.
4. **Boot:** done Nov 13 (title in 9.3 s on throttled 4G, was 19.9 s). See the Web packs note above.
5. **Balance re-check** after the playtest (gates 45-65, wait drain floor 40).
History of everything built: `TRACKER.md` (newest first).

## Commands (cloud sandbox)
- Godot: 4.5-stable Linux zip from GitHub releases → `/usr/local/bin/godot`. Fresh clone: `godot --headless --path . --import`
- **Stale imports (Nov 17):** `--import` trusts the local filesystem cache, and a changed `.import` param (quality,
  mode) never re-triggers an import whose source md5 still matches. Sandbox renders then show old art (a porch pirate
  as four tiny 1x guys in 3D). Fix: `rm .godot/editor/filesystem_cache10`, delete `.godot/imported/<file>-*` for any
  file whose params you changed, `--import`, and commit the new `.godot/imported` files (CI ships the committed ones
  when md5s match).
- **CI runs test_daily too (Nov 19):** build.yml's test job fails unless it prints `ALL PASS (0 failed)`, so a red suite no longer ships.
- **Tests (before every push):** `XDG_DATA_HOME=/tmp/xdg_x godot --headless --path . --script tools/test_daily.gd`
  must print `ALL PASS (0 failed)` with no `SCRIPT ERROR`; then `git checkout -- .godot/exported`.
- Soak (30 days, every system through real code, ~10+ min):
  `XDG_DATA_HOME=/tmp/xdg godot --headless --path . --fixed-fps 30 --script tools/soak.gd -- --seed=1` (add `--lazy` for the rent/upset paths)
- Smoke (what CI runs): `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
- In-engine renders: `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- <id>`
  (ids: a boss arena, `bounty:sendback`, `gala:husk`, `move:coupon:storm:22`, `waffle`, `title`, `home`, `hint`, `at:X,Y`) → `/tmp/qa/`. Copy keepers into `docs/renders/`.
- Phone onboarding render: `res://tools/touch_shot.tscn` + `python3 tools/touch_sheet.py` (forces touch mode).
- UI audit (every menu + minigame, touch mode): `res://tools/ui_audit_shot.tscn` + `python3 tools/ui_audit_sheet.py <tag>`
  -> `docs/renders/ui_audit_<tag>.png`. Play objects use `prop()` / `prop_circle()` (minigame.gd -> UiStyle), never raw
  `draw_rect` fills.
- Web boot test (needs web export templates in ~/.local/share/godot/export_templates/4.5.stable): export Web to
  /tmp/bw, `tools/make_extra_pack.gd -- /tmp/bw/extra.pck`, `gzip -9 -k -n /tmp/bw/index.wasm`, then
  `python3 tools/web_boot_test.py /tmp/bw 8832 after` (headless Chrome, throttled 4G, prints seconds + bytes).
- Arena walls: `godot --headless --path . res://tools/arena_wall_check.tscn`
- After swapping art: `touch` the files, then `godot --headless --path . --import`.
- CI status: `gh api repos/duffpowell-commits/duffquest/actions/runs?per_page=5` (`gh` GraphQL is blocked; the
  Actions secrets API is blocked too, so secret names can't be listed from a session).

## Art pipeline
- House style C: `docs/art_direction/STYLE_LOCK.md`. Duff always has both tattoo sleeves + fox neck piece (`docs/duff_look.md`).
- **Duff's hands (Nov 18, HARD, Duff: "so that the mistakes stop happening"):** LEFT = eye mandala (sun spikes run onto the
  finger backs) + finger dots, NO RING (Duff Nov 18: "Take the ring off"); RIGHT = calligraphy "This Red / Right Hand / Points Me / South" in RED ink, blended into the skin (Duff Nov 18: "blend the right hand tattoo and make the ink red"). Copy the masters in
  `docs/ref/duff/hand_*.png` (photos `photo_*_hand_*_2026-11-18.jpg`, sheet `hand_tattoos_canon.png`), never invent. Any new or
  re-made Duff sprite sheet: `python3 tools/hand_tattoos/stamp.py <sheet>` then `tools/hand_tattoos/atlas.py`. Stills: `tools/hand_tattoos/still_fix.py`
  (per-still config); finished videos/GIFs: `tools/hand_tattoos/video_patch.py IN OUT`. All art matched Nov 18: `docs/reviews/hand_tattoo_audit_2026-11-18.md`.
- **Fully automatic art pipeline (Nov 10), no Duff steps:** Canva `generate-image` -> put each media id full-bleed on
  its own 1920x1080 page of one Canva design (`edit-design` insert_fill, commit) -> `export-design` png -> Zapier
  Google Drive "Upload File" (connection `023ae0fb-19cc-8509-b28e-979de3a98f75`, pass it as connection_id) with the
  export URL into Drive "97 Gemini art drops" (folder id `1kwe88L_hV7qM_-It2I8n6ZRTMchYoFT4`) -> Drive connector
  `download_file_content` (spills to a tool-results JSON file; decode `content` with python, don't read it into
  context). The sandbox itself can't fetch Canva export URLs; Zapier can. Export links expire in hours: re-export.
- Backdrops + loading screens: `tools/backdrop_import/import_backdrops.py <dir>` (1280x720, manifest "s": 4, then set
  `compress/mode=1` in the .import and reimport). Check: `res://tools/backdrop_shot.tscn` + `tools/backdrop_sheet.py`.
- Arenas: `tools/arena_import/import_arenas.py`. Title (Nov 15): `bg_title` is Duff on the porch (Canva restyle of Duff's own concept, ref `docs/art_direction/refs/title_porch_duff_ref.png`, master Drive `bg_title_porch_v1.png`); the title card flanks its buttons left/right so he stays in view (`card.gd`, backdrop "title"). `tools/title_compose.py` is the old kitchen title, retired. Big HD art ships lossy (`.import` mode 1).

## House rules
- GitHub main only. Never force push. `git fetch` before starting and before pushing. One session per repo at a time.
- Push after every chunk of work; merge to main at the end of every milestone (no work left on a branch).
- Up to three milestones per session; update this file + `TRACKER.md` after each.
- Run the tests before every push. Show real engine renders for visual decisions; save them in `docs/renders/`,
  don't paste piles of images into chat.
- Duff is phone-only (Godot Android editor): GDScript only, no desktop-only tools or steps.
- No keys or tokens in the repo, commits, logs or chat. Duff sets secrets himself.
- Netlify credits are spent; builds go out via the `dev` release and itch.

## Layout
- `game.tscn`/`main.tscn` → `scripts/main.gd` (overworld, menus, dialogue, arenas; the biggest file).
- `scripts/minigames/`, `scripts/waffle.gd` (Waffle Haus shift), `scripts/boss.gd`, `scripts/daily.gd`.
- `data/cast.json` every real/parody name (`{key}` tokens). `scripts/art_manifest.gd` sprite/backdrop map.
- `tools/` tests, soak, render shots, art importers. `docs/renders/` renders. `docs/reviews/` reviews.
