# Duff Quest: reference

This file explains how the game works. `CLAUDE.md` is the session log (status and what happened when). `CLAUDE_REFERENCE.md` covers ops: secrets vault, hosting, shipping to itch. This file is
not a changelog. When the code and this file disagree, the code wins: fix this file.
Facts were checked against the source on Nov 9, 2026. Anything not checked is marked **(unverified)**.

---

## 1. The game in one paragraph

Duff Quest is a comedy RPG about Duff's real life as a line cook in Omaha. It is built in Godot 4.5 with GDScript,
landscape only, phone-first (Android plus web/itch). The player is always Duff. Each in-game day he keeps Madison
happy, pays the rent every Monday, works shifts at the Twisted Fork (a chain of station minigames), runs errands,
feeds the cats and fights street enemies and parody bosses with a frying pan. The fights play like the GBA Dragon
Ball Z games. The story: beat four exes, then Bruce Willnot in Nakatomeh Plaza, which rolls the ending. Side content:
Waffle Haus graveyard shifts, the 86 List bounties, Brittany's bets, dates, plasma donation, the stock market
and Octavia's college fund, and the Elite Gala (five gala bosses, invite lands the morning after the story ending, or story day 24 (`GALA_DAY`) at the latest; open through day 30 and after).
All narration is Duff telling the story at the bar, in present tense.

**Pillars** (`docs/PITCH.md`):
1. Duff's real life, told by Duff: real places and real people (parodied), his voice, present tense, satire in the
   EarthBound vein.
2. Bright, punchy action: combat like GBA DBZ (combos, specials, juice), and every boss looks different from
   every other.
3. The daily grind is the game: shifts, rent, errands, Madison's mood and Octavia's fund are the loop. Fights and
   minigames break it up.
- **Not in the game:** online play, voice acting, an open world beyond the block and its interiors, any other
  playable character, an isometric camera.
