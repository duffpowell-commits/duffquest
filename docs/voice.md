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
  (480×270 screen). Cut words before adding them.
- No double quotes inside a line unless they were already escaped (`\"`); use single quotes for
  quoted speech inside narration.
- Keep the joke. If the original punchline already lands, change only the framing.
- Light profanity is fine where the original already has it; don't add new slurs or meanness.

## Examples
| Before | After |
|---|---|
| Fryer smell: gone. I smell like Irish Spring and regret. Good enough. | So I scrub the fryer off me. Now I smell like Irish Spring and regret. Upgrade. |
| You and {partner} veg out on the couch. She steals the blanket. {cat1} sits on the remote. | So me and {partner} veg out on the couch. She steals the blanket. {cat1} sits on the remote like he pays the cable bill. |
| Fridge is 86'd. One sad pickle. Even he looks tired. | I open the fridge. Eighty-sixed. One sad pickle, and even he looks tired. |
| CRIT! The Cleaver hungers. | (unchanged: combat bark) |
