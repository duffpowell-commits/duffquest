# DuffQuest review, take two (build 9b8af74, Nov 10, 2026 night)

## The Grey Rooms Got Paint. The Thumbs Still Don't Get a Tutorial.

**Score: 7.1 / 10** (was 6.4 this morning)

Every fight now happens somewhere. Seven painted arenas plus a marble gala floor replace the grey void, the bounty
bosses inherit the alley, and the nine minigames that used beige box placeholders sit on real paintings now: a
Kwik-N-Go glowing like a crime scene at 2 AM, a Walgrumps with one sad chair, the Holland Center in full red velvet.
The climax no longer plays after the credits; the gala invite shows up the morning after. Week one stopped being an
ambush. That's most of a point.

What's left is the stuff a stranger notices in the first ninety seconds on a phone.

## What got better

- **Places, finally.** `docs/renders/arenas_painted_ingame.png` and `docs/renders/backdrops_nov10.png`. 0 of 17 bosses
  fight on bare grey (was 12). The gala is a ballroom with a melting ice swan instead of beige tiles.
- **The first week is survivable.** First Monday's rent is prorated, the Fork takes shifts that first weekend, and
  happiness gates dropped from 50/60/65/70/75 to 45/50/55/60/65. The leak while Madison waits on an errand went from
  0.2/s with no floor to 0.08/s (0.04/s in week one) and stops at 40. One grocery run no longer eats its own reward.
- **Nights respect your time.** After night one, BEDTIME offers autopilot: +8 happiness, a bottle and a diaper spent,
  no fail state. The 30-day soak hit that card 24 times without a script error.
- **Small UI debt paid.** The "Octavia's fund $0 / 100k" line is gone until there's money in it. The interact prompt
  is a dark pill with cream text instead of pale green dissolving into the rug.
- **Loading screens: 14 of 14.** The cats laying a toy mouse and a sock at the crib while tattooed Duff watches from the
  door is the best single image in the game. "I sleep with one eye open now."

## What still drags it

- **Three art styles became two and a half, and the seam got louder.** Painted HD rooms under chibi pixel sprites. In
  the gala shot a 32-pixel Duff stands on a 1280-wide oil-painting floor; the scale break reads as two games taped
  together. The overworld is still all pixel, so every minigame and arena entry is a style jump.
- **Phone onboarding is still a text menu.** "How to play" is a wall of copy. No three-card touch tutorial
  (move / A talks-or-uses / B rolls). G and special-swap buttons are 9 px radius against A's 11.
- **Minigame UI buries the new art.** Kwik-N-Go and Walgrumps are slabs of opaque teal buttons over the paintings you
  just paid for. Akarui's conveyor bar and Blackhead Patrol's card cover the room.
- **Bounty bosses still borrow kits.** Coupon Carol fights like Baron and Fences, the Allergy Liar like Ghoster, the
  Camper like Gym Bro. Six bounties, three original movesets.
- **First boot on 4G is about a minute** (38 MB index.wasm). Nobody waits a minute for a game they found by scrolling.

## Top 3 fixes, ranked by a stranger's first ten minutes

1. **Phone onboarding milestone.** Three tap-through cards on first launch (move, A, B), pixel-art hands, skippable.
   All touch buttons at least BTN_R 11. Key names never shown when touch is active.
2. **Let the art breathe.** Minigame menus go to translucent, bottom-anchored panels (about 70% alpha, max 40% of the
   screen height) so the painting reads. Same pass: render Duff 1.5-2x in arenas, or put a soft floor shadow and a
   painted-style outline under sprites, so the scale gap stops shouting.
3. **Give each bounty one signature move.** Coupon Carol's expired-coupon storm, the Camper's laptop-cord lasso, the
   Allergy Liar's "is there gluten in this?" stun. One move each beats six reskins.

## Closing

This morning DuffQuest was a sharp script in an empty theatre. Tonight the theatre has sets. The writing still carries
it: rent is due, rent is always due, and the cats are building a religion in the nursery. Fix the first ten minutes on a
phone and stop hiding the paintings behind buttons, and this is an 8.
