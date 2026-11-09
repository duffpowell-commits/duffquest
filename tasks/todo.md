# Duff Quest — todo

## JAM PUSH (Nov 9 → Dec 28; itch "2026 Jam" closes Dec 31). Entry: DuffQuest + Chaos if we bust ass.
- [ ] **Upload the updated build to itch** (`dufftkyosht.itch.io/duff-quest`). Fastest: Duff makes a butler API key
      (itch.io → Settings → API keys), pastes it once, Claude pushes with butler from the sandbox (itch API reachable,
      tested Nov 9). Key lives only in a temp env var, never in the repo. Fallback: phone upload, `docs/itch_deploy.md`.
- [ ] Rebuild the web zip AFTER the art fixes + KO sfx land (zip from 06:51 Nov 9 = commit dc217e1, stale).
- [ ] Submit DuffQuest to the 2026 Jam once the itch page is current; keep pushing updates until Dec 28.
- [ ] Itch page: screenshots, GIF, controls, AI-use disclosure, content tag (cartoon blood/violence).
- [ ] Shrink the web build (90 MB zipped; mostly KO/loading JPGs) — try q80 + 1024w for loading screens.
- [ ] Art fixes from `docs/reviews/*.md` (Canva agent running Nov 9): 19 KO stills, loading screens, crypto/fences cards, octavia/bdaydad portraits.
- [ ] Duff sprite tattoos via `tools/tattoo_sprites.py` (pixel recolor agent running Nov 9).
- [ ] KO sfx + stat screen overflow fix (agent running Nov 9) — review, test, commit.
- [ ] In-engine cartoon blood/spit/teeth particles on KO x-ray + finisher hits (art rule H2).
- [ ] KO stills for the last 6 bosses: coupon, allergy, camper, bdaydad, dasher, baron.
- [ ] Restyle 21 old chibi sprite sheets (see `docs/reviews/loading_sprites.md`).
- [ ] Portrait cut-out green halo cleanup script (all 21 portraits).
- [ ] Chaos Is the Mother of Order: separate repo/session; check where its jam slice stands.

## M1: Duff outfit sheets (Nov 8) — done
- [x] Key the 10 outdoor sheets from `grok_art/2026-11-08-duff-outfits/` (`tools/import_sheet.py`, drop 3)
- [x] Redraw `duff_shades.png` for the new head (`tools/make_shades.py`); old overlay sat on the hair
- [x] In-engine check: `tools/outfit_shot.tscn` + `tools/outfit_sheet.py` -> `docs/renders/duff_outfits_ingame.png`

## M2: street dressing (Nov 8) — done
- [x] Import trees/clutter/fences (`tools/import_dressing.py`), place via `data/town_dressing.json`
- [x] Depth sort + see-through canopy for Duff; `tools/dressing_check.gd` for blocked spots
- [x] Review fixes: bench by the bus sign, cones on the road, bin at the curb, props at Fork/Kwik/Walgrumps, stray picket removed

## Leftovers from the M2 review
- [x] Fade trees for NPCs/enemies/cats behind them too (M4, Nov 8: `see_through_actors.png`)
- [ ] Depth order for non-Duff actors: front-layer items are picked by DUFF's feet, so an enemy standing
      in FRONT of such a tree still draws under it (now faded, so visible, but wrong layering). Real fix =
      y-sort actors + dressing together (bigger refactor; only if it shows in play)
- [ ] Grok redraws: Waffle Haus pole sign, bus-stop sign, cats (old flat art)
- [ ] Right-hand lawns still big and empty; more props / a second yard once art allows

## Art follow-ups from the M1 review (Grok redraws, not code)
- [ ] Step frames (cols 1-2): clean legs on side rows, add a 1 px head bob
- [ ] Attack frame (col 3): real wind-up / extended swing + a smear frame (GBA DBZ pillar)
- [ ] Make outfits readable at a glance: real clogs, a light apron or coloured jacket; dark outfits vanish on asphalt
- [ ] Clean the speckled dark outline around hair/ponytail (in Grok's source)
- [ ] Hair: move from ginger toward the approved portrait's dirty blond

## M3: combat feel (Nov 8) — done
- [x] Hit-stop, shake (limit-clamped + zoom punch), sparks, popping numbers (`scripts/juice.gd`)
- [x] Review fixes: brulee/tempura ticks no longer freeze; spatula "flip" no longer counts as heavy; crits do; no late shake after the 86 cinematic/pause
- [ ] Try it on the phone: is 70 ms light hit-stop too sticky on fast combos?
- [ ] Enemy speech bubbles still cover damage numbers when 3+ enemies bunch up
- (Nov 9) Stat points screen: Defense and Grit button labels run past the button edge (seen in smoke frame 599).
