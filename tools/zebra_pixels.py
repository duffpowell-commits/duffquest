# Madison's framed zebra print. The room art already has a small framed picture on the wall by the shower;
# this paints a zebra head into that frame's picture area (7x10 px at home_interior density, s:2) so the
# frame, mat and lighting all stay the room's own. Colours are the old picture's muted, lamp-lit tones.
# Run: python3 tools/zebra_pixels.py assets/art   then touch the png and godot --import.
# Placement: interior px (483, 38) = world ZEBRA_PIC (241.5, 459) in main.gd.
import sys
from PIL import Image

OUT = sys.argv[1]
PIC = [
"KbbbbbK",
"WKbbbKW",
"bWKWKWb",
"bKWWWKb",
"WEKWKEW",
"bWWKWWb",
"bKWWWKb",
"bbWKWbb",
"bbMMMbb",
"ccMmMcc",
]
# lit (right) / shade (left) pairs
PAL = {
    "b": ((168, 170, 124), (140, 140, 104)),   # sage ground, like the old picture's greens
    "c": ((214, 186, 140), (190, 160, 118)),   # warm floor strip
    "W": ((244, 220, 176), (222, 192, 152)),   # hide, lamp-warmed
    "K": ((104, 66, 60), (84, 52, 50)),        # stripes, warm dark brown (no black)
    "E": ((60, 34, 36), (60, 34, 36)),
    "M": ((84, 52, 50), (70, 42, 44)),
    "m": ((54, 30, 32), (54, 30, 32)),
}
im = Image.new("RGBA", (len(PIC[0]), len(PIC)), (0, 0, 0, 0))
for y, row in enumerate(PIC):
    for x, c in enumerate(row):
        lit, shade = PAL[c]
        im.putpixel((x, y), (lit if x >= 3 else shade) + (255,))
# inner mat shadow along the top, like the frame casts on the old picture
for x in range(len(PIC[0])):
    r, g, b, a = im.getpixel((x, 0))
    im.putpixel((x, 0), (int(r * 0.78), int(g * 0.72), int(b * 0.7), 255))
im.save(OUT + "/home_zebra_print.png")
print(im.size)
