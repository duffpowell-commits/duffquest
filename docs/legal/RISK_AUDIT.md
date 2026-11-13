# Legal risk audit before advertising (Nov 13, 2026)

**This is not legal advice.** It's a ranked checklist from reading the repo and the itch copy. Items marked
**LAWYER** deserve a real lawyer before paid ads or a paid release. Ranked by how likely each is to cause actual
trouble (a takedown, a cease-and-desist letter or a lawsuit), not by how bad the worst case is.

Status key: FIXED (in PR "Credits & legal screen"), PUBLIC (fixed in the public edition; the family edition keeps the
original, see "Editions" below), PROPOSE (needs Duff's yes), ASK (needs a fact from Duff), OK (checked, no action).

**Editions (Nov 13).** Duff approved the renames for the advertised game and asked to keep a separate family game as
is. Default exports (itch, GitHub Pages root, `duffquest-public.apk`) are the public edition; the family edition
(Pages `/family/`, `duffquest.apk`) is unlisted and never advertised. Note: the public packs still contain the
family art files (unused), so a data-miner could find them; low risk, fixable later with per-edition pack filters.

## High

1. **Brittany steals from the real Twisted Fork (side quest "Brittany's Side Gig").** The Twisted Fork is a real
   Old Market restaurant (Twisted Fork Grill & Bar, 1014 Howard St, owned by Restaurants Inc.). The quest has a
   real, named person filling jars from its walk-in and selling them, and the player can pin it on "the dishwasher".
   Saying a real person committed a crime against a real business is the classic defamation fact pattern, even as a
   joke, and the restaurant (or her real manager) didn't consent. PROPOSE: rename the restaurant (new name + new
   sign art) and either make the thief a made-up coworker or get Brittany's written OK. **LAWYER** if both stay real.
   PUBLIC: restaurant renamed; Brittany is "Mazikeen" (`{coworker}` token) everywhere in the public build. Her sprite
   and portrait are still drawn from Brittany: get her written OK anyway, or repaint them before paid ads.
2. **The Twisted Fork in general.** Real business name and a look-alike green sign, shown with a health
   inspector, ranch theft, a villain buying it, "Nobody tips the fry cook". Even if Duff works there, the owner can
   object to its name in a game sold or advertised to the public, and an employer can discipline staff for it.
   PUBLIC: "The Busted Spatula", new sign (`sf_fork_pub`). Duff does work there; ASK: does management know?
