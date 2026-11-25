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
const CRIB := Vector3(1.6, 0, -2.72)   ## against the back wall, under the picture
const MAT := Vector3(-3.0, 0, 1.45)    ## play mat, front left
const HIGH_CHAIR := Vector3(2.98, 0, .9)

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
	_baby(game, root)
	_clutter(game, root, kx)

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
		"crib": Vector3(CRIB.x, 0, CRIB.z + .85),
		"play_mat": Vector3(MAT.x + .5, 0, MAT.z),
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

## The baby's things (Duff, Nov 25: "more baby props, more lived in"): crib with a mobile, play mat with a
## baby gym and toys, bouncer, high chair at the table, stroller by the door, bottles, a monitor.
static func _baby(game, root: Node3D) -> void:
	var wood := Color("#e9dcc6")
	var crib := Art.Sculpture.new()
	var c := CRIB
	crib.box(c + Vector3(0, .3, 0), Vector3(1.25, .06, .66), wood)                    # mattress base
	crib.box(c + Vector3(0, .36, 0), Vector3(1.18, .08, .6), Color("#f6f1e6"))        # mattress
	crib.box(c + Vector3(0, .4, .05), Vector3(.5, .03, .4), Color("#a9c7d8"))         # blanket
	crib.form(c + Vector3(-.42, .43, -.05), Vector3(.13, .07, .1), Color("#c79a6a"))  # teddy bear
	crib.form(c + Vector3(-.42, .53, -.05), Vector3(.08, .08, .07), Color("#c79a6a"))
	for dx in [-.6, .6]:
		crib.box(c + Vector3(dx, .45, 0), Vector3(.06, .9, .7), wood)                  # end boards
	for dz in [-.31, .31]:
		crib.box(c + Vector3(0, .86, dz), Vector3(1.24, .04, .04), wood)              # top rails
		for i in 11:
			crib.box(c + Vector3(-.52 + i * .104, .62, dz), Vector3(.025, .46, .025), wood)  # slats
	# Mobile over the crib: arm, ring, four hanging shapes.
	crib.box(c + Vector3(.55, 1.12, 0), Vector3(.03, .52, .03), Color("#d8d2c6"))
	crib.box(c + Vector3(.35, 1.37, 0), Vector3(.42, .03, .03), Color("#d8d2c6"))
	crib.band(c + Vector3(.15, 1.33, 0), .16, Color("#d8d2c6"), Vector3.ZERO, .01)
	var shapes := [Color("#f2c14e"), Color("#7cc4b4"), Color("#e8869a"), Color("#9ab4e8")]
	for i in 4:
		var a := i * TAU / 4
		crib.form(c + Vector3(.15 + cos(a) * .16, 1.2, sin(a) * .16), Vector3(.05, .05, .05), shapes[i], Vector3.ZERO, 8)
	crib.finish(root, "Crib")
	game._collider("CribCollider", c + Vector3(0, .45, 0), Vector3(1.3, .9, .72), root)

	# Play mat with a baby gym (two arches, hanging toys), stacking blocks, a duck, a ball.
	var m := MAT
	var play := Art.Sculpture.new()
	play.box(m + Vector3(0, .012, 0), Vector3(1.3, .02, 1.0), Color("#f0e2c0"))
	for i in 4:  # quilted squares
		play.box(m + Vector3(-.33 + (i % 2) * .66, .024, -.25 + (i / 2) * .5), Vector3(.6, .01, .46),
			[Color("#9fd0c4"), Color("#f4b6a0"), Color("#f7d98a"), Color("#b6c4ee")][i])
	for side in [-1.0, 1.0]:
		play.band(m + Vector3(0, .02, side * .3), .42, Color("#e8e2d6"), Vector3(PI / 2, 0, 0), .02)
	play.box(m + Vector3(0, .43, 0), Vector3(.03, .03, .62), Color("#e8e2d6"))
	for i in 3:
		play.box(m + Vector3(0, .36, -.2 + i * .2), Vector3(.01, .12, .01), Color("#8a8a8a"))
		play.form(m + Vector3(0, .29, -.2 + i * .2), Vector3(.05, .05, .05), shapes[i], Vector3.ZERO, 8)
	var blocks := [[Vector3(.45, .06, .32), Color("#d9534f")], [Vector3(.45, .16, .32), Color("#5b9bd5")],
		[Vector3(.58, .06, .2), Color("#f2c14e")], [Vector3(-.5, .06, .38), Color("#6cbf84")]]
	for b in blocks:
		play.box(m + b[0], Vector3(.1, .1, .1), b[1], Vector3(0, b[0].x * 3, 0))
	play.form(m + Vector3(-.4, .06, -.3), Vector3(.07, .06, .06), Color("#f5d327"))   # rubber duck
	play.form(m + Vector3(-.34, .1, -.3), Vector3(.04, .04, .04), Color("#f5d327"))
	play.box(m + Vector3(-.31, .1, -.3), Vector3(.03, .015, .02), Color("#f08a24"))
	play.form(m + Vector3(.75, .08, -.45), Vector3(.08, .08, .08), Color("#e8869a"), Vector3.ZERO, 10)  # ball
	play.finish(root, "PlayMat")
	# Bouncer next to the mat.
	var bounce := Art.Sculpture.new()
	var bp := m + Vector3(.2, 0, -.95)
	bounce.box(bp + Vector3(0, .03, 0), Vector3(.5, .04, .62), Color("#b8b8be"))
	bounce.form(bp + Vector3(0, .2, .04), Vector3(.22, .08, .3), Color("#7cc4b4"), Vector3(-.4, 0, 0))
	bounce.form(bp + Vector3(0, .3, -.18), Vector3(.2, .1, .1), Color("#6aaea0"), Vector3(-.9, 0, 0))
	bounce.box(bp + Vector3(0, .42, .12), Vector3(.42, .025, .025), Color("#d8d2c6"))
	bounce.form(bp + Vector3(.1, .36, .12), Vector3(.04, .04, .04), Color("#f2c14e"), Vector3.ZERO, 8)
	bounce.finish(root, "Bouncer")
	game._collider("BouncerCollider", bp + Vector3(0, .2, 0), Vector3(.5, .4, .62), root)

	# High chair at the dining table, tray with a sippy cup.
	var hc := HIGH_CHAIR
	var chair := Art.Sculpture.new()
	for dx in [-.17, .17]:
		for dz in [-.17, .17]:
			chair.box(hc + Vector3(dx, .4, dz), Vector3(.04, .8, .04), Color("#f4f1ea"), Vector3(dz * -.5, 0, dx * .5))
	chair.box(hc + Vector3(0, .72, 0), Vector3(.36, .06, .34), Color("#f4f1ea"))        # seat
	chair.box(hc + Vector3(.16, .96, 0), Vector3(.05, .46, .34), Color("#f4f1ea"))      # back
	chair.box(hc + Vector3(0, .8, 0), Vector3(.3, .03, .28), Color("#e8869a"))          # cushion
	chair.box(hc + Vector3(-.22, .9, 0), Vector3(.2, .03, .42), Color("#f4f1ea"))       # tray
	chair.form(hc + Vector3(-.24, .97, .1), Vector3(.035, .06, .035), Color("#7cc4b4"), Vector3.ZERO, 8)
	chair.form(hc + Vector3(-.24, .92, -.1), Vector3(.05, .012, .05), Color("#f2c14e"), Vector3.ZERO, 10)  # bowl
	chair.finish(root, "HighChair")
	game._collider("HighChairCollider", hc + Vector3(0, .5, 0), Vector3(.45, 1.0, .45), root)

	# Stroller parked by the door.
	var sp := Vector3(-3.45, 0, .5)
	var pram := Art.Sculpture.new()
	pram.form(sp + Vector3(0, .62, 0), Vector3(.28, .2, .36), Color("#3d4a5c"))         # basket
	pram.form(sp + Vector3(0, .78, -.16), Vector3(.27, .22, .2), Color("#2f3a4a"), Vector3(-.5, 0, 0))  # hood
	pram.box(sp + Vector3(0, .9, .42), Vector3(.46, .03, .03), Color("#222222"))        # handle
	for dx in [-.2, .2]:
		pram.box(sp + Vector3(dx, .62, .28), Vector3(.03, .6, .03), Color("#8a8a8a"), Vector3(-.5, 0, 0))
		for dz in [-.25, .25]:
			pram.band(sp + Vector3(dx * 1.1, .1, dz), .09, Color("#202022"), Vector3(0, 0, PI / 2), .025)
	pram.box(sp + Vector3(0, .3, 0), Vector3(.36, .04, .5), Color("#555555"))
	pram.finish(root, "Stroller")
	game._collider("StrollerCollider", sp + Vector3(0, .5, 0), Vector3(.55, 1.0, .9), root)

