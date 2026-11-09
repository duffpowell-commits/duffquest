"""Before/after HUD sheet from tools/hud_shot.tscn runs.
    python3 tools/hud_sheet.py /tmp/hud_before /tmp/hud_after  -> docs/renders/hud_declutter.png"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

before, after = Path(sys.argv[1]), Path(sys.argv[2])
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders" / "hud_declutter.png"
shots = ["town", "fight", "drawer", "peek", "rent_due"]
w, h, lab = 640, 360, 16
sheet = Image.new("RGB", (w * 2, (h + lab) * len(shots)), (20, 20, 24))
d = ImageDraw.Draw(sheet)
for i, s in enumerate(shots):
    for j, (tag, src) in enumerate((("BEFORE", before), ("AFTER", after))):
        f = src / f"{s}.png"
        x, y = j * w, i * (h + lab)
        if f.exists():
            sheet.paste(Image.open(f).convert("RGB").resize((w, h)), (x, y + lab))
        d.text((x + 4, y + 2), f"{tag}: {s}", fill=(240, 220, 160))
sheet.save(OUT)
print("wrote", OUT)
