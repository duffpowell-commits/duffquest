extends RefCounted

const GRAIN_SHADER = preload("porch_surface.gdshader")

# Build each prop into one indexed, vertex-colored surface. Collision belongs to the scene.
class Sculpture:
	var surface := SurfaceTool.new()
	var vertex_count := 0

	func _init() -> void:
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	func add(mesh: PrimitiveMesh, at: Vector3, color: Color, angles := Vector3.ZERO) -> void:
		var arrays := mesh.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var pose := Basis.from_euler(angles)
		var start := vertex_count
		for i in vertices.size():
			surface.set_color(color.srgb_to_linear().lerp(color, .57))
			surface.set_normal(pose * normals[i])
			surface.add_vertex(at + pose * vertices[i])
		for index in arrays[Mesh.ARRAY_INDEX]:
			surface.add_index(start + index)
		vertex_count += vertices.size()

	func box(at: Vector3, size: Vector3, color: Color, angles := Vector3.ZERO) -> void:
		var mesh := BoxMesh.new()
		mesh.size = size
		add(mesh, at, color, angles)

	func form(at: Vector3, size: Vector3, color: Color, angles := Vector3.ZERO, detail := 12) -> void:
		var mesh := SphereMesh.new()
		mesh.radial_segments = detail
		mesh.rings = 6
		var arrays := mesh.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var pose := Basis.from_euler(angles)
		var start := vertex_count
		for i in vertices.size():
			surface.set_color(color.srgb_to_linear().lerp(color, .57))
			surface.set_normal(pose * (normals[i] / size).normalized())
			surface.add_vertex(at + pose * (vertices[i] * size))
		for index in arrays[Mesh.ARRAY_INDEX]:
			surface.add_index(start + index)
		vertex_count += vertices.size()

	func blade(at: Vector3, spread: Vector3, height: float, color: Color) -> void:
		var tint := color.srgb_to_linear().lerp(color, .57)
		var right := Vector3(.025, 0, .008)
		for point in [at - right, at + Vector3.UP * height + spread, at + right]:
			surface.set_color(tint)
			surface.set_normal(Vector3(0, .5, 1).normalized())
			surface.add_vertex(point)
		for offset in [0, 1, 2, 0, 2, 1]:
			surface.add_index(vertex_count + offset)
		vertex_count += 3

	func band(at: Vector3, radius: float, color: Color, angles := Vector3.ZERO, thickness := .004) -> void:
		var mesh := TorusMesh.new()
		mesh.inner_radius = radius - thickness
		mesh.outer_radius = radius + thickness
		mesh.rings = 12
		mesh.ring_segments = 6
		add(mesh, at, color, angles)

	func finish(parent: Node3D, label: String, at := Vector3.ZERO) -> MeshInstance3D:
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = .89
		var visual := MeshInstance3D.new()
		visual.name = label
		visual.mesh = surface.commit()
		visual.material_override = material
		parent.add_child(visual)
		visual.position = at
		return visual

static func surface_detail(visual: MeshInstance3D, grain: float, scale: Vector3, lawn := false) -> void:
	var material := ShaderMaterial.new()
	material.shader = GRAIN_SHADER
	material.set_shader_parameter("grain", grain)
	material.set_shader_parameter("grain_scale", scale)
	material.set_shader_parameter("lawn", lawn)
	visual.material_override = material

const SKIN := Color("#d38a59")
const BLACK := Color("#25242c")
const GOLD := Color("#e3ab55")
const TRIM := Color("#e6c393")