## Everyday clutter: laundry, shoes, mail, plant, dishes, fridge drawings, a jacket, a TV remote, a diaper bag.
static func _clutter(game, root: Node3D, kx: float) -> void:
	var junk := Art.Sculpture.new()
	# Laundry basket between the couch and the crib, a shirt spilling over.
	var lb := Vector3(.55, 0, -2.75)
	junk.box(lb + Vector3(0, .17, 0), Vector3(.5, .34, .36), Color("#e6ddcc"))
	junk.form(lb + Vector3(0, .36, 0), Vector3(.24, .08, .17), Color("#8fb0c8"))
	junk.form(lb + Vector3(.06, .38, .06), Vector3(.12, .06, .1), Color("#f4b6a0"))
	junk.box(lb + Vector3(.18, .2, .22), Vector3(.24, .02, .22), Color("#c8483c"), Vector3(.9, .2, 0))
	game._collider("LaundryCollider", lb + Vector3(0, .17, 0), Vector3(.5, .34, .36), root)
	# Shoes by the door, a kid's pair too.
	for sh in [[Vector3(-3.9, .04, -.15), Color("#2a2a2a"), .3], [Vector3(-3.72, .04, -.1), Color("#2a2a2a"), .3],
			[Vector3(-3.9, .03, .15), Color("#e86a5a"), .12], [Vector3(-3.82, .03, .2), Color("#e86a5a"), .12]]:
		junk.form(sh[0], Vector3(sh[2] * .35, .05, sh[2] * .5), sh[1])
	# Diaper bag on the couch, a burp cloth over the arm, the remote.
	junk.form(Vector3(-.15, .62, -2.55), Vector3(.18, .14, .1), Color("#d9a65a"))
	junk.box(Vector3(-.15, .78, -2.55), Vector3(.2, .03, .03), Color("#8a5a2a"))
	junk.box(Vector3(-2.1, .68, -2.65), Vector3(.12, .02, .3), Color("#f6f1e6"))
	junk.box(Vector3(-1.5, .585, -2.5), Vector3(.16, .025, .05), Color("#1d1d20"), Vector3(0, .4, 0))
	# Coffee table: a baby bottle, the monitor, mail.
	var tz := BACK + .55 + 1.45
	junk.form(Vector3(-.65, .47, tz - .12), Vector3(.035, .07, .035), Color("#f6f6f6"), Vector3.ZERO, 8)
	junk.form(Vector3(-.65, .55, tz - .12), Vector3(.02, .025, .02), Color("#f2c14e"), Vector3.ZERO, 8)
	junk.box(Vector3(-1.5, .46, tz + .12), Vector3.ONE * .08, Color("#efefef"))      # monitor
	junk.form(Vector3(-1.5, .51, tz + .12), Vector3(.025, .025, .01), Color("#38c25a"))
	for i in 3:
		junk.box(Vector3(-.75 + i * .03, .42 + i * .006, tz + .16), Vector3(.22, .004, .12), [Color("#f4f0e4"), Color("#d8c8a8"), Color("#e8e2f0")][i], Vector3(0, i * .4, 0))
	# Kitchen: bottles drying on a rack, dishes, a fruit bowl, formula tin, drawings on the fridge.
	junk.box(Vector3(kx - .05, .99, -.9), Vector3(.36, .04, .26), Color("#c8c8c8"))
	for i in 3:
		junk.form(Vector3(kx - .05, 1.08, -1.0 + i * .1), Vector3(.03, .08, .03), Color("#f8f8f8"), Vector3(0, 0, .3), 8)
	for i in 3:
		junk.form(Vector3(kx + .05, .98 + i * .02, -2.0), Vector3(.12, .012, .12), Color("#f0ece4"), Vector3.ZERO, 12)
	junk.form(Vector3(kx - .1, 1.0, -.12), Vector3(.14, .05, .14), Color("#7a5236"), Vector3.ZERO, 12)
	for f in [[Vector3(-.04, .05, 0), Color("#e94b3c")], [Vector3(.05, .05, .03), Color("#f2c14e")], [Vector3(0, .07, -.05), Color("#7dbb42")]]:
		junk.form(Vector3(kx - .1, 1.0, -.12) + f[0], Vector3.ONE * .045, f[1], Vector3.ZERO, 8)
	junk.form(Vector3(kx - .15, 1.03, -.55), Vector3(.06, .08, .06), Color("#f0d070"), Vector3.ZERO, 10)  # formula tin
	var front := HALF_W - .33 - .05 - .37  # fridge front face
	for d in [[Vector3(front - .005, 1.35, -2.95), Color("#fff8e0")], [Vector3(front - .005, .7, -2.95), Color("#e8f4ff")]]:
		junk.box(d[0], Vector3(.01, .22, .18), d[1])
		junk.box(d[0] + Vector3(-.006, .02, -.03), Vector3(.005, .06, .08), Color("#e8869a"))
		junk.box(d[0] + Vector3(-.006, -.05, .04), Vector3(.005, .04, .06), Color("#5b9bd5"))
	# A jacket thrown over a stool, a plant in the front-right corner, a bin.
	junk.form(Vector3(2.2, .56, .28), Vector3(.2, .06, .18), Color("#4a4a52"))
	junk.box(Vector3(2.2, .4, .45), Vector3(.18, .3, .02), Color("#4a4a52"))
	var pot := Vector3(3.85, 0, 2.25)
	junk.form(pot + Vector3(0, .17, 0), Vector3(.17, .17, .17), Color("#b4683c"), Vector3.ZERO, 12)
	for i in 7:
		var a := i * TAU / 7
		junk.form(pot + Vector3(cos(a) * .12, .5 + (i % 3) * .07, sin(a) * .12), Vector3(.07, .18, .04), Color("#4f8a3c"), Vector3(sin(a) * .5, a, cos(a) * .5))
	game._collider("PlantCollider", pot + Vector3(0, .3, 0), Vector3(.4, .6, .4), root)
	junk.form(Vector3(kx - .1, .2, .35), Vector3(.14, .2, .14), Color("#3a3a40"), Vector3.ZERO, 10)  # bin
	game._collider("BinCollider", Vector3(kx - .1, .2, .35), Vector3(.3, .4, .3), root)
	junk.finish(root, "Clutter")
