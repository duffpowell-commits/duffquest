extends Node
## Gala exes check (Nov 9): for each gala ex, shoots {partner}'s setup line, the boss intro (the retired
## billionaire cards must NOT show), and the fight a moment later with an attack telegraph up.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/gala_shot.tscn
## -> /tmp/gala_shot/<stage>_<n>.png; sheet: python3 tools/gala_sheet.py -> docs/renders/gala_exes_intros.png

const BossScript: = preload("res://scripts/boss.gd")
const Cast: = preload("res://scripts/cast.gd")
const OUT: = "/tmp/gala_shot/"
const STAGES: = [0, 1, 2, 4]               # main.BOSS_ORDER: husk, bozos, fences, (baron), donald

var frame: = 0
var game: Node
var m: Node
var plan: Array = []
var wait: = 0
var shot: = ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game = load("res://game.tscn").instantiate()
	add_child(game)
	for st in STAGES:
		plan.append(["%d_1setup" % st, _start.bind(st)])
		plan.append(["%d_2intro" % st, func(): m.dialog.pop_front()])
		plan.append(["%d_3fight" % st, func(): m.dialog.clear()])

func _start(st: int) -> void:
	m.close_overlay()
	m.dialog.clear()
	m.gala_unlocked = true
	if m.gala_boss and is_instance_valid(m.gala_boss):
		m.gala_boss.queue_free()
		m.gala_boss = null
	m.location = "outside"
	m.start_gala(st)
	var b: Dictionary = BossScript.BOSSES[m.BOSS_ORDER[st]]
	m.dialog.clear()
	m.dialog.append(Cast.N(str(b.get("setup", "(no setup line)"))))
	m.dialog.append(Cast.N(str(b["intro"])))

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
			get_viewport().get_texture().get_image().save_png(OUT + shot + ".png")
		return
	if plan.is_empty():
		print("gala_shot: done")
		get_tree().quit()
		return
	var s: Array = plan.pop_front()
	shot = s[0]
	(s[1] as Callable).call()
	wait = 75 if shot.ends_with("fight") else 30
