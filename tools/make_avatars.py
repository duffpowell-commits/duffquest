"""Phone avatars (av_*) as head crops of the current 2x walk sheets.

python3 tools/make_avatars.py [OUT_DIR]   (default assets/art)
Takes the front idle frame (row 0, col 0, 128 px cells), finds the top of the head, crops a square around the head
and shoulders, scales to 96x96 (s 4: 24 world units) on a dark round-cornered tile like the old avatars,
and sets the av_* entries in assets/art/manifest.json + scripts/art_manifest.gd to 96 px, s 4."""
import json
import re
import sys
from PIL import Image, ImageDraw

SRC = {"av_duff": "duff_home", "av_madison": "ch_madison", "av_jen": "ch_jen", "av_chef": "ch_chef",
       "av_pharmacist": "ch_pharmacist", "av_sitter": "ch_sitter", "av_gala": "ch_butler"}
SIDE = 60  # crop side in sheet pixels (cell is 128, a body is ~104 tall)


def avatar(sheet: str) -> Image.Image:
    cell = Image.open("assets/art/%s.png" % sheet).convert("RGBA").crop((0, 0, 128, 128))
    a = cell.getchannel("A")
    box = a.point(lambda v: 255 if v > 40 else 0).getbbox()
    top = box[1]
    # head centre: middle of the opaque span on the rows just under the hair top
    rows = [y for y in range(top + 10, top + 26)]
    xs = [x for y in rows for x in range(128) if a.getpixel((x, y)) > 40]
    cx = (min(xs) + max(xs)) // 2
    x0 = max(0, cx - SIDE // 2)
    y0 = max(0, top - 3)
    head = cell.crop((x0, y0, x0 + SIDE, y0 + SIDE)).resize((88, 88), Image.LANCZOS)
    tile = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle((0, 0, 95, 95), 14, fill=(43, 34, 24, 255))
    mask = Image.new("L", (96, 96), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 95, 95), 14, fill=255)
    tile.alpha_composite(head, (4, 8))
    tile.putalpha(mask)
    return tile


def register(keys: list) -> None:
    ent = {"w": 96, "h": 96, "cell": [96, 96], "origin": [0, 0], "kind": "icon", "s": 4}
    mj = json.load(open("assets/art/manifest.json"))
    t = mj["assets"] if "assets" in mj else mj
    for k in keys:
        t[k] = dict(ent)
    open("assets/art/manifest.json", "w").write(json.dumps(mj, indent=2) + "\n")
    gd = open("scripts/art_manifest.gd").read()
    for k in keys:
        gd = re.sub(r'\n  "%s": \{.*?\n  \},' % re.escape(k), "", gd, flags=re.S)
        gd = re.sub(r'\n  "%s": \{[^\n]*\},' % re.escape(k), "", gd)
    add = "".join('\n  "%s": %s,' % (k, json.dumps(ent)) for k in sorted(keys))
    open("scripts/art_manifest.gd", "w").write(gd.replace("const ASSETS = {", "const ASSETS = {" + add, 1))


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/art"
    for av, sheet in SRC.items():
        avatar(sheet).save("%s/%s.png" % (out, av))
        print(av, "<-", sheet)
    if out == "assets/art":
        register(list(SRC))

