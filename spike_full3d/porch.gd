extends Node3D

const Art = preload("porch_art.gd")
const RigActor = preload("rig_actor.gd")
const WORLD_LAYER := 1
const ACTOR_LAYER := 2
const PLANTER_AT := Vector3(1.66, 0, -.74)
const PLANTER_SIZE := Vector3(1.06, .62, .82)
const PLAYER_SPEED := 4.6
const PIRATE_SPEED := 2.1
const PLAYER_HP := 5
const PIRATE_HP := 3
const DUFF_HEIGHT := 1.7
const PIRATE_HEIGHT := 1.4
## Game time each one-shot clip is squeezed into (gameplay timing stays the same as the block-model slice).
const ATTACK_ANIM := .42
const DODGE_ANIM := .45
const HIT_ANIM := .4
const PIRATE_ATTACK_ANIM := .55
## Marketplace Mike (boss "mike" in scripts/boss.gd): walks in once the parcel is back. Easy on purpose.
## Melee jab up close; from range he "posts" you (throws his OBO sign) or charges ("Cash only!").
const MIKE_HEIGHT := 1.65
const MIKE_HP := 6
const MIKE_SPEED := 1.9
const MIKE_RAGE_SPEED := 2.5
const MIKE_SPECIAL_RANGE := 2.4  ## posting / charge only from at least this far
const MIKE_SPECIAL_EVERY := 2.6  ## seconds between specials (x .7 once he rages)
const POST_TELE := .7            ## wind-up before the sign leaves his hand: dodge then
const SIGN_SPEED := 6.5
const SIGN_RADIUS := .55
const CHARGE_TELE := .75
const CHARGE_SPEED := 7.2
const CHARGE_TIME := .85
const MIKE_DIZZY := 1.0          ## after a charge: free hits
const MIKE_SPAWN := Vector3(5.6, 0, 3.4)
## Closer than the block-model slice (9.25) so the real models read on a phone; follows Duff sideways.
const CAMERA_SIZE := 7.0
const CAMERA_OFFSET := Vector3(0, 9.6, 13)
const CAMERA_X_LIMIT := 2.6

var player: CharacterBody3D
var pirate: CharacterBody3D
var player_model: RigActor
var pirate_model: RigActor
var mike: CharacterBody3D
var mike_model: RigActor
var mike_hp := MIKE_HP
var mike_state := "away"  ## away, stalk, post, charge_tele, charge, dizzy, taunt, ko
var mike_timer := 0.0
var mike_cool := 0.0
var mike_recovery := 0.0
var mike_raged := false
var charge_next := false
var charge_dir := Vector3.FORWARD
var obo_sign: Node3D
var sign_velocity := Vector3.ZERO
var sign_life := 0.0
var jab_next := true
var package: Node3D
var hit_marker: MeshInstance3D
var impact: MeshInstance3D
var impact_time := 0.0
var health: Label
var message: Label
var fps_label: Label
var camera: Camera3D
var player_hp := PLAYER_HP
var pirate_hp := PIRATE_HP
var attack_time := 0.0
var dodge_time := 0.0
var dodge_recovery := 0.0
var pirate_recovery := 0.0
var invulnerable := 0.0
var facing := Vector3.FORWARD
var active := true
var dodge_requested := false
var attack_requested := false
var touch: Dictionary = {}

func _ready() -> void:
	_build_street()
	player = _actor(Vector3(-2, 0, 3))
	pirate = _actor(Vector3(3, 0, -1))
	player_model = RigActor.make(player, "duff", DUFF_HEIGHT)
	pirate_model = RigActor.make(pirate, "pirate", PIRATE_HEIGHT)
	package = Art.parcel(pirate_model, Vector3(0, .78, -.3))
	mike = _actor(MIKE_SPAWN)
	mike_model = RigActor.make(mike, "mike", MIKE_HEIGHT)
	mike.hide()
	mike.collision_layer = 0
	mike.collision_mask = 0
	obo_sign = _obo_sign()
	obo_sign.hide()
	hit_marker = _strike_arc(player_model)
	hit_marker.hide()
	var burst := Art.Sculpture.new()
	for ray in 7:
		var angle := ray * TAU / 7.0
		var offset := Vector3(cos(angle), sin(angle), 0)
		burst.form(offset * .25, Vector3(.22, .056, .045), Color("#ffca79"), Vector3(0, 0, angle), 6)
	impact = burst.finish(self, "Impact")
	impact.hide()
	_build_hud()
	_update_hud()

