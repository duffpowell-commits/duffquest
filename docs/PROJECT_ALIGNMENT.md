# Wash, Rinse, Regret — project alignment
Date: 2026-11-27. Planning baseline; not a release or new runtime milestone.

## Creative identity
Preferred title: Wash, Rinse, Regret (pending clearance and deliberate release rename).
Tagline: Saving the world is easy. Try surviving Tuesday.
Satirical autobiographical action RPG about the absurdity of everyday working-class life; humor with heart. Cooking is hands-on; Rush is tactical. Narrative and dynamic comedy: [Regret Engine](FIND_OUT_ENGINE.md). Phone and offline assistant: [Duffphone 2.0 / Glitch](DUFFPHONE_2.md).

## Visual direction
Hand-painted stylized 3D, expressive characters, authentic weathered Omaha interiors, amber practical light and cool shadows. Existing approved models, likenesses, outfits and tattoo/piercing masters are canonical. No random celebrity or unrelated artwork used as character reference. Kitchen concept is quality target, not a claim about current engine output. Immersive room, not floating diorama; three-quarter exploration camera and closer contextual station camera.
Material priorities: brushed stainless steel, aged ceramic tile, red/cream checkerboard, red booth upholstery, rubber mat, painted wood and cast iron. Modular appliances, ventilation, counters, dining furniture, food, utensils, lighting and environmental clutter. Reuse assets before spending; no new paid assets approved.

## Approved visual reference boards (Nov 27)
- Exterior: [A + C neighborhood comparison](art/wrr-concepts/neighborhood-options.jpg). A is the primary treatment: golden-hour warmth, weathered painterly 3D, cool shadows; borrow C's richer teal, blue, green and red accents. Preserve existing geography and collision paths. Polish one residential block before expanding.
- Apartment: [B + C apartment comparison](art/wrr-concepts/apartment-options.jpg). B supplies colorful domestic furnishings and teal accents; C supplies amber lamplight and deep cool nighttime shadows. Preserve the established game layout and approved personal details; these invented concept rooms are not layout replacements. Relationship dialogue remains subject to existing approvals.
- Kitchen: [atmosphere benchmark](art/wrr-concepts/kitchen-atmosphere.jpg) and [gameplay benchmark](art/wrr-concepts/kitchen-gameplay.jpg). Match the warm, distressed materials and immersive room; existing approved character assets remain canonical.
- All four are generated concept boards, not Godot screenshots or production assets. JPEG copies retain full concept composition; originals are preserved separately. No celebrity or unapproved character likeness reference is implied.

## Storefront and residential asset reference batch (Nov 27)
- [Storefronts](art/wrr-concepts/storefronts.jpg): Busted Spatula weathered brick/teal restaurant; Waffle Haus retro red/cream diner; KWIK-N-GO red/yellow convenience store canopy. Preserve established fictional names and geography; use public-edition tokens where required.
- [Outdoor props](art/wrr-concepts/outdoor-props.jpg): maple/oak/ash, hedge/lilac, fences and gate, porch furniture and parcel, bins, sedan, utilities and surface modules. Model or reuse assets; keep routes clear.
- [Materials](art/wrr-concepts/outdoor-materials.jpg): siding, brick, shingles, concrete, asphalt, grass, red painted wood, steel and ceramic. Swatches are visual targets, not validated tiling textures or PBR maps; author individual maps and verify seams in-engine before shipping.
- All three are concept reference boards, not engine renders or production-ready meshes. First art pass is limited to one residential block; no paid assets or expansion.

## Approved contextual interface (Nov 27)
[Three-panel interface art board](art/wrr-concepts/interface-options.jpg). Use all three treatments with a shared visual system: A diner ticket for cooking, B graphic-novel speech and choice panels for dramatic encounters, C original Duffphone app panels for daily life. Palette: cream, charcoal, worn teal, amber and burgundy/plum. Keep established UI button roles, clear icons and readable typography; reduce distress behind text and controls, maintain contrast, generous touch targets and contextual actions. Preserve approved character and mascot designs; illustrations in the board are placeholders. Concept only, not an engine screenshot or final branding asset. Implementation follows current milestones.

## Approved character performance direction (Nov 27)
Preserve canonical models, rigs, outfits and likeness references. Five shared emotional states (neutral, happy, annoyed, exhausted, surprised) interpreted through each character's distinctive body language. Duff is competent, confident and occasionally cocky; relaxed at home, visibly tired after work. First kitchen animation batch: ready stance, efficient grill work, playful pan toss, precise plating, order-up acknowledgment, exasperated reaction, and satisfied shift completion. Reuse existing real clips where suitable; avoid sliding feet, prop clipping, abrupt transitions and excessive gestures. New clips and character-specific performances require actual in-engine previews and existing owner approvals before shipping. No unapproved likeness changes or paid assets. Design only, not implemented.

## Integrated playable-day milestone
[Survive Tuesday](PLAYABLE_DAY.md): first coherent 10–15 minute day, proposed scope and acceptance criteria. Existing porch, kitchen and neighborhood gates remain.

## Sequencing and dependencies
1. Existing porch acceptance and presentation polish.
2. Isolated kitchen visual prototype and immersive environment pass; actual engine comparison before gameplay expansion.
3. Grill Master: reusable interaction framework, 4 slots, 3 burger variants, 3–5 minute segment, adjustable scoring (accuracy 60%, speed 25%, waste prevention 15%).
4. Fryer, sauté, cold prep and pass; station mastery via successful actions, not purchased skill.
5. Neighborhood/daily-life foundation: compact zones, existing geography, schedules, existing finances, relationships, errands and work; preserve existing 2D game.
6. Duffphone and Glitch, then Regret Engine and remembered NPC outcomes.
7. Full integrated loop, optimization and release evidence.
These are planning dependencies, not a claim all tasks are active; consult QUEUE and open PRs before work. Keep isolated previews separate from production.

## Coordination
GitHub is the shared source of truth. Start sessions from current repo rules and handoffs; check existing branches/PRs and the studio task queue before edits. Record decisions, exact changed files, status, test evidence, blockers and next step in the relevant PR/handoff. Do not claim a concept is an engine render or cloud FPS is phone FPS. Retain existing approval and CI gates.
Suggested roles: ChatGPT for design, art direction and assets where available; Foxboard for asset library and generation; Codex for scoped Godot implementation and tests; Claude for independent technical checks where appropriate; owner for creative decisions and required approvals. No duplicate work or surprises. No public release rename or publication change from this planning PR. 60 FPS is a target, 9/10 is the internal release goal, not a measured score.
