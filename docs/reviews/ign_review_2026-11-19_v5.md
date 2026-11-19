# DuffQuest review, take five (Nov 19, 2026)

## Omaha Finally Breathes. It's Still Playing to an Empty Room.

**Score: 8.7 / 10** (v4 8.4, v3 7.9, v2 7.1, v1 6.4)

Two days, 53 commits. v4's list was: the town is a still life, the kitchen screens talk too much, the second wait is
too long, fights have no weight, and nobody can find the game. Four of those five got fixed. The fifth, the one that
costs ten minutes, is still open.

## What changed since v4

- **The town moves.** Vans brake for Duff, walkers step around him, pigeons scatter, steam comes off roofs, leaves and
  weather drift across the screen. A circle wipe on every door. In 3D, the depth pass adds camera sway, rounded
  cut-outs, contact shadows, trees that bend in the wind and haze. It finally reads as a place, not a diorama photo.
- **Fights hit.** Squash on impact, swing smears, roll dust, a push-in when a fight opens. Plus EDM stings: a riser and
  808 drop on every knockout. That KO sting is the best two seconds of feedback in the game.
- **Content nearly tripled.** Side quests went from 4 to 11: three more Brittany stories, Chef's Bad Week, the Cats'
  Heist, the Porch Pirate King, Dolores's side bets at the Waffle Haus, Thursday trivia night, Neighborhood Watch.
  No new art needed for any of it, and it doesn't feel recycled because the writing carries it.
- **A second soundtrack.** Settings > EDM soundtrack swaps every track for a synthesized one: lo-fi house at home,
  dubstep for DJ Vape, drum & bass for Willnot. Optional, off by default, and good.
- **Kitchen screens shut up.** The fryer is a colour gauge, tickets are picture tiles. Readable mid-rush on a phone.
- **Second wait halved.** Continue downloads 8 MB instead of 17.6, and returning players skip it entirely when only
  code changed.
- **Thumbs.** Bigger, spaced-out touch buttons; taps go to the nearest button. Fat-finger complaints addressed.
- **Today's audit** fixed 14 real bugs, including a quest that locked the whole 86 List and a bet that paid triple.

## Biggest strengths

1. **The writing.** Still the reason to play. Madison's stories (*The Zebra*, *Too Loud*, *Look At This*) are warm and
   specific; the new quests keep the voice (Dolores's book, the Lunch Thief).
2. **Density.** A day now has more going on than you can do: shift, bet, quest, trivia, watch request, home. That's
   the life-sim loop working.
3. **Feel.** The town and the fists finally match the art. KO stings + squash + push-in make fights feel like an
   event.
4. **Safety net.** Day/week rollbacks, a free get-up per day, saves that don't let you scum bets. Failing stings but
   never wipes you.
5. **Ship speed.** Every merge is on itch and the home-screen app in minutes, behind a daily test suite and 30-day soaks.

## Biggest weaknesses

1. **Still nobody can find it.** The itch page bot was built today but its only run failed: the login secrets aren't
   set. Play alerts are still `armed: false`. Eleven quests and a second soundtrack behind a bare page is the same
   traffic as a bad game. Same #1 as v4, two days later.
2. **The web build was silent until today.** No music, no sfx, on itch, for an unknown stretch. Nothing in the test
   suite or CI caught it; Duff did. That's the scary one: the pipeline proves the game *runs*, not that a player
   hears or sees it. A headless "does sound reach the speakers" check exists now in a session; it isn't in CI.
3. **Shipped faster than tested.** Seven new quests landed in one day, and the same day's audit found 14 bugs in them
   and their neighbours. The next batch will have its own 14. Slow the content rate until someone plays it.
4. **Brittany's iPhone freeze is unsolved.** It never reproduced; four blind fixes went out. Unknown if it's fixed.
5. **Balance is still one player's mood.** No outside player has touched it. Soaks end day 30 with $936-$7,600: a
   10x spread between lazy and normal says the economy is either too loose or too punishing, and nobody knows which.
6. **The 3D day look is blown out.** Bright daytime street renders wash toward flat yellow, and tilt-shift blurs the
   top of the screen where the storefronts are. Night and rooms look great; noon looks overexposed. And tilt-shift's
   cost on Duff's Android is still untested.
7. **Public-edition loose ends.** "Cheeto Chad" / "Flamin' Hot" (11 uses) and "Applebee's" are real brands in the
   public build, and `#dq=` dev links work in release builds (a player can start a new game over their save).

## Top fixes, ranked

1. **Set the two itch secrets and run the page bot, then arm alerts.** Phone-doable: GitHub app > Settings > Secrets.
   Nothing else on this list matters at zero players.
2. **Phone playtest of the 7 new quests + the iPhone freeze** (Duff's Android, Brittany's iPhone). Freeze new content
   until it's back.
3. **Put an audio check in CI** so a silent build goes red instead of live.
4. **Two outside players for balance**, then one pass on the economy spread.
5. **Tame the 3D noon look** (less bloom/exposure by day, lighter tilt-shift at the top edge).
6. **Rename the brands for public and gate `#dq=` to debug builds.** Small, do it before the page goes up.

## Closing

v4 said "add the living town and it's knocking on 9." The town lives, the fists land, the content is deep. It's
knocking. What keeps it at 8.7 is that nothing is watching the door: no page, no players, and a silent build that got
out unnoticed. Fix the page and the audio check this week and the next review starts at 9.
