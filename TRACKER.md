# DuffQuest tracker

One page: what's built, what's next, what could be better. Updated at every milestone, alongside `CLAUDE.md`
(the handoff) and `QUEUE.md` (the work queue). Newest first.

## Built

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

From the IGN-style review (`docs/reviews/ign_review_2026-11-10.md`) and QA, still open:

- **Gala floor** is still beige tiles; the arenas are painted now.
- **Three art styles:** chibi pixel sprites, flat cartoon portraits, glossy anime KO panels.
- **Bounty bosses reuse story moves** (Coupon Carol, the Allergy Liar, the Camper), and boss taunts lean on one joke formula.
- **Touch tutorial:** the review wanted a 3-card move / A / roll tutorial on first launch; the help text is phone-worded now but still a text card.
