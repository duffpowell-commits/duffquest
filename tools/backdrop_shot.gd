extends Node
## Backdrop check (Nov 10 Canva drop): boots game.tscn and shoots every minigame that draws a painted
## bg_* backdrop, the gala arena, and the cat_sacrifice loading screen.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/backdrop_shot.tscn
## -> /tmp/backdrop_shot/<name>.png ; sheet: python3 tools/backdrop_sheet.py -> docs/renders/backdrops_nov10.png

const OUT: = "/tmp/backdrop_shot/"
var frame: = 0
var game: Node
var m: Node
var steps: Array = []
var wait: = 0
var shot_name: = ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game = load("res://game.tscn").instantiate()
	add_child(game)
	steps = [
		["kwik", func(): _clean(); m.open_shop()],
		["grocery", func(): _clean(); m.open_grocery()],
		["pharmacy", func(): _clean(); m.clock = 720.0; m.open_pharmacy()],
		["plasma", func(): _clean(); m.clock = 720.0; m.open_plasma()],
		["holland", func(): _clean(); m._run_game(m.SymphonyScript.new(), func(_n, _s, _x): pass)],
		["akarui", func(): _clean(); m._run_game(m.AkaruiScript.new(), func(_n, _s, _x): pass)],
		["bedroom", func(): _clean(); m._run_game(m.BlackheadScript.new(), func(_n, _s, _x): pass)],
		["nursery", func(): _clean(); m._run_game(m.BabyScript.new(), func(_n, _s, _x): pass)],
		["living_night", func(): _clean(); m._run_game(m.EndingScript.new(), func(_n, _s, _x): pass)],
		["gala", func(): _clean(); m.gala_unlocked = true; m.start_gala(0); m.dialog.clear()],
		["loading_cat", func(): _clean(); _force_cat(); m.no_loading = false; m.show_loading()],
	]

func _force_cat() -> void:
	for n in game.find_children("*", "", true, false):
		if n.get_script() and str(n.get_script().resource_path).ends_with("loading_screen.gd"):
			n.screens = n.screens.filter(func(s): return s["id"] == "cat_sacrifice")

func _clean() -> void:
	m.no_loading = true
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0

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
		print("backdrop_shot: done")
		get_tree().quit()
		return
	var s: Array = steps.pop_front()
	shot_name = s[0]
	(s[1] as Callable).call()
	wait = 75 if shot_name == "loading_cat" else 40
