extends SceneTree
## Frames of Red Right Hand (the special) for a preview GIF.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 --script tools/rrh_shots.gd -- <outdir>

var out := "/tmp/porch_rrh"
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

func _run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.set_meta("porch_skip_title", true)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.bubble_time = 0
	s.opening = 0
	s.player.position = Vector3(-2.6, 0, 1.8)
	s.pirate.position = Vector3(.8, 0, 1.2)
	s.pirate_recovery = 99.0
	s.player_hp = 999
	s.meter = 70
	for i in 20:
		await process_frame
	s.facing = (s.pirate.position - s.player.position).normalized()
	s.player_model.rotation.y = atan2(-s.facing.x, -s.facing.z)
	await _grab(10)
	s.meter = 100
	await _grab(14)
	s.pirate.position = Vector3(.8, 0, 1.2)  # he walks in while the meter fills; show the full dash
	s.special_requested = true
	await _grab(64)
	quit()
