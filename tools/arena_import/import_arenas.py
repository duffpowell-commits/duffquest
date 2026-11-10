#!/usr/bin/env python3
"""Bring the six painted boss arenas (Canva, Nov 10, saved by Duff to Drive "97 Gemini art drops") into the game.

Usage: python3 tools/arena_import/import_arenas.py <dir with alley.png ghoster.png djvape.png crypto.png willnot.png waffle.png>
Each source is 1920x1080. Writes assets/art/arena_<id>.png at 1280x720 (manifest "s": 4 -> 320x180 world units,
4 screen px per unit, so they show at native sharpness). Gym (arena_gymbro) is separate art and is not touched.
tools/arena_paint/ is the old code-painted fallback; it writes over these files, so only run it on purpose.
"""
import os
import sys
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IDS = ["alley", "ghoster", "djvape", "crypto", "willnot", "waffle"]


def main():
    src = sys.argv[1]
    for k in IDS:
        im = Image.open(os.path.join(src, k + ".png")).convert("RGB")
        if im.size[0] * 9 != im.size[1] * 16:
            sys.exit("%s is not 16:9: %s" % (k, im.size))
        out = os.path.join(ROOT, "assets/art/arena_%s.png" % k)
        im.resize((1280, 720), Image.LANCZOS).save(out, optimize=True)
        print("wrote", os.path.relpath(out, ROOT), os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
