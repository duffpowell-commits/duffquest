# Art request M7: full-screen backgrounds (from Claude to Place, Nov 8 2026)

Hi Place. Everything outdoors, every character and every boss is in the new look now. These 19
full-screen backgrounds are the last big pieces of the old flat art. They are the rooms Duff walks
around in, the boss arenas, and the backgrounds behind the shop and minigame screens.

Duff asked for this list. Same deal as before: drop them in `grok_art/<date>-backdrops/` with a
HANDOFF.md, and Claude wires them in. Partial drops are fine; send them in priority order.

## Style
- World style bible (Drive): "DuffQuest — Style bible + Grok prompts". **Sea of Stars** pixel art:
  saturated, warm midday sun (rooms: warm lamp light), soft coloured shadows, lots of lived-in detail.
  Bright and funny, the opposite of Lethemoor.
- **Straight-on camera, top-down-ish 3/4**, exactly like the current files and the storefronts.
  No diagonal / isometric view.
- Must sit next to the sprites already in the game (Duff, Madison, bosses): same pixel density.

## Format (every file)
- PNG, **exactly 640×360**, opaque (no key colour, no transparency), filename = the id below
  (e.g. `home_interior.png`).
- 1 world unit = 2 px. Sprites stand ~52 px tall, so a doorway is ~40 px wide, a bed ~110×70 px.
- **Keep the layout.** Each id has a guide in `grok_art/requests/m7/<id>.png`: the current art on
  the left with red boxes, plus how it looks in game on the right when there is a shot. Red boxes are
  walls and furniture the player bumps into. They are code, not art, so the new picture has to put the
  same thing in the same place. Anything not boxed is free to redesign.
- The HUD covers the **top-left (stats), top-right (time/errand), bottom-left (joystick) and
  bottom-right (buttons)**. Keep the important detail in the middle.
- Lettering: only real in-world signs, spelled exactly as given below. No other text.

## The list, in priority order

| # | id | where it shows | must keep | notes |
|---|----|----------------|-----------|-------|
| 1 | `home_interior` | Duff & Madison's apartment; seen every day | bed (top-left), crib, fridge + counter (top middle), shower (top-right), couch (bottom-left), door mat + front door (bottom middle), mirror (right wall), Madison's spot | small, cluttered, loved. Baby stuff everywhere. Cat bowls. Not a showroom |
| 2 | `bg_kitchen` | behind EVERY line-cook minigame (fryer, prep, salad, sandwich, garnish, pickles, mash, temp check), dimmed 35–50% | nothing boxed; the game draws its stations on top | The Twisted Fork's line: steel, tickets, heat lamps, grease. Busy edges, calmer middle |
| 3 | `arena_alley` | 6 bounty bosses (Allergy Liar, Camper, Coupon Carol, Sends-It-Back, Birthday Dad, Dine-and-Dasher) | walls band: top 60 px, sides 16 px, bottom 16 px | "Out back of the Fork": dumpster, puddles, crates, back door, string lights |
| 4 | `arena_waffle` | The Regular's fight + the Waffle Haus night shift | same wall bands | Waffle Haus at 5 AM: counter stools, yellow glow, coffee pots. Sign: `WAFFLE HAUS` |
| 5 | `gala` | the billionaire gala, 5 bosses (Husk, Bozos, Fences, Baron, Donald) | same wall bands | over-the-top rich: chandeliers, champagne tower, red carpet, ice sculpture |
| 6 | `bg_kwik` | Kwik shop screen | none (menu on top) | gas-station store: snack racks, slushie machine, lottery |
| 7 | `bg_grocery` | grocery minigame (Hy-Whee Market) | none; the game draws aisles with labels on top, so keep a clear floor | supermarket aisles from above. Sign: `HY-WHEE MARKET` |
| 8 | `bg_pharmacy` | pharmacy screen (Walgrumps) | none | counter, shelves, a sad waiting chair. Sign: `WALGRUMPS` |
| 9 | `bg_plasma` | plasma donation screen | none | clinic chairs, TV on the wall, cookies + juice table |
| 10 | `arena_crypto` | Mr. Crypto (ex #4) | wall bands | his HoneyBunCoin mining rig: blinking servers, cables, a rug |
| 11 | `arena_djvape` | DJ Vape Lord (ex #3) | wall bands | vape lounge / club: neon, haze, DJ booth, dance floor |
| 12 | `arena_ghoster` | The Ghoster (ex #1) | wall bands | Seen Cafe: cafe tables, phones everywhere, menu board. Sign: `SEEN CAFE` |
| 13 | `arena_gymbro` | Gym Bro Supreme (ex #2) | wall bands | gym: racks, mirrors, mats. Sign: `IRON TEMPLE` |
| 14 | `arena_willnot` | Bruce Willnot, final fight | wall bands | 30th-floor office in a rigged tower: cubicles, windows to the city at night, a big red clock |
| 15 | `bg_holland` | Symphony date minigame | none | concert hall from the seats |
| 16 | `bg_akarui` | Akarui sushi date | none | small sushi bar, warm wood |
| 17 | `bg_bedroom` | bedroom minigames (back walk, blackheads, show & tell) | none | the apartment bedroom, close up |
| 18 | `bg_nursery` | baby minigame | none | Octavia's corner: crib, mobile, toys |
| 19 | `bg_living_night` | the ending | none | the apartment living room at night, warm lamp, peaceful |

**Arenas 10–14 matter most after the top 5.** Today all five are the same generic room in different
colours, so the gym doesn't look like a gym. Each boss's arena should look like their world.

## Signs the code draws today (Claude removes them when your art arrives)
- `arena_ghoster`: "SEEN CAFE - open 24/7, never replies" and "seen" tags on 4 tables.
- `arena_gymbro`: "IRON TEMPLE - NO LEG DAY ZONE".
- `arena_crypto`: "HONEYBUNCOIN MINING RIG (-99.8%)".
If you letter these into the art (spelled exactly), say so in the HANDOFF and Claude takes the code
text out.

## Later, not now
These minigames are drawn as plain shapes in code: fryer, prep, salad, sandwich, garnish, pickles, mash,
temp check, card, quiz, wordle, stealth, inspector. Each would need small prop sprites (baskets, plates,
tickets, ingredients). Claude will write a separate list once the backgrounds are in.

## Answered
- Boss intro cards: Duff picked your burst versions (Nov 8); they're in the game now.
