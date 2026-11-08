extends Node
## Depth check for the street dressing: puts Duff behind / in front of a few trees and props
## (boots game.tscn like the smoke test) and saves a frame each to /tmp/dressing/.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/dressing_shot.tscn
## then: python3 tools/dressing_sheet.py -> docs/renders/street_dressing_depth.png

const OUT: = "/tmp/dressing/"
const SPOTS: = [
	["oak_behind", Vector2(166, 96)], ["oak_front", Vector2(160, 120)],
	["pine_behind", Vector2(176, 272)], ["pine_front", Vector2(184, 298)],
	["maple_behind", Vector2(437, 336)], ["night_front", Vector2(160, 120)],
]

var frame: = 0
var game: Node
var m: Node
var i: = 0
var wait: = 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
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
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(OUT + str(SPOTS[i - 1][0]) + ".png")
		return
	if i >= SPOTS.size():
		print("dressing_shot: done")
		get_tree().quit()
		return
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	if str(SPOTS[i][0]).begins_with("night"):
		m.clock = 22 * 60.0
	m.player.position = SPOTS[i][1]
	m._set_camera()
	i += 1
	wait = 20
