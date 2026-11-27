extends Node3D
## Visual-only restaurant interior. Never registered as a gameplay zone.

var steel: StandardMaterial3D
var dark: StandardMaterial3D
var ivory: StandardMaterial3D
var red: StandardMaterial3D
var wood: StandardMaterial3D
var green: StandardMaterial3D
var camera: Camera3D

func _ready() -> void:
	steel = material(Color("#b1a9a2"), .12, .54)
	weather(steel, 63, true)
	dark = material(Color("#25292c"), .1, .84)
	ivory = material(Color("#e9dfc6"), 0, .86)
	red = material(Color("#943b2e"), 0, .8)
	wood = material(Color("#94643c"), 0, .9)
	green = material(Color("#71933d"), 0, .8)
	weather(ivory, 19, false)
	room()
	grill()
	fryer()
	saute()
	cold_prep()
	pass_station()
	details()
	restaurant()
	batch_static()
	build_occluders()
	lighting()
	cast()
	atmosphere()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 67
	add_child(camera)
	set_view(Vector3(-4.95, 2.98, 2.55), Vector3(-.15, .62, -.95), 80)
	camera.current = true

func material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	return m

func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	if mat == steel and minf(size.x, minf(size.y, size.z)) >= .085 and maxf(size.x, maxf(size.y, size.z)) >= .35:
		item.mesh = bevel_mesh(size, minf(.035, minf(size.x, minf(size.y, size.z)) * .22))
	else:
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
	mesh.radial_segments = 16
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
	box(self, Vector3(0, -.14, 2.4), Vector3(11.2, .25, 12.0), base)
	var tiles := [material(Color("#c9ab83"), 0, .72), material(Color("#803e35"), 0, .79)]
	for i in 2:
		weather(tiles[i], 40 + i, false)
		tiles[i].set_meta("no_shadow", true)
	for x in 22:
		for z in 24:
			box(self, Vector3(-5.25 + x * .5, .005, -3.25 + z * .5), Vector3(.486, .035, .486), tiles[(x + z) % 2]).rotation.y = ((x*17+z*13)%4) * PI/2
	var plaster := material(Color("#807267"), 0, .93)
	box(self, Vector3(0, 1.55, -3.58), Vector3(11.2, 3.1, .18), plaster)
	box(self, Vector3(-5.58, 1.55, 2.4), Vector3(.18, 3.1, 12.0), plaster)
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
		box(s, Vector3(-.7 + i * .127, 1.12, 0), Vector3(.025, .025, .77), dark)
	var food := material(Color("#70462e"), 0, .77)
	weather(food, 57, false)
	for x in [-.36, .24]:
		var patty := cylinder(s, Vector3(x, 1.16, -.1), .19, .09, food)
		var patty_mesh := patty.mesh as CylinderMesh
		patty_mesh.top_radius = .175
		patty_mesh.bottom_radius = .18
		for i in 3:
			box(s, Vector3(x - .1 + i * .1, 1.21, -.1), Vector3(.019, .008, .28), dark)
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
		glow.light_energy = .32
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
	env.ambient_light_color = Color("#a9bfd8")
	env.ambient_light_energy = .47
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff0da")
	sun.light_energy = .65
	sun.shadow_enabled = true
	sun.shadow_blur = 1.8
	sun.directional_shadow_max_distance = 24.0
	add_child(sun)
	sun.rotation_degrees = Vector3(-58, -32, 0)
	for x in [-4.0, -.5, 3.4]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("#ffc381")
		lamp.light_energy = 1.5
		lamp.omni_range = 4.2
		add_child(lamp)
		lamp.position = Vector3(x, 2.85, -.55)

func cast() -> void:
	var rig = load("res://rig_actor.gd")
	for entry in [["duff", Vector3(-2.5, 0, 1.0)], ["sendback", Vector3(-4.25, 0, -.85)], ["camper", Vector3(-1.0, 0, -1.0)], ["coupon", Vector3(.3, 0, .65)], ["allergy", Vector3(4.45, 0, -.7)]]:
		var actor = rig.make(self, entry[0], 1.65)
		actor.position = entry[1]
		actor.fit_head_bone()
		actor.rotation.y = -2.65
		ground_shadow(actor.position)

