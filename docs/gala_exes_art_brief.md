# Gala exes: art brief (Nov 9, 2026)

The four billionaire parodies at THE ELITE GALA are retired (dated jokes, Google Play risk, no tie to the story).
Their slots are now four of Madison's exes who "made it". Baron Von Trustfund stays as the host (not an ex).
Old art + old scripts: `docs/dlc_concepts/billionaires/` (copies, for a possible DLC).

Internal ids stay (saves, assets, manifest). Names live in `data/cast.json`.

| id (file names) | cast token | name | order at the gala |
|---|---|---|---|
| `husk` | `gala_ex_1` | Tyler Pivot | fight 1 |
| `bozos` | `gala_ex_2` | Grant Gratuity | fight 2 |
| `fences` | `gala_ex_3` | Landlord Lance | fight 3 |
| `baron` | `gala_baron` | Baron Von Trustfund (host, unchanged) | fight 4 |
| `donald` | `gala_ex_4` | Chip Leverage | fight 5, FINAL |

## What is placeholder right now (in game)
- **Intro cards** `assets/art/boss_intro/{husk,bozos,fences,donald}.png` still letter the OLD names. They are
  hidden in game: `Art.RETIRED_CARDS` in `scripts/art.gd`. Each intro falls back to the plain dialogue box.
  **When a new card lands:** replace the png, run `--import`, remove the id from `RETIRED_CARDS`.
- **KO stills** `assets/art/ko/<id>_a|b|c.jpg` show the old faces, so the four strips are `"live": false` in
  `data/knockouts.json`. The new scripts are already written. **When new stills land:** check K1 (x-ray bone
  = the `xray` line, listed per boss below), then flip `"live": true`.
- **Portraits** `portraits_hd/<id>.png` and **sprite sheets** `ch_<id>.png`: still the old made-up faces (no
  names on them, P1-clean). They show in game as placeholders until the new ones replace them.

