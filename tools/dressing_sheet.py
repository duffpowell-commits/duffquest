"""Contact sheet of /tmp/dressing/*.png (centre crops) -> docs/renders/street_dressing_depth.png"""
from pathlib import Path
from PIL import Image, ImageDraw
SRC = Path("/tmp/dressing")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders" / "street_dressing_depth.png"
fs = sorted(SRC.glob("*.png"))
tiles = []
for f in fs:
    im = Image.open(f).convert("RGB")
    W, H = im.size
    c = im.crop((W // 2 - 200, H // 2 - 200, W // 2 + 200, H // 2 + 100))
    ImageDraw.Draw(c).text((6, 6), f.stem, fill=(255, 255, 255))
    tiles.append(c)
sheet = Image.new("RGB", (400 * 3, 300 * ((len(tiles) + 2) // 3)))
for k, t in enumerate(tiles):
    sheet.paste(t, ((k % 3) * 400, (k // 3) * 300))
sheet.save(OUT)
print("wrote", OUT)
