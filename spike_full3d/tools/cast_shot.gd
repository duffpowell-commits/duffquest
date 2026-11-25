extends SceneTree
## Cast line-up: every rigged body side by side, all playing the same clip at the same moment.
## Proves new bodies share the cast's clips and sit in the same style as Duff and Mike.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x640 --script tools/cast_shot.gd -- <out.png> <clip> [0..1] [heads]
## heads: bone (default, as in the game: height kept, head bone scaled to Duff's) | body (whole body scaled
## to Duff's head size) | off (fitted by height only)

const CAST := [["duff", 1.7], ["mike", 1.65], ["pirate", 1.4], ["sendback", 1.75], ["camper", 1.68],
	["coupon", 1.5], ["allergy", 1.65]]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/cast.png"
	var clip: String = args[1] if args.size() > 1 else "idle"
	var at: float = float(args[2]) if args.size() > 2 else .4
	var heads: String = args[3] if args.size() > 3 else "bone"
	root.msaa_3d = Viewport.MSAA_4X
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.58, .63, .7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.75, .8, .9)
	env.environment.ambient_light_energy = .45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_color = Color(1, .9, .78)
	sun.light_energy = .85
	sun.shadow_enabled = true
	w.add_child(sun)
	var floor := MeshInstance3D.new()
	floor.mesh = PlaneMesh.new()
	(floor.mesh as PlaneMesh).size = Vector2(30, 10)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(.3, .33, .3)
	floor.material_override = fm
	w.add_child(floor)
	var RA = load("res://rig_actor.gd")
	var shown := []
	for c in CAST:
		if ResourceLoader.exists("res://models/%s.glb" % c[0]):
			shown.append(c)
	var gap := 1.25
	for i in shown.size():
		var a = RA.make(w, shown[i][0], shown[i][1])
		a.position = Vector3((i - (shown.size() - 1) * .5) * gap, 0, 0)
		if heads == "body":
			a.fit_body_to_head()
		elif heads == "bone":
			a.fit_head_bone()
		a.rotation.y = PI + deg_to_rad(-10)  # face the camera, a touch side-on
		var name := clip if a.has_clip(clip) else "idle"
		a.current = name
		a.player.play("rig/" + name, 0.0)
		a.player.seek(a.player.get_animation("rig/" + name).length * at, true)
		a.player.pause()
	var cam := Camera3D.new()
	cam.fov = 30
	w.add_child(cam)
	var span := shown.size() * gap
	cam.position = Vector3(0, 1.3, span * 1.2 + 1.0)
	cam.look_at(Vector3(0, .85, 0))
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	print("CAST SHOT ", out, " ", shown.size())
	quit()
