extends SceneTree
## Close renders of Duff's hands in the rest pose (checks the tattoo masters landed right).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/hands_shot.gd -- <outdir>

func _initialize() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/porch_shots"
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(900, 900)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#6a5a66")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .9
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	world.add_child(sun)
	var body: Node3D = (load("res://models/duff.glb") as PackedScene).instantiate()
	world.add_child(body)
	var anim := body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	anim.stop()
	var skel := body.find_child("Skeleton3D", true, false) as Skeleton3D
	skel.reset_bone_poses()
	var cam := Camera3D.new()
	cam.fov = 28
	world.add_child(cam)
	cam.make_current()
	_shoot.call_deferred(skel, cam, out)

func _shoot(skel: Skeleton3D, cam: Camera3D, out: String) -> void:
	await process_frame
	for side in ["LeftHand", "RightHand"]:
		var hand := skel.global_transform * skel.get_bone_global_rest(skel.find_bone(side))
		var p := hand.origin
		var outward := Vector3(signf(p.x), 0, 0)
		var i := 0
		for dir in [outward, (outward + Vector3.FORWARD * .8).normalized(), (outward + Vector3.BACK * .8).normalized()]:
			cam.position = p + dir * .42 + Vector3.DOWN * .06
			cam.look_at(p + Vector3.DOWN * .07)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/hands_%s_%d.png" % [out, side, i])
			i += 1
	quit()