## Compact, mipmapped procedural albedo + roughness maps shared by the static batches.
func weather(mat: StandardMaterial3D, seed_value: int, brushed: bool) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = .035
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var albedo := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var rough := Image.create(256, 256, false, Image.FORMAT_L8)
	for y in 256:
		for x in 256:
			var cloud := noise.get_noise_2d(x * .8, y * .8)
			var scuff := noise.get_noise_2d(x * .14, y * 16.0) if brushed else noise.get_noise_2d(x * 5.0, y * 5.0)
			var stain := smoothstep(.03, .48, cloud)
			var v := clampf(.91 + scuff * (.045 if brushed else .021) + rng.randf_range(-.018, .018) - stain * (.085 if brushed else .045), .45, 1.0)
			albedo.set_pixel(x, y, Color(v, v * (1.0 - stain * .035), v * (1.0 - stain * .075)))
			var r := clampf(.63 + stain * .24 + scuff * .13, .3, .98)
			rough.set_pixel(x, y, Color(r, r, r))
	if brushed:
		for i in 60:
			var y := rng.randi_range(1, 254)
			var x := rng.randi_range(1, 220)
			for dx in rng.randi_range(5, 30):
				albedo.set_pixel(x + dx, y, Color(.78, .79, .79) if i % 3 == 0 else Color(.96, .97, .97))
	albedo.generate_mipmaps()
	rough.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(albedo)
	mat.roughness_texture = ImageTexture.create_from_image(rough)
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.roughness = .74
	if brushed:
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(.65,.65,.65)

## Rounded cube with a single bevel band per face edge; preserves the original bounds.
func bevel_mesh(size: Vector3, radius: float) -> ArrayMesh:
	var half := size * .5
	var inner := half - Vector3.ONE * radius
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 3:
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for sign_value in [-1.0, 1.0]:
			var us := [-half[u], -inner[u], inner[u], half[u]]
			var vs := [-half[v], -inner[v], inner[v], half[v]]
			for i in 3:
				for j in 3:
					var corners := [[i,j], [i+1,j], [i+1,j+1], [i,j+1]]
					var order := [0,2,1,0,3,2] if sign_value > 0 else [0,1,2,0,2,3]
					for k in order:
						var p := Vector3.ZERO
						p[axis] = half[axis] * sign_value
						p[u] = us[corners[k][0]]
						p[v] = vs[corners[k][1]]
						var core := p.clamp(-inner, inner)
						var n := (p - core).normalized()
						st.set_normal(n)
						st.set_uv(Vector2(p[u]/size[u]+.5, p[v]/size[v]+.5))
						st.add_vertex(core + n * radius)
	st.index()
	return st.commit()

## Combine repeated static geometry by material, leaving actors and translucent effects unbatched.
func batch_static(parent: Node3D = self) -> void:
	var batches := {}
	for child in parent.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := child as MeshInstance3D
		var mat := mesh_node.material_override
		if not batches.has(mat):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[mat] = surface
		var surface: SurfaceTool = batches[mat]
		for index in mesh_node.mesh.get_surface_count():
			surface.append_from(mesh_node.mesh, index, parent.global_transform.affine_inverse() * mesh_node.global_transform)
		mesh_node.free()
	var group := Node3D.new()
	group.name = "StaticVisualBatches"
	parent.add_child(group)
	for mat in batches:
		var item := MeshInstance3D.new()
		item.mesh = batches[mat].commit()
		item.material_override = mat
		if mat.has_meta("no_shadow") or parent == roof:
			item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(item)

