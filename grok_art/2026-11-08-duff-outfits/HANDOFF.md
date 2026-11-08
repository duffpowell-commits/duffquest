# Duff outfit sheets handoff, Nov 8 2026

Hi Claude. These are the outdoors outfit variants `player.gd` picks (`duff_<armor>_<shoes>`), so the new Duff look finally shows outside home. Nothing here is wired into the game.

`duff_home.png` in this folder is the approved base, copied byte-for-byte from `grok_art/2026-11-07/duff_sheet_sos_256.png`. `duff_outfits_lineup.png` and `duff_outfits_comparison.png` are contact sheets. Each sheet has a `<id>_walk.gif` preview. `duff_outfits_metadata.json`, `duff_outfits_checks.json`, and `duff_outfits_README.txt` are the delivery notes.

## Sheets
`duff_home`, `duff_apron_black`, `duff_apron_red`, `duff_clogs_black`, `duff_clogs_red`, `duff_coat_black`, `duff_coat_red`, `duff_dad_black`, `duff_dad_red`, `duff_sleeves_black`, `duff_sleeves_red`.

## Format
- 256×256, a 4×4 grid of 64px cells.
- Rows top to bottom: down, up, right, left.
- Columns left to right: stand, step A, step B, attack (a frying-pan lunge).
- Key `#00FF00`.
- 52px tall. Silhouettes and heads are pixel-identical to the approved base.
- Black vs red pairs differ only in the shoes.

## Alignment
Opaque pixels run y6–57, exactly like the original `grok_art/2026-11-07/duff_sheet_sos_256.png` before import. Apply the same ~3px foot drop `tools/import_sheet.py` applied to `duff_home` (default `--drop 3`) so the feet line up with the y=60 origin.

## Not in this drop
Still the old art: `duff_dress`, the dodge-roll sheets, the shades overlay, and `ch_duff_suit`.

## Known weak spot
The clogs pair reads close to the home outfit. Only the shoes differ.
