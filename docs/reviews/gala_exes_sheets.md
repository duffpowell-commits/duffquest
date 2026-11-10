# Gala exes' world sprite sheets (Nov 10, 2026)

Canva refused the face-reference upload again, so these were repainted in code from sheets already in the
repo (deterministic scripts, `tools/sheet_repaint/<id>.py`; rerun from the repo root). Masters:
`grok_art/2026-11-10-gala-exes/sheet_<id>.png`; the old sheets are kept in `grok_art/2026-11-10-gala-exes/old/`.
Compare renders `docs/renders/sheet_<id>_compare.png` (old, new, portrait). In game: `docs/renders/gala_exes_sheets_ingame.png`.
Graded full-size against docs/art_rules.md (S1-S3, P1) and the brief's look.

| id | who | base | grade | notes / next fix |
|---|---|---|---|---|
| husk | Tyler Pivot | old ch_husk | PASS | Goggles, jetpack, silver jacket gone. Hair still spiky, not curtain bangs; faint strap line in side rows; left row is a mirror of the right body (base was). |
| bozos | Grant Gratuity | old ch_donald | PASS | Emerald tux, bow tie, pencil moustache, glasses, tablet + glare. Side-view glasses a bit heavy; side bow tie reads as a knot. |
| fences | Landlord Lance | ch_crypto | PASS | Captain's hat, salmon polo, navy blazer, khaki shorts, boat shoes, paper-slap attack. A few loose pixels in the back attack cell. |
| donald | Chip Leverage | ch_gymbro | PASS (weakest) | Silver hair, charcoal vest, blue sleeves, slacks, archive-box attack. Flatter and less detailed than the other sheets; side hair reads helmet-like. First to redo if real art becomes possible. |

Also fixed: `ch_crypto.png` had its side rows reversed against `Art.row_for()` (row 2 faced screen-left), so Mr.
Crypto walked backwards. Rows 2 and 3 swapped; the old file is in the `old/` folder.
