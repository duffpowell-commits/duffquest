extends Node
## Menu + minigame style audit: one screenshot of every menu card, overlay and minigame, in touch mode.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/ui_audit_shot.tscn
## -> /tmp/ui_audit/NN_<name>.png ; sheet: python3 tools/ui_audit_sheet.py -> docs/renders/ui_audit_<tag>.png

const Cast: = preload("res://scripts/cast.gd")
const OUT: = "/tmp/ui_audit/"
var frame: = 0
var game: Node
var m: Node
var steps: Array = []
var wait: = 0
var shot_name: = ""
var n: = 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game = load("res://game.tscn").instantiate()
	add_child(game)
	var sub: = func(s): return func(): _clean(); m._run_game(s.new(), func(_a, _b, _c): pass)
	steps = [
		["title", func(): _clean(); m.show_title()],
		["menu_card", func(): _clean(); m.in_title = false; m._menu("BEDTIME", ["Show & Tell with {partner}, the 3 AM shift, then the creak-free crawl to bed.", "Skip it and I wing the whole night on autopilot."], [["play", "Play tonight", KEY_1], ["skip", "Skip: autopilot", KEY_2]], func(_c): pass)],
		["dialogue", func(): _clean(); m._say(["{partner}: You said you'd be home by six. It is nine. The baby has learned three new words and two of them are about you."])],
		["phone", func(): _clean(); m.open_phone()],
		["settings", func(): _clean(); m.open_settings()],
		["gear", func(): _clean(); m.debug_station("gear")],
		["wordle", func(): _clean(); m.debug_station("wordle")],
		["shop", func(): _clean(); m.open_shop()],
		["pharmacy", func(): _clean(); m.debug_station("pharmacy")],
		["grocery", func(): _clean(); m.debug_station("grocery")],
		["plasma", func(): _clean(); m.debug_station("plasma")],
		["symphony", func(): _clean(); m.debug_station("symphony")],
		["akarui", func(): _clean(); m.debug_station("akarui")],
		["show_tell", sub.call(m_script("ShowTellScript"))],
		["baby", sub.call(m_script("BabyScript"))],
		["stealth", func(): _clean(); m.debug_station("stealth")],
		["blackheads", sub.call(m_script("BlackheadScript"))],
		["backwalk", sub.call(m_script("BackwalkScript"))],
		["mash", func(): _clean(); m.debug_station("mash")],
		["fryer", func(): _clean(); m.debug_station("fryer")],
		["sandwich", func(): _clean(); m.debug_station("sandwich")],
		["salad", func(): _clean(); m.debug_station("salad")],
		["garnish", func(): _clean(); m.debug_station("garnish")],
		["pickles", func(): _clean(); m.debug_station("pickles")],
		["prep", func(): _clean(); m.debug_station("prep")],
		["quiz", func(): _clean(); m.debug_station("quiz")],
		["temp_check", func(): _clean(); m.debug_station("temp_check")],
		["inspector", func(): _clean(); m.debug_station("inspector")],
		["ending", sub.call(m_script("EndingScript"))],
	]

func m_script(k: String) -> Script:
	return load("res://scripts/main.gd").get_script_constant_map()[k]

func _clean() -> void:
	if m.in_shift:
		m.end_shift({"left": true})
	m.no_loading = true
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	m.clock = 720.0
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
		m.tut.mark_seen()
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(OUT + "%02d_%s.png" % [n, shot_name])
			n += 1
		return
	if steps.is_empty():
		print("ui_audit_shot: done")
		get_tree().quit()
		return
	var s: Array = steps.pop_front()
	shot_name = s[0]
	(s[1] as Callable).call()
	wait = 45
