extends SceneTree
## Launch with --script tools/kitchen_preview_shot.gd -- <output directory>.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.msaa_3d = Viewport.MSAA_4X
	var scene = load("res://kitchen_preview.tscn").instantiate()
	root.add_child(scene)
	for station in ["Grill", "Fryer", "Saute", "ColdPrep", "Pass"]:
		if not scene.has_node(station):
			push_error("Missing station: " + station)
			quit(1)
			return
	for who in ["Duff", "Sendback", "Camper", "Coupon", "Allergy"]:
		var actor = scene.get_node_or_null(who)
		if actor == null or actor.skeleton == null or not actor.has_clip("idle"):
			push_error("Missing approved rig: " + who)
			quit(1)
			return
	print("PASS kitchen stations and five existing idle rigs")
	if DisplayServer.get_name() == "headless":
		quit()
		return
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Provide screenshot output directory")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(args[0].path_join("kitchen-overview.png"))
	if result != OK:
		quit(1)
		return
	scene.camera.position = Vector3(-4, 8, 12)
	scene.camera.size = 9.5
	scene.camera.look_at(Vector3(0, .9, -.35))
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	result = root.get_texture().get_image().save_png(args[0].path_join("kitchen-reverse.png"))
	quit(0 if result == OK else 1)
