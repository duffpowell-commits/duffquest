# Soak test report (Nov 9 2026, branch qa-soak)

## How to run
```
# one seed (about 10 min headless, 30 game days)
XDG_DATA_HOME=/tmp/xdg_soak godot --headless --path . --fixed-fps 30 --script tools/soak.gd -- --seed=1
#   --days=N  shorter run    --lazy  bot skips work, cats, bills and the evening couch (broke/upset paths)
# batch: seeds 1 2 3 + 4 lazy, two at a time, one line per seed, exit 1 on any failure
tools/soak.sh            # or: tools/soak.sh 5 6   /  DAYS=5 tools/soak.sh 1
```
`--fixed-fps 30` matters: it makes every frame 1/30 s, so loading screens, knockouts and minigame
timers run at full speed headless. Logs go to `/tmp/soak/seed_<n>.log` (`SOAK_OUT` to change).
The game saves to `user://soak_<seed>.json` and the file is erased at the end, so the real save is never touched.

## What it does
`tools/soak.gd` (SceneTree script) boots `game.tscn`, so the HD layer is live too (loading screens,
fridge calendar, knockout cutscenes). It starts a new game and plays every day with a seeded bot.
The bot only stands in for the thumbs: every action goes through the game's own functions
(`interact()`, menus, minigame buttons, `debug_solve`, `_on_attack()`).

Each day:
- Wake (night report, Show & Tell, 3 AM baby shift, stealth back to bed), loading screen, fridge calendar
  (tapped away after ~1 s; also opened from the fridge some mornings), daily event or calendar headline.
- Home: cats, Madison (quests, story announcements, deliveries, dates), random crib/shower/kitchen/
  mirror/Freya/back walk, the mail table (bills: pay/plan/ignore/negotiate/gig).
- Out: next story boss when unlocked (menu, fight, **knockout cutscene**, defeat flow), one bounty
  a day off the 86 List (locked ones get the "not yet" line or are forced), the Fork on weekdays
  (Full, Quick, Rush in turn, every station incl. the lineup quiz, Grill-Boy fixes, inspector, autopilot),
  the Fork on weekends/Thanksgiving (closed lines), Kwik-N-Go / pharmacy / grocery / plasma in rotation,
  a street fight (1-3 enemies from the day's spawn pool), Brittany's bet, phone, Wordle, bus, gear.
- Evening: shower if I smell like the fryer, Madison, couch time, bed. Every 6th night with 3+ shifts:
  Waffle Haus graveyard (grills worked, crowd fought, Earl on his nights), which wakes into the next day.
- Day 10 Falcor card (Stay / Space, random), day 28 Thanksgiving, Mondays rent.
- Day 15: save, free the whole game scene, boot a fresh `game.tscn`, Continue, then compare every
  saved field to the snapshot.
- Day 20: the gala (5 billionaires back to back, knockouts). After Willnot: the finale and the ending.

Minigames: 65% `debug_solve` (80% good runs), 20% "monkey" (random enabled buttons for 4 s, then a
random score), 15% left alone to time out by themselves (flags any that don't stop at their limit).
Cards: the option the bot asked for, else a random real option (12% any, incl. Never mind/Later).
First knockout of each boss plays in full; repeats get tapped through beat by beat.

Checks every frame: SCRIPT ERROR / push_error / warnings (an `OS.add_logger` Logger, Godot 4.5),
softlock (nothing in the state signature changes for 1500 frames = 50 s), a day longer than 60k frames,
NaN/inf or negative money, energy/happiness outside 0-100, negative inventory or scrap,
textures the game asked `Art.tex()` for that don't exist, and the reload diff. Exit 1 on anything.

Bot "assists" are logged, not hidden: happiness nudged to a story boss's gate if the bot's play left it
short 1+ day after the unlock day, god mode on the retry after a lost story fight, forced bounty when
below its Seniority level, damage chip-in if a fight passes 2 min, gala unlocked (the college fund
can't reach $100k in 30 days).

## Results (final code)
| Seed | Days | Engine errors | Issues | Assists | End state |
|---|---|---|---|---|---|
| 1 | 30/30 | 0 | 0 | 4 | ending seen, gala beaten |
| 2 | 30/30 | 0 | 0 | 4 | ending seen, gala beaten |
| 3 | 30/30 | 0 | 0 | 5 | ending seen, gala beaten |
| 4 lazy | 30/30 | 0 | 0 | 6 | ending seen, gala beaten |
| 5 | 30/30 | 0 | 0 | 3 | $658, 3 rents paid, 1 late notice, 22 shifts, 16 achievements |
| 6 | 30/30 | 0 | 0 | 1 | $242, 3 rents paid, 1 late notice, 22 shifts, 16 achievements |

Seeds 1-4 ran before the evening couch step was added to the bot (that's why they needed more
happiness assists); 5-6 are the current bot. Every run covered: all 5 story bosses (and a lost
story fight + retry), all 6 bounties, Earl, the 5 gala bosses, all 11 live knockouts, the ending,
all 3 shift modes and all 8 stations + inspector + both Grill-Boy fixes + autopilot, Falcor,
25 minigame scripts (shop, pharmacy, grocery, plasma, phone, settings, gear, Wordle, baby, stealth,
Show & Tell, back walk, blackheads, mash, akarui date, ending, every kitchen station), the reload.
Also after the fixes: `--import` clean, `test_daily` ALL PASS (50 checks), smoke no SCRIPT ERROR.

## Bugs found and fixed
1. **Money went to -$10** (seed 1, day 9). The `farmers_market` weekend event costs $10 and
   `daily_new_day()` added its money effect with no floor, so a broke morning showed -$10.
   Fix: `money = maxi(0, money + ...)` (broke = no candle). Regression check in `test_daily`.
2. **Energy went negative** (seed 1, days 2-3). `hurt_player()` did `energy -= dmg`, so a big hit
   left energy at e.g. -3 until the next frame's knockout/pass-out check (the HUD could show it).
   Fix: `energy = maxf(0.0, energy - dmg)`; every lose check already uses `<= 0`. Regression check in `test_daily`.

Both are one-line fixes in `scripts/main.gd`; nothing in knockout.gd, combat barks, dressing or assets was touched.

## Found, not fixed (with repro)
- **The naive player can't make the story gates.** Without the evening couch step, the bot
  (works every weekday, shops, does what Madison asks when it has the items) sat under the
  happiness gate for 4 of 5 story bosses on every seed and was upset at bedtime every night
  (fryer smell after shifts, missed errands), so it never saw Show & Tell. Repro: run seed 1-3 with
  the couch step removed from `_evening()` in `tools/soak.gd`; see the "happiness X -> Y" assists.
  With couch time most evenings, seed 6 made every gate with zero help. Balance call for Duff,
  not a code bug: the game leans hard on "shower, then couch" and doesn't say so.
- **College fund can't reach $100k in 30 days**, so the gala (5 of the 17 bosses) is post-game in
  practice. By design as far as I can tell; the soak unlocks it on day 20 to cover the fights.
- **`Art.tex("")` is asked for** somewhere (an optional slot probing for art); it's null-checked and
  harmless, so the soak ignores the empty name. Not tracked down.
- **Smoke prints "2 resources still in use at exit"** when `--quit-after` ends it. Engine shutdown
  noise, not a SCRIPT ERROR; baseline commit 5ee5f84 prints the same.
- Not covered by the bot: the symphony date (only the akarui date came up), the bus pass/car purchase,
  stonks trades on purpose (the phone monkey hits them at random), Freya at 5 trust, a full 100k fund.
