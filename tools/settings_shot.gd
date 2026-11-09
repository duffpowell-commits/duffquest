extends Node
## Screenshot of the Settings screen -> /tmp/qa/settings.png. Run:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://tools/settings_shot.tscn
var game: Node
var frame: = 0

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
	if frame == 200:
		var m: Node = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		m.open_settings()
	if frame == 240:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/settings.png")
		get_tree().quit()
