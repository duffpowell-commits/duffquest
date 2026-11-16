#!/bin/sh
# Rebuild spike3d/art/duff_home_hd3d.png from the Canva master, with Duff's two permanent fixes:
#   1. plain black T-shirt sleeves (his sleeve tattoos stop under the shirt; no print on the cloth)
#   2. his real fox on the LEFT side of the neck only (docs/ref/duff/duff_fox_neck_tattoo.png)
# Run from the repo root:  sh spike3d/tools/build_duff_hd.sh <master.png>
# Master: Drive "97 Gemini art drops", ch_duff_home_hd3d_v1.png.png (2048x2048, 4x4, magenta key).
# A new master needs the ellipses in sleeves.py and the polygons in fox_sheet.py re-placed.
set -e
SRC=$1; T=/tmp/duff_hd3d_build; mkdir -p $T
python3 tools/import_big_sheet.py "$SRC" duff_home_hd3d --cell 512 --height 416 --feet 480 --smooth --auto-grid --row-feet --tol 90 --fit-action
mv assets/art/duff_home_hd3d.png $T/raw.png
python3 spike3d/tools/sleeves.py $T/raw.png $T/sleeves.png
python3 spike3d/tools/fox_sheet.py $T/sleeves.png spike3d/art/duff_home_hd3d.png
python3 spike3d/tools/sleeves.py spike3d/art/duff_home_hd3d.png /dev/null --check
