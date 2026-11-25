extends RefCounted
## Duff's apartment, the first walkable zone after the porch (Phase 2 step 3, Nov 25 2026).
## Built free: Godot shapes plus the kit's seamless textures (models/kit), no Meshy credits.
## A cutaway room: back wall and two side walls, open toward the camera like a sitcom set.
## Couch under the window facing the camera (the TV is the fourth wall), coffee table on a rug,
## kitchenette and fridge on the right, a small table with two stools, a floor lamp and a ceiling
## light. The door on the left wall goes back out to the porch.
## `spots` marks where people at home stand or sit (Madison and Brittany, phase 4).

const Art = preload("porch_art.gd")
const Kit = preload("porch_kit.gd")

const HALF_W := 4.2      ## floor runs x -4.2..4.2
const BACK := -3.2       ## back wall's inside face
const FRONT := 2.6       ## open edge toward the camera
const WALL_H := 2.5
const WALL_T := .2
const DOOR_Z := -1.0     ## the door on the left wall (centre)

static func build(zones, root: Node3D) -> void:
	var game = zones.game
	var depth := FRONT - BACK
	var mid_z := (FRONT + BACK) * .5
	var paint := Kit._flat(Color("#c9a98e"))
	var trim := Kit._flat(Color("#efe4d2"))

	# Floor: warm wood planks, and a dark cutaway ground around the room.
	var floor_s := Art.Sculpture.new()
	floor_s.box(Vector3(0, -.05, mid_z), Vector3(HALF_W * 2, .1, depth), Color.WHITE)
	Kit._part(root, "Floor", floor_s, Kit._mat("cedar", .8, Color("#8a6e5c")))
	var outside := Art.Sculpture.new()
	outside.box(Vector3(0, -.12, mid_z + 1.5), Vector3(24, .1, depth + 9), Color("#2b2230"))
	outside.finish(root, "Cutaway")

	# Walls: exposed brick behind the couch, painted sides, white baseboards.
	var back := Art.Sculpture.new()
	back.box(Vector3(0, WALL_H * .5, BACK - WALL_T * .5), Vector3(HALF_W * 2 + WALL_T * 2, WALL_H, WALL_T), Color.WHITE)
	Kit._part(root, "BackWall", back, Kit._mat("brick", .75, Color("#c89a88")))
	var sides := Art.Sculpture.new()
	for side in [-1.0, 1.0]:
		var x: float = side * (HALF_W + WALL_T * .5)
		if side < 0:  # left wall has the door gap (1.1 wide) with a lintel over it
			var gap_a := DOOR_Z - .55
			var gap_b := DOOR_Z + .55
			sides.box(Vector3(x, WALL_H * .5, (BACK + gap_a) * .5), Vector3(WALL_T, WALL_H, gap_a - BACK), Color.WHITE)
			sides.box(Vector3(x, WALL_H * .5, (gap_b + FRONT) * .5), Vector3(WALL_T, WALL_H, FRONT - gap_b), Color.WHITE)
			sides.box(Vector3(x, 2.25, DOOR_Z), Vector3(WALL_T, .5, 1.1), Color.WHITE)
		else:
			sides.box(Vector3(x, WALL_H * .5, mid_z), Vector3(WALL_T, WALL_H, depth), Color.WHITE)
	Kit._part(root, "SideWalls", sides, paint)
	var base := Art.Sculpture.new()
	base.box(Vector3(0, .06, BACK + .02), Vector3(HALF_W * 2, .12, .04), Color.WHITE)
	base.box(Vector3(HALF_W - .02, .06, mid_z), Vector3(.04, .12, depth), Color.WHITE)
	Kit._part(root, "Baseboards", base, trim)
	# Wall caps: a dark top edge so the cut walls read as walls from above.
	var caps := Art.Sculpture.new()
	caps.box(Vector3(0, WALL_H + .02, BACK - WALL_T * .5), Vector3(HALF_W * 2 + WALL_T * 2, .04, WALL_T + .02), Color("#3a2c2a"))
	for side in [-1.0, 1.0]:
		caps.box(Vector3(side * (HALF_W + WALL_T * .5), WALL_H + .02, mid_z), Vector3(WALL_T + .02, .04, depth), Color("#3a2c2a"))
	caps.finish(root, "WallCaps")

	# The door out (green, like the front door) in the left wall, facing into the room.
	Kit._card(root, "Door", "door", Vector3(-HALF_W - .01, 1.05, DOOR_Z), Vector2(.95, 2.1))
	(root.get_node("Door") as Node3D).rotation.y = PI / 2
	var frame := Art.Sculpture.new()
	for dz in [-.53, .53]:
		frame.box(Vector3(-HALF_W + .02, 1.07, DOOR_Z + dz), Vector3(.05, 2.14, .08), Color.WHITE)
	frame.box(Vector3(-HALF_W + .02, 2.12, DOOR_Z), Vector3(.05, .08, 1.14), Color.WHITE)
	Kit._part(root, "DoorFrame", frame, trim)
	var mat := Art.Sculpture.new()
	mat.box(Vector3(-HALF_W + .5, .012, DOOR_Z), Vector3(.6, .02, .9), Color("#7a3b34"))
	mat.finish(root, "DoorMat")

	# Window over the couch: blinds lit by the sky (the clock tints it, porch_look.gd daylight()).
	var pane := QuadMesh.new()
	pane.size = Vector2(1.9, 1.05)
	var glass := StandardMaterial3D.new()
	glass.albedo_texture = load("res://models/kit/blinds.jpg")
	glass.albedo_color = Color("#e8e2d8")
	glass.emission_enabled = true
	glass.emission = Color("#ffcf9a")
	glass.emission_texture = glass.albedo_texture
	var window := MeshInstance3D.new()
	window.name = "Window"
	window.mesh = pane
	window.material_override = glass
	window.add_to_group("zone_window")
	root.add_child(window)
	window.position = Vector3(-1.0, 1.62, BACK + .01)
	var sill := Art.Sculpture.new()
	sill.box(Vector3(-1.0, 1.07, BACK + .06), Vector3(2.1, .06, .14), Color.WHITE)
	sill.box(Vector3(-1.0, 2.17, BACK + .03), Vector3(2.06, .06, .06), Color.WHITE)
	for dx in [-1.0, 1.0]:
		sill.box(Vector3(-1.0 + dx * 1.0, 1.62, BACK + .03), Vector3(.06, 1.16, .06), Color.WHITE)
	Kit._part(root, "WindowFrame", sill, trim)

	# Couch under the window, facing the camera.
	var couch := Art.Sculpture.new()
	var cx := -1.0
	var cz := BACK + .55
	var fabric := Color("#4f6a78")
	couch.box(Vector3(cx, .26, cz), Vector3(2.3, .3, .86), fabric.darkened(.15))       # base
	couch.form(Vector3(cx - .52, .5, cz + .06), Vector3(.56, .14, .4), fabric)          # seat cushions
	couch.form(Vector3(cx + .52, .5, cz + .06), Vector3(.56, .14, .4), fabric)
	couch.box(Vector3(cx, .72, cz - .34), Vector3(2.3, .62, .22), fabric.darkened(.1))  # back
	for dx in [-1.08, 1.08]:
		couch.form(Vector3(cx + dx, .56, cz), Vector3(.14, .2, .44), fabric.darkened(.05))  # arms
	couch.form(Vector3(cx - .78, .74, cz - .16), Vector3(.22, .2, .08), Color("#d9b04a"), Vector3(.2, 0, .3))  # pillow
	couch.box(Vector3(cx, .05, cz), Vector3(2.2, .1, .78), Color("#2a2024"))  # feet shadow line
	couch.finish(root, "Couch")
	game._collider("CouchCollider", Vector3(cx, .45, cz), Vector3(2.4, .9, .9), root)

	# Rug + coffee table with a pizza box and two cans.
	var rug := Art.Sculpture.new()
	rug.box(Vector3(cx, .01, cz + 1.55), Vector3(2.6, .02, 1.7), Color("#8c4a3c"))
	rug.box(Vector3(cx, .015, cz + 1.55), Vector3(2.3, .02, 1.4), Color("#b06a4a"))
	rug.finish(root, "Rug")
	var table := Art.Sculpture.new()
	var tz := cz + 1.45
	table.box(Vector3(cx, .38, tz), Vector3(1.2, .07, .6), Color("#6b4630"))
	for dx in [-.52, .52]:
		for dz in [-.24, .24]:
			table.box(Vector3(cx + dx, .18, tz + dz), Vector3(.06, .36, .06), Color("#4a2f22"))
	table.box(Vector3(cx - .2, .44, tz), Vector3(.44, .05, .44), Color("#e9e0cf"))  # pizza box
	for dx in [.3, .42]:
		table.form(Vector3(cx + dx, .48, tz + .08), Vector3(.04, .06, .04), Color("#c8382c"), Vector3.ZERO, 8)
	table.finish(root, "CoffeeTable")
	game._collider("TableCollider", Vector3(cx, .25, tz), Vector3(1.2, .5, .6), root)

	# Kitchenette on the right wall: counter run, sink, stove, cabinets above, fridge at the back.
	var kitchen := Art.Sculpture.new()
	var kx := HALF_W - .33
	kitchen.box(Vector3(kx, .45, -1.15), Vector3(.62, .9, 2.4), Color("#5e6e5a"))      # cabinets
	kitchen.box(Vector3(kx - .02, .93, -1.15), Vector3(.68, .06, 2.44), Color("#d8d2c6")) # counter top
	kitchen.box(Vector3(kx, .97, -1.6), Vector3(.4, .04, .5), Color("#9aa4aa"))          # sink
	for dz in [-.62, -.32]:
		kitchen.band(Vector3(kx - .05, .97, dz), .09, Color("#202024"), Vector3.ZERO, .015)  # stove rings
	kitchen.box(Vector3(kx + .1, 1.85, -1.15), Vector3(.42, .6, 2.4), Color("#6a7a64"))  # upper cabinets
	kitchen.box(Vector3(kx - .05, .9, -2.78), Vector3(.72, 1.8, .7), Color("#e8e6e0"))    # fridge
	kitchen.box(Vector3(kx - .42, 1.1, -2.6), Vector3(.03, .4, .04), Color("#8a8a8a"))   # handle
	kitchen.finish(root, "Kitchenette")
	game._collider("KitchenCollider", Vector3(kx, .5, -1.15), Vector3(.66, 1.0, 2.44), root)
	game._collider("FridgeCollider", Vector3(kx - .05, .9, -2.78), Vector3(.72, 1.8, .7), root)

	# Small table with two stools.
	var dining := Art.Sculpture.new()
	var dx0 := 2.2
	var dz0 := .9
	dining.form(Vector3(dx0, .74, dz0), Vector3(.5, .03, .5), Color("#7a5236"), Vector3.ZERO, 16)
	dining.box(Vector3(dx0, .37, dz0), Vector3(.08, .74, .08), Color("#3a2a22"))
	dining.form(Vector3(dx0, .02, dz0), Vector3(.25, .02, .25), Color("#3a2a22"))
	for dz in [-.62, .62]:
		dining.form(Vector3(dx0, .5, dz0 + dz), Vector3(.2, .04, .2), Color("#c8a040"), Vector3.ZERO, 12)
		dining.box(Vector3(dx0, .25, dz0 + dz), Vector3(.05, .5, .05), Color("#3a2a22"))
	dining.finish(root, "DiningTable")
	game._collider("DiningCollider", Vector3(dx0, .4, dz0), Vector3(.9, .8, .9), root)

	# Floor lamp by the couch + a framed picture.
	var lamp_s := Art.Sculpture.new()
	var lx := -2.75
	var lz := BACK + .35
	lamp_s.form(Vector3(lx, .02, lz), Vector3(.18, .02, .18), Color("#2a2428"))
	lamp_s.box(Vector3(lx, .8, lz), Vector3(.035, 1.6, .035), Color("#2a2428"))
	lamp_s.form(Vector3(lx, 1.62, lz), Vector3(.24, .18, .24), Color("#f3d9a6"), Vector3.ZERO, 14)
	lamp_s.finish(root, "FloorLamp")
	_lamp(root, "LampLight", Vector3(lx, 1.55, lz + .1), 2.4, 4.5)
	var art := Art.Sculpture.new()
	art.box(Vector3(1.55, 1.6, BACK + .03), Vector3(.9, .66, .04), Color("#2a2024"))
	art.box(Vector3(1.55, 1.6, BACK + .055), Vector3(.78, .54, .02), Color("#e0a050"))
	art.form(Vector3(1.4, 1.55, BACK + .07), Vector3(.16, .16, .01), Color("#b8432f"))
	art.form(Vector3(1.75, 1.68, BACK + .07), Vector3(.12, .12, .01), Color("#27998f"))
	art.finish(root, "Picture")
	_lamp(root, "CeilingLight", Vector3(.3, 2.6, -.5), 1.5, 7.0)

	# Walls and edges keep Duff in the room; the open front stops at the floor's edge.
	game._collider("Ground", Vector3(0, -.16, mid_z), Vector3(HALF_W * 2 + 2, .32, depth + 2), root)
	game._collider("BackWallCollider", Vector3(0, 1.25, BACK - .15), Vector3(HALF_W * 2 + 1, 2.5, .3), root)
	game._collider("RightWallCollider", Vector3(HALF_W + .15, 1.25, mid_z), Vector3(.3, 2.5, depth + 1), root)
	var gap_a := DOOR_Z - .55
	var gap_b := DOOR_Z + .55
	game._collider("LeftWallCollider", Vector3(-HALF_W - .15, 1.25, (BACK + gap_a) * .5), Vector3(.3, 2.5, gap_a - BACK), root)
	game._collider("LeftWallCollider", Vector3(-HALF_W - .15, 1.25, (gap_b + FRONT + 1) * .5), Vector3(.3, 2.5, FRONT + 1 - gap_b), root)
	game._collider("DoorBack", Vector3(-HALF_W - .45, 1.25, DOOR_Z), Vector3(.3, 2.5, 1.2), root)
	game._collider("FrontEdge", Vector3(0, .6, FRONT + .2), Vector3(HALF_W * 2 + 1, 1.2, .3), root)

	zones.doors.append({"at": Vector2(-HALF_W + .45, DOOR_Z), "to": "porch", "spawn": Vector3(0, 0, -1.2),
		"face": Vector3.BACK})
	zones.spots = {
		"couch_left": Vector3(cx - .52, 0, cz + .25),
		"couch_right": Vector3(cx + .52, 0, cz + .25),
		"kitchen": Vector3(kx - .7, 0, -1.2),
		"table": Vector3(dx0 - .55, 0, dz0),
		"door": Vector3(-HALF_W + 1.2, 0, DOOR_Z),
	}

static func _lamp(root: Node3D, label: String, at: Vector3, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.name = label
	light.light_color = Color("#ffc27a")
	light.light_energy = energy
	light.omni_range = reach
	light.set_meta("base_energy", energy)
	light.add_to_group("zone_lamp")
	root.add_child(light)
	light.position = at
