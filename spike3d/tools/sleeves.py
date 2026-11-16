"""Plain black sleeves on the hd3d Duff sheet: Duff's sleeve tattoos stop under the T-shirt, so the print the
AI painted on the sleeves is painted out (Duff, Nov 16: permanent rule).
Run with --check to only verify (exit 1 if any sleeve still shows print)."""
from PIL import Image
import numpy as np, cv2, sys
src,out=sys.argv[1],sys.argv[2]
im=np.asarray(Image.open(src).convert('RGBA')).copy()
# sleeve-print ellipses (cell coords: cx, cy, rx, ry) on the reference frame of each group
SLEEVES={0:[(185,256,18,20),(326,254,18,20)], 4:[(188,260,18,20),(326,262,18,20)],
         3:[(124,264,18,20),(264,244,18,20)], 7:[(124,264,18,20),(268,258,18,20)],
         8:[(210,292,26,22)], 12:[(286,298,26,22)], 11:[(134,296,22,20)], 15:[(272,296,22,20)]}
COPY={1:0,2:0,5:4,6:4,9:8,10:8,13:12,14:12}
cell=lambda f:((f%4)*512,(f//4)*512)
gray=lambda f: cv2.cvtColor(np.ascontiguousarray(im[cell(f)[1]:cell(f)[1]+512,cell(f)[0]:cell(f)[0]+512,:3]),cv2.COLOR_RGB2GRAY)
def shift(ref,f,cx,cy):
  tpl=gray(ref)[cy-50:cy+50,cx-50:cx+50]
  res=cv2.matchTemplate(gray(f),tpl,cv2.TM_CCOEFF_NORMED); _,_,_,loc=cv2.minMaxLoc(res)
  return loc[0]-(cx-50),loc[1]-(cy-50)
jobs=[]
for f in range(16):
  ref=COPY.get(f,f)
  for (cx,cy,rx,ry) in SLEEVES.get(ref,[]):
    dx,dy=(0,0) if ref==f else shift(ref,f,cx,cy)
    jobs.append((f,cx+dx,cy+dy,rx,ry))
mask=np.zeros(im.shape[:2],'uint8')
rgb=im[...,:3].astype(int); lum=rgb@[0.3,0.5,0.2]
for f,cx,cy,rx,ry in jobs:
  ox,oy=cell(f)
  e=np.zeros(im.shape[:2],'uint8'); cv2.ellipse(e,(ox+cx,oy+cy),(rx,ry),0,0,360,1,-1)
  R,B=rgb[...,0],rgb[...,2]
  printpx=(e>0)&(im[...,3]>0)&(lum>34)&(lum<190)&((R-B)>8)
  mask|=printpx.astype('uint8')
if '--check' in sys.argv:
  # print left on a sleeve = warm, mid-bright pixels inside the sleeve ellipses (plain black cloth has none)
  n=int((mask&((lum>60)).astype('uint8')).sum())
  print('sleeve print pixels:',n); sys.exit(1 if n>1500 else 0)  # raw AI sheet: ~14000; fixed: <1000 (edge pixels)
mask=cv2.dilate(mask,np.ones((3,3),'uint8'))&(im[...,3]>0)
bgr=np.ascontiguousarray(im[...,:3][...,::-1])
res=cv2.inpaint(bgr,mask*255,4,cv2.INPAINT_TELEA)[...,::-1]
# pull it to the shirt's black so it reads as cloth, not a smudge
res=np.minimum(res, (res.astype(int)*0.6+np.array([30,27,25])*0.4)).astype('uint8')
im[...,:3]=np.where(mask[...,None]>0,res,im[...,:3])
Image.fromarray(im).save(out)
print('jobs',len(jobs),'px',int(mask.sum()))
