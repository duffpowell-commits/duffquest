# Madison's zebra plush (after her Wild Republic one), hand-placed pixels at home_interior density (s:2).
# Run: python3 tools/zebra_plush_pixels.py assets/art/home_zebra_plush.png
import sys
from PIL import Image
G=[
".......OO....OO.....",
"......OKWO..OWPO....",
".....OKKWWOOWWPO....",
"....OKOKWWWWWWWO....",
"...OKKOWKWWKWWWWO...",
"...OKOWWWKWWWKWWO...",
"...OKOWKWWWEEWWWWO..",
"..OKKOWWKWWEeWWWWO..",
"..OKOWKWWKWWWWMMMMO.",
"..OKOWWKWWWWWMMMMMMO",
"..OKOWKWWKWWWOMMMMO.",
"..OKOWWKWWKWWWOOOO..",
"...OWKWWKWWKWWWO....",
"..OWKWWKWWKWWKWWO...",
".OWWKWWKWWKWWKWwO...",
".OWKWWKWOWWKWWKwO...",
"OOWKWWKWOWKWWKWWwO..",
"OKOWKWKWOWWKWOWKwO..",
"OKKOWWKWOWKWWOWWKwO.",
".OOWKWWOWWKWWOWKWwO.",
"..OWWKWOWKWWOOWKWwO.",
".OHHHHHOHHHHOHHHHHO.",
".OHHHHHOHHHHOHHHHHO.",
"..OOOOO.OOOO.OOOOO..",
]
PAL={"O":(34,22,22),"W":(244,214,166),"w":(196,156,110),"K":(40,28,30),"M":(30,22,24),"E":(10,8,8),"e":(250,240,230),"H":(44,30,30),"P":(226,150,128)}
Wd=max(len(r) for r in G)
im=Image.new("RGBA",(Wd,len(G)),(0,0,0,0))
for y,r in enumerate(G):
    for x,c in enumerate(r):
        if c in PAL: im.putpixel((x,y),PAL[c]+(255,))
# re-stripe the hide: continuous bands instead of dots
for y,r in enumerate(G):
    for x,c in enumerate(r):
        if c not in "WK" or (y<=11 and x<=4): continue
        if y<=11:
            if y<=2 or (x>=10 and 5<=y<=8 and x<=14): stripe=False  # ears, eye zone clear
            else: stripe=((y*1.0 - abs(x-12)*0.25) % 3) < 1
        elif y>=18: stripe = (y%2==0)
        else: stripe=((x + y*0.4) % 3) < 1
        im.putpixel((x,y),(PAL["K"] if stripe else PAL["W"])+(255,))
im.save(sys.argv[1])
# room light from upper right + contact shadow on the shelf (last row)
import numpy as np
a=np.array(Image.open(sys.argv[1])).astype(float); h,w=a.shape[:2]
yy,xx=np.mgrid[0:h,0:w]
a[...,:3]*=((1.03-0.2*yy/(h-1))*(0.88+0.12*xx/(w-1)))[...,None]
o=np.zeros((h+1,w+1,4)); o[h,2:w,:]=(60,22,12,110); o[h-1,w,:]=(60,22,12,70)
A=a[...,3]>0; o[:h,:w][A]=a[A]
Image.fromarray(np.clip(o,0,255).astype(np.uint8),"RGBA").save(sys.argv[1])
