import os, sys, time, torch
from PIL import Image
from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
torch.set_num_threads(4)
names = sys.argv[1].split(','); views = sys.argv[2].split(',') if len(sys.argv) > 2 else ['front', 'back']
t = time.time()
pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2mv', subfolder='hunyuan3d-dit-v2-mv-turbo', variant='fp16', device='cpu', dtype=torch.float32)
pipe.enable_flashvdm()
pipe.to('cpu', torch.float32)
for m in pipe.vae.modules(): m.float()
print('loaded', time.time() - t, flush=True)
for name in names:
    imgs = {v: Image.open(f'/tmp/h3d/in/{name}_{v}.png') for v in views}
    mesh = pipe(image=imgs, num_inference_steps=10, octree_resolution=256, num_chunks=20000, generator=torch.manual_seed(1234), output_type='trimesh')[0]
    tag = '' if len(views) == 2 else '_' + str(len(views)) + 'v'
    mesh.export(f'/tmp/h3d/out/{name}{tag}_shape.glb')
    print('gen', name, time.time() - t, len(mesh.vertices), len(mesh.faces), flush=True)
