extends Node3D
## Lightweight material batches: one MultiMesh per material and primitive type.
var batches: Dictionary = {}
var palette: Dictionary = {}
var rng := RandomNumberGenerator.new()
func _ready() -> void:
 rng.seed = 167
func material(key: String, c: Color, pattern := "plain", glow := false) -> StandardMaterial3D:
 if palette.has(key): return palette[key]
 var m := StandardMaterial3D.new()
 m.albedo_color = c
 m.roughness = .92
 if pattern != "plain":
  var image := Image.create(128,128,false,Image.FORMAT_RGB8)
  for y in 128:
   for x in 128:
    var n := rng.randf_range(.88,1.06) + .035*sin(x*.13+y*.28)
    if pattern == "brick" and (y%16 < 2 or (x+int(y/16)%2*16)%32 < 2): n *= .56
    if pattern == "siding" and y%16 < 2: n *= .65
    if pattern == "concrete" and (x%64 < 1 or y%64 < 1): n *= .7
    image.set_pixel(x,y,Color(n,n,n))
  image.generate_mipmaps()
  m.albedo_texture = ImageTexture.create_from_image(image)
  m.uv1_triplanar = true
  m.uv1_scale = Vector3(.55,.55,.55)
  # Reuse the approved painted porch kit where appropriate.
  var existing = {"brick":"brick", "house":"siding", "roof":"shingle", "bark":"cedar"}.get(key, "")
  if existing != "":
   var path = "res://models/kit/%s.jpg" % existing
   if ResourceLoader.exists(path):
    m.albedo_texture = load(path)
    m.uv1_scale = Vector3(1.7,1.7,1.7)
 if glow:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = .25
 palette[key] = m
 return m
func shape(kind: String, pos: Vector3, size: Vector3, mat: Material, yaw := 0.0, roll := 0.0) -> void:
 var key := str(mat.get_instance_id())+kind
 if not batches.has(key): batches[key] = [kind,mat,[]]
 var basis := Basis.from_euler(Vector3(0,yaw,roll)).scaled_local(size)
 batches[key][2].append(Transform3D(basis,pos))
func box(pos: Vector3, size: Vector3, mat: Material, yaw := 0.0, roll := 0.0) -> void:
 shape("box",pos,size,mat,yaw,roll)
func finish() -> void:
 for b in batches.values():
  var mesh: PrimitiveMesh
  if b[0] == "ball":
   var s := SphereMesh.new(); s.radial_segments=8; s.rings=4; s.radius=.5; s.height=1; mesh=s
  else:
   var cube := BoxMesh.new(); cube.size=Vector3.ONE; mesh=cube
  mesh.material=b[1]
  var mm := MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=mesh; mm.instance_count=b[2].size()
  for i in b[2].size(): mm.set_instance_transform(i,b[2][i])
  var instance := MultiMeshInstance3D.new(); instance.multimesh=mm; add_child(instance)
func tree(p: Vector3) -> void:
 var bark := material("bark",Color("745344"),"siding")
 var leaves := material("leaves",Color("687e42"))
 var gold := material("goldleaf",Color("a4a350"))
 box(p+Vector3(0,1.4,0),Vector3(.34,2.8,.34),bark)
 for i in 5:
  shape("ball",p+Vector3(cos(i*1.26)*.9,3.2+sin(i*2)*.5,sin(i*1.26)*.9),Vector3(2.3,2.1,2.3),gold if i%2==0 else leaves)
func building(p: Vector3, size: Vector2, kind: String, title: String) -> void:
 var house := kind=="house"
 var h := 5.6 if kind=="tower" else (3.2 if house or kind=="brick" else 2.7)
 var wall := material(kind,Color("c9b69b") if house else Color("a06c50") if kind=="brick" else Color("ded0aa") if kind=="diner" else Color("756d72"),"siding" if house or kind=="club" else "brick")
 var trim := material("cream",Color("e4c9a4"))
 var dark := material("roof",Color("494d49"),"siding")
 var glass := material("windows",Color("c98f57"),"plain",true)
 var front := p.z+size.y/2
 var accent := material("neon",Color("ee5e68"),"plain",true)
 var blue := material("diner_window",Color("709b9c"),"plain",true)
 box(p+Vector3(0,h/2,0),Vector3(size.x,h,size.y),wall)
 box(p+Vector3(0,h+.12,0),Vector3(size.x+.35,.24,size.y+.35),dark)
 if house:
  for side in [-1,1]:
   box(p+Vector3(side*size.x/4,h+.85,0),Vector3(size.x*.58,.18,size.y+.5),dark,0,-side*.4)
  box(Vector3(p.x,.16,front+.65),Vector3(size.x*.85,.32,1.3),trim)
  for side in [-1,1]: box(Vector3(p.x+side*size.x*.38,1.25,front+.95),Vector3(.16,2.3,.16),trim)
  box(Vector3(p.x,2.4,front+.65),Vector3(size.x*.86,.18,1.7),dark)
 box(Vector3(p.x,1,front+.04),Vector3(.85,2,.12),dark)
 for side in [-1,1]:
  var wx: float = p.x+side*size.x*.29
  box(Vector3(wx,1.65,front+.06),Vector3(size.x*.23,1.2,.12),trim)
  box(Vector3(wx,1.65,front+.13),Vector3(size.x*.2,1.0,.12),glass)
  box(Vector3(wx,1.65,front+.21),Vector3(.07,1.04,.08),dark)
 if kind == "diner":
  box(Vector3(p.x,2.3,front+.65),Vector3(size.x+.4,.18,1.5),trim)
  for i in range(4):
   var x: float=p.x+(i-1.5)*size.x*.2
   box(Vector3(x,1.38,front+.24),Vector3(size.x*.18,1.62,.08),blue)
   box(Vector3(x+size.x*.09,1.38,front+.3),Vector3(.08,1.65,.08),trim)
 if kind == "club":
  box(Vector3(p.x,2.2,front+.35),Vector3(size.x*.85,.06,.11),accent)
  box(Vector3(p.x-size.x*.43,1.55,front+.35),Vector3(.1,1.3,.1),accent)
 if kind == "tower":
  for level in range(2,5):
   for col in [-1,0,1]:
    box(Vector3(p.x+col*size.x*.28,level+.3,front+.12),Vector3(size.x*.18,.68,.12),glass)
 if kind == "brick":
  box(Vector3(p.x,h-.34,front+.13),Vector3(size.x+.1,.14,.18),trim)
  for side in [-1,1]:
   box(Vector3(p.x+side*size.x*.29,2.32,front+.2),Vector3(size.x*.25,.12,.21),trim)
 if not house:
  box(Vector3(p.x,2.55,front+.21),Vector3(size.x*.9,.55,.25),dark)
  var label := Label3D.new(); label.text=title; label.font_size=48; label.pixel_size=.012; label.outline_size=4; label.modulate=Color("ff7791") if kind=="club" else Color("ffcf90"); label.position=Vector3(p.x,2.55,front+.36); label.rotation.y=0; add_child(label)
