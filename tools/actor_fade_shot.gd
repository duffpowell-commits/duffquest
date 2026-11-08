extends Node
## M4 check: an enemy, a boss-sized enemy, a raccoon and a cat each stand behind a front-layer tree
## while Duff is out in the open. Shoots each spot with see-through off (old) and on (new).
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/actor_fade_shot.tscn
## then: python3 tools/actor_fade_sheet.py -> docs/renders/see_through_actors.png

const OUT: = "/tmp/actor_fade/"
## [name, Duff pos, actor kind, actor pos]; every actor's feet sit just above its tree's base.
const SPOTS: = [
	["oak_pirate", Vector2(120, 57), "pirate", Vector2(170, 96)],
	["pine_pirate", Vector2(126, 235), "pirate", Vector2(176, 274)],
	["maple_raccoon", Vector2(387, 297), "raccoon", Vector2(437, 326)],
	["maple_cat", Vector2(387, 297), "cat", Vector2(437, 328)],
]

var frame: = 0
var game: Node
var m: Node
var i: = 0
var pass_on: = false
var wait: = 0
var actor: Node

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

func _front() -> Node:
	for c in m.get_children():
		if c.get_script() == preload("res://scripts/dressing_front.gd"):
			return c
	return null

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
			var s: Array = SPOTS[i]
			get_viewport().get_texture().get_image().save_png(OUT + "%s_%s.png" % [s[0], "new" if pass_on else "old"])
			if pass_on:
				i += 1
			pass_on = not pass_on
		return
	if i >= SPOTS.size():
		print("actor_fade_shot: done")
		get_tree().quit()
		return
	var s: Array = SPOTS[i]
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	m.clear_enemies()
	for rc in m.raccoons:
		rc.position = Vector2(-500, -500)
		rc.set_physics_process(false)
		rc.queue_redraw()
	for c in m.cats:
		c.position = Vector2(-500, -500)
		c.set_process(false)
		c.queue_redraw()
	m.player.position = s[1]
	m._set_camera()
	match str(s[2]):
		"raccoon":
			actor = m.raccoons[0]
		"cat":
			actor = m.cats[0]
		_:
			actor = m.spawn_enemy(str(s[2]), s[3])
			actor.set_physics_process(false)
	actor.position = s[3]
	actor.queue_redraw()
	_front().fade_others = pass_on
	wait = 12
