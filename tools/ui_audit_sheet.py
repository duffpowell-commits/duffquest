#!/usr/bin/env python3
"""Contact sheet of /tmp/ui_audit/*.png (sorted) -> docs/renders/ui_audit_<tag>.png. Usage: ui_audit_sheet.py <tag>"""
import os, sys
from PIL import Image, ImageDraw
SRC = "/tmp/ui_audit"
tag = sys.argv[1] if len(sys.argv) > 1 else "before"
files = sorted(f for f in os.listdir(SRC) if f.endswith(".png"))
W, H, C = 400, 225, 5
rows = (len(files) + C - 1) // C
sheet = Image.new("RGB", (W * C, H * rows), "black")
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(os.path.join(SRC, f)).convert("RGB").resize((W, H), Image.LANCZOS)
    x, y = (i % C) * W, (i // C) * H
    sheet.paste(im, (x, y))
    name = f[:-4]
    d.rectangle([x, y + H - 14, x + 7 * len(name) + 8, y + H], fill="black")
    d.text((x + 4, y + H - 12), name, fill="yellow")
out = os.path.join(os.path.dirname(__file__), "..", "docs/renders/ui_audit_%s.png" % tag)
sheet.save(out)
print("wrote", os.path.normpath(out), len(files), "shots")
