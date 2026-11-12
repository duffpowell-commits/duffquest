# DuffQuest tracker

One page: what's built, what's next, what could be better. Updated at every milestone, alongside `CLAUDE.md`
(the handoff) and `QUEUE.md` (the work queue). Newest first.

## Built

- **2026-11-12** Side quest 3 live: **Brittany's Side Gig** (`ready: true`, from day 5, daytime). She's selling the
  Fork's ranch on Marketplace in hand-lettered mason jars and Chef blames Manny the dishwasher. Pick on a card: cover
  for her (next day +$60, +5 happy, "Ranch Cartel") or tell Chef (next day +$40, no bet that day, "Narc of the
  Fork"). The pick is the quest's saved `choice`. `main.gd` `_gig_talk()` / `gig_choose()` / `gig_payoff()`. Both
  branches tested end to end. `arena_shot gig`; render `docs/renders/quest_brittany_gig.png`.
- **2026-11-12** Side quest 2 live: **The Grease Trap** (`ready: true`, from day 4). An unsigned entry appears on
  the 86 List; after 10 PM the board sends Duff out back, where the floor drain stands up (new boss `grease` in
  `boss.gd`: 180 HP, posting + charge, Grill-Boy sprite tinted amber with an oil slick and drips until it gets its own
  art). Win: +$90, 3 scrap, achievement "Fryer Exorcist". Lose: try another night; it never uses up the day's 86 List
  bounty. `main.gd` `_grease_talk()` / `start_grease_fight()` / `grease_defeated()`. End-to-end check in test_daily.
  `arena_shot` ids `grease86` / `bounty:grease`; render `docs/renders/quest_grease_trap.png`.
- **2026-11-12** Side quest 1 live: **porch mystery** (`ready: true`, offered from day 2). Madison asks Duff to find
  who keeps taking the packages; Brittany saw orange fingers; the porch yields a gas-station receipt; knocking on the
  neighbor's door (daytime only) flushes out Cheeto Chad, a 6 HP pirate who bolts. Catch him: +$60, +12 happy,
  achievement "Neighborhood Watch". Let him over the fence and the quest waits for the next knock. Triggers live in
  `main.gd` `quest_talk()` / `quest_interactables()` / `porch_quest_won()`. End-to-end check in test_daily.
  `arena_shot` ids `porch` / `chad`; render `docs/renders/quest_porch_mystery.png`. Other 3 quests still `ready: false`.
- **2026-11-12** HD-2D polish pass: painted street gets a 1-px unsharp after the fit (`tools/import_street.py`).
  Lighting follows the clock like style board 2: `hd_presentation.gd` grades the world warm morning -> gold dusk ->
  blue night (replaces the flat night overlay), warm light pools fade in at shop doors after sunset, contact
  shadows swing and stretch with the sun, and street props now cast them (`dressing.gd`). Dialogue box hugs its
  text (bottom-anchored, 40 px portrait). `grok_art/**/_work/` + `*_tmp*` are git-ignored; drop rules in
  `grok_art/README.md`. Renders: `docs/renders/lighting_day_dusk_night.png`, `dialog_box_before_after.png`,
  `ground_crisp_before_after.png`. `arena_shot at:X,Y,MIN` sets the clock.
- **2026-11-12** Side-quest backbone (HD-2D plan step 1-2): `scripts/side_quests.gd` holds one save-safe state for
  hand-made side quests (stages, clues, branch choice, NEW flag); save v8 migrate adds an empty `side_quests`, and
  `clean()` drops unknown ids / junk so no save can break the loader. Phone gets a **Notes** app (the journal). Gold
  `!` / teal `?` badges float over quest givers and over whoever the current stage needs. Dialogue now types out
  (70 chars/s, pre-wrapped so words never jump); the first tap finishes the line, the second moves on. Debug builds
  get Settings > "Dev: quests" (jump any quest to any stage or branch; Duff warps to the right NPC), and web builds
  take `#dq=quest:<id>:<stage>`. The 4 quests (porch mystery, Grease Trap bounty, Brittany's side gig, lost & found)
  are defined but `ready: false`, so players see nothing until their content lands. 32 new checks in test_daily.
  `docs/renders/side_quests_backbone.png`.
- **2026-11-11** Last teal slabs painted (IGN v3 audit): props sheet K6 (16 props). Kwik-N-Go is a shelf of picture
  tiles (honey bun, formula can, diapers, cherries...); the temp check grills a real raw cut per protein (chicken,
  turkey, beef, pork chop, ribeye, salmon; wings reuse the Fork wings, paled while raw) that browns as the core climbs;
  baby FEED/CHANGE carry the formula and diaper props. `docs/renders/shop_baby_temp_after.png`. IGN review v3: 7.9/10
  (`docs/reviews/ign_review_2026-11-11_v3.md`). Soak PASS.
- **2026-11-11** Street ground repainted: the flat tile crossroads is now one detailed pixel painting (lane lines,
  cracks, manhole, slab sidewalks, flowers and leaves in the grass) matched to the home interior's style, its roads
  fitted onto the gameplay roads by `tools/import_street.py`. Soak PASS.
- **2026-11-11** Boss taunts: the "I'm not X. I'm Y." reframe was 9 of 68 lines; 12 rewritten (Husk films the
  beatdown "in vertical, for the investors", the Regular has been sitting there "since Truman", the crypto bro's wallet
  password was his ex's birthday). New test caps the formula at 2 and bans shared openers. Last slab screens: Gear
  rows get item icons (16-prop sheet K5), the hustler fight is a door slamming shut, breading has dry/wet hands.
- **2026-11-11 (early)** Fork kitchen painted (Duff: "minigames still behind on style"): 47 house-style C props from
  three Canva 4x4 sheets + a Black Forest cake, cut by `tools/import_kitchen_props.py` (magenta key, rim-only despill
  so purple onions survive, wire-mesh cleanup). Fryer = two real fryers with baskets that brown; sandwich builds real
  layers on a plate; salad fills a real bowl; dessert is a real cake with piped cream and cherries; breading bowls,
  cutting board + tomato that dices down, hotel pans, spray/rag. Every ingredient button is a picture tile. Soak PASS.
- **2026-11-10 (late night)** "Heard." moved into the kitchens only (Duff): stripped from the intro ("That's the whole
  religion. Amen."), the raccoon gag, the gala, a combat toast, the grocery coupon win and the mirror line; the
  Heard-Chef Holler skill is now the Line-Cook Holler ("BEHIND!!"). Added where it belongs: the Fork's between-station
  button reads "Heard.", the 86 warning, and Duff answers about one in three of Dolores's Waffle Haus calls.
  `test_daily` fails if "Heard." / "HEARD!" shows up outside waffle.gd, shift.gd or the sandwich station.
- **2026-11-10 (late night)** 4G first boot 55.5 s -> 17.0 s (IGN v2 "~60 s on 4G"), measured in headless Chrome on
  a throttled 9 Mbit/s link against the real web build. First download 61 MB -> 17.6 MB: the game pack drops to
  8.3 MB (KO stills, boss intro cards, 12 loading screens, 9 scene backdrops stream in after boot as extra.pck,
  landing ~30 s in, during the title/intro) and the engine ships pre-gzipped (9.3 MB) with an in-browser unzip that
  falls back to the plain file on old browsers. HD portrait/arena art re-encoded at lossy 0.8.
- **2026-11-10 (late night)** Bounty signature moves (IGN v2 "six bounties, three original movesets"): Coupon Carol's
  coupon storm (expired coupons flutter down onto growing shadows, three on Duff), the Camper's charger-cord lasso
  (yanks Duff toward him, tangles him half a second; a roll slips it), the Allergy Liar's "IS THERE GLUTEN IN THIS?!"
  shout ring (stuns unless rolled). New `test_daily` checks for all three. Soak fixed: the bot now taps the phone
  control cards away (it had been stuck on them since the onboarding milestone); 30-day soak PASS, all three new
  fights played. `docs/renders/bounty_signature_moves.png`.
- **2026-11-10 (late night)** Arena sprite scale (IGN v2 "32-pixel Duff on a 1280-wide painting"): on painted
  fight floors Duff draws at 1.45x like the bosses, regular enemies at 1.3x, scaled around the feet; Waffle Haus
  shift stays 1x so Dolores matches. Hitboxes unchanged. Render tool got `gala:<boss>` ids and stops teleporting Duff
  off the gala floor. `docs/renders/arena_scale_before_after.png`.
- **2026-11-10 (late night)** UI style pass 2: stealth floor is one night-lit plank floor (warped creaky boards with
  ink cracks, crib, bed, pulsing step tiles for touch) over the nursery painting; Blackhead Patrol is Duff's back
  with both tattoo sleeves and the fox at his nape; Back Walk is Duff face-down on the bed with the real Madison
  sprite walking him; quiz and inspector answers are cream index cards with coloured key badges
  (`UiStyle.card_button`); temp check got a glowing grill and sear marks. Quiz question that only made sense after
  another one now stands alone. UI audit's temp-check shot was catching the shift menu (wrong key), fixed.
  `docs/renders/ui_pass2_before_after.png`, full sheet `ui_audit_pass2.png`.
- **2026-11-10 (night)** UI style pass 1 (Duff: menus + minigames should match the art): every play object in
  15 minigames drawn as a style-lock prop (ink outline, hard shadow, one cel band); art-less screens (gear, Wordle,
  settings, mash, stealth) get the cards' sunburst; phone home has a navy/teal wallpaper; store/pharmacy item grids
  moved right so the paintings show. `docs/renders/ui_audit_before.png` vs `ui_audit_after.png`.
- **2026-11-10 (night)** Phone onboarding: three tap-through control cards (walk / A / B) on a phone's first new
  game, once per install (`user://touch_tut.cfg`), replay from How to play > Show me the buttons; G/S/swap/D touch
  buttons now as big as A; no keyboard chips or "E /" prompts on touch. `docs/renders/touch_onboarding.png`.
- **2026-11-10 (night)** Canva drop live: cat_sacrifice loading screen (14/14 now), painted backdrops for
  Kwik-N-Go, Hy-Whee, Walgrumps, plasma, Holland Center, Akarui, bedroom, nursery, ending living room, and the gala
  floor. Art pipeline is now hands-off (Canva -> Zapier -> Drive -> repo, see CLAUDE.md). `docs/renders/backdrops_nov10.png`.
- **2026-11-10 (late)** Balance softened (Duff): story happiness gates 50/60/65/70/75 -> 45/50/55/60/65;
  the drain while Madison waits on a want went 0.2/s -> 0.08/s (0.04/s in week one) and never drags her below 40.
- **2026-11-10 (late)** IGN fixes: nightly routine gets a BEDTIME card after night one (play, or skip on
  autopilot: +8 Happiness, uses a bottle + diaper, no fail risk; missing supplies still cost). The dead
  "Octavia's fund $0 / 100k" drawer line + bar are gone; the line shows only once there's money in the fund.
- **2026-11-10 (late)** Interact prompt ("E / A: Talk to Madison") readable on any floor: dark pill, gold
  edge, cream text (was pale green on the teal rug). NPC/cat barks now dodge the pill instead of overlapping it
  (`barks.gd hint_rects`). Render id `hint` added (`docs/renders/hint_prompt_pill.png`).
- **2026-11-10 (night)** The six themed boss arenas are real painted art (alley, Seen Cafe, Club Cloud 9, crypto
  garage, tower office, Waffle Haus) at 1280x720 (`tools/arena_import/`), walls fitted to each painting, Waffle Haus
  grills and order rail moved onto the art (`docs/renders/arenas_painted_ingame.png`). CLAUDE.md rewritten as a lean
  handoff; the old log is `docs/handoffs/SESSION_LOG.md`. GitLab dropped for now: GitHub main is the only home.
- **2026-11-10 (evening)** Title screen shows the real Duff: both tattoo sleeves and the fox on his neck, from his
  style-C portrait, in a comic panel over the in-game kitchen (`tools/title_compose.py`,
  `docs/renders/title_tattoos_before_after.png`). GitHub is the main repo again: `build.yml` passed and pushed the
  web build to itch (`BUTLER_API_KEY` works there). GitLab is a backup mirrored by `.github/workflows/mirror_gitlab.yml`.
- **2026-11-10** IGN review fixes: phone-first touch wording and bigger outlined buttons; first Monday's rent
  prorated to half and the Fork open the first weekend; six boss arenas painted in code (alley, Seen Cafe,
  Club Cloud 9, crypto garage, tower office, Waffle Haus); the gala invite arrives the morning after the ending,
  not on day 24. Itch builds deploy from GitLab CI (`BUTLER_API_KEY` set). Tests 112/112, 30-day soak clean.
- **2026-11-10** Gala exes' world sprites (Tyler Pivot, Grant Gratuity, Landlord Lance, Chip Leverage); Mr. Crypto
  walks the right way. IGN-style review: 6.4/10 (`docs/reviews/ign_review_2026-11-10.md`).
- **2026-11-09** Money paths tested (bus pass, minivan, stocks, college fund, symphony date); CI deploy job.
- **2026-11-09** QA fixes: real weekly bill in the intro, knockout x-ray crops per boss.
- **2026-11-09** Build shrink (113 -> 54 MB), knockout gore, HUD declutter, all 17 knockouts live, gala bosses
  became Madison's exes, itch page kit.
- **2026-11-09** Parody bosses with intro cards and knockouts; Falcor's story and Thanksgiving; fridge calendar,
  14 daily events, weekends off; shuffled shifts with autopilot.
- **2026-11-08** Bar-story narration voice and fun facts; restyled menus; Duff's outfits v2; all 17 bosses with
  unique attacks and HD portraits; combat feel (hit-stop, shake, sparks, damage numbers); town dressing.

## Next

1. ~~Itch page CI build switch~~ done by Duff Nov 10. Still to paste: `docs/itch/PAGE.md` + images (Duff).
   dashboard), then paste `docs/itch/PAGE.md` and the images.
2. **Cat loading screen:** Alastor, Lucifer and Freya.
3. **M7 backgrounds** still waiting on real art: the remaining scene backdrops in
   `grok_art/requests/REQUEST_M7_backdrops.md`.
4. **Brittany playtest** of the gentler first week on her iPhone.
5. Balance softened Nov 10; re-check with Brittany's playtest.

## Could improve

From the IGN v2 review (`docs/reviews/ign_review_2026-11-10_v2.md`) and QA, still open (Nov 11):

- **Overworld is still all pixel tiles** (outside street + home): every walk into a painted fight/minigame is a style
  jump. Duff wants the FULL repaint (painted neighborhood, house, Fork/Waffle Haus exteriors, collision refit).
- Nobody has played the gentler week one on a real phone yet (Brittany).
