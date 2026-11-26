extends "fight_core.gd"
## The porch: the set, the HUD, the zones and walking home, on top of the fight engine (fight_core.gd).

func _ready() -> void:
	_build_street()
	player = _actor(Vector3(-2, 0, 3), DUFF_RADIUS)
	player_model = RigActor.make(player, "duff", DUFF_HEIGHT)
	skillet = Art.skillet(self)
	player_model.attach("LeftHand", skillet, SKILLET_GRIP)
	fight = Zones.FIGHTS["porch"]
	for entry in fight.foes:
		foes.append(FoeBrain.make(self, entry[0]))
	thief = foes[0]
	boss = foes[1]
	rival = foes[2]
	package = Art.parcel(pirate_model, Vector3(0, .78, -.3))
	foes[0].arrive(false)  # the first foe is already on the porch
	_skip_to(Engine.get_meta("porch_checkpoint", 0))
	Engine.set_meta("porch_checkpoint", 0)
	hit_marker = _strike_arc(player_model)
	hit_marker.hide()
	var burst := Art.Sculpture.new()
	for ray in 7:
		var angle := ray * TAU / 7.0
		var offset := Vector3(cos(angle), sin(angle), 0)
		burst.form(offset * .25, Vector3(.22, .056, .045), Color("#ffca79"), Vector3(0, 0, angle), 6)
	impact = burst.finish(self, "Impact")
	impact.hide()
	tell_ring = _tell_ring()
	fight_cam.snap(player.position, current_foe())
	feel = Feel.make(self, camera)
	if not OS.get_cmdline_user_args().has("--plain"):
		look = Look.apply(self, [player_model] + foes.map(func(f): return f.model))
	_build_hud()
	_update_hud()
	if OS.get_cmdline_user_args().has("--zone=apartment"):  # start at home, nobody to fight
		_start_exploring()
		zones.arrive("apartment", Vector3(-1.0, 0, .4))
		return
	var wants_title := OS.has_feature("template") or OS.get_cmdline_user_args().has("--title")
	if wants_title and not Engine.get_meta("porch_skip_title", false):
		hud.show_title()
	else:
		begin()

## Retry after losing to a later foe: whoever came before is already beaten and Duff has the parcel.
func _skip_to(at: int) -> void:
	if at <= 0 or at >= foes.size():
		return
	checkpoint = at
	for i in at:
		foes[i].hp = 0
		foes[i].state = "ko"
		foes[i].body.hide()
		foes[i].body.collision_layer = 0
		foes[i].body.collision_mask = 0
	package.reparent(self)
	package.hide()
	player.position = Vector3(-.6, 0, 2.2)

## The fight starts: Duff calls the pirate out and the pirate answers (or, from a checkpoint, the
## foe he lost to walks straight back in).
func begin() -> void:
	if checkpoint > 0:
		foes[checkpoint].arrive()
		return
	_say(player, "Hey! That's my package.", 2.2)
	opening = 2.4

func retry() -> void:
	Engine.set_meta("porch_skip_title", true)
	Engine.set_meta("porch_checkpoint", checkpoint)
	_reset()

func quit_to_title() -> void:
	Engine.set_meta("porch_skip_title", false)
	Engine.set_meta("porch_checkpoint", 0)
	_reset()

