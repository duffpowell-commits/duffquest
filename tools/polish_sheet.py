"""Before/after sheets for the Nov 9 combat polish (run barks_shot + ysort_shot with SHOT_TAG=old
on the old code and SHOT_TAG=new on this one first; frames in /tmp/cp_shots/<tag>/).
-> docs/renders/barks_bunched.png, docs/renders/actor_ysort.png"""
from pathlib import Path
from PIL import Image, ImageDraw
SRC = Path("/tmp/cp_shots")
OUT = Path(__file__).resolve().parent.parent / "docs" / "renders"

def sheet(names, crop, scale, out, labels):
    w, h = crop[2] - crop[0], crop[3] - crop[1]
    W, H = int(w * scale), int(h * scale)
    img = Image.new("RGB", (W * len(names), H * 2 + 4), (20, 16, 24))
    for r, tag in enumerate(["old", "new"]):
        for c, n in enumerate(names):
            t = Image.open(SRC / tag / f"{n}.png").convert("RGB").crop(crop).resize((W, H), Image.NEAREST)
            d = ImageDraw.Draw(t)
            txt = f"{'BEFORE' if tag == 'old' else 'AFTER'}  {labels[c]}"
            d.rectangle((0, H - 18, 8 + 7 * len(txt), H), fill=(0, 0, 0))
            d.text((5, H - 15), txt, fill=(255, 230, 0))
            img.paste(t, (c * W, r * (H + 4)))
    img.save(OUT / out)
    print("wrote", OUT / out)

sheet(["barks_a", "barks_b", "barks_c"], (300, 120, 980, 460), 0.75, "barks_bunched.png",
      ["4 barks tried in 1.5 s", "+1 s", "+2 s"])
sheet(["ysort_behind", "ysort_front", "ysort_both"], (420, 170, 860, 520), 0.9, "actor_ysort.png",
      ["pirate behind oak", "pirate in front", "one each side"])
