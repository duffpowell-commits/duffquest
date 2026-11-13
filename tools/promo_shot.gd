extends Node
## Marketing footage (itch GIFs, CrazyGames preview clips). Plays a scripted take in real time; record it
## with --write-movie. Duff is driven by fake input, never takes damage, and the KO beats are stepped on a
## timer so a take is short. Touch controls and the control tutorial are hidden.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --fixed-fps 30 --resolution 1920x1080 \
##     --write-movie /tmp/promo/f.png res://tools/promo_shot.tscn -- fight:gymbro
## Takes:
##   fight:<boss>   story boss: intro card, ~6 s of fighting, last hit, knockout cutscene (beats stepped)
##   walk:X,Y,MIN,DX  outdoors at world point X,Y at clock minute MIN, walking DX px/s sideways (+ = right)
##   still:gala     one PNG: the gala floor, {partner} reacting to the landlord ex (-> /tmp/qa/promo_gala.png)
##   still:madison  one PNG: home, a {partner} line in the dialogue box (-> /tmp/qa/promo_madison.png)
##   still:at:X,Y,MIN  one PNG outdoors at X,Y at clock minute MIN (-> /tmp/qa/promo_at.png)
## Gore and language follow user://settings.json (point XDG_DATA_HOME at a folder with gore off for portals).
## Frames: the take starts at the frame printed as "PROMO_START <n>" (trim everything before it).

const KO_BEAT_SECS: = {"stance": 1.4, "slip": 1.5, "xray": 2.6, "finisher": 2.2, "crowd": 2.0, "closer": 2.4}
const FIGHT_SECS: = 6.0

var game: Node
var m: Node
var ko: Node
var frame: = 0
var take: = "fight:gymbro"
var t0: = -1                      # frame the take starts
var boss: Node
var phase: = ""
var phase_f: = 0
var ko_beat_f: = 0
var ko_last_beat: = -1
var end_f: = -1

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		take = a[0]
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _key(k: int) -> void:
	for p in [true, false]:
		var e: = InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)

func _find(n: Node, script_path: String) -> Node:
	for c in n.get_children():
		if c.get_script() and (c.get_script() as Script).resource_path == script_path:
			return c
		var r: = _find(c, script_path)
		if r:
			return r
	return null

func _hide_touch() -> void:
	if m == null:
		return
	if m.touch:
		m.touch.visible = false
	if m.tut:
		m.tut.visible = false

func _release_moves() -> void:
	for act in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(act)

func _start(f: int) -> void:
	t0 = f
	print("PROMO_START ", f)

func _process(_d: float) -> void:
	frame += 1
	if frame > 3000:
		get_tree().quit()
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		m.no_loading = true
		m.clear_enemies()              # skip the new-game cold open (porch pirate + its toast)
		m.story["cold_open"] = false
		m.porch_pkg = false
		m.toast_t = 0.0
		var ls: = _find(game, "res://scripts/loading_screen.gd")
		if ls:
			ls._finish()
		ko = _find(game, "res://scripts/knockout.gd")
		if ko:
			ko.fixed_seed = 1234
	if frame >= 200:
		_hide_touch()
	if frame < 200:
		return
	if take.begins_with("fight:"):
		_fight(take.substr(6))
	elif take.begins_with("walk:"):
		_walk(take.substr(5).split(","))
	elif take.begins_with("still:"):
		_still(take.substr(6))

func _still(k: String) -> void:
	if frame == 205:
		if k == "gala":
			m.gala_unlocked = true
			m.start_gala(2)                # fences: the landlord ex
			while m.dialog.size() > 1 and not str(m.dialog[0]).contains("LANDLORD"):
				m.dialog.pop_front()
		elif k == "madison":
			m.debug_station("home")
			m.dialog.clear()
			m._say(["{partner}: Diapers. We're down to the ones with the cartoon that scares her."])
		elif k.begins_with("at:"):
			var p: = k.substr(3).split(",")
			if m.location != "outside":
				m.leave_home()
			m.dialog.clear()
			m.player.position = Vector2(float(p[0]), float(p[1]))
	if k.begins_with("at:") and frame >= 205:
		m.clock = float(k.substr(3).split(",")[2])
		m.dialog.clear()
	if frame == 300:
		DirAccess.make_dir_recursive_absolute("/tmp/qa")
		var n: = "at" if k.begins_with("at:") else k
		get_viewport().get_texture().get_image().save_png("/tmp/qa/promo_%s.png" % n)
		get_tree().quit()

func _walk(p: PackedStringArray) -> void:
	if frame == 205:
		if m.location != "outside":
			m.leave_home()
		m.dialog.clear()
		m.player.position = Vector2(float(p[0]), float(p[1]))
	if frame >= 205:
		m.clock = float(p[2])          # hold the light still for the whole take
		if not m.dialog.is_empty():    # texts and barks that the clock jump fires would freeze Duff
			m.dialog.clear()
	if frame == 230:
		_start(frame)
		Input.action_press("move_right" if float(p[3]) >= 0.0 else "move_left")
	if t0 > 0 and frame > t0 + 30 * 8:
		_release_moves()
		get_tree().quit()

func _fight(id: String) -> void:
	if frame == 205:
		m.start_story_fight(id)
		boss = m.arena_boss
		phase = "intro"
		phase_f = frame
		_start(frame)
	if boss == null:
		return
	m.energy = 100.0                   # Duff can't lose a take
	match phase:
		"intro":                       # hold the intro card, then tap through it
			if frame - phase_f == 75:
				while m.dialog.size() > 0:
					m.dialog.pop_front()
				m.dialog.clear()
				phase = "fight"
				phase_f = frame
		"fight":
			_drive(frame - phase_f)
			if frame - phase_f == int(FIGHT_SECS * 30) and is_instance_valid(boss):
				boss.hp = minf(boss.hp, 6.0)    # next hit finishes him
			if ko and ko.playing():
				_release_moves()
				phase = "ko"
				phase_f = frame
				ko_beat_f = frame
				ko_last_beat = ko.beat
		"ko":
			if not ko.playing():
				if end_f < 0:
					end_f = frame
				if frame > end_f + 45:
					get_tree().quit()
				return
			if ko.beat != ko_last_beat:
				ko_last_beat = ko.beat
				ko_beat_f = frame
			var secs: float = float(KO_BEAT_SECS.get(ko.BEATS[ko.beat], 2.0))
			if frame - ko_beat_f >= int(secs * 30):
				ko._next()

## Fake player: close in on the boss, swing, roll out every so often.
func _drive(f: int) -> void:
	if not is_instance_valid(boss):
		_release_moves()
		return
	var d: Vector2 = boss.position - m.player.position
	var want: = Vector2(d.x - signf(d.x) * 26.0, d.y)
	_release_moves()
	if absf(want.x) > 4.0:
		Input.action_press("move_right" if want.x > 0.0 else "move_left")
	if absf(want.y) > 4.0:
		Input.action_press("move_down" if want.y > 0.0 else "move_up")
	if f % 9 == 0 and d.length() < 44.0:
		m._on_attack()
	if f % 70 == 50:
		m._on_roll()