func _process(delta: float) -> void:
	var target_x := clampf(player.position.x, -CAMERA_X_LIMIT, CAMERA_X_LIMIT)
	camera.position.x = lerpf(camera.position.x, target_x, minf(1.0, delta * 4.0))
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()

func _physics_process(delta: float) -> void:
	if not active:
		return
	attack_time = maxf(0, attack_time - delta)
	impact_time = maxf(0, impact_time - delta)
	impact.visible = impact_time > 0.0
	impact.scale = Vector3.ONE * (1.15 - impact_time * 2.0)
	dodge_time = maxf(0, dodge_time - delta)
	dodge_recovery = maxf(0, dodge_recovery - delta)
	pirate_recovery = maxf(0, pirate_recovery - delta)
	mike_recovery = maxf(0, mike_recovery - delta)
	invulnerable = maxf(0, invulnerable - delta)
	var direction := _movement()
	if dodge_time <= 0 and direction != Vector3.ZERO:
		facing = direction
		player_model.rotation.y = atan2(-direction.x, -direction.z)
	if dodge_requested:
		dodge_requested = false
		_dodge()
	if attack_requested:
		attack_requested = false
		_attack()
	hit_marker.visible = attack_time > .14
	var motion := facing * 8.8 if dodge_time > 0 else direction * PLAYER_SPEED
	_move(player, motion)
	var speed := Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	player_model.move(minf(speed / PLAYER_SPEED, 1.0))
	if pirate_hp > 0:
		_tick_pirate()
	elif mike_state == "away":
		if player.position.distance_to(package.position) <= .85:
			_mike_arrives()
	elif mike_state != "ko":
		_tick_mike(delta)
	_tick_sign(delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		attack_requested = true
	elif event is InputEventKey:
		if event.physical_keycode == KEY_SHIFT:
			dodge_requested = true
		elif event.physical_keycode == KEY_R:
			_reset()

func _movement() -> Vector3:
	var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right") or touch.has("right")) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left") or touch.has("left"))
	var z := float(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down") or touch.has("down")) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up") or touch.has("up"))
	return Vector3(x, 0, z).normalized()

func _move(actor: CharacterBody3D, motion: Vector3) -> void:
	actor.velocity = Vector3(motion.x, -2, motion.z)
	actor.move_and_slide()

func _tick_pirate() -> void:
	var offset := player.position - pirate.position
	offset.y = 0
	var distance := offset.length()
	var direction := offset.normalized()
	if direction != Vector3.ZERO:
		pirate_model.rotation.y = atan2(-direction.x, -direction.z)
	_move(pirate, direction * PIRATE_SPEED if distance > .85 else Vector3.ZERO)
	var speed := Vector2(pirate.get_real_velocity().x, pirate.get_real_velocity().z).length()
	pirate_model.move(minf(speed / PIRATE_SPEED, 1.0) * .55)
	if distance <= 1.04 and pirate_recovery <= 0 and _clear_strike(pirate, player):
		pirate_recovery = 1.15
		pirate_model.strike("jab", PIRATE_ATTACK_ANIM)
		_hurt_duff()

## One point of damage unless Duff is in dodge / hit immunity. Returns true when it landed.
func _hurt_duff() -> bool:
	if invulnerable > 0 or not active:
		return false
	player_hp -= 1
	_show_impact(player.position)
	invulnerable = .45
	_update_hud()
	if player_hp <= 0:
		active = false
		hit_marker.hide()
		player_model.strike("ko")
		message.text = "Duff is down. Retry the encounter."
	else:
		player_model.strike("hit", HIT_ANIM)
	return true

func _attack() -> void:
	var foe := _foe()
	if not active or attack_time > 0 or foe == null or dodge_time > 0:
		return
	attack_time = .27
	player_model.strike("jab" if jab_next else "hook", ATTACK_ANIM)
	jab_next = not jab_next
	var offset := foe.position - player.position
	offset.y = 0
	if offset.length() > 1.75 or facing.dot(offset.normalized()) < .38:
		return
	if not _clear_strike(player, foe):
		return
	if foe == mike:
		_hit_mike()
		return
	pirate_hp -= 1
	_show_impact(pirate.position)
	if pirate_hp > 0:
		pirate_model.strike("hit", HIT_ANIM)
		pirate_recovery = maxf(pirate_recovery, HIT_ANIM)  # staggered: no jab back during the hit clip
	if pirate_hp == 0:
		var drop := pirate.position + Vector3.UP * .22
		package.reparent(self)
		package.position = drop
		package.rotation = Vector3(0, .25, 0)
		pirate_model.strike("ko")
		pirate.collision_layer = 0
		pirate.collision_mask = 0
		message.text = "Walk over to grab the parcel."
	_update_hud()

