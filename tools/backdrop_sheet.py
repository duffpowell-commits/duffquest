#!/usr/bin/env python3
"""Contact sheet of /tmp/backdrop_shot/*.png -> docs/renders/backdrops_nov10.png (4 columns, labelled)."""
import os
from PIL import Image, ImageDraw
SRC = "/tmp/backdrop_shot"
ORDER = ["kwik", "grocery", "pharmacy", "plasma", "holland", "akarui", "bedroom", "nursery", "living_night", "gala", "loading_cat"]
W, H = 480, 270
names = [n for n in ORDER if os.path.exists(os.path.join(SRC, n + ".png"))]
rows = (len(names) + 3) // 4
sheet = Image.new("RGB", (W * 4, H * rows), "black")
d = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    im = Image.open(os.path.join(SRC, n + ".png")).convert("RGB").resize((W, H), Image.LANCZOS)
    x, y = (i % 4) * W, (i // 4) * H
    sheet.paste(im, (x, y))
    d.rectangle([x, y, x + 9 * len(n) + 8, y + 16], fill="black")
    d.text((x + 4, y + 3), n, fill="yellow")
out = os.path.join(os.path.dirname(__file__), "..", "docs/renders/backdrops_nov10.png")
sheet.save(out)
print("wrote", os.path.normpath(out))
