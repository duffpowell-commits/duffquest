# Web portal submission (CrazyGames, GameDistribution)

Checked 2026-11-13 against https://docs.crazygames.com/requirements/intro/ and the GameDistribution SDK guide.

## The build
- CI makes `duffquest-crazygames.zip` on every push to main (release `dev`): the public web export minus the plain
  `index.wasm` (index.html streams `index.wasm.gz`), so it is ~29 MB in 11 files. CrazyGames without its SDK counts
  total size against a 50 MB cap (1500 files max). The full web zip is 57.7 MB and would fail.
- The zip sets `window.DQ_PORTAL=1`: new players start with clean language ON and cartoon gore OFF (PEGI 12, which
  CrazyGames requires). Both still switch in Settings. It also adds `user-select: none` on body (tablet long-press).
- Booted in headless Chrome at 907x510 (CrazyGames' smallest desktop iframe): reaches the title, fetches only
  index.wasm.gz + the three packs.

## CrazyGames: Basic Launch (no SDK, no ads, no money yet)
| Requirement | Status |
| --- | --- |
| Total size <= 50 MB without SDK, <= 1500 files | Pass (29 MB, 11 files) |
| Relative paths only | Pass (packs resolve against document.baseURI) |
| PEGI 12 | Pass with portal defaults (clean on, gore off). Story still has exes, booze jokes, a drunk enemy: mild |
| No custom fullscreen button | Pass (none in game) |
| No cross-promo / external links | Pass (no outbound links in game) |
| English, readable at 907x510 and 800x450 | Pass at 907x510 (render); 800x450 phone not checked yet |
| Mouse + keyboard + touch | Touch controls exist; CrazyGames says don't pick mobile controls from touch detection alone |
| Covers: 1920x1080, 800x1200, 800x800, title only, no borders/logos | Done: `docs/portals/covers/` (`tools/make_portal_covers.py`; Duff portrait upscaled ~2x, fine at card size) |
| Preview video: 15-20 s, landscape 1080p + portrait 2:3, no sound | TODO |
| Mobile homepage (<= 20 MB initial) | Not eligible without the SDK. With SDK + gameplayStart after world.pck it is ~20 MB |

Full Launch (ads, revenue share) comes after Basic Launch metrics, and needs the CrazyGames SDK (gameplay start/stop,
ads through the SDK, saves through the Data module, land in gameplay within one click). Not started.

## GameDistribution
Needs its SDK in index.html with a gameId from Duff's GD dashboard before upload. Blocked on Duff making the account.

## Duff's steps (phone)
1. developer.crazygames.com: sign up, Submit game, upload `duffquest-crazygames.zip` from the `dev` release.
2. Orientation: landscape. Mobile: on.
3. Upload the 3 covers + 2 videos (once made).
