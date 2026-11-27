extends SceneTree
## Capture only the visual preview; no HUD or production gameplay.
const VIEWS := [
	["full", Vector3(-5.12, 2.92, 2.8), Vector3(.2, .70, -.8), 82.0],
	["gameplay", Vector3(-4.95, 2.98, 2.55), Vector3(-.15, .62, -.95), 80.0],
	["grill", Vector3(-3.12, 2.25, -.7), Vector3(-4.25, 1.27, -2.53), 54.0],
	["dining", Vector3(-1.75, 2.45, -1.2), Vector3(1.1, 1.25, 5.1), 75.0],
	["character", Vector3(-3.65, 1.65, -1.0), Vector3(-2.5, .88, 1), 51.0],
]
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or DisplayServer.get_name() == "headless":
		quit(1)
		return
	var scene = load("res://kitchen_preview.tscn").instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute(args[0])
	for view in VIEWS:
		scene.set_view(view[1],view[2],view[3])
		for i in 5:
			await process_frame
			await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(args[0].path_join(view[0]+".png")) != OK:
			quit(1)
			return
		print("CAPTURE ",view[0])
	scene.set_view(VIEWS[1][1],VIEWS[1][2],VIEWS[1][3])
	var start := Time.get_ticks_usec()
	for i in 60:
		await process_frame
		await RenderingServer.frame_post_draw
	print("Desktop benchmark: %.2f FPS; draws %d; primitives %d" % [60000000.0/(Time.get_ticks_usec()-start),RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	quit()
