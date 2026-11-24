extends SceneTree
## Scripted 12 s fight for a preview video (real input actions, real clips):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --write-movie /tmp/porch.avi --fixed-fps 30 --script tools/demo.gd

func _initialize() -> void:
	root.size = Vector2i(960, 540)
	call_deferred("_run")

func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)

func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame

func _tap(keycode: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	e.keycode = keycode
	e.pressed = true
	Input.parse_input_event(e)
	await physics_frame
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)

func _run() -> void:
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	s.pirate.position = Vector3(2.6, 0, -.6)
	await _wait(30)
	await _hold("ui_right", 40)
	await _hold("ui_up", 10)
	for i in 3:
		s.facing = (s.pirate.position - s.player.position).normalized()
		s.player_model.rotation.y = atan2(-s.facing.x, -s.facing.z)
		s.attack_requested = true
		await _wait(22)
		if i == 1:
			s.dodge_requested = true
			await _wait(26)
	await _wait(40)
	var to_box: Vector3 = s.package.global_position - s.player.position
	await _hold("ui_right" if to_box.x > 0 else "ui_left", int(absf(to_box.x) / 4.6 * 60))
	await _wait(60)
	quit()
