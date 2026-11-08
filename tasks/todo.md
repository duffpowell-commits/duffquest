# Duff Quest — todo

## M1: Duff outfit sheets (Nov 8) — done
- [x] Key the 10 outdoor sheets from `grok_art/2026-11-08-duff-outfits/` (`tools/import_sheet.py`, drop 3)
- [x] Redraw `duff_shades.png` for the new head (`tools/make_shades.py`); old overlay sat on the hair
- [x] In-engine check: `tools/outfit_shot.tscn` + `tools/outfit_sheet.py` -> `docs/renders/duff_outfits_ingame.png`

## M2: street dressing (Nov 8) — done
- [x] Import trees/clutter/fences (`tools/import_dressing.py`), place via `data/town_dressing.json`
- [x] Depth sort + see-through canopy for Duff; `tools/dressing_check.gd` for blocked spots
- [x] Review fixes: bench by the bus sign, cones on the road, bin at the curb, props at Fork/Kwik/Walgrumps, stray picket removed

## Leftovers from the M2 review
- [ ] Fade trees for NPCs/enemies/cats behind them too (only Duff now)
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
