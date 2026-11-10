#!/usr/bin/env python3
"""Import painted 16:9 backdrops (Canva -> Drive "97 Gemini art drops") into the game.

Usage: python3 tools/backdrop_import/import_backdrops.py <dir> [name ...]
Each <dir>/<name>.png must be 16:9 (Canva exports 1920x1080).
  - bg_* and gala_floor -> assets/art/<id>.png at 1280x720; the manifest entry becomes w/h 1280x720, "s": 4
    (same 320x180 world units as the old 640x360 "s": 2 placeholders, but native sharpness). gala_floor -> gala.
  - cat_sacrifice (and any other loading id in data/loading_screens.json) -> assets/art/loading/<id>.jpg, 1280x720 q85.
Run `godot --headless --path . --import` afterwards (touch the files first if they already existed).
"""
import json
import os
import re
import sys
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MANIFEST = os.path.join(ROOT, "scripts/art_manifest.gd")
RENAME = {"gala_floor": "gala"}


def loading_ids():
    data = json.load(open(os.path.join(ROOT, "data/loading_screens.json")))
    items = data if isinstance(data, list) else data.get("screens", data.get("items", []))
    return {str(x.get("id")) for x in items if isinstance(x, dict)}


def set_manifest_hd(key):
    s = open(MANIFEST).read()
    pat = re.compile(r'("%s": \{\s*"w": )\d+(,\s*"h": )\d+(,\s*"cell": \[\s*)\d+(,\s*)\d+(\s*\],[\s\S]*?"s": )\d+' % re.escape(key))
    s2, n = pat.subn(r"\g<1>1280\g<2>720\g<3>1280\g<4>720\g<5>4", s, count=1)
    if n != 1:
        sys.exit("manifest entry not found for " + key)
    open(MANIFEST, "w").write(s2)


def main():
    src = sys.argv[1]
    names = sys.argv[2:] or sorted(os.path.splitext(f)[0] for f in os.listdir(src) if f.endswith(".png"))
    loads = loading_ids()
    for name in names:
        im = Image.open(os.path.join(src, name + ".png")).convert("RGB")
        if im.size[0] * 9 != im.size[1] * 16:
            sys.exit("%s is not 16:9: %s" % (name, im.size))
        im = im.resize((1280, 720), Image.LANCZOS)
        key = RENAME.get(name, name)
        if key in loads:
            out = os.path.join(ROOT, "assets/art/loading/%s.jpg" % key)
            im.save(out, quality=85, optimize=True)
        else:
            out = os.path.join(ROOT, "assets/art/%s.png" % key)
            im.save(out, optimize=True)
            set_manifest_hd(key)
        print("wrote", os.path.relpath(out, ROOT), os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
