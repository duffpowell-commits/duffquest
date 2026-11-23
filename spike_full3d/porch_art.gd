extends RefCounted

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


const SKIN := Color("#d38a59")
const BLACK := Color("#25242c")
const GOLD := Color("#e3ab55")
const WOOD := Color("#a77953")
const TRIM := Color("#e6c393")
const CONCRETE := Color("#ae9580")
const LEAF := Color("#74803e")

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
	body.finish(model, "TorsoAndHead")
	for side in [-1.0, 1.0]:
		var tag := "Left" if side < 0 else "Right"
		var leg := Sculpture.new()
		leg.form(Vector3(0, -.13, -.017), Vector3(.25, .34, .28), trousers, Vector3(.28 if hood else .11, 0, 0))
		leg.form(Vector3(side * .023, -.33, .026), Vector3(.215, .31, .22), trousers.darkened(.08), Vector3(-.21, 0, 0))
		leg.form(Vector3(side * .026, -.474, -.044), Vector3(.26, .11, .345), TRIM.darkened(.18))
		leg.form(Vector3(side * .026, -.421, -.048), Vector3(.248, .15, .33), BLACK if hood else Color("#77332f"))
		for lace in 3:
			leg.form(Vector3(side * .026, -.354 + lace * .009, -.135 + lace * .034), Vector3(.126, .014, .017), TRIM, Vector3.ZERO, 8)
		leg.finish(model, tag + "Leg", Vector3(side * .146, .53, .008))
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


