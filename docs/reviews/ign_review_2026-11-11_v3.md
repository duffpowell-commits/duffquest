# DuffQuest review, take three (Nov 11, 2026)

## The Kitchen Finally Looks Like a Kitchen. The Street Still Looks Like a Board Game.

**Score: 7.9 / 10** (v2 was 7.1, v1 was 6.4)

All three of v2's ranked fixes shipped. A phone player gets three tap-through control cards before anything moves.
Duff fights at 1.45x on the painted floors, so he no longer looks pasted onto a stranger's oil painting. Coupon Carol
drops expired coupons on you, the Camper yanks you in with a charger cord, and the Allergy Liar's "IS THERE GLUTEN IN
THIS?!" ring stuns you unless you roll. None of the six bounties borrows a moveset now.

Then the minigames got the paint the arenas got. The Fork line has real fryers with baskets that brown, a sandwich
that stacks on a plate, a Black Forest cake you pipe cream onto, and a tomato that dices down on the board. At the
Kwik-N-Go you shop from a shelf of products, not a grid of teal slabs. The temp check puts an actual raw ribeye on
the grill and browns it as the core climbs. That's most of the jump.

## What got better

- **First ten minutes on a phone.** The onboarding cards are `scripts/touch_tutorial.gd`
  (`docs/renders/touch_onboarding.png`). First boot on throttled 4G went from 55.5 s to 17.0 s: the first download
  dropped from 61 MB to 17.6 MB and the rest streams in during the title.
- **Minigames match the fights.** The Fork kitchen has 47 painted props, and 16 more cover the Kwik-N-Go shelf, the
  baby's formula and diapers, and the seven raw cuts (`fork_kitchen_before_after.png`,
  `shop_baby_temp_after.png`). Quiz and inspector answers are index cards. Stealth is a creaky plank floor. Blackhead
  Patrol is Duff's tattooed back.
- **The bosses got funnier.** 12 taunts were rewritten. Husk films your beatdown "in vertical, for the investors" and
  the Regular has been waiting on his refill "since Truman". A test now caps the old "I'm not X, I'm Y" formula.
- **The street is one painting.** The flat tile crossroads now has cracks, lane lines, a manhole and leaves in the
  grass, and it matches the home interior.
- **It holds up.** The 30-day soak passes with 0 issues and `test_daily` is all green.

## What still drags it

- **The overworld is the last style seam.** The ground is painted now, but the 13 storefronts are small pixel sprites
  on small footprints. The trip from the street to a painted interior or arena is still a jump in fidelity. It's
  smaller than v2's, but it's the first thing a stranger sees after the title screen.
- **Five screens are still flat:** the phone screen, symphony, show & tell, the grocery aisle map and the wordle
  keyboard. They aren't ugly. They're plain next to everything around them.
- **Nobody has played it on a real phone.** Every touch claim here comes from a forced-touch render in a headless
  engine. Brittany's iPhone run is the only test that counts and it hasn't happened yet.
- **17 seconds is better, but it's not instant.** That's fine for a scroller who's curious. It's a coin flip for one
  who isn't.
- **The itch page is still a stub.** `docs/itch/PAGE.md` and the images exist, but nobody has pasted them in. A good
  game behind a bare page gets about the same clicks as a bad one.

## Top fixes, ranked by a stranger's first ten minutes

1. **Real-phone playtest (Brittany, iPhone).** It costs nothing and could change everything below it. Watch for thumb
   reach, the tutorial cards, and whether week one still feels gentle.
2. **The itch page.** Paste `PAGE.md`, the cover, and 4-5 renders. Without it nobody finds the game, and polish
   doesn't matter.
3. **Overworld repaint.** Painted neighborhood, home and Fork exteriors at real footprints, so walking around reads
   like the fights and minigames. It's the biggest visual gain left, and a big job: give it a whole session.
4. **The last five flat screens.** One props sheet (phone apps, music stand, show & tell table, grocery map tiles,
   letter tiles) wires the same way the shop did.
5. **Boot under 10 s.** Measure what's left in the 8.3 MB index.pck and move the next-biggest chunk (likely music)
   to extra.pck.

## Closing

The writing carried v1. v2 gave it sets. v3 makes the game look like it all came from one place, everywhere except
the street between those places. Get it onto Brittany's phone, put up the store page, and repaint the walk. That's an
8.5 in a week.
