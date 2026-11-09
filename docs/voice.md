# Duff Quest writing voice

**Duff telling the story at the bar after a shift. Present tense.** (Duff's call, Nov 7 2026.)
"So I walk in, right, and..." EarthBound-dry, a little satirical, warm underneath.

## What changes
- **Narration** (what happens, descriptions, results of actions, item pickups, home life,
  errands, quest setups, notices, flavor text) becomes Duff telling it, first person, present
  tense. Second-person "You..." narration becomes "I...". Stage directions become story beats.
- **Duff's own lines** stay first person, just more storyteller: setup, then the punchline.

## What does NOT change
- **Other characters' quotes.** `{partner}: "..."`, Inspector Tiny, bosses, NPCs keep their own
  words. Duff can frame them ("Then Madison goes, '...'") only when the line is narration that
  contains a quote, not when it's a speaker-labelled line.
- **Combat barks** (CRIT!, hit/bonk results, damage pops, short callouts): keep them short and
  punchy. A story mid-fight kills the timing.
- **UI**: buttons, menu labels, stat names, prices, control hints, place names, titles,
  quiz questions/answers, word lists.
- Madison's show-and-tell lines (`data/show_and_tell*.json`): that's her talking.

## Rules
- Keep every `{token}` (`{partner}`, `{baby}`, `{cat1}`...) and every format code (`%d`, `%s`,
  `%.1f`, `%%`) exactly, same count and order.
- Keep `+5 Energy`-style stat results at the end of the line, unchanged.
- Length: aim for the same length; never more than ~1.4× the original. Text boxes are small
  (640×360 screen). Cut words before adding them.
- No double quotes inside a line unless they were already escaped (`\"`); use single quotes for
  quoted speech inside narration.
- Keep the joke. If the original punchline already lands, change only the framing.
- Light profanity is fine where the original already has it; don't add new slurs or meanness.

## Tic budget (Nov 7 polish pass)
The first rewrite overdid the storyteller tics ("So..." x68, "Then..." x23, "goes," x16,
", right?" x10). Read in a row, a few popups a minute, it turned into a gimmick. Rules now:
- **"So..." only opens a scene or a story**: the intro, loading a save, arriving somewhere new
  (Waffle Haus, the gala tower, downtown), a time jump ("So it's 2 AM."). About 10 in the game.
- **Quick popups are Duff's thoughts, not a story**: results, pickups, bills, cat stuff. Short,
  first person, punchline last. "Fridge is 86'd. One sad pickle. Even he looks tired."
- Quotes use `Name: '...'`, not `Name goes, '...'`. ", right?" at most once in a while.
- If the original line was punchier, keep the original words and only fix person/tense.
- Card titles match their body (no "Your ..." title over a first-person body).

## Examples
| Before | After |
|---|---|
| You dropped the {phone}. It landed screen-first, like toast. | I drop the {phone}. Screen-first, like toast. |
| You and {partner} veg out on the couch. She steals the blanket. {cat1} sits on the remote. | So me and {partner} veg out on the couch. She steals the blanket. {cat1} sits on the remote like he pays the cable bill. |
| Fridge is 86'd. One sad pickle. Even he looks tired. | (unchanged: already lands) |
| CRIT! The Cleaver hungers. | (unchanged: combat bark) |

## Palahniuk layer (Nov 8, Duff's call)
Still Duff at the bar, present tense. On top: Chuck Palahniuk's *tone*, never his text (no quotes,
no lifted lines; everything is original). What we borrow:
- **Fragments as rhythm.** "Floor. Fully dressed." Short sentences, then one that turns the knife.
- **Choruses.** A few lines that come back word for word at the same kind of moment. They gain
  weight by repeating, so they must stay EXACT and stay RARE. Current choruses and where they live:
  | Chorus | Where | Budget |
  |---|---|---|
  | `Rent is due. Rent is always due.` | intro rent line, Monday rent payment, end credits | 3, don't add more |
  | `Hell of a girl.` | Madison saves/loves him: knockout pickup, cake, mirror note | 3 + the ending if ever |
  | `The body keeps the receipts.` | the job's toll: bald-shoe slide, snow walk, knife nick | 4 max |
  | `Nobody tips the fry cook.` | bad shift grades (C, F) | 2 |
- **Deadpan facts.** `scripts/fun_facts.gd`: 40 real facts, each with one turn back onto Duff's life.
  Shown on 35% of bus/minivan rides and once after "So where was I." on load. Every fact must be
  TRUE (or framed as "legend says"); check numbers before adding one. Keep ~120 chars.
- **Aphorisms.** "A shortage is just a price with a press release." One per line at most.
- **The body.** Burns, numb toes, bald shoes, plasma: the cost lands on Duff's body, said flatly.

What we DON'T borrow: shock/gross-out content, cruelty, nihilism. The game stays bright and warm
underneath; Madison, Octavia and the cats are never the joke's target. If a line already lands (most
satire lines do: "Nobody needs a gnome. The economy needs you to need a gnome."), leave it alone.
Budget: about one Palahniuk-flavoured line in five popups. Rewrites: `tools/rewrites/palahniuk_m9.json`
(22 lines, applied with `tools/apply_rewrites.py`).

## Knockout strips (Nov 9, M14)
Duff: "the dialogue for each strip is too similar." Read in a row, 17 strips with the same shape (He's X / I'm Y / I bounce;
he throws X, I step around it; "The human ___ has N bones"; a pet-name quip; a shrug-aphorism) turn into a template. Rules:
- **One device per strip** that runs through its beats: a running number, a format (ticket, tracking, error popup, timestamps),
  addressing the boss as "you", or plain sincerity (Earl). Don't reuse a device across bosses.
- **Budgets across all 17:** "Fun fact" x1, "The human ___" x2, "I bounce" x1, one bet line, Dolores pet names x2 (sweetie, hon).
- **The x-ray line names the bone the art shows being hit.** If the still changes, the line changes.
- Keep lines that already land word for word (finishers mostly).

