# DuffQuest tracker

One page: what's built, what's next, what could be better. Updated at every milestone, alongside `CLAUDE.md`
(the handoff) and `QUEUE.md` (the work queue). Newest first.

## Built

- **2026-11-10 (evening)** Title screen shows the real Duff: both tattoo sleeves and the fox on his neck, from his
  style-C portrait, in a comic panel over the in-game kitchen (`tools/title_compose.py`,
  `docs/renders/title_tattoos_before_after.png`). GitHub Actions itch deploy (`.github/workflows/deploy_itch.yml`).
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

1. **Real painted arena backgrounds** (Duff's pick, Nov 10): replace the six code-painted arenas with painted art in
   the game's style, rendered in the engine.
2. **Itch page:** make it play the CI build (`duff-quest-html.zip`) instead of the old manual upload (Duff, itch
   dashboard), then paste `docs/itch/PAGE.md` and the images.
3. **Cat loading screen:** Alastor, Lucifer and Freya.
4. **Brittany playtest** of the gentler first week on her iPhone.
5. **Balance call:** happiness gates are strict (`tasks/todo.md`), and the errand drain is harsh in week one.
6. **M7 backgrounds** still waiting on real art: the remaining scene backdrops in
   `grok_art/requests/REQUEST_M7_backdrops.md`.

## Could improve

From the IGN-style review (`docs/reviews/ign_review_2026-11-10.md`) and QA, still open:

- **Arenas:** the six code-painted rooms are stand-ins; only the gym is real art. The gala floor is still beige tiles.
- **Three art styles:** chibi pixel sprites, flat cartoon portraits, glossy anime KO panels.
- **Nightly routine:** Show & Tell, the 3 AM baby game and the stealth crawl run every night with no skip.
- **Bounty bosses reuse story moves** (Coupon Carol, the Allergy Liar, the Camper), and boss taunts lean on one joke formula.
- **HUD:** the drawer still shows "Octavia's fund $0 / 100k", a goal nobody reaches that no longer unlocks anything.
- **Touch tutorial:** the review wanted a 3-card move / A / roll tutorial on first launch; the help text is phone-worded now but still a text card.
- **Madison's errand drain** (happiness ticks down in real time) can still feel harsh in week one.
