extends SceneTree
## Renders the HUD and menus (porch_hud.gd): fight HUD, pause sheet, title, KO and win cards.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/hud_shots.gd -- <outdir>

var out := "/tmp/porch_hud"

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
	Engine.set_meta("porch_skip_title", false)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.hud.show_title()
	await _frames(30)
	await _snap("hud_1_title")
	s.hud.start()
	s.pirate.position = Vector3(1.4, 0, .6)
	s.player.position = Vector3(-.6, 0, 1.6)
	await _frames(40)
	s.hud.a_down = true
	await _frames(4)
	await _snap("hud_2_fight")
	s.hud.a_down = false
	# Mike's line in the new bubble.
	s.pirate_hp = 0
	s.pirate.hide()
	s.player.position = s.package.position
	while s.mike_state == "away":
		await physics_frame
	s.set_physics_process(false)
	s.player.position = Vector3(-1.4, 0, 1.8)
	s.mike.position = Vector3(1.6, 0, 1.0)
	s.mike_hp = 5
	s._say(s.mike, "Cash only! No lowballers!", 30.0)
	await _frames(20)
	await _snap("hud_3_mike")
	s.hud.open_pause()
	await _frames(6)
	await _snap("hud_4_pause")
	s.hud.close_menu()
	s.hud.show_end(false)
	await _frames(6)
	await _snap("hud_5_ko")
	s.result = {"grade": "A", "time": 72.0, "hits": 2, "specials": 2, "best_grade": "A", "best_time": 64.0, "new_best": false}
	s.hud.show_end(true)
	await _frames(6)
	await _snap("hud_6_win")
	quit()