## Who Duff's punches can land on right now.
func _foe() -> CharacterBody3D:
	if pirate_hp > 0:
		return pirate
	if mike_state not in ["away", "ko"]:
		return mike
	return null

func _mike_arrives() -> void:
	package.hide()  # Duff has it now
	player_hp = maxi(player_hp, PLAYER_HP)  # fresh fight; Mike is the easy first boss
	mike_state = "stalk"
	mike_cool = 1.6
	mike.position = MIKE_SPAWN
	mike.show()
	mike.collision_layer = ACTOR_LAYER
	mike.collision_mask = WORLD_LAYER | ACTOR_LAYER
	message.text = "Marketplace Mike: That pirate was my best guy. Porch box goes for twelve bucks. Or best offer."
	_update_hud()

func _tick_mike(delta: float) -> void:
	mike_timer = maxf(0, mike_timer - delta)
	mike_cool = maxf(0, mike_cool - delta)
	var offset := player.position - mike.position
	offset.y = 0
	var distance := offset.length()
	var direction := offset.normalized()
	match mike_state:
		"stalk":
			if direction != Vector3.ZERO:
				mike_model.rotation.y = atan2(-direction.x, -direction.z)
			if distance <= 1.05 and mike_recovery <= 0 and _clear_strike(mike, player):
				mike_recovery = .8 if mike_raged else 1.15
				mike_model.strike("jab", PIRATE_ATTACK_ANIM)
				_hurt_duff()
			elif mike_cool <= 0 and distance >= MIKE_SPECIAL_RANGE and active:
				_mike_special(direction)
			var speed := MIKE_RAGE_SPEED if mike_raged else MIKE_SPEED
			var walking := distance > .9 and mike_state == "stalk"
			var heading := direction
			if not _clear_strike(mike, player):
				heading = (direction + direction.cross(Vector3.UP)).normalized()  # step around the planter
			_move(mike, heading * speed if walking else Vector3.ZERO)
			var pace := Vector2(mike.get_real_velocity().x, mike.get_real_velocity().z).length()
			mike_model.move(minf(pace / MIKE_SPEED, 1.0) * .55)
		"post":
			_move(mike, Vector3.ZERO)
			if direction != Vector3.ZERO:
				mike_model.rotation.y = atan2(-direction.x, -direction.z)
				charge_dir = direction  # the sign flies at where Duff is when it leaves his hand
			if mike_timer <= 0:
				_throw_sign()
				mike_state = "stalk"
		"charge_tele":
			_move(mike, Vector3.ZERO)
			if mike_timer <= 0:
				mike_state = "charge"
				mike_timer = CHARGE_TIME
				mike_model.locked = 0
				mike_model.play("charge")
				mike_model.player.speed_scale = 1.0
		"charge":
			if distance <= .95 and charge_dir.dot(direction) > .2:
				_hurt_duff()
				_mike_dizzy()
				return
			_move(mike, charge_dir * CHARGE_SPEED)
			var bonked := false
			for i in mike.get_slide_collision_count():
				var hit := mike.get_slide_collision(i)
				var body := hit.get_collider() as CollisionObject3D
				if body and body.collision_layer & WORLD_LAYER and absf(hit.get_normal().y) < .5:
					bonked = true
			if bonked or mike_timer <= 0:
				_mike_dizzy()
		"dizzy", "taunt":
			_move(mike, Vector3.ZERO)
			if mike_timer <= 0:
				mike_state = "stalk"
				mike_model.locked = 0

## Ranged turn: alternate posting (sign throw) and the charge, each with a readable wind-up.
func _mike_special(direction: Vector3) -> void:
	mike_cool = MIKE_SPECIAL_EVERY * (.7 if mike_raged else 1.0)
	charge_dir = direction
	if charge_next:
		mike_state = "charge_tele"
		mike_timer = CHARGE_TELE
		mike_model.strike("taunt", CHARGE_TELE)
		message.text = "Mike: Cash only! No lowballers!"
	else:
		mike_state = "post"
		mike_timer = POST_TELE
		mike_model.strike("throw", POST_TELE + .35)
		message.text = "Mike lists you. \"Used. Fair condition.\""
	charge_next = not charge_next

func _mike_dizzy() -> void:
	mike_state = "dizzy"
	mike_timer = MIKE_DIZZY
	mike_model.strike("hit", MIKE_DIZZY)

