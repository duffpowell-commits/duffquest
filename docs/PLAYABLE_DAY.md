# Survive Tuesday — first integrated playable day
2026-11-27. Proposed milestone for Wash, Rinse, Regret; planning, not implemented. Name/branding work tracked separately in PR #234. Preserve repository IDs and existing 2D edition.

## Player promise
One short day demonstrates work, home, neighborhood, optional comedy and meaningful consequences. Target 10–15 minutes, not a full month or five fully implemented stations. A competent player should feel rewarded; a mistake should create a recoverable story. The day starts and ends at home, with a clear reason to play again.

## Sequence
| Beat | Target time | Player activity | Proof |
| --- | --- | --- | --- |
| Home morning | 1–2 min | Check Duffphone, choose a daily objective, leave apartment | Readable phone, correct state, safe door transition |
| Neighborhood | 2 min | Walk to work through polished residential block; optional encounter | Existing map routes work, camera and collision clear |
| Kitchen arrival | 1 min | Clock in, choose grill, learn by doing | Station prompt and camera transition |
| Grill shift | 3–5 min | Four slots, three burger variations, flip, plate, validate tickets | Accurate orders, recoverable mistakes, readable feedback |
| Clock out | 1 min | Grade, earnings and mastery XP | Reward applied exactly once |
| Walk home | 1–2 min | Optional callback from an earlier decision | NPC memory persists and no forced interruption |
| Evening | 1–2 min | Check finances/calendar, optional household action, save and end day | Correct balances, next day preview and reload |

Targets are adjustable and not measured. Use existing economy values and day-cycle behavior; do not reset player progress. The apartment has approved B furnishings/C night treatment; residential A+C; kitchen visual and UI boards in PROJECT_ALIGNMENT.md. No unapproved partner dialogue, real-person details or likeness changes.

## Minimal interactions
- One compact residential route, apartment and restaurant; existing porch encounter remains intact. No new mandatory combat.
- Only grill is required; other stations can be decorative or explicitly closed until their milestones.
- One optional Regret Engine decision and one later callback, e.g. a fictional customer complaint resolved through a replacement order or respectful response. Glitch may gently comment once. No penalties for dismissing advice; no new real-world AI services.
- Duffphone first apps: Messages, Calendar, Banking and Glitch; read game state. No invented financial data, new economy or external connection.
- Earned station XP from accuracy and consistency; initial score weights 60% accuracy, 25% speed, 15% waste prevention. Don't duplicate existing systems. A low grade pays fairly according to existing rules; no irreversible failure spiral.
- Seven approved kitchen performance clips are the animation target; stage previews for owner approval, prioritize ready/grill/plating and shift completion.

## Implementation order and integration
1. Review current PRs #228–#234 and latest main; identify ownership and overlap. Resolve porch and kitchen visual acceptance, then reuse neighborhood foundation #231. Do not stack feature branches or merge unfinished previews into production.
2. Grill vertical slice and reusable station framework, tested independently.
3. Shared day-state adapter and scene transitions; reuse existing save, economy, clock and dialogue contracts where compatible.
4. Smallest Duffphone/Glitch and event callback implementation; wire only the necessary subset.
5. Integrate in a dedicated milestone branch from current main after dependencies are accepted. Preserve approved art and existing builds. No new paid asset credits.
6. Verify the entire day from new game and resumed saves; capture real gameplay footage and screenshots before release consideration.

## Acceptance
- End-to-end new game and resume complete with no crash, softlock, duplicate rewards, negative unintended balances, or broken doors; test early exit, retry, and interruption.
- Touch controls at narrow and wide landscape aspect ratios; opening/closing phone and stations never leaks input. Android back and focus loss handled.
- Deterministic milestone event and callback; no spoiler leakage or external calls; public cast and dialogue safeguards pass.
- Score and reward match actual actions; successful and mistaken orders are both recoverable. Save migration tested if needed.
- Root regression and 3D smoke tests pass, plus focused integration tests; CI green and existing repo review requirements honored. Actual Godot captures for home, street, grill, phone, grade and evening. Performance report reports cloud vs actual Android separately; target 60 FPS on S26 Ultra, unverified until measured. Internal 8.5 milestone quality aspiration and 9/10 release target are not claimed scores.
- Human enjoyment remains unmeasured until playtested. No new blind review while suspended. No publication or merge of gameplay without applicable gates.

## Handoff
Approved design dependencies in PROJECT_ALIGNMENT.md, DUFFPHONE_2.md and FIND_OUT_ENGINE.md. Codex is the recommended implementation tool once the prerequisite work is ready. Current planning may proceed without changing ongoing production tasks.
