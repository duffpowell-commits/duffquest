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
		["menu_wallpaper", func(): _clean(); m.in_title = false; m.visible = false; m._veil_tex = null; m._menu("SHIFT'S OVER", ["No scene to blur behind this card (shift menus, cold boot): a blurred loading-screen wallpaper."], [["ok", "Clock out", KEY_1]], func(_c): pass); m.visible = true],
		["phone", func(): _clean(); m.open_phone()],
		["settings", func(): _clean(); m.open_settings()],
		["credits", sub.call(m_script("CreditsScript"))],
		["credits_licenses", func(): m.overlay_node.scroll = 160.0 * 8.0],
		["gear", func(): _clean(); m.debug_station("gear")],
		["wordle", func(): _clean(); m.debug_station("wordle")],
		["shop", func(): _clean(); m.open_shop()],
		["pharmacy", func(): _clean(); m.debug_station("pharmacy")],
		["grocery", func(): _clean(); m.debug_station("grocery")],
		["plasma", func(): _clean(); m.debug_station("plasma")],
		["symphony", func(): _clean(); m.debug_station("symphony")],
		["symphony_bus", func(): m.overlay_node.go("busrun"); m.overlay_node.run_t = 1.2],
		["symphony_concert", func(): m.overlay_node.go("concert"); m.overlay_node.mt = 3.0],
		["symphony_snacks", func(): m.overlay_node.go("intermission")],
		["akarui", func(): _clean(); m.debug_station("akarui")],
		["akarui_belt", func(): m.overlay_node.go("conveyor"); m.overlay_node.plates = [["tuna", 60.0], ["salmon", 150.0], ["tuna", 250.0]]],
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
		["temp_check", func(): _clean(); m.debug_station("temp")],
		["inspector", func(): _clean(); m.debug_station("inspector")],
		["ending", sub.call(m_script("EndingScript"))],
		["prep_stock", func(): _clean(); m.debug_station("prep"); var g = _g(); g.pi = 1; g._enter_phase(); g.coach_open = false; g.pans[0]["temp"] = 47; g.pans[1]["level"] = 0.15],
		["bounty86", func(): _clean(); m.combat.level = 1; m.bounty_menu()],
		["coach_prep_stock", func(): _clean(); _coach(true); m.debug_station("prep"); var g = _g(); g.pi = 1; g._enter_phase(); g.coach_show(); g.coach_t = 0.4],
		["coach_fryer", func(): _clean(); _coach(true); m.debug_station("fryer"); _g().coach_show(); _g().coach_t = 0.4],
		["coach_garnish", func(): _clean(); _coach(true); m.debug_station("garnish"); _g().coach_show(); _g().coach_t = 0.4],
		["coach_baby", func(): _clean(); _coach(true); m._run_game(m_script("BabyScript").new(), func(_a, _b, _c): pass); _g().coach_show(); _g().coach_t = 0.4],
		["coach_noise", func(): _clean(); _coach(true); m._run_game(m_script("NoiseScript").new(), func(_a, _b, _c): pass); _g().coach_show(); _g().coach_t = 0.4],
		["coach_easy_fryer", func(): _clean(); _coach(true); m.debug_station("fryer"); _g().coach_open = false; _g().pace = 0.7],
	]

	# optional filter: `-- baby stealth` renders only those shots (a step whose name starts with a kept one stays too)
	var only: = Array(OS.get_cmdline_user_args())
	if not only.is_empty():
		steps = steps.filter(func(st): return only.any(func(o): return str(st[0]).begins_with(o)))

func m_script(k: String) -> Script:
	return load("res://scripts/main.gd").get_script_constant_map()[k]

## The running minigame: inside a shift it's the shift's current station.
func _g() -> Node:
	return m.shift.current if m.in_shift and m.shift.current != null else m.overlay_node

## The first-time coach (how-to cards, slow first go) stays out of the regular audit shots.
func _coach(on: bool) -> void:
	var ms = load("res://scripts/minigames/minigame.gd")
	if ms.source_code.contains("static var coach_on"):
		ms.coach_on = on

func _clean() -> void:
	_coach(false)
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
