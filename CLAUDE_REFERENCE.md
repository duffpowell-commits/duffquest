# Claude reference: key facts for every DuffQuest session

Short and stable. `CLAUDE.md` = status log; this = ops (secrets, hosting, shipping); `reference.md` = how the GAME works (systems, data, art, tools). Update when a fact changes.

## Secrets (never ask Duff to paste keys again)
- Vault: Cloudflare D1 database **`duff-vault`** (id `af975dad-2989-45e3-92c9-03caf55f14e3`), table `secrets(name, value, note, expires)`.
  Read with the Cloudflare MCP: `d1_database_query` -> `SELECT name, value FROM secrets`.
  - `GITLAB_TOKEN`: user duffpowell, expires **2026-12-08** (remind Duff a week before). Scopes: read/write repo, read_api.
    NO `api` scope, so it can't set CI variables or project settings.
  - `BUTLER_API_KEY`: itch.io user `dufftkyosht`.
- Keys live in env vars for the session only. Never in the repo, `.git/config`, memory, or chat.
  Clone: `git clone https://oauth2:$GITLAB_TOKEN@gitlab.com/dufftkyosht-group/duffquest.git`, then
  `git remote set-url origin https://gitlab.com/dufftkyosht-group/duffquest.git` (strip the token).
  Push: `git push https://oauth2:$GITLAB_TOKEN@gitlab.com/dufftkyosht-group/duffquest.git main`.
- New key? Insert/replace a row: `INSERT OR REPLACE INTO secrets (name,value,note,expires) VALUES (...)`.

## Repos and hosting
- Code: GitLab `dufftkyosht-group/duffquest` (private). `duffpowell/duffquest` is an empty stub; ignore it.
  GitHub `duffpowell-commits` is suspended (appeal filed).
- Itch: https://dufftkyosht.itch.io/duff-quest, butler target **`dufftkyosht/duff-quest:html`** (NOT `html5`).
- Ship: `BUTLER_API_KEY=... tools/ship_itch.sh` (installs Godot 4.5 + web templates + butler if missing,
  then import, test_daily, smoke, export, secret scan, push). `--no-push` to build only.
- `.gitlab-ci.yml`: tests on every push; deploys to itch from `main` only if a `BUTLER_API_KEY` CI variable
  exists (needs a token with `api` scope or Duff adding it in GitLab > Settings > CI/CD > Variables).

## Art pipeline (Nov 9)
- **Image generator = Canva (`generate-image`) + Claude.** Grok is out of usage; Gemini app runs are retired.
  Canva: Business plan, ONE agent at a time (parallel calls hit the rate limit). Edit flow: upload the original
  with `create-upload-url`, pass it as the FIRST reference. Full-size export via scratch design `DAHabdund5o` (26 pages Nov 9; `DAHabf2Qa9U` also works; old `DAHaZZaEJBs` is locked at 100+ pages). Start a new one past ~90 pages.
  Duff refs in Canva: front `MAHabDL4f8M`, side `MAHabLtLOTk`, eye hand `MAHabBgv_Hk`, creature forearm `MAHabP7oeP8`.
- Claude does everything in code: keying, cutting sheets, recolors (`tools/tattoo_sprites.py`), fixes
  (`tools/fix_sheet_cells.py`), procedural SFX, in-engine effects (blood/spit lives in code, Canva blocks it).
- Rules: `docs/art_rules.md` (Duff's look D1-D7, gore H2), `docs/duff_look.md`, voice `docs/voice.md`.
- "Place" (Cursor/Grok art agent) hands drops in `grok_art/<date>-<name>/HANDOFF.md`.

## Deadlines
- itch "2026 Jam" closes Dec 31, 2026; our deadline **Dec 28**. Entries: DuffQuest (+ Chaos, separate repo).

## Duff's house rules (short)
- Phone only (Godot Android editor, GDScript). No desktop steps.
- Push after every chunk; merge to main at each milestone; keep `CLAUDE.md` current; renders to files in repo.
- Run tests before every push. Tests never touch the real save (`tasks/lessons.md`).
- Automate; don't hand Duff manual steps.
