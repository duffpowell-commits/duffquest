extends Node
## Real morning flow: new game, then sleep -> wake -> loading screen -> fridge calendar -> wake report.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/wake_shot.tscn --fixed-fps 30
## -> /tmp/qa/wake_*.png
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
	get_viewport().get_texture().get_image().save_png("/tmp/qa/wake_%s.png" % n)

func _process(_d: float) -> void:
	frame += 1
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 170:
		for c in game.find_children("*", "", true, false):
			if c.has_method("show_calendar"):
				main = c
		main._wake(0)
	if frame == 200: _shot("1_loading")
	if frame == 300: _shot("2_fridge")
	if frame == 305: _key(KEY_SPACE)
	if frame == 330: _shot("3_report")
	if frame == 340:
		print("calendar_on=%s day=%d event=%s" % [main.calendar_on, main.day_count, main.today_event()])
		get_tree().quit()
