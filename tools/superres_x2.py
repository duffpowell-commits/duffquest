"""2x super-resolution for painted art (EDSR, OpenCV dnn_superres), tiled with overlap.

Used Nov 16 2026 for assets/art/ground_painted.png (1344x768 -> 2688x1536) so the street matches the
4 px/unit sprites at native resolution. Layout is untouched: same footprint, same origin (ground.gd
accepts a painted ground at 1x or 2x the tile build).

Setup (sandbox): pip install opencv-contrib-python-headless
  curl -sSL -o /tmp/sr/EDSR_x2.pb https://raw.githubusercontent.com/Saafke/EDSR_Tensorflow/master/models/EDSR_x2.pb
Run: python3 tools/superres_x2.py SRC OUT [--model /tmp/sr/EDSR_x2.pb]   (~5 min on CPU for the ground)
After tools/import_street.py (which writes 1x), run this on its output to get back to 2x.
"""
import sys
import cv2
import numpy as np

args = sys.argv[1:]
model = "/tmp/sr/EDSR_x2.pb"
if "--model" in args:
    i = args.index("--model")
    model = args[i + 1]
    del args[i:i + 2]
src, out_path = args[0], args[1]
sr = cv2.dnn_superres.DnnSuperResImpl_create()
sr.readModel(model)
sr.setModel("edsr", 2)
img = cv2.imread(src, cv2.IMREAD_COLOR)
h, w = img.shape[:2]
T, O = 256, 16
out = np.zeros((h * 2, w * 2, 3), np.uint8)
for y in range(0, h, T):
    for x in range(0, w, T):
        y0, x0 = max(0, y - O), max(0, x - O)
        y1, x1 = min(h, y + T + O), min(w, x + T + O)
        up = sr.upsample(img[y0:y1, x0:x1])
        oy, ox = (y - y0) * 2, (x - x0) * 2
        hh, ww = min(T, h - y) * 2, min(T, w - x) * 2
        out[y * 2:y * 2 + hh, x * 2:x * 2 + ww] = up[oy:oy + hh, ox:ox + ww]
cv2.imwrite(out_path, out)
print("wrote", out_path, out.shape[1], "x", out.shape[0])