static func planter(parent: Node3D, at: Vector3, width: float, depth: float) -> void:
	var mesh := Sculpture.new()
	for side in [-1.0, 1.0]:
		for row in 4:
			var y := .115 + row * .112
			var board := WOOD.lightened(row * .055)
			mesh.box(Vector3(0, y, side * (depth / 2 - .06)), Vector3(width - .065, .104, .08), board)
			mesh.box(Vector3(side * (width / 2 - .055), y, 0), Vector3(.08, .104, depth - .065), board.darkened(.1))
		for end in [-1.0, 1.0]:
			mesh.box(Vector3(side * (width / 2 - .05), .289, end * (depth / 2 - .05)), Vector3(.10, .578, .10), WOOD.darkened(.18))
		mesh.box(Vector3(0, .567, side * (depth / 2 - .06)), Vector3(width, .106, .12), TRIM.darkened(.17))
		mesh.box(Vector3(side * (width / 2 - .06), .567, 0), Vector3(.12, .106, depth - .24), TRIM.darkened(.13))
	mesh.box(Vector3(0, .515, 0), Vector3(width - .17, .06, depth - .16), Color("#503b2c"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 186
	for i in 30:
		var angle := i * 2.4
		var spread := rng.randf_range(.1, .43)
		mesh.form(Vector3(cos(angle) * spread, .66 + rng.randf_range(-.08, .07), sin(angle) * spread * .65), Vector3(.13, .095, .27), LEAF.lightened(rng.randf_range(-.15, .18)), Vector3(-.42, -angle, .14), 8)
	for i in 5:
		var angle := i * TAU / 5.0
		var bloom := Vector3(cos(angle) * .28, .81 + .04 * (i % 2), sin(angle) * .16)
		for petal in 9:
			var orbit := petal * 2.4
			mesh.form(bloom + Vector3(cos(orbit) * .056, .026 * (petal % 3), sin(orbit) * .052), Vector3(.083, .076, .081), Color("#c07669").lightened(.055 * (petal % 3)), Vector3.ZERO, 7)
	mesh.finish(parent, "FlowerPlanter", at)


static func frontage(parent: Node3D) -> void:
	var mesh := Sculpture.new()
	var brick := Color("#a15643")
	mesh.box(Vector3(0, 1.4, -4.6), Vector3(10.6, 2.8, 2.4), brick.darkened(.27))
	for row in 16:
		var y := .085 + row * .172
		for column in 29:
			var x := -5.14 + column * .363 + (row % 2) * .09
			if y > .89 and x > .8:
				continue
			var tint := 1.0 - float((column * 19 + row * 7) % 13) / 86.0
			mesh.box(Vector3(x, y, -3.385), Vector3(.35, .156, .035), brick * Color(tint, tint, tint))
	for row in 11:
		mesh.box(Vector3(3.07, .963 + row * .172, -3.374), Vector3(4.51, .163, .064), TRIM.darkened(.19 + .032 * (row % 3)))
	var roof := Color("#555064")
	for side in [-1.0, 1.0]:
		mesh.box(Vector3(0, 3.35, -4.61 + side * .84), Vector3(11.08, .16, 1.91), roof, Vector3(side * .43, 0, 0))
		for row in 5:
			for column in 29:
				var x := -5.36 + column * .38 + (row % 2) * .09
				var tint := .92 + .025 * ((row + column * 3) % 5)
				mesh.box(Vector3(x, 3.132 + row * .145, -4.61 + side * (1.515 - row * .317)), Vector3(.367, .046, .35), roof * Color(tint, tint, tint), Vector3(side * .43, 0, 0))
	# A narrow board at each height follows the triangular gable.
	for row in 8:
		var width := 4.18 - row * .50
		mesh.box(Vector3(3.04, 2.951 + row * .105, -2.939), Vector3(width, .10, .14), TRIM.darkened(.16 + .018 * (row % 3)))
	for side in [-1.0, 1.0]:
		mesh.box(Vector3(3.04 + side * 1.06, 3.357, -2.88), Vector3(2.37, .114, .19), TRIM, Vector3(0, 0, -side * .402))
		mesh.box(Vector3(3.04 + side * 1.06, 3.432, -3.17), Vector3(2.35, .095, .70), roof, Vector3(0, 0, -side * .402))
	mesh.box(Vector3(3.04, 3.347, -2.842), Vector3(.35, .29, .05), WOOD.darkened(.23))
	for slat in 4:
		mesh.box(Vector3(3.04, 3.246 + slat * .065, -2.807), Vector3(.27, .03, .04), TRIM.darkened(.29))
	mesh.box(Vector3(-1.96, 2.968, -2.965), Vector3(7.08, .13, .105), TRIM)
	mesh.box(Vector3(0, 3.087, -3.012), Vector3(2.43, .12, .93), roof, Vector3(.14, 0, 0))
	mesh.box(Vector3(0, 2.999, -2.59), Vector3(2.49, .12, .085), TRIM)
	for side in [-1.0, 1.0]:
		mesh.box(Vector3(side * 1.11, 2.83, -3.18), Vector3(.103, .34, .33), WOOD, Vector3(.55, 0, 0))
		var x: float = side * 3.1
		mesh.box(Vector3(x, 1.59, -3.32), Vector3(1.87, 1.28, .12), TRIM)
		mesh.box(Vector3(x, 1.59, -3.249), Vector3(1.65, 1.06, .04), Color("#59423c"))
		for pane in [-1.0, 1.0]:
			mesh.box(Vector3(x + pane * .41, 1.84, -3.221), Vector3(.77, .455, .017), Color("#cf9756"))
			mesh.box(Vector3(x + pane * .41, 1.34, -3.221), Vector3(.77, .455, .017), Color("#805e55"))
			for slat in 5:
				mesh.box(Vector3(x + pane * .41, 1.66 + slat * .08, -3.208), Vector3(.74, .021, .011), Color("#9d6b47"))
		mesh.box(Vector3(x, 1.59, -3.197), Vector3(.07, 1.18, .062), TRIM.darkened(.07))
		mesh.box(Vector3(x, 1.59, -3.192), Vector3(1.73, .065, .068), TRIM.darkened(.07))
		mesh.box(Vector3(x, .946, -3.205), Vector3(1.99, .091, .24), TRIM)
	mesh.box(Vector3(0, 1.23, -3.326), Vector3(1.42, 2.44, .12), TRIM)
	mesh.box(Vector3(0, 1.202, -3.239), Vector3(1.16, 2.28, .071), Color("#263e3a"))
	for y in [.49, 1.16, 1.88]:
		for x in [-.284, .284]:
			mesh.box(Vector3(x, y, -3.19), Vector3(.438, .495, .04), Color("#354a44"))
			mesh.box(Vector3(x, y, -3.166), Vector3(.372, .429, .011), Color("#2b403c"))
	mesh.form(Vector3(.486, 1.19, -3.151), Vector3(.074, .074, .083), GOLD)
	mesh.form(Vector3(0, 2.63, -3.16), Vector3(.18, .25, .20), Color("#ffd487"))
	mesh.form(Vector3(0, 2.765, -3.16), Vector3(.22, .13, .22), BLACK)
	mesh.finish(parent, "BrickAndClapboardFrontage")
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.58, -3.03)
	lamp.light_color = Color("#ffb15e")
	lamp.light_energy = 1.55
	lamp.omni_range = 2.8
	parent.add_child(lamp)


static func stoop(parent: Node3D) -> void:
	var mesh := Sculpture.new()
	mesh.box(Vector3(0, .119, -2.95), Vector3(2.84, .238, 1.03), CONCRETE)
	mesh.box(Vector3(0, .066, -2.35), Vector3(2.92, .132, .22), CONCRETE.darkened(.14))
	mesh.box(Vector3(0, .248, -2.98), Vector3(.95, .02, .36), WOOD.darkened(.38))
	for side in [-1.0, 1.0]:
		var x: float = side * 1.31
		for post in 5:
			var z := -3.32 + post * .218
			var high := .99 - .075 * post
			mesh.box(Vector3(x, (high + .24) * .5, z), Vector3(.045, high - .24, .043), BLACK)
		mesh.box(Vector3(x, .84, -2.88), Vector3(.075, .065, 1.01), BLACK, Vector3(.329, 0, 0))
	mesh.finish(parent, "StoopAndRails")


static func fence(parent: Node3D, x: float) -> void:
	var mesh := Sculpture.new()
	for i in 47:
		var z := -5.31 + i * .229
		var tint := float((i * 17) % 11) * .017
		var y := .66 + (i % 3) * .013
		mesh.box(Vector3(0, y, z), Vector3(.12, 1.23, .208), WOOD.lightened(tint))
		mesh.box(Vector3(0, y + .614, z), Vector3(.12, .072, .146), WOOD.lightened(tint + .055))
	for y in [.28, 1.07]:
		mesh.box(Vector3(-signf(x) * .084, y, 0), Vector3(.095, .128, 10.84), WOOD.darkened(.17))
	for i in 6:
		var z := -5.35 + i * 2.14
		mesh.box(Vector3(0, .724, z), Vector3(.29, 1.448, .30), WOOD.darkened(.18))
		mesh.box(Vector3(0, 1.463, z), Vector3(.333, .105, .339), TRIM.darkened(.21))
	mesh.finish(parent, "TimberFence", Vector3(x, 0, 0))


static func pavement(parent: Node3D) -> void:
	var mesh := Sculpture.new()
	mesh.box(Vector3(0, -.055, 5.43), Vector3(20.0, .11, 3.69), Color("#4b4146"))
	for i in 12:
		var x := -7.25 + i * 1.32
		mesh.box(Vector3(x, .012, 2.91), Vector3(1.306, .043, 1.45), CONCRETE.lightened(.027 * (i % 4)))
		mesh.box(Vector3(x, .029, 3.672), Vector3(1.304, .078, .16), CONCRETE.darkened(.10))
	mesh.finish(parent, "SidewalkAndCurb")


static func garden(parent: Node3D) -> void:
	var mesh := Sculpture.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 341
	mesh.box(Vector3(0, -.146, -.5), Vector3(22, .28, 12), Color("#77834c"))
	for i in 230:
		var x := rng.randf_range(-6.84, 6.84)
		var z := rng.randf_range(-3.4, 2.16)
		var blade := LEAF.lightened(rng.randf_range(-.18, .14))
		if i % 4 == 0:
			mesh.form(Vector3(x, -.001, z), Vector3(rng.randf_range(.16, .62), .012, rng.randf_range(.12, .41)), blade.darkened(.04), Vector3.ZERO, 8)
		else:
			for leaf in 4:
				var offset := Vector3(rng.randf_range(-.055, .055), 0, rng.randf_range(-.055, .055))
				mesh.blade(Vector3(x, 0, z) + offset, offset * 1.3, rng.randf_range(.026, .076), blade)
	for center in [-4.8, -2.15, 2.18, 4.85]:
		for i in 17:
			mesh.form(Vector3(center + rng.randf_range(-.43, .43), rng.randf_range(.08, .49), -2.96 + rng.randf_range(-.22, .21)), Vector3(.35, .30, .31), LEAF.darkened(rng.randf_range(-.12, .25)), Vector3.ZERO, 8)
	for side in [-1.0, 1.0]:
		var x: float = side * 6.31
		mesh.form(Vector3(x, 1.18, -4.6), Vector3(.55, 2.66, .54), WOOD.darkened(.44), Vector3(.16, 0, side * .11))
		for i in 17:
			mesh.form(Vector3(x + rng.randf_range(-.91, .91), rng.randf_range(2.0, 3.85), -4.67 + rng.randf_range(-.8, .68)), Vector3(1.25, 1.28, 1.2), LEAF.lightened(rng.randf_range(-.24, .12)), Vector3.ZERO, 10)
	mesh.finish(parent, "LawnAndPlanting")
