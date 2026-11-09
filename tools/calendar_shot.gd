extends Node
## Renders the fridge calendar on a few days, for checking by eye.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/calendar_shot.tscn
## -> /tmp/qa/cal_<day>.png ; contact sheet: docs/renders/fridge_calendar.png (tools/calendar_sheet.py)
## Cases: [day, forced daily event id or ""]
const CASES: = [[1, ""], [7, "cat_chaos"], [9, ""], [16, "park_day"], [19, "ice"], [25, ""]]
var frame: = 0
var game: Node
var main: Node
var ci: = 0

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

func _process(_d: float) -> void:
	frame += 1
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 170:
		for c in game.find_children("*", "", true, false):
			if c.has_method("show_calendar"):
				main = c
	if frame >= 180 and (frame - 180) % 30 == 0:
		if ci > 0:
			var prev: Array = CASES[ci - 1]
			get_viewport().get_texture().get_image().save_png("/tmp/qa/cal_%02d.png" % int(prev[0]))
			main.calendar_done()
		if ci >= CASES.size():
			get_tree().quit()
			return
		var c: Array = CASES[ci]
		main.day_count = int(c[0])
		main.day_i = int(c[0]) + 3
		main.daily = {"day": int(c[0]), "id": str(c[1]), "recent": [], "falcor": ""}
		main.show_calendar()
		ci += 1