func details() -> void:
	var chrome := material(Color("#c5c7bd"), .55, .38)
	var rubber := material(Color("#252b2a"), 0, .95)
	var brass := material(Color("#b58b47"), .35, .55)
	var amber := material(Color("#d28a37"), 0, .5)
	var toast := material(Color("#b6793d"), 0, .82)
	var patty := material(Color("#593929"), 0, .88)
	var paper := material(Color("#eee2bf"), 0, .9)
	var towel := material(Color("#a65945"), 0, .95)
	var lamp_mat := material(Color("#fff0c4"), 0, .5)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color("#ffcd83")
	lamp_mat.emission_energy_multiplier = .65
	# Control fascia, dial markings, raised handles and indicator lamps.
	for station_name in ["Grill", "Fryer", "Saute", "ColdPrep", "Pass"]:
		var s := get_node(station_name) as Node3D
		var width := 3.3 if station_name == "Pass" else (2.4 if station_name == "ColdPrep" else 1.65)
		for x in [-.3, .3]:
			for dx in [-.17, .17]:
				box(s, Vector3(width*x+dx, .58, .505), Vector3(.04,.05,.075), chrome)
			box(s, Vector3(width*x,.58,.55), Vector3(.38,.045,.045), chrome)
		if station_name in ["Grill", "Fryer", "Saute"]:
			box(s, Vector3(0,.87,.477), Vector3(width-.12,.13,.045), dark)
			for i in 4:
				var xx := -.52+i*.34
				cylinder(s, Vector3(xx,.87,.52), .044,.05, chrome).rotation.x = PI/2
				box(s, Vector3(xx,.887,.55), Vector3(.012,.03,.008), dark)
				box(s, Vector3(xx+.09,.87,.505), Vector3(.025,.018,.012), amber)
	# Hood baffles and under-hood lights, kept above the cooking surface.
	for x in 22:
		box(self, Vector3(-5.18+x*.24,2.125,-2.9), Vector3(.18,.045,.8), chrome).rotation.x = .14
	for x in [-4.35,-2.55,-.7]:
		box(self,Vector3(x,2.13,-2.32),Vector3(1.36,.04,.09),lamp_mat)
	# Wall-mounted utensil rail and tools between cold prep and service shelving.
	box(self,Vector3(1.5,1.8,-3.35),Vector3(1.35,.043,.08),chrome)
	for i in 5:
		var x := .96+i*.24
		box(self,Vector3(x,1.58,-3.28),Vector3(.035,.34,.04),chrome)
		if i % 2 == 0:
			cylinder(self,Vector3(x,1.38,-3.27),.09,.035,chrome).rotation.x = PI/2
		else:
			box(self,Vector3(x,1.36,-3.27),Vector3(.12,.18,.025),chrome)
	# Floor mats are visual, flat, and remain within existing station footprints/aisle clearance.
	for x in [-4.35,-2.55,-.7,1.8]:
		var z := -1.65 if x < 1 else -.98
		box(self,Vector3(x,.026,z),Vector3(1.42,.018,.56),rubber)
		for i in 12:
			box(self,Vector3(x-.61+i*.11,.038,z),Vector3(.055,.008,.46),dark)
	# Basket mesh crossbars, handles and contents.
	var fryer_node := get_node("Fryer") as Node3D
	for x in [-.39,.39]:
		for i in 7:
			box(fryer_node,Vector3(x,1.23,-.34+i*.09),Vector3(.54,.018,.018),chrome)
		for dx in [-.28,.28]:
			for y in [1.12,1.19]:
				box(fryer_node,Vector3(x+dx,y,-.08),Vector3(.018,.016,.55),chrome)
		for i in 6:
			box(fryer_node,Vector3(x-.19+i*.07,1.13,-.05),Vector3(.038,.032,.24),amber).rotation.y = .15 * (i%3)
	# Prep containers, squeeze bottles and towel.
	var prep := get_node("ColdPrep") as Node3D
	for i in 5:
		var x := -.86+i*.43
		for dx in [-.19,.19]:
			box(prep,Vector3(x+dx,1.22,-.27),Vector3(.025,.065,.34),chrome)
		for z in [-.44,-.10]:
			box(prep,Vector3(x,1.22,z),Vector3(.38,.065,.025),chrome)
		for j in 4:
			cylinder(prep,Vector3(x-.11+j*.07,1.23,-.25+(.03 if j%2==0 else -.06)),.035,.045,[green,red,ivory,green,wood][i])
	for i in 3:
		var x := .72+i*.14
		cylinder(prep,Vector3(x,1.2,.26),.055,.27,[red,amber,ivory][i])
		cylinder(prep,Vector3(x,1.36,.26),.027,.07,ivory)
	box(prep,Vector3(-1.05,.64,.54),Vector3(.25,.34,.045),towel)
	for i in 4:
		box(prep,Vector3(-1.16+i*.07,.64,.57),Vector3(.025,.31,.008),red)
	# Pass: stacked rimmed plates, marked ticket strips, condiment caddy, heat-lamp bulbs.
	var pass_node := get_node("Pass") as Node3D
	for i in 5:
		cylinder(pass_node,Vector3(1.40,1.07+i*.033,-.1),.17,.025,ivory)
	for x in [-.95,0,.95]:
		cylinder(pass_node,Vector3(x,1.775,-.2),.13,.025,lamp_mat)
		cylinder(pass_node,Vector3(x,1.14,.18),.132,.035,patty)
		cylinder(pass_node,Vector3(x,1.16,.18),.138,.018,green)
		cylinder(pass_node,Vector3(x,1.179,.18),.127,.022,amber)
		var bun := MeshInstance3D.new()
		var bun_mesh := SphereMesh.new()
		bun_mesh.radius = .125
		bun_mesh.height = .105
		bun_mesh.radial_segments = 16
		bun_mesh.rings = 8
		bun.mesh = bun_mesh
		bun.material_override = toast
		pass_node.add_child(bun)
		bun.position = Vector3(x,1.222,.18)
	for i in 4:
		var x := -1.15+i*.23
		box(pass_node,Vector3(x,1.76,.01),Vector3(.15,.22,.015),paper).rotation.x = -.08
		for j in 4:
			box(pass_node,Vector3(x,1.82-j*.035,.023),Vector3(.10 if j!=2 else .065,.009,.003),dark)
	for i in 3:
		cylinder(pass_node,Vector3(-1.40+i*.13,1.17,-.02),.045,.22,[red,amber,green][i])
		cylinder(pass_node,Vector3(-1.40+i*.13,1.30,-.02),.02,.045,ivory)
	# Overhead fixtures float beneath the absent cutaway ceiling, behind station signage.
	label(self, "ORDER UP", Vector3(3.8,2.68,-3.37), 1.22)
	for x in [-3.7, .6, 3.6]:
		box(self,Vector3(x,2.92,-3.22),Vector3(1.15,.10,.27),dark)
		box(self,Vector3(x,2.86,-3.13),Vector3(1.05,.04,.22),lamp_mat)

