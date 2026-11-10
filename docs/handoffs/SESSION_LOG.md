# Duff Quest session log (moved out of CLAUDE.md, Nov 10 2026)

Newest first. History only: CLAUDE.md is the live handoff, TRACKER.md the Built / Next / Could improve list.

## Where things stand
- **TRACKER.md** (repo root) is the running Built / Next / Could improve list. Update it every milestone with this file.
  **GitHub (`duffpowell-commits/duffquest`) is the primary home again (Nov 10, Duff); GitLab is the backup.**
  `.github/workflows/mirror_gitlab.yml` mirrors main to GitLab on every push (needs repo secret `GITLAB_TOKEN`).
  Push to GitHub; GitLab follows. Its `.github/workflows/build.yml` already uploads main to itch
  (needs repo secret `BUTLER_API_KEY`). GitHub and GitLab histories are unrelated (GitLab was a re-import); GitHub's
  main tree = our 9148e34, so join with a merge commit (parents gh/main + main, our tree), never a force push.
- **Nov 10 ~18:30: title screen shows the real Duff** (branch `title-tattoos`, Duff's note: missing tattoos, wrong style).
  `tools/title_compose.py` builds `bg_title.png` (now 1280x720, manifest `s` 4) from the style-C portrait
  (`portraits_hd/duff.png`, grin: both sleeves, fox neck piece, beard, bun) in a flat comic panel over the in-game
  kitchen (`bg_kitchen`) with a navy/teal sunburst. Before/after: `docs/renders/title_tattoos_before_after.png`.
  Not pushed yet: the GitLab token was revoked; push needs fresh access.
- **Nov 10 evening: IGN review fixes merged** (branch `review-fixes`). (1) **Phone-first controls:** `Cast.touch` +
  `Cast.TOUCH_WORDS` rewrite keyboard hints ("PULL (Space)" -> "PULL IT") in minigames/buttons while the touch layer is up;
  touch-only "How to play" (`TITLE_HELP_TOUCH`); buttons radius 9, outlined captions, A says next / talk/use / bonk.
  (2) **Gentler week one:** first Monday bills half (`first_week_prorate()`), the Fork takes shifts the first weekend
  (`first_weekend()`, days 2-3); intro line says so. (3) **Real boss arenas:** the six identical placeholder rooms
  (alley, ghoster, djvape, crypto, willnot, waffle) are painted in code, `tools/arena_paint/paint_arenas.py` (stand-ins
  until M7 art); sheet `docs/renders/arenas_painted_sheet.png`, in game `docs/renders/arenas_ingame.png`
  (`arena_shot -- bounty:sendback` renders the alley). (4) **Gala bug:** invite lands the morning after the ending
  (`gala_due()`), not 12 dead days later on day 24; soak updated (seeds 1 + 4 lazy clean, gala day 13/14). test_daily 112/112. CI itch push works (BUTLER_API_KEY set); builds now labelled with `CI_COMMIT_SHORT_SHA` (CI image has no git).
- **Nov 9 night: money paths tested.** `_money_path_checks` in `tools/test_daily.gd`: bus pass, minivan, brokerage buy/sell (wealth conserved), 60 market weeks (finite prices), college fund caps, symphony date gating + result. All passed first run (no bugs). Doc drift fixed (reference.md section 9 lists what is still open).
- **Nov 9 night: itch deploys from GitLab CI.** `deploy_itch` runs on main; needs CI/CD variable `BUTLER_API_KEY` (masked, protected), else logs `SKIP` and passes. CI installs python3 for lossy imports. GitLab account is verified; main pipelines run (test job ~3 min). This sandbox can't reach itch.io. See `HANDOFF.md` section 3.
- **Nov 10 ~04:30: gala exes' sprites + IGN review** (branch `gala-exes-sheets`): Canva face-ref uploads are blocked for these sessions, so the 4 gala exes' `ch_<id>` sheets were repainted in code from repo sheets (`tools/sheet_repaint/<id>.py`; bases: old ch_husk, old ch_donald, ch_crypto, ch_gymbro; old sheets in `grok_art/2026-11-10-gala-exes/old/`). Review `docs/reviews/gala_exes_sheets.md`, render `docs/renders/gala_exes_sheets_ingame.png`. Fixed `ch_crypto` side rows (were reversed vs `Art.row_for`). Outside review: `docs/reviews/ign_review_2026-11-10.md` (6.4/10) with a ranked fix list; good source for the next milestone.
- **Nov 9 ~14:45: QA milestone merged** (branch `qa-nov9-evening`): intro rent text = `weekly_base()` ($195); KO x-ray `b_anchor` per boss in `data/knockouts.json` (willnot, dasher = 0, impacts remapped); render `docs/renders/ko_xray_crop_fix.png`. **GitLab CI fails with 0 jobs because Duff's GitLab account isn't verified** (GraphQL failureReason); local `ship_itch.sh` is the gate until he verifies. See `HANDOFF.md`.
- **Nov 9 ~13:10: STOPPING POINT. FULL HANDOFF: `HANDOFF.md` in the repo root (read it first; `docs/HANDOFF_NOV9_PM.md` has same-day detail).** All art is house style C (KO + loading converted). itch `html` channel = `532e95b`, BUT the page still embeds the old manual upload until Duff switches it (see handoff). Logo + page copy in `docs/itch/`.
- **Nov 9 ~09:00: MULTI-AGENT PUSH (session_01V3sbx).** Merged + live on itch (build `bb95ad0`, 56 MB): build shrink 113->54 MB (`tools/set_lossy_imports.py`, run by ship script; HD art ships as WebP), portrait green-halo cleanup (`tools/clean_halo.py`), in-engine cartoon gore on KOs (`scripts/ko_gore.gd`, per-boss `"impact"` key, Settings toggle), screen-shake toggle, grocery labels, footpaths to doors, bark cap + `scripts/barks.gd` (max 2 bubbles, numbers on top), outdoor y-sort of actors + dressing (`dressing_front.gd` rewritten), HUD declutter (one top strip + Tab/tap drawer), Willnot intro QA fix, **all 17 KOs live** (last 6 stills), itch page kit `docs/itch/`. **Gala bosses are now Madison's exes:** Tyler Pivot (husk), Grant Gratuity (bozos), Landlord Lance (fences), Chip Leverage (donald, final). Names in `data/cast.json`; old billionaire art/scripts in `docs/dlc_concepts/billionaires/`; their old cards hidden via `RETIRED_CARDS` (scripts/art.gd) and KOs `live:false` until new art (brief: `docs/gala_exes_art_brief.md`). **JAM:** the itch 2026 Jam bans AI art; DuffQuest can't enter it. Options + ranked list in tasks/todo.md. **Art direction:** comparison A/B/C running (`docs/art_direction/`); pick ONE comic style, then lock it before more images. Gotcha: test_daily prints ALL PASS even on compile errors; ship script now also fails on SCRIPT ERROR. `.godot/editor/` untracked. **Later Nov 9:** soak test (`tools/soak.sh`, 30 days x 6 seeds clean; 2 bugs fixed), phone perf + auto Lite graphics + `ship_itch.sh --web-check` merged; itch build `8ac17f8`. Balance decisions pending in tasks/todo.md (happiness gates strict). **Later still (Nov 9 ~11:30):** gala unlocks story day 24 (`GALA_DAY` in main.gd; soak verifies it). **Art style C locked** (`docs/art_direction/STYLE_LOCK.md`, checklist ST1-ST7 in art_rules.md section 7); canonical Duff face sheet `docs/art_direction/duff_face_sheet.png` = Canva `MAHacL92VLk`, FIRST ref for every Duff image. Gala exes have style-C portraits, lettered cards (`tools/letter_card.py`) and live KOs; `RETIRED_CARDS` empty. Their `ch_<id>` sprite sheets were repainted in code Nov 10 (`tools/sheet_repaint/`). itch build `cac220e`. Gotcha: after merging new art, `touch` the files before `--import` or the tracked cache keeps old art; untracked `*.gd.uid` files can silently block `git merge` (check its exit).
- **Nov 9 07:30: ITCH IS CURRENT (build `7cd1f78`, all art fixes + tattoos + KO sfx).** Full handoff: `docs/HANDOFF_NOV9.md` (secrets in gitignored `.env`; Canva scratch now `DAHabf2Qa9U`). Next: jam submission + itch page polish, title-screen tattoos, in-engine KO blood.
- **Nov 9 (M12): Falcor + Thanksgiving LIVE.** Falcor = the stray Madison feeds (`{stray}` in cast.json), never drawn. Notes on days 3/7/9/11/13. Day 10 wake opens the SUNDAY card (`FALCOR_LINES`, text approved by Duff, quiet `living_night` backdrop): Stay with her (+10 Happiness, morning gone) / Give her some space; saved in `daily.falcor`. Days 11-13: no fussy rolls, a soft wake line each day, Madison's bowl text on day 11. Day 28 Thanksgiving: Fork closed, Waffle Haus, +10 Happiness +20 Energy. Render `docs/renders/falcor_day.jpg` (`tools/wake_shot.tscn -- 9`). test_daily 43/43. **Tests must not touch the real save** (see tasks/lessons.md).
- **Nov 9: DUFF HAS FULL TATTOO SLEEVES.** Every Duff prompt must include the TATTOOS block from `docs/duff_look.md` and attach
  the refs in `docs/ref/duff/` (Duff's real left-sleeve photos + fox-Duff art for placement). Until now prompts only said "fox neck
  tattoo", so the knockout comics, loading screens and sprites show bare arms. Fix list (HD stills DONE Nov 9: all 16 KO/loading images with Duff now tattooed; rules in docs/art_rules.md, reviews in docs/reviews/): 5 shared Duff KO panels
  (stance, slip, fin1-3), 6 x-ray stills (husk, bozos, fences, donald, willnot, ghoster), 7 loading screens (brunch_atlas,
  fryer_nap, gym_spot, octavia_fund, one_trip, plasma_day, raccoon_break), then the Duff sprite sheets (test one first: does a
  Canva edit keep the 4x4 grid?) and `portraits_hd/duff.png`.
- **Nov 9: knockout SFX + button text fit.** 9 original synthesized sounds in `assets/sfx/ko/*.ogg` (`tools/make_ko_sfx.py`, numpy/scipy -> ffmpeg libvorbis, peaks ~-3 dBFS, rerun = same files): whoosh (slip), crack + drone/heartbeat (xray), snap1-3 + boom (finisher panels / white flash), crowd gasp-murmur, jazz walk-off sting (closer). Cue table `SFX_CUES` in `scripts/knockout.gd`, played on the SFX bus (settings volume/mute apply); beds stop when a beat is skipped. Button labels now fit their box everywhere (`UiStyle.fit_text`; fixed the stat points card). test_daily 48/48.
- **Nov 9 (M14): knockout x-rays + dialogue variety (Duff's notes).** (1) The 5 parody B stills were redone WITHOUT Ghoster's still
  as the template (it cloned Duff's two faces + layout into every one, and the x-ray showed a different bone than the hit). Refs
  now: `ko/duff_stance.jpg` + Duff's face sheet + the boss face sheet; prompt names THE HIT, THE X-RAY "at that exact contact point,
  inside the same figure", and EXPRESSIONS for both. Each: own layout, own Duff face, x-ray on the struck bone, matching the `xray`
  text. (2) All 17 knockout scripts: 34 lines rewritten so each strip has its own device (Husk = viewer count, Bozos = package
  tracking, Fences = error popups, Ghoster = timestamps, Willnot = floor forty, Send-It-Back = a ticket, Camper = battery %, Baron
  = talked to as "you"). Rules in `docs/voice.md` ("Knockout strips"). File: `tools/rewrites/ko_variety_m14.json`, applied with
  `tools/apply_ko_rewrites.py` (token + length checks, minimal diff). ko_shot misses Ghoster's finisher frame (the beat ends itself
  before the 100-frame step); his beats sheet reuses the old finisher panel.
- **Nov 9 (M13): parody bosses DONE + LIVE.** Husk, Bozos, Fences, The Donald, Willnot: burst intro cards (`boss_intro/<b>.png`,
  names spelled right), `ch_<b>` sheets, KO stills `ko/<b>_a|b|c.jpg`, `"live": true` in `data/knockouts.json`. Masters in
  `grok_art/2026-11-09-parody-bosses/` (Canva generate-image with refs: face sheet + Ghoster's card / sheet / ko stills as style;
  full-size via scratch design `DAHaZZaEJBs` pages 25-49). Sheets: row 4 = row 3 mirrored (`fix_sheet_cells.py 3,c=2,c:m`; Canva
  drew the left-walk cells facing right). **Gotcha:** B stills made from `ghoster_b` as the ref copy GHOSTER's face into the
  bottom-middle panel; fixed with a Canva edit ("change ONLY the grey face in the bottom-middle panel"). Check that panel on every
  new B still. Renders: `docs/renders/ko_<b>_beats.png`, `qa_boss_intro.png`, `qa_boss_fight.png`.
  Also fixed: `debug_station` goes straight into the station again (M10 put a NEXT STATION card first); `qa_shot` ends any running
  shift between shots and sets `no_loading` (before, every boss shot was a shift card or a loading screen).
- **Next:** the 16 M7 backgrounds (QUEUE NOW); KO stills for coupon, allergy, camper, bdaydad, dasher, baron; Freya's photo -> cat
  scene + Lucifer recolor. Bonds (spec section 5) cut by Duff. Time slots skipped (saved for future games).
- **Nov 9 (M11): fridge calendar + daily events LIVE.** Spec `docs/daily_life.md`. `scripts/daily.gd` (pure logic) + `data/calendar.json` (30 handwritten November days: today card, grid tag, sticky notes from hero/partner/baby/cat1-3; `headline` days block random events) + `data/daily_events.json` (10 weekday + 4 weekend events, 75% of mornings, no repeat within 5 days; effects: energy/happy/money on wake, shift_pay, shift_modes, inspector, walk, spawn). `scripts/fridge_calendar.gd` (HD layer, game.gd) shows after the morning loading screen and from the new **Fridge calendar** spot at home (`FRIDGE_PT`). One headline per day: a random event or calendar headline blocks the old bill roll (`curveball_new_day`). **Weekends: no Fork shift.** Fonts: Caveat (Madison) + Patrick Hand (Duff), OFL, from npm @fontsource (GitHub raw is 403 from the sandbox). Tests: `godot --headless --path . --script tools/test_daily.gd` (33 checks). Renders: `docs/renders/fridge_calendar.png`, `fridge_wake_flow.jpg` (tools `calendar_shot`, `wake_shot`).
- **Nov 9 (M10): shift shuffle + muscle memory.** Full shift: quiz first, other 7 shuffled. `main.station_best` (saved) = best grade per station; an S unlocks **Autopilot (B)** on that station's card. Render `docs/renders/shift_autopilot.png` (`tools/shift_shot`).
- **Nov 9: parody bosses have made-up HUMAN faces** (Duff: duck/TV/lightbulb heads were too much Hazbin imitation; cartoon sheets kept for DLC in `docs/dlc_concepts/`). New portraits_hd for husk/bozos/fences/donald/willnot, drawn against Ghoster's portrait as the style ref. Willnot's gun: shoulder holster. (Cards, sprites, KO stills done in M13.) `import_portrait.py`: bg from top corners, `--min-island` keeps detached props.
- **Nov 8 late (4): Knockouts LIVE for gymbro, ghoster, djvape, crypto, sendback, regular** (beat sheets `docs/renders/ko_<boss>_beats.png`). **Full-size Canva without Duff downloading:** media id -> scratch design `DAHaZZaEJBs` (read-design open_transaction, add_page + insert_fill per page, commit) -> export-design PNG 1680x945 -> curl the URLs. After adding art run `godot --headless --path . --import` or ResourceLoader won't see it. Parody bosses (husk/bozos/fences/donald/willnot) keep names, new original faces: face sheets generated (Canva jobs), Willnot's gun-on-back needs a rethink (Duff).
- **Nov 8 late (3): Knockout cutscene ENGINE + Gym Bro pilot LIVE.** `scripts/knockout.gd` (HD layer, beats from `data/knockouts.json`, `"live": true` per boss; only gymbro so far) hooked in `main.boss_defeated()` -> `knockout_done()`. Stills `assets/art/ko/*.jpg` (Canva, style-fusion prompt in `docs/knockout_cutscenes.md`); missing stills fall back to portraits. Check: `tools/ko_shot.tscn -- <boss>` -> `/tmp/qa/ko_*`. **Loading screens LIVE:** `scripts/loading_screen.gd`, 13 scenes in `assets/art/loading/*.jpg` + captions `data/loading_screens.json`; shown on wake, shift, story/bounty fight, Waffle Haus (`main.show_loading()`, tools set `no_loading`). Renders `docs/renders/ko_gymbro_beats.png`.
- **Nov 8 late (2):** Boss knockout cutscenes for ALL 17 bosses (Baki x Spike Spiegel, Palahniuk narration): scripts done in `data/knockouts.json`, plan + beat template + art list in `docs/knockout_cutscenes.md` (pilot: Gym Bro). Loading screens: 14 captions in `data/loading_screens.json`; 13 Canva scenes generated, waiting on Duff's full-size downloads; engine for both not built yet.
- **Nov 8 late:** Canva sheets in: `ch_gymbro`, `ch_brittany`, new `ch_dolores` (her own sheet; Waffle Haus uses it, `ch_waitress` kept for generic diners). Canva sheets often draw wrong-facing side cells: fix with `tools/fix_sheet_cells.py` before `import_big_sheet.py`. `tools/arena_shot.tscn -- waffle` shows the Waffle Haus shift. Remote is GitLab while GitHub is suspended (see `handoff-duffquest.md`).
- **Next milestone: see `QUEUE.md` NOW** (Nov 8: M7 backgrounds IN PROGRESS, 2/19 in: home + kitchen. Place's next drops: `arena_alley`, `arena_waffle`, `gala`).
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
- **Gemini capability test (Nov 8): Grok is nearly out of usage.** Doc "DuffQuest — Gemini capability test"
  (https://docs.google.com/document/d/13q2fog54B7WVbSIWjhQQzf9AOtz1NRHlV7Q8EThOh0s/edit) in DuffQuest Art Inbox;
  refs + results in subfolder **98 Gemini capability test** (`ref_room_home`, `ref_sheet_duff`, `ref_sheet_boss`,
  `ref_portrait_madison`, `ref_style_board_2`; results `g1_try1.png`...). Tests are real next assets: G1 home redraw
  keeping layout (unlocks all M7 backgrounds), G2 IRON TEMPLE arena + sign, G3 Duff tux sheet edit, G4 Porch Pirate
  sheet, G5 Dolores portraits, G6 kitchen props 4×4, G7 show-off. 2 tries each. When Duff says it's in: pull,
  score (rubric in the doc; G1 = overlay `tools/make_m7_guides.py` boxes), GIFs, fill the results table.
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
  underneath; card AND bar are drawn only in the strips around the box, never over it. Renders: `docs/renders/qa_boss_intro.png`,
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

- **Done (Nov 8): portrait touch-ups (Place PR #21).** Masters copied from `grok_art/2026-11-08-portrait-touchups/`
  into `duffquesthd/portraits/`, re-cut with `tools/import_portrait.py ... --cell 512 --margin 16`: Madison's
  middle face has brown irises; Octavia = giggling / curious / wailing (no adult teeth; pink wail eyes kept).
  Render: `docs/renders/portrait_touchups.png` (old vs new).

- **Done (Nov 8): Palahniuk voice layer (M9).** Duff: keep the narration style, add Chuck Palahniuk's tone.
  Rules + chorus budgets in `docs/voice.md` ("Palahniuk layer"): tone only, never his text; bright/warm
  underneath, no shock content. 22 lines rewritten (`tools/rewrites/palahniuk_m9.json`); 4 choruses kept EXACT
  and rare ("Rent is due. Rent is always due." / "Hell of a girl." / "The body keeps the receipts." /
  "Nobody tips the fry cook."). Monday rent chorus is its own dialogue beat in `pay_rent()`. Fun facts:
  `scripts/fun_facts.gd` (40 real facts, each checked; "legend says" for shaky ones) via `main.next_fact()`
  on 35% of bus/minivan rides and after "So where was I." on load. text_fit 0 overflow (1428). Render:
  `docs/renders/palahniuk_voice.png` (`tools/voice_shot.tscn` + `tools/voice_sheet.py`).

- **M7 backgrounds, drop 1 (Nov 8):** Place PR #25 -> `grok_art/2026-11-08-backdrops/` (`home_interior`,
  `bg_kitchen`, opaque 640×360, same ids). Wiring = copy over `assets/art/<id>.png` (same size, no code), then
  `godot --headless --path . --import`, then check: `python3 tools/make_m7_guides.py` (red collision boxes over the
  NEW art; `git checkout grok_art/requests/m7/` after, the guides should stay on the old art) and
  `tools/qa_shot.tscn` (now also shoots `kitchen_fryer` + `kitchen_sandwich`). Home layout matches every box; the
  exit is the drawn door at the bottom middle (Duff gets "Go outside" there). Laptop on couch, baby bath, rugs
  are art, not overlays; rugs aren't walls. Renders: `docs/renders/m7_backdrops_drop1.png` (before/after),
  `m7_backdrops_drop1_ingame.png`. **Next drops** land the same way: copy, import, guide overlay (arenas/gala:
  wall bands), QA shot, before/after, merge. Arenas: when Place letters a sign into the art, delete the matching
  `draw_string` in `main._draw_arena` (ghoster/gymbro/crypto).

- **Grok is out of usage for the week (Nov 8); Gemini is the art department now.** Duff runs the Gemini app by
  hand (no API: free tier has 0 image quota, Duff declined billing). Drops land in Drive **DuffQuest Art Inbox /
  97 Gemini art drops** (filenames = ids); refs there: `ref_done_home/kitchen/boss_card`. Claude pulls, grades, wires.
  `tools/gemini_art.py` exists for the API if billing is ever turned on (key in `~/.gemini_key`, never commit).
- **Done (Nov 8): Gemini apartment swapped in.** Gemini's G1 (`grok_art/2026-11-08-gemini-test/g1_try1.jpg`, ~9/12)
  replaced Grok's `home_interior`. Its furniture moved, so the CODE moved to match: `main.gd` FRIDGE_R, COUNTER_R,
  MIRROR_R (now a wall), new SIDE_TABLE_R / DRESSER_R / CAT_TREE_R walls; KITCHEN_PT, MAT_PT (back walk = big rug),
  MAIL_R/PT (side table), MIRROR_PT, BOWLS_R/PT. `tools/make_m7_guides.py` HOME boxes updated. Render:
  `docs/renders/m7_home_gemini_ingame.png`, `gemini_g1_vs_grok.png`. Lesson: when new art moves furniture, moving
  the collision boxes is cheaper than a redraw.

- **Done (Nov 8): Gemini gym (`arena_gymbro`).** G2 try 2 (`grok_art/2026-11-08-gemini-test/g2_try2.jpg`, 10/12: sign
  spelled right, warm light; racks still reach ~40% down, junk text on tubs, angled right wall) resized to 640×360.
  Duff OK'd fixing layout in CODE: `main.gd ARENA_EXTRA_WALLS` = per-arena walls (switched on by the `arena_id` setter
  -> `_sync_arena_walls`), gym = racks band 70, bench, plate rack, tub shelves, bottom 162. Gym's `draw_string` sign
  removed. `tools/make_m7_guides.py` EXTRA draws them. Checks: `godot --headless --path . res://tools/arena_wall_check.tscn`
  (where Duff stops in each arena), `tools/arena_shot.tscn -- <id>` (in-game shot). Render: `docs/renders/m7_gym_gemini.png`.
  Known: the top HUD covers the arena's top ~35 units, so lettered wall signs (IRON TEMPLE) sit under the HUD panels
  in a fight. **Duff (Nov 8): Gemini drops signs low** (rule in `grok_art/requests/REQUEST_M7_backdrops.md`); gym
  sign edit-prompt pending. Also `qa_shot`'s boss_*_fight shots are broken (kitchen overlay from `kitchen_sandwich` stays up).
- **Done (Nov 8): Gemini G4–G7 graded (try 1).** G4 Porch Pirate 9/12 (row 2 not a back view; left row can be
  the right row mirrored), G5 "Dolores" 8/12 (wrong character: curlers/robe/cigarette; keep for another NPC),
  G6 props 9/12 (5/16 of the list, but clean), G7 show-off 11/12. No G3, no try 2s. Gemini (esp. Flash-Lite) ignores
  lists/row orders: give it short one-job prompts and EDITS of existing images. Files: `grok_art/2026-11-08-gemini-test/`.
- **Done (Nov 8): title screen = G7.** `assets/art/bg_title.png` (Duff at the fryer); `_menu(..., backdrop)` param;
  title shows only the tagline, controls moved to a "How to play" button (`TITLE_HELP`). Render: `docs/renders/title_g7.png`.
- **Done (Nov 8): G6 kitchen props in.** `tools/import_props.py` -> `assets/art/kp_*.png` (16 props; per-prop scale).
  Fryer: basket + food sprite tinted by doneness. Sandwich: bun halves / chicken (grilled = tinted) / lettuce / tomato are
  sprites, mayo/cheese/bacon/sauce/pickles still bars. Unused so far: pickle jar, mash, thermometer, ticket, heat lamp,
  ketchup, spatula, skillet, plate, salt. `tools/arena_shot.tscn -- title|fryer|sandwich` shoots them.
  Render: `docs/renders/kitchen_props_g6.png`.
- **Done (Nov 8): ChatGPT apartment swapped in (Duff's call).** ChatGPT C1 (`grok_art/2026-11-08-chatgpt-test/c1_try1.png`,
  11/12) kept Gemini G1's layout almost exactly (Duff likely attached the finished room), so no collision changes; sharper
  and warmer. Render: `docs/renders/m7_home_chatgpt.png`, `chatgpt_c1_vs_gemini_g1.png`. `arena_shot.tscn -- home` added.
  Shootout brief: `grok_art/requests/AI_ART_SHOOTOUT.md`; Gemini's copy is a Google Doc in Drive `geminiart`.
  Note: importing `tools/make_m7_guides.py` from Python runs it (no main guard) and rewrites the guides.
- **Done (Nov 8): ChatGPT gym + tux.** C2 try 2 (straight-on, racks only along the back wall, sign spelled right) replaced
  Gemini's `arena_gymbro`; its extra walls shrank to one racks band (`ARENA_EXTRA_WALLS gymbro = [Rect2(0,0,320,56)]`).
  Sign top sits ~16% down, so the errand panel clips its last letter in fights. C3 (tux sheet, rows/poses match
  `duff_home` exactly; back row shows a black tee, not the jacket) -> new `tools/import_big_sheet.py` (any-size 4x4 sheet ->
  256 format, one scale from the stand frame) -> `ch_duff_suit` (symphony/gala). Renders: `docs/renders/m7_gym_chatgpt.png`,
  `duff_tux_chatgpt.png`. **GitHub account suspended Nov 8 ~4:35 PM (appeal filed by Duff);** these commits were made
  locally and pushed once access returned (or are still waiting: check `git log origin/main..`).
- **Done (Nov 8): Dolores HD portrait (ChatGPT C5).** `portraits_hd/dolores.png` (smug / deadpan / furious);
  `Art.portrait_for` maps any line starting "Dolores" (her lines are narration-style: 'Dolores (31 years in): "..."');
  mood = Brittany's word rules. `arena_shot.tscn -- dolores`. Render: `docs/renders/dolores_portrait_chatgpt.png`.
  ChatGPT results so far (`grok_art/2026-11-08-chatgpt-test/`): C1 11, C2 11, C3 11, C5 11, C6 12 (all 16 props in order,
  not wired: Gemini's kp_* still drive fryer/sandwich), C7 12 (Duff vs giant waffle; spare title/splash art).
  X1 (add one tree, change nothing): FAIL strictly, the whole image is re-rendered (5.8% of pixels outside the corner
  changed >60), but no furniture moved. Fix for edits: paste only the edited region back onto the original.
  C4 Porch Pirate 12 (both tries: real back view, box hidden in front, throw column) -> `ch_pirate0/2` (try 1),
  `ch_pirate1/3` (try 2) via `import_big_sheet.py`; render `docs/renders/porch_pirate_chatgpt.png`. X2 seamless tile:
  PASS by eye (3x3 tiling continues the checker; edge-diff numbers are high only because the edge is a grout line).
  Missing: X3. Next: ChatGPT vs Grok rematch, brief `grok_art/requests/CHATGPT_VS_GROK.txt` (Drive Doc "ChatGPT vs Grok
  rematch (Nov 8)" in `geminiart`). Results: R1 Kwik: Grok wins (ChatGPT drew it isometric with a lot/car/trees; try-2 prompt
  asks straight-on, building only; render `docs/renders/rematch_r1_kwik.png`). R2 trees: ChatGPT wins, maple/oak/ash/pine/lilac
  swapped in by `tools/import_chatgpt_trees.py` (scaled to Grok's heights, placements unchanged; Grok's long hedge kept);
  renders `rematch_r2_trees.png`, `rematch_r2_trees_ingame.png`. Also fixed: 'Madison texts: ...' lines showed Duff's portrait.
  R1 try 2 (straight-on, building only) WON and replaced `sf_kwik` via new `tools/swap_storefront.py SRC NAME` (fits the
  footprint canvas, bottom-aligned; door/shop trigger unchanged). Shot: `arena_shot.tscn -- at:535,128`; render
  `docs/renders/rematch_r1_kwik_ingame.png`. Storefront prompts must say straight-on + building only. List: R1 Kwik storefront, R2 trees, R3 clutter, R4 Gym Bro intro card, R5 Brittany
  portraits (redo), R6 Earl sheet, R7 Duff apron; Grok's original prompts, results `r1_chatgpt.png`...

