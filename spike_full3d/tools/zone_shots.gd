extends SceneTree
## Renders for walkable zones + clock lighting (Phase 2 step 3):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/zone_shots.gd -- <outdir> [walk]
## Writes porch_<time>.png and home_<time>.png at four times of day. With `walk`, also writes
## walk_####.png frames: Duff walks up the stoop, through the door, and across the apartment.

var out := "/tmp/zone_shots"
var walk := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	walk = args.has("walk")
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _set_time(s, minute: int) -> void:
	s.hud.clock_start = minute
	s.hud.minutes = 0
	s.look.daylight(minute)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.set_meta("porch_skip_title", true)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s._start_exploring()
	if walk:
		await _walk(s)
		quit()
		return
	for spot in [["porch", Vector3(-1.2, 0, 1.0)], ["home", Vector3(-.4, 0, .2)]]:
		s.zones.arrive("porch" if spot[0] == "porch" else "apartment", spot[1])
		s.player_model.rotation.y = 0.5
		for t in [["0800", 480], ["1200", 720], ["1730", 1050], ["2130", 1290]]:
			_set_time(s, t[1])
			await _frames(30)
			await _snap("%s_%s" % [spot[0], t[0]])
	quit()

## Porch (golden hour) -> up to the stoop door -> fade -> HOME -> over to the couch, then the kitchen.
## Steers with the stick actions toward waypoints, so it follows the same path however slow the render is.
func _walk(s) -> void:
	_set_time(s, 1050)
	s.zones.arrive("porch", Vector3(-2.2, 0, 2.6))
	await _frames(20)
	var n := [0]
	for target in [Vector3(-.2, 0, .4), Vector3(0, 0, -2.3)]:
		await _go(s, target, n)
	while s.zones.zone != "apartment" or s.zones.moving:  # the fade card
		_hold(Vector2.ZERO)
		await process_frame
		await _snap("walk_%04d" % n[0])
		n[0] += 1
	for target in [Vector3(-2.1, 0, .2), Vector3(-2.1, 0, -1.9), Vector3(-1.0, 0, -1.9), Vector3(1.6, 0, -1.3), Vector3(1.0, 0, .2)]:
		await _go(s, target, n)
	_hold(Vector2.ZERO)
	for i in 10:
		await process_frame
		await _snap("walk_%04d" % n[0])
		n[0] += 1

func _go(s, target: Vector3, n: Array) -> void:
	for i in 400:
		var to: Vector3 = target - s.player.position
		to.y = 0
		if to.length() < .2 or s.zones.moving:
			return
		var dir := to.normalized()
		_hold(Vector2(dir.x, dir.z))
		await process_frame
		if i % 2 == 0:
			await _snap("walk_%04d" % n[0])
			n[0] += 1

func _hold(v: Vector2) -> void:
	for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(a)
	if v.x > 0:
		Input.action_press("ui_right", v.x)
	elif v.x < 0:
		Input.action_press("ui_left", -v.x)
	if v.y > 0:
		Input.action_press("ui_down", v.y)
	elif v.y < 0:
		Input.action_press("ui_up", -v.y)
