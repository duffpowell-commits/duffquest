extends Node
## Renders the shift cards with muscle memory on (every station S'd), for checking by eye.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/shift_shot.tscn
## -> /tmp/qa/shift_*.png

var frame: = 0
var game: Node
var main: Node

func _ready() -> void:
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

func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("/tmp/qa/shift_%s.png" % n)

func _process(_d: float) -> void:
	frame += 1
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 180:
		for c in game.find_children("*", "", true, false):
			if c.get("station_best") != null and c.has_method("start_shift"):
				main = c
		for k in ["quiz", "prep", "pickles", "fryer", "temp", "sandwich", "salad", "garnish"]:
			main.station_best[k] = "S"
		main.start_shift()
	if frame == 200: _shot("menu")
	if frame == 205: _key(KEY_1)
	if frame == 225: _shot("first")
	if frame == 230: _key(KEY_2)
	if frame == 250: _shot("after_autopilot")
	if frame == 260: get_tree().quit()
