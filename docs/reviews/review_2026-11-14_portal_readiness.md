# DuffQuest review, take four (Nov 14, 2026): portal readiness

**Score: 8.3 / 10** (IGN v3 on Nov 11 was 7.9)

How this was checked: current main (26aabed), `test_daily` ALL PASS, the ad shots re-rendered in the engine
(town, street at night, fryer, home, gala), a scripted Gym Bro fight and a night walk recorded at 1080p with
`tools/promo_shot`, and the copy read against the code. Nobody hand-played a 30-day run for this review; the 30-day
soak covers that path.

## What works

- **The first ten seconds.** New game opens on a porch pirate jogging at Madison's package, and the line tells a
  keyboard player "WASD or arrows to walk, Space to bonk". The rules come after the first win. On a portal, where a
  player decides in under a minute, this is the most valuable change since v3.
- **The street finally matches the fights.** v3's main complaint ("the street still looks like a board game") is
  mostly gone: 13 storefronts and 17 street props painted at 4x, time-of-day light, painted fences. The Kwik-N-Go
  corner at 10 AM and the same corner at 9:40 PM both read as one painted town.
- **Duff looks like the cover now.** HD sheets, the casual tee off the line, the smug face. The in-game hero and the
  cover portrait are finally the same guy.
- **Boot.** Title in 9.3 s on throttled 4G (was 55 s two versions ago). New Game only waits for a 2.9 MB street pack.
- **Depth for a free web game.** 18 bosses with their own arenas and comic-panel knockouts, four side quests with a
  phone Notes journal, kitchen minigames, a 30-day calendar. Most portal games have one loop. This has five.
- **The writing.** Still the reason to play. The humor audit cut 63 repeated jokes, which is the right direction.
- **Portal plumbing.** Clean/gore-off defaults for portal players, fractional scaling that fills CrazyGames' iframe,
  keyboard-first HUD placement, public-edition names everywhere, privacy policy, credits.

## What's weak

1. **The cast is half-migrated.** Duff is 2x HD; most of the people he talks to and fights are not. At the gala,
   Lance (the landlord ex) is a chunky low-res sprite in a painted ballroom, standing in a screen we use for ads. Every
   ad shot with an ex or a boss in it shows the seam. Finish the cast 2x pass for everyone in the ads (Gym Bro, the
   four gala exes, the porch pirate) before paying for any promotion.
2. **It's a slow game on a fast shelf.** CrazyGames players come for instant action. After the cold-open pirate, the
   game is four lines of rules, then errands, a couch, a calendar. The fights are where the portal crowd lives, and
   the next one is a few minutes away for a new player. Expect a steep drop after minute one. The fix is a second,
   bigger fight inside the first five minutes (the porch-mystery thread or a street bounty pointed at day one).
3. **Clean mode takes the edge off.** Portal players get clean language and no gore by default, and a lot of the
   voice lives in the swearing and the teeth. The game is still funny clean, but it's a different, milder game. The
   itch build keeps the uncut default; good.
4. **The second wait.** Continue, the kitchen, arenas and the gala wait on world.pck (~23 s cold). On a portal the
   first fight is covered by the street pack, but the first trip into the kitchen can hit a loading card mid-session.
5. **No real-phone notes on file.** Duff and Brittany played it Nov 11 ("it's come a long way"), but their notes
   aren't written down anywhere. They still outrank everything on this list.
6. **AI art and itch.** itch's crowd is touchy about AI art. The disclosure is correct and required; don't tag it
   `pixel-art`, and lead with the human story (one line cook, one phone, no computer) instead of the visuals.
7. **No revenue path yet.** CrazyGames Basic Launch is a traffic test with no SDK; money starts at Full Launch with
   the SDK and ads. GameDistribution waits on its gameId. itch is pay-what-you-want at best.

## Bug found and fixed during this review

- **Keyboard players: the level/heat panel covered the end of every boss's health bar.** The Nov 14 portal polish
  tucked the panel into the bottom-right corner (`combat_ui.PANEL_R_KEYS`), which is where the boss bar ends. It
  showed in the recorded Gym Bro take. During a boss fight the panel now sits just above the boss bar
  (`PANEL_R_KEYS_BOSS`); touch layout unchanged.

## What would most improve its chances

1. **Write down Duff's and Brittany's playtest notes** and fix what they hit first.
2. **Finish the 2x cast for everyone who appears in the ads**, then re-record the clips and the gala screen.
3. **A second fight in the first five minutes**, so a portal player sees combat twice before the life-sim kicks in.
4. **Submit to CrazyGames Basic Launch now** with the current zip; its numbers (time played, retention) tell you more
   than any review. Add the SDK for Full Launch only if Basic Launch earns it.
5. **Post the itch page** (`docs/itch/PAGE_paste.txt`) and lead socials with the true story: a line cook built a game
   about his rent, his partner and his exes on his phone.

## Ad kit check (Nov 14)

| Asset | Status |
|---|---|
| Covers (`docs/portals/covers/`) | Current. HD portrait matches HD Duff. |
| `knockout.gif`, `boss_intro.gif` | Stale: the walk-in and last hit show the old Duff sprite and the old floating level panel. Re-cut Nov 14 from a new Gym Bro take. |
| Preview clips (`docs/portals/preview/`) | Stale for the same reason. Re-recorded Nov 14 (same cut: cover, intro card, fight, KO panels, night walk). |
| Screens 01, 08, 09 | Stale (old Duff, old level panel). Re-rendered Nov 14. |
| Screens 04, 05, 06 | Current. |
| Screen 07 (gala) | Matches the build today, but Lance is still the old low-res sprite. Re-render after the cast 2x batch. |
| Screens 02, 03 | 1280x720 and older; 02 shows the old Duff. Drop them or replace with frames from the new fight take. |
| `PAGE.md` copy | Fixed: said real names were approved for the itch page (itch now ships the public edition), 17 bosses (now 18), "first load 56 MB", and tagged `pixel-art`. Added the cold open and side quests. |
| `LISTING.md` (CrazyGames) | Fixed the boss count. Otherwise current. |
