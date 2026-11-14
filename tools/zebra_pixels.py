# Hand-placed pixel art for Madison's framed zebra print, same density as home_interior (s:2).
# Run: python3 tools/zebra_pixels.py assets/art   then touch the pngs and godot --import.
import sys
from PIL import Image
OUT=sys.argv[1]
PLUSH=[
"......OMO......",
"..OO.OMMMO.OO..",
".OWPOWKMKWOPWO.",
".OWWKWKWKWKWwO.",
"..OKWWKWKWWKO..",
".OWWKWWKWWKWwO.",
".OKWWEWWWEWWKO.",
".OWKWEWKWEWKwO.",
".OKWWWWKWWWWKO.",
".OWKGGGGGGGKwO.",
"..OGgGGGGGgGO..",
"..OOGGGGGGGOO..",
".OWKOOOOOOOKwO.",
"OWKWWKWWWKWWKwO",
"OWWKWWKWKWWKWwO",
"OKWWKWWWWWKWWKO",
"OHHHWKWWWKwHHHO",
"OHHHOOWWwOOHHHO",
".OOO..OOO..OOO.",
]
PAL={"O":(74,30,22),"W":(246,222,184),"w":(204,166,128),"K":(46,28,32),"M":(30,18,22),
     "E":(20,12,14),"P":(232,150,132),"p":(178,92,86),"H":(84,50,44),"G":(110,82,80),"g":(40,24,28)}
FACE=[
".KK.....KK.",
".KWK.M.KWK.",
"..KWKMKWK..",
".KWKWKWKWK.",
".KWEWKWEWK.",
".KWKWWWKWK.",
"..KWKWKWK..",
"..KKWKWKK..",
"..KWKWKWK..",
"..KGGGGGK..",
"..KgGGGgK..",
"...KKKKK...",
]
FPAL={"K":(40,26,30),"M":(40,26,30),"W":(248,240,222),"E":(20,12,14),"P":(226,150,138),"p":(170,96,90),"G":(110,82,80),"g":(30,18,22)}
def grid(rows,pal):
    im=Image.new("RGBA",(len(rows[0]),len(rows)),(0,0,0,0))
    for y,r in enumerate(rows):
        for x,c in enumerate(r):
            if c in pal: im.putpixel((x,y),pal[c]+(255,))
    return im
# plush now comes from tools/zebra_plush_pixels.py
fw,fh=len(FACE[0])+6,len(FACE)+6
F=Image.new("RGBA",(fw,fh+3),(0,0,0,0))
dark=(108,34,26,255); mid=(178,64,42,255); hi=(220,120,70,255); mat=(206,180,134,255)
from PIL import ImageDraw
d=ImageDraw.Draw(F)
d.rectangle((0,3,fw-1,fh+2),fill=dark); d.rectangle((1,4,fw-2,fh+1),fill=mid); d.rectangle((2,5,fw-3,fh),fill=dark)
d.rectangle((3,6,fw-4,fh-1),fill=mat); d.line((2,4,fw-3,4),fill=hi)
cx=fw//2
for p in [(cx-1,0),(cx,0),(cx-2,1),(cx+1,1),(cx-3,2),(cx+2,2)]: F.putpixel(p,dark)
F.alpha_composite(grid(FACE,FPAL),(3,6))
F.save(OUT+"/home_zebra_print.png")
print(grid(PLUSH,PAL).size,F.size)
# soft room lighting: lit from the upper right, darker low and left; plus a contact shadow on the shelf
import numpy as np
def shade(path, shadow):
    im=np.array(Image.open(path)).astype(float); h,w=im.shape[:2]
    yy,xx=np.mgrid[0:h,0:w]
    f=(1.04-0.22*yy/(h-1))*(0.88+0.12*xx/(w-1))
    im[...,:3]*=f[...,None]; im[...,:3]*=np.array([1.0,0.95,0.88])
    out=np.clip(im,0,255).astype(np.uint8)
    if shadow:
        o=np.zeros((h+1,w+1,4),np.uint8); 
        o[h,2:w,:]=(60,22,12,110); o[h-1,w,:]=(60,22,12,70)
        o[:h,:w][out[...,3]>0]=out[out[...,3]>0]
        out=o
    Image.fromarray(out,"RGBA").save(path)

shade(OUT+"/home_zebra_print.png",False)

