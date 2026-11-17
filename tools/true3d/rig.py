"""Hunyuan shape -> low-poly, 4-view projected texture atlas, bone weights. Writes OUT/<name>.bin + .json + _atlas.png
Usage: rig.py NAME SHAPE_GLB OUTDIR [faces]"""
import sys, json, numpy as np, trimesh, pymeshlab
from PIL import Image
from scipy.ndimage import distance_transform_edt, binary_erosion
name, shape, out = sys.argv[1], sys.argv[2], sys.argv[3]
FACES = int(sys.argv[4]) if len(sys.argv) > 4 else 7000
T = 512  # per-view atlas tile

m = trimesh.load(shape, force='mesh')
ms = pymeshlab.MeshSet(); ms.add_mesh(pymeshlab.Mesh(m.vertices, m.faces))
ms.meshing_decimation_quadric_edge_collapse(targetfacenum=FACES, preservenormal=True, preserveboundary=True, optimalplacement=True)
lm = ms.current_mesh()
m = trimesh.Trimesh(lm.vertex_matrix(), lm.face_matrix(), process=True)
# keep the biggest piece only (Hunyuan leaves floaters)
parts = m.split(only_watertight=False)
m = max(parts, key=lambda p: len(p.faces))
v = m.vertices.copy(); lo, hi = v.min(0), v.max(0)
# feet on y=0, centred, height 1
v[:, 1] -= lo[1]; h = hi[1] - lo[1]
v[:, 0] -= (lo[0] + hi[0]) / 2; v[:, 2] -= (lo[2] + hi[2]) / 2
v /= h
m.vertices = v
lo, hi = v.min(0), v.max(0)

def view(vname):
    im = Image.open(f'/tmp/h3d/in/{name}_{vname}.png').convert('RGBA')
    a = np.asarray(im).astype(np.float32)
    mask = a[:, :, 3] > 128
    ys, xs = np.where(mask)
    box = (xs.min(), xs.max(), ys.min(), ys.max())
    em = binary_erosion(mask, iterations=2)
    _, (iy, ix) = distance_transform_edt(~em, return_indices=True)
    rgb = a[:, :, :3][iy, ix]
    # crop the silhouette box (+ margin) into a T x T tile
    pad = 8
    x0, x1, y0, y1 = box[0] - pad, box[1] + pad, box[2] - pad, box[3] + pad
    tile = Image.fromarray(rgb.astype(np.uint8)).crop((x0, y0, x1, y1)).resize((T, T), Image.LANCZOS)
    # silhouette box in tile coords (0..1)
    W, H = x1 - x0, y1 - y0
    b = ((box[0] - x0) / W, (box[1] - x0) / W, (box[2] - y0) / H, (box[3] - y0) / H)
    return tile, b, mask[box[2]:box[3] + 1, box[0]:box[1] + 1]

V = ['front', 'back', 'left', 'right']   # left = row 3 (faces screen-left), right = row 2 (faces screen-right)
tiles = {}
for k in V:
    tiles[k] = view(k)