## Rules every image follows
`docs/art_rules.md`: H1 house style (match `portraits_hd/ghoster.png`), P1 made-up human faces (no real person,
no public figure, no animal/object heads), H3 clean output, K1-K6 for KO stills, S1-S4 for sheets, R1-R7 process.
Duff's look (D1-D7) on every image he is in: buff, blackout sacred-geometry sleeve on one arm, grey-wash
horns/flames + dark creature head (orange eyes, NOT a panther) on the other, fox on his LEFT neck. Attach his
refs (Canva media `MAHabDL4f8M` front, `MAHabLtLOTk` side, `MAHabBgv_Hk` eye hand, `MAHabP7oeP8` creature forearm).
Never prompt for blood (Canva blocks it; it is added in-engine). Never name a show, brand or real person in a prompt.
Lessons that apply: refs leak characters (check every panel for Ghoster's face), never use one finished still
as the layout ref for the others, grade full-size only.

## Shared prompt blocks

**STYLE-PORTRAIT** (portraits, cards): "Bold cartoon character art: thick tapered black ink lines, angular
shapes, flat cel shading with one hard shadow tone, saturated colours, expressive rubbery faces. Match the
drawing style of the attached portrait (STYLE ONLY: do not copy that character's face, hair or clothes).
An original, made-up adult human face that does not resemble any real person."

**PORTRAIT LAYOUT**: "A 3-panel character portrait strip, 1536x512, three equal square panels on a transparent
background, the same character framed from mid-chest up in every panel, same outfit, same props, same
lighting. Expressions left to right: (1) SMUG, (2) SHOCKED, (3) ENRAGED. No text, no letters, no logos."
Attach: `portraits_hd/ghoster.png` (style). Import: `tools/import_portrait.py` -> `portraits_hd/<id>.png`.

**BURST CARD LAYOUT**: "A 16:9 boss intro card, 1920x1080. Background: a full-bleed sunburst of alternating
radiating rays in two tones of <CARD COLOUR>. The character stands full body on the VIEWER'S LEFT half in a
dynamic action pose, feet near the bottom edge. On the VIEWER'S RIGHT half, the name in huge chunky rounded
cartoon lettering, cream fill with a thick dark outline, on two lines, spelled exactly: '<LINE 1>' / '<LINE 2>'.
All lettering sits in the upper two thirds of the card (nothing below 65% of the height). No other text,
no logos, no watermark." Attach: the new portrait (face ref) + `boss_intro/ghoster.png` (layout ref only;
check the output for Ghoster's face). Import: `tools/import_boss_intro.py <id>` (960x540).

**SHEET LAYOUT**: "A 4x4 pixel-art character sprite sheet, 1024x1024, flat solid magenta (#FF00FF) background,
16 equal cells. Modern high-detail pixel art with crisp dark outlines, no blur, no anti-aliased halo, chibi
proportions about 2.5 heads tall. Rows top to bottom: facing the viewer, facing away, facing the VIEWER'S RIGHT,
facing the VIEWER'S LEFT. Columns left to right: standing, walk step 1, walk step 2, ATTACK pose (<ATTACK>).
Same character, same size and same foot line in every cell. No text." Attach: the new portrait (face ref) +
`grok_art/2026-11-09-parody-bosses/sheet_willnot.png` (layout ref: grid only). Canva often draws row 4 facing
right: fix with `tools/fix_sheet_cells.py 3,c=2,c:m`, then `tools/import_big_sheet.py <src> ch_<id>`. Check
scale against Duff (S3, ~26 units).

**KO STYLE** (all KO stills): the style-fusion prompt in `docs/knockout_cutscenes.md`, verbatim. 1280x720 JPG
q88. A = boss wind-up close-up (boss alone). B = impact + x-ray (Duff and the boss; the x-ray inset is at the
exact contact point inside the struck figure, showing the bone named below). C = boss knocked out. Refs for B:
`ko/duff_stance.jpg` + Duff's refs + the new boss portrait. Never another boss's still. Each B gets its own
layout (K6): the layout for each is written below.

---

## 1. Tyler Pivot (`husk`, `gala_ex_1`)
**Who:** dated Madison in college. Now a hustle influencer and "founder" of an app nobody has used. He
livestreams the gala the whole fight. Calls everyone "fam", pivots every sentence, has never finished anything.
Mean to: hustle culture, fake founders. **KO device:** the viewer count.

**Look:** late 20s, tall and lanky, slight slouch. Floppy brown curtain-bang hair, patchy stubble, big white
veneer grin. Cream oversized hoodie under an unbuttoned slim mustard blazer, a conference lanyard with a blank
badge, black joggers, chunky white sneakers. A shoulder rig holding a phone on a gimbal arm in front of his face
and a small ring light behind his head. Wireless earbuds. Palette: hot pink + cyan "stream" neon on cream.
Prop for attacks: a rental e-scooter (plain, no logo).
(Do not reuse the old placeholder: no goggles, no jetpack, no silver fringe jacket.)

- **Portrait:** STYLE-PORTRAIT + PORTRAIT LAYOUT + look. Expressions: (1) smug grin at his own phone screen,
  one eyebrow up; (2) shocked, jaw dropped, phone slipping out of the gimbal; (3) enraged, shouting straight
  into the phone camera, veins on his forehead, ring light flaring.
- **Card:** BURST CARD, colour = hot pink and magenta. Pose: one foot on the e-scooter deck, pointing the
  gimbal phone at the viewer, other hand doing a peace sign. Name: `Tyler` / `Pivot`.
- **Sheet:** SHEET LAYOUT, attack = holding the phone gimbal out at arm's length with a cyan flash burst from
  the screen (like the old sheet's attack column; facing matches the row).
- **KO A:** low angle, Tyler rearing back on the e-scooter like a jousting lance, gimbal phone in his teeth,
  manic grin. Neon pink speed lines.
- **KO B (xray = JAW):** *"The jaw is the only bone in the skull that moves... My elbow gives it the night off."*
  Layout: over-the-shoulder from behind Duff (Duff's back three-quarter on the VIEWER'S RIGHT, blackout sleeve
  arm nearest the viewer per D5), Duff's ELBOW driving into the side of Tyler's lower jaw; x-ray inset ON Tyler's
  face showing the skull with the mandible glowing and cracked at the elbow's contact point. The phone flies out
  of the frame. Expressions: Duff bored half-lidded, Tyler cross-eyed shock.
- **KO C:** Tyler flat on his back on the gala carpet, spiral eyes, the gimbal phone still filming him from
  above, ring light tipped over, shrimp from a toppled shrimp tower around him. No readable screen text.

## 2. Grant Gratuity (`bozos`, `gala_ex_2`)
**Who:** tipped Madison 0% on every date (she snuck back in and tipped for him). Now CEO of "TipTop", a tip
app that skims 30% of servers' tips. Calls her "babe". Mean to: tip-skimming platforms, cheapskates who brag.
Never mean to servers. **KO device:** "Tip status:" tracking.

**Look:** mid 30s, short and compact, puffed-up chest. Hair slicked straight back with far too much product
(wet shine), thin pencil moustache, tiny rectangular glasses. Tight emerald-green velvet tuxedo, gold cufflinks,
an enormous gold smartwatch. Carries a swivel card-reader tablet like a shield, its screen showing three blank
rounded buttons (NO numbers or letters). Two small round hover drones with a coin slot on top follow him.
Palette: money green + gold + white.
(Do not reuse the old placeholder: no box mech, no propeller hat, no buck teeth.)

- **Portrait:** expressions: (1) smug, turning the tablet toward the viewer with a fake smile; (2) shocked,
  glasses knocked crooked, a drone bonking his head; (3) enraged, red-faced, jabbing the tablet screen.
- **Card:** BURST, colour = emerald and lime green. Pose: holding the tablet out toward the viewer like a
  waiter's check presenter, two drones hovering over his shoulders. Name: `Grant` / `Gratuity`.
- **Sheet:** attack = swinging the tablet screen toward the facing direction with a white-yellow glare flash.
- **KO A:** Grant snapping his fingers, a swarm of coin-slot drones launching behind him, eyes glinting.
- **KO B (xray = JAW, both hinges):** *"Two hinges hold a jaw on. My knee comes up from below and takes thirty
  percent of each."* Layout: side view from floor level, Grant bent forward over the tablet, Duff's KNEE rising
  into the underside of his chin from the VIEWER'S LEFT; x-ray inset on Grant's head showing the mandible with
  BOTH temporomandibular joints (hinges in front of the ears) glowing and cracked. Tablet cracking in half.
  Expressions: Duff calm, Grant eyes bulging, moustache flying.
- **KO C:** Grant sprawled face-up on a banquet table among scattered coins, drones crashed beside him, spiral
  eyes, tablet screen dark and cracked. Coins carry no symbols or text.

## 3. Landlord Lance (`fences`, `gala_ex_3`)
**Who:** dumped Madison by text. Now owns Duff and Madison's building (he is "the landlord" from the rent
notices and the third-boat jokes). Passive-aggressive, everything is a fee, quotes the lease. Mean to: slumlords.
**KO device:** "NOTICE:" lines.

**Look:** early 40s, sunburnt pink, receding blond hair gelled into spikes, wraparound sunglasses pushed up on
his head on a neon croakie strap. White captain's yacht hat, salmon polo with a popped collar under a navy
blazer, khaki shorts, boat shoes without socks. A huge ring of keys on a carabiner on his belt. Holds a clipboard
with a lease (lines only, no readable text) and a rolled-up eviction notice. Palette: nautical navy, salmon,
white, with a red "overdue" accent.
(Do not reuse the old placeholder: no cardigan, no beard, no loading spinner.)

- **Portrait:** expressions: (1) smug, fake-friendly smile, tapping the clipboard with a pen; (2) shocked,
  sunglasses falling, keys jangling; (3) enraged, tearing the notice in half, sunburn going purple.
- **Card:** BURST, colour = navy and nautical red. Pose: one boat shoe up on a stack of rent notices (blank
  paper), holding the giant key ring up like a trophy. Name: `Landlord` / `Lance`.
- **Sheet:** attack = slapping a blank paper notice forward with a flat palm, a paper burst effect.
- **KO A:** Lance hurling a fan of blank paper notices like throwing cards, smug, hat tilted.
- **KO B (xray = SPINE, the whole column):** *"The spine is thirty-three vertebrae, stacked like overdue
  notices. My palm serves every one."* Layout: high angle from above and behind Lance (he's bent over his
  clipboard, back to the camera), Duff's open PALM landing flat between his shoulder blades from the VIEWER'S
  RIGHT; x-ray inset ON Lance's back showing the full vertebral column glowing top to bottom with a crack line
  at the palm's contact point. Papers exploding outward. Expressions: Duff half-lidded, Lance gasping, hat off.
- **KO C:** Lance face-down on the carpet, captain's hat crushed, keys fanned out, a glossy boat brochure (no
  text) under his cheek, spiral eye visible.

