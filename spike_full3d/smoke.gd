extends SceneTree

const PORCH := "res://porch.tscn"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(result: bool, title: String) -> void:
	if result:
		print("PASS: " + title)
	else:
		failures += 1
		push_error("FAIL: " + title)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	change_scene_to_file(PORCH)
	await scene_changed
	await _frames(2)
	var sample = current_scene
	_check(sample.player is CharacterBody3D and sample.pirate is CharacterBody3D
		and root.get_camera_3d() is Camera3D, "3D actors and camera")
	_check(sample.package.get_parent() == sample.pirate_model, "parcel starts in pirate grip")

	# Walk freely on both axes, then walk into and dodge against the planter.
	sample.pirate.position = Vector3(-5, 0, -2)
	var start: Vector3 = sample.player.position
	Input.action_press("ui_right")
	Input.action_press("ui_up")
	await _frames(12)
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	_check(sample.player.position.x > start.x + .45 and sample.player.position.z < start.z - .45
		and absf(sample.player.position.y) < .1, "diagonal keyboard movement on the ground")

	sample.player.position = sample.PLANTER_AT + Vector3(0, 0, 1.8)
	Input.action_press("ui_up")
	await _frames(34)
	var edge: float = sample.PLANTER_AT.z + sample.PLANTER_SIZE.z * .5 + .34
	_check(absf(sample.player.position.z - edge) < .035, "walking stops at the planter")
	sample._dodge()
	await _frames(16)
	Input.action_release("ui_up")
	_check(absf(sample.player.position.z - edge) < .035, "dodging stops at the planter")

	sample.set_physics_process(false)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	await _frames(2)
	sample.facing = Vector3.BACK
	sample.attack_time = 0
	sample._attack()
	_check(sample.pirate_hp == 3, "wrong-facing attack misses")
	sample.facing = Vector3.FORWARD
	sample.pirate.position = Vector3(0, 0, -.1)
	sample.attack_time = 0
	sample._attack()
	_check(sample.pirate_hp == 3, "out-of-range attack misses")

	# A short diagonal through the corner is in reach of both actors.
	var corner: Vector3 = sample.PLANTER_AT + Vector3(sample.PLANTER_SIZE.x, 0, sample.PLANTER_SIZE.z) * .5
	sample.player.position = corner + Vector3(.34, 0, -.36)
	sample.pirate.position = corner + Vector3(-.36, 0, .34)
	sample.facing = (sample.pirate.position - sample.player.position).normalized()
	sample.attack_time = 0
	sample.pirate_recovery = 0
	sample.invulnerable = 0
	await _frames(2)
	sample._attack()
	sample._tick_pirate()
	_check(sample.pirate_hp == 3 and sample.player_hp == 5,
		"planter blocks in-range strikes from Duff and the pirate")

	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.facing = Vector3.FORWARD
	sample.dodge_recovery = 0
	sample._dodge()
	await _frames(2)
	sample._tick_pirate()
	sample.attack_time = 0
	sample._attack()
	_check(sample.player_hp == 5 and sample.pirate_hp == 3,
		"dodge grants brief invulnerability and cancels attacking")

	sample.pirate.position = Vector3(-5, 0, -2)
	sample.player.position = Vector3(-2, 0, 2)
	sample.set_physics_process(true)
	var before_dodge: Vector3 = sample.player.position
	await _frames(8)
	_check(sample.player.position.z < before_dodge.z - .8, "dodge moves Duff through clear space")
	await _frames(45)
	_check(sample.dodge_recovery == 0 and sample.invulnerable == 0, "dodge cooldown and immunity expire")

	sample.set_physics_process(false)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.facing = Vector3.FORWARD
	sample.pirate_recovery = 0
	await _frames(2)
	sample._tick_pirate()
	_check(sample.player_hp == 4, "unobstructed pirate attack damages Duff")
	for expected in [2, 1, 0]:
		sample.attack_time = 0
		sample._attack()
		_check(sample.pirate_hp == expected, "unobstructed Duff attack brings pirate HP to %d" % expected)
	_check(sample.package.get_parent() == sample and sample.package.visible
		and not sample.pirate.visible and sample.pirate.collision_layer == 0,
		"defeated pirate drops the visible parcel and clears actor collision")
	sample.player.position = sample.package.position
	sample.set_physics_process(true)
	await _frames(3)
	_check(not sample.active and not sample.package.visible, "walking over the parcel recovers it and wins")

	sample._reset()
	await scene_changed
	sample = current_scene
	_check(sample.active and sample.player_hp == 5 and sample.pirate_hp == 3
		and sample.pirate.visible and sample.package.visible and sample.package.get_parent() == sample.pirate_model,
		"retry restores actors, health, and held parcel")
	sample.set_physics_process(false)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.player_hp = 1
	await _frames(2)
	sample._tick_pirate()
	_check(sample.player_hp == 0 and not sample.active, "last pirate hit ends the encounter in defeat")
	sample._reset()
	await scene_changed
	_check(current_scene.active and current_scene.player_hp == 5, "retry after defeat restores Duff")
	quit(1 if failures else 0)
