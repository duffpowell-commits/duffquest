extends SceneTree
## Frames of the combos for a preview GIF: A A A knockdown, A A K launcher, roll -> A dash hook.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 --script tools/combo_shots.gd -- <outdir>

var out := "/tmp/porch_combo"
var n := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("_run")

func _grab(frames: int) -> void:
	for i in frames:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/f%03d.png" % [out, n])
		n += 1

func _reset_target(s, offset: Vector3) -> void:
	s.pirate_hp = s.PIRATE_HP
	s.pirate_recovery = 99.0
	s.combo = 0
	s.player.position = Vector3(-.4, 0, 1.6)
	s.pirate.position = s.player.position + offset
	s.facing = offset.normalized()
	s.player_model.rotation.y = atan2(-s.facing.x, -s.facing.z)
	await _grab(8)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.set_meta("porch_skip_title", true)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.bubble_time = 0
	s.opening = 0
	s.player.position = Vector3(-.4, 0, 1.6)
	s.pirate.position = Vector3(.75, 0, 1.3)
	s.pirate_recovery = 99.0  # a still target for the preview
	s.player_hp = 999
	for i in 20:
		await process_frame
	s.facing = (s.pirate.position - s.player.position).normalized()
	s.player_model.rotation.y = atan2(-s.facing.x, -s.facing.z)
	await _grab(6)
	for beat in 3:  # A A A: knockdown
		s.attack_requested = true
		await _grab(12)
	await _grab(18)
	await _reset_target(s, Vector3(1.05, 0, -.3))
	for beat in 2:  # A A K: launcher
		s.attack_requested = true
		await _grab(12)
	s.kick_requested = true
	await _grab(30)
	await _reset_target(s, Vector3(2.2, 0, -.5))
	s.dodge_requested = true  # roll, then A: dash hook
	await _grab(9)
	s.attack_requested = true
	await _grab(26)
	quit()
