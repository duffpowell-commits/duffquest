# Narrative identity and Regret Engine — planning
Date: 2026-11-27. Creative direction approved; title clearance unresolved. No implementation or release change.

## Identity
Preferred new working title: **Wash, Rinse, Regret** (owner preference, Nov 27). Existing shipped title remains Fork Around and Find Out (PR #222) until a deliberate rename is approved and clearance is resolved. Keep repository, package IDs, save keys and URLs unchanged.
Approved tagline: "Saving the world is easy. Try surviving Tuesday."
Genre: satirical autobiographical action RPG, grounded in fictionalized working-class everyday life.
Celebrate competence, hard work and earned victories. Laugh at absurd circumstances, let serious moments breathe, and make mistakes entertaining rather than purely punitive. Keep genuine heart underneath the sarcasm. Preserve existing public-edition cast tokens, approved likenesses and dialogue approval requirements.

## Branding screening
- Wash, Rinse, Regret: preliminary exact-phrase and punctuation-variant searches found no exact game listing or trademark result; a web novel chapter uses the phrase. This is not formal clearance. Source: https://en.webnovel.com/book/36908104908455805/99136815902026921 .
- Hand Wash Only was rejected as a candidate because an existing game uses it: https://pixel-tanuki.itch.io/hand-wash-only (2025).
- 86 My Sanity remains an alternate candidate, not cleared.
- Previous title screening:
Preliminary web search on 2026-11-27 found an exact-name US trademark application, serial 99296333, filed July 24, 2025, with downloadable game software, card games and online computer games in the listed goods/services. A secondary docket reports a notice of allowance dated June 9, 2026, live/pending; the current official status could not be retrieved from the TSDR page. This is a material naming risk, not a legal conclusion. No exact match for the full tagline surfaced in limited web searches. Neither title nor tagline nor feature names are cleared. Do not expand branding investment until a decision following further clearance; no automatic rename, filing, or spending.
Sources: https://tsdr.uspto.gov/#caseNumber=99296333 ; https://tmng-al.uspto.gov/resting2/api/casedoc/cms/case/99296333/office-action/OfficeAction8070802.pdf ; https://www.trademarkia.com/fork-around-and-find-out-99296333 ; https://www.uspto.gov/trademarks/search/comprehensive-clearance-search-similar-trademarks

## Regret Engine (formerly Find Out Engine)
Everyday decision -> complication -> player response -> consequence -> remembered incident -> later callback. Reuse existing daily events and quest state rather than duplicating them. The player can decline optional events. No unavoidable ruinous consequences or constant punchlines.
Seven categories: kitchen chaos, neighborhood absurdity, marketplace disasters, financial surprises, workplace politics, social misunderstandings, Glitch commentary.
Initial scope: 12 events, five recurring fictional characters, three running joke chains:
- Marketplace Misery: questionable purchases, repair or return opportunities, Mike remembers outcomes.
- Kitchen Karma: workplace mishaps and coworkers' reactions, recovery through competent work.
- Glitch Was Right: ignored in-game advice can unlock optional callbacks, never punishment merely for declining advice.
Example: a questionable $35 toaster listing; buy, negotiate, request a demonstration, or walk away. Each branch has its own outcome and potential later callback.
Initial tuning weights: minor inconvenience 45%, positive surprise 25%, comedic opportunity 20%, major complication 8%, rare absurdity 2%. Proposed tone mix 70% believable everyday absurdity, 30% heightened satire. These are starting targets, subject to play evidence.
NPC state: trust, respect, annoyance, and bounded shared-history flags. Callbacks progress introduction -> recognition -> escalation -> payoff, then cool down. Persist event IDs, choice IDs, cooldowns and resolution flags; avoid duplicate rewards on reload. Glitch may surface remembered incidents in an optional Questionable Decisions view, without real-world data or network calls. See DUFFPHONE_2.md.

## Development loop and dependencies
Plan -> art -> implement -> verify -> review -> refine -> handoff. Prioritize porch acceptance, kitchen visual quality, grill station, then daily-life/neighborhood foundations before this system enters implementation. Existing 2D edition stays intact. Target 60 FPS on Android and studio internal 9/10 release quality; neither is a measured result.
Future tests: save/reload determinism, choice effects only once, cooldowns, no inaccessible required events, accurate Glitch context, public-edition privacy, phone navigation and interruption handling. Use actual engine screenshots and test evidence.