func _process(delta: float) -> void:
	_place_bubble(delta)
	if special_time > 0 and not active:
		special_time = 0  # the fight ended mid-special (his KO punch, or Duff KO'd in the recovery)
		_end_special()
	if opening > 0:
		opening -= delta
		var first = foes[0]
		if opening <= 0 and active and first.fighting() and first.hp > 0 and bubble_from == player and first.d.has("opening"):
			_say(first.body, first.d.opening)
	callout_time = maxf(0, callout_time - delta / maxf(Engine.time_scale, .05))  # real time: hit-stop and slow-mo mustn't pin it on screen
	if end_in > 0:
		end_in -= delta
		if end_in <= 0:
			hud.show_end(end_won)
	tell_ring.visible = tell_foe != null and active
	if tell_ring.visible:
		tell_ring.position = tell_foe.position + Vector3.UP * .04
		tell_ring.scale = Vector3.ONE * (1.0 + .12 * sin(clock * 30.0))
	var foe_at = current_foe()
	if foe_at != null and _foe():
		foe_at = _foe().get_global_transform_interpolated().origin
	fight_cam.follow(delta, player.get_global_transform_interpolated().origin, foe_at)  # where they're drawn, between physics ticks
	if meter >= 100 and not meter_rang and active:
		meter_rang = true
		if feel:
			feel.sfx("achievement", 0.0, -4.0)  # special ready
	elif meter < 100:
		meter_rang = false
	fps_label.text = "%d FPS%s" % [Engine.get_frames_per_second(), " LITE" if look and look.lite else ""]

func _physics_process(delta: float) -> void:
	if not active:
		return
	clock += delta
	attack_time = maxf(0, attack_time - delta)
	impact_time = maxf(0, impact_time - delta)
	impact.visible = impact_time > 0.0
	impact.scale = Vector3.ONE * (1.15 - impact_time * 2.0)
	dodge_time = maxf(0, dodge_time - delta)
	dodge_recovery = maxf(0, dodge_recovery - delta)
	for foe in foes:
		foe.recovery = maxf(0, foe.recovery - delta)
	invulnerable = maxf(0, invulnerable - delta)
	kick_cool = maxf(0, kick_cool - delta)
	var direction := _movement()
	if dodge_time <= 0 and special_time <= 0 and direction != Vector3.ZERO:
		facing = direction.normalized()
		player_model.turn_to(atan2(-direction.x, -direction.z))  # turns, never snaps
	if special_requested:
		special_requested = false
		red_right_hand()
	if special_time > 0:
		_tick_special(delta)
	if dodge_requested:
		dodge_requested = false
		_dodge()
	if attack_requested:
		attack_requested = false
		_attack()
	if kick_requested:
		kick_requested = false
		_kick()
	for foe in launched.keys():
		launched[foe] -= delta
		if launched[foe] <= 0:
			launched.erase(foe)
	hit_marker.visible = attack_time > .14
	var motion := facing * 8.8 if dodge_time > 0 else direction * PLAYER_SPEED
	if special_time > 0:
		motion = facing * RRH_SPEED if _dashing() else Vector3.ZERO
	_move(player, motion)
	var speed := Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	player_model.move_at(speed)  # legs match the ground speed: no skating
	if exploring:
		zones.tick()
		if use_requested:
			use_requested = false
			var spot: Dictionary = zones.nearest_use()
			if not spot.is_empty():
				use(spot.id)
		return
	var now = _now()
	if now and now.state == "away":
		var enter = fight.foes[foes.find(now)][1]
		if enter is String and enter == "parcel":  # he comes for the parcel once Duff has it
			if player.position.distance_to(package.position) <= .85:
				package.hide()
				now.arrive()
		elif next_in > 0:
			next_in -= delta
			if next_in <= 0:
				now.arrive()
	elif now and toss_foe != now.body:
		now.tick(delta)
	for foe in foes:
		foe.tick_shots(delta)

## Backstop for the thumb buttons. In the browser (iPhone Safari, Messenger) TouchScreenButton ignored touches
## that landed square on it (Nov 26: a whole grid of taps over A/B/K/R pressed nothing), while the touches
## themselves arrived at the right spot. So a touch inside a button's box presses it here, unless the button
## already took it itself on the same touch.
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	if touch.pressed:
		for button in thumb_buttons:
			if button.is_visible_in_tree() and Rect2(button.position, button.shape.size).has_point(touch.position):
				if button.get_meta("touch", -1) != _touch_serial:  # the button didn't take this touch itself
					_thumb_taps[touch.index] = button
					button.pressed.emit()
				break
	elif _thumb_taps.has(touch.index):
		var button: TouchScreenButton = _thumb_taps[touch.index]
		_thumb_taps.erase(touch.index)
		button.released.emit()
	_touch_serial += 1

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		_press_a()
	elif event is InputEventKey:
		if event.physical_keycode == KEY_SHIFT:
			dodge_requested = true
		elif event.physical_keycode in [KEY_K, KEY_C]:
			kick_requested = true
		elif event.physical_keycode in [KEY_R, KEY_E, KEY_V]:
			special_requested = true  # R like the button
		elif event.physical_keycode == KEY_BACKSPACE:
			retry()

