extends Node
## Whole-town screenshot: boots the game like the smoke test, starts a new game, then zooms the
## camera out to show the full 640×360-unit outdoor map and saves it.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/map_shot.tscn -- docs/renders/out.png

var frame: = 0
var game: Node
var out: = "res://docs/renders/town_ground_full.png"

func _ready() -> void:
	var args: = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = "res://" + args[0]
	game = load("res://main.tscn").instantiate()
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
		var cam: = get_viewport().get_camera_2d()
		if cam:
			cam.zoom = Vector2(1, 1)
			cam.limit_left = -10000
			cam.limit_top = -10000
			cam.limit_right = 10000
			cam.limit_bottom = 10000
			cam.position_smoothing_enabled = false
			cam.global_position = Vector2(320, 180)
			cam.offset = Vector2.ZERO
			if cam.get_parent() != game:
				cam.reparent(game)
				cam.global_position = Vector2(320, 180)
		for h in game.find_children("*", "CanvasLayer", true, false):
			(h as CanvasLayer).visible = false
	if frame == 240:
		var img: = get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(out))
		print("saved ", out)
		get_tree().quit()