var shadow_material: StandardMaterial3D
func ground_shadow(at: Vector3) -> void:
	if shadow_material == null:
		var img := Image.create(64,64,false,Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var r := Vector2(x-31.5,y-31.5).length()/31.5
				img.set_pixel(x,y,Color(.10,.07,.05,.55*pow(maxf(0,1-r),1.5)))
		shadow_material = StandardMaterial3D.new()
		shadow_material.albedo_texture = ImageTexture.create_from_image(img)
		shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var quad := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(.85,.70)
	quad.mesh = plane
	quad.material_override = shadow_material
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(quad)
	quad.position = at + Vector3(0,.05,0)

var wisps: Array[MeshInstance3D] = []
var wisp_time := 0.0
func atmosphere() -> void:
	var tex := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := Vector2((x-31.5)/17.0,(y-31.5)/30.0).length()
			tex.set_pixel(x,y,Color(.94,.91,.83,.34*pow(maxf(0,1-r),1.7)))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(tex)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for i in 6:
		var q := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(.34,.68)
		q.mesh = mesh
		q.material_override = mat
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)
		wisps.append(q)
	_process(0)

func _process(delta: float) -> void:
	wisp_time += delta
	for i in wisps.size():
		var phase := fposmod(wisp_time * .28 + i * .33, 1.0)
		var x: float = [-4.35,-2.55,-.7][i >> 1]
		wisps[i].position = Vector3(x + sin(phase*TAU+i)*.10, 1.35+phase*.67, -2.58)
		wisps[i].scale = Vector3.ONE * (.55+phase*.7)


var roof: Node3D
var east_wall: Node3D
var south_wall: Node3D

func set_view(at: Vector3, target: Vector3, fov: float) -> void:
	camera.position = at
	camera.look_at(target)
	camera.fov = fov
	roof.visible = at.y < 3.05
	east_wall.visible = at.x < 5.45
	south_wall.visible = at.z < 8.25

