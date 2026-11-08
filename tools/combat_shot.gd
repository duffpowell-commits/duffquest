extends Node
## Combat-feel check: boots game.tscn, new game, spawns a few street enemies next to Duff and
## mashes the bonk button (plus one special) while the movie writer records.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/combat_shot.tscn --fixed-fps 30 --write-movie /tmp/combat/f.png --quit-after 520
## Then: python3 tools/combat_sheet.py -> docs/renders/combat_feel.png (+ combat_feel.gif)

var frame: = 0
var game: Node
var m: Node
var impacts: = 0

func _ready() -> void:
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _key(k: int, down: bool = true, up: bool = true) -> void:
	for p in ([true] if down else []) + ([false] if up else []):
		var e: = InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)

func _process(_d: float) -> void:
	frame += 1
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		m.toast_t = 0.0
		m.player.position = Vector2(200, 176)
		m.player.facing = Vector2.RIGHT
		for i in 3:
			m.spawn_enemy(["scammer", "pirate", "drunk"][i], m.player.position + Vector2(16 + i * 5, -4 + i * 5))
	if frame > 220 and frame < 470 and frame % 7 == 0:
		m.dialog.clear()
		m.toast_t = 0.0
		_key(KEY_SPACE)
	if frame == 330:
		m.spawn_enemy("scammer", m.player.position + Vector2(18, 0))
	if frame == 475:
		print("combat_shot: done, time_scale ", Engine.time_scale)
