"""Contact sheet for tools/outfit_shot: crops Duff out of each /tmp/outfits/*.png (4x nearest)
next to the old sheet's stand frame, plus the full shades/fight frames.
    python3 tools/outfit_sheet.py [OLD_DIR]
OLD_DIR (optional) holds the pre-import duff_*.png for a before/after row."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

SRC = Path("/tmp/outfits")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders" / "duff_outfits_ingame.png"
old = Path(sys.argv[1]) if len(sys.argv) > 1 else None
names = [f"{a}_{s}" for a in ["apron", "clogs", "sleeves", "coat", "dad"] for s in ["red", "black"]]
full = Image.open(SRC / "apron_red.png")
W, H = full.size
cx, cy = W // 2, H // 2
cw, ch = W // 8, H // 4
tiles = []
for n in names:
    im = Image.open(SRC / f"{n}.png").convert("RGB")
    crop = im.crop((cx - cw // 2, cy - ch // 2 - ch // 6, cx + cw // 2, cy + ch // 2 - ch // 6))
    crop = crop.resize((240, 240 * crop.height // crop.width), Image.NEAREST)
    t = Image.new("RGB", (crop.width + (130 if old else 0), crop.height + 22), (24, 22, 30))
    t.paste(crop, (0, 22))
    if old:
        o = Image.open(old / f"duff_{n}.png").convert("RGBA").crop((0, 0, 64, 64)).resize((128, 128), Image.NEAREST)
        bg = Image.new("RGBA", o.size, (60, 60, 70, 255)); bg.alpha_composite(o)
        t.paste(bg.convert("RGB"), (crop.width + 1, 40))
    ImageDraw.Draw(t).text((4, 4), n + ("   (old sheet ->)" if old else ""), fill=(255, 255, 255))
    tiles.append(t)
tw, th = tiles[0].size
cols = 5
sheet_w = tw * cols
extra = [Image.open(SRC / f"{n}.png").convert("RGB") for n in ["shades", "fight"]]
ex = [e.resize((sheet_w // 2, sheet_w // 2 * e.height // e.width)) for e in extra]
sheet = Image.new("RGB", (sheet_w, th * 2 + ex[0].height), (24, 22, 30))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % cols) * tw, (i // cols) * th))
for i, e in enumerate(ex):
    sheet.paste(e, (i * sheet_w // 2, th * 2))
sheet.save(OUT)
print("wrote", OUT, sheet.size)