## 4. Chip Leverage (`donald`, `gala_ex_4`, FINAL gala boss)
**Who:** private-equity guy. Bought the Twisted Fork (Duff's restaurant) this morning, so he is Madison's ex
AND Duff's new boss. Calm, smiling, cuts everything. Attacks: exploding budget box ("CUTS", bursts into
layoffs) and walls of NDAs. Mean to: private equity buying and gutting restaurants. **KO device:** quarters
(Q1-Q4, "Year end").

**Look:** late 40s, big and broad, final-boss mass. Silver-fox hair swept back, square jaw, blindingly white
veneers, a fake tan. A charcoal fleece quarter-zip vest over a crisp pale-blue dress shirt, sleeves rolled
once, slate slacks, loafers. A gold pen behind his ear and a thick binder under his arm. Behind him, stacks of
paper documents tied with red tape (the NDA walls). Palette: corporate charcoal, slate blue, with red-tape
accents.
(Do not reuse the old placeholder: no pompadour, no big moustache, no red tie, no duck pin.)

- **Portrait:** expressions: (1) smug, calm closed-mouth smile, signing a document without looking; (2)
  shocked, pen snapping, binder slipping; (3) enraged, teeth bared, ripping the binder open, papers flying.
- **Card:** BURST, colour = slate blue and steel grey (gold accents on the rays). Pose: towering, arms crossed
  over the binder, a wall of tied paper stacks rising behind him. Name: `Chip` / `Leverage`.