static func person(parent: Node3D, hood: bool) -> Node3D:
	var model := Node3D.new()
	model.name = "PorchPirate" if hood else "Duff"
	parent.add_child(model)
	var shirt := Color("#3e394b") if hood else BLACK
	var hair := Color("#a05229") if hood else Color("#935533")
	var trousers := Color("#343d59") if hood else Color("#39343a")
	var body := Sculpture.new()
	body.form(Vector3(0, .77, .015), Vector3(.56, .58, .36), shirt)
	body.form(Vector3(0, .63, .02), Vector3(.48, .25, .34), shirt.darkened(.12))
	body.form(Vector3(0, 1.04, -.02), Vector3(.23, .22, .22), SKIN)
	if hood:
		body.form(Vector3(0, 1.27, .035), Vector3(.65, .66, .53), shirt, Vector3(-.13, 0, 0), 18)
		body.form(Vector3(0, 1.26, -.19), Vector3(.49, .49, .095), shirt.darkened(.38))
	body.form(Vector3(0, 1.25, -.13 if hood else -.015), Vector3(.43 if hood else .39, .43 if hood else .46, .37), SKIN, Vector3.ZERO, 16)
	var face_z := -.295 if hood else -.18
	body.form(Vector3(0, 1.235, face_z - .027), Vector3(.106, .092, .09), SKIN.lightened(.08))
	body.form(Vector3(0, 1.151, face_z + .018), Vector3(.12, .017, .027), SKIN.darkened(.55))
	for side in [-1.0, 1.0]:
		body.form(Vector3(.105 * side, 1.32, face_z + .014), Vector3(.15, .037, .06), hair.darkened(.49), Vector3(0, 0, side * .18))
		if hood:
			body.form(Vector3(side * .106, 1.285, face_z - .005), Vector3(.22, .106, .065), BLACK)
			body.form(Vector3(side * .106, 1.29, face_z - .035), Vector3(.17, .075, .016), Color("#171720"))
			body.form(Vector3(side * .11, 1.29, -.22), Vector3(.25, .027, .025), BLACK)
			body.form(Vector3(side * .103, .935, -.167), Vector3(.018, .16, .02), TRIM)
		else:
			body.form(Vector3(.097 * side, 1.285, face_z + .009), Vector3(.105, .041, .043), Color("#fff1cd"))
			body.form(Vector3(.097 * side, 1.285, face_z - .012), Vector3(.039, .041, .023), Color("#446969"))
			body.form(Vector3(.195 * side, 1.256, 0), Vector3(.078, .126, .10), SKIN)
			body.form(Vector3(.228 * side, 1.218, -.01), Vector3(.024, .076, .076), BLACK)
			body.band(Vector3(.242 * side, 1.218, -.01), .035, GOLD, Vector3(0, 0, PI / 2.0))
			for hoop in 4:
				body.band(Vector3(.226 * side, 1.254 + hoop * .018, -.035 + hoop * .013), .015, GOLD if hoop % 2 == 0 else BLACK, Vector3(PI / 2.0, 0, 0), .003)
	for lock in 7:
		var progress := float(lock) / 6.0
		var x := lerpf(-.15, .19 if hood else -.30, progress)
		body.form(Vector3(x, 1.437 - progress * .059, -.23 if hood else -.13), Vector3(.12, .23, .12), hair.lightened(.04 * (lock % 3)), Vector3(-.35, 0, -.65 if hood else -1.05))
	if not hood:
		for side in [-1.0, 1.0]:
			for lock in 3:
				body.form(Vector3(side * (.13 + lock * .022), 1.26 - lock * .032, .121), Vector3(.13, .40, .19), hair.darkened(.05 * lock), Vector3(.29, 0, -.37))
		# Duff faces -Z, so his anatomical left is scene -X.
		animal_ink(body, Vector3(-.119, 1.054, -.038), Color("#92503d"), false, PI / 2.0)
	if hood:
		body.form(Vector3(0, .651, -.148), Vector3(.42, .187, .113), shirt.darkened(.16))
		for side in [-1.0, 1.0]:
			body.form(Vector3(side * .119, .674, -.195), Vector3(.034, .12, .018), shirt.lightened(.13), Vector3(0, 0, side * .45), 8)
	surface_detail(body.finish(model, "TorsoAndHead"), .12, Vector3(88, 123, 92))
	for side in [-1.0, 1.0]:
		var tag := "Left" if side < 0 else "Right"
		var leg := Sculpture.new()
		leg.form(Vector3(0, -.13, -.017), Vector3(.25, .34, .28), trousers, Vector3(.28 if hood else .11, 0, 0))
		leg.form(Vector3(side * .023, -.33, .026), Vector3(.215, .31, .22), trousers.darkened(.08), Vector3(-.21, 0, 0))
		leg.form(Vector3(side * .026, -.474, -.044), Vector3(.26, .11, .345), TRIM.darkened(.18))
		leg.form(Vector3(side * .026, -.421, -.048), Vector3(.248, .15, .33), BLACK if hood else Color("#77332f"))
		for lace in 3:
			leg.form(Vector3(side * .026, -.354 + lace * .009, -.135 + lace * .034), Vector3(.126, .014, .017), TRIM, Vector3.ZERO, 8)
		for fold in 3:
			leg.form(Vector3(side * .02, -.20 - fold * .064, -.113 + fold * .016), Vector3(.184, .042, .053), trousers.lightened(.055), Vector3(0, 0, side * .22), 8)
		surface_detail(leg.finish(model, tag + "Leg", Vector3(side * .146, .53, .008)), .17, Vector3(91, 137, 91))
		var arm := Sculpture.new()
		var gripping: bool = hood and side < 0
		arm.form(Vector3(side * .037, -.064, -.025), Vector3(.22, .24, .225), shirt, Vector3(0, 0, side * .25))
		arm.form(Vector3(side * .058, -.204 if not gripping else -.151, -.072 if not gripping else -.167), Vector3(.16, .29, .17), shirt if hood else SKIN, Vector3(-.24 if not gripping else -1.02, 0, side * .13))
		arm.form(Vector3(side * .059 if not gripping else side * -.044, -.35 if not gripping else -.213, -.115 if not gripping else -.35), Vector3(.134, .162, .118), SKIN)
		if gripping:
			for digit in 4:
				arm.form(Vector3(.111, -.163 - digit * .026, -.406 + digit * .006), Vector3(.143, .031, .045), SKIN.lightened(.037), Vector3(0, -.28, -.18), 8)
		if not hood and side > 0:
			animal_ink(arm, Vector3(.053, -.219, -.152), Color("#35434c"), true)
		arm.finish(model, tag + "Arm", Vector3(side * .27, .925, 0))
	return model

