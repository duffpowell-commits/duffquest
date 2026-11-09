extends Node
## Visual QA: boots game.tscn, starts a new game, then jumps through the places the smoke test
## never reaches (long dialogue + toast, home interior, street combat, all 17 bosses, the gala,
## shop overlays) and saves one screenshot each.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/qa_shot.tscn
## Output: /tmp/qa/*.png (contact sheets go in docs/renders/qa_*.png via tools/qa_sheet.py).

const BossScript: = preload("res://scripts/boss.gd")
const OUT: = "/tmp/qa/"

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
	steps = [
		["dialog_long", func(): _clean(); m._say(["*psst psst* I hit myself with {cologne}. Notes of leather, venture capital and Applebee's parking lot. CHARISMA 6 hrs: 20% off stores, bigger tips, +25% {partner} happiness."])],
		["dialog_madison", func(): _clean(); m._say(["{partner}: You said you'd be home by six. It is nine. The baby has learned three new words and two of them are about you."])],
		["toast_long", func(): _clean(); m._toast("I break free! Now he's knocking on {sister}'s door. She'll eat him alive. Meanwhile I'm out here with a fryer burn, no rent money and a cat judging me from the porch.")],
		["home", func(): _clean(); m.enter_home(); m.dialog.clear()],
		["combat", func():
			_clean(); m.leave_home(); m.dialog.clear()
			for k in ["scammer", "pete", "pirate", "drunk"]:
				m.spawn_enemy(k, m.player.position + Vector2(randf_range(-50, 50), randf_range(-30, 30)))],
		["shop", func(): _clean(); m.open_shop()],
		["pharmacy", func(): _clean(); m.open_pharmacy()],
		["grocery", func(): _clean(); m.open_grocery()],
		["plasma", func(): _clean(); m.open_plasma()],
		["kitchen_fryer", func(): _clean(); m.debug_station("fryer")],
		["kitchen_sandwich", func(): _clean(); m.debug_station("sandwich")],
	]
	for k in BossScript.BOSSES.keys():
		steps.append(["boss_%s_intro" % k, _boss.bind(k)])
		steps.append(["boss_%s_fight" % k, func(): m.dialog.clear()])
	steps.append(["gala", func():
		_clean(); m.gala_unlocked = true; m.start_gala(0)])

func _clean() -> void:
	if m.in_shift:  # kitchen shots leave a shift running; its card would sit over every later shot
		m.end_shift({"left": true})
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	if m.arena_boss and is_instance_valid(m.arena_boss):
		m.arena_boss.queue_free()
	if m.location != "outside":
		m.location = "outside"
		m.player.position = Vector2(180, 150)
		m._set_camera()

func _boss(k: String) -> void:
	if m.in_shift:
		m.end_shift({"left": true})
	m.close_overlay()
	m.dialog.clear()
	if m.arena_boss and is_instance_valid(m.arena_boss):
		m.arena_boss.queue_free()
	m.start_story_fight(k)

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
		m.no_loading = true  # loading screens would cover every shot
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(OUT + shot_name + ".png")
		return
	if steps.is_empty():
		print("qa_shot: done")
		get_tree().quit()
		return
	var s: Array = steps.pop_front()
	shot_name = s[0]
	(s[1] as Callable).call()
	wait = 40
