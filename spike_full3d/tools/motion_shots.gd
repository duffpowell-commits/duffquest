extends SceneTree
## Walking and running check (Nov 26 2026, Duff: "the motion looks bad"): Duff strolls, then runs, turns
## back, while Marketplace Mike stalks in. One PNG per frame at a fixed 30 fps of game time:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 --fixed-fps 30 --script tools/motion_shots.gd -- <outdir>
## Make a GIF: ffmpeg -framerate 30 -i <outdir>/m_%04d.png ...

var out := "/tmp/motion_shots"
var n := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("_run")

func _snap() -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/m_%04d.png" % [out, n])
	n += 1

func _hold(v: Vector2) -> void:
	for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(a)
	if v.x > 0: Input.action_press("ui_right", v.x)
	elif v.x < 0: Input.action_press("ui_left", -v.x)
	if v.y > 0: Input.action_press("ui_down", v.y)
	elif v.y < 0: Input.action_press("ui_up", -v.y)

func _run() -> void:
	Engine.set_meta("porch_skip_title", true)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.opening = 0
	s.pirate_hp = 0          # straight to Mike: he walks, stalks and runs at his rage speed
	s.thief.body.hide()
	s.package.hide()
	s.player.position = Vector3(-3.0, 0, 2.6)
	s.boss.arrive()
	s.boss.cool = 99.0       # no sign throws or charges: this is about legs
	for i in 20:
		_hold(Vector2.ZERO)
		await _snap()
	for step in [[Vector2(.45, 0), 45], [Vector2(1, 0), 30], [Vector2(-1, 0), 25], [Vector2(0, -.4), 30], [Vector2.ZERO, 30]]:
		for i in step[1]:
			_hold(step[0])
			s.boss.recovery = 9.0  # he follows and stalks but never jabs
			s.player_hp = s.PLAYER_HP
			await _snap()
	quit()
