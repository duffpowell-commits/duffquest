"""Neck fox for the hd3d Duff sheet: repaint the AI's neck blob as skin, then multiply Duff's real fox on.
# Run from the repo root: python3 tools/duff_hd3d/fox_sheet.py <sheet without fox> assets/art3d/duff_home_hd3d.png
# (Canva master: Drive ch_duff_home_hd3d_v1.png.png, imported with import_big_sheet.py --cell 512).
Front + right-facing frames get the fox; left-facing frames (his bare right side) get skin only."""
from PIL import Image, ImageDraw, ImageOps, ImageFilter
import numpy as np, cv2, sys
SRC, OUT = sys.argv[1], sys.argv[2]
sheet = np.asarray(Image.open(SRC).convert('RGBA')).astype(float)
# polygons in cell coords of the reference frame of each row; fox box (x, y, w, h, mirror)
REF = {
  0:  dict(poly=[(266,203),(290,205),(293,220),(290,236),(282,243),(268,244),(262,232),(263,214)], fox=(264,203,30,34,False)),
  8:  dict(poly=[(222,236),(240,236),(252,248),(256,262),(250,270),(232,269),(220,262),(219,248)], fox=(219,234,36,36,True)),
  12: dict(poly=[(250,244),(270,244),(282,252),(285,268),(270,276),(250,277),(244,262),(246,250)], fox=None),
}
ROWS = {0:[0,1,2,3], 8:[8,9,10,11], 12:[12,13,14,15]}
m = Image.open('docs/ref/duff/duff_fox_neck_tattoo.png').convert('RGBA')
ma = np.asarray(m).astype(float)
skin = ma[300:340,360:420,:3].reshape(-1,3).mean(0)
lum = np.clip((ma[...,:3]@[0.3,0.5,0.2])/(skin@[0.3,0.5,0.2]),0.12,1.0)
blue = np.clip(((ma[...,2]-ma[...,0])+5)/30,0,1)
al = ma[...,3]/255

def cell(f):
  r,c = divmod(f,4); return c*512, r*512

def head_shift(ref, f):
  """offset of frame f's head vs the ref frame (template match on the head/neck block)."""
  rx, ry = cell(ref); fx, fy = cell(f)
  gray = lambda x,y: cv2.cvtColor(np.ascontiguousarray(sheet[y:y+512,x:x+512,:3]).astype('uint8'), cv2.COLOR_RGB2GRAY)
  a, b = gray(rx,ry), gray(fx,fy)
  px = [p for p in REF[ref]['poly']]; cx = int(np.mean([p[0] for p in px])); cy = int(np.mean([p[1] for p in px]))
  tpl = a[cy-110:cy+30, cx-80:cx+80]
  res = cv2.matchTemplate(b, tpl, cv2.TM_CCOEFF_NORMED)
  _,score,_,loc = cv2.minMaxLoc(res)
  return loc[0]-(cx-80), loc[1]-(cy-110), score

for ref, frames in ROWS.items():
  spec = REF[ref]
  for f in frames:
    dx, dy, sc = (0,0,1.0) if f==ref else head_shift(ref, f)
    print(f, 'shift', dx, dy, 'match %.2f' % sc)
    ox, oy = cell(f)
    poly = [(x+dx, y+dy) for x,y in spec['poly']]
    xs=[p[0] for p in poly]; ys=[p[1] for p in poly]
    x0,y0,x1,y1 = min(xs)-3,min(ys)-3,max(xs)+4,max(ys)+4
    W,H = x1-x0, y1-y0
    mk = Image.new('L',(W,H),0); ImageDraw.Draw(mk).polygon([(x-x0,y-y0) for x,y in poly], fill=255)
    mk = np.asarray(mk.filter(ImageFilter.GaussianBlur(0.8))).astype(float)[...,None]/255
    reg = sheet[oy+y0:oy+y1, ox+x0:ox+x1]
    mk = mk*(reg[...,3:4]>0)
    # skin: neck under the jaw, shadow at the top, a touch lighter low down
    # inpaint the neck from the skin, beard and collar around it (keeps the painting's light)
    hard = (np.asarray(Image.fromarray((mk[...,0]*255).astype('uint8')))>40).astype('uint8')*255
    big = sheet[oy+y0-12:oy+y1+12, ox+x0-12:ox+x1+12,:3]
    hm = np.zeros(big.shape[:2],'uint8'); hm[12:12+H,12:12+W]=hard
    fill = cv2.inpaint(np.ascontiguousarray(big[...,::-1]).astype('uint8'), hm, 7, cv2.INPAINT_TELEA)[...,::-1].astype(float)
    fill = cv2.GaussianBlur(fill,(0,0),1.6)[12:12+H,12:12+W]
    # pull greys from the collar back to skin hue, same lightness
    lumf = fill@[0.3,0.5,0.2]
    hue = np.array([205,122,66.]); fill = fill*0.35 + (hue*(lumf/(hue@[0.3,0.5,0.2]))[...,None])*0.65
    # a little grain so it sits with the painted pixels
    fill += np.random.default_rng(f).normal(0,4,fill.shape)
    if spec['fox']:
      fx_, fy_, fw, fh, mir = spec['fox']
      L = Image.fromarray((lum*255).astype('uint8')); Bl = Image.fromarray((blue*255).astype('uint8')); Al = Image.fromarray((al*255).astype('uint8'))
      if mir: L,Bl,Al = ImageOps.mirror(L),ImageOps.mirror(Bl),ImageOps.mirror(Al)
      L,Bl,Al = [im.resize((fw,fh),Image.LANCZOS) for im in (L,Bl,Al)]
      l = np.asarray(L).astype(float)[...,None]/255; bw = np.asarray(Bl).astype(float)[...,None]/255; a2 = np.asarray(Al).astype(float)[...,None]/255
      l = l**2.2
      px_, py_ = fx_+dx-x0, fy_+dy-y0
      sub = fill[py_:py_+fh, px_:px_+fw]
      ink = sub*(l*a2+(1-a2))
      lv = ink.mean(2,keepdims=True)/150
      bluec = np.array([120,165,215])*np.clip(lv,0.4,1.1)
      bw = bw*a2
      fill[py_:py_+fh, px_:px_+fw] = ink*(1-bw*0.8)+bluec*bw*0.8
    reg[...,:3] = reg[...,:3]*(1-mk) + fill*mk
Image.fromarray(sheet.clip(0,255).astype('uint8')).save(OUT)
