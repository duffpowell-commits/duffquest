"""/tmp/voice/v*.png -> docs/renders/palahniuk_voice.png (2 columns, half size)."""
from pathlib import Path
from PIL import Image
fs = sorted(Path("/tmp/voice").glob("v*.png"))
W, H = 640, 360
s = Image.new("RGB", (W * 2, H * ((len(fs) + 1) // 2)))
for k, f in enumerate(fs):
    s.paste(Image.open(f).convert("RGB").resize((W, H)), ((k % 2) * W, (k // 2) * H))
out = Path(__file__).resolve().parent.parent / "docs/renders/palahniuk_voice.png"
s.save(out); print("wrote", out)
