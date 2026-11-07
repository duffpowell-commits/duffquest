extends Node
## Smoke test: boots the game, starts a new game, walks around, opens the phone.
## xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/smoke.tscn --fixed-fps 30 --write-movie /tmp/smoke/f.png --quit-after 600

var frame := 0
const SCRIPT := {
	40: [KEY_1], 80: [KEY_ENTER], 110: [KEY_ENTER], 140: [KEY_ENTER],
	170: [KEY_D, 40], 220: [KEY_S, 40], 270: [KEY_A, 30], 320: [KEY_W, 30],
	380: [KEY_E], 420: [KEY_ENTER], 460: [KEY_P], 520: [KEY_ESCAPE],
}

func _ready() -> void:
	add_child(load("res://main.tscn").instantiate())

func _key(k: int, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = pressed
	Input.parse_input_event(e)

var held := {}

func _process(_d: float) -> void:
	frame += 1
	if SCRIPT.has(frame):
		var s: Array = SCRIPT[frame]
		_key(s[0], true)
		held[s[0]] = frame + (s[1] if s.size() > 1 else 2)
	for k in held.keys():
		if frame >= held[k]:
			_key(k, false)
			held.erase(k)