func restaurant() -> void:
	var paint := material(Color("#836b54"), 0, .92)
	weather(paint, 102, false)
	var burgundy := material(Color("#702c28"), 0, .63)
	var piping := material(Color("#a55342"), 0, .8)
	var trim := material(Color("#392c29"), 0, .83)
	var brass := material(Color("#b1844c"), .18, .5)
	var glass := material(Color("#607c8b"), .1, .28)
	var light := material(Color("#ffe0a1"), 0, .5)
	light.emission_enabled = true
	light.emission = Color("#ffbe67")
	light.emission_energy_multiplier = .85
	# Continuous baseboards and tiled west wall, with dining wainscoting.
	box(self, Vector3(-5.45,.55,2.4), Vector3(.09,1.1,11.8), burgundy)
	box(self, Vector3(-5.39,1.12,2.4), Vector3(.12,.12,11.8), trim)
	for z in 14:
		for y in 4:
			box(self,Vector3(-5.38,1.27+y*.25,-3.25+z*.5),Vector3(.035,.235,.485),ivory)
	# Kitchen/service partition, real opening over pass and aisle at left.
	box(self,Vector3(3.0,2.87,2.64),Vector3(4.95,.56,.17),paint)
	for x in [.58,5.43]:
		box(self,Vector3(x,1.45,2.64),Vector3(.19,2.9,.19),trim)
	box(self,Vector3(3.0,2.53,2.64),Vector3(4.95,.13,.23),steel)
	# Dinette booths: upholstered separate backs, padded seat ribs, pedestal tables.
	for z in [4.0,6.25]:
		for x in [-3.9,3.9]:
			for dz in [-.73,.73]:
				box(self,Vector3(x,.27,z+dz),Vector3(1.65,.51,.52),trim)
				box(self,Vector3(x,.56,z+dz),Vector3(1.72,.18,.58),burgundy)
				var back_z: float = z+dz+signf(dz)*.25
				box(self,Vector3(x,.96,back_z),Vector3(1.72,.85,.20),burgundy)
				for i in 6:
					box(self,Vector3(x-.69+i*.275,.97,back_z-signf(dz)*.115),Vector3(.025,.71,.025),piping)
			box(self,Vector3(x,.86,z),Vector3(1.35,.10,.98),wood)
			cylinder(self,Vector3(x,.43,z),.10,.79,steel)
			cylinder(self,Vector3(x,.06,z),.30,.07,trim)
			for i in 2:
				cylinder(self,Vector3(x-.12+i*.15,.99,z-.1),.05,.18,[red,brass][i])
				cylinder(self,Vector3(x-.12+i*.15,1.10,z-.1),.025,.06,ivory)
			cylinder(self,Vector3(x+.35,.945,z+.15),.14,.03,ivory)
			# Pendant with warm inner disc; small non-shadowed local fill.
			cylinder(self,Vector3(x,2.92,z),.025,.62,trim)
			var shade := cylinder(self,Vector3(x,2.60,z),.28,.22,brass)
			var cone := shade.mesh as CylinderMesh
			cone.top_radius = .13
			cylinder(self,Vector3(x,2.48,z),.23,.035,light)
			var glow := OmniLight3D.new()
			glow.light_color = Color("#ffb76d")
			glow.light_energy = 1.2
			glow.omni_range = 2.5
			add_child(glow)
			glow.position = Vector3(x,2.35,z)
	# Wall menu boards and windows with mullions and blinds.
	for z in [4.0,6.25]:
		box(self,Vector3(-5.43,2.1,z),Vector3(.10,1.45,1.90),trim)
		box(self,Vector3(-5.36,2.1,z),Vector3(.055,1.30,1.72),glass)
		for dz in [-.57,0,.57]:
			box(self,Vector3(-5.31,2.1,z+dz),Vector3(.08,1.32,.04),trim)
		for i in 5:
			box(self,Vector3(-5.27,2.69-i*.09,z),Vector3(.08,.035,1.66),wood)
	# Service door, push plate and inset window in the rear wall corner.
	box(self,Vector3(-5.34,1.23,-.85),Vector3(.09,2.42,.94),trim)
	box(self,Vector3(-5.27,1.23,-.85),Vector3(.07,2.32,.84),steel)
	box(self,Vector3(-5.22,1.78,-.85),Vector3(.04,.40,.45),dark)
	box(self,Vector3(-5.19,1.78,-.85),Vector3(.02,.31,.36),glass)
	box(self,Vector3(-5.18,1.04,-.55),Vector3(.06,.32,.12),brass)
	# Extra kitchen detail: pot stack, prep bowls, spatula and backsplash shelf brackets.
	for i in 6:
		cylinder(self,Vector3(2.2,1.83+i*.035,-3.07),.20,.03,ivory)
	for x in [2.8,3.35]:
		cylinder(self,Vector3(x,2.56,-3.08),.21,.23,steel)
		cylinder(self,Vector3(x,2.69,-3.08),.21,.028,dark)
		for dx in [-.25,.25]:
			box(self,Vector3(x+dx,2.58,-3.08),Vector3(.11,.045,.10),dark)
	var grill_node := get_node("Grill") as Node3D
	box(grill_node,Vector3(.64,1.15,.20),Vector3(.19,.025,.24),steel)
	box(grill_node,Vector3(.64,1.17,.42),Vector3(.06,.04,.23),dark)
	for i in 3:
		cylinder(grill_node,Vector3(-.54+i*.16,1.18,.28),.08,.035,wood)
	# Larger raised backsplash behind hot equipment; warm under-hood task lighting.
	for x in [-4.35,-2.55,-.7]:
		box(self,Vector3(x,1.63,-3.40),Vector3(1.63,.91,.035),steel)
		var task := SpotLight3D.new()
		task.light_color = Color("#ffb573")
		task.light_energy = 1.6
		task.spot_range = 3.1
		task.spot_angle = 55
		add_child(task)
		task.position = Vector3(x,2.10,-2.48)
		task.rotation_degrees.x = -90
	# A duct joining hood to the ceiling and narrow overhead framing.
	box(self,Vector3(-2.65,3.03,-3.24),Vector3(1.70,.40,.55),steel)
	box(self,Vector3(0,3.13,-3.39),Vector3(10.8,.18,.20),trim)

