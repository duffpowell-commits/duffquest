"""Key Place's 1920x1080 boss intro splashes (flat #FF00FF or #00FF00, name lettered on) into
transparent 960x540 PNGs for the HD overlay.

    python3 tools/import_boss_intro.py            # all 17, burst cards (Duff's pick, Nov 8)
    python3 tools/import_boss_intro.py husk baron
    python3 tools/import_boss_intro.py --keyed    # the cut-out versions instead
Burst cards (`new_boss_intro_<b>_burst_preview.png`) are opaque full-bleed 16:9: just downscaled.

- key read from the corner pixel; soft alpha ramp on the key distance (cartoon edges stay smooth)
- key spill pulled out of the semi-transparent edge pixels
- downscaled 2x (LANCZOS: these are cartoons, not pixel art)
Output: assets/art/boss_intro/<boss>.png
"""
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "grok_art" / "2026-11-08-bosses"
OUT = ROOT / "assets" / "art" / "boss_intro"
BOSSES = ["husk", "bozos", "fences", "baron", "donald", "ghoster", "gymbro", "djvape", "crypto",
          "willnot", "regular", "sendback", "coupon", "allergy", "camper", "bdaydad", "dasher"]
LO, HI = 70, 200   # key distance: <= LO fully clear, >= HI fully solid


def key_out(im):
    im = im.convert("RGB")
    key = im.getpixel((0, 0))
    green = key[1] > key[0]
    w, h = im.size
    src = im.load()
    out = Image.new("RGBA", (w, h))
    dst = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = src[x, y]
            d = abs(r - key[0]) + abs(g - key[1]) + abs(b - key[2])
            if d <= LO:
                dst[x, y] = (0, 0, 0, 0)
                continue
            a = 255 if d >= HI else int(255 * (d - LO) / (HI - LO))
            if green and g > max(r, b):
                g = max(r, b)
            elif not green and min(r, b) > g:
                r = b = min(max(r, b), g + (max(r, b) - g) // 3)
            dst[x, y] = (r, g, b, a)
    return out


def run(boss, keyed):
    if keyed:
        im = key_out(Image.open(SRC / f"new_boss_intro_{boss}.png"))
    else:
        im = Image.open(SRC / f"new_boss_intro_{boss}_burst_preview.png").convert("RGB")
    im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    dst = OUT / f"{boss}.png"
    im.save(dst, optimize=True)
    print("wrote", dst.relative_to(ROOT), im.size, f"{dst.stat().st_size // 1024} KB")


if __name__ == "__main__":
    keyed = "--keyed" in sys.argv
    names = [a for a in sys.argv[1:] if not a.startswith("--")]
    for b in (names or BOSSES):
        run(b, keyed)
