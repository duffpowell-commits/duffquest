extends SceneTree
## Actual renderer comparison: -- <absolute output directory> <before|after>
const VIEWS := [
	["elevated", Vector3(8, 9, 12), Vector3(0, 1.05, -.25), 10.1],
	["lower", Vector3(5, 5, 13), Vector3(0, 1.0, -.2), 8.7],
	["grill", Vector3(-2.3, 4.4, 2.5), Vector3(-3.45, 1.35, -2.5), 3.8],
	["pass", Vector3(6, 4, 7), Vector3(3, 1.2, 2.19), 3.7],
	["character", Vector3(.3, 2.7, 6), Vector3(-2.5, .95, 1), 2.7],
]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.msaa_3d = Viewport.MSAA_DISABLED
	var scene = load("res://kitchen_preview.tscn").instantiate()
	root.add_child(scene)
	for who in ["Duff", "Sendback", "Camper", "Coupon", "Allergy"]:
		var actor = scene.get_node(who)
		actor.player.seek(.4, true)
		actor.player.pause()
	DirAccess.make_dir_recursive_absolute(args[0])
	for view in VIEWS:
		scene.camera.position = view[1]
		scene.camera.look_at(view[2])
		scene.camera.size = view[3]
		for i in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(args[0].path_join(args[1] + "-" + view[0] + ".png")) != OK:
			quit(1)
			return
	# Benchmark elevated angle, actual elapsed wall time including GPU completion.
	scene.camera.position = VIEWS[0][1]
	scene.camera.look_at(VIEWS[0][2])
	scene.camera.size = VIEWS[0][3]
	for who in ["Duff", "Sendback", "Camper", "Coupon", "Allergy"]:
		scene.get_node(who).player.play("rig/idle")
	for i in 8:
		await process_frame
		await RenderingServer.frame_post_draw
	var start := Time.get_ticks_usec()
	var frames := 60
	for i in frames:
		await process_frame
		await RenderingServer.frame_post_draw
	var elapsed := (Time.get_ticks_usec() - start) / 1000000.0
	print("BENCHMARK %s: %.2f FPS, %.2f ms/frame; draws %d, primitives %d" % [args[1], frames / elapsed, elapsed * 1000 / frames, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	if args[1] == "after":
		# The lower whole-room composition is checked against the old controls, without wiring any controls.
		scene.camera.position = VIEWS[1][1]
		scene.camera.look_at(VIEWS[1][2])
		scene.camera.size = VIEWS[1][3]
		var guide := HudGuide.new()
		root.add_child(guide)
		for i in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(args[0].path_join("after-lower-hud-guide.png")) != OK:
			quit(1)
			return
		# Preserve the lower pitch but pull back and shift the room left of the right thumb area.
		scene.camera.position = VIEWS[1][1] + Vector3(1.75, 0, 0)
		scene.camera.look_at(VIEWS[1][2] + Vector3(1.75, 0, 0))
		scene.camera.size = 12.4
		guide.hide()
		for i in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(args[0].path_join("after-mobile-safe.png")) != OK:
			quit(1)
			return
		guide.show()
		for i in 4:
			await process_frame
			await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(args[0].path_join("after-mobile-safe-hud-guide.png")) != OK:
			quit(1)
			return
	quit()

## Read-only diagnostic overlay, using the real porch HUD footprints. Not gameplay.
class HudGuide extends Node2D:
	func _draw() -> void:
		var hud = load("res://porch_hud.gd")
		draw_set_transform(Vector2.ZERO, 0, get_viewport_rect().size / Vector2(960,540))
		var fill := Color(.05,.10,.16,.45)
		var line := Color(.95,.76,.30,.9)
		for entry in [[hud.A_AT,hud.A_R],[hud.B_AT,hud.B_R],[hud.K_AT,hud.K_R],[hud.R_AT,hud.R_R]]:
			draw_circle(entry[0],entry[1],fill)
			draw_arc(entry[0],entry[1],0,TAU,48,line,2,true)
		for rect in [hud.STRIP,hud.GOAL,hud.PLATE,hud.PAUSE]:
			draw_rect(rect,fill)
			draw_rect(rect,line,false,2)
		draw_circle(Vector2(132,384),64,fill)
		draw_arc(Vector2(132,384),64,0,TAU,48,line,2,true)
		draw_string(ThemeDB.fallback_font,Vector2(20,525),"HUD footprint guide only - not gameplay",HORIZONTAL_ALIGNMENT_LEFT,-1,16,line)
