extends Node3D
## Visual-only kitchen diorama. Never registered as a gameplay zone.

var steel: StandardMaterial3D
var dark: StandardMaterial3D
var ivory: StandardMaterial3D
var red: StandardMaterial3D
var wood: StandardMaterial3D
var green: StandardMaterial3D
var camera: Camera3D

func _ready() -> void:
	steel = material(Color("#b8bec0"), .35, .48)
	# Deterministic brushed, mottled steel; no external asset purchase.
	var noise := FastNoiseLite.new()
	noise.seed = 63
	noise.frequency = .12
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var v := .85 + .035 * noise.get_noise_2d(x * .12, y * 3.0) + .04 * noise.get_noise_2d(x, y)
			img.set_pixel(x, y, Color(v, v, v))
	steel.albedo_texture = ImageTexture.create_from_image(img)
	dark = material(Color("#25292c"), .1, .84)
	ivory = material(Color("#e9dfc6"), 0, .86)
	red = material(Color("#943b2e"), 0, .8)
	wood = material(Color("#94643c"), 0, .9)
	green = material(Color("#71933d"), 0, .8)
	room()
	grill()
	fryer()
	saute()
	cold_prep()
	pass_station()
	lighting()
	cast()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.1
	add_child(camera)
	camera.position = Vector3(8, 9, 12)
	camera.look_at(Vector3(0, 1.05, -.25))
	camera.current = true

func material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	return m

func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = mat
	parent.add_child(item)
	item.position = at
	return item

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	item.mesh = mesh
	item.material_override = mat
	parent.add_child(item)
	item.position = at
	return item

func label(parent: Node3D, title: String, at: Vector3, width: float) -> void:
	box(parent, at, Vector3(width, .32, .08), dark)
	var text := Label3D.new()
	text.text = title
	text.font_size = 44
	text.pixel_size = .006
	text.modulate = Color("#ffddb0")
	text.outline_size = 0
	parent.add_child(text)
	text.position = at + Vector3(0, 0, .05)

