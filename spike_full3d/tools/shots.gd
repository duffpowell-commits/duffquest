extends SceneTree
## Real engine renders of the slice: gameplay frames + a close turnaround of each character.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/shots.gd -- <outdir>
## Prints the average frame time of a scripted fight so a cheap CPU build can be compared.

var out := "/tmp/porch_shots"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _run() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.pirate.position = Vector3(1.6, 0, .2)
	s.player_hp = 999  # renders only: keep Duff standing through the scripted fight
	await _frames(20)
	await _snap("01_idle")
	Input.action_press("ui_right")
	await _frames(14)
	await _snap("02_walk")
	Input.action_release("ui_right")
	s.player.position = s.pirate.position + Vector3(-.9, 0, .1)
	s.facing = Vector3.RIGHT
	s.player_model.rotation.y = -PI / 2
	s.attack_time = 0
	s._attack()
	await _frames(7)
	await _snap("03_jab")
	await _frames(25)
	s.attack_time = 0
	s._attack()
	await _frames(8)
	await _snap("04_hook")
	await _frames(30)
	s._dodge()
	await _frames(6)
	await _snap("05_dodge")
	await _frames(40)
	s.attack_time = 0
	s._attack()
	await _frames(70)
	await _snap("06_pirate_ko")
	# Frame time over a busy stretch.
	var t0 := Time.get_ticks_usec()
	for i in 120:
		await process_frame
	print("AVG FRAME MS %.2f" % ((Time.get_ticks_usec() - t0) / 120000.0))
	# Turnarounds.
	var cam := Camera3D.new()
	s.add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 30
	cam.make_current()
	s.set_physics_process(false)
	s.get_node("CanvasLayer").hide() if s.has_node("CanvasLayer") else null
	for layer in s.find_children("*", "CanvasLayer", true, false):
		layer.hide()
	s.player.position = Vector3(-2.5, 0, 1.5)
	s.pirate.position = Vector3(2.5, 0, 1.5)
	for who in [s.player_model, s.pirate_model]:
		who.rotation.y = 0
		who.locked = 0
		who.play("idle", true)
		who.player.speed_scale = 0.0
		var base: Vector3 = who.global_position
		for i in 4:
			var a := i * PI / 2
			cam.position = base + Vector3(sin(a) * 4.2, 1.1, cos(a) * 4.2)
			cam.look_at(base + Vector3.UP * .85)
			await _frames(2)
			await _snap("turn_%s_%d" % [who.name.to_lower(), i])
		# Hands close-up (backs of both hands).
		for side in ["LeftHand", "RightHand"]:
			var bone: Transform3D = who.skeleton.global_transform * who.skeleton.get_bone_global_pose(who.skeleton.find_bone(side))
			var p := bone.origin
			var out_dir := (p - (base + Vector3.UP * p.y)).normalized()
			cam.position = p + out_dir * .55 + Vector3.UP * .05
			cam.look_at(p)
			await _frames(2)
			await _snap("hand_%s_%s" % [who.name.to_lower(), side])
	quit()
