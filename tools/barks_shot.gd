extends Node
## Bark layout check (Nov 9): four street enemies bunched on Duff, each tries to bark ~0.5 s apart
## while damage numbers pop on all of them. Old code: every bubble at its own head, stacked on top
## of each other and over the white numbers. New (scripts/barks.gd): max 2 bubbles, no overlaps,
## numbers outlined and on top.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/barks_shot.tscn
## Shots -> /tmp/cp_shots/<tag>/barks_*.png (tag = $SHOT_TAG or "new"); python3 tools/polish_sheet.py

const LINES: = ["Hey king! Quick opportunity...", "Thanks for the package, chief! Leave five stars!",
	"I'm not drunk, YOU'RE drunk. Respectfully.", "I WANT TO SPEAK TO THE MANAGER!"]
const KINDS: = ["scammer", "pirate", "drunk", "karen"]
const OFFS: = [Vector2(16, -3), Vector2(22, 3), Vector2(12, 6), Vector2(26, -6)]
const SHOTS: = {300: "barks_a", 330: "barks_b", 360: "barks_c"}

var frame: = 0
var game: Node
var m: Node
var es: Array = []
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
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.clock = 12 * 60.0
		m.close_overlay()
		m.dialog.clear()
		m.toast_t = 0.0
		m.clear_enemies()
		m.player.position = Vector2(200, 176)
		m._set_camera()
		for k in 4:
			var e: Node = m.spawn_enemy(KINDS[k], m.player.position + OFFS[k])
			e.set_physics_process(false)   # stand still; we tick line_t ourselves
			e.line_cd = 999.0
			es.append(e)
	if frame < 200:
		return
	m.dialog.clear()
	m.toast_t = 0.0
	for k in es.size():
		var e: Node = es[k]
		if not is_instance_valid(e):
			continue
		e.line_t = maxf(0.0, e.line_t - 1.0 / 30.0)
		if frame == 230 + k * 15:
			e.say(LINES[k], 4.0)
		if frame > 260 and (frame + k * 4) % 9 == 0:
			m.combat.fx.number(e.global_position + Vector2(0, -12), 3 + (frame + k) % 9, (frame + k) % 4 == 0)
		e.queue_redraw()
	if SHOTS.has(frame):
		get_viewport().get_texture().get_image().save_png(out + SHOTS[frame] + ".png")
	if frame == 370:
		print("barks_shot: done")
		get_tree().quit()
