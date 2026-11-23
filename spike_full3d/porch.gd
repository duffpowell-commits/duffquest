extends Node3D

const Art = preload("porch_art.gd")
const WORLD_LAYER := 1
const ACTOR_LAYER := 2
const PLANTER_AT := Vector3(1.66, 0, -.74)
const PLANTER_SIZE := Vector3(1.06, .62, .82)
const PLAYER_SPEED := 4.6
const PIRATE_SPEED := 2.1
const PLAYER_HP := 5
const PIRATE_HP := 3

var player: CharacterBody3D
var pirate: CharacterBody3D
var player_model: Node3D
var pirate_model: Node3D
var package: Node3D
var hit_marker: MeshInstance3D
var impact: MeshInstance3D
var impact_time := 0.0
var health: Label
var message: Label
var player_hp := PLAYER_HP
var pirate_hp := PIRATE_HP
var attack_time := 0.0
var dodge_time := 0.0
var dodge_recovery := 0.0
var pirate_recovery := 0.0
var invulnerable := 0.0
var facing := Vector3.FORWARD
var active := true
var stride := 0.0
var pirate_stride := 0.0
var dodge_requested := false
var attack_requested := false
var touch: Dictionary = {}

func _ready() -> void:
	_build_street()
	player = _actor(Vector3(-2, 0, 3))
	pirate = _actor(Vector3(3, 0, -1))
	player_model = Art.person(player, false)
	pirate_model = Art.person(pirate, true)
	package = Art.parcel(pirate_model, Vector3(-.144, .806, -.395))
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
	stride += delta * speed * 4.2
	_animate(player_model, stride, minf(speed / PLAYER_SPEED, 1.0), attack_time / .27, dodge_time > 0)
	if pirate_hp > 0:
		_tick_pirate()
	elif player.position.distance_to(package.position) <= .85:
		package.hide()
		active = false
		hit_marker.hide()
		message.text = "Parcel recovered. Porch secured."

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
	pirate_stride += get_physics_process_delta_time() * speed * 5.1
	_animate(pirate_model, pirate_stride, minf(speed / PIRATE_SPEED, 1.0), maxf(0, (pirate_recovery - .94) / .21), false, true)
	if distance <= 1.04 and pirate_recovery <= 0 and _clear_strike(pirate, player):
		pirate_recovery = 1.15
		if invulnerable <= 0:
			player_hp -= 1
			_show_impact(player.position)
			invulnerable = .45
			_update_hud()
			if player_hp == 0:
				active = false
				hit_marker.hide()
				message.text = "Duff is down. Retry the encounter."

func _attack() -> void:
	if not active or attack_time > 0 or pirate_hp <= 0 or dodge_time > 0:
		return
	attack_time = .27
	var offset := pirate.position - player.position
	offset.y = 0
	if offset.length() > 1.75 or facing.dot(offset.normalized()) < .38:
		return
	if not _clear_strike(player, pirate):
		return
	pirate_hp -= 1
	_show_impact(pirate.position)
	if pirate_hp == 0:
		var drop := pirate.position + Vector3.UP * .22
		package.reparent(self)
		package.position = drop
		package.rotation = Vector3(0, .25, 0)
		pirate.hide()
		pirate.collision_layer = 0
		pirate.collision_mask = 0
		message.text = "Walk over to grab the parcel."
	_update_hud()

func _clear_strike(attacker: CharacterBody3D, target: CharacterBody3D) -> bool:
	var height := Vector3.UP * .50
	var ray := PhysicsRayQueryParameters3D.create(
		attacker.global_position + height, target.global_position + height, WORLD_LAYER
	)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _animate(model: Node3D, phase: float, pace: float, strike: float, rolling: bool, carrying := false) -> void:
	var swing := sin(phase) * pace * .42
	model.get_node("LeftLeg").rotation.x = swing
	model.get_node("RightLeg").rotation.x = -swing
	if not carrying:
		model.get_node("LeftArm").rotation.x = -swing * .66
	model.get_node("RightArm").rotation.x = swing * .66 - sin(strike * PI) * 1.6
	model.rotation.x = -.32 if rolling else (sin(phase * 2.0) * pace * .035 - (.10 if carrying else 0.0))
	model.position.y = absf(sin(phase)) * pace * .065

func _dodge() -> void:
	if active and dodge_recovery <= 0:
		dodge_time = .23
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
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-41, -36, 0)
	sun.light_color = Color("#ffdbb6")
	sun.light_energy = 1.02
	sun.shadow_enabled = true
	add_child(sun)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 9.6, 13)
	camera.look_at(Vector3(0, .55, -.35))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.25
	camera.make_current()
	Art.garden(self)
	Art.pavement(self)
	Art.frontage(self)
	Art.stoop(self)
	Art.planter(self, PLANTER_AT, PLANTER_SIZE.x, PLANTER_SIZE.z)
	_collider("Ground", Vector3(0, -.16, 0), Vector3(16, .32, 11))
	_collider("FrontageCollider", Vector3(0, 1.4, -4.6), Vector3(10.6, 2.8, 2.4))
	_collider("StoopCollider", Vector3(0, .119, -2.95), Vector3(2.84, .238, 1.03))
	_collider("StepCollider", Vector3(0, .066, -2.35), Vector3(2.92, .132, .22))
	for x in [-6.9, 6.9]:
		Art.fence(self, x)
		_collider("FenceCollider", Vector3(x, .65, 0), Vector3(.32, 1.3, 11))
	_collider("StreetLimit", Vector3(0, .6, 5.39), Vector3(15, 1.2, .23))
	_collider("RearLimit", Vector3(0, .7, -5.51), Vector3(15, 1.4, .25))
	_collider("PlanterCollider", PLANTER_AT + Vector3.UP * PLANTER_SIZE.y * .5, PLANTER_SIZE)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := _hud_label(layer, Vector2(22, 13), 23, Color("#ffcf97"))
	title.text = "DUFF QUEST"
	health = _hud_label(layer, Vector2(22, 47), 16, Color.WHITE)
	message = _hud_label(layer, Vector2(22, 73), 16, Color("#ffe7ca"))
	message.text = "Stop the Porch Pirate and recover the parcel."
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
	health.text = "DUFF %d/%d   ·   PIRATE %d/%d" % [player_hp, PLAYER_HP, pirate_hp, PIRATE_HP]