## Keys (WASD / arrows) or the on-screen stick, which presses the ui_* actions with analog strength.
func _movement() -> Vector3:
	var keys := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	# deadzone 0: the stick already applies its own (ui_* actions default to 0.5, which ate half the throw)
	var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.0) + keys
	move = move.limit_length(1.0)
	if move.length() < .05:
		return Vector3.ZERO
	return Vector3(move.x, 0, move.y)

func _tick_pirate(delta := 1.0 / 60) -> void:
	thief.tick(delta)

func _pirate_windup(seconds: float) -> void:
	thief.jab(seconds)

## The thrown pirate's parcel sails back onto the stoop: Return to Sender.
func _send_parcel_home() -> void:
	var from := package.position
	var arc := func(k: float) -> void:
		package.position = from.lerp(STOOP_AT, k) + Vector3.UP * sin(k * PI) * 1.4
		package.rotation.y = k * TAU
	var fly := create_tween()
	fly.tween_method(arc, 0.0, 1.0, .75).set_trans(Tween.TRANS_SINE)
	fly.tween_callback(func() -> void:
		if feel:
			feel.sfx("cash", 0.0, -2.0))  # delivered

func _reset() -> void:
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(action)  # a stick held through Retry would otherwise keep Duff walking
	get_tree().paused = false  # a menu pauses the tree; the new porch must run
	get_tree().reload_current_scene()

func _actor(at: Vector3, radius := .34) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.collision_layer = ACTOR_LAYER
	actor.collision_mask = WORLD_LAYER | ACTOR_LAYER
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = 1.4
	collision.shape = shape
	collision.position.y = .7
	actor.add_child(collision)
	add_child(actor)
	actor.position = at
	return actor

func _collider(label: String, at: Vector3, dimensions: Vector3, parent: Node3D = null) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = WORLD_LAYER
	body.collision_mask = ACTOR_LAYER
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var hit := CollisionShape3D.new()
	hit.shape = shape
	body.add_child(hit)
	(parent if parent else self).add_child(body)
	body.position = at

func _build_street() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#9c7475")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#e9cbc0")
	world.environment.ambient_light_energy = .69
	# AgX keeps the Meshy textures' colour and the set's highlights from clipping (Compatibility supports it).
	world.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.environment.tonemap_exposure = 1.0
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-41, -36, 0)
	sun.light_color = Color("#ffdbb6")
	sun.light_energy = 1.02
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # moved in _process; the bodies it follows are interpolated
	add_child(camera)
	camera.make_current()
	fight_cam = FightCam.new(camera)
	zones = Zones.make(self)
	zones.load_zone("porch")

