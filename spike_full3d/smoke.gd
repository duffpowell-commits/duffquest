extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var sample = (load("res://porch.tscn") as PackedScene).instantiate()
	root.add_child(sample)
	await physics_frame
	await physics_frame
	assert(sample.player is CharacterBody3D and sample.pirate is CharacterBody3D)
	assert(sample.get_viewport().get_camera_3d() is Camera3D)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	await physics_frame
	sample.facing = Vector3.BACK
	sample._attack()
	assert(sample.pirate_hp == 3)
	sample.facing = Vector3.FORWARD
	for expected in [2, 1, 0]:
		sample.attack_time = 0
		sample._attack()
		assert(sample.pirate_hp == expected)
	assert(sample.package.get_parent() == sample)
	sample.player.position = sample.package.position
	await physics_frame
	await physics_frame
	assert(not sample.active and not sample.package.visible)
	print("PASS: 3D actors and camera, attack facing, three hits, parcel drop and recovery")
	quit()
