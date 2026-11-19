# DuffQuest review, take six (Nov 19, 2026, evening)

## The Door's Open. Nobody's Been Told.

**Score: 8.9 / 10** (v5 8.7, v4 8.4, v3 7.9, v2 7.1, v1 6.4)

v5 this morning said nothing mattered until the store page was up, that a silent build had slipped out, that
the economy spread was 10x between lazy and active play, and that a dev link could wipe a player's save. By
tonight most of that is done. The page is live, a silent build can't ship, the dev link is fixed, and two audits
fixed 36 bugs. What's left can't be fixed with code: nobody has played it.

## What changed since v5

- **The itch page is live.** New description, a "Minute one" hook, 8 inline clips and stills, 7 screenshots,
  cover. The inline footage loads from fixed-name files on GitHub, so swapping a clip means replacing one
  file, not re-editing itch. The page bot hit itch's Cloudflare wall and was shelved. Pasting it by hand was the
  right call.
- **The pipeline grew teeth.** CI now listens at the speakers and goes red on a silent build. It also runs the
  daily test suite and fails on any red test. Nothing broken reaches itch quietly anymore.
- **Audit round 2: 22 fixes.** The gala rematch was an unlimited money farm ($250 + ~600 XP, no clock cost). It's
  once a day now and pays $75. Also fixed: stun-locked bosses, endless Demon Time, the grocery cart spawning inside
  a shelf, and a missed ending.
- **The economy has teeth.** Seniority pay flattened from 8x to 3x at the top. Back rent and late fees now
  count, and the landlord shows up at two weeks behind. Shift meals stop being free energy. Thirty-day test
  runs that used to end on $3,458-$7,600 now end around $324 with rent paid every week. Rent matters through
  week 4 now, not just week 1.
- **Safety:** `#dq=` dev links play on their own save slot and only work in family and debug builds. 3D noon is
  less blown out.

## Biggest strengths

1. **Writing.** Unchanged and still the reason to play.
2. **It's for sale now, in the window.** The page sells the hook in the first screen: a porch-pirate fight,
   then a bet. It's honest about AI art and has a real privacy note and a parody notice.
3. **Money finally matters.** With the pay ladder flattened and the gala farm gone, Monday rent is a real
   threat for the whole month, the way the premise promises.
4. **Quality control.** Two audits in one day caught 36 player-facing bugs, and the CI gates now cover sound
   and tests. For a one-person project made on a phone, that rigor is rare.

## Biggest weaknesses

1. **Zero players, still.** Play alerts are `armed: false`. The page has never been shared anywhere. A live
   page nobody links to gets the traffic of no page.
2. **The balance pass was tuned with no human input.** Automated test runs show the money is tight now. They
   can't show whether it feels fair or miserable. Watch one number: the active run ends with $324 and the lazy
   run with $247. If working hard only beats coasting by $77 over a month, effort feels unrewarded. That
   needs checking before players decide it for you.
3. **The new quests are still unplayed.** Eleven side quests, seven of them a day old, plus 36 fixes, and not
   one human playthrough since Nov 11.
4. **Brittany's iPhone freeze is still unconfirmed fixed.**
5. **Two sessions working main at once.** Two Claude sessions pushed to main all day, which caused merge
   conflicts and broke the repo's one-session rule. Nothing broke in the game, but this is how a bad merge
   ships someday.
6. **Store footage hotlinks GitHub's raw file server.** It's clever for swapping footage. But raw GitHub isn't
   a CDN, and a traffic spike could get it throttled. Fine at zero players, worth moving before a launch push.

## Top fixes, ranked

1. **Arm play alerts and share the link once.** A subreddit, a Discord, friends. Ten real players beat
   another audit.
2. **One evening playtest each:** Duff on Android, Brittany on her iPhone. Days 1-10, hitting the new quests.
   Send bug reports from Settings.
3. **Check the active vs. lazy gap** with their notes in hand. If effort barely pays, widen the shift pay
   or the S-rank bonus before strangers notice.
4. **Keep one session on main at a time.**
5. **Before any launch push,** upload the 8 page clips to itch itself (or another CDN).

## Closing

Every review since v3 has said the same thing in a different costume: get it in front of people. Tonight that's
finally possible, and every remaining point now depends on players, not code. Share the link, get ten people
through week one, and this is a 9.