static func animal_ink(mesh: Sculpture, at: Vector3, ink: Color, wolf: bool, yaw := 0.0) -> void:
	var pose := Basis(Vector3.UP, yaw)
	mesh.form(at, Vector3(.09, .108, .018), ink, Vector3(0, yaw, 0), 8)
	for side in [-1.0, 1.0]:
		mesh.form(at + pose * Vector3(.033 * side, .058, .007), Vector3(.031, .064, .018), ink, Vector3(0, yaw, side * -.43), 6)
	mesh.form(at + pose * Vector3(0, -.043, -.01), Vector3(.043, .049, .018), ink.lightened(.27), Vector3(0, yaw, 0), 8)
	var eyes := [Vector2(-.020, .012), Vector2(.020, .012)]
	if wolf:
		eyes.append_array([Vector2(0, .04), Vector2(-.027, .033), Vector2(.027, .033), Vector2(-.022, -.009), Vector2(.022, -.009)])
	for eye in eyes:
		mesh.form(at + pose * Vector3(eye.x, eye.y, -.013), Vector3(.012, .008, .008), GOLD, Vector3(0, yaw, 0), 6)

static func parcel(parent: Node3D, at: Vector3) -> Node3D:
	var mesh := Sculpture.new()
	mesh.box(Vector3.ZERO, Vector3(.34, .36, .25), Color("#bc7c42"))
	mesh.box(Vector3(0, .182, 0), Vector3(.089, .005, .254), TRIM)
	mesh.box(Vector3(0, .137, -.127), Vector3(.089, .088, .005), TRIM)
	mesh.box(Vector3(0, .137, .127), Vector3(.089, .088, .005), TRIM.darkened(.12))
	mesh.box(Vector3(.086, .034, -.128), Vector3(.086, .07, .004), Color("#e6d7ae"))
	return mesh.finish(parent, "Parcel", at)

# --- Meshy set dressing (Nov 24): props made in the same render style as the characters. ---
# Each GLB is normalised (largest side ~1.9) and centred, so place() fits it to a target size.
# Collision stays the simple boxes in porch.gd.

