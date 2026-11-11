extends Node
## Phone onboarding check: forces touch mode, then shoots the three tutorial cards, the overworld with the
## touch buttons, and a store menu (no keyboard chips on touch).
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/touch_shot.tscn
## -> /tmp/touch_shot/*.png ; sheet: python3 tools/touch_sheet.py -> docs/renders/touch_onboarding.png

const Cast: = preload("res://scripts/cast.gd")
const OUT: = "/tmp/touch_shot/"
var frame: = 0
var game: Node
var m: Node
var steps: Array = []
var wait: = 0
var shot_name: = ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://touch_tut.cfg"))
	game = load("res://game.tscn").instantiate()
	add_child(game)
	steps = [
		["card1", func(): _phone(); m.dialog.clear(); m.tut.start()],
		["card2", func(): m.tut.next()],
		["card3", func(): m.tut.next()],
		["hud", func(): m.tut.finish(); m.dialog.clear(); _phone()],
		["store", func(): _phone(); m.open_shop()],
	]

func _phone() -> void:
	m.touch.visible = true
	m.touch.used = true
	Cast.touch = true

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
	if frame < 200:
		return
	if m == null:
		m = game.get_child(0).get_child(0).get_child(0)
		m.no_loading = true
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(OUT + shot_name + ".png")
		return
	if steps.is_empty():
		print("touch_shot: done")
		get_tree().quit()
		return
	var s: Array = steps.pop_front()
	shot_name = s[0]
	(s[1] as Callable).call()
	wait = 30
