"""Keep the big HD art lossy (WebP) in the build. The masters on disk stay untouched.

    python3 tools/set_lossy_imports.py          # fix every .import; prints what it changed

Godot's default texture import is lossless, which turned a 270 KB KO JPG into a 1.4 MB .ctex and
made the web pck ~80 MB. tools/ship_itch.sh runs this before importing, so new drops in these
folders get the same treatment without anyone touching the import dock. Pixel-art sprites
(assets/art/*.png, iso/, ground/) are NOT listed: lossy would smear their hard pixels.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# folder -> WebP quality. Portraits keep alpha lossless (WebP alpha), only the colour is lossy.
LOSSY = {
    "assets/art/ko": 0.8,
    "assets/art/loading": 0.8,
    "assets/art/boss_intro": 0.8,
    "assets/art/portraits_hd": 0.9,
}


def main():
    changed = 0
    for folder, q in LOSSY.items():
        for imp in sorted((ROOT / folder).glob("*.import")):
            t = imp.read_text()
            if 'importer="texture"' not in t:
                continue
            new = re.sub(r"^compress/mode=\d+$", "compress/mode=1", t, flags=re.M)
            new = re.sub(r"^compress/lossy_quality=[\d.]+$", f"compress/lossy_quality={q}", new, flags=re.M)
            if new != t:
                imp.write_text(new)
                changed += 1
    print(f"set_lossy_imports: {changed} .import files switched to lossy")


if __name__ == "__main__":
    main()
