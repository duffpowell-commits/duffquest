extends Node
## HUD declutter render: boots game.tscn, new game, then shoots the HUD in town, in a street fight,
## with the detail drawer open, with a change "peek", and with the rent chip up.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/hud_shot.tscn -- /tmp/hud_after
## Then: python3 tools/hud_sheet.py /tmp/hud_before /tmp/hud_after -> docs/renders/hud_declutter.png

var out: = "/tmp/hud_shot/"
var frame: = 0
var game: Node
var m: Node
var steps: Array = []
var wait: = 0
var shot_name: = ""

func _ready() -> void:
	var args: = OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://game.tscn").instantiate()
	add_child(game)
	steps = [
		["town", func():
			_setup(); m.leave_home(); m.dialog.clear()
			m.inventory["eggs"] = 2; m.inventory["flour"] = 1; m.gear["scraps"] = 33
			m.player.position += Vector2(40, 10)],
		["fight", func():
			m.dialog.clear(); m.energy = 100.0
			var offs: = [Vector2(-50, -6), Vector2(46, 8), Vector2(20, -30)]
			for i in 3:
				m.spawn_enemy(["pete", "pirate", "drunk"][i], m.player.position + offs[i])
			m.combat.heat = m.combat.heat_max() * 0.6],
		["drawer", func():
			m.clear_enemies(); m.dialog.clear(); m.toast_t = 0.0
			m.combat.heat = m.combat.heat_max()
			if m.hud.has_method("toggle_drawer"):
				m.hud.drawer_open = true],
		["peek", func():
			if m.hud.get("drawer_open") != null:
				m.hud.drawer_open = false
			m.inventory["chocolate"] = 1],
		["rent_due", func():
			m.dialog.clear(); m.toast_t = 0.0
			m.day_i = 6; m.money = 40],
	]

func _setup() -> void:
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	m.touch.visible = true
	m.touch.used = true

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
		if shot_name == "fight":
			m.dialog.clear()
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(out + shot_name + ".png")
		return
	if steps.is_empty():
		print("hud_shot: done")
		get_tree().quit()
		return
	var s: Array = steps.pop_front()
	shot_name = s[0]
	(s[1] as Callable).call()
	wait = 30 if not shot_name in ["peek", "rent_due", "fight"] else 6
