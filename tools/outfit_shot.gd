extends Node
## Outfit check: boots game.tscn, new game, then shows Duff outdoors in every armor/shoes combo
## (and the shades gag + a street fight) and saves one screenshot each.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/outfit_shot.tscn
## Output: /tmp/outfits/*.png -> python3 tools/outfit_sheet.py -> docs/renders/duff_outfits_ingame.png

const OUT: = "/tmp/outfits/"
const ARMORS: = ["apron", "clogs", "sleeves", "coat", "dad"]

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
	for a in ARMORS:
		for s in ["red", "black"]:
			steps.append(["%s_%s" % [a, s], _outfit.bind(a, s, false)])
	steps.append(["shades", _outfit.bind("apron", "red", true)])
	steps.append(["fight", func():
		_outfit("coat", "black", false)
		for k in ["scammer", "pete", "pirate"]:
			m.spawn_enemy(k, m.player.position + Vector2(randf_range(-40, 40), randf_range(-25, 25)))])

func _outfit(a: String, s: String, shades: bool) -> void:
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	if m.location != "outside":
		m.leave_home()
		m.dialog.clear()
	m.player.position = Vector2(180, 150)
	m._set_camera()
	m.player.armor_id = a
	m.player.shoes = s
	m.shades = shades
	m.player.shades = shades
	m.player.at_home = false
	m.player.facing = Vector2(0, 1)
	m.player.queue_redraw()

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
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(OUT + shot_name + ".png")
		return
	if steps.is_empty():
		print("outfit_shot: done")
		get_tree().quit()
		return
	var st: Array = steps.pop_front()
	shot_name = st[0]
	(st[1] as Callable).call()
	wait = 30