func build_occluders() -> void:
	var paint := material(Color("#807267"),0,.92)
	var trim := material(Color("#48372c"),0,.9)
	var ceiling := material(Color("#a49277"),0,.9)
	roof = Node3D.new()
	add_child(roof)
	box(roof,Vector3(0,3.29,2.4),Vector3(11.2,.2,12.0),ceiling).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z in [-2.8,-.4,2.64,5.2,7.8]:
		box(roof,Vector3(0,3.13,z),Vector3(11.0,.13,.12),trim).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	east_wall = Node3D.new()
	add_child(east_wall)
	box(east_wall,Vector3(5.58,1.55,2.4),Vector3(.18,3.1,12),paint)
	box(east_wall,Vector3(5.45,.55,2.4),Vector3(.09,1.10,11.8),red)
	south_wall = Node3D.new()
	add_child(south_wall)
	box(south_wall,Vector3(0,1.55,8.38),Vector3(11.2,3.1,.18),paint)
	box(south_wall,Vector3(0,.55,8.24),Vector3(11,.95,.09),red)
	var glass := material(Color("#83a6b6"),.05,.4)
	for x in [-3.6,0,3.6]:
		box(south_wall,Vector3(x,2.02,8.24),Vector3(2.65,1.46,.12),trim)
		box(south_wall,Vector3(x,2.02,8.16),Vector3(2.47,1.28,.06),glass)
		for dx in [-.8,0,.8]:
			box(south_wall,Vector3(x+dx,2.02,8.11),Vector3(.045,1.29,.06),trim)
		for i in 6:
			box(south_wall,Vector3(x,2.62-i*.09,8.10),Vector3(2.48,.035,.07),wood)
	for z in [4.0,6.25]:
		box(east_wall,Vector3(5.43,2.1,z),Vector3(.10,1.45,1.9),trim)
		box(east_wall,Vector3(5.36,2.1,z),Vector3(.055,1.30,1.72),glass)
		for dz in [-.57,0,.57]:
			box(east_wall,Vector3(5.31,2.1,z+dz),Vector3(.08,1.32,.04),trim)
		for i in 5:
			box(east_wall,Vector3(5.27,2.69-i*.09,z),Vector3(.08,.035,1.66),wood)

	for section in [roof, east_wall, south_wall]:
		batch_static(section)