func station(title: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = title
	add_child(node)
	node.position = at
	return node

func room() -> void:
	var base := material(Color("#473631"), 0, .9)
	box(self, Vector3(0, -.14, 0), Vector3(11.2, .25, 7.2), base)
	var tiles := [material(Color("#e2d5bb"), 0, .9), material(Color("#454948"), 0, .92)]
	for x in 22:
		for z in 14:
			box(self, Vector3(-5.25 + x * .5, .005, -3.25 + z * .5), Vector3(.486, .035, .486), tiles[(x + z) % 2])
	box(self, Vector3(0, 1.55, -3.58), Vector3(11.2, 3.1, .18), ivory)
	box(self, Vector3(-5.58, 1.55, -2.35), Vector3(.18, 3.1, 2.4), ivory)
	box(self, Vector3(0, .12, -3.45), Vector3(11, .24, .08), red)
	box(self, Vector3(-5.45, .12, -2.35), Vector3(.08, .24, 2.4), red)
	# Grouted subway tile backsplash, short side wall for clear cutaway.
	for y in 4:
		for x in 22:
			box(self, Vector3(-5.25 + x * .5, 1.1 + y * .25, -3.46), Vector3(.485, .235, .028), ivory)
	box(self, Vector3(-2.65, 2.43, -2.88), Vector3(5.3, .33, 1.2), steel)
	box(self, Vector3(-2.65, 2.23, -2.88), Vector3(5.15, .08, 1.04), dark)
	for x in 12:
		box(self, Vector3(-5 + x * .43, 2.18, -2.87), Vector3(.26, .04, .76), steel)
	box(self, Vector3(-2.65, 2.82, -3.24), Vector3(2.4, .48, .45), steel)
	# A tall cooler, shelves and service supplies along the rear wall.
	box(self, Vector3(4.78, 1.07, -2.93), Vector3(1.14, 2.14, 1.02), steel)
	box(self, Vector3(4.78, 1.04, -2.40), Vector3(1.07, .025, .035), dark)
	for y in [.78, 1.55]:
		box(self, Vector3(4.42, y, -2.36), Vector3(.07, .35, .08), dark)
	for y in [1.75, 2.4]:
		box(self, Vector3(2.75, y, -3.12), Vector3(2.3, .07, .55), steel)
		for i in 5:
			cylinder(self, Vector3(1.9 + i * .38, y + .12, -3.08), .13, .2, ivory)

func base_unit(node: Node3D, width: float) -> void:
	box(node, Vector3(0, .54, 0), Vector3(width, .85, .92), steel)
	box(node, Vector3(0, .99, 0), Vector3(width + .06, .09, 1.0), steel)
	box(node, Vector3(0, .12, 0), Vector3(width - .12, .17, .78), dark)
	# Seams, kick plate and fine scuffs distinguish the brushed cabinet doors.
	box(node, Vector3(0, .55, .464), Vector3(.018, .72, .014), dark)
	var scratch := material(Color("#8a9293"), .2, .65)
	for i in 5:
		box(node, Vector3(-width * .39 + i * width * .14, .32 + i * .037, .466), Vector3(.13 + i * .035, .006, .005), scratch).rotation.z = -.12 + i * .045
	for x in [-.3, .3]:
		box(node, Vector3(x * width, .58, .47), Vector3(.42, .04, .05), dark)

func grill() -> void:
	var s := station("Grill", Vector3(-4.35, 0, -2.55))
	base_unit(s, 1.65)
	box(s, Vector3(0, 1.055, 0), Vector3(1.53, .09, .86), dark)
	for i in 12:
		box(s, Vector3(-.7 + i * .127, 1.12, 0), Vector3(.035, .035, .77), steel)
	var food := material(Color("#9a5636"), 0, .9)
	for x in [-.36, .24]:
		cylinder(s, Vector3(x, 1.16, -.1), .19, .09, food)
		for i in 3:
			box(s, Vector3(x - .1 + i * .1, 1.21, -.1), Vector3(.025, .008, .28), dark)
	label(s, "GRILL", Vector3(0, 2.43, .30), 1.5)

func fryer() -> void:
	var s := station("Fryer", Vector3(-2.55, 0, -2.55))
	base_unit(s, 1.65)
	var oil := material(Color("#b78c31"), .1, .45)
	for x in [-.39, .39]:
		box(s, Vector3(x, 1.05, 0), Vector3(.65, .04, .77), dark)
		box(s, Vector3(x, 1.075, -.05), Vector3(.53, .025, .56), oil)
		for i in 5:
			box(s, Vector3(x - .22 + i * .11, 1.18, -.08), Vector3(.018, .18, .55), steel)
		for z in [-.36, .2]:
			box(s, Vector3(x, 1.26, z), Vector3(.55, .04, .025), steel)
		box(s, Vector3(x, 1.27, .42), Vector3(.055, .055, .50), dark)
	label(s, "FRYER", Vector3(0, 2.43, .30), 1.5)

func saute() -> void:
	var s := station("Saute", Vector3(-.7, 0, -2.55))
	base_unit(s, 1.8)
	for x in [-.47, .47]:
		for z in [-.23, .23]:
			cylinder(s, Vector3(x, 1.07, z), .20, .08, dark)
			cylinder(s, Vector3(x, 1.13, z), .11, .04, steel)
			cylinder(s, Vector3(x, .92, .52), .06, .05, red).rotation.x = PI / 2
	for x in [-.47, .47]:
		cylinder(s, Vector3(x, 1.19, -.23), .23, .075, dark)
		box(s, Vector3(x, 1.21, .11), Vector3(.055, .045, .34), dark)
	label(s, "SAUTÉ", Vector3(0, 2.43, .30), 1.6)

func cold_prep() -> void:
	var s := station("ColdPrep", Vector3(1.8, 0, -1.94))
	base_unit(s, 2.4)
	box(s, Vector3(0, 1.08, -.27), Vector3(2.25, .2, .4), steel)
	for i in 5:
		box(s, Vector3(-.86 + i * .43, 1.195, -.27), Vector3(.36, .025, .30), [green, red, ivory, green, wood][i])
	box(s, Vector3(-.4, 1.07, .22), Vector3(.78, .045, .43), ivory)
	for i in 5:
		cylinder(s, Vector3(-.65 + i * .12, 1.11, .24), .07, .02, red)
	box(s, Vector3(.62, 1.11, .18), Vector3(.34, .09, .30), wood)
	label(s, "COLD PREP", Vector3(0, 1.65, -.49), 2.1)

func pass_station() -> void:
	var s := station("Pass", Vector3(3.0, 0, 2.19))
	base_unit(s, 3.3)
	for x in [-1.45, 1.45]:
		box(s, Vector3(x, 1.52, -.33), Vector3(.08, 1.05, .08), steel)
	box(s, Vector3(0, 1.99, -.32), Vector3(3.1, .10, .32), steel)
	for x in [-.95, 0, .95]:
		cylinder(s, Vector3(x, 1.87, -.20), .19, .18, red)
		var glow := OmniLight3D.new()
		glow.light_color = Color("#ffb86e")
		glow.light_energy = .4
		glow.omni_range = 2.0
		s.add_child(glow)
		glow.position = Vector3(x, 1.72, -.18)
		cylinder(s, Vector3(x, 1.07, .18), .25, .035, ivory)
		cylinder(s, Vector3(x, 1.11, .18), .12, .06, wood)
	label(s, "PASS", Vector3(0, 2.16, -.32), 1.4)
	for i in 4:
		box(s, Vector3(-1.15 + i * .23, 1.85, -.09), Vector3(.17, .21, .009), ivory)

func lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#292a30")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e4e5e4")
	env.ambient_light_energy = .42
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff0dc")
	sun.light_energy = .8
	sun.shadow_enabled = true
	add_child(sun)
	sun.rotation_degrees = Vector3(-58, -32, 0)
	for x in [-4.0, -.5, 3.4]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffc381")
		lamp.light_energy = .65
		lamp.omni_range = 5.0
		add_child(lamp)
		lamp.position = Vector3(x, 3.5, -.4)

func cast() -> void:
	var rig = load("res://rig_actor.gd")
	for entry in [["duff", Vector3(-2.5, 0, 1.0)], ["sendback", Vector3(-4.25, 0, -.85)], ["camper", Vector3(-1.0, 0, -1.0)], ["coupon", Vector3(.3, 0, .65)], ["allergy", Vector3(4.45, 0, -.7)]]:
		var actor = rig.make(self, entry[0], 1.65)
		actor.position = entry[1]
		actor.fit_head_bone()
		actor.rotation.y = -2.65
