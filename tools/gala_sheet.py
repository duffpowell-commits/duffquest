"""Tile /tmp/gala_shot/*.png (tools/gala_shot.tscn) into docs/renders/gala_exes_intros.png:
one row per gala ex (setup line, intro, fight).    python3 tools/gala_sheet.py"""
from pathlib import Path
from PIL import Image, ImageDraw

SRC = Path("/tmp/gala_shot")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders" / "gala_exes_intros.png"
fs = sorted(SRC.glob("*.png"))
w, h, cols = 640, 360, 3
rows = (len(fs) + cols - 1) // cols
sheet = Image.new("RGB", (w * cols, (h + 14) * rows), (20, 20, 24))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(fs):
    x, y = (i % cols) * w, (i // cols) * (h + 14)
    sheet.paste(Image.open(f).convert("RGB").resize((w, h)), (x, y + 14))
    d.text((x + 4, y + 1), f.stem, fill=(240, 220, 160))
sheet.save(OUT)
print(OUT)