## Fit a prop so its bounding box becomes `size` (axes left at 0 follow the largest given scale),
## with its base on y=at.y and its centre at at.x/at.z.
static func place(parent: Node3D, file: String, at: Vector3, size: Vector3, yaw := 0.0) -> Node3D:
	var prop: Node3D = (load("res://models/set/%s.glb" % file) as PackedScene).instantiate()
	prop.name = file.capitalize()
	prop.set_meta("set_prop", file)
	parent.add_child(prop, true)
	var box := AABB()
	var first := true
	for mesh in prop.find_children("*", "MeshInstance3D", true, false):
		var visual := mesh as MeshInstance3D
		var bounds: AABB = visual.transform * visual.get_aabb()
		box = bounds if first else box.merge(bounds)
		first = false
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var turned := box.size if is_zero_approx(fmod(yaw, PI)) else Vector3(box.size.z, box.size.y, box.size.x)
	var fit := Vector3(size.x / turned.x if size.x > 0 else 0.0, size.y / turned.y if size.y > 0 else 0.0,
		size.z / turned.z if size.z > 0 else 0.0)
	var largest := maxf(fit.x, maxf(fit.y, fit.z))
	for axis in 3:
		if fit[axis] == 0.0:
			fit[axis] = largest
	if not is_zero_approx(fmod(yaw, PI)):
		fit = Vector3(fit.z, fit.y, fit.x)
	prop.scale = fit
	prop.rotation.y = yaw
	var centre := box.get_center() * fit
	prop.position = at - Basis(Vector3.UP, yaw) * Vector3(centre.x, 0, centre.z) - Vector3(0, box.position.y * fit.y, 0)
	return prop

## World z of a placed prop's front-most point.
static func _front(prop: Node3D) -> float:
	var front := -INF
	for mesh in prop.find_children("*", "MeshInstance3D", true, false):
		var visual := mesh as MeshInstance3D
		var local := visual.get_aabb()
		for i in 8:
			front = maxf(front, (prop.transform * visual.transform * local.get_endpoint(i)).z)
	return front

static func textured(visual: MeshInstance3D, file: String, tiles_per_metre: float, tint := Color.WHITE) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://models/set/%s.jpg" % file)
	material.albedo_color = tint
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * tiles_per_metre
	material.roughness = .95
	visual.material_override = material

static func meshy_set(parent: Node3D, planter_at: Vector3, planter_size: Vector3) -> void:
	# House: front wall + stoop where the old frontage stood; the roof runs back out of the way.
	var house := place(parent, "house", Vector3(0, 0, -4.6), Vector3(10.4, 0, 0))
	house.scale.y *= .78  # a little squat so the door and windows stay on screen under the high camera
	house.position.y *= .78  # the squash pivots on the origin; keep the base on the ground
	house.position.z += -2.3 - _front(house)  # stoop's front edge on the old step line
	for x in [-6.9, 6.9]:
		for i in 5:
			place(parent, "fence", Vector3(x, 0, -4.4 + i * 2.2), Vector3(0, 1.4, 2.24), PI / 2)
	for side in [-1.0, 1.0]:
		place(parent, "tree", Vector3(side * 6.0, 0, -4.2), Vector3(0, 4.6, 0), side * .6)
	for x in [-4.6, -2.3, 2.3, 4.6]:
		place(parent, "bush", Vector3(x, 0, -2.95), Vector3(0, .8, 0), x)
	place(parent, "planter", planter_at, planter_size)
	place(parent, "mailbox", Vector3(6.1, 0, 2.45), Vector3(0, 1.25, 0), -PI / 2)
	ground(parent)


# Lawn, sidewalk and street: shared by the Meshy set and our own kit (porch_kit.gd).
static func ground(parent: Node3D) -> void:
	var lawn := Sculpture.new()
	lawn.box(Vector3(0, -.146, -.5), Vector3(22, .28, 12), Color.WHITE)
	textured(lawn.finish(parent, "Lawn"), "grass", .3, Color("#b8c4a0"))
	var walk := Sculpture.new()
	for i in 12:
		var x := -7.25 + i * 1.32
		walk.box(Vector3(x, .012, 2.91), Vector3(1.29, .043, 1.45), Color.WHITE)
		walk.box(Vector3(x, .029, 3.672), Vector3(1.304, .078, .16), Color.WHITE)
	textured(walk.finish(parent, "Sidewalk"), "sidewalk", .55, Color("#cdbfb4"))
	var street := Sculpture.new()
	street.box(Vector3(0, -.055, 5.43), Vector3(20.0, .11, 3.69), Color.WHITE)
	textured(street.finish(parent, "Street"), "sidewalk", .35, Color("#55505a"))
