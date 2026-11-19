# Full game audit — Nov 19, 2026

Four tracks ran: save/load safety, quest and system logic, player-facing text (three read-only reviewers), plus
the UI render audit (44 screens, `docs/renders/ui_audit_audit_nov19.png`) and two 30-day soaks (seed 1 normal,
seed 2 lazy). The UI sheet came back clean. The fixes below are on branch `ccr-cac0fd1d-ozjlwu`.

## Fixed

| # | What the player hit | Fix |
|---|---|---|
| 1 | **Grease Trap locked the whole 86 List** from day 4 until the boss was beaten (day taps said "come back later", night taps forced the fight). | By day the board is the normal 86 List (with a toast). At night there's a card: Grease Trap / just the 86 List / not now. |
| 2 | **Cover My Shift could be accepted on a weekend** (it unlocks day 9 = a Saturday). The Fork is closed, so it auto-failed as "flaked" next morning. | She only asks while the Fork is open. |
| 3 | **Brittany's Side Gig blocked her daily bet** on the pitch day and the wait day. | The choice card has "Not yet (today's bet)"; the same-day wait falls through to her bet. |
| 4 | **Dolores's Clean Grill paid 3x for idling**: no plates touched = nothing burnt. | Needs zero burnt AND at least half the tables served. |
| 5 | **Cats' Heist blocked Freya's menu** for the whole quest. | By day / after tonight's try it shows a toast and opens Freya's menu. |
| 6 | **Markers where a tap does nothing**: Chef "!" on a closed Fork, "!"/"?" over Brittany and Chad at night. | `main.quest_marker()` hides them (2D and 3D). |
| 7 | **Quitting during the cold open lost the first bet forever** ($60 + Marketplace Mike never pitched). | Continue pitches it if it was never pitched. |
| 8 | **Save-scumming**: closing the app mid daily bet / Double or Nothing / trivia gave a free retry. | The day gate (and the Double stake) is saved when the fight starts. |
| 9 | **Web: backing out of the loading card lost a stake** (Dolores, Double). | Stakes come out once the shift/fight actually starts. |
| 10 | **Double or Nothing paid triple** (win +2x, stake never taken). | Stake goes in at the start, a win pays double back (net +stake). |
| 11 | **Thanksgiving bonus day** wasn't saved (`daily.thanks_day`). | Saved and cleaned. |
| 12 | **Phone Notes**: showed internal clue keys (`day:5`, `go:10`, `night:7`), raw choice ids ("Done. (rat)"), cut long steps off, and only ~4 quests ever fit (no scrolling). | Bookkeeping clues hidden, choices in words, steps wrap to 2 lines, finished quests are one-line rows, a More button pages. Render `docs/renders/notes_full_after_audit.png`. |
| 13 | Chef's Bad Week offer ate the Fork walk-in (you had to walk out and back in). | The offer card has "Clock in". |
| 14 | Text: "back door" vs side door; "Who Took The Porch?" casing; a hard-coded "Madison" in a dev line; new lines used "Amazon" and "FaceTime"; Dolores's "3 to 1" (it pays 3x the stake). | Fixed. |

## Not changed (Duff's call)

- **Brands in older lines (public edition):** "Cheeto Chad" / "Flamin' Hot" (11 uses), "Applebee's parking lot". Not on
  RISK_AUDIT's checked list. Rename for the public edition (`cast_public.json`) or add to the "passing brand jokes" list.
- **`#dq=` dev links work in release web builds.** A player typing one starts a new game over their save. It's also
  Duff's phone dev tool, so it stays until he says otherwise. Fix if wanted: gate `_check_debug_hash` on a debug build.
- **Free energy refill on fight entry** (bets, bounties, quest fights set energy 100 and don't restore it). Long-standing;
  looks deliberate.
- **Option labels over ~28 characters** (e.g. "Eat {partner}'s cooking...", "Spritz cologne...") render fine in the UI
  audit, so left alone.
- **Brittany "gone home" at night but the porch clue still works** — minor, left.
- Balance: two soaks ended at $3,458-$7,600 (normal) and $936 (lazy) on day 30, rent paid. Re-check after the playtest
  (CLAUDE.md Next #5).
