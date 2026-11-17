extends SceneTree
## Turnaround sheet of a true3d model: 6 poses (front, 3/4, side, back, mid-stride, skillet swing).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/true3d/model_shot.gd -- duff [/tmp/qa/model_duff.png]

func _init() -> void:
	var args: = OS.get_cmdline_user_args()
	var key: String = args[0] if args.size() > 0 else "duff"
	var out: String = args[1] if args.size() > 1 else "/tmp/qa/model_%s.png" % key
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var vp: = SubViewport.new()
	vp.size = Vector2i(1800, 600)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env: = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.68, 0.55)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.ambient_light_energy = 0.7
	var we: = WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun: = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var t3: Node3D = load("res://scripts/view3d/true3d.gd").new()
	vp.add_child(t3)
	var poses: = [[0.0, 0.0, -1.0], [0.7, 0.0, -1.0], [PI / 2, 0.0, -1.0], [PI, 0.0, -1.0], [0.5, 1.0, -1.0], [0.5, 0.0, 0.15]]
	var rigs: = []
	for i in poses.size():
		var r = t3._make(key)
		r.root.position = Vector3((i - 2.5) * 2.4, 0, 0)
		r.yaw = poses[i][0]
		r.turn.rotation.y = r.yaw
		r.walk = poses[i][1]
		r.phase = PI / 2
		r.swing = poses[i][2]
		t3._apply(r)
		rigs.append(r)
	var cam: = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 5.2
	cam.position = Vector3(0, 1.75, 10)
	cam.rotation_degrees.x = -6
	vp.add_child(cam)
	cam.current = true
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
