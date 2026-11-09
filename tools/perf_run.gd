extends Node
## Frame-time profile of the heavy scenes (desktop/xvfb as a proxy for phones). Run unthrottled:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/perf_run.tscn -- [scenes=town,fight] [off=post,lights] [low]
## Prints one "PERF <scene> ..." line per scene (wall ms mean/p50/p95, script ms, draw calls, objects)
## and writes them to /tmp/perf_run.txt. Uses a throwaway save (never touches the real one).
## off=  hides one piece to measure what it costs: post (hd2d screen shader), lights (PointLight2D),
##       hud, touch, fx (combat fx), overlay (HD portrait layer)
## low   starts with PerfGuard low-spec forced on (bloom/lights off)
const SCENES: = ["title", "town", "home", "fight", "boss", "ko", "calendar"]
const WARM: = 45
const MEASURE: = 240
const SANDBOX: = "user://perf_sandbox.save"

var game: Node
var m: Node
var scenes: Array = SCENES.duplicate()
var off: Array = []
var low: = false
var si: = -1
var f: = 0
var samples: Array = []
var proc: Array = []
var draws: Array = []
var last_us: = 0
var out: = PackedStringArray()
var walk_t: = 0.0
var cpu0: = 0
var home_pos: = Vector2.ZERO
var walk_dir: = 1.0

## Process CPU time (all threads, incl. llvmpipe raster threads) in ms, from /proc/self/stat.
## Unlike wall time it barely moves when other jobs load the machine.
func _cpu_ms() -> int:
	var fa: = FileAccess.open("/proc/self/stat", FileAccess.READ)
	if fa == null:
		return 0
	var parts: = fa.get_line().split(") ")[1].split(" ")
	return (int(parts[11]) + int(parts[12])) * 10

func _ready() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("scenes="):
			scenes = Array(a.substr(7).split(","))
		elif a.begins_with("off="):
			off = Array(a.substr(4).split(","))
		elif a == "low":
			low = true
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _find(n: Node, script_path: String) -> Node:
	for c in n.get_children():
		if c.get_script() and (c.get_script() as Script).resource_path == script_path:
			return c
		var r: = _find(c, script_path)
		if r:
			return r
	return null

func _apply_off() -> void:
	var hd: = m.get_node_or_null("HD2DPresentation")
	if hd:
		if "post" in off:
			hd.get_node("WorldOnlyPostProcess").visible = false
		if "lights" in off:
			for l in hd.lights:
				l.enabled = false
	if "hud" in off:
		m.hud.visible = false
		m.hud.set_process(false)
	if "touch" in off:
		m.touch.visible = false
		m.touch.set_process(false)
	if "fx" in off:
		m.combat.fx.visible = false
	if "overlay" in off:
		_find(game, "res://scripts/hd_portrait_overlay.gd").visible = false
	var pg: = _find(game, "res://scripts/perf_guard.gd")
	if pg and low:
		pg.force_low(true)

func _start(scene: String) -> void:
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	m.no_loading = true
	match scene:
		"title":
			m.show_title()
		"town":
			m.in_title = false
			m.new_game(false)
			m.dialog.clear()
			m.player.position = Vector2(200, 176)
		"home":
			m.enter_home()
			m.dialog.clear()
			m.player.position = Vector2(110, 560)   # mid-room, clear of the front door
		"fight":
			if m.location != "outside":
				m.new_game(false)
			m.dialog.clear()
			m.player.position = Vector2(200, 176)
			for i in 4:
				m.spawn_enemy(["scammer", "pirate", "drunk", "scammer"][i], m.player.position + Vector2(18 + i * 6, -8 + i * 6))
		"boss":
			m.clear_enemies()
			m.start_story_fight("gymbro")
			m.dialog.clear()
		"ko":
			if m.arena_boss:
				m.boss_defeated(m.arena_boss)
		"calendar":
			m.no_loading = false
			m.ko_kind = ""
			m.show_calendar()
	m.dialog.clear()

func _drive(scene: String, d: float) -> void:
	walk_t += d
	# ping-pong along a line around where the scene started (random walks wander through doors)
	if f == 1:
		home_pos = m.player.position
	var tgt: Vector2 = home_pos + Vector2(36.0 * walk_dir, 0)
	if m.player.position.distance_to(tgt) < 4.0 or (f % 90 == 0):
		walk_dir = -walk_dir
	var dir: Vector2 = (tgt - m.player.position).normalized()
	if scene in ["town", "home", "fight", "boss"]:
		if m.overlay_node != null:              # level-up cards etc. would hide the scene being measured
			m.close_overlay()
		m.dialog.clear()
		m.player.joy_vec = dir
		m.energy = 100.0
	if scene in ["fight", "boss"] and f % 9 == 0:
		m.player.swing()
	if scene == "fight" and m.get_tree().get_nodes_in_group("enemy").size() < 4 and f % 30 == 0:
		m.spawn_enemy("pirate", m.player.position + Vector2(20, 0))
	if scene == "ko":
		var ko: = _find(game, "res://scripts/knockout.gd")
		if ko and ko.playing():
			ko.bt = minf(ko.bt, 2.0)       # keep the cutscene on screen for the whole window
			if f % 40 == 0:
				ko._next()

func _process(d: float) -> void:
	var now: = Time.get_ticks_usec()
	if m == null:
		f += 1
		if f < 20:
			return
		m = game.get_child(0).get_child(0).get_child(0)
		m.save_path = SANDBOX
		_apply_off()
		f = 0
		_next_scene()
		last_us = now
		return
	f += 1
	if f == WARM:
		cpu0 = _cpu_ms()
	if f > WARM:
		samples.append((now - last_us) / 1000.0)
		proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	last_us = now
	_drive(scenes[si], d)
	if f % 60 == 0:
		print("perf_run: ", scenes[si], " frame ", f)
	if f >= WARM + MEASURE:
		_report(scenes[si])
		_next_scene()

func _next_scene() -> void:
	si += 1
	if si >= scenes.size():
		var fa: = FileAccess.open("/tmp/perf_run%s.txt" % ("_headless" if DisplayServer.get_name() == "headless" else ""), FileAccess.WRITE)
		fa.store_string("\n".join(out) + "\n")
		fa.close()
		if FileAccess.file_exists(SANDBOX):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SANDBOX))
		get_tree().quit()
		return
	f = 0
	samples.clear()
	proc.clear()
	draws.clear()
	_start(scenes[si])

func _pct(a: Array, p: float) -> float:
	var s: = a.duplicate()
	s.sort()
	return s[clampi(int(p * (s.size() - 1)), 0, s.size() - 1)]

func _mean(a: Array) -> float:
	var t: = 0.0
	for v in a:
		t += v
	return t / maxf(1.0, a.size())

func _report(scene: String) -> void:
	var cpu: = float(_cpu_ms() - cpu0) / maxf(1.0, samples.size())
	var line: = "PERF %-8s cpu_ms %6.2f | wall_ms mean %6.2f p50 %6.2f p95 %6.2f | script_ms %5.2f | draws %4d | objects %d | nodes %d | loc %s busy %s" % [
		scene, cpu, _mean(samples), _pct(samples, 0.5), _pct(samples, 0.95), _mean(proc), int(_mean(draws)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), str(m.location), str(m.busy())]
	print(line)
	out.append(line)
