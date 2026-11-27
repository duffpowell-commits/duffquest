extends SceneTree
## Launch with --script tools/kitchen_preview_shot.gd -- <output directory>.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.msaa_3d = Viewport.MSAA_4X
	var scene = load("res://kitchen_preview.tscn").instantiate()
	root.add_child(scene)
	var stations := {"Grill": Vector3(-4.35, 0, -2.55), "Fryer": Vector3(-2.55, 0, -2.55), "Saute": Vector3(-.7, 0, -2.55), "ColdPrep": Vector3(1.8, 0, -1.94), "Pass": Vector3(3, 0, 2.19)}
	for station in stations:
		var node = scene.get_node_or_null(station)
		if node == null or not node.position.is_equal_approx(stations[station]):
			push_error("Missing or moved station: " + station)
			quit(1)
			return
	var cast_positions := {"Duff": Vector3(-2.5, 0, 1), "Sendback": Vector3(-4.25, 0, -.85), "Camper": Vector3(-1, 0, -1), "Coupon": Vector3(.3, 0, .65), "Allergy": Vector3(4.45, 0, -.7)}
	for who in cast_positions:
		var actor = scene.get_node_or_null(who)
		if actor == null or actor.skeleton == null or not actor.has_clip("idle") or not actor.position.is_equal_approx(cast_positions[who]) or not is_equal_approx(actor.rotation.y, -2.65):
			push_error("Missing or moved approved rig: " + who)
			quit(1)
			return
	if not scene.find_children("*", "CollisionObject3D", true, false).is_empty():
		push_error("Unexpected new collision in visual-only preview")
		quit(1)
		return
	var batches = scene.get_node_or_null("StaticVisualBatches")
	if batches == null or batches.get_child_count() > 32 or batches.get_child_count() < 5:
		push_error("Static batching missing or above material budget")
		quit(1)
		return
	for item in batches.get_children():
		if not item.mesh or item.mesh.get_surface_count() != 1:
			push_error("Empty static material batch")
			quit(1)
			return
	print("PASS unchanged station/actor transforms; no new collisions; %d static material batches" % batches.get_child_count())
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