## The porch set (zone "porch", porch_zones.gd): Meshy set or our kit, the porch lamp, colliders.
func _build_porch_set(root: Node3D) -> void:
	if OS.get_cmdline_user_args().has("--kit"):  # our own set, to compare with the Meshy one
		Kit.build(root, PLANTER_AT, PLANTER_SIZE)
		Art.ground(root)
	else:
		Art.meshy_set(root, PLANTER_AT, PLANTER_SIZE)
	var lamp := OmniLight3D.new()  # porch light by the door
	lamp.name = "PorchLamp"
	lamp.position = Vector3(0, 2.6, -2.9)
	lamp.light_color = Color("#ffb15e")
	lamp.light_energy = 1.4
	lamp.omni_range = 2.8
	lamp.set_meta("base_energy", 3.2)  # golden hour; porch_look.gd scales it with the clock
	lamp.set_meta("look_range", 4.5)
	lamp.add_to_group("zone_lamp")
	root.add_child(lamp)
	_collider("Ground", Vector3(0, -.16, 0), Vector3(16, .32, 11), root)
	_collider("FrontageCollider", Vector3(0, 1.4, -4.85), Vector3(10.6, 2.8, 1.9), root)
	_collider("StoopCollider", Vector3(0, .119, -2.95), Vector3(2.84, .238, 1.03), root)
	_collider("StepCollider", Vector3(0, .066, -2.35), Vector3(2.92, .132, .22), root)
	for x in [-6.9, 6.9]:
		_collider("FenceCollider", Vector3(x, .65, 0), Vector3(.32, 1.3, 11), root)
	_collider("StreetLimit", Vector3(0, .6, 5.39), Vector3(15, 1.2, .23), root)
	_collider("RearLimit", Vector3(0, .7, -5.51), Vector3(15, 1.4, .25), root)
	_collider("PlanterCollider", PLANTER_AT + Vector3.UP * PLANTER_SIZE.y * .5, PLANTER_SIZE, root)
	for x in [-6.0, 6.0]:
		_collider("TrunkCollider", Vector3(x, .9, -4.2), Vector3(.5, 1.8, .5), root)
	_collider("MailboxCollider", Vector3(6.1, .62, 2.45), Vector3(.42, 1.25, .5), root)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# The fight still writes these; the HUD draws them in the main game's style (porch_hud.gd).
	health = _hud_label(layer, Vector2(22, 47), 16, Color.WHITE)
	message = _hud_label(layer, Vector2(22, 73), 16, Color("#ffe7ca"))
	message.text = lesson_line
	fps_label = _hud_label(layer, Vector2(800, 22), 14, Color("#eddbd0"))
	for label in [health, message, fps_label]:
		label.hide()
	stick = _stick(layer)
	_button(layer, Hud.A_AT, Hud.A_R, "attack")
	_button(layer, Hud.B_AT, Hud.B_R, "dodge")
	_button(layer, Hud.K_AT, Hud.K_R, "kick")
	_button(layer, Hud.R_AT, Hud.R_R, "special")
	_build_bubble(layer)
	hud = Hud.make(self, layer)  # last: its menus cover everything else

## Left half of the screen: the stick appears where the thumb lands (4.7 VirtualJoystick, dynamic).
func _stick(layer: CanvasLayer) -> Control:
	var pad := VirtualJoystick.new()
	pad.name = "Stick"
	pad.position = Vector2(0, 150)
	pad.size = Vector2(440, 390)
	pad.joystick_mode = VirtualJoystick.JOYSTICK_DYNAMIC
	pad.joystick_size = 150.0
	pad.tip_size = 66.0
	pad.deadzone_ratio = .15
	pad.initial_offset_ratio = Vector2(.3, .6)
	pad.action_left = &"ui_left"
	pad.action_right = &"ui_right"
	pad.action_up = &"ui_up"
	pad.action_down = &"ui_down"
	for part in ["normal_joystick", "pressed_joystick", "normal_tip", "pressed_tip"]:
		var ring := StyleBoxFlat.new()  # faint cream ring + ink tip, like the main game's pad
		var tip: bool = part.ends_with("tip")
		var down: bool = part.begins_with("pressed")
		ring.bg_color = Color(Hud.CREAM, .9 if down else .7) if tip else Color(Hud.INK, .32 if down else .22)
		ring.border_color = Color(Hud.INK, .8) if tip else Color(Hud.CREAM, .55 if down else .35)
		ring.set_border_width_all(3)
		ring.set_corner_radius_all(200)
		ring.anti_aliasing = true
		pad.add_theme_stylebox_override(part, ring)
	layer.add_child(pad)
	return pad

