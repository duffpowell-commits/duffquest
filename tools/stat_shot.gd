extends Node
## Renders the stat points card (Spend stat points) from a fresh new game, full window size.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/stat_shot.tscn
## -> /tmp/qa/stat_screen.png (copy to docs/renders/ when it's a keeper)
var game: Node
var m: Node
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
		m = game.get_child(0).get_child(0).get_child(0)
		m.no_loading = true
		m.close_overlay()
		m.dialog.clear()
		m.combat.level = 2
		m.combat.points = 3
		m.combat.open_allocation()
	if frame == 240:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/stat_screen.png")
		get_tree().quit()
