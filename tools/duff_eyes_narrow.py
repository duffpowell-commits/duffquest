# Usage: python3 tools/duff_eyes_narrow.py SRC.png OUT.png [cut]  (run once per Duff 2x sheet; not twice)
# Narrow Duff's eyes: squash each painted eye vertically (keeps the painted look), refill the gap with
# the skin row above, and drop the inner half of the brow a pixel. Reads less chibi, more scowl.
import sys, numpy as np
from PIL import Image
C=128
def skin(c):
    r,g,b,al=[c[...,i].astype(int) for i in range(4)]
    return (al>200)&(r>170)&(g>110)&(b>70)&(r>g+15)&(g>b+10)&(r-b<150)
def eye_mask(c):
    r,g,b,a=[c[...,i].astype(int) for i in range(4)]
    mx=np.maximum(np.maximum(r,g),b); mn=np.minimum(np.minimum(r,g),b)
    return (a>200)&(r>185)&(g>185)&(b>175)&(mx-mn<50), (a>200)&(b>r+15)&(b>90)
def label(m):
    lab=np.zeros(m.shape,int); n=0; H,W=m.shape
    for y in range(H):
        for x in range(W):
            if m[y,x] and not lab[y,x]:
                n+=1; st=[(y,x)]; lab[y,x]=n
                while st:
                    cy,cx=st.pop()
                    for dy in (-1,0,1):
                        for dx in (-1,0,1):
                            yy,xx=cy+dy,cx+dx
                            if 0<=yy<H and 0<=xx<W and m[yy,xx] and not lab[yy,xx]:
                                lab[yy,xx]=n; st.append((yy,xx))
    return lab,n
def squash(patch, newh):
    h,w,_=patch.shape
    out=np.zeros((newh,w,4),patch.dtype)
    for j in range(newh):
        # area-ish: blend the source rows that map here, but keep dark lash rows dark
        s0=j*h/newh; s1=(j+1)*h/newh
        rows=[r for r in range(int(s0),int(np.ceil(s1)))]
        blk=patch[rows].astype(int)
        lum=blk[...,:3].sum(-1)
        # pick per column the darkest source row if any is very dark (keeps outlines), else average
        dark=lum.min(0)<200
        avg=blk.mean(0)
        mn=blk[lum.argmin(0),np.arange(w)]
        out[j]=np.where(dark[:,None],mn,avg).astype(patch.dtype)
    return out
def do_cell(c, dy, face, cut=2):
    al=np.where(c[...,3].max(1)>0)[0]
    if not len(al): return 0
    top=al.min(); ey=top+dy
    band=skin(c[ey-3:ey+4]); xs=np.where(band.any(0))[0]
    if not len(xs): return 0
    x0,x1=max(0,xs.min()-1),min(C,xs.max()+2); y0,y1=ey-7,ey+6
    sub=c[y0:y1,x0:x1]
    scl,iris=eye_mask(sub); lab,n=label(scl|iris)
    eyes=[]
    for i in range(1,n+1):
        m=lab==i; ys,xx=np.where(m)
        if len(ys)<4 or not iris[m].any(): continue
        eyes.append((ys.min(),ys.max(),xx.min(),xx.max()))
    fcx=sub.shape[1]/2
    for ty,by,ex0,ex1 in eyes:
        t0=max(1,ty-1)                       # include the upper lash line
        b0=min(sub.shape[0]-1,by+1)          # and the lower lid
        xa,xb=max(0,ex0-1),min(sub.shape[1],ex1+2)
        patch=sub[t0:b0+1,xa:xb].copy()
        h=patch.shape[0]
        if h-cut<3: continue
        new=squash(patch,h-cut)
        # top 'cut' rows become lid skin: copy the row above the eye, a touch darker (lid crease)
        ring=sub[max(0,t0-4):t0, xa:xb]
        sm=skin(ring)
        skc=np.median(ring[sm][:,:3],0) if sm.any() else np.array([243,182,104])
        for k in range(cut):
            shade=0.9 if k==cut-1 else 0.97       # crease darkens toward the lash line
            for i,x in enumerate(range(xa,xb)):
                if patch[k,i,3]==0: continue
                sub[t0+k,x,:3]=(skc*shade).astype(sub.dtype); sub[t0+k,x,3]=255
        sub[t0+cut:b0+1,xa:xb]=np.where((patch[cut:,:,3]>0)[...,None],new,sub[t0+cut:b0+1,xa:xb])
        # brow: drop its inner half one pixel
        cx=(ex0+ex1)/2
        inner_right=(cx<fcx) if face=='front' else (face=='right')
        for x in range(xa,xb):
            if inner_right != (x>cx): continue
            for y in range(t0-1,max(-1,t0-8),-1):
                p=sub[y,x].astype(int)
                if p[3]>200 and p[0]<90 and p[1]<70:
                    if y+1<t0 and skin(sub[y+1:y+2,x:x+1])[0,0]: sub[y+1,x,:3]=p[:3]
                    break
    return len(eyes)
def process(path,out,cut=2):
    a=np.array(Image.open(path).convert('RGBA')); tot=0
    for row,dy in ((0,36),(2,28),(3,28)):
        for col in range(4):
            tot+=do_cell(a[row*C:(row+1)*C,col*C:(col+1)*C],dy,{0:'front',2:'right',3:'left'}[row],cut)
    Image.fromarray(a).save(out); return tot
if __name__=='__main__': print(process(sys.argv[1],sys.argv[2],int(sys.argv[3]) if len(sys.argv)>3 else 2))
