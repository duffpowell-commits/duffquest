extends Node
## Full-window shots of single UI screens (QA leftovers, Nov 9). Pick the screen after `--`:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/ui_shot.tscn -- grocery [out.png]
##   ... -- settings [out.png]
##   ... -- map [out.png]   (whole town; 1 world unit = 2 px)
## Default output: /tmp/qa/ui_<screen>.png. Uses a throwaway save path, never the real save.
var game: Node
var m: Node
var frame: = 0
var screen: = "grocery"
var out: = ""

func _ready() -> void:
	var args: = OS.get_cmdline_user_args()
	if args.size() > 0:
		screen = args[0]
	out = args[1] if args.size() > 1 else "/tmp/qa/ui_%s.png" % screen
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
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
		m.save_path = "user://ui_shot_throwaway.json"
		m.no_loading = true
		m.close_overlay()
		m.dialog.clear()
		m.toast_t = 0.0
		match screen:
			"grocery":
				m.clock = 12.0 * 60.0
				m._start_grocery(false, {})
			"settings":
				m.open_settings()
			"map":   # whole town, zoomed out (1 world unit = 2 px at 1280x720), HUD hidden
				var cam: Camera2D = m.cam
				m.juice.enabled = false
				cam.zoom = Vector2.ONE
				cam.limit_left = -10000
				cam.limit_top = -10000
				cam.limit_right = 10000
				cam.limit_bottom = 10000
				cam.position_smoothing_enabled = false
				cam.reparent(m)
				cam.global_position = Vector2(320, 180)
				cam.offset = Vector2.ZERO
				for h in game.find_children("*", "CanvasLayer", true, false):
					(h as CanvasLayer).visible = false
	if frame == 240:
		get_viewport().get_texture().get_image().save_png(out)
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ui_shot_throwaway.json"))
		get_tree().quit()
