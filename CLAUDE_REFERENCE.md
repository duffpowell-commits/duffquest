# Claude reference: key facts for every DuffQuest session

Short and stable. `CLAUDE.md` = status log; this = ops (secrets, hosting, shipping); `reference.md` = how the GAME works (systems, data, art, tools). Update when a fact changes.

## Secrets
- This repo is public. Tokens live only in GitHub Actions secrets that Duff adds. Never commit them, never put them in a clone URL, and never ask Duff to paste one in chat.

## Repos and hosting
- Code: GitHub `duffpowell-commits/duffquest`.
- Itch: https://dufftkyosht.itch.io/duff-quest, butler target **`dufftkyosht/duff-quest:html`** (NOT `html5`).
- Ship: `tools/ship_itch.sh` (installs Godot 4.5 + web templates + butler if missing,
  then import, test_daily, smoke, export, secret scan, push). `--no-push` to build only.
  The itch key is the `BUTLER_API_KEY` Actions secret, not a file in the repo.

## Art pipeline (Nov 9)
- House style = C (docs/art_direction/STYLE_LOCK.md); canonical Duff ref = docs/art_direction/duff_face_sheet.png; no image outside the lock.
- **Canonical Duff face sheet in Canva: `MAHacL92VLk`** (FIRST reference for every future Duff image). Scratch export design (new Nov 9): `DAHacBeu8SQ`.
- **Image generator = Canva (`generate-image`) + Claude.** Grok is out of usage; Gemini app runs are retired.
  Canva: Business plan, ONE agent at a time (parallel calls hit the rate limit). Edit flow: upload the original
  with `create-upload-url`, pass it as the FIRST reference. Full-size export via scratch design `DAHabdund5o` (26 pages Nov 9; `DAHabf2Qa9U` also works; old `DAHaZZaEJBs` is locked at 100+ pages). Start a new one past ~90 pages.
  Duff refs in Canva: front `MAHabDL4f8M`, side `MAHabLtLOTk`, eye hand `MAHabBgv_Hk`, creature forearm `MAHabP7oeP8`.
- Claude does everything in code: keying, cutting sheets, recolors (`tools/tattoo_sprites.py`), fixes
  (`tools/fix_sheet_cells.py`), procedural SFX, in-engine effects (blood/spit lives in code, Canva blocks it).
- Rules: `docs/art_rules.md` (Duff's look D1-D7, gore H2), `docs/duff_look.md`, voice `docs/voice.md`.
- DuffQuest art drops from Place now go to the bot Quase (Art Team). This repo keeps game art, not bot prompts.

## Decisions (Nov 9)
- The public itch build uses the names already in the game. New personal or family details stay out of this repo.
- House art style = C (docs/art_direction/). Gala unlocks story day 24.
- 2026 Jam is out (bans AI art). Seasonal RPG Game Jam #1 (closes Dec 23 5:59 PM CT; host artistotel; born on Melonland forum) has no AI rule; Duff asked the host on the jam's itch Community tab.

## Deadlines
- itch "2026 Jam" closes Dec 31, 2026; our deadline **Dec 28**. Entries: DuffQuest (+ Chaos, separate repo).

## Duff's house rules (short)
- Phone only (Godot Android editor, GDScript). No desktop steps.
- Push after every chunk; merge to main at each milestone; keep `CLAUDE.md` current; renders to files in repo.
- Run tests before every push. Tests never touch the real save (`tasks/lessons.md`).
- Automate; don't hand Duff manual steps.
