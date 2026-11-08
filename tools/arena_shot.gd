extends Node
## In-game shot of one boss arena (fight view), for M7 backdrop checks. Run:
##   (ids: a boss arena, "title", or "fryer"/"sandwich" = the kitchen station with food in it)
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- gymbro
## -> /tmp/qa/arena_<id>.png   (id "title" = the title screen -> /tmp/qa/title.png)
var game: Node
var m: Node
var frame: = 0
var id: = "gymbro"

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		id = a[0]
	DirAccess.make_dir_recursive_absolute("/tmp/qa")
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _key(k: int) -> void:
	for p in [true, false]:
		var e: = InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)

func _process(_d: float) -> void:
	frame += 1
	if id == "title":
		if frame == 30:
			get_viewport().get_texture().get_image().save_png("/tmp/qa/title.png")
			get_tree().quit()
		return
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		if id in ["fryer", "sandwich"]:
			m.debug_station(id)
		else:
			m.start_story_fight(id)
	if frame == 215 and id in ["fryer", "sandwich"]:
		_key(KEY_SPACE)  # past the NEXT STATION card
	if frame == 260 and id in ["fryer", "sandwich"]:
		var g: Node = _find_game(m)
		if g and id == "sandwich":
			g.built = g.ORDER.duplicate()
		elif g:
			g.toggle(0)
			g.baskets[0]["prog"] = 0.8
			g.baskets[1]["prog"] = 1.5

	if frame == 230 and not id in ["fryer", "sandwich"]:
		m.dialog.clear()
		m.player.position = m.ARENA_ORIGIN + Vector2(200, 140)
	if frame == 280:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/arena_%s.png" % id)  # fryer/sandwich: the station
		get_tree().quit()

func _find_game(n: Node) -> Node:
	for c in n.get_children():
		if c.has_method("_draw_game") and (c.get("built") != null or c.get("baskets") != null):
			return c
		var r: = _find_game(c)
		if r:
			return r
	return null