func _hit_mike() -> void:
	mike_hp -= 1
	_show_impact(mike.position)
	_update_hud()
	if mike_hp <= 0:
		mike_state = "ko"
		mike_model.strike("ko")
		mike.collision_layer = 0
		mike.collision_mask = 0
		obo_sign.hide()
		active = false
		hit_marker.hide()
		message.text = "Mike: Okay. Mark me as sold. Parcel recovered. Porch secured."
		return
	if mike_state == "charge":
		return  # mid-charge he shrugs it off
	if not mike_raged and mike_hp <= MIKE_HP / 2:
		mike_raged = true
		mike_state = "taunt"
		mike_timer = 1.2
		mike_model.strike("taunt", 1.2)
		message.text = "Mike: Price drop! Everything must go! Starting with YOU!"
		return
	if mike_state == "stalk":
		mike_model.strike("hit", HIT_ANIM)
		mike_recovery = maxf(mike_recovery, HIT_ANIM)

func _throw_sign() -> void:
	obo_sign.position = mike.position + Vector3.UP * 1.05 + charge_dir * .5
	obo_sign.rotation = Vector3(-.65, 0, 0)  # face tipped toward the camera so "OBO" reads in flight
	sign_velocity = charge_dir * SIGN_SPEED
	sign_life = 1.4
	obo_sign.show()

func _tick_sign(delta: float) -> void:
	if not obo_sign.visible:
		return
	sign_life -= delta
	var step := sign_velocity * delta
	var ray := PhysicsRayQueryParameters3D.create(obo_sign.position, obo_sign.position + step, WORLD_LAYER)
	if sign_life <= 0 or not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		obo_sign.hide()
		return
	obo_sign.position += step
	obo_sign.rotation.z = sin(sign_life * 14.0) * .35  # tumbling wobble
	var gap := obo_sign.position - player.position
	gap.y = 0
	if gap.length() <= SIGN_RADIUS and _hurt_duff():
		obo_sign.hide()  # a dodged sign keeps flying past him

## Mike's OBO sign, readable from both sides.
func _obo_sign() -> Node3D:
	var art := Art.Sculpture.new()
	art.box(Vector3.ZERO, Vector3(.62, .3, .04), Color("#c9822f"))
	var board: Node3D = art.finish(self, "OboSign")
	for side in [-1.0, 1.0]:
		var text := Label3D.new()
		text.text = "OBO"
		text.font_size = 72
		text.outline_size = 0
		text.pixel_size = .0032
		text.modulate = Color("#3a2414")
		text.position = Vector3(0, 0, side * .023)
		text.rotation.y = 0.0 if side > 0 else PI
		board.add_child(text)
	return board

func _clear_strike(attacker: CharacterBody3D, target: CharacterBody3D) -> bool:
	var height := Vector3.UP * .50
	var ray := PhysicsRayQueryParameters3D.create(
		attacker.global_position + height, target.global_position + height, WORLD_LAYER
	)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _dodge() -> void:
	if active and dodge_recovery <= 0:
		dodge_time = .23
		player_model.strike("dodge", DODGE_ANIM)
		dodge_recovery = .65
		invulnerable = maxf(invulnerable, .27)

func _reset() -> void:
	get_tree().reload_current_scene()

func _actor(at: Vector3) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	actor.collision_layer = ACTOR_LAYER
	actor.collision_mask = WORLD_LAYER | ACTOR_LAYER
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = .34
	shape.height = 1.4
	collision.shape = shape
	collision.position.y = .7
	actor.add_child(collision)
	add_child(actor)
	actor.position = at
	return actor

func _show_impact(at: Vector3) -> void:
	impact.position = at + Vector3.UP * 1.03
	impact_time = .20
	impact.show()

func _strike_arc(parent: Node3D) -> MeshInstance3D:
	var art := Art.Sculpture.new()
	for segment in 12:
		var angle := lerpf(-.80, .80, segment / 11.0)
		var at := Vector3(sin(angle), 0, -cos(angle)) * .86
		at.y = .72
		var weight := sin(segment / 11.0 * PI)
		art.form(at, Vector3(.15, .025 + .07 * weight, .04), Color("#f5be77"), Vector3(0, -angle, .11), 8)
	return art.finish(parent, "StrikeArc")

