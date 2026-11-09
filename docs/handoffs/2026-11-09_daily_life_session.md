# Session summary: human parody bosses, daily life layer, Falcor (Nov 8 23:40 – Nov 9 00:30 CT)

For other agents. This is a record of one chat with Duff: what he asked for, what he decided,
what got built, and what went wrong. Session id: `session_01V3sbxM7rZ4sc71oLLv5RQq`.
Commits: `M10` shift shuffle, `5802320` M11 fridge calendar, `096c33a` M12 Falcor, plus the
portrait commit before them.

**Read this alongside, not instead of:** `CLAUDE.md`, `docs/HANDOFF_NOV9.md` (newer: written by a
later session), `docs/daily_life.md` (the spec built here), `tasks/lessons.md`.

**Superseded since this chat (don't redo):**
- The 5 parody bosses are now `"live": true` in `data/knockouts.json` (cards, sprites and KO stills were done by a later session).
- The Canva scratch design moved to `DAHabf2Qa9U`. The old `DAHaZZaEJBs` hit 100 pages.
- Secrets now live in the Cloudflare D1 vault (`CLAUDE_REFERENCE.md`). **Never ask Duff to paste a token in chat again.** This session did, and the token is in the chat transcript.

---

## 1. How the chat went (timeline)

1. **Handoff #5** pasted. Duff said go on the face-sheet export. Picked for Willnot: **gun in a shoulder holster**, because it reads at 64 px and holds in all four facing rows.
2. Exported the 4 cartoon face sheets (Husk, Bozos, Fences, Donald) from Canva at 3072x1536 and cut portrait strips.
3. **Duff interrupted:** "Bruce and Jeff need human faces, it's out of pocket and too much imitation on Hazbin Hotel."
   - Then he widened it: **all parody bosses get made-up HUMAN faces**. The duck, the TV head and the lightbulb are dropped. The extra-cartoony versions are saved "for DLC or add-ons."
   - Rule held: invented faces only, never a likeness of the real person. Recognizable by outfit and props only.
4. Generated 5 new human sheets in Canva with **Ghoster's portrait as the style reference** (the house style: flat cel shading, thick even outlines, no glow, no fangs). Graded them, keyed them, put them in the game, and confirmed in-engine dialogue renders. Pushed.
5. Duff asked **how long the game takes and how repetitive it is.** Answer (estimate from code, not measured):
   - 2-3 h to the ending; 3-5 h for all 17 bosses.
   - Willnot unlocks day 12 at 75% happiness.
   - One day is about 8-10 real minutes (2 game-min per real second).
   - The biggest grind: the Full shift was the same 8 stations in the same order every shift.
6. Duff picked from the anti-monotony list: shift shuffle, muscle memory, random daily events, weekends, weather. **Rejected:** skip-to-shift ("it's a small world").
7. Duff asked for a Persona-5-style daily encounter prompt. I wrote one, and he answered:
   - **"Skip 2"** = no Persona time slots in DuffQuest. **Save the concept for future games** (saved to Duff's Claude memory, `/topics/game-ideas.md`).
   - **Bonds (M13) cut.**
   - **Calendar = a full month, as a FRIDGE calendar with little notes to each other, cats included.**
   - **Falcor:** "make one of the daily events the passing of her cat Falcor, don't include him in game, just mentions of him, a stray she feeds." Falcor's day-10 text was approved as drafted ("yes to everything").
8. Built and pushed **M10, M11, M12** (sections 3-5). Stopped at the 3-milestone session cap.

## 2. Duff's decisions from this chat (binding)

| Topic | Decision |
|---|---|
| Parody bosses | Made-up human faces for all 5 (Husk, Bozos, Fences, The Donald, Willnot). No duck, TV or lightbulb heads. |
| Cartoon heads | Saved as DLC concepts: `docs/dlc_concepts/*_cartoon_sheet.png` |
| Hazbin | Too much imitation. Keep the portrait style on Ghoster's house style. Never name the show in prompts. |
| Willnot's gun | Shoulder holster over the tank top |
| Time slots (Persona) | Not in DuffQuest. Saved for future games. |
| Skip-to-shift | No |
| Bonds / relationship ranks | Cut |
| Calendar | 30-day fridge calendar with notes between Duff and Madison, Octavia's crayon, and the 3 cats |
| Falcor | Stray Madison feeds, `{stray}` token. **Never drawn.** Only mentioned. Passes on day 10 (one-time). Treat sincerely, no jokes at his expense. |
| Weekends | No Fork shift on Sat/Sun |

## 3. M10: shuffled shift + muscle memory (`scripts/shift.gd`, `scripts/main.gd`)

- **Full shift:** `Shift.full_order()` keeps `quiz` first (it's Chef's lineup) and shuffles the other 7. Quick shift was already 4 random stations.
- **Saved bests:** `main.station_best` (saved as `"station_best"`) holds the best grade per station. `record_station_bests()` runs in `apply_shift_result`. Autopilot runs and event stations don't count.
- **Autopilot:** a station with an S shows **Autopilot (B)** (KEY_2) on its card. That gives a flat `AUTOPILOT_SCORE` 0.72 = B with the note "Muscle memory...". `can_autopilot()` covers FULL stations only, never the inspector.
- **Render:** `docs/renders/shift_autopilot.png` (`tools/shift_shot.tscn`).

## 4. M11: fridge calendar + random daily events + weekends

**Files**
- `scripts/daily.gd`: pure logic. Calendar lookup, month/day-of-month, weighted deterministic roll (seed = `wordle_seed`, day), no-repeat list, effect getters.
- `data/calendar.json`: 30 November days. Day 1 is a Friday; paydays are Fridays, rent is Mondays, Thanksgiving is day 28. Each day has:
  - `card`: Duff's line on the wake band, bar voice, present tense.
  - `tag`: the scribble in the grid square.
  - `notes`: sticky notes from `hero|partner|baby|cat1|cat2|cat3`.
  - `headline`/`event` on days 10 (`falcor`) and 28 (`thanksgiving`).
- `data/daily_events.json`: 10 weekday and 4 weekend events.
  - `chance` 0.75; no repeat within 5 days.
  - Effect fields: `energy/happy/money` (applied on wake), `shift_pay`, `shift_modes`, `inspector`, `walk`, `spawn`, `needs_beaten`.
  - Each event also has a fridge `note` and a small-print `effect`.
- `scripts/fridge_calendar.gd`: full-screen overlay on game.gd's HD layer, drawn in code.
  - Fridge door and handle, a paper month grid with magnets.
  - Past days crossed off in pencil, today ringed in red marker.
  - Up to 4 rotated stickies on the right: today's event first, then the calendar notes.
  - Cats sign with a paw; Octavia's crayon note is pink.
  - Bottom band shows the day name and card. Tap to close (MIN_T 0.6 s, MAX_T 25 s).
- **Fonts:** `assets/fonts/Caveat-Bold.woff2` (Madison, cats, Octavia) and `PatrickHand-Regular.woff2` (Duff). Both OFL, licenses alongside. They came from npm `@fontsource/*`, because **GitHub raw downloads are 403 from the sandbox**.

**Wiring in `scripts/main.gd`**
- **Morning:** `_wake` sets `calendar_pending`. `loading_done()` shows the fridge after the loading screen. `calendar_on` is part of `busy()`.
- **Daily roll:** `daily_new_day()` runs on wake and in `new_game`.
- **Helpers:** `today_event()` returns today's id or "". `daily_headline()` is true when a random event or a calendar headline owns the morning.
- **One headline per day:** if a random event rolls, or it's a headline day, the old bill roll (`curveball_new_day` / `Life.roll_event`) waits. Bill resolution still runs. Ordinary calendar days still roll random events.
- **Effect hooks:**
  - `apply_shift_result`: total x `Daily.shift_pay`.
  - shift start: `shift.modes`, plus `shift.force["inspector"]`.
  - `spawn_interval`: divided by `Daily.spawn`.
  - `apply_gear`: `speed_mult` x `Daily.walk`.
- **Weekends:** `try_shift` refuses on `Daily.is_weekend(day_i % 7)`, with a line.
- **Fridge spot:** new interaction "Fridge calendar" at `FRIDGE_PT` (131, 515) in the home. The fridge is visible in `home_interior.png`.
- **Saves:** `daily` dict `{day, id, recent, falcor, thanks_day}`, cleaned by `Daily.clean()` on load.

**Renders:** `docs/renders/fridge_calendar.png` (6 days), `docs/renders/fridge_wake_flow.jpg` (loading, then fridge, then report). Tools: `tools/calendar_shot.tscn`, `tools/calendar_sheet.py`, `tools/wake_shot.tscn [-- <day before>]`.

## 5. M12: Falcor + Thanksgiving

- **Before:** fridge notes on days 3 (Madison names him), 7 (dead moth gift), 9 (bowl full) and 13 (bowl moved inside).
- **Day 10:** headline, no random event.
  - The fridge has no notes, on purpose: the empty fridge carries the moment.
  - Wake opens the `SUNDAY` card with `FALCOR_LINES`. The text is approved; don't rewrite it without Duff.
  - The card uses the `living_night` backdrop, dimmed 0.45. **No party burst behind sad scenes.**
  - **Stay with her:** +10 Happiness, 3 h pass, a line about the moth.
  - **Give her some space:** no penalty, a kiss on her head.
  - Saved in `daily.falcor`. The normal wake report shows after the choice. Street spawns hold for about 150 s.
- **Days 11-13 (`falcor_grief()`):**
  - No fussy-mood rolls.
  - One soft wake line per day (`FALCOR_GRIEF`).
  - Day 11: Madison texts "bowl's still on the porch. not ready to move it."
- **Day 28, Thanksgiving:** Fork closed (`try_shift` line), Waffle Haus at noon, +10 Happiness, +20 Energy. Applied once via `daily.thanks_day`.
- **Render:** `docs/renders/falcor_day.jpg`.

## 6. Parody boss portraits (this chat's part)

- **Canva media ids for the human sheets (2:1, smug / deadpan / furious, on #00FF00 green):**
  - Husk `MAHaZVquI-k`
  - Bozos `MAHaZazRUis`
  - Fences `MAHaZZHv4kg`
  - Donald `MAHaZVjIpnw`
  - Willnot `MAHaZRN7OnI`
- **Designs:**
  - Husk: wiry, goatee, goggles, silver fringe jacket, jetpack straps, phones taped on.
  - Bozos: tiny bald man, sunburn, gap teeth, propeller-drone hat, cardboard-box cockpit.
  - Fences: lanky, shaggy salt-and-pepper mullet, full beard, no glasses, cardigan, a blue loading wheel floating above his head.
  - Donald: huge man, black pompadour, handlebar mustache, navy suit, very long red tie, rubber-duck tie pin.
  - Willnot: sunburned, dirty-blond mullet, stubble, nose band-aid, torn tank top, shoulder holster.
- **Grades** (brief / layout / style / clean, 12-point): Husk 11, Bozos 12, Fences 12 after the wheel fix, Donald 12, Willnot 11.
- **`tools/import_portrait.py` changes:**
  - Background is sampled from the **top corners only**, because busts run off the bottom edge.
  - New **`--min-island N`** keeps detached props. Fences' wheel is drawn as about 10 dashes; use `--min-island 400`.
- `tools/portrait_shot.gd` now includes lines for the 5 bosses; shouty lines pick the furious cell.
- **Renders:** `docs/renders/parody_bosses_human_v1.jpg`, `docs/renders/parody_portraits_dialogue.png`.

## 7. Tests and checks added

- `godot --headless --path . --script tools/test_daily.gd` covers:
  - shuffle and autopilot
  - calendar data integrity
  - roll pools, no-repeat and `needs_beaten`
  - effects, save round trips and the sick-day menu
  - the Falcor card and choice, grief days and Thanksgiving

  It had 43 checks at the end of this chat; a later session counts 48. It uses a **throwaway save path** (`user://test_daily_save.json`).
- The smoke test passed with 601 frames after every milestone. `text_fit` reported 0 overflows.

## 8. Mistakes made here (also in `tasks/lessons.md`)

1. **The "reset" landed in `from_dict`.**
   - What happened: I added `station_best = {}` next to the `bet` reset, but that line lives in `from_dict`, so it wiped the saved grades on every load. Caught and fixed before the push.
   - Rule: `new_game()` is `from_dict({})`. Put defaults in `d.get(key, default)`.
2. **A test wrote to the real save.**
   - What happened: a headless test called `_wake()`, which saves to the real `user://` save. The next render tool pressed Continue and loaded the test's state, which showed up as a Bed menu where the Falcor card should be.
   - Rules: tests set `main.save_path` to a throwaway file. Delete the sandbox save before renders.
3. **My first portrait crop** clipped Husk's hair and kept the white panel dividers. Use an inset crop and render before calling it done.
4. **`import_portrait` dropped Fences' floating wheel** (it only kept the largest piece). Hence `--min-island`.
5. **Debug tool mistakes:** `main.dialog` is a typed array, so tools must not assign `[]`. A key pressed on the shift menu can land on the wrong button: Quick was chosen instead of Full in the autopilot render. The render was still valid for checking autopilot.
6. **Process:** I asked Duff to paste the GitLab token into chat. Don't; use the vault.

## 9. Open items from this chat

- **Ear and eye test on the phone:** fridge calendar readability at phone size, especially Duff's Patrick Hand stickies, which are small.
- **Economy check:** weekends off removes 2 shift days a week against $195 weekly rent. Five shifts should cover it, but nobody has playtested it.
- **Calendar after day 30:** only November is handwritten. Later months show the empty grid and random events only. Duff may want December written (Christmas, New Year's).
- **The Falcor card backdrop** `bg_living_night` is old flat art. A softer morning porch backdrop would be better if one gets made.
- **The 5 cartoon parody sheets** in `docs/dlc_concepts/` are DLC material. Don't use them in the base game.

## 10. Commands used

```
# smoke (before every push)
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600   # expect 601 frames, no SCRIPT ERROR
# after any art/font swap
godot --headless --path . --import
# daily-life tests
godot --headless --path . --script tools/test_daily.gd
# renders
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/calendar_shot.tscn && python3 tools/calendar_sheet.py
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/wake_shot.tscn --fixed-fps 30 -- 9    # wakes into day 10
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/shift_shot.tscn
xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/portrait_shot.tscn
# portraits from a 2:1 three-mood sheet
python3 tools/import_portrait.py SRC.png <id> --cell 512 [--min-island 400]
```
