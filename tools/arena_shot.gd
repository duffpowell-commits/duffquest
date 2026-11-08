extends Node
## In-game shot of one boss arena (fight view), for M7 backdrop checks. Run:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- gymbro
## -> /tmp/qa/arena_<id>.png
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
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		m.start_story_fight(id)
	if frame == 230:
		m.dialog.clear()
		m.player.position = m.ARENA_ORIGIN + Vector2(200, 140)
	if frame == 280:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/arena_%s.png" % id)
		get_tree().quit()