- **Kill/pivot:** testers stop choosing to play new builds, or the median fun score stays under 6/10 after two
  rounds, or the game crowds out Lethemoor (Duff's main game).
- **Public build:** swap the real names in `data/cast.json`. The family build keeps them.

**Cast.** Code refers to every real or parody name with a `{token}` from `data/cast.json`, resolved by
`Cast.N()`/`Cast.T()`. `{KEY}` gives the upper-case form.
| Token | Value | Role |
|---|---|---|
| `{hero}` | Duff | the only playable character. Buff, dirty-blond undercut and ponytail, tattoo sleeves (section 5) |
| `{partner}` | Madison | her happiness is the main meter. Gives quests, errands, notes and texts |
| `{baby}` | Octavia | baby daughter. 3 AM baby shift, the college fund, crayon notes |
| `{cat1}` `{cat2}` `{cat3}` | Alastor, Lucifer, Freya | house cats. Feed them nightly. Freya has trust and treat interactions (`freya_menu`) |
| `{stray}` | Falcor | the orange stray Madison feeds. **Never drawn**, only mentioned. Dies on day 10 |
| `{sister}` / `{sister_full}` | Jen / Jennifer | texts daily Wordle roasts (`jen_text_daily`). Babysits for dates (`JEN_FEE`) |
| `{ex_1}`..`{ex_4}` | The Ghoster, Gym Bro Supreme, DJ Vape Lord, Mr. Crypto | story bosses |
| `{ex_final}` / `{final_tower}` | Bruce Willnot / Nakatomeh Plaza | final boss and tower |
| `{gala_baron}` | Baron Von Trustfund | gala boss |
| `{pharmacy}` `{pharmacist}` `{grocery}` `{plasma}` `{phlebotomist}` | Walgrumps / Pharmacist Deb / Hy-Whee Market / PlazMart / Phlebotomist Phil | errand and plasma places |
| `{pirate_1..6}` `{cologne}` `{sitter_app}` | porch pirate names, "Gucchi Eau de Duff", SitterSnap | |
| `{city}` `{nearby_town}` `{phone}` | Omaha, Council Bluffs, Duffphone | |
These names are hard-coded rather than tokens: **Brittany** (best friend; runs the bets; spectator in knockouts; HD
portrait), **Dolores** (Waffle Haus waitress, "31 years in", has her own `ch_dolores` sheet and HD portrait),
**Earl** = The Regular (Waffle Haus boss), **Grill-Boy Brayden** (Fork coworker who burns food), **Inspector Tiny**
(health inspector), **Palm Beach Pete** (rare rich street enemy), plus Chef and the Landlord. Speaker names that get
portraits are listed in `Art.NPC_SPEAKERS`.
Note: `scripts/cast.gd DEFAULTS` has no `stray` or `gala_baron` entry. If cast.json fails to load, those tokens
stay raw.

---

## 2. Architecture

### Scenes and autoloads
- `project.godot`: main scene `res://game.tscn`. Viewport 640×360, window override 1280×720, stretch
  `canvas_items` with `scale_mode="integer"` (narrow phones letterbox and the boxes never shrink). Renderer
  `gl_compatibility` on desktop and mobile. 2D pixel snap on, default texture filter nearest, mouse emulates touch.
- **The only autoload is `UiFonts` = `scripts/ui_style.gd`.** It installs the fonts and makes Nunito
  `ThemeDB.fallback_font`. Everything else is preloaded (`const X := preload(...)`) or is a child node of main.
- `game.tscn` → `scripts/game.gd` (root). It builds a `SubViewportContainer` + 640×360 `SubViewport` (nearest,
  snapped) and instances `main.tscn` inside it, then sets `Art.hd_enabled = true`. Next it adds a `CanvasLayer`
  (layer 100) at the screen's real resolution holding, from bottom to top: `hd_portrait_overlay.gd`,
  `loading_screen.gd`, `fridge_calendar.gd`, `knockout.gd`. Each one gets `.main` set and uses linear+mipmaps filtering.
- `main.tscn` → `scripts/main.gd` (about 4.8k lines): the overworld, interiors, menus, dialogue, day loop, the story and
  most systems' glue. Children it creates include the player, HUD, touch controls, combat (`combat.gd`), FX,
  Juice, `DressingFront`, cats, raccoons and `HD2DPresentation`.
- Tools that need the raw world (`tools/map_shot`) boot `main.tscn` directly. Everything else boots `game.tscn`.

### Pixel world and HD layers
- The pixel world is 640×360 px. World units are half of that (rooms and arenas are 320×180 units, `UI_SCALE` 2.0,
  art pixels are 2 per world unit). The HUD draws in world units ×2.
- World locations share one big coordinate space: outside around (0,0); home interior `INT_ORIGIN (0,440)`; gala
  `GALA_ORIGIN (400,440)`; arena `ARENA_ORIGIN (760,440)`. `location` is one of `outside | home | arena | gala`.
- The HD layer reads state from main (`dialog`, `ko_kind`, `loading_req`, `calendar_req`, ...) and draws at full
  resolution so that cartoon art keeps its lines. HD things freeze the world through `main.busy()`.
- `hd_portrait_overlay.gd` draws the dialogue portrait over the HUD's portrait box and the boss intro card
  (section 3.6). `Art.portrait_for(line, ...)` picks who is speaking. Unknown speakers default to Duff;
  `Art.boss_names()` excludes bosses from that default.
- `hd_presentation.gd` + `shaders/hd2d.gdshader`: warm `CanvasModulate`, LDR bloom/vignette in the screen shader
  (gl_compatibility can't do HDR 2D), window and lamp lights. Presentation only.

### main.gd responsibilities (key functions)
- Boot and title: `_ready`, `_setup_input`, `show_title`, `new_game`, `load_game`, `_menu(title, lines, opts, cb, backdrop)`.
- Dialogue: `dialog: Array[String]`, `_say(lines)`, `_toast(s)` (2.5 s). A/attack pops a line.
- Overlays and minigames: `_run_game(node, cb)`, `open_overlay` / `close_overlay`. `busy()` blocks input and the clock.
- Day: `_process` (clock, autosave, upset/pass-out checks, Ensure on the bench, director spawns), `go_to_sleep`,
  `_wake`, `pay_rent`, `curveball_new_day`, `daily_new_day`.
- Places: `enter_home` / `leave_home`, `interactables()`, `interact(id)`, `_auto_doors()` (`AUTO_DOORS`, radius 9,
  re-arm 20).
- Drawing: `_draw_outside` (ground → y-sorted storefronts + dressing → actors), `_draw_inside`, `_draw_arena`,
  `_draw_gala`, `draw_world_labels`.
- Combat glue: `hurt_player`, `spawn_enemy`, `_director`, `enemy_defeated`, `boss_defeated` → `knockout_done`.
- Debug: on web, URL hash `#dq=<id>` runs `debug_station(id)` (home, shop, baby, stealth, mash, stations...).

### Save system
- `scripts/save_game.gd`: JSON at `user://duffquest_save.json` (`DEFAULT_PATH`), `VERSION = 7`, `migrate()`
  upgrades v0 to v7. `main.save_path` can be overridden; tests must override it.
- **`new_game()` = `from_dict({})`**, then it seeds wordle/market, Jen's text, today's errand, `daily_new_day()` and the
  intro lines. Defaults live only in the `d.get(key, default)` calls inside `from_dict`. Never add a separate reset.
- `main.to_dict()` saves: location and position, `day_i`/`day_count`/`clock`, money/energy/happiness, quest state,
  inventory, leftovers, achievements, shifts_worked, `station_best`, `daily`, rent_debt/weeks_paid/late_notices,
  cat/couch/crib/freya days, inspector, gear, shades, wordle, kills, Pete, raccoon gifts, porch package, `story`,
  `bounties`, `waffle`, `bet`, errand + stats, buffs + buff_days, meal/cha days, dates, glow, plasma, mood,
  bills/owed/plans/rent_bump, events, phone_cracked, car/bus pass/rides, market/brokerage/college, threads/unread,
  gala flags, fund_happy, and `combat.to_dict()` (level, xp, points, stats, heat, selected, demon, extra_unlocks).
- Loading inside a gala or arena puts you back outside at `OUTSIDE_SPAWN`. Autosave runs every `AUTOSAVE_EVERY` 180 s
  of free time, on wake and after shifts. Manual save is at the bed. Settings (volume/mute) are saved separately in
  `user://settings.json` (`audio.gd`).

### Input and controls
- Keys (`_setup_input`): move WASD/arrows; interact E/Enter; bonk Space/J (mash for a 3-hit combo,
  `COMBO_WINDOW_MS` 600); roll Shift/K/L; gear I; special F/U (hold to charge); swap special Q; Demon Time R;
  stats T; phone P/Tab; settings O/Esc.
- Touch (`touch_controls.gd`): joystick bottom-left, A (use/bonk), B (roll), S (special), G (gear), the P phone
  icon in the HUD, the `<>` swap, and D (demon, only shown when ready). The title has a "How to play" card
  (`TITLE_HELP`, or `TITLE_HELP_TOUCH` when touch is up). Touch through the SubViewport is verified. While the touch layer is
  visible, `Cast.touch` is true and `Cast.T()` rewrites keyboard hints in minigame text and button labels into tap words
  (`Cast.TOUCH_WORDS`, e.g. "PULL (Space)" -> "PULL IT"). Buttons are radius 9 with outlined captions; A's caption says
  next / talk/use / bonk depending on what A will do.

---

## 3. Core loop and systems

### 3.1 Day, time, rent, money, happiness, energy (`main.gd`, `life.gd`, `moods.gd`)
- **Clock:** `clock` is in minutes and runs at `MIN_PER_SEC` 2.0 game-minutes per real second, only when no dialogue
  is up and Duff is not in an arena or the gala. Wake is 7:00 (`clock = 420`). The bed allows sleep from 20:00
  (`clock >= 1200` or before 5:00). At 2:00 (`clock >= 1560`) he passes out, -5 Happiness. `phase()`: Morning
  5-11, Shift 11-17, Evening 17-22, Night.
- **Days:** `day_count` starts at 1, `day_i` starts at 4 so day 1 is a **Friday** (`DAY_NAMES[day_i % 7]`). Monday is
  `day_i % 7 == 0`, which triggers `market_week()` and `pay_rent()` on wake.
- **Rent:** `weekly_base() = RENT 110 + rent_bump + BILLS 40 + Life.HOUSEHOLD 45 + plan_due()`. If Duff can't pay, he
  pays what he has, plus `LATE_FEE` 15, the rest goes to `rent_debt`, he gets a late notice, -20 Happiness and
  Madison is upset ("rent"). **Week one is prorated** (`first_week_prorate()`: nothing paid yet, no late notice, day <= 7):
  the first Monday bills half (`rent_due()` and `pay_rent()` both apply it). The intro line quotes `weekly_base()` and the
  prorated amount.
- **Money:** an int. Comes from shifts, Waffle Haus, bosses and bounties, bets, plasma, market sales, events. Prices use
  `price_mult()` (0.8 with CHA).
- **Energy** (0-100, capped at `Life.DRAIN_MAX` 80 while drained after plasma) is also Duff's **HP**:
  `hurt_player` subtracts damage from it. At 0 outdoors he passes out (`_pass_out`: sent home, energy 40, -10
  Happiness, +2 h). Sources: the Ensure on the bench (+40, 30 s respawn), kindness mornings, shift meal (+40 on
  B or better), Waffle coffee, the Feast special, level-up (+15), GRIT on kills. Wake energy is
  `clampf(100 - penalty, 30, 100)`.
- **Happiness** (0-100, starts at 60): drains 0.2/s while a quest is open. Hits 0 → couch night, reset to 30.
  Gains go through `gain_happy(x)` (×1.25 with CHA, ×`Dates.GLOW_HAPPY` during the date glow). It gates the story
  bosses (`STORY[i].happy`) and date invites (`INVITE_HAPPY` 50).
- **Madison's moods** (`moods.gd`): fussy days (`FUSSY_CHANCE` 0.15, 3-day gap, she swaps the request mid-quest),
  upset (causes rent, promise, ...; `make_up`/`bounce`), couch night (`COUCH_ENERGY` 70 next morning).
  `QUEST_WARN` [240,360,480] min: a quest left open too long makes her upset ("promise").
- **Quests** (`QUEST_NEEDS`): honey buns, formula, diapers, cake (cherries, chocolate, cream, flour, eggs). Started
  and finished by talking to Madison (`_talk_to_madison`, `start_quest`, `complete_quest`).
- **Kindness mornings** (`kindness_new_day`): 50% chance (25% if Happiness < 40) of a packed lunch, coffee, a mirror
  note, a kiss (full Heat) or a sweet text.
- **Money curveballs** (`life.gd EVENTS`): 30% roll from day 3 (`START_DAY`, `CHANCE`): bad mail (sneakers, work
  shoes, snow day, vet, rent hike...), car-only bad events (tire, battery, parking), good ones (tax refund,
  catering). Bills are settled at the mail table (`mail_menu`/`resolve_bill`) within `DECIDE_DAYS` 3, with payment
  plans. **They only roll when no calendar headline or daily event owns the morning** (`daily_headline()`).
- **Night:** `go_to_sleep` → Show & Tell with Madison (`show_tell.gd`, data `show_and_tell*.json`) →
  `_after_show_tell` → 3 AM baby shift (`baby.gd`) → stealth (`stealth.gd`, "baby's finally asleep") → `_wake`.
  Unfed cats cost -5 Happiness.
- **Transit** (`transit.gd`): bus fare $2, 30-day pass $40, stops home/kwik/fork/market, runs 5:30-23:30. Car for
  $2500 (`buy_car`, enables the car-only events). 35% of rides show a fun fact (`next_fact()`).
- **Test/render:** `tools/test_daily.gd`; `tools/wake_shot.tscn -- <day before>`.

### 3.2 Fridge calendar, daily events, weekends (`daily.gd`, `fridge_calendar.gd`, data)
- **Rule: one headline per morning.** Calendar headline > random daily event > `life.gd` money event.
- `data/calendar.json`: `{_readme, month: "NOVEMBER", days: {"1".."30": {tag, card, notes:[{from,text}], headline?, event?}}}`.
  `from` ∈ hero | partner | baby | cat1 | cat2 | cat3. `card` = Duff's line in the wake report ("Day N, <Weekday>. <card>").
  Headline days: **10** (`event: falcor`) and **28** (`event: thanksgiving`). Only the first 30 days are
  handwritten (`Daily.entry` returns {} after that). `MONTHS` cycles NOVEMBER..APRIL for the header.
- `data/daily_events.json`: `{_readme, no_repeat: 5, chance: 0.75, events:[{id, pool weekday|weekend, weight, card,
  note, effect, energy?, happy?, money?, shift_pay?, shift_modes?, inspector?, walk?, spawn?, needs_beaten?}]}`.
  10 weekday events (inspector, outage, sick_day, cat_chaos, boss_tips, double_tips, short_staffed, porch_pirates,
  ice, wind_chill) and 4 weekend ones (farmers_market, park_day, side_gig, lazy).
- `Daily.roll(day_count, weekday, recent, beaten, seed)` is deterministic per (seed, day) and skips headline days.
  `main.daily_new_day()` stamps `daily {day,id,recent,falcor}` and applies energy/happy/money once. Lookups:
  `Daily.shift_pay/walk/spawn/shift_modes/inspector(today_event())`.
- **Weekends** (`Daily.WEEKEND = [5,6]`, Sat/Sun): `try_shift` refuses ("schedule says I'm off"), except the first weekend (`first_weekend()`, story days 2-3), so a new
  player gets two shifts before the first Monday. The Fork's
  hours are 6:00-22:00.
- `fridge_calendar.gd`: full-screen month grid with magnets plus today's sticky notes. Fonts Caveat (Madison) and
  Patrick Hand (Duff). It appears after the morning loading screen (`calendar_pending` → `loading_done` →
  `show_calendar`) and from the **Fridge calendar** spot at home (`FRIDGE_PT`). Tap to close (`MIN_T` 0.6 s).
- **Render:** `tools/calendar_shot.tscn` → `python3 tools/calendar_sheet.py` → `docs/renders/fridge_calendar.png`.

### 3.3 Falcor thread and Thanksgiving (`main.gd`)
- Falcor shows up in the cards and notes on days 3, 7, 9, 11 and 13 (days 3/7/9 introduce him).
- **Day 10** (Sunday): if `daily.falcor == ""`, `_wake` calls `falcor_scene()`: a quiet `SUNDAY` card with
  `FALCOR_LINES` (text approved by Duff), the `living_night` backdrop at dim 0.45 (no party burst) and two choices.
  **Stay with her** gives +10 Happiness and costs 3 h. **Give her some space** costs nothing. The choice is saved in
  `daily.falcor`. `spawn_t = 150` keeps the block empty until about noon. Tone: sincere, no jokes at his expense.
- **Days 11-13:** `falcor_grief()` adds one soft line each morning from `FALCOR_GRIEF`. On day 11 Madison texts
  "bowl's still on the porch. not ready to move it." No fussy rolls while she grieves.
- **Day 28 Thanksgiving:** the Fork is closed. `calendar_day_lines` gives +10 Happiness, +20 Energy and a Waffle Haus pie line
  (once, `daily.thanks_day`).
- **Render:** `tools/wake_shot.tscn -- 9` → `docs/renders/falcor_day.jpg`.

### 3.4 The Twisted Fork shift (`shift.gd`, `scripts/minigames/*`)
- Entry: the Fork door (`FORK_DOOR`) → `try_shift` → `start_shift` (loading screen, black shoes, HUD hidden, shift on
  CanvasLayer 10) → `end_shift` → `apply_shift_result`.
- Modes (`menu_opts`, filtered by `shift.modes` from the daily event): **Full Shift (8)**, **Quick Shift (4)**,
  **Friday Night Rush**. `ENERGY_COST` full 20 / quick 10 / rush 15. Clock advances 6 h / 3 h / 4 h.
- **Stations** (`GAMES`): quiz (Lineup Quiz, `quiz_bank.gd`), prep, pickles, fryer, temp (Temp Check), sandwich,
  salad, garnish (Dessert). Extras: inspector, fix_temp, fix_fryer.
- **Shuffle:** `full_order()` keeps the quiz first and shuffles the other 7. Quick = shuffle `full_order()` and
  take 4 (the quiz can land anywhere).
- Random inserts: 86-board 45% (sandwich/salad), Grill-Boy 55% (steal a sandwich ticket, or a fix_fryer/fix_temp
  station worth +$5), inspector 35% (forced by the `inspector` event). A failed inspection makes Inspector Tiny follow
  Duff for 180 s with quips.
- **Grades:** `grade_for(score)`: S ≥0.92, A ≥0.8, B ≥0.65, C ≥0.5, else F. Pay = `BASE_PER_STATION` 6 × stations ×
  `MULT` (S2.0 A1.25 B1.0 C0.8 F0.5) + `TIPS` (S20 A12 B8 C3 F0, halved on quick) + bonuses, -$10 on F, -$2 per
  walked rush table, then × seniority (`main.pay_mult()`), × the daily `shift_pay`, plus CHA tips. Leftovers: S → cake
  + honey buns, A → cake, B → 40% honey buns. S also gives the "Chef's Kiss" achievement. Quips for C and F use
  the "Nobody tips the fry cook." chorus.
- **Muscle memory / Autopilot:** `main.station_best` (saved) holds the best grade per FULL station
  (`record_station_bests`; autopilot runs don't count). A station with a best of S shows **Autopilot (B)** on its
  NEXT card when it has no special context (`can_autopilot`). It scores `AUTOPILOT_SCORE` 0.72 = B.
- **Rush:** `RUSH_POOL` fryer/sandwich/salad/garnish/temp, 8 tickets, 150 s, combo multiplier.
- **Fork seniority (pay titles):** `main.TIERS` by `shifts_worked`: 0 Line Cook ×1.0, 5 Lead ×1.6, 12 Sous ×2.5,
  21 Chef de Cuisine ×3.8, 32 Executive ×5.5, 45 Celebrity ×8.0. This is separate from the combat "Seniority Lv".
- Kitchen props: `kp_*` sprites (Gemini G6) are used by fryer and sandwich. The rest are flat bars.
- **Test/render:** `tools/shift_shot.tscn` → `docs/renders/shift_autopilot.png`; `tools/arena_shot.tscn -- fryer|sandwich`;
  web `#dq=<station>`.

### 3.5 Combat (`combat.gd`, `player.gd`, `enemy.gd`, `projectile.gd`, `player_shot.gd`, `juice.gd`, `combat_fx.gd`, `combat_ui.gd`)
- `player.gd`: `SPEED` 70, roll 0.32 s at 175 with 0.8 s i-frames, 3-hit combo, attack column frame. `ARMORS` apron/clogs/
  sleeves/coat/dad set the outfit sheet. `shoes` red (street) / black (work).
- **Gear** (`gear.gd`, `gear_screen.gd`): weapons spatula, skillet, knife, tenderizer, flail, cleaver,
  golden_spatula; armor apron, clogs, sleeves, coat, dad, trust_fund. Upgrade level max 5 using scraps. Story wins
  grant pieces (`Gear.grant_piece`). The starter spatula passes special `"flip"` on every swing, so **flip is
  not a heavy hit**. Cleaver and Golden crits pass `"crit"`.
- **Heat** (resource): `HEAT_BASE` 100 (+10 per HEAT point), regen 3/s, +5 per hit, +10 per finisher.
  **Demon Time** (R/D): unlocks at Lv 10 or after beating any story boss. ×1.5 damage, ×1.3 speed, drains 10/s, half-cost
  specials, then a crash (×0.7 speed for 4 s).
- **Specials** (`SPECIALS`, unlocked by level): Spatter L1, Pinwheel L2, Julienne L3, Holler L4, Counter L5,
  Brulee L6, Feast L7, Salamander L8 (hold to charge), Sous-Vide Snare L9, Tempura L10, Eighty-Six Execution L12 (100
  Heat, cinematic). Hash Brown Hurricane L1, but only after Earl's first defeat (`extra_unlocks`).
- **Combat level ("Seniority Lv"):** `MAX_LEVEL` 20, `xp_to_next = 15 + 10*level`, `POINTS_PER_LEVEL` 3. XP comes from
  `XP` per kind, scaled down when you out-level the enemy by 4+ (`ENEMY_LEVEL`). Level-up refills Heat, +15 Energy,
  "SENIORITY UP!" banner, and maybe a Madison text.
- **Stats** (T or the card): **STR** +8% damage/pt; **DEF** -4% damage taken/pt (max -50%); **HEAT** +10 max Heat,
  +10% regen/pt; **GRIT** +1 Energy per non-boss kill/pt and quicker rolls (`roll_mult` min 0.6). Button labels fit
  through `UiStyle.fit_text` (`tools/stat_shot.tscn`).
- **Damage taken:** `hurt_player`: amount × (1 - gear reduction) × `taken_mult` × DEF buff 0.75 × glow/drain
  modifiers → subtracted from energy. Counter window reflects the hit.
- **Juice** (`juice.gd`, node "Juice"): hit-stop = `Engine.time_scale` `STOP_SCALE` 0.05 for real-time seconds
  LIGHT 0.07 / HEAVY 0.085 / KILL 0.12 / HURT 0.07 (+0.02 boss). Shake px 1.2/2.6/3.6/3.2 (×1.25 boss), trauma on
  `cam.offset` **clamped to camera limits**, plus a zoom punch. Skipped while paused or `combat.cinematic`.
  Resets time_scale on exit. Heavy = `"crit"`, dmg ≥ 10, or finisher heat. `combat.hit(..., feel=false)` is used for
  beam/brulee/tempura ticks. `combat_fx`: spark bursts, a ring on heavy hits, popping numbers.
- **Street enemies** (`enemy.gd STATS`): scammer, karen (+ karen_buddy Linda), hoa, driver, hustler (mash trap),
  pete (Palm Beach Pete: first day 7, rare), drone, butler, nft, pirate (porch pirates steal the package), drunk,
  heckler, kid. `main._director` spawns them (`spawn_pool`, `spawn_interval`, `spawn_cap`, × the daily `spawn`).
  Loot comes from `DROPS` and `DEFEAT_LINES`. Raccoons (`raccoon.gd`) are friendly: pet them for gifts.
- **Test/render:** `tools/combat_shot.tscn` (movie writer) → `python3 tools/combat_sheet.py` →
  `docs/renders/combat_feel.png/.gif`. Hit-stop doesn't show in movie-writer frames, so judge it on a device.

### 3.6 Bosses: 17 (`boss.gd BOSSES`, `TELE` telegraphs), intro cards, where they fight
| id | Name | Where | Gimmick / attacks | KO live |
|---|---|---|---|---|
| ghoster | {ex_1} The Ghoster | story d2, happy ≥50, Seen Cafe | seen, vanish (hides, pops out "u up?") | yes |
| gymbro | {ex_2} Gym Bro Supreme | story d4, ≥60, Iron Temple | curl, flex (don't hit while he flexes), charge | yes |
| djvape | {ex_3} DJ Vape Lord | story d6, ≥65, Club Cloud 9 | drop (bass wave), vape cloud | yes |
| crypto | {ex_4} Mr. Crypto | story d9, ≥70, Mining Rig | nft, rug (don't stand on rugs) | yes |
| willnot | {ex_final} Bruce Willnot | story d12, ≥75, Nakatomeh Plaza | spray (gun), vent crawl, glass floor, `FINAL_TIME` 210 s timer, then the floor explodes → ending | yes |
| husk | Elon Husk | gala 1 | posting, rocket | yes |
| bozos | Jeff Bozos | gala 2 | drones, shine | yes |
| fences | Bill Fences | gala 3 | bsod, update | yes |
| baron | {gala_baron} | gala 4 | hire (minions), coins | **no** |
| donald | The Donald | gala 5 | tariff, wall | yes |
| regular | The Regular (Earl) | Waffle Haus, 5 AM on regular nights | curl, hire, charge | yes |
| sendback | Sir Sends-It-Back | 86 List, Lv 2 | posting, charge | yes |
| coupon | Coupon Carol | 86 List, Lv 4 | coins, update | no |
| allergy | The Allergy Liar | 86 List, Lv 5 | seen, vanish | no |
| camper | The Four-Hour Camper | 86 List, Lv 6 | flex, curl | no |
| bdaydad | Birthday Party Dad | 86 List, Lv 8 | hire, coins, charge; kid minions | no |
| dasher | The Dine-and-Dasher | 86 List, Lv 10, after all the others | charge, vanish, rug | no |
- The story is `main.STORY`, in order. Madison announces each boss (`story_announce`) when the day and Happiness
  conditions are met. Fight via the building door (`story_doors`) → `start_story_fight` (arena `arena_<id>`, energy
  refilled). The reward is cash + scrap + a gear piece + an achievement + 15 Happiness. Losing → `story_lose`.
- **Gala:** `check_gala_unlock()` fires from `_wake()` (`gala_new_day()`) the first morning `gala_due()` is true: the story ending has
  played (`story.ending_seen`, so normally day 13) or `day_count` reaches `GALA_DAY` (24). Committee
  thread + Madison's guest-list text, calendar day 24 is a headline tagged GALA (`tag_from` hides it till then). Saves past day 24 without it
  catch up in `from_dict`; old saves with `gala_unlocked` keep it. The $100k fund is its own goal (`check_fund_goal()`, "Fully Funded").
  Phone: "Take the limo". `BOSS_ORDER` husk → bozos → fences → baron → donald, with a full heal between fights. `gala_win`/`gala_lose`.
- **Parody bosses** (husk, bozos, fences, donald, willnot) have made-up **human** faces (art rule P1). The duck/TV/
  lightbulb heads are DLC concepts only (`docs/dlc_concepts/`).
- **Boss art:** sprites `ch_<id>.png` (256 4×4, column 3 = that boss's own attack pose); HD portraits
  `portraits_hd/<id>.png` (cells 0 smug / 1 shocked / 2 enraged; `Art.hd_mood`: defeat line → shocked, rage or
  shouty line (`_shouty`: ALL-CAPS 4+ letters or two `!`) → enraged, else smug).
- **Intro burst cards:** `assets/art/boss_intro/<id>.png`, opaque 960×540 (`tools/import_boss_intro.py` from Place's
  burst previews). `hd_portrait_overlay` shows the card while the boss's exact intro line is up
  (`Art.boss_intro_for`): full-bleed, slides in from the right over 0.28 s (`SPLASH_IN`), lifted by `CARD_LIFT` 0.13 so the
  name clears the dialogue box, with an ink letterbox bar. The card and bar draw only in the strips around the box.
- **Render:** `tools/qa_shot.tscn` → `python3 tools/qa_sheet.py` → `docs/renders/qa_boss_intro.png`, `qa_boss_fight.png`.

### 3.7 Knockout cutscenes (`knockout.gd`, `data/knockouts.json`, `docs/knockout_cutscenes.md`)
- The style is Baki (anatomy, crack-line muscles, freeze frames, spectators) × Spike Spiegel (loose bounce, slips, one
  snap strike, walk-away). Narration uses Duff's bar voice plus the Palahniuk layer.
- **Flow:** HP 0 → `main.boss_defeated(b)`. If `KnockoutScript.is_live(kind)` and the cutscene hasn't played for
  this boss, it sets `ko_kind` and freezes. `knockout.gd` notices `main.ko_kind`, plays the beats, then calls
  `main.knockout_done()`, which re-enters `boss_defeated` and runs the normal defeat flow (bounty/waffle/story/gala
  branch, then the boss `defeat` line).
- **Beats** (`BEATS`): `stance` → `slip` → `xray` → `finisher` → `crowd` → `closer`. Each holds
  `clamp(1.6 + 0.045*len(text), 2.4, 8.5)` s. Tap/key skips (ignored in the first 0.35 s). Effects are code: letterbox
  (`BAR` 0.12), speed lines, crack lines, teal glow, `move` name stamp, shake, white flash (xray start; finisher at
  1.05 s).
- **knockouts.json schema:** `{_doc, <boss>: {move, stance, slip, xray, finisher, crowd, closer, live?}}`. `crowd` is
  a speaker-labelled line (`Brittany: "..."`) and gets that NPC's portrait. Keep `{tokens}`. `"live": true` turns it on.
  **Live: 11/17** (all except baron, coupon, allergy, camper, bdaydad, dasher).
- **Stills:** `assets/art/ko/<boss>_a|b|c.jpg` (A wind-up, B impact/x-ray, C down), 1280×720 JPG q88. Shared
  Duff stills: `ko/duff_stance|slip|fin1|fin2|fin3|walk.jpg`. Missing stills fall back to the intro card and
  portraits, so the cutscene always runs.
- **SFX:** `assets/sfx/ko/{whoosh,crack,drone,snap1,snap2,snap3,boom,crowd,jazz}.ogg`, from `tools/make_ko_sfx.py`
  (original numpy/scipy synthesis → ffmpeg libvorbis, peaks about -3 dBFS, deterministic). `SFX_CUES` = [sec into beat,
  file, dB, bed?], played on the **SFX** bus (settings apply). Beds (drone, crowd) stop when a beat is skipped.
  `played` records cues for tests.
- **Planned, not built:** in-engine cartoon blood, spit and teeth on the xray and finisher hits (art rule H2).
- **Render:** `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/ko_shot.tscn -- <boss>` → `/tmp/qa/ko_*`
  → `docs/renders/ko_<boss>_beats.png`. Known: ko_shot misses Ghoster's finisher frame.

### 3.8 Loading screens (`loading_screen.gd`, `data/loading_screens.json`)
- `main.show_loading()` bumps `loading_req` and sets `loading_on`. It is shown on wake, shift start, story and bounty
  fights, and Waffle Haus. `no_loading = true` (tools) skips it, and the fridge calendar too.
- Picks a random screen, never one of the last few. Holds `HOLD` 3.2 s, tap after `MIN_T` 0.5 s, 0.25 s fade. Then
  `main.loading_done()`.
- Data: `{_doc, screens:[{id, caption}]}`. There are 14 captions. A screen only loads if
  `assets/art/loading/<id>.jpg` exists. 13 JPGs are present; `cat_sacrifice` has no art, so it never shows.

### 3.9 Waffle Haus (`waffle.gd`, `main.waffle_menu/start_waffle/end_waffle`)
- Sign by the interstate (`WAFFLE_SIGN_PT`). Needs `WAFFLE_MIN_SHIFTS` 3 Fork shifts, clock-in between 21:00 and 1:00,
  and energy ≥ 25. It runs in arena `waffle`, gives +25 Energy (coffee) and Dolores is the waitress.
- Grill minigame: 3 grills, `DURATION` 180 s (from 22:00), `COOK_T` 4, `READY_T` 5 (then it burns), `PATIENCE` 32,
  `MAX_TICKETS` 5, $5 a plate + up to $3 tip, -2 per walkout, +20 finish bonus. Bar-close crowd at 2 AM (drunks).
- **Regular night** (`waffle_regular_tonight`: from the 3rd graveyard on, every night until Earl is beaten, then every
  3rd): Earl (boss `regular`) spawns at 5 AM. First win: $60 (later $30), the **Hash Brown Hurricane** special and the
  "Earl Approves" achievement.
- `end_waffle` → night report → `_wake(55)` (no sleep, -6 Happiness). S grade gives "Scattered, Smothered, Covered".
- **Render:** `tools/arena_shot.tscn -- waffle`.

### 3.10 Bounties (86 List), bets, errands (`bounties.gd`, `errands.gd`, `main.gd`)
- **The 86 List** (board `BOARD_PT` by the Fork): sendback L2 $40, coupon L4 $55, allergy L5 $65, camper L6 $75,
  bdaydad L8 $100, dasher L10 $180 (`needs_all`). One bounty per day, fought in arena `alley`. Rematches pay ×0.25
  (`REMATCH_CUT`). All six give "86'd Them All".
- **Brittany's bets** (`BETS`, at `BRITT_POS`, not at night): nohit (8 KOs untouched), combo (45 hits in 45 s on HOA),
  speed (12 KOs in 50 s). One a day, in the `alley` arena.
- **Errands** (`errands.gd`): one per day from Madison by text. Pharmacy (open 8:00-21:00, due 19:00, +15 Happiness,
  copay $10/$5) or grocery (6:00-23:00, due 20:00, +12, list and budget). Early by 12 h gives +5. A miss costs -10.
  Minigames `pharmacy.gd`, `grocery.gd`.
- **Porch package:** `porch_delivery()` on wake. Grab it at `PORCH_PT` before a pirate does (`pirate_snatch`).

### 3.11 Buffs (`buffs.gd`, HUD `status_icons`)
| Icon | Source | Effect |
|---|---|---|
| SPD | `speed`, "Back walk" (backwalk.gd, Madison) | +20% move speed |
| STR | `strength`, "Her cooking" (eat her meal) | +25% damage, 300 min base |
| DEF | `defense`, "Pore-fect skin" (blackheads.gd, mirror) | -25% damage taken |
| CHA | `charisma`, {cologne} spray ($12, 3 sprays) | 20% off, bigger tips (`CHA_TIP`), +25% happiness gains, 360 min base |
| LUV | date glow (`glow_active`, `dates.gd`) | ×`GLOW_HAPPY` happiness gains (and combat modifiers, unverified) |
| DRN | plasma drain (`drained()`) | energy cap 80, ×0.85 speed and damage, ×1.15 taken, ×0.75 regen |
| PASS | `buff_PASS.png` exists | bus pass icon. Not in `status_icons` (unverified where it is drawn) |
- Each kind once per day (`buff_days`). Duration = `base × (0.5 + 0.5 × minigame score)`. Madison refuses while upset
  or fussy (`_buff_refusal`). Using all four in one day gives "Fully Buffed Boyfriend". HUD icons: `assets/art/buff_<LABEL>.png`.

### 3.12 Phone, market, dates, plasma, other minigames
- **Phone** (`phone.gd`, P): text threads `sister` / `gala` / `madison`, Wordle (`wordle.gd` + `wordle_logic.gd`;
  data `words5.txt` valid guesses, `answers_common.txt`, `answers_themed.txt` at a 40% themed chance; Jen roasts the
  result), brokerage and **college fund** (`market.gd`: VOOM, SCHMD, BUNZ, BONDZ, GTS, GMSTP, DOGEB; weekly
  `market_week()` on Mondays; fund goal $100k = "Fully Funded" achievement, not the gala).
- **Dates** (`dates.gd`, `akarui.gd` sushi from day 2 +25, `symphony.gd` from day 4 +30): invite when Happiness ≥ 50,
  3-day cooldown, window 17:00-21:00, sitter $35 or Jen $20, tickets $60. Gives the glow.
- **Plasma** (`life.gd`, `plasma.gd`): 8:00-18:00, promo pay $50/60/70/80/100 then $35 (+$15 second time that week), max 2 a week,
  2-day gap, 90 min, needs energy ≥ 30 → drained.
- **Kwik-N-Go** (`shop.gd`): honey buns and so on. **Settings** (`settings.gd`): volume/mute. **Ending** (`ending.gd`) after Willnot.
  **Mash** (`mash.gd`): hustler trap. Fun facts (`fun_facts.gd`, 40 facts) also play once after "So where was I." on load.

### 3.13 Town map, dressing, arenas, interiors
- **Ground:** `ground.gd` builds the outdoor ground at runtime from `data/town_ground.txt` (a dual grid, one letter per
  corner: g grass, s sidewalk, a asphalt, d dirt, b brick, v gravel; `tile 64`, `origin -10 -32`) and
  `assets/art/ground/ground_atlas.{png,json}` (64 px tiles = 32 units, 12 transition masks per pair). Only the drawn
  pairs can touch (sidewalk/asphalt, grass/sidewalk, grass/asphalt, dirt/grass). Brick and gravel have fills only.
  Hand-edit the txt. Duff's call: keep the sidewalks and pavement (the real block is urban).
- **Buildings:** `main.buildings` = `{r footprint, n label, art sf_<name>, story?/errand?}`: HOME, NEIGHBOR,
  KWIK-N-GO, THE TWISTED FORK, HOA HQ, SEEN CAFE, IRON TEMPLE, CLUB CLOUD 9, MINING RIG, {FINAL_TOWER}, {PHARMACY},
  {GROCERY}, {PLASMA_SIGN}. Storefront sprites are footprint×2 with the bottom on the footprint edge. Walls come from `_art_rect()`
  (the opaque area), and the bottom edge stays the footprint so doors work. Shut places are tinted grey. Floating labels only on
  HOME/NEIGHBOR.
- **Dressing:** `data/town_dressing.json` `{_doc, objects:[{a sd_*, p [x,y] ground point, s scale?, wall?, tree?}],
  fences:[...]}` (fence segment 39 units). `dressing.gd` sorts by ground y. Things behind Duff are drawn in
  `_draw_outside`, things in front by `dressing_front.gd` (z 1), which fades to 45% (`SEE_THROUGH_ALPHA`) any front item
  covering a body box (Duff, enemies, bosses ×1.45, raccoons, cats, Brittany, inspector; `actor_boxes`).
  `main.trees` is derived from this data. After editing, run `tools/dressing_check.gd`.
- **Interior (home):** `home_interior.png` (ChatGPT C1). Collision rects and spots are consts in main.gd (`BED_R`,
  `FRIDGE_R`, `COUNTER_R`, `COUCH_R`, `MIRROR_R`, `SIDE_TABLE_R`, `DRESSER_R`, `CAT_TREE_R`; `*_PT` interaction
  points: bed, crib, shower, kitchen, fridge calendar, couch, bowls, mirror, mat, mail). The exit is the drawn door at the
  bottom middle. When new art moves the furniture, move the rects (cheaper than a redraw).
- **Arenas:** `assets/art/arena_<id>.png` 640×360: alley (bounties/bets), crypto, djvape, ghoster, gymbro,
  waffle, willnot; plus `gala.png`. gymbro is Gemini art; the other six are painted in code by
  `tools/arena_paint/paint_arenas.py` (Nov 10; stand-ins until M7 art lands; the script header lists where each
  in-code overlay sits). Render one in game: `tools/arena_shot.tscn -- <id>` or `-- bounty:sendback` (alley). `ARENA_EXTRA_WALLS` holds per-arena walls (`gymbro`: back racks band) and is applied by
  the `arena_id` setter → `_sync_arena_walls`. `_draw_arena` still draws text signs for ghoster/djvape/crypto; delete
  them when the art letters the sign. The top HUD covers the top ~35 units of an arena.
- **Checks:** `tools/map_shot.tscn` (whole town), `tools/arena_shot.tscn -- <id>|home|title|dolores|at:X,Y`,
  `res://tools/arena_wall_check.tscn`, `python3 tools/make_m7_guides.py` (red collision boxes over the art; it has no main
  guard, so importing it runs it).

---

## 4. Writing and voice rules (`docs/voice.md`)
- **Narration = Duff at the bar, first person, present tense.** "You..." narration becomes "I...". Other characters'
  lines, combat barks, UI, quiz and word lists, and Madison's show-and-tell stay as they are.
- Keep every `{token}` and format code (`%d %s %.1f %%`) in the same count and order. Stat results like `+5 Energy`
  go at the end. Same length as the original, never over about 1.4×. No raw double quotes (use single quotes inside
  narration). Keep the joke. If the original line was punchier, keep its words.
- **Tic budget:** "So..." only opens a scene (about 10 in the game). Quick popups are short thoughts with the punchline last.
  Quotes are written `Name: '...'`, not "goes,". ", right?" is rare.
- **Palahniuk layer:** tone only, never his text. Fragments, deadpan facts, one aphorism per line at most, the cost lands
  on Duff's body. Bright and warm underneath. Madison, Octavia and the cats are never the target. About one such
  line in five popups. **Choruses, EXACT and rare:** "Rent is due. Rent is always due." (3), "Hell of a girl." (3),
  "The body keeps the receipts." (4 max), "Nobody tips the fry cook." (2, C/F grades).
- **Fun facts** (`fun_facts.gd`): every one must be TRUE (or framed as "legend says"), about 120 characters, with one turn
  back onto Duff's life.
- **Knockout strips:** one device per strip, used across its beats and never reused by another boss (Husk viewer count, Bozos
  package tracking, Fences error popups, Ghoster timestamps, Willnot floor forty, Send-It-Back a ticket, Camper
  battery %, Baron talked to as "you", Earl plain sincerity). Budgets across all 17: "Fun fact" ×1, "The human ___"
  ×2, "I bounce" ×1, one bet line, Dolores pet names ×2. **The x-ray line names the bone the art shows being hit.**
- **Text fit:** `godot --headless --path . --script tools/text_fit.gd` wraps every 25+ char literal with the HUD font
  and width → `docs/text_fit.txt` (target 0 overflow). Buttons use `UiStyle.fit_text(text, w, h, size)`, which
  wraps, shrinks to `MIN_SIZE` 6 and cuts with "...". Narrow screens letterbox, so boxes never shrink.
- **Rewrite tools:** `tools/apply_rewrites.py` (rejects changed tokens or codes, raw quotes, >1.5× length, literals used
  elsewhere); `tools/apply_ko_rewrites.py` for knockouts.json (token and length checks, minimal diff). Rewrite sets live in
  `tools/rewrites/` (`palahniuk_m9.json`, `ko_variety_m14.json`).
- Note: voice.md still says the boxes are "480×270". The screen is now 640×360.

---

## 5. Art pipeline and rules

### Direction
- **World and character sprites:** modern high-detail pixel art like *Sea of Stars* (saturated, warm sun, soft coloured
  shadows), straight-on camera (not board 2's diagonal), and no isometric view. Bright and sunny (the opposite of Lethemoor).
- **HD art** (portraits, boss cards, KO stills, loading screens): bold cartoon like *Hazbin Hotel*, but **humans**
  (thick tapered ink, angular shapes, exaggerated faces, flat cel shading).
- **UI** (`ui_style.gd`, M8): copies the boss-card look. Palette INK `#1e1220`, CREAM `#fff1d6`, PANEL `#2a1e36`,
  GOLD, PINK, TEAL. `panel()`, `label()`, `button()`, `round_button()`, `burst()`. Fonts (OFL, `assets/fonts/`):
  Baloo 2 ExtraBold (display), Nunito ExtraBold (body/fallback), Caveat + Patrick Hand (fridge notes).
- Sad scenes get a quiet `backdrop` + dim, never the party burst.

### Art rules summary (`docs/art_rules.md`; PASS / FIX / REDO; HARD failures are automatic FIX or REDO)
- **D1** Buff build (never skinny or dad-bod). **D2** Heavy blackout sacred-geometry sleeve on one arm, shoulder to wrist.
  **D3** Other arm: grey-wash horns or flames on the upper arm, a dark creature head with orange eyes on the forearm (not a panther,
  lion or cat). **D4** Blackout-arm hand: an eye in a ring of triangles; other hand: blackletter script. **D5** Fox neck tattoo on
  Duff's LEFT side, used to check the sides. **D6** Face matches `portraits_hd/duff.png` and the photos (the photos win). **D7** Clothes
  may cover the ink; ink drawn on top of clothes fails.
- **K1** (HARD) The x-ray is at the hit and shows the bone the `xray` line names. **K2** A unique expression for each boss per still,
  and nobody gets Ghoster's face. **K3** (HARD) No characters leaked from the reference: check every panel. **K4** Ink, cel,
  crack-line hatching, speed lines on a flat colour; Duff in navy/amber/grey, bosses in neon. **K5** No text in the art.
  **K6** No two B stills share a layout, and a finished still never serves as the layout reference.
- **P1** (HARD) Parody bosses have made-up human faces. No real likeness, no duck/TV/lightbulb heads.
- **H1** One house style (match `portraits_hd/` and Ghoster). **H2** Cartoon gore is OK (spit, bloody nose, teeth,
  bruises), with no dismemberment, organs or realistic wounds. Canva blocks blood, so never prompt for it; blood gets
  added in-engine. **H3** Clean output (no crops, watermarks, fake text or extra limbs). **H4** KO and loading art 1280×720 JPG
  q88; portraits and cards keep their existing sizes.
- **S1** Sea of Stars pixel art, crisp, no blur. **S2** Grid and frame count unchanged and readable at game scale.
  **S3** Scale checked against Duff (about 26 units tall). **S4** Duff sprites still read D1-D3 (dark arm, lighter inked arm, buff).
- **R1** Run `godot --headless --path . --import` after any art swap, before renders. **R2** Judge full-size frames, not
  contact sheets. **R3** Write prompt sides from the viewer ("the arm on the VIEWER'S RIGHT"). **R4** Style references have no
  characters in them; characters get their own references. **R5** Masters go in `grok_art/<date>-<set>/`, review sheets in `docs/renders/`. **R6** Reviews
  go in `docs/reviews/`, one line per image (grade, failed rule ids, fix prompt). **R7** Side sprites: facing screen-RIGHT
  shows his RIGHT side (creature arm near); facing screen-LEFT shows his LEFT side (blackout sleeve + fox near). Side rows are
  inked separately and never mirrored (`tools/tattoo_sprites.py`).

### Duff's look (`docs/duff_look.md`; paste the TATTOOS block into every prompt that shows his arms, and attach `docs/ref/duff/`)
- Build: **buff**. Head: dirty-blond undercut, hair tied back in a ponytail, blue eyes, ginger-blond stubble,
  stretched lobes with round plugs plus small spiked hoops, a calm flat stare. Usual clothes: black tee, work apron
  (black or red), red shoes.
- **TATTOOS block (verbatim from duff_look.md):**
  > Duff has full tattoo sleeves on BOTH arms:
  > - LEFT arm, shoulder to wrist (layout from the Nov 9 photos): petal MANDALA on the shoulder cap; a thin skin line, then a big
  >   FLOWER OF LIFE over the whole upper arm; a grinning SKULL with bared teeth on the inner upper arm; a petal mandala on the outer
  >   elbow; a big STAR MANDALA on the outer forearm; an EYE inside the band at the wrist. All of it a heavy blackout sacred-geometry sleeve — mostly solid black ink with skin-tone negative-space
  >   designs: flower-of-life circles on the upper arm, a large petal mandala with a central eye on the outer elbow, chevron and
  >   triangle bands down the forearm.
  > - Back of the LEFT hand: a large all-seeing eye inside a ring of sharp black triangles (a spiked sun/mandala) covering the whole
  >   back of the hand, blending into the sleeve at the wrist; small dot tattoos on the fingers and knuckles.
  > - RIGHT upper arm: a large grey-wash biomechanical piece — organic horn/flame shapes with eye-like openings, wrapping the outer
  >   arm from shoulder to just above the elbow (NOT solid black flames — the fox art got this wrong). Small piece on the back of the
  >   right shoulder.
  > - RIGHT forearm: NOT a panther (Duff, Nov 9). A dark creature head with several glowing eyes (orange in colour photos), a snout
  >   with a nose and freckle dots and its pink tongue curling out, framed by leaves (orange-gold), with two lines of small script
  >   above it. A thin black bracelet on the wrist.
  > - Back of the RIGHT hand: several lines of bold gothic blackletter script running from the knuckles down onto the wrist
  >   (draw it as illegible blackletter; never invent readable words).
  > - LEFT side of the neck: a realistic fox head with pale blue crystal shards and a pale blue rose.
  > - Under the shirt (only if shirtless, which the game never is): skull with a pink bow (right chest), small script (left chest),
  >   belly script "Despite these scars I will recover".
  >
  > At sprite size (64 px) this reads as: LEFT arm almost solid dark ink shoulder to wrist; RIGHT arm skin with grey markings on the
  > upper arm and a darker forearm patch with an orange fleck; a dark mark on the left side of the neck.
  >
  > Photos win over the fox art wherever they disagree.
- The real sleeve is mostly **solid blackout** with skin-tone negative space, darker than the fox art draws it. Facing the
  camera, his left arm is on the viewer's right. R7 covers the side sprites (above).

### Asset layout and naming (`assets/art/`; `scripts/art_manifest.gd` + `assets/art/manifest.json` = sheet metadata)
- `duff_<armor>_<red|black>.png` (apron, clogs, sleeves, coat, dad), `duff_home.png`, `duff_shades.png` (overlay
  tied to the head position: re-check it whenever a sheet changes), `duff_dress`, `duff_roll_*` (still old art). `ch_<id>.png`:
  NPC, enemy and boss sheets, including `ch_duff_suit` (tux), `ch_pirate0-3`, `ch_dolores`, `ch_waitress`.
- **Humanoid sheet format:** 256×256, 4×4 cells of 64; rows down/up/right/left (`Art.row_for`); columns stand, step A,
  step B, attack (`WALK = [1,0,2,0]`). Feet at y = 60 in the cell.
- `portraits_hd/<who>.png`: 3 cells of 512 (1536×512, transparent). Family: 0 happy / 1 deadpan / 2 furious (Octavia
  giggle/curious/wail; her pink wail eyes are intentional). Bosses: smug/shocked/enraged. `HD_PORTRAITS` = duff, madison,
  octavia, brittany, dolores, plus the 17 bosses.
- `boss_intro/<id>.png` 960×540 opaque; `ko/*.jpg` and `loading/*.jpg` 1280×720.
- Prefixes: `sf_` storefronts, `sd_` street dressing, `kp_` kitchen props, `bg_` minigame backdrops (title,
  kitchen, bedroom, nursery, living_night, kwik, grocery, pharmacy, plasma, akarui, holland), `arena_`, `av_` phone
  avatars, `face_` Madison HUD moods, `buff_`, `ic_` icons, `cat_<name>`, `ground/`, legacy `map_outside.png` / `map_objects.png`
  (now only the old bus sign) / `portrait_*` (pixel portraits, off when HD).
- Audio: `assets/audio/` (WAV sfx, `mus_<track>.ogg`: neighborhood, home, kitchen, boss, willnot, gala, date, credits;
  `main.music_track()`), `assets/sfx/ko/`. Unused legacy: `assets/iso/` + `scripts/iso/iso_test.gd` (isometric was cut).

### Import tools (`tools/`)
- `import_sheet.py`: Grok 256 4×4 sheet on a flat key → game format (`--drop N` feet offset: v1 used 3, v2 and bosses use 1).
- `import_big_sheet.py`: any-size 4×4 sheet → 256 format (one scale from the stand frame).
- `fix_sheet_cells.py`: fix wrong-facing cells before importing (e.g. `3,c=2,c:m` = row 4 is row 3 mirrored; don't use it
  for Duff because of R7).
- `tattoo_sprites.py`: deterministic pixel recolour of Duff's ink on his sheets, from backups in
  `grok_art/2026-11-09-sprites-backup/`. Safe to rerun.
- `import_portrait.py <strip> <name> --cell 512 [--margin 16] [--min-island]`: cuts an expression strip into a
  portraits_hd file (background from the top corners, keeps the largest island, equal-slice fallback).
- `import_boss_intro.py` (burst cards → 960×540; `--keyed` = old cut-outs), `import_storefronts.py`, `swap_storefront.py
  SRC NAME`, `import_dressing.py`, `import_chatgpt_trees.py`, `import_prop_sheet.py`, `import_props.py` (kp_*),
  `import_ground.py`, `gen_town_ground.py` (one-off first layout), `extract_map_objects.py` (one-off), `make_shades.py`
  (shades overlay with BOB/LUNGE per column), `make_ko_sfx.py`, `make_m7_guides.py`.
- After any import: `godot --headless --path . --import`, then render and look at full-size frames.

### Canva workflow (the current art source; Duff is on the Business plan; one Canva user at a time)
- **Scratch design: `DAHabdund5o`** (also `DAHabf2Qa9U`; the old `DAHaZZaEJBs` hit the 100-page limit).
- Edit: `create-upload-url` (POST raw bytes) → `generate-image` with the original as the FIRST reference.
- Full size without Duff downloading anything: `read-design` (open_transaction) → `add_page` + `insert_fill` per image →
  `commit` → `export-design` png (1680×945) → curl the URLs.
- Duff's refs already in Canva: front `MAHabDL4f8M`, side `MAHabLtLOTk`, eye hand `MAHabBgv_Hk`, creature `MAHabP7oeP8`.
- Prompts describe traits and never name shows (the style-fusion prompt is in `docs/knockout_cutscenes.md`). Check
  every panel for leaked reference characters (Ghoster's face ended up in the B stills).
- Other sources used: Grok (out of quota), Gemini app (by hand), ChatGPT. The "Place" agent (Cursor/Grok) hands over drops in
  `grok_art/<date>-<name>/` with a HANDOFF.md. The art is Place's and the code is Claude's.
- **Masters:** `grok_art/` (has a `.gdignore`, never ships; README has the key rules: PNG, flat `#FF00FF` or `#00FF00`, margins).
  Requests: `grok_art/requests/` (M7 backdrops, guides in `requests/m7/`). **Renders:** `docs/renders/`. **Reviews:**
  `docs/reviews/`.

---

## 6. Testing and QA
- **`tools/test_daily.gd`** (`godot --headless --path . --script tools/test_daily.gd`, must be ALL PASS, 48 checks)
  covers: full-shift order (quiz first, all 8 once, order varies), autopilot (S only, never on the inspector, grade B, doesn't
  overwrite the best), station_best upgrade and save/load, calendar (30 days, cards, known note authors, day 10
  headline, day 31 = December 1), events (unique and pooled, deterministic, weekend pool, no repeats, needs_beaten, about 75%
  rate, no_repeat cap, short_staffed, sick-day menu, ice as headline and slower walking, expiry, save/load), Falcor (day 10
  card, no event, Stay choice saved +Happiness, day 11 grief line and text, no fussy), Thanksgiving (Fork closed),
  knockout SFX (all import, cues once in order, skipping drops the later cues), stat buttons fit, `fit_text` ellipsis.
  It sets `main.save_path = "user://test_daily_save.json"`.
- **Smoke test** (before every push): `xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn
  --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600` → expect 601 frames, then look at them. Parse check:
  `godot --headless --path . --check-only --script <file>`.
- **Shot tools** (xvfb + opengl3, they boot `game.tscn` and set `no_loading`, output to `/tmp/...`):
  `qa_shot` (dialogue/toast, home, kitchen props, street combat, shops, all 17 boss intros and fights, gala; it ends any
  running shift between shots) + `qa_sheet.py`; `ko_shot -- <boss>`; `stat_shot`; `wake_shot [-- <day before>]`;
  `calendar_shot` + `calendar_sheet.py`; `shift_shot`; `arena_shot -- <id>`; `portrait_shot` (all HD faces/moods);
  `outfit_shot` + `outfit_sheet.py`; `combat_shot` + `combat_sheet.py`; `dressing_shot` + `dressing_sheet.py`;
  `actor_fade_shot` + `actor_fade_sheet.py`; `voice_shot` + `voice_sheet.py`; `map_shot` (boots main.tscn).
  Headless checks: `arena_wall_check.tscn`, `dressing_check.gd`, `text_fit.gd`.
- **Save-file gotcha:** delete the sandbox save before renders: `rm -f ~/.local/share/godot/app_userdata/*/*save*.json`.
  The file is `duffquest_save.json`, and the pattern `save*.json` does NOT match it. Tests must never write the real save
  (a test once called `_wake()` → `save_game()` and the next render hit Continue).
- After a feature adds a new overlay, rerun qa_shot and LOOK at one full-size boss frame (a tool that silently shoots
  the wrong screen is worse than having none).

---

## 7. Build and deploy
- **Web export** (preset 0 "Web", `export_presets.cfg`): `thread_support=false` (no SharedArrayBuffer/COOP/COEP needed),
  `include_filter="data/*, *.json, *.txt"` (every file read with `FileAccess`), `exclude_filter="tools/*, docs/*,
  .env, .env.*"`. `grok_art/` is excluded by `.gdignore`, and `duffquesthd/` is skipped as a separate project. Textures are
  lossless (iPhone Safari is fine). Needs the Godot **4.5-stable** web templates.
  ```
  godot --headless --path . --import
  rm -rf build/web && mkdir -p build/web && touch build/.gdignore
  godot --headless --path . --export-release "Web" build/web/index.html   # ~113 MB, mostly KO/loading JPGs
  ```
  Boot test: serve `build/web` over http, headless Chromium (Playwright, swiftshader, not cross-origin isolated),
  wait 25 s, screenshot, check the console (`docs/renders/web_boot.png`).
- **itch:** page `https://dufftkyosht.itch.io/duff-quest` (with the hyphen). butler from
  `https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default`;
  `butler push build/web dufftkyosht/duff-quest:html --userversion <sha>`; check with `butler status dufftkyosht/duff-quest`.
  Embed settings: 1280×720, mobile friendly, landscape, fullscreen button, SAB off, click-to-play. Phone fallback upload: `docs/itch_deploy.md`.
  Jam: itch "2026 Jam", closes Dec 31 (our deadline Dec 28). Add a blood/violence content tag and an AI-use disclosure.
- **Secrets:** `.env` in the repo root (gitignored and excluded from exports) holds `BUTLER_API_KEY` and `GITLAB_TOKEN`. Load it with
  `set -a; . ./.env; set +a`. A fresh clone won't have it: ask Duff and recreate it with `umask 077`. **Never commit, print or
  paste secret values. Never put tokens in `.git/config`.**
- **Git remote:** private GitLab `dufftkyosht-group/duffquest`, remote name `gitlab` (the GitHub account is suspended). Push:
  write a temp `/tmp/askpass.sh` (user `oauth2`, prints `$GITLAB_TOKEN`), run `git push gitlab main`, delete the script.
  GitLab has no CI. The old `.github/workflows/build.yml` (parse, smoke, web + debug APK, `dev` release, optional butler
  step) can't run while GitHub is suspended, and the Netlify credits are spent. `git fetch` before starting and before pushing (one
  session per repo).
- **Android** (preset 1): arm64-v8a only, version 0.11.0 (code 11), signed, immersive, no gradle build, output
  `build/android/duffquest.apk`. Package id is in `export_presets.cfg`. Signing keystore setup unverified.
- **Windows** (preset 2): embedded pck, x86_64. Its `include_filter` is empty, so `data/*.json`/`.txt` may not be packed
  (unverified, never tested).

---

## 8. Gotchas (one line each)
- Run `godot --headless --path . --import` after any asset swap, or renders show old textures and new files don't exist.
- `new_game()` is `from_dict({})`: put defaults in `d.get(key, default)`. A separate "reset" wipes data on every load.
- Tests set `main.save_path` to a throwaway file. Delete the sandbox `*save*.json` before renders.
- `main.gd` copies `shades` onto the player every frame: tools set `m.shades`, not `player.shades`.
- Overlays tied to a sheet (shades) must be re-checked in-engine whenever that sheet changes.
- Check every new art drop's scale against Duff (~26 units). Grok's fences came in 2.5× too big.
- Run `tools/dressing_check.gd` after moving props (one layout put a hydrant on Brittany and a bench on the Ensure).
- Don't infer "heavy hit" from a special's name: the spatula passes "flip" on every swing. Pass intent explicitly.
- `Camera2D.offset` ignores limits: clamp it, or the shake shows the void past the arena.
- Before calling anything "blocked on art", `ls grok_art/` and check merged Place drops.
- Judge overlays and UI from one full-size frame per screen, not a shrunk contact sheet.
- AI image refs leak their characters: check every panel. Style refs must contain no characters.
- Using one finished still as the layout ref clones its composition and faces: describe the composition per image.
- Grade impact stills on whether the x-ray is at the hit and shows the bone the narration names.
- Parody bosses: human faces only (the cartoon heads read as Hazbin imitation and went to the DLC).
- Sad scenes: quiet backdrop + dim, never the burst.
- Canva/AI sheets often draw side cells facing the wrong way: fix with `fix_sheet_cells.py` (Duff: ink side rows separately, R7).
- AI "edits" re-render the whole image: paste only the edited region back onto the original.
- Gemini ignores lists and row orders: give it short one-job prompts and edits. Storefront prompts must say "straight-on, building only".
- Wall signs lettered near the top of an arena sit under the top HUD (~35 units): ask for signs low.
- `make_m7_guides.py` has no main guard: importing it rewrites the guides (`git checkout grok_art/requests/m7/` after a run).
- `qa_shot` must end running shifts and set `no_loading`, or boss shots capture shift cards or loading screens.
- Movie-writer runs show no hit-stop (it's real-time): judge feel on a device.
- The YouTube references can't be downloaded from the sandbox. GitHub raw returns 403 (fonts came from npm `@fontsource`).
- `gh` GraphQL is blocked in Claude sessions: use `gh api repos/...` (moot while GitHub is suspended).
- The front dressing layer is picked by Duff's feet, so an enemy in front of such a tree draws under it (faded, so visible).
- Two sessions pushed on Nov 9: always `git fetch` first. One session per repo.
- Never write Duff's real surname or email into API contact fields or docs.

---

## 9. Index

### scripts/*.gd
| File | Purpose |
|---|---|
| `game.gd` | Root: SubViewport pixel world + HD CanvasLayer (portraits, loading, calendar, knockout) |
| `main.gd` | Overworld, interiors, menus, dialogue, day loop, story, gala, bounties, waffle, bets, errands, save glue |
| `art.gd` | Sprite/frame drawing, texture cache, row/walk helpers, speaker→portrait and mood mapping, `hd_enabled` |
| `art_manifest.gd` | Generated sprite metadata (size, cell, origin, kind, scale) per art id |
| `audio.gd` | Music tracks, SFX pool, bus volumes, `user://settings.json` |
| `boss.gd` | All 17 bosses: stats, lines, attacks, telegraphs, AI, sprite drawing |
| `bounties.gd` | The 86 List data, lock rules, payouts |
| `buffs.gd` | Buff kinds (SPD/STR/DEF/CHA), multipliers, durations, cleaning |
| `cast.gd` | Loads `data/cast.json`, `{token}` replacement (`N`, `T`, `lookup`) |
| `cat.gd` | House cat actors (Alastor/Lucifer/Freya sheets) |
| `combat.gd` | Level/XP/stat points, Heat, specials, Demon Time, `hit()` |
| `combat_fx.gd` | Impact sparks, rings, damage numbers, floating text |
| `combat_ui.gd` | Combat HUD: Heat bar, special, banners, allocation UI bits |
| `daily.gd` | Pure logic: calendar entries, daily event roll, effect lookups, weekends |
| `dates.gd` | Date invites, venues, costs, glow |
| `dressing.gd` | Loads and draws `town_dressing.json`, depth split, see-through fade |
| `dressing_front.gd` | z 1 overlay drawing dressing in front of actors, `actor_boxes` |
| `enemy.gd` | Street enemy kinds, stats, barks, AI |
| `errands.gd` | Daily pharmacy/grocery errand generation, due times, rewards |
| `fridge_calendar.gd` | HD fridge calendar + sticky notes screen |
| `fun_facts.gd` | 40 true deadpan facts (Palahniuk layer) |
| `gear.gd` | Weapons/armor, upgrade levels, scraps, damage reduction |
| `ground.gd` | Builds the town ground texture from the tile atlas + `town_ground.txt` |
| `hd_portrait_overlay.gd` | HD dialogue portraits + boss intro burst card |
| `hd_presentation.gd` | Warm grade, LDR bloom/vignette, lights (presentation only) |
| `hud.gd` | Pixel HUD: bars, clock, money, quest, buff icons, phone icon, dialogue box |
| `juice.gd` | Hit-stop, screen shake, zoom punch |
| `knockout.gd` | Boss knockout cutscene player (beats, effects, SFX cues) |
| `life.gd` | Money curveball events, bills/plans, plasma rules, drain |
| `loading_screen.gd` | Random loading-screen art + caption |
| `market.gd` | Stock market sim, accounts, college fund goal |
| `moods.gd` | Madison's fussy/upset/couch states and lines |
| `player.gd` | Duff: movement, roll, combo, outfits, shades |
| `player_shot.gd` | Duff's projectiles (grease, plate, reflect, hashbrown) |
| `projectile.gd` | Enemy/boss projectiles and specials (laser, wave, rug, glass...) |
| `raccoon.gd` | Friendly raccoons (gifts, gags) |
| `save_game.gd` | Save read/write/migrate (v7), cleaners |
| `shift.gd` | Fork shift flow: stations, shuffle, grades, pay, autopilot, rush |
| `tone.gd` | Procedural tone generator (22050 Hz) (unverified exact use) |
| `touch_controls.gd` | On-screen joystick and buttons |
| `transit.gd` | Bus stops, fares, pass, car, ride lines |
| `ui_style.gd` | Autoload `UiFonts` + static UI drawing helpers, `fit_text` |
| `waffle.gd` | Waffle Haus graveyard grill minigame |
| `wordle_logic.gd` | Wordle word lists, scoring, daily seed |
| `iso/iso_test.gd` | Legacy isometric test (cut feature) |
| `minigames/minigame.gd` | Base class for every minigame/overlay (frame, buttons, finish callback) |
| `minigames/card.gd` | Generic menu/result card (`_menu`, shift cards, title) |
| `minigames/quiz.gd`, `quiz_bank.gd` | Lineup quiz + its question bank |
| `minigames/prep.gd` `pickles.gd` `fryer.gd` `temp_check.gd` `sandwich.gd` `salad.gd` `garnish.gd` `inspector.gd` | Shift stations |
| `minigames/baby.gd` / `stealth.gd` | 3 AM crying baby / sneak out once she's asleep |
| `minigames/show_tell.gd` | Bedtime Show & Tell with Madison |
| `minigames/backwalk.gd` / `blackheads.gd` | SPD buff rhythm game / DEF buff tap game |
| `minigames/akarui.gd` / `symphony.gd` | Date minigames (sushi, symphony) |
| `minigames/pharmacy.gd` / `grocery.gd` / `shop.gd` / `plasma.gd` | Errand stores, Kwik-N-Go, plasma donation |
| `minigames/phone.gd` / `wordle.gd` | Phone (texts, market, fund) / Wordle |
| `minigames/mash.gd` | Door-to-door hustler mash trap |
| `minigames/gear_screen.gd` / `settings.gd` / `ending.gd` | Gear menu / settings / ending credits |

### data/*
| File | Read by | Purpose |
|---|---|---|
| `cast.json` | `cast.gd` | Every real/parody name as `{token}` (edit only this for a public build) |
| `calendar.json` | `daily.gd`, `fridge_calendar.gd`, `main._wake` | 30 handwritten November days: tag, card, notes, headline/event |
| `daily_events.json` | `daily.gd` | 14 random morning events + chance/no_repeat |
| `knockouts.json` | `knockout.gd` | 17 knockout scripts (6 beats + move) and `live` flags |
| `loading_screens.json` | `loading_screen.gd` | 14 loading captions (art must exist to show) |
| `show_and_tell.json`, `show_and_tell_family.json` | `minigames/show_tell.gd` | Madison's bedtime show-and-tell openers/items (family build variant) |
| `town_dressing.json` | `dressing.gd` | Street trees/props/fences placements |
| `town_ground.txt` | `ground.gd` | Dual-grid ground material layout |
| `words5.txt`, `answers_common.txt`, `answers_themed.txt` | `wordle_logic.gd` | Wordle valid guesses / answer pools |

### Contradictions between docs and code (found Nov 9; fix the docs when touching them)
Fixed Nov 9 night: knockout still extension, knockouts.json pilot note, loading_screens.json `_doc`, voice.md screen size,
the $150 intro, cast.gd DEFAULTS (now has `stray` + `gala_baron`). Still open below.
- `docs/knockout_cutscenes.md` says stills are `ko/<boss>_a.png`; the code and files use `.jpg`. The knockouts.json `_doc` still
  says "pilot: gymbro" (11 are live).
- `loading_screens.json _doc` says `.png` and "12 of 14 in". The code loads `.jpg`; 13 exist; `cat_sacrifice` has no art.
- CLAUDE.md lists `tools/recovery/` and `tools/gemini_art.py`; neither is in `tools/`.
- `docs/daily_life.md` event table is the draft. The shipped `daily_events.json` differs (outage = -15 Energy, not
  "home off"; inspector ×1.25 flat, not ×1.5 on A+; cat_chaos -10; boss_tips instead of boss_customer; porch_pirates = spawn ×2,
  not a porch fight; wind_chill = -10 Energy and walk ×0.9, not 1.3× drain). The data wins.
- `docs/voice.md` says the boxes are 480×270; the screen is 640×360.
- CLAUDE.md M5 says "burst-preview splashes unused (keyed versions shipped)", but the same entry and the files show the
  opaque burst cards shipped.
- M7 counts disagree: QUEUE says "3/19 done", a CLAUDE.md line says "2/19 in", and another says "the 16 M7 backgrounds".
