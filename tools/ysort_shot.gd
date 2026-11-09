extends Node
## Depth-order check (Nov 9): a pirate standing BEHIND the big oak, one IN FRONT of it, and both at
## once, with Duff off to the side (so the old "front layer picked by Duff's feet" rule shows).
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/ysort_shot.tscn
## Shots -> /tmp/cp_shots/<tag>/ysort_*.png (tag = $SHOT_TAG or "new"); python3 tools/polish_sheet.py
## -> docs/renders/actor_ysort.png (run it once on the old code with SHOT_TAG=old for the before row).

const OAK: = Vector2(170, 112)
## [name, [enemy origins]]; enemy feet = origin + 11. Behind: feet 5 px above the trunk base.
const SPOTS: = [
	["behind", [Vector2(166, 96)]],
	["front", [Vector2(160, 110)]],
	["both", [Vector2(178, 96), Vector2(158, 110)]],
]

var frame: = 0
var game: Node
var m: Node
var i: = 0
var wait: = 0
var out: = ""

func _ready() -> void:
	out = "/tmp/cp_shots/%s/" % (OS.get_environment("SHOT_TAG") if OS.get_environment("SHOT_TAG") != "" else "new")
	DirAccess.make_dir_recursive_absolute(out)
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
	if frame < 200:
		return
	if m == null:
		m = game.get_child(0).get_child(0).get_child(0)
		m.clock = 12 * 60.0
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(out + "ysort_%s.png" % SPOTS[i][0])
			i += 1
		return
	if i >= SPOTS.size():
		print("ysort_shot: done")
		get_tree().quit()
		return
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	m.clear_enemies()
	for rc in m.raccoons:
		rc.position = Vector2(-500, -500)
		rc.set_physics_process(false)
	for c in m.cats:
		c.position = Vector2(-500, -500)
		c.set_process(false)
	m.player.position = OAK + Vector2(-50, -55)
	m._set_camera()
	for p in SPOTS[i][1]:
		var e: Node = m.spawn_enemy("pirate", p)
		e.set_physics_process(false)
		e.position = p
		e.queue_redraw()
	wait = 12
