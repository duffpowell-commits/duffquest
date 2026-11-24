extends SceneTree
## One frame per clip at 0 / 33 / 66 % of its length, to eyeball a new character's clips.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/clip_sheet.gd -- <who> <outdir>

const RigActor = preload("res://rig_actor.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var who: String = args[0] if args.size() > 0 else "mike"
	var out: String = args[1] if args.size() > 1 else "/tmp/clip_sheet"
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(400, 500)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#6a5a66")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	world.add_child(sun)
	var actor = RigActor.make(world, who, 1.7)
	var cam := Camera3D.new()
	cam.fov = 35
	world.add_child(cam)
	cam.look_at_from_position(Vector3(1.6, 1.2, -3.6), Vector3(0, .85, 0))
	cam.make_current()
	_shoot.call_deferred(actor, out, who)

func _shoot(actor, out: String, who: String) -> void:
	for clip in actor.player.get_animation_library("rig").get_animation_list():
		var length: float = actor.player.get_animation("rig/" + clip).length
		for i in 3:
			actor.player.play("rig/" + clip, 0)
			actor.player.seek(length * i / 3.0, true)
			actor.player.speed_scale = 0
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("%s/%s_%s_%d.png" % [out, who, clip, i])
	quit()
