extends SceneTree
## Turns tools/true3d/rig.py output (NAME.bin + NAME.json + NAME_atlas.png in a folder) into a skinned
## ArrayMesh resource the game loads: res://assets/model3d/NAME.res (atlas copied next to it as NAME_atlas.png,
## imported first). Bones ride in the mesh's metadata ("bones": [[name, parent, head xyz], ...]), heights in
## model units (feet at y 0, height 1). Run:
##   godot --headless --path . --script tools/true3d/build_mesh.gd -- SRC_DIR NAME [NAME ...]

func _init() -> void:
	var args: = OS.get_cmdline_user_args()
	var src: String = args[0]
	for i in range(1, args.size()):
		_build(src, args[i])
	quit()

func _build(src: String, name: String) -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [src, name]))
	var n: = int(meta["verts"])
	var nt: = int(meta["tris"])
	var f: = FileAccess.open("%s/%s.bin" % [src, name], FileAccess.READ)
	var pos: = _v3(f.get_buffer(n * 12).to_float32_array())
	var nor: = _v3(f.get_buffer(n * 12).to_float32_array())
	var uvf: = f.get_buffer(n * 8).to_float32_array()
	var uv: = PackedVector2Array()
	uv.resize(n)
	for i in n:
		uv[i] = Vector2(uvf[i * 2], uvf[i * 2 + 1])
	var bones: = f.get_buffer(n * 16).to_int32_array()
	var weights: = f.get_buffer(n * 16).to_float32_array()
	var idx: = f.get_buffer(nt * 12).to_int32_array()
	var arr: = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_BONES] = bones
	arr[Mesh.ARRAY_WEIGHTS] = weights
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh: = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat: = StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/model3d/%s_atlas.png" % name)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)
	mesh.set_meta("bones", meta["bones"])
	mesh.set_meta("cuts", meta["cuts"])
	var out: = "res://assets/model3d/%s.res" % name
	var err: = ResourceSaver.save(mesh, out, ResourceSaver.FLAG_COMPRESS)
	print("saved ", out, " verts ", n, " tris ", nt, " err ", err)

func _v3(a: PackedFloat32Array) -> PackedVector3Array:
	var o: = PackedVector3Array()
	o.resize(a.size() / 3)
	for i in o.size():
		o[i] = Vector3(a[i * 3], a[i * 3 + 1], a[i * 3 + 2])
	return o
