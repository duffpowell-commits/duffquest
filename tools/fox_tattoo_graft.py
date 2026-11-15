"""Graft Duff's real fox neck tattoo onto the painted Blackhead Patrol back.

Usage: python3 tools/fox_tattoo_graft.py BASE_NO_TATTOO.png OUT.png [--mirror]
BASE: the 2560x1440 back with a bare neck (project files renders/bg_blackheads_back_no_tattoo.png).
Tattoo master: docs/ref/duff/duff_fox_neck_tattoo.png (crop of Duff's photo, alpha = tattoo outline).
Ink multiplies the skin (keeps the painting's light); blue ink is painted pale blue.
Then: import_backdrops.py on a folder holding OUT as bg_blackheads_back.png.
"""
from PIL import Image, ImageDraw, ImageFilter, ImageOps
import numpy as np, sys
BASE, OUT = sys.argv[1], sys.argv[2]
MIRROR = '--mirror' in sys.argv
tw,th,px,py,sx = 170, 165, 1132, 390, (0.12 if MIRROR else -0.12)
master=Image.open('docs/ref/duff/duff_fox_neck_tattoo.png').convert('RGBA')
tat=master.convert('RGB')
m=master.getchannel('A')
a=np.asarray(tat).astype(float)
skin=np.array(a[300:340,360:420].reshape(-1,3).mean(0))
ratio=a/skin
blue=np.clip(((a[:,:,2]-a[:,:,0])+5)/30,0,1)  # blue ink weight
lum=np.clip((a@[0.3,0.5,0.2])/(skin@[0.3,0.5,0.2]),0.1,1.0)
ratio=np.dstack([lum,lum,lum,blue])
mm=np.asarray(m).astype(float)[:,:,None]/255
ratio=np.concatenate([ratio[:,:,:3]*mm+(1-mm),ratio[:,:,3:]*mm],2)
def prep(arr,mode,fill):
    r=Image.fromarray((arr*255).astype('uint8'),mode)
    if MIRROR: r=ImageOps.mirror(r)
    r=r.resize((int(tw),int(th)),Image.LANCZOS)
    W,H=r.size
    return r.transform((W,H),Image.AFFINE,(1,sx,-sx*H/2,0,1,0),Image.BICUBIC,fillcolor=fill)
r=prep(ratio[:,:,:3],'RGB',(255,255,255)); W,H=r.size
bwi=prep(ratio[:,:,3],'L',0)
rr=np.asarray(r).astype(float)/255
bw=np.asarray(bwi).astype(float)[:,:,None]/255; rr=rr**2.7

im=np.asarray(Image.open(BASE)).astype(float)
px,py=int(px),int(py)
reg=im[py:py+H,px:px+W]*rr
lv=reg.mean(2,keepdims=True)/150
bluec=np.array([120,165,215])*np.clip(lv,0.35,1.1)
im[py:py+H,px:px+W]=reg*(1-bw*0.85)+bluec*bw*0.85
out=Image.fromarray(im.clip(0,255).astype('uint8'))
out.save(OUT)
