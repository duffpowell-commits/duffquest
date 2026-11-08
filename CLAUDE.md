# Duff Quest

Comedy RPG about Duff's real life in Omaha: keep Madison happy, pay the rent,
work the line at the Twisted Fork, fight exes and porch pirates. Godot 4.5, GDScript, 640×360
landscape (HD chibi pixel art since Nov 7; was 480×270). Owner: Duff. Read this first; it is the handoff between sessions.

## Where things stand
- **Next milestone: see `QUEUE.md` NOW** (Nov 8: M7 backgrounds waiting on Place: `grok_art/requests/REQUEST_M7_backdrops.md`; M8 menu style done).
- **Other agent: "Place"** (Duff's art agent, Cursor/Grok side) owns art: it is redrawing the outfit
  sheets, Waffle Haus sign, bus-stop sign, cats, extra lawn props, and making all 17 bosses. It hands
  drops over in `grok_art/<date>-<name>/` with a HANDOFF.md; Claude wires them in. Code is Claude's.
- **Source recovered Nov 7, 2026.** The game was built elsewhere (Grok) and only builds survived
  (Windows zips v0.2–v0.10.1 in Duff's Drive; web build at
  https://lighthearted-custard-a79ec2.netlify.app). This repo was rebuilt from that web build's
  `index.pck` (Godot 4.4.1) with `tools/recovery/`:
  - `detok.py` turns compiled scripts (`.gdc`, binary tokens) back into GDScript. Original
    **comments are gone**; line layout and indentation are rebuilt from the token line/column maps.
  - `recover.gd` (run with `--main-pack`) writes `project.godot`, textures as PNG, music as OGG
    (rebuilt from Godot's packet data), and dumps QOA sounds that `qoa2wav.py` decodes to WAV.
  - `main.tscn` was one node + script, rewritten by hand.
- Proof: all 61 scripts parse; the title screen matches the original pixel for pixel
  (`docs/renders/recovery_title_original_vs_rebuilt.png`); scripted playthrough (new game, intro,
  walk, pick up an Ensure, phone) runs clean (`docs/renders/recovery_smoke_playthrough.png`).
- Original Windows-build version history is not in git (only the final state).
- Lethemoor is Duff's active game; Duff Quest is the side project. Chaos is paused.

- **Dialogue voice done (Nov 7):** 436 narration lines across 31 scripts rewritten as Duff telling
  the story at the bar, **present tense** (Duff's call). Guide: `docs/voice.md`. Left alone on
  purpose: other characters' lines (Madison, bosses, NPCs), combat barks, texts, UI, quiz/word lists,
  Madison's show-and-tell. Applied with `tools/apply_rewrites.py` (rejects changed `{tokens}` /
  `%d` codes, raw quotes, >1.5x length, literals used elsewhere). Render: `docs/renders/dialogue_voice_smoke.png`.
  Unverified: whether any longer toast lines clip on narrow screens. Look for it when playing.
- **Dialogue polish (Nov 7, later):** 117 lines reworked to cut the storyteller tics ("So..."
  68x -> ~10, "goes," / ", right?" / "Then" mostly gone), punchier originals restored for quick
  popups. Rules added to `docs/voice.md` ("Tic budget"). Keep to them.
- **HD art merged (Nov 7):** `duffquest_hd_project.zip` (Duff's Drive; made outside this repo
  from the v0.10 pck) ported onto main without touching gameplay: 110/131 sprites and backdrops
  replaced (chibi Style A), viewport 640×360, `UI_SCALE` 2.0, camera smoothing off, pixel snap,
  `scripts/hd_presentation.gd` + `shaders/hd2d.gdshader` (LDR bloom/vignette, warm tint, window
  and lamp lights), soft contact shadows in `art.gd`. Its notes: `docs/hd/`. Renders:
  `docs/renders/hd_art_merged_smoke.png`, `hd_vs_original_neighborhood.png`.
  Claude's review: much cleaner than the old art but generic. Same cream houses, lollipop trees,
  empty grass, pale low-contrast palette, Seen Cafe reads as a clinic. Smoke only covers
  outdoors + phone; interiors, combat and bosses not eyeballed yet.
- **ART DIRECTION CHANGED (Nov 7, evening): no longer EarthBound.** World + character sprites:
  modern high-detail pixel art like **Sea of Stars** (saturated, warm sun, soft coloured shadows,
  lush detail), same 64 px 4×4 sheet format. Dialogue portraits + boss intros: bold cartoon like
  **Hazbin Hotel** (thick tapered ink lines, angular shapes, exaggerated faces, flat cel shading;
  humans, not demons). Keep it bright and sunny, opposite of Lethemoor. Prompts: Drive doc
  "DuffQuest — Style bible + Grok prompts" (https://docs.google.com/document/d/1lmADUpw6NO0A_rvmwdox_t2oJoh8yZVLc1AXliRUwnE/edit); capability test doc updated to match.
  **Solved (Nov 8): HD dialogue portraits.** Root scene is now `game.tscn` (`scripts/game.gd`): the
  pixel game (`main.tscn`, unchanged) renders at 640×360 in a SubViewport (nearest, snapped), and
  `scripts/hd_portrait_overlay.gd` draws the cartoon portraits on a CanvasLayer at the screen's real
  resolution over the HUD's portrait box (`project.godot`: main scene `game.tscn`, stretch
  `canvas_items`). `Art.hd_enabled` switches the HUD's old pixel portrait off. Moods:
  `Art.hd_mood()` maps to cells 0 happy / 1 deadpan / 2 furious (Duff: neutral+tired -> deadpan,
  ANGRY_WORDS -> furious; Madison same order as before; Octavia: giggle -> happy, WAIL_WORDS ->
  furious; Brittany lines `Brittany: ...` now get her portrait). Duff's shades gag = dark band drawn
  over the HD eyes. Touch input verified through the SubViewport (simulated tap on A advanced
  dialogue). Smoke now boots `game.tscn`. Check tool: `tools/portrait_shot.tscn` -> all 12 faces;
  render `docs/renders/hd_portraits_dialogue.png`. Tools that need the raw world (`map_shot`) still
  boot `main.tscn` directly.
- **Grok art drop (Nov 7):** new files in `grok_art/2026-11-07/`; see `grok_art/NEXT_STEPS_FROM_GROK.md`. Duff is the only playable character. Board 2 is the world style reference.
- **Art personality pass (EarthBound-era brief, partly superseded):** Duff makes art with Grok. Brief + prompts:
  `docs/art_brief.md` (also a Google Doc "READ ME FIRST - Grok prompts" in Drive folder
  **DuffQuest Art Inbox**, with `reference_current_HD.png`). One Drive folder per design, three
  options (A/B/C) each: 00 Style board (pick first), 01 Storefronts (13 buildings, one folder
  each), 02 Trees, 03 Street clutter. Duff marks winners with a star in the filename or says so.

- **Grok capability test (Nov 7):** Doc "DuffQuest — Grok capability test" in Drive folder
  DuffQuest Art Inbox (https://docs.google.com/document/d/1ay5y-iWh__M8sJx4JbcHVWp0WvOMgoi8g2gFnHzAtC4/edit).
  Tests D1–D7 (4×4 sheet in the game's exact format, Duff upgrade, DBZ combo, hurt, portraits,
  sign spelling, show-off). Results go in Drive subfolder **99 Grok capability test**
  (`d1_try1.png`...). Attach `reference_duff_sheet.png` (inbox) = `assets/art/duff_home.png` on
  magenta. When Duff says it's in: pull, score (rubric in the doc), make GIFs, fill the doc's
  results table, then write the real design prompts around what passed.
- **Sheet format:** humanoid sheets are 256×256, 4×4 cells of 64; rows down/up/right/left;
  cols stand, step A, step B, attack (`art.gd`: `WALK = [1,0,2,0]`, col 3 = attack).
- **PR #2 (`cursor/add-duffquesthd-7d71`, Cursor):** adds `duffquesthd/` = the HD zip as a
  separate Godot 4.4.1 project + 42 MB web build. Its art is byte-identical to main (131/131);
  its dialogue is the OLD pre-voice text (40/40 sampled lines) and it lacks the walking fix.
  Claude recommends closing it unmerged; Duff said "not yet" (Nov 7). Don't merge without asking.

- **`grok_art/` (Nov 7):** drop folder for Grok designs (never ships), README has rules + log.
  First in: `duff_portraits.jpg` (Duff's cartoon portraits, approved look). **v2 approved** (`duff_portraits_v2.jpg`,
  from his photo: dirty-blond undercut/ponytail, ear spikes, fox neck tattoo, black tee). Cut with
  `tools/import_portrait.py` -> `assets/art/portraits_hd/duff.png` (3×512 cells, transparent).
  **Next:** native-res dialogue layer so these keep their lines, then swap them in for `portrait_duff`.
  The walking sprite should be updated to match (undercut/ponytail, black tee).

- **Production list (Nov 7, made by another agent):** Google Sheet "DuffQuest — Full sprite list
  (Sea of Stars + Hazbin)" https://docs.google.com/spreadsheets/d/1nQ9h_KqccoSbITQw3A6a8Oh5zX7YyHh33gvkr1L62Aw/edit
  223 rows: all 131 manifest ids + 92 new (59 HD portraits, 17 boss splashes, 13 storefronts, trees,
  clutter, style board), each with a ready-to-paste Grok prompt (column F), priority, status.
  Tab 1 holds the approved likenesses (Duff, Madison, Brittany, Octavia) and open questions.
  Style boards 1–3 are in `grok_art/2026-11-07/`; **Duff picked board 2**. Treat this sheet as the art to-do list.
- **Approved cast portraits (Nov 7):** PR #3 (Cursor, merged) put 4 green-screen sheets in
  `duffquesthd/portraits/` (Duff v3 with jacket, Madison, Octavia, Brittany). Cut with
  `tools/import_portrait.py` (now: equal-slice fallback + keep-largest-island) ->
  `assets/art/portraits_hd/{duff,madison,octavia,brittany}.png`, 3×512 cells each
  (happy / deadpan / furious). Not wired in yet: needs the native-res dialogue layer.
  Brittany is marked **redo** in the sheet (same face template as Madison). Octavia's pink furious
  eyes are **intentional, keep them** (Duff). Sheet edited Nov 7: boss splash prompts reworded +
  every boss (16 sprite rows, 17 splashes) must look unlike all other bosses and regular enemies
  (Duff's one requirement); legacy 96 px portrait rows marked skip.

- **Map decision (Nov 7): Option A + tiles.** Keep the straight-on camera (Sea of Stars itself is
  straight-on; board 2's diagonal is NOT the target, only its palette/detail). Rebuild the outdoor
  map as a TileMap from reusable tiles instead of the single `map_outside` painting, so the world
  can grow; keep the `buildings` footprints, doors and collisions working. Isometric (`scripts/iso/`)
  rejected: it would need diagonal facings on every character sheet. Sheet updated: all pixel rows
  say "style_board_2 look, NOT its diagonal camera"; storefront/tree/clutter rows say straight-on,
  midday sun; new rows `new_ground_textures` (6 seamless 512 swatches), `new_ground_edges`
  (curbs, lines, transitions), `new_fences_walls`.

- **Done (Nov 7, late): new character sheets in.** `tools/import_sheet.py` keyed Grok's
  `grok_art/2026-11-07/*_sheet_sos_256.png` into `duff_home`, `ch_madison`, `ch_brittany`, `ch_jen`
  (feet dropped 3 px to the y=60 origin). Outdoor outfits followed Nov 8 (below).
- **Done (Nov 7, late): tile ground for the town.** `tools/import_ground.py` cuts Grok's ground
  sheets into `assets/art/ground/ground_atlas.{png,json}` (64 px tiles = 32 world units; transition
  tiles classified by their corner pixels: all 4 pairs × 12 masks). Layout = `data/town_ground.txt`
  (one letter per grid corner, dual grid; first written by `tools/gen_town_ground.py` to match the old
  roads; hand-edit from now on). `scripts/ground.gd` builds and caches the texture at runtime;
  `main.gd _draw_outside` draws it, then `map_objects` (old buildings/trees/props cut out of
  `map_outside` by `tools/extract_map_objects.py`; lamp posts + picket fence were too thin and are
  gone until Grok's clutter sheet). Collisions, doors, NPC spots untouched. Renders:
  `docs/renders/town_ground_before_after.png`, `town_ground_full.png`, `town_ground_closeup.png`.
  Whole-map shot tool: `tools/map_shot.tscn` (zooms out, hides HUD). Layout rules: only pairs Grok
  drew can touch (sidewalk/asphalt, grass/sidewalk, grass/asphalt, dirt/grass); no diagonal pairs;
  that's why every road has sidewalks. Brick and gravel have no transitions yet (fills only).
  **Decided (Duff): keep the sidewalks / pavement.** The real block is urban, not lawny; don't add
  grass to "fix" it. Grass colour (darker olive vs old bright lawn) not raised as a problem.

- **Done (Nov 8): Grok storefronts placed.** `tools/import_storefronts.py` keys the 13 PNGs in
  `grok_art/2026-11-08-storefronts/` into `assets/art/sf_<name>.png` (size = footprint ×2, building
  dropped so its lowest pixel sits on the footprint's bottom edge), registers them in both manifests
  and clears the old painted buildings out of `map_objects.png`. `buildings` entries have an `"art"`
  key; `_draw_outside` draws them (shut places tinted grey instead of a dark box). `_art_rect()` =
  the sprite's opaque area: walls use it (top/sides; bottom stays the footprint edge so doors and
  story triggers still work), labels too. Storefronts carry their own signs, so floating names only
  remain on HOME / NEIGHBOR; CLOSED plaques float above the roof; pharmacy cross + grocery slogan
  overlays removed. Renders: `docs/renders/town_storefronts_full.png`, `_closeup.png`, `_before_after.png`.
  Known: some footpaths (Kwik, Mining Rig) don't line up perfectly with the new doors; trees,
  clutter, lamps, fences are still the old art / missing until Grok's sheets.

- **Done (Nov 8): visual QA pass.** Tools: `tools/qa_shot.tscn` (boots `game.tscn`, new game, then
  long dialogue/toast, home, street combat, Kwik/pharmacy/grocery/plasma, all 17 bosses intro +
  fight, gala; shots to `/tmp/qa`) -> `python3 tools/qa_sheet.py` -> `docs/renders/qa_ui.png`,
  `qa_boss_intro.png`, `qa_boss_fight.png`. `godot --headless --path . --script tools/text_fit.gd`
  wraps every 25+ char literal with the HUD's font/width and lists overflows in `docs/text_fit.txt`
  (now 0 of 1387). "Clips on narrow screens" is not a thing: stretch is canvas_items + keep +
  integer, so narrow phones letterbox, the boxes never shrink.
  Fixed: bounty/gala boss lines ("The Allergy Liar: ...") showed DUFF's portrait (unknown speakers
  default to Duff; `Art.boss_names()` now excludes every boss); cologne line ran into the
  "E / A >" prompt (shortened); pharmacy buttons clipped (labels shortened).
  Still open (art, not code): 5+ bosses share the same grey-haired sprite (bozos, fences, bdaydad,
  regular, sendback) = breaks Duff's "every boss unique" rule until Grok's boss sheets land; Duff in
  arenas/outdoors is still the old outfit art; home interior + all shop/minigame screens are the old
  flat art; enemy barks overlap when 3+ enemies bunch up; grocery aisle labels sit on the shelves.

- **Done (Nov 8): Duff's outfits outdoors (M1).** Cursor PR #8 dropped Grok's outfit sheets in
  `grok_art/2026-11-08-duff-outfits/`; the 10 `duff_<apron|clogs|sleeves|coat|dad>_<red|black>` sheets
  were keyed in with `tools/import_sheet.py` (drop 3). `duff_shades.png` redrawn by
  `tools/make_shades.py` (the old overlay sat on the new hair; positions measured from the eye whites).
  Check tool: `tools/outfit_shot.tscn` -> `python3 tools/outfit_sheet.py [old_dir]` ->
  `docs/renders/duff_outfits_ingame.png`. Still old art: `duff_dress`, `duff_roll_*`, `ch_duff_suit`.
  Review (fresh agent) top issues, all Grok art, logged in `tasks/todo.md`: step frames messy (side
  legs mush, no head bob); attack col is a walk pose + pan, no wind-up; clogs ≈ home outfit and the
  dark outfits melt into asphalt; speckled dark outline around the hair is in Grok's source, not the keying.
- **Repo rules docs (Nov 8):** `docs/PITCH.md` (pillars, not-in-game, kill criteria), `QUEUE.md`
  (work only on NOW), `tasks/todo.md`, `tasks/lessons.md`. Read QUEUE first.

- **Done (Nov 8): street dressing (M2).** Cursor PR #7's drop (`grok_art/2026-11-08-street-dressing/`)
  -> `tools/import_dressing.py` -> `assets/art/sd_*.png` (trees/props native; fences scaled 0.375, one
  segment = 39 world units). Placements: `data/town_dressing.json` (hand-edit; `p` = ground point,
  `s` scale, `wall` size, `tree`). `scripts/dressing.gd` loads/draws; `main._draw_outside` y-sorts
  storefronts + dressing behind Duff; `scripts/dressing_front.gd` (z 1 child of main) draws what's in
  front of him and fades it to 45% where it covers him. `trees` is now derived from the data.
  `map_objects.png` only holds the old bus-stop sign now. After editing the data run
  `godot --headless --path . --script tools/dressing_check.gd` (walls vs doors/NPC/bus/Ensure spots).
  Renders: `docs/renders/street_dressing_before_after.png`, `_full.png`, `_depth.png`
  (`tools/dressing_shot.tscn` + `tools/dressing_sheet.py`).
  Review leftovers (logged in tasks/todo.md): NPCs/enemies/cats behind a tree aren't faded (only Duff);
  old flat art next to the new (Waffle Haus pole sign, bus-stop sign, cats); right-side lawns still big
  and empty; political_sun_sign unused on purpose.

- **Done (Nov 8): combat feel (M3).** `scripts/juice.gd` (node "Juice", child of main): hit-stop =
  `Engine.time_scale` 0.05 for real-time ms (light 70 / heavy 85 / kill 120, +20 boss), trauma shake on
  `cam.offset` clamped to the camera limits plus a small zoom punch (so the arena, which exactly fills
  the screen, still kicks), skipped while paused or during `combat.cinematic`; resets time_scale on exit.
  `combat.hit(..., feel=true)` calls `juice.impact`; beam / brulee / tempura ticks pass `feel=false`.
  Heavy = finisher heat, `"crit"` (main now passes it for Cleaver/Golden crits) or dmg >= 10. NOT
  `"flip"` (the starter spatula's every-swing special). `combat_fx`: spark bursts, ring on heavy,
  bigger popping numbers (9/12 px). Check tool: `tools/combat_shot.tscn` (movie writer) ->
  `python3 tools/combat_sheet.py` -> `docs/renders/combat_feel.png/.gif`. Note: in movie-writer runs
  the hit-stop is real-time, so frozen frames don't show; judge it on a device.
  Not done: knockback/launch tuning, enemy hit poses (need art), shake toggle (IDEAS).

- **Done (Nov 8): see-through trees for everyone (M4).** `dressing_front.gd actor_boxes(m)` = body boxes
  for Duff, live enemies/bosses (x1.45, skipped while a boss is hidden so trees don't give it away),
  raccoons, cats, Brittany (not at night), the inspector; `Dressing.draw_layer` fades any front-layer item
  covering any box (`SEE_THROUGH_ALPHA` 0.45). `fade_others = false` restores old Duff-only behaviour.
  Check: `tools/actor_fade_shot.tscn` -> `python3 tools/actor_fade_sheet.py` ->
  `docs/renders/see_through_actors.png` (pirate behind oak + pine, raccoon + cat behind maple; before/after).
  Known: the front layer is chosen by Duff's feet, so an enemy in FRONT of such a tree draws under it
  (faded now, so visible). Proper fix = y-sort; logged in tasks/todo.md, only if it shows in play.

- **Done (Nov 8): all 17 bosses wired (M5).** Sheets: `grok_art/2026-11-08-outfits-v2-and-boss-attacks/boss_attacks/`
  (= PR #12 sheets with Place's unique attack column) -> `tools/import_sheet.py ... --drop 1` (Grok feet y59,
  game y60). Portraits: `grok_art/2026-11-08-bosses/new_portrait_<b>.png` -> `tools/import_portrait.py` ->
  `assets/art/portraits_hd/<b>.png` (cells 0 smug / 1 shocked / 2 enraged). `Art.boss_speaker(line)` maps a
  "Name: ..." line to the boss kind; `portrait_for` returns it (HD only; no pixel boss portraits). Mood
  (`Art.hd_mood`): defeat line -> shocked, rage line or a shouty line (`_shouty`: ALL-CAPS 4+ letters or two
  `!`) -> enraged, else smug. Rage is a mid-fight bark, so enraged mostly shows on shouty intros.
  Intro card: **Duff picked Place's burst cards** (Nov 8). `tools/import_boss_intro.py` downscales
  `new_boss_intro_<b>_burst_preview.png` to opaque 960×540 `assets/art/boss_intro/<b>.png` (~4 MB;
  `--keyed` = the old cut-outs). `hd_portrait_overlay.gd` shows it while the boss's exact intro line is up
  (`Art.boss_intro_for`): full-bleed, slides in from the right 0.28 s, lifted `CARD_LIFT` 0.13 so every
  name (lettering runs to 70% of the card) clears the dialogue box (starts at 60%), ink letterbox bar
  underneath; drawn around the box, never over it. Renders: `docs/renders/qa_boss_intro.png`,
  `qa_boss_fight.png`, `bosses_before_after.png` (old / new / new attack, facing right).
  **Gotcha:** after replacing PNGs run `godot --headless --path . --import` before any render, or Godot
  serves the old cached textures (and new files don't exist to it).
  Not done: attack poses are single key frames (no wind-up/recovery); hitboxes and projectile anchors not
  re-tuned to the new silhouettes; burst-preview splashes unused (keyed versions shipped).

- **Done (Nov 8): Duff outfits v2 (M6).** 11 sheets from `grok_art/2026-11-08-outfits-v2-and-boss-attacks/outfits/`
  keyed with `tools/import_sheet.py ... --drop 1` (v2 stands on y59; NOT the old drop 3). Stand frames are pixel-
  aligned with v1; steps bob the head 1 px; attack = frying-pan swing that lunges the head (front -2, right +3,
  left -3 px). `tools/make_shades.py` now applies BOB/LUNGE per column; verified 0 uncovered eye-white px.
  Renders: `docs/renders/duff_outfits_ingame.png` (old sheet stand frame beside each),
  `duff_outfits_v2_frames.png` (facing right, 4 frames, old vs new). Still old art: `duff_dress`, `duff_roll_*`,
  `ch_duff_suit`. One key attack pose, no recovery frame.

- **Done (Nov 8): menu style (M8).** Duff: "menus need looked at, unless you can copy the style" -> copied
  Place's boss-card look in code. `scripts/ui_style.gd` (autoload **UiFonts** installs fonts; scripts use
  `const UiStyle := preload(...)` statics): palette INK/CREAM/PANEL/GOLD/PINK/TEAL; `panel()` (hard ink shadow,
  flat plum fill, thick ink border), `label()` (cream display text, ink outline via draw_string_outline),
  `button()` (saturated fill, top highlight, ink border, hard shadow; old grey default -> teal), `round_button()`
  (touch A/B/S/G), `burst()` (sunburst rays). Fonts (OFL, `assets/fonts/`): **Baloo 2 ExtraBold** = display
  (closest to the cards' lettering), **Nunito ExtraBold** = body and `ThemeDB.fallback_font` (every
  `draw_string` in the game picks it up). Static weights cut from Google's variable fonts with fontTools
  instancer (name table still says ExtraLight; glyphs are 800). Applied: HUD panels/bars/dialogue box,
  every minigame/shop button + header (gold caption tab, ink title) + flash box, touch buttons, `card.gd`
  (all menu cards: title, bus stop, results): pink heading band, burst background when no backdrop,
  panel behind text, line heights from the real wrapped size (fixed 10/line overlapped with Nunito).
  `tools/text_fit.gd` now measures with the new font (0 overflow). Renders: `docs/renders/qa_ui.png`,
  `menu_style_before_after.png`, `menu_style_title.png`. Not restyled yet: phone screen, gear/settings
  screens' own art, combat UI numbers, per-minigame custom panels (they draw their own rects).

## Next (Duff's asks)
- When Grok art lands in the Drive inbox: pull it (subagent; Drive returns big base64), clean
  to the grid (magenta key, nearest downscale, palette quantize), composite storefront facades onto
  `assets/art/map_outside.png` at the `buildings` footprints, swap trees/props, render before/after.
- Graphics update, flesh out the world, possible Google Play release (from Duff's plans).
- Combat goal: action RPG like the GBA Dragon Ball Z games.

## Layout
- `main.tscn` → `scripts/main.gd` (the whole overworld, menus, dialogue; ~the biggest file).
- `scripts/minigames/` fryer, pickles, pharmacy, ending, card, etc.
- `data/cast.json` every real name and parody name (`{key}` tokens in code). `data/*.txt` word lists.
- `assets/art/manifest.json` sprite sheet map; `assets/iso/` iso map + objects; `assets/audio/`.
- `tools/smoke.tscn` scripted playthrough used by CI. `tools/recovery/` the recovery kit.

## Commands
- Godot in the cloud sandbox: download the 4.5-stable Linux zip from GitHub releases with curl,
  move to `/usr/local/bin/godot`. Fresh clone: `godot --headless --path . --import`.
- Parse check: `godot --headless --path . --check-only --script <file>`
- Smoke test (before every push):
  `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600`
  then look at the frames.
- CI: `.github/workflows/build.yml` parses scripts, runs the smoke test, exports web + debug APK,
  and refreshes the **`dev` release** on every push to `main`:
  https://github.com/duffpowell-commits/duffquest/releases/tag/dev
  `gh` GraphQL is blocked in Claude sessions: use `gh run ...` / `gh api repos/...`.

## House rules
- One Claude session per repo at a time. `git fetch` before starting and before pushing.
- Duff is phone-only (Godot Android editor). GDScript only, no desktop-only tools.
- Push after every chunk of work; merge to `main` at the end of every milestone.
- Up to three milestones per session; update this handoff and merge after each.
- Save renders to `docs/renders/`, don't paste lots of images into chat.
- Netlify free credits are spent (Chaos used them); test builds go out via the `dev` release / itch.
