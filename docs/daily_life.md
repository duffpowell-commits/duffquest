# Daily life: calendar, curveballs, bonds (spec, Nov 9 2026)

Goal: no day feels like filler. Spirit of Persona 5's calendar life, minus time slots
(Duff, Nov 9: skip time slots in DuffQuest; concept saved for future games).
Status: Duff said go Nov 9 (M10-M12; bonds cut). M10 DONE. Calendar is a **fridge calendar** with notes Duff and Madison leave each other, cats included (Duff).

## What already exists (build on it, don't duplicate)
- Day loop: wake 7:00 (`clock = 420`), sleep from 20:00, forced at 2:00. 2 game-min per real second.
- `life.gd` EVENTS: 30% roll from day 3, mostly money (bills, snow_day, missed_bus, vet...).
- `moods.gd`: Madison's fussy days (15%, 3-day gap). `dates.gd`: date invites.
- `shift.gd`: FULL = 8 stations in a FIXED order (the main grind). Rush pool already random.
- Story bosses: Ghoster d2, Gym Bro d4, DJ Vape d6, Crypto d9, Willnot d12. Day 1 is a Friday; rent Mondays.

## Rule: one headline per day
Each morning gets at most ONE headline: calendar day > curveball > life.gd money event.
If a calendar day or curveball fires, the money roll waits until tomorrow. Stops pile-ups.

## 1. Calendar (`data/calendar.json`)
Fixed handwritten days, shown on the wake splash as a "today" card (date + one line, bar voice).

| Day | | Today card | Notes |
|---|---|---|---|
| 1 Fri | | "Payday is a rumor I heard once." | intro, unchanged |
| 2 Sat | W | "Saturday. No shift. Just me and my unresolved exes." | Ghoster |
| 3 Sun | W | "Sunday. Madison sets a bowl on the porch for the orange stray. She calls him Falcor." | Falcor intro |
| 4 Mon | | "Rent day. The landlord's love language is Venmo." | Gym Bro |
| 5 Tue | | "Octavia discovers her feet. Production halts." | baby milestone |
| 6 Wed | | "Hump day. I am the camel." | DJ Vape |
| 7 Thu | | "Falcor leaves a dead moth on the welcome mat. Madison calls it a love letter." | |
| 8 Fri | | "Payday. Rush night. The Fork smells like money and pickle brine." | rush shift default |
| 9 Sat | W | "Falcor's bowl is still full this morning. Madison checks it twice." | Crypto |
| 10 Sun | W | Falcor (see 4) | quiet day, no curveball |
| 11 Mon | | "Rent day. Madison does the budget app without The Face. That's worse." | grief lines |
| 12 Tue | | "The tower's lit up downtown. Somebody's waiting on the top floor." | Willnot |
| 13 Wed | | "Madison moves the porch bowl inside. Doesn't throw it out." | |
| 14 Thu | | "Thanksgiving's coming. Earl wants to know if I'm 'doing a bird.'" | |

Past day 14: the calendar repeats paydays/rent; curveballs carry the variety.

## 2. Daily curveball (`data/daily_events.json`)
Weighted roll each non-calendar morning. No repeat within 5 days. Weekdays and weekends roll
from separate pools. Every effect reuses existing knobs (energy, spawn rate, shift pay, clock, prices).

Weekday pool:
| id | Today card (draft) | Effect |
|---|---|---|
| inspector | "Health inspector at the Fork. Clipboard energy." | shift adds the inspector station; pay x1.5 on A+ |
| outage | "Power's out on the block. The fridge is a coffin now." | home actions off till noon; Kwik closed |
| sick_day | "Octavia's running warm. Daycare says no." | shift is Quick only; +Madison if you stay home |
| cat_chaos | "Alastor and Lucifer knock the coffee off the counter. Unprovoked. Probably." | -15 energy, no coffee buff |
| boss_customer | "A beaten boss is at table six. He wants it 'well done, like me.'" | one shift station replaced by a taunt-ordered ticket |
| double_tips | "Somebody's grandma tips in two-dollar bills." | shift pay x1.25 |
| short_staffed | "Brayden no-call no-showed. Again." | full shift forced, pay x1.5 |
| porch_pirate | "Package on the porch. A hoodie is circling it." | street fight before work, loot on win |
| ice | "First ice of the year. Omaha turns into a rink." | walk speed 0.85 outdoors, enemies slip too |
| wind_chill | "Wind chill's a war crime." | energy drains 1.3x outdoors |

Weekend pool (no shift):
| id | Today card (draft) | Effect |
|---|---|---|
| farmers_market | "Market's open. Madison wants 'just one' candle." | shop with discounts, +Madison |
| park_day | "Sun's out. Octavia meets a duck. Both are horrified." | +Madison +energy, a bounty spawns in the park |
| side_gig | "Earl's buddy needs a line cook for a wedding." | optional gig minigame, cash |
| lazy | "Nothing happens. It's beautiful." | +20 energy |

## 3. Weekends
Sat/Sun: no shift. Each weekend day rolls the weekend pool. Story bosses still unlock by day.

## 4. Falcor (never drawn, only mentioned)
A stray Madison feeds. Appears only in today cards, texts and Madison's lines (days 3, 7, 9).
Day 10 is a one-time event: no curveball, no shift, no enemies on the block till noon. Sincere,
no jokes at his expense. Draft, for Duff to approve:

> Sunday. Madison's on the porch steps before the coffee's done. Falcor's curled up next to his
> bowl like he's waiting on seconds. He's not waiting on anything anymore.
> I get the shovel. She picks the spot. Neither of us says much.
> A stray is a cat that picked you without asking. That's the whole contract. He kept his end.

Then a choice: **Stay with her** (+Madison, lose the morning) / **Give her some space** (no penalty).
Days 11-13: Madison gets 1-2 quiet lines a day (no fussy rolls those days). Text on day 11:
"bowl's still on the porch. not ready to move it."

## 5. Bonds
Cut (Duff, Nov 9).

## 6. Shift changes
- FULL: same 8 stations, **shuffled** each shift.
- QUICK: **4 random** of the 8 (was a fixed 4).
- **Muscle memory:** best grade per station is saved. A station you've S'd shows an
  "Autopilot (B)" button: takes an automatic B instead of playing.
- Rush unchanged.

## Build order (one milestone each, smoke + render + push after each)
- M10: shift shuffle + muscle memory.
- M11: calendar + one-headline rule + daily curveball (data files, wake splash card) + weekends + weather.
- M12: Falcor thread.

## Decisions
- Falcor day 10 text approved as drafted (Duff, Nov 9).
