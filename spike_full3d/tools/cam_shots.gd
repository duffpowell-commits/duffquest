extends SceneTree
## Camera tests: the same two Mike moments (close, and Mike at range) under candidate cameras.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/cam_shots.gd -- <outdir> <cam>
## cam: now | close | frame | low. Only moves the camera; the game is untouched.

var out := "/tmp/porch_cams"
var cam := "now"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		cam = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("_run")

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.pirate_hp = 0
	s.pirate_model.strike("ko")
	s.pirate.position = Vector3(3.6, 0, 2.6)
	s.player.position = s.package.position
	while s.mike_state == "away":
		await physics_frame
	s.player_hp = 999
	s.set_physics_process(false)
	s.set_process(false)
	s.mike_state = "stalk"
	s.mike_cool = 9.0
	s.message.text = "Mike: Cash only! No lowballers!"
	for shot in [["close", Vector3(-1.0, 0, 1.6), Vector3(.6, 0, 1.3)], ["range", Vector3(-2.2, 0, 1.8), Vector3(2.6, 0, .4)]]:
		s.player.position = shot[1]
		s.mike.position = shot[2]
		s.player_model.rotation.y = -PI / 2
		s.mike_model.rotation.y = PI / 2
		_place(s.camera, s.player.position, s.mike.position)
		await _frames(30)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("%s/cam_%s_%s.png" % [out, cam, shot[0]])
	quit()

func _place(c: Camera3D, duff: Vector3, foe: Vector3) -> void:
	var mid := (duff + foe) * .5
	var sep := duff.distance_to(foe)
	match cam:
		"now":
			c.position.x = clampf(duff.x, -2.6, 2.6)
		"close":  # same high angle, half the distance, follows Duff on both axes
			c.size = 4.4
			c.position = Vector3(duff.x, 0, duff.z) + Vector3(0, 9.6, 13) * .6
			c.look_at(Vector3(duff.x, .55, duff.z - .9 * .6))
		"frame":  # perspective, frames Duff and his foe, zooms out as they separate
			c.projection = Camera3D.PROJECTION_PERSPECTIVE
			c.fov = 32
			var dist := clampf(5.0 + sep * 1.1, 6.0, 11.0)
			var dir := Vector3(0, sin(deg_to_rad(42)), cos(deg_to_rad(42)))
			var aim := mid + Vector3(0, .8, 0)
			c.position = aim + dir * dist
			c.look_at(aim)
		"low":  # brawler: low and side-on, house as the backdrop
			c.projection = Camera3D.PROJECTION_PERSPECTIVE
			c.fov = 38
			var dist := clampf(4.5 + sep * .9, 5.0, 9.0)
			var dir := Vector3(0, sin(deg_to_rad(22)), cos(deg_to_rad(22)))
			var aim := mid + Vector3(0, .9, 0)
			c.position = aim + dir * dist
			c.look_at(aim)