3. **"Wordle".** The New York Times owns the WORDLE trademark and has had clones pulled from app stores and GitHub.
   The name appears 100+ times ("Play today's Wordle", Jen's texts, credits). The game mechanic itself is fine.
   PUBLIC: "Word Brawl" everywhere players see it (`{wordle}` token); internal ids kept.
4. **Madison's exes.** The itch page says "Madison's exes. All of them." Madison is real and named, so if any boss
   is drawn from a real ex, people in Omaha who know them can identify them, and the game shows them beaten bloody.
   ASK: are all five story exes (and the four gala exes) invented? If any is based on a real person, change the
   identifying details. The new notice ("every other character is invented") only helps if that's true.
5. **Consent from real people.** Madison, Jen, Brittany, Octavia (a minor: both parents' OK) and anyone else real
   (Chef, Manny, Earl, Deb, Gail?). A verbal "sure" isn't proof. FIX ON DUFF'S SIDE: get a text or email from each
   adult: "I'm OK with my name, likeness and story appearing in Duff Quest, a public game that will be advertised."
   Madison's health content (EDS, autism, ADHD) needs her explicit written OK; that already runs through her
   per-change approval. Keep the screenshots.

## Medium

6. **Walgrumps sign = Walgreens trade dress.** Red sign, white script "W". The parody name is fine; copying the
   look is what gets letters. PUBLIC: teal band, mustard block letters (`sf_walgrumps_pub`).
7. **Hy-Whee slogan.** "A helpful smile in every aisle-ish" is Hy-Vee's real slogan with "-ish" on it, plus a red
   heart sign. Hy-Vee is huge in Omaha. PUBLIC: "Groceries, mostly. Smiles, sometimes."; name kept.
8. **Music provenance.** `assets/audio/manifest.json` says every track came from `tools/audio/gen_audio.py`, but that
   script isn't in the repo or its history. If any track came from an AI music service, check its terms (several free
   tiers ban commercial use). RESOLVED: Duff says the music is his own. Credits, itch page and the audio manifest
   now say "Music by Duff". If any of it was made with an AI music tool, check that tool's commercial terms.
9. **"Gucchi Eau de Duff".** Gucci polices its name hard. PUBLIC: "Eau de Fryer".
10. **Bruce Willnot in Nakatomeh Plaza.** A riff on a real actor's name (right of publicity) and on Die Hard's
    building. No likeness in the art (made-up face, long blond hair). Low odds, but it's the only boss named after a
    real person. Duff: he is based on Madison's real ex (they allegedly looked alike), which makes this item 4, not a
    celebrity riff. PUBLIC: "Rex Tankton" in "Glasshaus Tower", dark hair and a charcoal tank top in all of his art.
    The other four story exes and the gala exes: ASK whether any is a real person.

## Low

11. **Waffle Haus.** Name riff on Waffle House; no sign art copies its yellow tiles. OK. Keep its logo look out of ads.
12. **Hazbin Hotel / Helluva Boss.** Show & Tell text mentions them; the cats are named Alastor and Lucifer. Text
    mentions only, no character art: OK. Don't use their names, art or "Hazbin style" in ads or the store page.
13. **Passing brand jokes** (Venmo, Uber, TikTok, Tesla, Costco, iPhone, Ensure, FEMA/Waffle House fact). Normal
    use of a name in a joke. OK.
14. **Gala exes** (were billionaire parodies). Renamed, made-up faces. Satire of public figures is strongly
    protected. OK.
15. **Real venues** (Holland Center, Omaha Symphony, Akarui sushi, Council Bluffs). Shown as date spots. OK as long
    as nothing shows them badly.
16. **AI art.** Grok, Gemini, ChatGPT and Canva all let you use outputs commercially. Catch: AI art isn't
    copyrightable in the US, so you can't stop someone reusing it. itch's AI disclosure is already set. OK.
17. **Public repo.** Anyone can read and fork the whole game, Duff's photos (`docs/ref/duff`) and real names. Not a
    lawsuit risk; a privacy and copycat one. Making it private would break free GitHub Pages (needs GitHub Pro).

## Licenses and privacy

18. **Godot's MIT license and third-party notices were not in the game.** MIT requires the notice to ship with the
    game. FIXED: Settings > Credits & legal shows Godot's license, its component copyrights (FreeType line included)
    and every license text, all pulled from the engine at runtime.
19. **Fonts (OFL 1.1).** The license files existed but nothing showed them. FIXED: same screen lists each font's
    copyright and the OFL text.
20. **Privacy.** The game collects nothing (no accounts, analytics or ads; saves are local; the web build only
    downloads its own packs). FIXED: `docs/legal/PRIVACY.md`, linked from the itch page and summarized in-game.
21. **Parody/fiction notice.** FIXED: in-game screen, end credits and the itch page.
22. **Google Play (if it goes there).** Needs: a privacy policy URL (use the PRIVACY.md GitHub link), the Data
    safety form ("no data collected"), the IARC content rating questionnaire (cartoon blood, crude humor, strong
    language), and target audience 18+ so the chibi art isn't treated as made for kids.
23. **Ads.** Don't use real logos or other studios' characters in ad creative (ad platforms reject them anyway). If
    you pay or gift anyone to post about it, they have to label it as an ad (FTC).

## Worth a lawyer (one consult covers all of it)

- Items 1-2 if the Twisted Fork and Brittany stay real.
- Item 4 if any boss is a real ex.
- Before charging money: name/likeness releases for the real family and friends, and whether to sell through an LLC
  so a claim can't reach personal savings.
