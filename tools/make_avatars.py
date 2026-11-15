"""Phone avatars (av_*) as head crops of the current 2x walk sheets.

python3 tools/make_avatars.py [OUT_DIR]   (default assets/art)
Takes the front idle frame (row 0, col 0, 128 px cells), finds the top of the head, crops a square around the head
and shoulders, scales to 48x48 on a dark round-cornered tile like the old avatars."""
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
    head = cell.crop((x0, y0, x0 + SIDE, y0 + SIDE)).resize((44, 44), Image.LANCZOS)
    tile = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle((0, 0, 47, 47), 7, fill=(43, 34, 24, 255))
    mask = Image.new("L", (48, 48), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 47, 47), 7, fill=255)
    tile.alpha_composite(head, (2, 4))
    tile.putalpha(mask)
    return tile


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/art"
    for av, sheet in SRC.items():
        avatar(sheet).save("%s/%s.png" % (out, av))
        print(av, "<-", sheet)
