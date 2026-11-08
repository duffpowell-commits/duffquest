extends Node2D

const MAP: = "res://assets/iso/iso_map.json"
const DIR: = "res://assets/iso/"
const SPEED: = 48.0
const DIRS: = {"se": Vector2(2, 1), "sw": Vector2(-2, 1), "ne": Vector2(2, -1), "nw": Vector2(-2, -1) }
const SCREEN: = Vector2(320, 180)
const EXIT_BTN: = Rect2(300, 2, 18, 12)

class Actor extends Node2D:
	var tex: Texture2D
	var fsize: = Vector2i(24, 32)
	var foot: = Vector2i(12, 30)
	var col: = 0
	var row: = 0
	var lift: = 0
	var shadow: = Vector2(6, 2.2)
	func _draw() -> void:
		var snap: = position.round() - position

		var pts: = PackedVector2Array()
		for i in 12:
			var a: = TAU * i / 12.0
			pts.append(snap + Vector2(2.0 + cos(a) * shadow.x, -lift + 0.5 + sin(a) * shadow.y))
		draw_colored_polygon(pts, Color(0.11, 0.09, 0.07, 0.38))
		draw_texture_rect_region(tex, Rect2(snap + Vector2(-foot.x, -foot.y - lift), fsize), Rect2(col * fsize.x, row * fsize.y, fsize.x, fsize.y))

var m: Node = null
var meta: Dictionary = {}
var tileset: TileSet
var ground: TileMapLayer
var objects: TileMapLayer
var world: Node2D
var cam: Node2D
var ui: Node2D
var duff: Actor
var madison: Actor
var cats: Array = []
var solid: Dictionary = {}
var facing: = "se"
var walk_t: = 0.0
var t: = 0.0
var input_override: = Vector2.ZERO
var joy_idx: = -1
var joy_center: = Vector2.ZERO
var joy_vec: = Vector2.ZERO

const SKIRT: = 14

func _ready() -> void:
	build()

func build() -> void:
	if ground != null:
		return
	meta = JSON.parse_string(FileAccess.get_file_as_string(MAP))
	var bg: = ColorRect.new()
	bg.color = Color("#2b2218")
	bg.size = SCREEN
	add_child(bg)
	cam = Node2D.new()
	add_child(cam)
	tileset = TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_size = Vector2i(int(meta["tile"][0]), int(meta["tile"][1]))
	var w: int = int(meta["size"][0])
	var h: int = int(meta["size"][1])
	var gsrc: = TileSetAtlasSource.new()
	gsrc.texture = load(DIR + "iso_ground.png")
	gsrc.texture_region_size = tileset.tile_size
	for v in h:
		for u in w:
			gsrc.create_tile(Vector2i(u, v))
	tileset.add_source(gsrc, 0)

	var skirt: = TileMapLayer.new()
	skirt.name = "Skirt"
	skirt.tile_set = tileset
	for v in range(-SKIRT, h + SKIRT):
		for u in range(-SKIRT, w + SKIRT):
			if u < 0 or v < 0 or u >= w or v >= h:
				skirt.set_cell(Vector2i(u, v), 0, Vector2i(clampi(u, 0, w - 1), clampi(v, 0, h - 1)))
	skirt.modulate = Color(0.86, 0.84, 0.8)
	cam.add_child(skirt)
	ground = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	for v in h:
		for u in w:
			ground.set_cell(Vector2i(u, v), 0, Vector2i(u, v))
	cam.add_child(ground)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	cam.add_child(world)
	objects = TileMapLayer.new()
	objects.name = "Objects"
	objects.tile_set = tileset
	objects.y_sort_enabled = true
	world.add_child(objects)
	var objs: Array = meta["objects"]
	for i in objs.size():
		var o: Dictionary = objs[i]
		var src: = TileSetAtlasSource.new()
		src.texture = load(DIR + "obj_%s.png" % o["name"])
		var sz: = Vector2i(int(o["size"][0]), int(o["size"][1]))
		src.texture_region_size = sz
		src.create_tile(Vector2i.ZERO)
		tileset.add_source(src, i + 1)
		var td: = src.get_tile_data(Vector2i.ZERO, 0)
		td.texture_origin = Vector2i(int(o["foot"][0]) - sz.x / 2, int(o["foot"][1]) - sz.y / 2)
		td.y_sort_origin = int(o["sort"])
		objects.set_cell(Vector2i(int(o["cell"][0]), int(o["cell"][1])), i + 1, Vector2i.ZERO)
		for c in o["solid"]:
			solid[Vector2i(int(c[0]), int(c[1]))] = true

	duff = _actor("duff_iso.png", meta["duff"]["cell"], Vector2i(24, 32), Vector2i(12, 30))
	madison = _actor("madison_iso.png", meta["madison"]["cell"], Vector2i(24, 32), Vector2i(12, 30))
	madison.lift = int(meta["madison"].get("lift", 0))
	madison.position.y += 1.0
	for c in meta["cats"]:
		var a: = _actor("cat_%s.png" % c["name"], c["cell"], Vector2i(18, 16), Vector2i(9, 14))
		a.lift = int(c.get("lift", 0))
		a.position.y += 1.0
		a.shadow = Vector2(5, 1.6)
		a.set_meta("cat", str(c["name"]))
		cats.append(a)
	ui = Node2D.new()
	ui.draw.connect(_draw_ui)
	add_child(ui)
	_update_cam()

