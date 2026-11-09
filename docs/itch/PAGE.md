# Duff Quest: itch page kit (2026 Jam)

Page: https://dufftkyosht.itch.io/duff-quest. Build upload steps: `docs/itch_deploy.md`.
Everything here is ready to paste. `[CHECK]` = Duff has to answer it before the page goes live.

## STOP: read before submitting to the jam

The "2026 Jam" rules (itch.io/jam/2026-jam, read Nov 9) say, word for word:
1. "Only have the game developed in 2026"
2. "No NSFW"
3. "No AI content (no AI stuff in your games, so no AI assets like sprites, music, etc), however you may use AI for code assistance"

Duff Quest's art is AI-generated (Grok, Gemini, ChatGPT, Canva). **As written, rule 3 rules it out.** Code by Claude is fine
under the rules. `docs/art_rules.md` H2 says the jam "has no content rules beyond itch's own". That is wrong.

- **[CHECK] Rule 3, AI art.** Options: (a) ask the host on the jam's Discord (linked on the jam page) whether an
  AI-art game with full disclosure can enter; (b) submit anyway with the disclosure below and accept it may be
  disqualified; (c) skip this jam (Chaos might qualify instead, if its assets aren't AI). Recommended: (a) first.
  Never hide or soften the disclosure to get in.
- **[CHECK] Rule 1, made in 2026.** The Grok-built versions (v0.2 to v0.10.1) came before the Nov 7 recovery.
  Were they all made in 2026?
- **[CHECK] Rule 2, NSFW.** Cartoon blood, crude jokes and swearing (there is a clean-language toggle). No sex or
  nudity. That should be fine, but the jam doesn't define NSFW.

## Files

| File | Use on itch |
|---|---|
| `cover.png` (630x500) | Edit game > Cover image |
| `screens/01_town_kwik_n_go.png` | Screenshot 1: the block (Kwik-N-Go, PlazMart Plasma, Iron Temple, Waffle Haus sign, touch controls) |
| `screens/02_boss_intro_gym_bro.png` | Screenshot 2: boss intro card |
| `screens/03_knockout_xray.png` | Screenshot 3: knockout cutscene, x-ray beat |
| `screens/04_kitchen_sandwich_station.png` | Screenshot 4: kitchen shift station ("TICKET STOLEN BY GRILL-BOY BRAYDEN") |
| `screens/05_fridge_calendar.png` | Screenshot 5: fridge calendar + sticky notes from the cats |
| `screens/06_dialogue_madison.png` | Screenshot 6: dialogue with HD portrait |
| `knockout.gif` (640x360, 7.8 s loop, 4.1 MB) | Upload as a screenshot (itch plays GIFs there), or put it in the description |
| `contact_sheet.jpg` | Everything at a glance; not for upload |

All screenshots are real 1280x720 engine frames (640x360 game at 2x, HD layers native), taken with the existing
shot tools: `arena_shot -- at:535,128`, `qa_shot` (boss_gymbro_intro, dialog_madison), `ko_shot -- gymbro`,
`arena_shot -- sandwich`, `calendar_shot` (day 7). The GIF is the Gym Bro knockout recorded in-engine
(`ko_shot.tscn --fixed-fps 30 --write-movie ... -- gymbro video`), cut to slip > x-ray > finisher (beats shortened).
Cover = the knockout stance still (`assets/art/ko/duff_stance.jpg`, tattooed Duff) with the title set in the game's
own fonts (Baloo 2, Nunito).

**[CHECK] Real names in the public build.** Screenshots and the build show Madison, Octavia, Jen, Brittany and the
cats by real name. `docs/PITCH.md` says a public build should swap these for parody names via `data/cast.json`.
Is Duff OK with the real names going public? If not, the swap and new screenshots have to happen first.

**[CHECK] Parody bosses of real people** (Elon Husk, Jeff Bozos, Bill Fences, The Donald). They aren't in the
screenshots on purpose. The page text only names the made-up bosses. Fine to name them?

---

## Title / tagline

**Duff Quest**
Short description (itch "tagline", max ~100 chars):
> Keep Madison happy. Pay the rent. Work the line. Bonk porch pirates with a spatula. Omaha, NE.

## Description (paste into the itch description box)

> So I'm a line cook in Omaha. Thirty-something. Full sleeves, a fox on my neck, a frying-pan burn on my
> wrist I don't remember getting. Rent is due. Rent is always due.
>
> I've got a partner who deserves better, a baby with dimples that could start a war, and three cats who
> leave notes on the fridge like they pay the bills. They don't. I do. Barely.
>
> Every morning I check the fridge calendar. Every day I pick: work the Fork, run Madison's errand, sell
> some plasma, or go settle something on the block. Porch pirates. 3 AM drunks. A scammer selling Rolecks.
> And when it's a boss, it's a boss: Gym Bro Supreme. The Ghoster. Coupon Carol. A guy who sends back
> medium-rare-well. Seventeen of them. Some of them are my exes. Some of them are billionaires. One of them
> is a regular named Earl.
>
> I win, the world slows down. Comic panels. An x-ray of the exact bone. A crowd that saw everything.
>
> The body keeps the receipts. Nobody tips the fry cook. Hell of a girl, though.

**Features**
- **Real life, played as an RPG.** One real Omaha line cook's week: rent on Monday, payday on Friday, a partner's
  mood bar, a baby fund, and a calendar that remembers what you forgot.
- **Brawl the block.** Three-hit combos, dodge rolls, a chargeable special and Demon Time. Spatula first,
  questions never.
- **17 bosses**, each with a burst intro card, its own arena and its own trash talk.
- **Knockout cutscenes:** comic-panel finishers with x-ray hits, crowd reactions and a closing line. Eleven so far.
- **Work the line.** Kitchen shifts at the Twisted Fork: fryer, sandwich builds, prep, a lineup quiz and more.
  S-rank a station and your hands remember it (Autopilot).
- **The fridge calendar.** 30 handwritten November days, sticky notes from Madison, the baby and the cats,
  random morning events, weekends off, Thanksgiving at the Waffle Haus.
- **Errands and side hustles:** grocery runs on a $15 budget, the pharmacy, plasma donation, a night shift
  at the Waffle Haus, a gala you're underdressed for.
- **Plays on your phone** (touch controls, landscape) or with a keyboard. Saves in your browser.
- **Clean language toggle** in Settings for the swearing.

## Controls (paste under the description)

| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD / arrow keys | Left joystick |
| Use / talk | E or Enter | A |
| Bonk (mash for a 3-hit combo) | Space or J | A |
| Dodge roll | Shift, K or L | B |
| Special (hold to charge) | F or U | S |
| Swap special | Q | <> |
| Demon Time (once unlocked) | R | D |
| Gear | I | G |
| Phone | P or Tab | Phone icon (top) |
| Spend stat points | T | (stat screen) |
| Settings / back | O or Esc | |
| Menu choices | Number keys 1-9 | Tap the button |
| Skip a cutscene beat / calendar | Any key | Tap |

Best in landscape. Tap **Run game**, then the fullscreen button. First load is about 90 MB.

## Content warning (paste near the top or in the content section)

> Cartoon violence and cartoon blood (bloody noses, spit, flying teeth, x-ray bone hits in comic panels).
> Crude humour and swearing (switch on Clean language in Settings). Jokes about rent, bills, exes,
> billionaires and plasma donation. No sexual content.

## Credits

> **Design, story, real life:** Duff Powell (dufftkyosht)
> **Code:** written with AI: Claude (Anthropic); the original version was built with Grok (xAI)
> **Art:** AI-generated (Grok, Gemini, ChatGPT, Canva AI) from Duff's own photos and reference art, then cut,
> keyed, recoloured and fixed in code
> **Music and sound effects:** synthesized procedurally by code; no samples. The date theme is Brahms' Lullaby
> (1868, public domain)
> **Fonts:** Baloo 2, Nunito, Caveat, Patrick Hand (SIL Open Font License)
> **Engine:** Godot 4.5
> **Main tester:** Brittany

## AI use disclosure (paste as its own section; also tick itch's AI disclosure boxes)

> **How this game was made, honestly.** Duff Quest is one guy's life, designed and written by him, built with
> AI tools because he works the line and has no computer, only a phone.
> - **Code:** written by AI (Claude by Anthropic; the first version by Grok), directed and playtested by Duff.
> - **Art:** generated with AI image tools (Grok, Gemini, ChatGPT and Canva AI), using Duff's own photos and
>   reference drawings, then edited in code: cut into sprite sheets, keyed, recoloured, fixed.
> - **Sound and music:** synthesized by code (no recorded samples, no AI music model). The date theme is
>   Brahms' Lullaby (public domain).
> - **Writing:** Duff's voice and stories; dialogue drafted and edited with AI help.

Notes behind that text (not for the page):
- `assets/audio/manifest.json`: "All SFX/music synthesized by tools/audio/gen_audio.py. Date theme: Brahms'
  Lullaby (1868, public domain). Everything else original." That script came with the Grok-built version and is
  not in this repo. Knockout SFX: `tools/make_ko_sfx.py` (numpy/scipy, written by Claude).
- **[CHECK]** The brief listed Grok, Gemini and Canva for art. `handoff-duffquest.md` shows ChatGPT art went into
  the game too (Kwik-N-Go, trees, home, gym, Dolores). The text above names ChatGPT; keep it unless that's wrong.
- **[CHECK]** Writing line: is "drafted and edited with AI help" accurate? (The voice rewrites in `tools/rewrites/`
  were done by Claude.)
- **[CHECK]** Music: the music code was written by an AI (Grok). The text above calls it "synthesized by code",
  which is true. If the jam host asks, say that too.

## itch settings checklist (Edit game page)

- [ ] **Kind of project:** HTML (upload per `docs/itch_deploy.md`; viewport 1280x720, Mobile friendly, Landscape,
      Fullscreen button, SharedArrayBuffer OFF, autostart OFF)
- [ ] **Classification:** Game
- [ ] **Release status:** In development
- [ ] **Pricing:** No payments (free) `[CHECK]` (price is undecided in PITCH.md; free is the norm for jam entries)
- [ ] **Genre:** Role Playing
- [ ] **Tags** (itch allows up to 10): `comedy`, `rpg`, `beat-em-up`, `pixel-art`, `life-simulation`, `cooking`,
      `funny`, `story-rich`, `godot`, `mobile`
- [ ] **AI generation disclosure:** "Yes", and tick graphics, code and text `[CHECK]` (sound: the music code was
      AI-written but no AI audio model was used; tick it too if you want to be safe)
- [ ] **Content / "Content warnings" section:** blood, violence, crude humour, strong language. Do NOT tick the
      adult-only "contains sexual content" box (there is none). `[CHECK]` that itch's current form has these
      exact fields; it changes now and then.
- [ ] **Inputs:** Keyboard, Touchscreen. **Accessibility:** none claimed.
- [ ] **Languages:** English
- [ ] **Cover image:** `cover.png`. **Screenshots:** 01-06 in that order, plus `knockout.gif`
- [ ] **Theme:** pick dark background, accent around the cover's yellow (`#FFD65A`) `[CHECK]` (taste call)
- [ ] **Visibility:** Public (a jam entry should be public; draft pages can't be seen by voters) `[CHECK]`
- [ ] Save, open the page on the phone, tap Run, reach the title screen.

## Submitting to the jam from a phone (after the [CHECK]s at the top)

1. Do the itch settings above first and make sure the page is **Public** and the HTML build runs.
2. In Chrome open **itch.io/jam/2026-jam** (logged in as dufftkyosht). ⋮ > **Desktop site** helps.
3. Tap **Submit your project**.
4. Pick **Duff Quest** from "Choose an existing project" (don't create a new one).
5. Fill anything the form asks (it may ask about AI use or team members), tap **Submit**.
6. Check the entry shows up under the jam's **Entries** tab. You can still edit the game page after submitting.
   Deadline: jam closes Dec 31, 2026 22:59 (time zone not stated on the jam page); ours is **Dec 28**.
