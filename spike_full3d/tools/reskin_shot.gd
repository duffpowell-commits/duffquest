extends SceneTree
## Side-by-side of a base body and its free reskin (tools/reskin.py), both in idle, on the porch lawn light.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/reskin_shot.gd -- <out.png> <base> <skin.jpg>

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/reskin.png"
	var base: String = args[1] if args.size() > 1 else "mike"
	var skin: String = args[2] if args.size() > 2 else "res://tools/reskins/sendback_Image_0.jpg"
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#5a4a6a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#8d93c4")
	env.environment.ambient_light_energy = .62
	env.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24, -62, 0)
	sun.light_color = Color("#ffb06a")
	sun.light_energy = 1.55
	world.add_child(sun)
	var Rig = load("res://rig_actor.gd")
	var tex := Image.load_from_file(ProjectSettings.globalize_path(skin))
	for i in 2:
		for view in 2:
			var holder := Node3D.new()
			world.add_child(holder)
			holder.position = Vector3(-2.7 + i * 3.6 + view * 1.5, 0, 0)
			var actor = Rig.make(holder, base, 1.65)
			actor.rotation.y = PI if view == 0 else PI * 1.5
			if i == 1:
				for m in actor.find_children("*", "MeshInstance3D", true, false):
					var mat := (m.get_active_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
					mat.albedo_texture = ImageTexture.create_from_image(tex)
					m.set_surface_override_material(0, mat)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 1.3, 6.2)
	cam.look_at(Vector3(0, .9, 0))
	cam.fov = 40
	cam.make_current()
	for f in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	quit()