func _hud_label(layer: CanvasLayer, at: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color("#25191e"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	return label

## An invisible round-ish thumb zone over the HUD's drawn A / B button.
func _button(layer: CanvasLayer, centre: Vector2, radius: float, action: String) -> void:
	var button := TouchScreenButton.new()
	button.name = action.capitalize()
	button.position = centre - Vector2.ONE * radius
	var bounds := RectangleShape2D.new()
	bounds.size = Vector2.ONE * radius * 2
	button.shape = bounds
	button.shape_centered = false
	layer.add_child(button)
	thumb_buttons.append(button)
	button.set_meta("base", button.position)  # porch_hud.gd slides it to the real screen edge
	button.pressed.connect(func() -> void: button.set_meta("touch", _touch_serial))
	var down: String = {"attack": "a_down", "dodge": "b_down", "kick": "k_down", "special": "r_down"}[action]
	button.pressed.connect(func() -> void: hud.set(down, true))
	button.released.connect(func() -> void: hud.set(down, false))
	match action:
		"attack": button.pressed.connect(_press_a)
		"dodge": button.pressed.connect(func() -> void: dodge_requested = true)
		"kick": button.pressed.connect(func() -> void: kick_requested = true)
		"special": button.pressed.connect(func() -> void: special_requested = true)

## Speech bubble over whoever talks, in the main game's dialogue look: plum glass, cream text, pink name tag.
func _build_bubble(layer: CanvasLayer) -> void:
	var body: Font = load("res://fonts/Nunito-ExtraBold.ttf")
	var display: Font = load("res://fonts/Baloo2-ExtraBold.ttf")
	bubble = PanelContainer.new()
	bubble.name = "Bubble"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Hud.PANEL
	style.border_color = Hud.INK
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, .35)
	style.shadow_offset = Vector2(3, 4)
	style.shadow_size = 2
	bubble.add_theme_stylebox_override("panel", style)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	bubble.add_child(lines)
	bubble_name = Label.new()
	bubble_name.add_theme_font_override("font", display)
	bubble_name.add_theme_font_size_override("font_size", 19)
	bubble_name.add_theme_color_override("font_color", Hud.PINK)
	lines.add_child(bubble_name)
	bubble_text = Label.new()
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.custom_minimum_size = Vector2(300, 0)
	bubble_text.add_theme_font_override("font", body)
	bubble_text.add_theme_font_size_override("font_size", 19)
	bubble_text.add_theme_color_override("font_color", Hud.CREAM)
	lines.add_child(bubble_text)
	bubble_tail = Polygon2D.new()
	bubble_tail.polygon = PackedVector2Array([Vector2(-13, -4), Vector2(13, -4), Vector2(0, 19)])
	bubble_tail.color = Hud.INK
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(0, 12)])
	inner.color = Hud.PANEL
	bubble_tail.add_child(inner)
	layer.add_child(bubble_tail)
	layer.add_child(bubble)
	bubble.hide()
	bubble_tail.hide()

func _say(speaker: Node3D, line: String, seconds := 2.8) -> void:
	bubble_from = speaker
	bubble_name.text = "Duff" if speaker == player else (speaker.get_meta("brain").d.name if speaker.has_meta("brain") else "")
	bubble_text.text = line
	bubble_time = seconds
	bubble.size = Vector2.ZERO  # shrink to the new line
	_place_bubble(0.0)

