"""Tile /tmp/qa/*.png (from tools/qa_shot.tscn) into labelled contact sheets in docs/renders/qa_*.png.
    python3 tools/qa_sheet.py"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

SRC = Path("/tmp/qa")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders"
GROUPS = {"ui": ["dialog_", "toast_", "home", "combat", "shop", "pharmacy", "grocery", "plasma", "gala"],
          "boss_intro": ["boss_*_intro"], "boss_fight": ["boss_*_fight"]}

def pick(pats):
    out = []
    for p in pats:
        out += sorted(SRC.glob(p + ("" if "*" in p else "*") + ".png"))
    return out

for name, pats in GROUPS.items():
    fs = pick(pats)
    if not fs:
        continue
    w, h, cols = 640, 360, 3
    rows = (len(fs) + cols - 1) // cols
    sheet = Image.new("RGB", (w * cols, (h + 14) * rows), (20, 20, 24))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(fs):
        x, y = (i % cols) * w, (i // cols) * (h + 14)
        sheet.paste(Image.open(f).convert("RGB").resize((w, h)), (x, y + 14))
        d.text((x + 4, y + 1), f.stem, fill=(240, 220, 160))
    sheet.save(OUT / f"qa_{name}.png")
    print("wrote", OUT / f"qa_{name}.png", len(fs))
