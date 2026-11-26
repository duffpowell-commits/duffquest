extends SceneTree

const PORCH := "res://porch.tscn"
var failures := 0

func _initialize() -> void:
	# Headless windows are 64x64 (square): with the game's "expand" aspect that would be a 960x960 view.
	# The checks are written for a 16:9 phone, so keep 960x540 here; one check below turns expand back on.
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
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

## Wait out a zone trip: until the fade card is gone (a first load of the home models can take a while).
func _trip(sample) -> void:
	await create_timer(.2, true, false, true).timeout
	for i in 200:
		if not sample.zones.moving:
			return
		await create_timer(.05, true, false, true).timeout

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
	# The APK must ship every model a fight loads by path (Nov 26: the sendback model was excluded, so the
	# phone build had no third foe). Every foe in every zone's FIGHTS, against the export excludes.
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	var shipped := true
	for zone in sample.Zones.FIGHTS.values():
		for entry in zone.foes:
			var model: String = sample.FoeData.FOES[entry[0]].model
			for line in presets.split("\n"):
				if line.begins_with("exclude_filter=") and ("models/%s" % model) in line:
					shipped = false
	_check(shipped, "the phone export ships every fighting foe's model")
	var props := {}
	for child in sample.zones.root.get_children():
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
		and sample.get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and sample.get_viewport().scaling_3d_scale < 1.0,
		"lite drops glow and MSAA and draws the 3D at 3/4 size, scaled up smooth")
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
	var clear := true
	for spot in [[Vector3(0, 0, 2), Vector3(1.2, 0, 2)], [Vector3(-3, 0, 3), Vector3(-1.8, 0, 2.6)], [Vector3(4, 0, 1), Vector3(5.2, 0, 1.4)]]:
		cam.global_transform = sample.fight_cam.goal(spot[0], spot[1])
		for body in spot:
			for y in [0.0, 1.8]:
				var q := cam.unproject_position(body + Vector3.UP * y)
				clear = clear and q.x < view.x * .72 and q.y > view.y * .18
	_check(clear, "fight camera keeps both fighters out of the right thumb buttons and under the status strip")
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND  # a screen taller than 16:9 (the square headless window)
	await _frames(2)
	sample.hud._fit_to_screen()  # (the HUD runs it every frame; this check's porch has its processing parked)
	var tall := sample.get_viewport().get_visible_rect().size
	var a_btn: TouchScreenButton = sample.find_child("Attack", true, false)
	_check(tall.y > 540 and sample.hud.spare.y == tall.y - 540 and is_equal_approx(a_btn.position.y + a_btn.shape.size.y, tall.y - 20)
		and sample.stick.position.y == 150 + sample.hud.spare.y,
		"on a screen that isn't 16:9 the view fills it and the thumb buttons and stick slide to its edges")
	sample.hud.spare = Vector2.ZERO  # as at _ready, before any frame has measured the screen
	sample.hud.show_title()
	var title_frame: Control = sample.hud.menu.get_node("Frame")
	_check(title_frame.position == sample.hud.spare * .5 and sample.hud.spare.y > 0,
		"a menu opened before the first frame is still centred on a screen that isn't 16:9")
	sample.hud.close_menu()
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	await _frames(2)
	sample.hud._fit_to_screen()
	for actor in [sample.player_model, sample.pirate_model]:
		_check(actor.skeleton.get_bone_count() == 24 and actor.skeleton.find_bone("RightHand") >= 0,
			"%s is a skinned mesh on the 24-bone humanoid skeleton" % actor.name)
		var clips := ["idle", "walking", "running", "jab", "hit", "ko"]
		if actor == sample.player_model:
			clips += ["hook", "dodge"]
		_check(clips.all(func(c): return actor.has_clip(c)), "%s has real clips %s" % [actor.name, clips])
		_check(actor.current in ["idle", "walking", "running"] and actor.player.is_playing(), "%s starts in a real idle, walk or run clip" % actor.name)
	# Walking and running (Duff, Nov 26: "the motion looks bad"): legs play at the body's real ground
	# speed, so feet don't skate, and bodies turn instead of snapping.
	for foe in sample.foes:
		var m = foe.model
		_check(m.ground.walking > .5 and m.ground.walking < 2.0 and m.ground.running > m.ground.walking * 1.5,
			"%s's clips know their own ground speed (walk %.2f, run %.2f m/s)" % [foe.d.name, m.ground.walking, m.ground.running])
	var legs = sample.mike_model
	var skate := 0.0
	for speed in [.6, 1.0, 1.9, 2.5, 4.0]:
		legs.locked = 0
		legs.move_at(speed)
		skate = maxf(skate, absf(legs.player.speed_scale * legs.ground[legs.current] - speed) / speed)
	_check(skate < .05, "from a stroll to a sprint the feet keep pace with the ground (worst slip %d%%)" % int(skate * 100))
	legs.move_at(0)
	legs = sample.player_model  # Duff: the one turning under the player's thumb
	var yaw_before: float = legs.rotation.y
	legs.turn_to(yaw_before + PI * .9)
	legs._process(1.0 / 60)  # one frame on the phone
	var turned: float = absf(wrapf(legs.rotation.y - yaw_before, -PI, PI))
	for i in 15:
		legs._process(1.0 / 60)
	_check(turned > 0 and turned < 1.0 and absf(wrapf(legs.rotation.y - yaw_before - PI * .9, -PI, PI)) < .05,
		"a turn takes a few frames, never one (%.2f rad in the first frame)" % turned)

	# HUD + menus in the main game's style (porch_hud.gd).
	var hud = sample.hud
	_check(hud != null and hud.screen == "" and sample.foe_status() == ["Porch Pirate", sample.PIRATE_HP, sample.PIRATE_HP]
		and sample.bubble_name.text == "Duff" and hud.clock_text() == "5:30 PM",
		"HUD up with the pirate's plate, 5:30 PM, and Duff opens the fight")
	_check(hud.find_child("Pause", true, false) is TouchScreenButton and Rect2(hud.PAUSE).end.x <= view.x,
		"phone-style pause button on screen")
	hud.open_pause()
	_check(paused and hud.screen == "pause" and hud.menu.find_children("*", "Button", true, false).size() == 6,
		"pause sheet: Resume, Retry, Controls, Graphics, Sound, Quit to title; the fight stops")
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
	for pair in [["Attack", "a_down"], ["Dodge", "b_down"], ["Kick", "k_down"], ["Special", "r_down"]]:
		var btn: TouchScreenButton = sample.find_child(pair[0], true, false)
		var centre_tap := InputEventScreenTouch.new()
		centre_tap.index = 5
		centre_tap.position = btn.position + btn.shape.size / 2
		centre_tap.pressed = true
		btn.set_process_input(false)  # play the browser, where the button itself ignored the touch
		sample.get_viewport().push_input(centre_tap, true)
		var landed: bool = sample.hud.get(pair[1])
		centre_tap.pressed = false
		sample.get_viewport().push_input(centre_tap, true)
		var let_go: bool = not sample.hud.get(pair[1])
		btn.set_process_input(true)
		_check(landed and let_go, "a tap on the middle of %s presses and releases it even when the button ignores touches (the browser)" % pair[0])
	sample.attack_requested = false
	sample.dodge_requested = false
	sample.kick_requested = false
	sample.special_requested = false
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
	_check(sample.pirate_hp == sample.PIRATE_HP - 1 and sample.facing.z < -.9,
		"A with his back to a close foe turns Duff to him and lands (soft lock-on)")
	sample.pirate_hp = sample.PIRATE_HP
	sample.pirate.position = Vector3(0, 0, 4.6)  # 2.6 away, behind him: out of lock-on range
	sample.facing = Vector3.FORWARD
	_plain(sample)
	sample._attack()
	_check(sample.pirate_hp == sample.PIRATE_HP and sample.facing.z < -.9, "out of lock-on range, the swing stays where he faces")
	sample.pirate.position = Vector3(0, 0, 1)
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
	_check(sample.pirate_hp == sample.PIRATE_HP - 3 and sample.blocked == 0,
		"the pirate (the first fight) never blocks a mashed flurry: a first-timer's A always lands")
	# The bosses still read mashing: the hit after GUARD_AFTER in one flurry is blocked.
	sample.chain = {}
	sample.boss.state = "stalk"
	var reads := []
	for i in sample.GUARD_AFTER + 1:
		reads.append(sample._guards(sample.mike))
	sample.boss.state = "away"
	sample.chain = {}
	_check(reads == [false, false, true], "Mike blocks the third mashed hit in a flurry (%s)" % [reads])
	sample.player_hp = 2
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
	_check(sample.player_hp == 2 and sample.feel.knock_of(sample.player).x < -5.0 and sample.mike_cool <= sample.FoeData.FOES["mike"]["jab"]["cool_after"],
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
	_check(sample.mike_hp == 0 and mm.current == "ko" and sample.active and sample.mike.collision_layer == 0
		and sample._foe() == null and sample.rival.state == "away",
		"Mike's KO clip plays and the fight goes on: somebody else is coming")

	# Sir Sends-It-Back: the third fight. Only a special gets through his cloche.
	var sb = sample.rival
	var sm = sb.model
	sample.rival_in = .05
	sample.set_physics_process(true)
	await _frames(6)
	_check(sb.state == "stalk" and sample.sendback.visible and sample.sendback.collision_layer != 0
		and sample._foe() == sample.sendback and sample.player_hp == sample.PLAYER_HP and sample.foe_status()[0] == "Sir Sends-It-Back",
		"Sir Sends-It-Back walks in after Mike; Duff starts fresh")
	sample.set_physics_process(false)
	sample.player.position = Vector3(0, 0, 1)
	sample.sendback.position = Vector3(1.2, 0, 1)
	sample.facing = Vector3.RIGHT
	sb.state = "stalk"
	sb.plate_rest = 0
	sb.streak = 0
	for i in sb.PLATE_AFTER:
		_plain(sample)
		sample.chain.clear()  # paced hits, not a mashed flurry (that's the normal guard)
		sample._attack()
	_check(sb.hp == sb.HP - sb.PLATE_AFTER and sb.state == "plate" and sb.cloche.visible,
		"two clean hits and up comes the cloche")
	var sb_hp: int = sb.hp
	_plain(sample)
	sample._attack()
	_plain(sample)
	sample._kick()
	_check(sb.hp == sb_hp and sb.state == "plate" and sample.callout == "SENT BACK!" and sample.feel.knock_of(sample.player).x < -3.0,
		"punches and kicks bounce off the cloche: SENT BACK, Duff is shoved away")
	sample.player.position = Vector3(0, 0, 1)
	sample.sendback.position = Vector3(1.2, 0, 1)
	sample.special_strike = true  # what Red Right Hand's and Return to Sender's hits carry
	sample._damage(sample.sendback, sample.RRH_DAMAGE, 1.0)
	sample.special_strike = false
	sb.raged = true  # his rage line is Mike's tested pattern; here the free hit is the point
	_check(sb.hp == sb_hp - sample.RRH_DAMAGE - 1 and not sb.cloche.visible and sb.state == "dizzy" and sample.callout == "CLOCHE SMASHED!",
		"a special smashes the cloche: +1 damage and he's dizzy")
	_plain(sample)
	sample._attack()
	_check(sb.state == "dizzy" and sb.hp == sb_hp - sample.RRH_DAMAGE - 2, "dizzy, he takes free hits")
	sb.state = "stalk"
	sb.cool = 0
	sb.charge_next = false
	sample.sendback.position = Vector3(4, 0, 1)
	sample.player.position = Vector3(0, 0, 1)
	sample.player_hp = sample.PLAYER_HP
	sample.invulnerable = 0
	sb.tick(.016)
	_check(sb.state == "cards_tele" and sm.current == "throw" and sample.tell_foe == sample.sendback, "he winds up a 1-star card throw (red ring)")
	sb.tick(sb.CARD_TELE + .01)
	_check(sb.cards.size() == (5 if sb.raged else 3), "the cards fly out in a spread")
	for i in 120:
		sb.tick_cards(1.0 / 60)
		if sample.player_hp < sample.PLAYER_HP:
			break
	_check(sample.player_hp == sample.PLAYER_HP - 1, "a card in the spread hits Duff")
	sb.clear_shots()
	sb.state = "stalk"
	sb.cool = 0
	sb.tick(.016)
	_check(sb.state == "charge_tele", "then he telegraphs a charge")
	sb.state = "plate"
	sb.cloche.show()
	sample.toss_foe = null
	sample.player.position = Vector3(0, 0, 1)
	sample.sendback.position = Vector3(1.0, 0, 1)
	sample.meter = 100
	sample.set_physics_process(true)
	sample.red_right_hand()
	_check(sample.toss_foe == sample.sendback and sb.cloche.visible, "Return to Sender grabs him straight through the cloche")
	await _frames(160)
	_check(not sb.cloche.visible and (sb.state == "dizzy" or sb.hp == 0) and sample.sendback.collision_layer != 0 or sb.hp == 0,
		"the throw lands, the cloche is smashed and he's dizzy")
	sample.set_physics_process(false)
	sb.state = "dizzy"
	sb.timer = 5.0
	sample.player.position = Vector3(0, 0, 1)
	sample.sendback.position = Vector3(1.2, 0, 1)
	sample.facing = Vector3.RIGHT
	for i in 12:
		if sb.hp <= 0:
			break
		sb.state = "dizzy"
		_plain(sample)
		sample._attack()
	_check(sb.hp == 0 and sm.current == "ko" and not sample.active and sample.sendback.collision_layer == 0,
		"Sir Sends-It-Back goes down and the porch is secured")
	sample.set_physics_process(true)

	await _frames(120)  # the win card follows his last line
	_check(sample.hud.screen == "win" and paused, "PORCH SECURED card after the last foe goes down")
	var r: Dictionary = sample.result
	_check(r.get("grade", "") in ["S", "A", "B", "C", "D"] and r.time > 0 and r.best_grade != "" and r.hits == sample.hits_taken,
		"the win card grades the fight (%s in %s, %d hits, %d specials)" % [r.get("grade"), sample.clock_label(r.get("time", 0.0)), r.get("hits", -1), r.get("specials", -1)])
	var card_text := ""
	for label in sample.hud.find_children("*", "Label", true, false):
		card_text += (label as Label).text + " "
	_check(("GRADE " + r.get("grade", "?")) in card_text and ("NEW BEST" in card_text or "Best:" in card_text),
		"the win card shows the grade and the best on this phone")
	_check(sample.grade_for(100, 0, 2) == "S" and sample.grade_for(120, 2, 1) == "A" and sample.grade_for(240, 4, 0) == "D" and sample.grade_for(190, 3, 0) == "C"
		and sample.grade_for(190, 3, 3) == "B", "grades: clean and quick is S, slow and hurt is D, specials pull it up")

	# Walkable zones (Phase 2 step 3): Go inside -> the apartment, the door back out, the stoop door in.
	var buttons := []
	for b in sample.hud.menu.find_children("*", "Button", true, false):
		buttons.append((b as Button).text)
	_check(buttons == ["Go inside", "Play again", "Quit to title"], "the win card offers Go inside (%s)" % [buttons])
	var zones = sample.zones
	sample.go_inside()
	_check(zones.card.visible and not sample.active, "Go inside fades to the loading card")
	await _trip(sample)
	var home := {}
	for child in zones.root.get_children():
		if child.has_meta("set_prop") or child is MeshInstance3D:
			home[String(child.name)] = true
	_check(zones.zone == "apartment" and zones.indoor and sample.exploring and sample.active and not zones.card.visible
		and sample.foe_status() == [] and sample.current_foe() == null and not sample.pirate.visible and not sample.sendback.visible,
		"HOME: the apartment loads, nobody to fight, foes gone")
	_check(home.has("Couch") and home.has("Kitchenette") and home.has("CoffeeTable") and home.has("DiningTable")
		and home.has("Window") and home.has("Door") and zones.root.find_children("*", "StaticBody3D", true, false).size() >= 10,
		"the apartment is dressed: couch, kitchenette, tables, window, door, walls you can't walk through")
	_check(home.has("Crib") and home.has("PlayMat") and home.has("HighChair") and home.has("Stroller") and home.has("Bouncer")
		and home.has("Clutter"), "lived in: crib, play mat, bouncer, high chair, stroller, everyday clutter")
	_check(sample.fight_cam.mode == "explore" and zones.spots.has("couch_left") and zones.spots.has("kitchen"),
		"the explore camera follows Duff indoors; spots wait for Madison and Brittany")
	_check(not sample.has_node("Zone_porch") and sample.find_children("PorchLamp", "", true, false).is_empty(),
		"the porch zone is freed while Duff is home")
	sample.attack_requested = true
	sample.kick_requested = true
	sample.special_requested = true
	await _frames(3)
	_check(sample.active and sample.player_hp > 0 and sample._foe() == null, "A, K and R with nobody to fight do nothing harmful")
	_check(zones.people.has("madison") and zones.people.has("brittany") and zones.people.madison.current == "idle"
		and sample.feel.music.stream.resource_path.ends_with("mus_edm_home.ogg") and sample.feel.bed.stream != null,
		"home: Madison and Brittany idle in the room; home music and the room sound play")
	# USE at home (Duff's pick): A is USE, the other fight buttons are hidden.
	var hidden := 0
	for b in ["Dodge", "Kick", "Special"]:
		hidden += int(not (sample.find_child(b, true, false) as CanvasItem).visible)
	_check(hidden == 3, "at home only the big button shows (B, K, R hidden)")
	var spot_of := {}
	for u in zones.uses:
		spot_of[u.id] = u
	_check(spot_of.has("couch") and spot_of.has("fridge") and spot_of.has("crib") and spot_of.has("blinds") and spot_of.has("duck"),
		"USE spots: couch, fridge, crib, blinds, duck")
	# Every USE spot can be walked to: a Duff-sized capsule fits somewhere inside each spot's radius.
	var space: PhysicsDirectSpaceState3D = sample.player.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = sample.DUFF_RADIUS
	capsule.height = 1.4
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = sample.WORLD_LAYER
	var reachable := 0
	for u in zones.uses:
		var fits := false
		for ring in [0.0, .33, .66, .95]:
			for k in 16:
				var p: Vector2 = u.at + Vector2.from_angle(k * TAU / 16) * ring * u.radius
				query.transform = Transform3D(Basis(), Vector3(p.x, .75, p.y))
				if space.intersect_shape(query, 1).is_empty():
					fits = true
		reachable += int(fits)
		if not fits:
			print("no room at USE spot ", u.id)
	_check(reachable == zones.uses.size(), "every USE spot has room for Duff to stand (%d/%d)" % [reachable, zones.uses.size()])
	sample.player.position = Vector3(spot_of.fridge.at.x, 0, spot_of.fridge.at.y)
	sample.player_hp = 2
	sample._press_a()
	await _frames(3)
	_check(sample.player_hp == 4 and sample.bubble_text.text.begins_with("Cold pizza") and sample.attack_time == 0,
		"USE at the fridge: a snack, +2 hearts, no punch thrown")
	sample.player.position = Vector3(spot_of.couch.at.x, 0, spot_of.couch.at.y)
	var before: float = sample.hud.minutes
	sample._press_a()
	await _frames(3)
	_check(sample.hud.minutes >= before + 30 and sample.player_hp == 5, "USE on the couch: half an hour passes, +1 heart")
	sample.player.position = Vector3(spot_of.blinds.at.x, 0, spot_of.blinds.at.y)
	sample._press_a()
	await _frames(3)
	var pane: MeshInstance3D = zones.root.get_node("Window")
	_check(sample.blinds_down and (pane.material_override as StandardMaterial3D).albedo_color == Color("#8a8478"), "USE at the window: blinds down, the window darkens")
	sample._press_a()
	await _frames(3)
	_check(not sample.blinds_down, "USE again: blinds up")
	sample.player.position = Vector3(0, 0, 1.5)
	await _frames(2)
	_check(zones.nearest_use().is_empty(), "nothing to use in the middle of the room")
	var door: Dictionary = zones.doors[0]
	sample.player.position = Vector3(door.at.x, 0, door.at.y)
	await _trip(sample)
	_check(zones.zone == "porch" and not zones.indoor and sample.player.position.distance_to(Vector3(0, 0, -1.2)) < .5
		and sample.fight_cam.mode == "explore" and sample.has_node("Zone_porch"),
		"the apartment door leads back out to the porch (Duff on the walk, still exploring)")
	await _frames(3)
	sample.player.position = Vector3(0, 0, -2.3)
	await _trip(sample)
	_check(zones.zone == "apartment" and zones.trips == 3, "the front door on the stoop takes Duff back inside (%d trips)" % zones.trips)
	# Light follows the clock.
	var Daylight = load("res://porch_daylight.gd")
	_check(Daylight.phase(1050) == "golden hour" and Daylight.phase(60) == "night" and Daylight.phase(720) == "afternoon"
		and Daylight.at(720).sun_energy > Daylight.at(0).sun_energy * 3, "day phases: golden hour at 5:30 PM, bright noon, dark night")
	var lamp: OmniLight3D = zones.root.get_node("LampLight")
	sample.look.daylight(0)
	var night_lamp := lamp.light_energy
	var night_sun: float = sample.look.sun.light_energy
	sample.look.daylight(720)
	_check(night_lamp > lamp.light_energy * 5 and night_sun < sample.look.sun.light_energy * .3,
		"night: lamps up, sun down; noon: lamps off, sun up")
	sample.hud.minutes += 60
	await _frames(3)
	_check(absf(sample.look.minute_shown - sample.hud.game_minute()) < .1, "the light keeps up with the HUD clock")

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
	sample.learned.clear()
	sample._brain(sample.pirate).arrive(false)
	sample.player.position = Vector3(0, 0, 2)
	sample.pirate.position = Vector3(0, 0, 1)
	sample._tick_pirate()
	_check(sample._brain(sample.pirate).state == "stalk" and sample.lesson == "a",
		"the tutorial pirate squares up but won't swing before Duff's first punch, and A is ringed")
	sample.learned["a"] = true
	sample.lesson = ""
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
	_check(sample.pops > 0, "a landed hit pops a damage number over him")

	# Nov 26 first-timer fixes (scored 5/10): the yard, the checkpoint, the controls card.
	sample.set_physics_process(false)
	sample.player.position = Vector3(-9.0, 0, 7.0)
	sample._move(sample.player, Vector3.ZERO)
	_check(absf(sample.player.position.x) <= sample.YARD_X + .01 and sample.player.position.z <= sample.YARD_Z.y + .01,
		"a knock past the fence puts Duff back in the yard (Mike knocked him into the void)")
	sample.player.position = Vector3(1, -3, 1)
	sample._move(sample.player, Vector3.ZERO)
	_check(sample.player.position.y > -.5, "Duff falling under the ground is put back on it")
	sample.hud.show_controls(sample.hud.open_pause)
	var says := ""
	for label in sample.hud.menu.find_children("*", "Label", true, false):
		says += (label as Label).text + " "
	_check(sample.hud.screen == "controls" and "Up close: a throw" in says and "red ring" in says,
		"Controls: one screen for A, B, K, R and the stick")
	sample.hud.close_menu()
	sample.checkpoint = 1  # Duff lost to Mike
	sample.retry()
	await scene_changed
	sample = current_scene
	_check(sample.checkpoint == 1 and sample._brain(sample.pirate).state == "ko" and not sample.pirate.visible
		and not sample.package.visible and sample._brain(sample.mike).state != "away" and sample.hud.screen == "",
		"Retry after losing to Mike starts at Mike: the pirate stays beaten and Duff has the parcel")
	var pops_before: int = sample.pops
	sample.invulnerable = 0
	sample._hurt_duff(sample.mike.position)
	_check(sample.invulnerable == sample.HURT_GRACE and sample.pops == pops_before + 1,
		"a hit on Duff pops -1 and gives him %.1f s before the next one can land" % sample.HURT_GRACE)
	sample.quit_to_title()
	await scene_changed
	_check(current_scene.checkpoint == 0 and current_scene._brain(current_scene.pirate).state != "ko",
		"Quit to title starts over from the pirate")
	quit(1 if failures else 0)
