"""Before/after sheet of /tmp/actor_fade/*_{old,new}.png (full frames, half size)
-> docs/renders/see_through_actors.png"""
from pathlib import Path
from PIL import Image, ImageDraw
SRC = Path("/tmp/actor_fade")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders" / "see_through_actors.png"
names = sorted({f.stem.rsplit("_", 1)[0] for f in SRC.glob("*.png")})
W, H = 640, 360
sheet = Image.new("RGB", (W * 2, H * len(names)))
for r, n in enumerate(names):
    for c, v in enumerate(["old", "new"]):
        t = Image.open(SRC / f"{n}_{v}.png").convert("RGB").resize((W, H), Image.NEAREST)
        d = ImageDraw.Draw(t)
        d.rectangle((0, H - 16, 240, H), fill=(0, 0, 0))
        d.text((6, H - 14), f"{n}  {'BEFORE' if v == 'old' else 'AFTER (M4)'}", fill=(255, 255, 0))
        sheet.paste(t, (c * W, r * H))
sheet.save(OUT)
print("wrote", OUT)
