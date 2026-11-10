# DuffQuest review (build of Nov 10, 2026)

## Rent Is Always Due, and So Is the Polish

**Verdict:** The funniest, most specific slice-of-life RPG writing I've read in a jam-sized game, stapled to a phone port that still thinks you own a keyboard and arenas that are literally grey.

**Score: 6.4 / 10**

The writing, systems and test suite (102 checks green; six 30-day soak runs, zero engine errors) are past "jam game". The presentation isn't: most boss fights happen on a flat grey floor, the climax plays *after* the credits, and a phone player's first screen is keyboard bindings. That's a 6, with the writing dragging it up.

## The good

- **The voice is the product.** Duff at the bar, present tense, and it mostly holds. "Wind chill's a war crime. My face files for asylum." "I sell my blood twice a week. It buys me back a Tuesday." The Palahniuk choruses are rationed in `docs/voice.md` ("Rent is due. Rent is always due." capped at 3 uses), and the rationing shows. Each knockout strip runs on one device (Tyler Pivot's viewers falling from 40,000 to "1. Stream ended."), so 17 cutscenes don't feel templated.
- **The grind is actually designed.** Rent is $195 a week (`weekly_base()`: $110 rent + $40 bills + $45 household), a B-grade full shift pays about $56 before promotions (`BASE_PER_STATION` 6 × 8 stations), plasma pays a $50-$100 new-donor promo then $35, and promotions run to ×8.0 "Celebrity Chef". Shift shuffle plus Autopilot after an S grade (`AUTOPILOT_SCORE` 0.72) is a smart answer to minigame fatigue.
- **Combat has more going on than it needs.** Real-time: 3-hit combo (4 with quick weapons), dodge roll, a Heat meter, 12 specials from Searing Spatter to Eighty-Six Execution, Demon Time,.
- **The home is gorgeous.** `m7_home_gemini_ingame.png` is warm, dense, readable pixel art.
- **It's engineered like someone plans to ship it.** Soak bot, save/reload diffing, money and energy floors, gore and shake toggles.

## The bad

- **Placeholders where the fights happen.** `qa_boss_fight.png`: 12 of 17 bosses fight on bare grey. Crypto, Ghoster and Willnot share one beige office. Sir Sends-It-Back (Seniority Lv 2, so early) opens with "Out back of the Fork. Dumpster, puddles..." over a grey void. The gala is beige tiles.
- **The story ends before its best part.** Willnot (story day 12) triggers `start_ending()`, then "Post-game: the days keep going." The gala, with four of Madison's exes and Chip Leverage buying the Fork, only unlocks on `GALA_DAY` 24. Your biggest set piece is post-credits content.
- **Built for a keyboard, sold for a phone.** The title help is a paragraph of WASD/E/Space/Shift/I/G/P/F/Q/R/T. Cards show "Space", "Escape", "(H switches)". In `touch_controls.gd` the special-swap button is 12 px radius and the G button 14 px, and the labels are 10 px text at 55% alpha. The A button is both "use" and "bonk".
- **Three art styles, still.** Chibi pixel sprites, flat cartoon portraits, glossy anime KO panels. And the gala exes' world sprites don't match their own art: Tyler Pivot's KO panels show a yellow hoodie, his sprite is the old goggles-and-vest billionaire. Chip Leverage is still plainly the Donald in a red tie.
- **Content is thinner than the roster.** Bounty bosses borrow story kits: Coupon Carol uses Baron's `coins` and Fences' `update`, the Allergy Liar is Ghoster's `seen/vanish/seen`, the Camper is Gym Bro's `flex/curl`. Boss taunts lean on one formula ("I'm not unemployed. I'm pre-seed." / "...I'm 'between drops.'" / "You're not fired. You're right-sized."). Every night runs Show & Tell (~25 s), the 3 AM baby game (up to 50 s) and a stealth crawl (up to 40 s), with no skip, for 30 nights. The HUD drawer still shows "Octavia's fund $0 / 100k", a goal nobody hits in a month and that no longer gates anything.

## Top 3 fixes (ranked by a new player's first 30 minutes)

1. **Make it a phone game on screen one.** Swap the title control list for a 3-card touch tutorial (move, A, B/roll). Hide key names ("Space", "Escape", "H") when touch is active. Raise `BTN_SW_R` and `BTN_G_R` to at least `BTN_R` (11), and draw labels at 7+ size and full alpha. Split talk from attack: if an NPC or door is in range, A talks and never swings.
2. **Teach the first week instead of ambushing it.** New games start Friday with $40, $195 due Monday, and the Fork shut on weekends. Meanwhile an open Madison errand drains happiness 0.2/s real time (12 a minute). Halve week-one rent or open the Fork on the first Saturday. Have Madison's day-1 text spell out the evening routine; the story gates need 50 to 75 happiness.
3. **Kill the grey void.** Give every arena a floor before any new art lands: tinted ground plus existing dressing props per boss (dumpsters for the alley, booths for the Waffle Haus bosses, chandeliers for the gala). Do Sends-It-Back's alley first; it's the first bounty most players reach.

## Closing

DuffQuest knows exactly who it's about, and that specificity is rare. Under it sits a sturdy, tested sim. But a stranger on itch meets keyboard prompts on a phone, a grey box where the dumpster should be, and a credits roll before the best fight. Fix the first half hour and the floor goes up a full point.