func _collider(label: String, at: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = WORLD_LAYER
	body.collision_mask = ACTOR_LAYER
	var shape := BoxShape3D.new()
	shape.size = dimensions
	var hit := CollisionShape3D.new()
	hit.shape = shape
	body.add_child(hit)
	add_child(body)
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
	add_child(camera)
	camera.position = CAMERA_OFFSET
	camera.look_at(Vector3(0, .55, -.9))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.make_current()
	Art.meshy_set(self, PLANTER_AT, PLANTER_SIZE)
	var lamp := OmniLight3D.new()  # porch light by the door
	lamp.position = Vector3(0, 2.6, -2.9)
	lamp.light_color = Color("#ffb15e")
	lamp.light_energy = 1.4
	lamp.omni_range = 2.8
	add_child(lamp)
	_collider("Ground", Vector3(0, -.16, 0), Vector3(16, .32, 11))
	_collider("FrontageCollider", Vector3(0, 1.4, -4.85), Vector3(10.6, 2.8, 1.9))
	_collider("StoopCollider", Vector3(0, .119, -2.95), Vector3(2.84, .238, 1.03))
	_collider("StepCollider", Vector3(0, .066, -2.35), Vector3(2.92, .132, .22))
	for x in [-6.9, 6.9]:
		_collider("FenceCollider", Vector3(x, .65, 0), Vector3(.32, 1.3, 11))
	_collider("StreetLimit", Vector3(0, .6, 5.39), Vector3(15, 1.2, .23))
	_collider("RearLimit", Vector3(0, .7, -5.51), Vector3(15, 1.4, .25))
	_collider("PlanterCollider", PLANTER_AT + Vector3.UP * PLANTER_SIZE.y * .5, PLANTER_SIZE)
	for x in [-6.0, 6.0]:
		_collider("TrunkCollider", Vector3(x, .9, -4.2), Vector3(.5, 1.8, .5))
	_collider("MailboxCollider", Vector3(6.1, .62, 2.45), Vector3(.42, 1.25, .5))

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := _hud_label(layer, Vector2(22, 13), 23, Color("#ffcf97"))
	title.text = "DUFF QUEST"
	health = _hud_label(layer, Vector2(22, 47), 16, Color.WHITE)
	message = _hud_label(layer, Vector2(22, 73), 16, Color("#ffe7ca"))
	message.text = "Stop the Porch Pirate and recover the parcel."
	fps_label = _hud_label(layer, Vector2(800, 22), 14, Color("#eddbd0"))
	var hint := _hud_label(layer, Vector2(22, 512), 14, Color("#eddbd0"))
	hint.text = "WASD / arrows  ·  Space to hit  ·  Shift to dodge  ·  R to retry"
	_button(layer, "", Vector2(84, 381), "up", 0.0)
	_button(layer, "", Vector2(22, 439), "left", -PI / 2.0)
	_button(layer, "", Vector2(84, 439), "down", PI)
	_button(layer, "", Vector2(146, 439), "right", PI / 2.0)
	_button(layer, "Hit", Vector2(884, 399), "attack")
	_button(layer, "Dodge", Vector2(822, 457), "dodge")
	_button(layer, "Retry", Vector2(884, 15), "reset")

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

func _button(layer: CanvasLayer, caption: String, at: Vector2, action: String, angle := 0.0) -> void:
	var button := TouchScreenButton.new()
	button.name = action.capitalize()
	button.position = at
	var bounds := RectangleShape2D.new()
	bounds.size = Vector2(54, 50)
	button.shape = bounds
	button.shape_centered = false
	button.passby_press = action in ["up", "left", "down", "right"]
	layer.add_child(button)
	var panel := Panel.new()
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#211b29d9")
	style.border_color = Color("#edb178a0")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	button.add_child(panel)
	var label := Label.new()
	label.size = bounds.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = caption
	panel.add_child(label)
	if caption.is_empty():
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(0, -10), Vector2(10, 3), Vector2(4, 3), Vector2(4, 9), Vector2(-4, 9), Vector2(-4, 3), Vector2(-10, 3)])
		arrow.position = bounds.size * .5
		arrow.rotation = angle
		arrow.color = Color("#ffe5c3")
		panel.add_child(arrow)
	button.pressed.connect(func() -> void: panel.modulate = Color("#ffd59e"))
	button.released.connect(func() -> void: panel.modulate = Color.WHITE)
	match action:
		"attack": button.pressed.connect(func() -> void: attack_requested = true)
		"dodge": button.pressed.connect(func() -> void: dodge_requested = true)
		"reset": button.released.connect(_reset)
		_:
			button.pressed.connect(func() -> void: touch[action] = true)
			button.released.connect(func() -> void: touch.erase(action))

func _update_hud() -> void:
	if mike_state == "away":
		health.text = "DUFF %d/%d   ·   PIRATE %d/%d" % [player_hp, PLAYER_HP, pirate_hp, PIRATE_HP]
	else:
		health.text = "DUFF %d/%d   ·   MARKETPLACE MIKE %d/%d" % [player_hp, PLAYER_HP, maxi(mike_hp, 0), MIKE_HP]
