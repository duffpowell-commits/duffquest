"""Contact sheet of the fridge calendar renders: /tmp/qa/cal_*.png -> docs/renders/fridge_calendar.png"""
import glob
from PIL import Image
fs = sorted(glob.glob("/tmp/qa/cal_*.png"))
ims = [Image.open(f).convert("RGB") for f in fs]
w, h = ims[0].size
tw, th = w // 2, h // 2
out = Image.new("RGB", (tw * 2, th * ((len(ims) + 1) // 2)), (20, 20, 20))
for k, im in enumerate(ims):
    out.paste(im.resize((tw, th), Image.LANCZOS), ((k % 2) * tw, (k // 2) * th))
out.save("docs/renders/fridge_calendar.png")
print(len(ims), out.size)
