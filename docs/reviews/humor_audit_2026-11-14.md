# Humor audit: repeated jokes (Nov 14, 2026)

Every player-facing string in `scripts/` and `data/` (2,310 lines) was pulled and checked for repeated
punchlines, verbal tics and premises that land twice. 63 lines changed. Saves are untouched (text only, no ids,
flags or keys). Both editions get the fix: no new real names, every name still goes through `{tokens}`.

Rule used: a running gag that escalates stays (Tanner bites, Earl's exact change, "scattered, smothered, covered",
the man in row F, KO closers that throw a boss's own line back). A punchline that just shows up again somewhere
else gets cut down to its best use.

## Fixed (kept the best one, rewrote the rest)

| Repeat | Count | Kept | Rewrote |
|---|---|---|---|
| "That's the whole reason / religion / bonus / sentence / text / friendship / contract" | 7 | baby gurgle, Falcor's contract | cold open ("Three rules. I'm already 0 for 1."), shift grade, bet intro, sweet text, loading screen |
| "The body keeps the receipts." | 3 | snow walk (life.gd) | bald-shoe slide, prep knife |
| "Hell of a girl." | 3 | cake | sticky note, curb scrape |
| Body part "files a complaint / for a transfer / for asylum" | 4 | face (asylum), stomach (transfer) | brain on autopilot, back after the crib floor |
| "Nobody tips the fry cook." | 2 (adjacent grades) | Eh grade | Disaster grade |
| "...since 2019" | 4 | loading screen, pharmacy sign | back walk pop, Grease Trap |
| "...from 2009" | 2 | Coupon Carol | expired eggnog (now 1998) |
| "X is a rumor" | 3 | loading screen, mail verdict | calendar payday |
| "like it owes me/her money" | 2 | honey bun box | ironing the shirt |
| "{baby} could do this. She eats crayons." | 2 | Five-guess roast | Wordle halfway taunt |
| "Bold. Wrong, but bold." | 2 | Wordle opener | symphony mid-music clap |
| "I use my blinker" | 2 | minivan drive | symphony drive |
| "Classy." | 3 | sidewalk KO, sippy-lid wine | symphony silence |
| Boats (landlord, Chef, owner all own boats) | 9 | the landlord's (now it's his alone, and it lands at the gala) | Chef's tip pool, Chef at Thanksgiving, the owner's comp |
| "The market is three landlords / The market is him" | 2 in one event | rent notice | failed negotiation (now pays off the boat) |
| "Marry me. Again." | 2 | work cake | pharmacy run |
| "You're my favorite person" | 3 | mornings (Madison, untouched), Jen | honey buns |
| "That's kind of hot" | 2 | Ghoster KO | tower jump |
| "smell like a department store" | 2 on the same spritz | the in-person line | the text |
| Cake baked "For ME." verbatim | 2 | honey-run route | grocery-errand route |
| Earl "since 1994" | 2 in one boss | intro | a bark |
| Earl "exact change. And advice." | 3 | KO and the shift payout | the bark |
| Earl and Dolores both "thirty-one years" | 4 | Dolores = 31 years (matches main.gd), Earl = since '94 | three KO lines |
| KO x-ray "His have only ever..." | 2 | Chip's hand | Sir Sends-It-Back's taste buds |
| "HoneyBunCoin. Whitepaper's a napkin." | 2 | the ex_4 boss | scammer bark |
| "Excuse me. EXCUSE ME." | 2 | Karen | Allergy Liar |
| "Respectfully." / "Waffle Houses" | 2 | drunk | Pete (now "Waffle Hauses", fixes a real brand in the public build too) |
| Tyler "pivoting" + "Uber for X" | 2 + 2 | "pivoting to violence", Uber for dogs | Tyler's startup bark |
| "Rise and grind" / "Be your own boss!" | 2 + 2 | hustler barks | gym ex, door-to-door minigame |
| "Why is it ALWAYS glass / Why am I ALWAYS barefoot" | 2 in one boss | defeat line | hit bark |
| Objects judging me (gum rack, cologne rack, cart, kiosk) | 4 | cart, kiosk | gum rack, cologne rack |
| "dignity" | 3 | bagging area, Gala butler | card declined |
| Poverty-tax punchline two lines apart | 2 | "That's the business model." | payment plan line |
| "quota" | 3 | Inspector Tiny, inspector minigame | fare inspector |
| "Walking's free." | 2 | fare line | night bench |
| "stadium" | 2 | night bench | bonds blurb |
| Waffle Haus "never closes" | 3 | intro, clock-in | hiring sign |
| "Respect." as a tag | 7 | T-bone, calendar note, KO hat, Crocs | butler hit, bet win, Kool-Aid (now "OH YEAH."), duckling |
| Show & Tell: "extremely fluffy", plush resale price, "That's literally X / This is you" | 2 + 2 + 8 | the family file (her real shows) | the generic file only: moth, limited plush, raccoon, fitted sheet |
| "Babe. BABE." | 4 | home, texts, Show & Tell | gala crowd line |

## Flagged, NOT changed (Madison: needs Duff's yes, one at a time)

These sit in `moods.gd` (fussy days), `mornings.gd` or her real-shows file. Nothing here was touched.

1. **"One of those days"** shows up 4 times: `main.gd` (I don't know what I want / changes the list again),
   `moods.gd` (thank-you line, the "idk. nothing. everything." text). Pitch: keep the text, rewrite the other three.
2. **"...Okay. We're okay. Don't do it again."** twice in the make-up lines (`moods.gd`), one with "babe".
   Pitch: second one becomes something else she'd say when it's patched up.
3. **"Ask me again in a bit"** (`moods.gd`) vs **"Ask me again in five minutes"** (date-night indecision in
   `main.gd`). Pitch: rewrite the date-night one.
4. **"sorry in advance for today. my brain is soup"** (`moods.gd`) vs the Gala's **"I am SO sorry. In advance."**
   Pitch: rewrite the Gala line (not hers to carry), leave the fussy-day text.
5. **Family Show & Tell:** Stolas "extremely fluffy" and Blitzo "300 dollars resale" used to echo generic plushies;
   fixed from the generic side, so the family file stays as is.

## Other things spotted (not humor, not fixed here)

- Fixed in the follow-up PR: every bare "the Fork" (27 strings) now uses `{fork_nick}` (family: Fork, public: Spatula),
  the Club Fork sandwich shows as `{club_sandwich}`, and the "Narc of the Fork" achievement migrates in old saves.
- `baby.gd` hardcodes "OCTAVIA IS CRYING" instead of `{BABY}` (same name in both editions today, so harmless).
- `main.gd` dev render line `say_happy` hardcodes "Love you, Madison!" (dev shots only).

Tests: `test_daily` ALL PASS (0 failed), no SCRIPT ERROR.
