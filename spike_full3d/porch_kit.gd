extends RefCounted
# Our own porch set: plain Godot shapes dressed in free seamless textures (models/kit/*.jpg).
# Same footprint as the Meshy set, so porch.gd's colliders fit both. Meshy is kept for characters.

const Art = preload("porch_art.gd")

const WALL_FRONT := -3.88  # brick face (FrontageCollider front is -3.9)
const BRICK_TOP := 1.25
const EAVE := 3.3


static func _mat(file: String, tiles_per_metre: float, tint := Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var folder := "set" if file == "sidewalk" else "kit"  # concrete is shared with the Meshy set's sidewalk
	material.albedo_texture = load("res://models/%s/%s.jpg" % [folder, file])
	material.albedo_color = tint
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * tiles_per_metre
	material.roughness = .95
	return material


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .8
	return material


static func _part(parent: Node3D, label: String, sculpt: Art.Sculpture, material: Material) -> MeshInstance3D:
	var visual := sculpt.finish(parent, label)
	visual.material_override = material
	visual.set_meta("set_prop", label.to_lower())
	return visual


# A picture on a flat card (door, windows): one copy of the texture, not tiled.
static func _card(parent: Node3D, label: String, file: String, at: Vector3, size: Vector2, tint := Color.WHITE) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://models/kit/%s.jpg" % file)
	material.albedo_color = tint
	material.roughness = .85
	var visual := MeshInstance3D.new()
	visual.name = label
	visual.mesh = quad
	visual.material_override = material
	parent.add_child(visual)
	visual.position = at


static func build(parent: Node3D, planter_at: Vector3, planter_size: Vector3) -> void:
	var trim := _flat(Color("#ece6da"))
	var iron := _flat(Color("#26242a"))

	# House: brick base, siding above, shingle roof sloping away from the camera.
	var brick := Art.Sculpture.new()
	brick.box(Vector3(0, BRICK_TOP * .5, WALL_FRONT - 1.0), Vector3(10.4, BRICK_TOP, 2.0), Color.WHITE)
	_part(parent, "House", brick, _mat("brick", .6))
	var siding := Art.Sculpture.new()
	siding.box(Vector3(0, (BRICK_TOP + EAVE) * .5, WALL_FRONT - 1.0), Vector3(10.4, EAVE - BRICK_TOP, 2.0), Color.WHITE)
	_part(parent, "Siding", siding, _mat("siding", .8, Color("#f2ede4")))
	var roof := Art.Sculpture.new()
	var slope := Vector3(-0.62, 0, 0)  # tilt back so the camera sees the shingles
	roof.box(Vector3(0, EAVE + .55, WALL_FRONT - .55), Vector3(11.0, .14, 2.6), Color.WHITE, slope)
	_part(parent, "Roof", roof, _mat("shingle", 1.1, Color("#8c8a92")))
	var bands := Art.Sculpture.new()
	for side in [-1.0, 1.0]:  # sill line, broken by the door
		bands.box(Vector3(side * 2.9, BRICK_TOP + .03, WALL_FRONT + .03), Vector3(4.6, .08, .08), Color.WHITE)
	bands.box(Vector3(0, EAVE - .05, WALL_FRONT + .04), Vector3(10.6, .14, .1), Color.WHITE)  # fascia
	for x in [-5.17, 5.17]:
		bands.box(Vector3(x, EAVE * .5, WALL_FRONT + .03), Vector3(.12, EAVE, .1), Color.WHITE)  # corner boards
	# door frame + window frames
	bands.box(Vector3(0, 2.72, WALL_FRONT + .04), Vector3(1.34, .14, .1), Color.WHITE)
	for x in [-.62, .62]:
		bands.box(Vector3(x, 1.58, WALL_FRONT + .04), Vector3(.12, 2.2, .1), Color.WHITE)
	for wx in [-3.1, 3.1]:
		for y in [1.42, 2.88]:
			bands.box(Vector3(wx, y, WALL_FRONT + .05), Vector3(1.9, .12, .12), Color.WHITE)
		for dx in [-.9, 0.0, .9]:
			bands.box(Vector3(wx + dx, 2.15, WALL_FRONT + .05), Vector3(.1, 1.46, .1), Color.WHITE)
	_part(parent, "Trim", bands, trim)
	_card(parent, "Door", "door", Vector3(0, 1.55, WALL_FRONT + .02), Vector2(1.1, 2.1))
	for wx in [-3.1, 3.1]:
		for dx in [-.45, .45]:
			_card(parent, "Window", "blinds", Vector3(wx + dx, 2.15, WALL_FRONT + .02), Vector2(.8, 1.36))

	# Stoop: landing + two steps in front of the door, iron rails either side.
	var stoop := Art.Sculpture.new()
	stoop.box(Vector3(0, .25, -3.3), Vector3(2.84, .5, 1.16), Color.WHITE)
	stoop.box(Vector3(0, .17, -2.58), Vector3(2.9, .34, .28), Color.WHITE)
	stoop.box(Vector3(0, .085, -2.35), Vector3(2.96, .17, .22), Color.WHITE)
	_part(parent, "Stoop", stoop, _mat("sidewalk", .8, Color("#d8d2cb")))
	var rails := Art.Sculpture.new()
	for x in [-1.38, 1.38]:
		rails.box(Vector3(x, .95, -3.2), Vector3(.05, .9, .05), Color.WHITE)
		rails.box(Vector3(x, .95, -2.5), Vector3(.05, 1.1, .05), Color.WHITE)
		rails.box(Vector3(x, 1.42, -2.86), Vector3(.06, .06, .86), Color.WHITE, Vector3(.24, 0, 0))
	rails.box(Vector3(.8, 2.35, WALL_FRONT + .1), Vector3(.14, .22, .12), Color.WHITE)  # porch lamp
	_part(parent, "Rails", rails, iron)

	# Beds: mulch strip along the wall, a bush in each.
	var beds := Art.Sculpture.new()
	for side in [-1.0, 1.0]:
		beds.box(Vector3(side * 3.3, .03, -3.38), Vector3(3.6, .06, 1.0), Color.WHITE)
	_part(parent, "Beds", beds, _mat("mulch", 1.4))
	var leaves := _mat("leaves", 1.6, Color("#a6b98a"))
	for x in [-4.6, -2.3, 2.3, 4.6]:
		var bush := Art.Sculpture.new()
		bush.form(Vector3(x, .38, -3.3), Vector3(.48, .4, .42), Color.WHITE)
		bush.form(Vector3(x - .28, .3, -3.15), Vector3(.3, .28, .3), Color.WHITE)
		bush.form(Vector3(x + .3, .32, -3.18), Vector3(.32, .3, .3), Color.WHITE)
		_part(parent, "Bush", bush, leaves)

	# Trees in the back corners.
	var bark := _mat("cedar", 1.8, Color("#7a5a48"))
	for side in [-1.0, 1.0]:
		var trunk := Art.Sculpture.new()
		var stem := CylinderMesh.new()
		stem.top_radius = .14
		stem.bottom_radius = .22
		stem.height = 2.6
		stem.radial_segments = 10
		trunk.add(stem, Vector3(side * 6.0, 1.3, -4.2), Color.WHITE)
		_part(parent, "Tree", trunk, bark)
		var crown := Art.Sculpture.new()
		crown.form(Vector3(side * 6.0, 3.3, -4.3), Vector3(1.3, 1.1, 1.2), Color.WHITE, Vector3.ZERO, 14)
		crown.form(Vector3(side * 5.4, 2.9, -4.0), Vector3(.8, .7, .8), Color.WHITE)
		crown.form(Vector3(side * 6.5, 2.8, -3.9), Vector3(.7, .6, .7), Color.WHITE)
		_part(parent, "Canopy", crown, _mat("leaves", 1.2, Color("#93ad78")))

	# Cedar fences down both sides: rails + posts every 2.2 m.
	var cedar := _mat("cedar", 1.5)
	for x in [-6.9, 6.9]:
		var fence := Art.Sculpture.new()
		fence.box(Vector3(x, .7, 0), Vector3(.08, 1.4, 11.0), Color.WHITE)
		for i in 6:
			fence.box(Vector3(x, .74, -5.5 + i * 2.2), Vector3(.16, 1.48, .16), Color.WHITE)
		fence.box(Vector3(x, 1.43, 0), Vector3(.14, .06, 11.0), Color.WHITE)
		_part(parent, "Fence", fence, cedar)

	# Planter box with flowers.
	var planter := Art.Sculpture.new()
	planter.box(planter_at + Vector3.UP * planter_size.y * .5, planter_size, Color.WHITE)
	_part(parent, "Planter", planter, cedar)
	var soil := Art.Sculpture.new()
	soil.box(planter_at + Vector3.UP * (planter_size.y - .02), Vector3(planter_size.x - .12, .04, planter_size.z - .12), Color.WHITE)
	_part(parent, "PlanterSoil", soil, _mat("mulch", 2.0, Color("#b08a70")))
	var blooms := Art.Sculpture.new()
	for i in 5:
		var dx := -.36 + i * .18
		blooms.form(planter_at + Vector3(dx, planter_size.y + .1, (i % 2) * .16 - .08), Vector3(.12, .1, .12), Color.WHITE, Vector3.ZERO, 8)
	_part(parent, "Blooms", blooms, _mat("leaves", 3.0, Color("#c4d49a")))

	# Mailbox on the sidewalk.
	var post := Art.Sculpture.new()
	post.box(Vector3(6.1, .5, 2.45), Vector3(.1, 1.0, .1), Color.WHITE)
	_part(parent, "MailboxPost", post, cedar)
	var box := Art.Sculpture.new()
	box.box(Vector3(6.1, 1.1, 2.45), Vector3(.26, .24, .52), Color.WHITE)
	box.form(Vector3(6.1, 1.22, 2.45), Vector3(.13, .1, .26), Color.WHITE, Vector3(0, 0, 0), 10)
	_part(parent, "Mailbox", box, _flat(Color("#33404c")))