atlas = Image.new('RGB', (2 * T, 2 * T))
for i, k in enumerate(V):
    atlas.paste(tiles[k][0], ((i % 2) * T, (i // 2) * T))

def uv_for(k, p):
    """model point(s) -> atlas uv for view k (orthographic, silhouette box = model bbox)"""
    x01 = (p[:, 0] - lo[0]) / (hi[0] - lo[0]); y01 = p[:, 1] / hi[1]; z01 = (p[:, 2] - lo[2]) / (hi[2] - lo[2])
    if k == 'front': s = x01
    elif k == 'back': s = 1 - x01
    elif k == 'right': s = z01       # faces screen-right: we see his +x side, his front on the image right
    else: s = 1 - z01                # faces screen-left: -x side
    t = 1 - y01
    b = tiles[k][1]
    u = b[0] + s * (b[1] - b[0]); vv = b[2] + t * (b[3] - b[2])
    i = V.index(k)
    return np.stack([((i % 2) + u) / 2, ((i // 2) + vv) / 2], 1)

fn = m.face_normals
dirs = {'front': np.array([0, 0, 1.]), 'back': np.array([0, 0, -1.]), 'right': np.array([1., 0, 0]), 'left': np.array([-1., 0, 0])}
SIDE_BIAS = 0.75  # sides are only picked where they clearly win (front/back art is the sharper read)
score = np.stack([fn @ dirs[k] * (SIDE_BIAS if k in ('left', 'right') else 1.0) for k in V], 1)
pick = score.argmax(1)

# --- bones from the front silhouette ---
fm = tiles['front'][2]          # mask cropped to silhouette, row 0 = top
Hm, Wm = fm.shape
def runs(row):
    r = []; on = False
    for x, b in enumerate(row):
        if b and not on: s = x; on = True
        if not b and on: r.append((s, x - 1)); on = False
    if on: r.append((s, len(row) - 1))
    return [q for q in r if q[1] - q[0] > 2]
y01_of = lambda row: 1 - row / (Hm - 1)
cx = Wm / 2
crotch = 0.2
for row in range(Hm - 1, int(Hm * 0.4), -1):   # from the feet up: last row with a gap in the middle
    rs = runs(fm[row])
    if len(rs) >= 2 and not fm[row, int(cx)]:
        crotch = y01_of(row)
three = [row for row in range(int(Hm * 0.25), int(Hm * 0.85)) if len(runs(fm[row])) >= 3]
if three:
    armpit = y01_of(min(three)); hand = y01_of(max(three))
    halfs = []
    for row in three:
        rs = runs(fm[row]); mid = min(rs, key=lambda q: abs((q[0] + q[1]) / 2 - cx))
        halfs.append(max(cx - mid[0], mid[1] - cx))
    torso_half = float(np.median(halfs)) / Wm   # in x01 units
else:
    armpit, hand, torso_half = 0.5, crotch + 0.05, 0.3
widths = [(row, fm[row].sum()) for row in range(int(Hm * 0.08), int(Hm * 0.6))]
neck_row = min([w for w in widths if y01_of(w[0]) > armpit], key=lambda w: w[1], default=(int(Hm * 0.4), 0))[0]
neck = y01_of(neck_row)
shoulder = armpit + 0.35 * (neck - armpit)
print('crotch %.3f hand %.3f armpit %.3f shoulder %.3f neck %.3f torso_half %.3f' % (crotch, hand, armpit, shoulder, neck, torso_half))

W_ = hi[0] - lo[0]
def xmodel(x01): return lo[0] + x01 * W_
sh_x = (torso_half * 0.85) * W_
bones = [  # name, parent, head position (model units)
    ['root', -1, [0, crotch * hi[1], 0]],
    ['spine', 0, [0, armpit * hi[1], 0]],
    ['head', 1, [0, neck * hi[1], 0]],
    ['arm_l', 1, [sh_x, shoulder * hi[1], 0]],
    ['arm_r', 1, [-sh_x, shoulder * hi[1], 0]],
    ['leg_l', 0, [W_ * 0.12, crotch * hi[1], 0]],
    ['leg_r', 0, [-W_ * 0.12, crotch * hi[1], 0]],
]
def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)
P = m.vertices; y = P[:, 1] / hi[1]; xu = (P[:, 0] - lo[0]) / W_ - 0.5
wt = np.zeros((len(P), 7))
head = ss(neck - 0.015, neck + 0.02, y)
leg = 1 - ss(crotch - 0.03, crotch + 0.03, y)
armside = ss(torso_half * 0.95, torso_half * 1.15, np.abs(xu)) * ss(hand - 0.06, hand - 0.02, y) * (1 - ss(shoulder, neck, y))
upper = ss(crotch, armpit, y)
body = (1 - head) * (1 - leg)
wt[:, 2] = head
wt[:, 5] = leg * (xu > 0); wt[:, 6] = leg * (xu <= 0)
arm = body * armside
wt[:, 3] = arm * (xu > 0); wt[:, 4] = arm * (xu <= 0)
rest = body * (1 - armside)
wt[:, 1] = rest * upper; wt[:, 0] = rest * (1 - upper)
wt /= wt.sum(1, keepdims=True) + 1e-9
idx = np.argsort(-wt, 1)[:, :4]; ww = np.take_along_axis(wt, idx, 1); ww /= ww.sum(1, keepdims=True)

# vertices shared per (mesh vertex, picked view): one uv each, smooth normals
F = m.faces; vn = m.vertex_normals
key = F * 4 + pick[:, None]
uniq, inv = np.unique(key.reshape(-1), return_inverse=True)
vid = uniq // 4; vview = uniq % 4
pos = P[vid]; nor = vn[vid]
uv = np.zeros((len(uniq), 2))
for i, k in enumerate(V):
    sel = vview == i
    if sel.any(): uv[sel] = uv_for(k, pos[sel])
bi = idx[vid]; bw = ww[vid]
tri = inv.reshape(-1, 3)[:, ::-1].reshape(-1)   # Godot: clockwise front faces
n = len(pos)
with open(f'{out}/{name}.bin', 'wb') as f:
    for arr in (pos.astype('<f4'), nor.astype('<f4'), uv.astype('<f4'), bi.astype('<i4'), bw.astype('<f4'), tri.astype('<i4')):
        f.write(arr.tobytes())
atlas.save(f'{out}/{name}_atlas.png')
json.dump({'verts': n, 'tris': len(F), 'bones': bones, 'width': float(W_), 'depth': float(hi[2] - lo[2]),
           'cuts': {'crotch': crotch, 'hand': hand, 'armpit': armpit, 'shoulder': shoulder, 'neck': neck}}, open(f'{out}/{name}.json', 'w'))
print('ok', name, len(F), 'faces', n, 'verts', 'picks', np.bincount(pick, minlength=4))
