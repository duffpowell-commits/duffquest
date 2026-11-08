"""Contact sheet + GIF from tools/combat_shot frames (/tmp/combat/f*.png).
    python3 tools/combat_sheet.py [first last step]
-> docs/renders/combat_feel.png (grid of centre crops) and docs/renders/combat_feel.gif"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw
SRC = Path("/tmp/combat")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders"
first, last, step = (int(a) for a in sys.argv[1:4]) if len(sys.argv) > 3 else (226, 300, 3)
def crop(n):
    im = Image.open(SRC / f"f{n:08d}.png").convert("RGB")
    W, H = im.size
    return im.crop((W // 2 - 160, H // 2 - 110, W // 2 + 160, H // 2 + 70))
frames = list(range(first, last + 1, step))
tiles = []
for n in frames:
    c = crop(n)
    ImageDraw.Draw(c).text((4, 4), str(n), fill=(255, 255, 0))
    tiles.append(c)
cols = 5
w, h = tiles[0].size
sheet = Image.new("RGB", (w * cols, h * ((len(tiles) + cols - 1) // cols)))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % cols) * w, (i // cols) * h))
sheet.save(OUT / "combat_feel.png")
gif = [crop(n).resize((w // 2 * 2, h // 2 * 2)) for n in range(first, min(last + 120, 470), 1)]
gif[0].save(OUT / "combat_feel.gif", save_all=True, append_images=gif[1:], duration=33, loop=0)
print("wrote combat_feel.png/.gif", len(tiles), len(gif))
