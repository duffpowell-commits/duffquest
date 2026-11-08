"""Layout guides for the M7 backdrop request (grok_art/requests/m7/<id>.png).
Left: current backdrop (640x360) with must-keep areas outlined. Right: in-game shot if one exists
(/tmp/qa from tools/qa_shot.tscn). Re-run after qa_shot if screens change.
    python3 tools/make_m7_guides.py"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "grok_art" / "requests" / "m7"
QA = Path("/tmp/qa")
S = 2  # world units -> backdrop px

# home interior solids, world coords relative to INT_ORIGIN (0, 440); from main.gd
HOME = {"bed": (12, 42, 56, 36), "crib": (76, 42, 30, 26), "shower": (272, 42, 36, 40),
        "fridge": (120, 42, 24, 36), "counter": (144, 42, 92, 37), "couch": (20, 136, 72, 22),
        "mirror": (272, 92, 17, 40), "side table": (207, 134, 44, 26), "dresser": (290, 136, 22, 26),
        "cat tree": (113, 160, 14, 12), "Madison spot": (106, 132, 8, 6), "top wall": (0, 0, 320, 8)}
ROOM = {"top wall band (walkable starts below)": (0, 0, 320, 30), "left wall": (0, 0, 8, 180),
        "right wall": (312, 0, 8, 180), "bottom wall": (0, 172, 320, 8)}
SHOTS = {"home_interior": "home", "bg_kwik": "shop", "bg_pharmacy": "pharmacy", "bg_grocery": "grocery",
         "bg_plasma": "plasma", "gala": "gala", "arena_crypto": "boss_crypto_fight",
         "arena_djvape": "boss_djvape_fight", "arena_ghoster": "boss_ghoster_fight",
         "arena_gymbro": "boss_gymbro_fight", "arena_willnot": "boss_willnot_fight"}
IDS = ["home_interior", "bg_kitchen", "arena_alley", "arena_waffle", "gala", "bg_kwik", "bg_grocery",
       "bg_pharmacy", "bg_plasma", "arena_crypto", "arena_djvape", "arena_ghoster", "arena_gymbro",
       "arena_willnot", "bg_holland", "bg_akarui", "bg_bedroom", "bg_nursery", "bg_living_night"]


def guide(i):
    art = Image.open(ROOT / "assets" / "art" / f"{i}.png").convert("RGB")
    over = Image.new("RGBA", art.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    boxes = HOME if i == "home_interior" else (ROOM if i.startswith("arena_") or i == "gala" else {})
    for name, (x, y, w, h) in boxes.items():
        r = (x * S, y * S, (x + w) * S - 1, (y + h) * S - 1)
        d.rectangle(r, fill=(255, 40, 40, 60), outline=(255, 40, 40, 255), width=2)
        d.text((r[0] + 3, r[1] + 2), name, fill=(255, 255, 255, 255))
    left = Image.alpha_composite(art.convert("RGBA"), over).convert("RGB")
    shot = QA / f"{SHOTS[i]}.png" if i in SHOTS else None
    w = 640 + (660 if shot and shot.exists() else 0)
    sheet = Image.new("RGB", (w, 384), (24, 22, 30))
    sheet.paste(left, (0, 24))
    t = ImageDraw.Draw(sheet)
    t.text((4, 6), f"{i}  current art, red = keep this layout (walls / furniture you collide with)", fill=(255, 220, 0))
    if shot and shot.exists():
        sheet.paste(Image.open(shot).convert("RGB").resize((640, 360)), (660, 24))
        t.text((664, 6), "in game today (UI drawn on top)", fill=(255, 220, 0))
    sheet.save(OUT / f"{i}.png")


OUT.mkdir(parents=True, exist_ok=True)
for i in IDS:
    guide(i)
print("wrote", len(IDS), "guides to", OUT.relative_to(ROOT))
