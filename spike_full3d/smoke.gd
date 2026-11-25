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
	var props := {}
	for child in sample.get_children():
		if child.has_meta("set_prop"):
			var key: String = child.get_meta("set_prop")
			props[key] = props.get(key, 0) + 1
	_check(props.get("house", 0) == 1 and props.get("fence", 0) == 10 and props.get("tree", 0) == 2
		and props.get("bush", 0) == 4 and props.get("planter", 0) == 1 and props.get("mailbox", 0) == 1,
		"the Meshy set is dressed: house, 10 fence panels, 2 trees, 4 bushes, planter, mailbox (%s)" % props)
	var look = sample.look
	var outlined := 0
	for actor in [sample.player_model, sample.pirate_model, sample.mike_model]:
		var mesh: MeshInstance3D = actor.find_children("*", "MeshInstance3D", true, false)[0]
		var mat := mesh.get_active_material(0) as StandardMaterial3D
		if mat and mat.rim_enabled and mat.next_pass is ShaderMaterial and actor.get_parent().has_node("ContactShadow"):
			outlined += 1
	_check(look != null and outlined == 3 and sample.has_node("Vignette"),
		"golden hour look: every fighter has rim, ink outline and a contact shadow; vignette on")
	_check(look.env.glow_enabled and sample.get_viewport().msaa_3d == Viewport.MSAA_4X, "golden hour starts with glow and MSAA")
	look.set_lite(true)
	_check(not look.env.glow_enabled and sample.get_viewport().msaa_3d == Viewport.MSAA_DISABLED, "lite drops glow and MSAA")
	look.set_lite(false)
	sample.fight_cam.snap(sample.player.position, sample.pirate.position)
	var cam: Camera3D = sample.camera
	var view := sample.get_viewport().get_visible_rect().size
	var framed := true
	for body in [sample.player, sample.pirate]:
		var p := cam.unproject_position(body.position + Vector3.UP * .8)
		framed = framed and p.x > view.x * .08 and p.x < view.x * .92 and p.y > view.y * .1 and p.y < view.y * .9
	var feet := cam.unproject_position(sample.player.position)
	var head := cam.unproject_position(sample.player.position + Vector3.UP * sample.DUFF_HEIGHT)
	_check(framed and feet.y - head.y > view.y * .25,
		"fight camera frames Duff and the pirate; Duff stands %d%% of the screen tall" % int((feet.y - head.y) / view.y * 100))
	sample.mike.position = sample.player.position + Vector3(4.5, 0, -1)
	var near_tf: Transform3D = sample.fight_cam.goal(sample.player.position, sample.player.position + Vector3(1, 0, 0))
	var far_tf: Transform3D = sample.fight_cam.goal(sample.player.position, sample.mike.position)
	_check(far_tf.origin.distance_to(sample.player.position) > near_tf.origin.distance_to(sample.player.position),
		"fight camera pulls back when the foe is far")
	sample.mike.position = sample.MIKE_SPAWN
	var corners_ok := true
	for spot in [[Vector3(-6.4, 0, 4.9), null], [Vector3(6.4, 0, 0), null], [Vector3(0, 0, 4.9), null],
			[Vector3(-6.4, 0, 3), sample.MIKE_SPAWN], [Vector3(6.4, 0, -2.2), Vector3(-6.4, 0, 4.9)]]:
		cam.global_transform = sample.fight_cam.goal(spot[0], spot[1])
		for body in ([spot[0]] if spot[1] == null else [spot[0], spot[1]]):
			for y in [0.0, 1.8]:
				var q := cam.unproject_position(body + Vector3.UP * y)
				corners_ok = corners_ok and q.x >= 0 and q.x <= view.x and q.y >= 0 and q.y <= view.y
	_check(corners_ok, "fight camera keeps Duff (and his foe) fully on screen at the fences and the street edge")
	for actor in [sample.player_model, sample.pirate_model]:
		_check(actor.skeleton.get_bone_count() == 24 and actor.skeleton.find_bone("RightHand") >= 0,
			"%s is a skinned mesh on the 24-bone humanoid skeleton" % actor.name)
		var clips := ["idle", "walking", "running", "jab", "hit", "ko"]
		if actor == sample.player_model:
			clips += ["hook", "dodge"]
		_check(clips.all(func(c): return actor.has_clip(c)), "%s has real clips %s" % [actor.name, clips])
		_check(actor.current in ["idle", "walking"] and actor.player.is_playing(), "%s starts in an idle or walk clip" % actor.name)

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
	var edge: float = sample.PLANTER_AT.z + sample.PLANTER_SIZE.z * .5 + sample.DUFF_RADIUS
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
	sample.player.position = corner + Vector3(.3, 0, -.5)  # 1.13 apart, inside both reaches,
	sample.pirate.position = corner + Vector3(-.5, 0, .3)  # the line between crosses the planter
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
	_check(sample.player_model.current in ["jab", "hook"], "Duff's attack plays a jab or hook clip")
	_check(sample.package.get_parent() == sample and sample.package.visible
		and sample.pirate_model.current == "ko" and sample.pirate.collision_layer == 0,
		"defeated pirate plays its KO clip, drops the visible parcel and clears actor collision")
	_check(not sample.mike.visible and sample.mike.collision_layer == 0 and sample.mike_state == "away",
		"Marketplace Mike waits off-screen during the pirate fight")
	_check(sample.feel.trauma > 0 and sample.feel.knock_of(sample.player) != Vector3.ZERO,
		"landed and taken hits shake the camera and knock fighters back")
	await create_timer(.4, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "hit-stop lets go of the world")
	sample.player_hp = 2
	sample.player.position = sample.package.position
	sample.set_physics_process(true)
	await _frames(3)
	_check(sample.active and not sample.package.visible and sample.mike.visible
		and sample.mike_state == "stalk" and sample.player_hp == 5,
		"grabbing the parcel brings Marketplace Mike in and refills Duff")
	var mm = sample.mike_model
	_check(mm.skeleton.get_bone_count() == 24 and ["idle", "walking", "running", "jab", "throw", "charge", "taunt", "hit", "ko"].all(
		func(c): return mm.has_clip(c)), "Mike is on the 24-bone skeleton with jab, throw, charge, taunt, hit and KO clips")

	# Posting: wind-up plays the throw clip, then the OBO sign flies and lands on a Duff who stays put.
	sample.set_physics_process(false)
	sample.player.position = Vector3(-1.5, 0, 2)
	sample.mike.position = Vector3(2, 0, 2)
	sample.invulnerable = 0
	sample.dodge_time = 0
	sample.charge_next = false
	sample.mike_cool = 0
	await _frames(2)
	sample._tick_mike(.016)
	_check(sample.mike_state == "post" and mm.current == "throw", "Mike winds up a sign throw from range")
	sample._tick_mike(sample.POST_TELE + .01)
	_check(sample.obo_sign.visible, "the OBO sign leaves his hand")
	for i in 40:
		sample._tick_sign(1.0 / 60)
	_check(sample.player_hp == 4 and not sample.obo_sign.visible, "a sign that reaches Duff costs one HP")

	# Dodging through the sign: immunity means no damage.
	sample.mike_state = "stalk"
	sample.mike_cool = 0
	sample.charge_next = false
	sample._tick_mike(.016)
	sample._tick_mike(sample.POST_TELE + .01)
	sample.invulnerable = 1.0
	for i in 40:
		sample._tick_sign(1.0 / 60)
	_check(sample.player_hp == 4 and sample.obo_sign.position.x < sample.player.position.x - .3,
		"dodge immunity lets the sign fly past harmlessly")

	# Charge: telegraph, then a straight rush that hits Duff and leaves Mike dizzy.
	sample.invulnerable = 0
	sample.mike_state = "stalk"
	sample.mike_cool = 0
	sample.charge_next = true
	sample.player.position = Vector3(-1.5, 0, 2)
	sample.mike.position = Vector3(2, 0, 2)
	await _frames(2)
	sample._tick_mike(.016)
	_check(sample.mike_state == "charge_tele", "Mike telegraphs his charge")
	sample._tick_mike(sample.CHARGE_TELE + .01)
	_check(sample.mike_state == "charge" and mm.current == "charge", "the charge plays its run clip")
	for i in 40:
		if sample.mike_state != "charge":
			break
		sample._tick_mike(1.0 / 60)
		await physics_frame
	_check(sample.player_hp == 3 and sample.mike_state == "dizzy", "the charge hits Duff and leaves Mike dizzy")

	# A charge into the fence bonks him too.
	sample.invulnerable = 0
	sample.mike_state = "charge"
	sample.mike_timer = 2.0
	sample.charge_dir = Vector3.RIGHT
	sample.mike.position = Vector3(5.5, 0, 0)
	sample.player.position = Vector3(-3, 0, 2)
	await _frames(2)
	for i in 60:
		if sample.mike_state != "charge":
			break
		sample._tick_mike(1.0 / 60)
		await physics_frame
	_check(sample.mike_state == "dizzy" and sample.mike.position.x < 6.6 and sample.player_hp == 3,
		"a charge into the fence stops at the fence and leaves him dizzy")

	# Beat him: halfway he rages (taunt), then KO wins the encounter.
	sample.mike_state = "dizzy"
	sample.mike_timer = 5.0
	sample.player.position = Vector3(0, 0, 2)
	sample.mike.position = Vector3(0, 0, 1)
	sample.facing = Vector3.FORWARD
	await _frames(2)
	for i in 3:
		sample.attack_time = 0
		sample._attack()
	_check(sample.mike_hp == 3 and sample.mike_raged and sample.mike_state == "taunt" and mm.current == "taunt",
		"at half health Mike rages with his taunt")
	sample.mike_timer = 5.0
	for i in 3:
		sample.attack_time = 0
		sample._attack()
	_check(sample.mike_hp == 0 and mm.current == "ko" and not sample.active and sample.mike.collision_layer == 0,
		"Mike's KO clip plays and the porch is secured")

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