func _place_bubble(delta: float) -> void:
	bubble_time = maxf(0, bubble_time - delta)
	var showing := bubble_time > 0 and bubble_from != null and camera != null \
		and not camera.is_position_behind(bubble_from.global_position)
	bubble.visible = showing
	bubble_tail.visible = showing
	if not showing:
		return
	var head := camera.unproject_position(bubble_from.global_position + Vector3.UP * 1.95)
	var view := get_viewport().get_visible_rect().size
	if not Rect2(Vector2.ZERO, view).has_point(head):  # speaker off screen: wait until he walks in
		bubble.hide()
		bubble_tail.hide()
		return
	var box := bubble.get_combined_minimum_size()
	var at := Vector2(head.x - box.x * .5, head.y - box.y - 18)
	var top := Hud.GOAL.end.y + 6  # stay clear of the status strip and objective line
	var edge := view.x - 288.0  # and left of the thumb buttons (8.5 pass: bubbles covered B and R)
	if at.y >= top:  # room above the head: tail points down at him
		at.x = clampf(at.x, 12, maxf(12, edge - box.x - 12))
		bubble.position = at
		bubble_tail.rotation = 0
		bubble_tail.position = Vector2(clampf(head.x, at.x + 20, at.x + box.x - 20), at.y + box.y - 2)
		if not _bubble_hides_duff():
			return
	# no room (the camera keeps heads high), or it would cover Duff: sit beside his head, on the side
	# away from Duff, tail pointing at it
	var duff_x := camera.unproject_position(player.global_position).x
	var fits_right := head.x + 40 + box.x <= edge - 12
	var right := fits_right and (duff_x <= head.x or bubble_from == player or head.x - 40 - box.x < 12)
	at = Vector2(head.x + 40 if right else head.x - 40 - box.x, clampf(head.y - box.y * .5, top, maxf(top, view.y - box.y - 12)))
	bubble.position = at
	bubble_tail.rotation = PI / 2 if right else -PI / 2
	bubble_tail.position = Vector2(at.x + 2 if right else at.x + box.x - 2, clampf(head.y, at.y + 16, at.y + box.y - 16))

## True when someone else's speech bubble sits on Duff (Nov 26 first-timer: Mike's line hid him mid-fight).
func _bubble_hides_duff() -> bool:
	if bubble_from == player:
		return false
	var feet := camera.unproject_position(player.global_position)
	var crown := camera.unproject_position(player.global_position + Vector3.UP * DUFF_HEIGHT)
	var duff := Rect2(crown, Vector2.ZERO).expand(feet).grow(24)
	return Rect2(bubble.position, bubble.get_combined_minimum_size()).intersects(duff)

func _update_hud() -> void:
	var shown = _shown_foe()
	if shown:
		health.text = "DUFF %d/%d   ·   %s %d/%d" % [player_hp, PLAYER_HP, shown.d.name.to_upper(), shown.hp, shown.d.hp]
	else:
		health.text = "DUFF %d/%d" % [player_hp, PLAYER_HP]

## The letter for a won fight: 100, minus GRADE_HIT a hit taken and GRADE_SLOW a second past par,
## plus GRADE_SPECIAL for each special landed (up to 3).
static func grade_for(seconds: float, hits: int, specials: int) -> String:
	var score := 100.0 - GRADE_HIT * hits - GRADE_SLOW * maxf(0, seconds - PAR_TIME) + GRADE_SPECIAL * mini(specials, 3)
	for step in GRADES:
		if score >= step[0]:
			return step[1]
	return "D"

static func grade_rank(grade: String) -> int:
	return "DCBAS".find(grade)

## This win's grade and time against the best on this phone; saves a new best.
func _grade_result() -> Dictionary:
	var grade := grade_for(clock, hits_taken, specials_landed)
	var best := ConfigFile.new()
	best.load(BEST_PATH)  # missing on the first win: stays empty
	var best_grade: String = best.get_value("porch", "grade", "")
	var best_time: float = best.get_value("porch", "time", INF)
	var new_best := best_grade == "" or grade_rank(grade) > grade_rank(best_grade) \
		or (grade == best_grade and clock < best_time)
	if new_best:
		best.set_value("porch", "grade", grade)
		best.set_value("porch", "time", clock)
		best.save(BEST_PATH)
		best_grade = grade
		best_time = clock
	return {"grade": grade, "time": clock, "hits": hits_taken, "specials": specials_landed,
		"best_grade": best_grade, "best_time": best_time, "new_best": new_best}