- **Sheet:** attack = hurling a cardboard archive box forward with both hands (paper bursting from the lid).
- **KO A:** Chip winding up to throw a cardboard archive box overhead, smiling with every veneer, paper stacks
  rising like walls on both sides.
- **KO B (xray = HAND, all 27 bones):** *"Twenty-seven bones in a hand. His have only ever signed things. My
  fist reorganizes all twenty-seven."* Layout: dead-centre symmetrical close-up, fist meets fist: Chip's
  signing hand (gold pen flying) blocks Duff's punch knuckles-to-knuckles; x-ray inset INSIDE Chip's hand showing
  the carpals, metacarpals and phalanges glowing and cracked at the knuckle contact. (Different from every other
  B layout: front-on, symmetrical.) Expressions: Duff bored, Chip's smile cracking. Duff's hand tattoos per D4.
- **KO C:** Chip sitting slumped against a collapsed wall of paper stacks, binder open on his lap, gold pen
  stuck in the papers, spiral eyes, one shoe off.

## After the art lands (checklist)
1. Masters to `grok_art/2026-11-XX-gala-exes/`; grade each in `docs/reviews/` (R6), full-size.
2. Import (portrait, card, sheet tools above; KO stills straight to `assets/art/ko/<id>_a|b|c.jpg`).
3. `godot --headless --path . --import`.
4. Remove ids from `Art.RETIRED_CARDS`, flip `"live": true` in `data/knockouts.json`.
5. Renders: `tools/portrait_shot.tscn` (intro lines), `tools/ko_shot.tscn -- <id>` -> `docs/renders/ko_<id>_beats.png`.
