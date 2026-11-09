#!/usr/bin/env python3
"""Stitch the gore frames from ko_shot ("-- <boss> gore") into docs/renders/ko_gore_<boss>.png (2 x 3, half size).
   python3 tools/ko_gore_sheet.py gymbro [ghoster ...]"""
import sys
from PIL import Image

for boss in sys.argv[1:]:
    frames = [Image.open(f"/tmp/qa/ko_gore_{boss}_{i}.png").convert("RGB") for i in range(6)]
    w, h = frames[0].size
    sw, sh = w * 2 // 3, h * 2 // 3
    sheet = Image.new("RGB", (sw * 2 + 8, sh * 3 + 16), (12, 10, 14))
    for i, f in enumerate(frames):
        # column 0 = x-ray hit, column 1 = finisher; rows = early, mid, late
        col, row = i // 3, i % 3
        sheet.paste(f.resize((sw, sh), Image.LANCZOS), (col * (sw + 8), row * (sh + 8)))
    out = f"docs/renders/ko_gore_{boss}.png"
    sheet.save(out, optimize=True)
    print(out)