func _actor(file: String, cell: Array, fs: Vector2i, ft: Vector2i) -> Actor:
	var a: = Actor.new()
	a.tex = load(DIR + file)
	a.fsize = fs
	a.foot = ft
	a.position = ground.map_to_local(Vector2i(int(cell[0]), int(cell[1])))
	world.add_child(a)
	return a

func blocked(p: Vector2) -> bool:
	var c: = ground.local_to_map(p)
	if c.x < 0 or c.y < 0 or c.x >= int(meta["size"][0]) or c.y >= int(meta["size"][1]):
		return true
	return solid.has(c)

func pick_dir(v: Vector2) -> String:
	var best: = facing
	var bd: = -2.0
	for k in DIRS:
		var d: float = v.normalized().dot((DIRS[k] as Vector2).normalized()) + (0.01 if k == facing else 0.0)
		if d > bd:
			bd = d
			best = k
	return best

func step(delta: float) -> void:
	t += delta
	var v: = input_override
	if v == Vector2.ZERO and InputMap.has_action("move_left"):
		v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	elif v == Vector2.ZERO:
		v = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if v == Vector2.ZERO:
		v = joy_vec
	if v.length() > 0.2:
		facing = pick_dir(v)
		var dv: Vector2 = (DIRS[facing] as Vector2).normalized() * SPEED * delta
		var np: Vector2 = duff.position + dv
		if not blocked(np):
			duff.position = np
		walk_t += delta
		duff.col = [0, 1, 0, 2][int(walk_t * 8.0) % 4]
	else:
		walk_t = 0.0
		duff.col = 0
	duff.row = ["se", "sw", "ne", "nw"].find(facing)
	madison.col = int(t * 1.5) % 2
	for c in cats:
		c.col = 1 if fmod(t + float(cats.find(c)) * 0.7, 3.0) < 0.35 else 0
	_update_cam()
	for n in [duff, madison] + cats:
		n.queue_redraw()
	ui.queue_redraw()

func _process(delta: float) -> void:
	step(delta)

func px_scale() -> float:

	var k: = get_canvas_transform().get_scale().x
	return k if k > 0.0 else 1.0

func _update_cam() -> void:
	var k: = px_scale()
	cam.scale = Vector2(1.0 / k, 1.0 / k)
	cam.position = (SCREEN * k * Vector2(0.5, 0.56) - duff.position).round() / k

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
	elif e is InputEventScreenTouch:
		var tch: = e as InputEventScreenTouch
		var tp: = get_canvas_transform().affine_inverse() * tch.position
		if tch.pressed and EXIT_BTN.grow(4).has_point(tp):
			close()
		elif tch.pressed and joy_idx == -1:
			joy_idx = tch.index
			joy_center = tp
			joy_vec = Vector2.ZERO
		elif not tch.pressed and tch.index == joy_idx:
			joy_idx = -1
			joy_vec = Vector2.ZERO
	elif e is InputEventScreenDrag and (e as InputEventScreenDrag).index == joy_idx:
		joy_vec = ((get_canvas_transform().affine_inverse() * (e as InputEventScreenDrag).position - joy_center) / 20.0).limit_length(1.0)

func close() -> void:
	if m != null and m.has_method("close_overlay"):
		m.close_overlay()
	else:
		queue_free()

func _draw_ui() -> void:
	var f: = ThemeDB.fallback_font
	ui.draw_rect(Rect2(0, 0, 320, 14), Color(0.11, 0.09, 0.07, 0.78))
	ui.draw_string(f, Vector2(4, 10), "ISO STYLE TEST  (look only)  arrows / stick to walk", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#f0e4c4"))
	ui.draw_rect(EXIT_BTN, Color("#7a2a22"))
	ui.draw_string(f, EXIT_BTN.position + Vector2(6, 9), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#f0e4c4"))
	if joy_idx != -1:
		ui.draw_arc(joy_center, 20.0, 0, TAU, 20, Color(1, 1, 1, 0.3), 1.0)
		ui.draw_circle(joy_center + joy_vec * 20.0, 6.0, Color(1, 1, 1, 0.3))
