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

## A press that isn't part of a combo: the swing is over, no rhythm going, no roll just before.
func _plain(sample) -> void:
	sample.attack_time = 0
	sample.combo = 0
	sample.combo_broken = false
	sample.last_dodge = -99.0
	sample.kick_cool = 0

## The next press in rhythm: the swing is over and it comes .4 s after the last hit.
func _beat(sample) -> void:
	sample.clock += .4
	sample.attack_time = 0

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
	_check(not look.env.glow_enabled and sample.get_viewport().msaa_3d == Viewport.MSAA_DISABLED
		and sample.get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_NEAREST and sample.get_viewport().scaling_3d_scale < 1.0,
		"lite drops glow and MSAA and draws the 3D at 3/4 size, nearest-scaled")
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

	# HUD + menus in the main game's style (porch_hud.gd).
	var hud = sample.hud
	_check(hud != null and hud.screen == "" and sample.foe_status() == ["Porch Pirate", sample.PIRATE_HP, sample.PIRATE_HP]
		and sample.bubble_name.text == "Duff" and hud.clock_text() == "7:00 AM",
		"HUD up with the pirate's plate, 7:00 AM, and Duff opens the fight")
	_check(hud.find_child("Pause", true, false) is TouchScreenButton and Rect2(hud.PAUSE).end.x <= view.x,
		"phone-style pause button on screen")
	hud.open_pause()
	_check(paused and hud.screen == "pause" and hud.menu.find_children("*", "Button", true, false).size() == 5,
		"pause sheet: Resume, Retry, Graphics, Sound, Quit to title; the fight stops")
	hud.close_menu()
	_check(not paused and hud.screen == "", "Resume closes the sheet and the fight runs again")

	# Phone controls: a 4.7 VirtualJoystick on the left, big round HIT and DODGE on the right.
	_check(sample.stick is VirtualJoystick and sample.stick.action_left == &"ui_left"
		and sample.stick.joystick_mode == VirtualJoystick.JOYSTICK_DYNAMIC, "the stick is Godot 4.7's VirtualJoystick, dynamic")
	var hit_btn: TouchScreenButton = sample.find_child("Attack", true, false)
	var dodge_btn: TouchScreenButton = sample.find_child("Dodge", true, false)
	var hit_box := Rect2(hit_btn.position, hit_btn.shape.size)
	var dodge_box := Rect2(dodge_btn.position, dodge_btn.shape.size)
	_check(hit_box.size.x >= 120 and dodge_box.size.x >= 90 and not hit_box.grow(8).intersects(dodge_box)
		and hit_box.end.x <= view.x and hit_box.end.y <= view.y, "HIT and DODGE are big thumb buttons, 8+ apart, on screen")
	var tap := InputEventScreenTouch.new()
	tap.index = 0
	tap.position = Vector2(150, 400)
	tap.pressed = true
	sample.get_viewport().push_input(tap, true)  # straight to the GUI: headless has no display to deliver it
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(150, 330)
	drag.relative = Vector2(0, -70)
	sample.get_viewport().push_input(drag, true)
	await _frames(2)
	var pushed := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.0)
	var half_drag := InputEventScreenDrag.new()
	half_drag.index = 0
	half_drag.position = Vector2(150, 365)
	half_drag.relative = Vector2(0, 35)
	sample.get_viewport().push_input(half_drag, true)
	await _frames(1)
	var half: Vector3 = sample._movement()
	tap.pressed = false
	tap.position = drag.position
	sample.get_viewport().push_input(tap, true)
	await _frames(2)
	_check(half.z < -.25 and half.z > -.75, "half a thumb's throw walks Duff at part speed (%s)" % half)
	_check(pushed.y < -.5 and Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.0) == Vector2.ZERO,
		"a thumb dragged up on the left half walks Duff up, and letting go stops him (%s)" % pushed)

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
	_plain(sample)
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP, "wrong-facing attack misses")
	sample.facing = Vector3.FORWARD
	sample.pirate.position = Vector3(0, 0, -.1)
	_plain(sample)
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP, "out-of-range attack misses")

	# A short diagonal through the corner is in reach of both actors.
	var corner: Vector3 = sample.PLANTER_AT + Vector3(sample.PLANTER_SIZE.x, 0, sample.PLANTER_SIZE.z) * .5
	sample.player.position = corner + Vector3(.3, 0, -.5)  # 1.13 apart, inside both reaches,
	sample.pirate.position = corner + Vector3(-.5, 0, .3)  # the line between crosses the planter
	sample.facing = (sample.pirate.position - sample.player.position).normalized()
	_plain(sample)
	sample.pirate_recovery = 0
	sample.invulnerable = 0
	await _frames(2)
	sample._attack()
	sample._tick_pirate()
	_check(sample.pirate_hp == sample.PIRATE_HP and sample.player_hp == 5,
		"planter blocks in-range strikes from Duff and the pirate")

	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.facing = Vector3.FORWARD
	sample.dodge_recovery = 0
	sample._dodge()
	await _frames(2)
	sample._tick_pirate()
	_plain(sample)
	sample._attack()
	_check(sample.player_hp == 5 and sample.pirate_hp == sample.PIRATE_HP,
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
	_check(sample.player_hp == 5 and sample.pirate_wind > 0 and sample.tell_foe == sample.pirate,
		"the pirate winds up first, with the red ring under him")
	sample._tick_pirate(sample.PIRATE_TELE + .01)
	_check(sample.player_hp == 4 and sample.tell_foe == null, "an undodged wind-up jab damages Duff")
	sample.pirate_recovery = 0
	sample.invulnerable = 0
	sample._tick_pirate()
	_plain(sample)
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP - 1 and sample.pirate_wind > 0,
		"hitting into his wind-up lands but doesn't stop the jab")
	sample._tick_pirate(sample.PIRATE_TELE + .01)
	_check(sample.player_hp == 3, "trading into a wind-up costs Duff a hit")
	_plain(sample)
	sample._attack()
	_plain(sample)
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP - 2 and sample.blocked == 1 and sample.pirate_wind > 0,
		"the third hit of a flurry is blocked and the pirate counters")
	sample.invulnerable = 0
	sample._tick_pirate(sample.COUNTER_TELE + .01)
	_check(sample.player_hp == 2, "mashing into his guard costs Duff a hit")
	# Combos: A in rhythm can't be guarded and the third is a knockdown; a mashed press starts over.
	sample.pirate_hp = sample.PIRATE_HP
	sample.chain = {}
	sample.pirate_wind = 0
	sample._tell(null)
	var blocks_before: int = sample.blocked
	_plain(sample)
	sample._attack()
	_beat(sample)
	sample._attack()
	_check(sample.combo == 2 and sample.callout == "2 HIT", "A again in rhythm is a 2-hit combo")
	_beat(sample)
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP - 4 and sample.blocked == blocks_before and sample.callout == "KNOCKDOWN!"
		and sample.pirate_recovery >= sample.FINISHER_STUN, "third hit in rhythm is an unguardable knockdown for 2")
	sample.pirate_hp = sample.PIRATE_HP
	sample.chain = {}
	_plain(sample)
	sample._attack()
	sample._attack()  # pressed mid-swing: mashing
	_beat(sample)
	sample._attack()
	_check(sample.combo == 1 and not sample.combo_broken, "a press mid-swing drops the combo: the next hit starts over")
	sample.pirate_hp = sample.PIRATE_HP
	sample.chain = {}
	sample.pirate_wind = 0
	sample._tell(null)
	_plain(sample)
	sample.pirate.position = Vector3(1.6, 0, 0)  # 2.3 away, off to the side
	sample.facing = Vector3.FORWARD
	sample.last_dodge = sample.clock - .3
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP - 1 and sample.callout == "DASH HOOK!" and sample.facing.x > .5,
		"A right after a roll is a homing dash hook")
	# K: the push kick.
	_check(sample.player_model.has_clip("kick"), "Duff has the real push-kick clip")
	var k_btn: TouchScreenButton = sample.find_child("Kick", true, false)
	var k_box := Rect2(k_btn.position, k_btn.shape.size)
	_check(not k_box.grow(8).intersects(hit_box) and not k_box.grow(8).intersects(dodge_box) and k_box.end.x <= view.x,
		"K is its own thumb button, 8+ clear of A and B")
	sample.pirate.position = Vector3(0, 0, .2)  # 1.8 away: past a punch, inside a kick
	sample.facing = Vector3.FORWARD
	sample.pirate_hp = sample.PIRATE_HP
	sample.chain = {sample.pirate: [5, sample.clock]}  # mid-flurry: a punch would be guarded
	_plain(sample)
	sample._kick()
	_check(sample.pirate_hp == sample.PIRATE_HP - 1 and sample.callout == "KICK!" and sample.player_model.current == "kick"
		and sample.feel.knock_of(sample.pirate).length() > sample.feel.KNOCK_HIT * 2,
		"K reaches past a punch, goes through the guard and shoves him back")
	sample.pirate.position = Vector3(0, 0, 1)
	sample.pirate_hp = sample.PIRATE_HP + 2  # so the wall hit below doesn't KO him
	_plain(sample)
	sample._attack()
	_beat(sample)
	sample._attack()
	_beat(sample)
	sample.kick_cool = 0
	sample._kick()
	_check(sample.pirate_hp == sample.PIRATE_HP - 2 and sample.callout == "LAUNCHER!" and sample.launched.has(sample.pirate),
		"A A K is a launcher for 2")
	sample._wall_splat(sample.pirate)
	_check(sample.pirate_hp == sample.PIRATE_HP - 3 and sample.wall_hits == 1 and sample.callout == "LAUNCHER!",
		"a launched foe into a wall takes 1 more, with a thud and no callout")
	sample.pirate_hp = sample.PIRATE_HP
	sample.pirate.position = Vector3(1.2, 0, 1.2)
	sample.facing = Vector3.FORWARD
	_plain(sample)
	var hp_before: int = sample.player_hp
	sample.invulnerable = .3
	sample.last_dodge = sample.clock - .1
	sample._hurt_duff(sample.pirate.position)
	sample.attack_time = 0
	sample._kick()
	_check(sample.player_hp == hp_before and sample.pirate_hp == sample.PIRATE_HP - 2 and sample.callout == "COUNTER KICK!",
		"roll through a hit, then K: a homing counter kick for 2")
	var hp_after_counter: int = sample.pirate_hp
	sample.attack_time = 0
	sample._kick()
	_check(sample.pirate_hp == hp_after_counter and sample.kick_cool > 0, "kicks have a cooldown")
	# Real physics: a plain kick in the open isn't a wall hit; a launcher into the planter is.
	sample.pirate_hp = sample.PIRATE_HP
	sample.wall_hits = 0
	sample.player.position = Vector3(-3, 0, 2.5)
	sample.pirate.position = Vector3(-3, 0, 1.2)
	sample.facing = Vector3.FORWARD
	_plain(sample)
	sample.pirate_recovery = 9.0
	sample.launched = {}
	sample._kick()
	sample.set_physics_process(true)
	await create_timer(.7, true, false, true).timeout  # real time: the hit-stop slows the first frames
	sample.set_physics_process(false)
	_check(sample.pirate_hp == sample.PIRATE_HP - 1 and sample.wall_hits == 0 and sample.launched.is_empty(),
		"a plain kick in the open does 1: the ground isn't a wall (%d HP, %d walls, active %s, %s)" % [sample.pirate_hp, sample.wall_hits, sample.active, sample.callout])
	sample.pirate_hp = sample.PIRATE_HP
	sample.player.position = sample.PLANTER_AT + Vector3(-.3, 0, 2.6)
	sample.pirate.position = sample.PLANTER_AT + Vector3(-.3, 0, 1.15)
	sample.facing = Vector3.FORWARD
	_plain(sample)
	sample.combo = 2
	sample.combo_at = sample.clock
	sample._kick()
	sample.set_physics_process(true)
	await create_timer(.7, true, false, true).timeout
	sample.set_physics_process(false)
	_check(sample.wall_hits == 1 and sample.pirate_hp == sample.PIRATE_HP - 3, "a launcher into the planter takes 1 more (%d HP, %d walls, at %s)" % [sample.pirate_hp, sample.wall_hits, sample.pirate.position])
	# R: Red Right Hand, the special.
	_check(sample.player_model.has_clip(sample.RRH_CLIP), "Duff has the real Red Right Hand swing clip")
	var r_btn: TouchScreenButton = sample.find_child("Special", true, false)
	var r_box := Rect2(r_btn.position, r_btn.shape.size)
	_check(not r_box.grow(8).intersects(hit_box) and not r_box.grow(8).intersects(dodge_box)
		and not r_box.grow(8).intersects(k_box) and r_box.end.x <= view.x and r_box.position.y >= 0,
		"R is its own thumb button, 8+ clear of A, B and K")
	sample.launched = {}
	sample.pirate_recovery = 0
	sample.pirate_hp = sample.PIRATE_HP
	sample.player.position = Vector3(-3, 0, 2.5)
	sample.pirate.position = Vector3(-3, 0, 1.2)
	sample.facing = Vector3.FORWARD
	sample.meter = 50
	sample.red_right_hand()
	_check(sample.special_time == 0 and sample.meter == 50, "no Red Right Hand until the meter is full")
	_plain(sample)
	sample.chain = {}
	sample._attack()
	_check(sample.meter == 50 + sample.METER_HIT, "a landed hit fills the meter")
	var hp_meter: int = sample.player_hp
	sample.invulnerable = 0
	sample._hurt_duff(sample.pirate.position)
	_check(sample.meter == 50 + sample.METER_HIT + sample.METER_HURT, "taking a hit fills the meter too")
	sample.player_hp = hp_meter
	# A hit: from 3.5 m away the dash closes the gap and lands 3 through his guard.
	sample.pirate_hp = sample.PIRATE_HP
	sample.player.position = Vector3(-3, 0, 2.5)
	sample.pirate.position = Vector3(-3, 0, -1)
	sample.pirate_recovery = 9.0
	sample.chain = {sample.pirate: [5, sample.clock]}  # mid-flurry: a punch would be guarded
	sample.meter = 100
	_plain(sample)
	sample.red_right_hand()
	_check(sample.meter == 0 and sample.special_time > 0 and sample.invulnerable > 0, "a full meter fires Red Right Hand: meter spent, Duff untouchable in the wind-up")
	sample.set_physics_process(true)
	await create_timer(2.0, true, false, true).timeout  # real time: the hit-stop slows the first frames
	sample.set_physics_process(false)
	_check(sample.special_hit and sample.pirate_hp == sample.PIRATE_HP - sample.RRH_DAMAGE and sample.player.position.z < 2.2,
		"the dash closes the gap (3.5 m, he walks in too) and lands %d through his guard (%d HP, Duff at %s)" % [sample.RRH_DAMAGE, sample.pirate_hp, sample.player.position])
	_check(sample.special_time == 0 and not sample.rrh_fire.emitting and not sample.rrh_trail.visible, "the fire and trail go out after the special")
	# A whiff: nobody in the path, he skids to a stop and is open.
	sample.pirate.position = Vector3(3, 0, 2.5)
	sample.player.position = Vector3(-3, 0, 2.5)
	sample.facing = Vector3.FORWARD
	sample.pirate_hp = sample.PIRATE_HP
	sample.meter = 100
	sample.red_right_hand()
	sample.facing = Vector3.FORWARD  # aim away from him
	sample.player_model.rotation.y = 0
	sample.set_physics_process(true)
	await create_timer(sample.RRH_WINDUP + sample.RRH_DASH + .05, true, false, true).timeout
	sample.set_physics_process(false)
	_check(not sample.special_hit and sample.pirate_hp == sample.PIRATE_HP and sample.special_time > 0 and sample.invulnerable == 0,
		"a whiffed Red Right Hand leaves Duff open in the recovery")
	sample.dodge_recovery = 0
	sample._dodge()
	_check(sample.dodge_time == 0 and sample.invulnerable == 0, "B can't roll out of the special: the whiff stays open")
	# The fight ending mid-special (his KO punch, or Duff KO'd in the recovery) puts the fire out.
	sample.player_model.player.speed_scale = 0.0
	sample.rrh_fire.emitting = true
	sample.active = false
	await process_frame
	await process_frame
	_check(sample.special_time == 0 and not sample.rrh_fire.emitting and not sample.rrh_glow.visible
		and sample.player_model.player.speed_scale != 0.0, "a fight that ends mid-special lets go of the fist and puts the fire out")
	sample.active = true
	sample.special_time = 0
	sample.attack_time = 0
	# Return to Sender: a full meter next to him grabs instead of dashing, and the throw lands 3 through his guard.
	sample.pirate_hp = sample.PIRATE_HP
	sample.player.position = Vector3(0, 0, 1.5)
	sample.pirate.position = Vector3(0, 0, .5)
	sample.pirate_recovery = 9.0
	sample.chain = {sample.pirate: [5, sample.clock]}
	sample.meter = 100
	_plain(sample)
	sample.red_right_hand()
	_check(sample.toss_foe == sample.pirate and sample.meter == 0 and sample.special_time > 0 and sample.invulnerable > 0,
		"a full meter within %.2f m grabs him: Return to Sender, Duff untouchable" % sample.RTS_RANGE)
	sample.set_physics_process(true)
	await create_timer(1.0, true, false, true).timeout
	_check(sample.pirate.collision_layer == 0 and sample.pirate_model.current == "flail" and sample.pirate.position.y > .3,
		"held over Duff's shoulder he flails, off the ground, no collision (y %.2f)" % sample.pirate.position.y)
	await create_timer(1.0, true, false, true).timeout  # landed a moment ago
	var thrown := Vector2(sample.toss_land.x - sample.player.position.x, sample.toss_land.z - sample.player.position.z).length()
	_check(sample.toss_foe == null and sample.special_time == 0 and sample.pirate_hp == sample.PIRATE_HP - sample.RTS_DAMAGE
		and sample.pirate.collision_layer == sample.ACTOR_LAYER and absf(sample.pirate.position.y) < .05 and thrown > 1.2 and sample.pirate_model.current == "flyup",
		"the throw lands %d through his guard %.1f m away, flat on the lawn, collision back (%d HP, %s)" % [sample.RTS_DAMAGE, thrown, sample.pirate_hp, sample.pirate_model.current])
	await create_timer(1.6, true, false, true).timeout
	sample.set_physics_process(false)
	_check(sample.pirate_model.current != "flyup" and sample.pirate_model.locked <= 0,
		"a thrown pirate who isn't KO'd gets back up (%s)" % sample.pirate_model.current)
	# Out of reach it is the Red Right Hand dash, not a grab.
	sample.pirate.position = Vector3(-3, 0, -1)
	sample.player.position = Vector3(-3, 0, 2.5)
	sample.meter = 100
	sample.red_right_hand()
	_check(sample.toss_foe == null and is_equal_approx(sample.special_time, sample.RRH_TIME), "out of grab range the special is the dash")
	sample._end_special()
	sample.special_time = 0
	sample.attack_time = 0
	sample.player_model.locked = 0
	# The fight ending mid-carry puts him back on his feet with his collision.
	sample.pirate.position = Vector3(-3, 0, 1.5)
	sample.pirate_recovery = 9.0
	sample.meter = 100
	sample.red_right_hand()
	sample.set_physics_process(true)
	await create_timer(1.0, true, false, true).timeout
	sample.set_physics_process(false)
	sample.active = false
	await process_frame
	await process_frame
	_check(sample.toss_foe == null and sample.pirate.collision_layer == sample.ACTOR_LAYER and absf(sample.pirate.position.y) < .05
		and is_zero_approx(sample.pirate_model.rotation.x) and sample.pirate_model.current not in ["flail", "flyup"],
		"a fight that ends mid-carry drops him back on his feet with his collision")
	sample.active = true
	sample.special_time = 0
	sample.attack_time = 0
	sample.player_model.locked = 0
	sample.invulnerable = 0
	sample.pirate_recovery = 0
	sample.launched = {}
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.facing = Vector3.FORWARD
	sample.pirate_hp = 3
	sample.pirate_recovery = 0
	sample.player_hp = 3
	for expected in range(sample.PIRATE_HP - 3, -1, -1):
		sample.chain = {}
		_plain(sample)
		sample._attack()
		_check(sample.pirate_hp == expected, "unobstructed Duff attack brings pirate HP to %d" % expected)
	_check(sample.player_model.current in ["jab", "hook"], "Duff's attack plays a jab or hook clip")
	_check(sample.package.get_parent() == sample and sample.package.visible
		and sample.pirate_model.current == "ko" and sample.pirate.collision_layer == 0,
		"defeated pirate plays its KO clip, drops the visible parcel and clears actor collision")
	_check(not sample.mike.visible and sample.mike.collision_layer == 0 and sample.mike_state == "away",
		"Marketplace Mike waits off-screen during the pirate fight")
	_check(sample.feel.trauma > 0 and sample.feel.knock_of(sample.pirate) != Vector3.ZERO,
		"landed hits shake the camera and knock the foe back")
	await create_timer(1.0, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "hit-stop lets go of the world")
	sample.player_hp = 2
	sample.player.position = sample.package.position
	sample.set_physics_process(true)
	await _frames(3)
	_check(sample.active and not sample.package.visible and sample.mike.visible
		and sample.mike_state == "stalk" and sample.player_hp == 5,
		"grabbing the parcel brings Marketplace Mike in and refills Duff")
	sample.mike.position = sample.player.position + Vector3(1.5, 0, 0)  # on screen, as he walks in
	sample._place_bubble(0.0)
	var bubble_head: Vector2 = sample.camera.unproject_position(sample.mike.global_position + Vector3.UP * 1.95)
	_check(sample.bubble.visible and sample.bubble_from == sample.mike and "best offer" in sample.bubble_text.text
		and sample.bubble_tail.position.distance_to(bubble_head) < 60
		and not Rect2(sample.bubble.position, sample.bubble.size).has_point(bubble_head),
		"Mike's line is a speech bubble over his head (%s, tail %s, head %s)" % [sample.bubble.position, sample.bubble_tail.position, bubble_head])
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

	# Up close: Mike winds up a jab that shoves Duff out to sign / charge range.
	sample.invulnerable = 0
	sample.mike_state = "stalk"
	sample.mike_recovery = 0
	sample.mike_cool = 2.0
	sample.player.position = Vector3(0, 0, 2)
	sample.mike.position = Vector3(1, 0, 2)
	await _frames(2)
	sample._tick_mike(.016)
	_check(sample.mike_state == "jab_tele" and sample.tell_foe == sample.mike, "up close Mike winds up a shove")
	sample._tick_mike(sample.MIKE_JAB_TELE + .01)
	_check(sample.player_hp == 2 and sample.feel.knock_of(sample.player).x < -5.0 and sample.mike_cool <= .35,
		"the shove costs one HP, sends Duff flying and readies his next special")
	sample.player_hp = 3

	# Beat him: halfway he rages (taunt), then KO wins the encounter.
	sample.mike_state = "dizzy"
	sample.mike_timer = 5.0
	sample.player.position = Vector3(0, 0, 2)
	sample.mike.position = Vector3(0, 0, 1)
	sample.facing = Vector3.FORWARD
	await _frames(2)
	for i in sample.MIKE_HP / 2:
		_plain(sample)
		sample._attack()
	_check(sample.mike_hp == sample.MIKE_HP / 2 and sample.mike_raged and sample.mike_state == "taunt" and mm.current == "taunt",
		"at half health Mike rages with his taunt")
	_plain(sample)
	sample._attack()
	_check(sample.mike_hp == sample.MIKE_HP / 2 and sample.mike_state == "jab_tele",
		"his price-drop rant is no opening: the hit is blocked and he swings back")
	sample.mike_state = "dizzy"
	sample.mike_timer = 5.0
	for i in sample.MIKE_HP / 2:
		_plain(sample)
		sample._attack()
	_check(sample.mike_hp == 0 and mm.current == "ko" and not sample.active and sample.mike.collision_layer == 0,
		"Mike's KO clip plays and the porch is secured")

	await _frames(120)  # the win card follows Mike's last line
	_check(sample.hud.screen == "win" and paused, "PORCH SECURED card after Mike goes down")
	var r: Dictionary = sample.result
	_check(r.get("grade", "") in ["S", "A", "B", "C", "D"] and r.time > 0 and r.best_grade != "" and r.hits == sample.hits_taken,
		"the win card grades the fight (%s in %s, %d hits, %d specials)" % [r.get("grade"), sample.clock_label(r.get("time", 0.0)), r.get("hits", -1), r.get("specials", -1)])
	var card_text := ""
	for label in sample.hud.find_children("*", "Label", true, false):
		card_text += (label as Label).text + " "
	_check(("GRADE " + r.get("grade", "?")) in card_text and ("NEW BEST" in card_text or "Best:" in card_text),
		"the win card shows the grade and the best on this phone")
	_check(sample.grade_for(60, 0, 2) == "S" and sample.grade_for(80, 2, 1) == "A" and sample.grade_for(200, 4, 0) == "D" and sample.grade_for(150, 3, 0) == "C"
		and sample.grade_for(150, 3, 3) == "B", "grades: clean and quick is S, slow and hurt is D, specials pull it up")

	Input.action_press("ui_right", .8)  # thumb still on the stick when Retry is tapped
	sample._reset()
	await scene_changed
	sample = current_scene
	_check(not Input.is_action_pressed("ui_right"), "Retry with the stick held doesn't leave Duff walking")
	_check(sample.active and sample.player_hp == 5 and sample.pirate_hp == sample.PIRATE_HP
		and sample.pirate.visible and sample.package.visible and sample.package.get_parent() == sample.pirate_model,
		"retry restores actors, health, and held parcel")
	sample.set_physics_process(false)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.player_hp = 1
	await _frames(2)
	sample._tick_pirate()
	sample._tick_pirate(sample.PIRATE_TELE + .01)
	_check(sample.player_hp == 0 and not sample.active, "last pirate hit ends the encounter in defeat")
	await _frames(90)
	_check(sample.hud.screen == "ko" and paused, "KNOCKED OUT card after Duff goes down")
	sample.retry()
	await scene_changed
	_check(current_scene.active and current_scene.player_hp == 5 and not paused and current_scene.hud.screen == "",
		"retry after defeat restores Duff and skips the title")
	# Return to Sender as the KO: he stays down and the parcel sails back onto the stoop.
	sample = current_scene
	sample.set_physics_process(false)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample.pirate_recovery = 9.0
	sample.pirate_hp = sample.RTS_DAMAGE
	sample.meter = 100
	await _frames(2)
	sample.red_right_hand()
	sample.set_physics_process(true)
	await create_timer(4.0, true, false, true).timeout  # grab, carry, throw, then the parcel's flight
	_check(sample.pirate_hp == 0 and sample.pirate_model.current == "ko" and sample.pirate.collision_layer == 0
		and sample.package.get_parent() == sample and sample.package.position.distance_to(sample.STOOP_AT) < .05,
		"a Return to Sender KO leaves him down and lands the parcel on the stoop (%s)" % sample.package.position)
	quit(1 if failures else 0)