static func clock_label(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]

## Mike's moves, for the tests and tools (foe_brain.gd does the work).
func _mike_arrives() -> void:
	package.hide()
	boss.arrive()

func _tick_mike(delta: float) -> void:
	boss.tick(delta)

func _tick_sign(delta: float) -> void:
	boss.tick_shots(delta)

func _mike_jab(seconds: float) -> void:
	boss.jab(seconds)

func _hit_mike(damage := 1) -> void:
	boss.hit(damage, HIT_ANIM)

## A foe is down (foe_brain.gd calls this). Whoever holds the parcel drops it; the next foe in the
## fight walks in after his delay (or once Duff has the parcel); the last one wins the porch.
func _foe_down(foe) -> void:
	hit_marker.hide()
	chain.clear()
	if package.get_parent() == foe.model:
		var drop: Vector3 = foe.body.position + Vector3.UP * .22
		package.reparent(self)
		package.position = drop
		package.rotation = Vector3(0, .25, 0)
	var down: Dictionary = foe.d.get("ko", {})
	if down.has("message"):
		message.text = down.message
	var at := foes.find(foe)
	if at == foes.size() - 1:
		_porch_won(fight.won)
		return
	var enter = fight.foes[at + 1][1]
	if not enter is String:
		next_in = float(enter)

## The last foe is down: the porch is secured, the fight is graded.
func _porch_won(line: String) -> void:
	checkpoint = 0  # Play again starts from the pirate
	active = false
	hit_marker.hide()
	message.text = line
	end_in = 1.6
	end_won = true
	result = _grade_result()
	if feel:
		feel.stop_music()
		feel.sfx("win", 0.0)

## "Go inside" on the win card: the fight is over, Duff walks home through the front door.
func go_inside() -> void:
	hud.close_menu()
	_start_exploring()
	zones.travel("apartment", Vector3(-2.75, 0, -.45), Vector3.RIGHT)

## A (the big button, or Space): a punch in a fight, USE while exploring.
func _press_a() -> void:
	if exploring:
		use_requested = true
	else:
		attack_requested = true

## USE: what each spot at home does (zone_apartment.gd lists them).
func use(id: String) -> void:
	match id:
		"couch":  # five minutes: the clock jumps half an hour (watch the light move) and Duff gets a heart back
			_say(player, "Five minutes. Just five.", 2.4)
			hud.minutes += 30
			player_hp = mini(PLAYER_HP, player_hp + 1)
		"fridge":
			_say(player, "Cold pizza. Breakfast of champions.", 2.4)
			player_hp = mini(PLAYER_HP, player_hp + 2)
		"crib":
			_say(player, "Out cold. Nobody breathe.", 2.4)
		"blinds":
			blinds_down = not blinds_down
			_say(player, "Blinds down." if blinds_down else "Let the light in.", 1.8)
			if look:
				look.daylight(look.minute_shown)
		"duck":
			_say(player, "Squeak.", 1.4)
	if feel:
		feel.sfx("pickup", .05, -6.0)
	_update_hud()

## No more fight: foes, parcel and fight bits leave the scene; Duff walks freely.
func _start_exploring() -> void:
	exploring = true
	skillet.hide()  # the skillet is for fights; walking home his hands are free
	active = true
	end_in = 0
	hit_marker.hide()
	tell_foe = null
	bubble_time = 0
	opening = 0
	message.text = "Porch secured. Walk home: the front door's on the stoop."
	for foe in foes:
		foe.cancel()
		foe.clear_shots()
		var body: CharacterBody3D = foe.body
		body.hide()
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		body.collision_mask = 0
	package.hide()
	for button in ["Dodge", "Kick", "Special"]:  # only the big button stays: USE
		var touch := find_child(button, true, false)
		if touch:
			touch.hide()
	if feel:
		feel.stop_music()
