extends Node3D

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
var status: Label
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
var attack_requested := false
var touch: Dictionary = {}

func _ready() -> void:
	_build_street()
	player = _actor(Vector3(-2, 0, 3))
	pirate = _actor(Vector3(3, 0, -1))
	player_model = _person(player, Color("#28262a"), Color("#b0783c"), false)
	pirate_model = _person(pirate, Color("#37324b"), Color("#37221f"), true)
	package = _box(pirate_model, Vector3(0, .73, -.43), Vector3(.43, .34, .38), Color("#bd824b"))
	hit_marker = _box(player_model, Vector3(0, .65, -.79), Vector3(.72, .07, .75), Color("#ffbe64"))
	hit_marker.hide()
	_build_hud()
	_update_hud()

func _physics_process(delta: float) -> void:
	if not active:
		return
	attack_time = maxf(0, attack_time - delta)
	dodge_time = maxf(0, dodge_time - delta)
	dodge_recovery = maxf(0, dodge_recovery - delta)
	pirate_recovery = maxf(0, pirate_recovery - delta)
	invulnerable = maxf(0, invulnerable - delta)
	if attack_requested:
		attack_requested = false
		_attack()
	hit_marker.visible = attack_time > .14
	var direction := _movement()
	if dodge_time <= 0 and direction != Vector3.ZERO:
		facing = direction
		player_model.rotation.y = atan2(-direction.x, -direction.z)
	var motion := facing * 8.8 if dodge_time > 0 else direction * PLAYER_SPEED
	_move(player, motion)
	if pirate_hp > 0:
		_tick_pirate()
	elif player.position.distance_to(package.position) <= .85:
		package.hide()
		active = false
		message.text = "Parcel recovered. Porch secured."

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_accept"):
		attack_requested = true
	elif event is InputEventKey:
		if event.physical_keycode == KEY_SHIFT:
			_dodge()
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
	if distance <= 1.04 and pirate_recovery <= 0:
		pirate_recovery = 1.15
		if invulnerable <= 0:
			player_hp -= 1
			invulnerable = .45
			_update_hud()
			if player_hp == 0:
				active = false
				message.text = "Duff is down. Retry the encounter."

func _attack() -> void:
	if not active or attack_time > 0 or pirate_hp <= 0 or dodge_time > 0:
		return
	attack_time = .27
	var offset := pirate.position - player.position
	offset.y = 0
	if offset.length() > 1.75 or facing.dot(offset.normalized()) < .38:
		return
	var ray := PhysicsRayQueryParameters3D.create(player.position + Vector3.UP * .6, pirate.position + Vector3.UP * .6)
	ray.exclude = [player.get_rid(), pirate.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
		return
	pirate_hp -= 1
	if pirate_hp == 0:
		var drop := pirate.position + Vector3.UP * .22
		package.reparent(self)
		package.position = drop
		pirate.hide()
		pirate.collision_layer = 0
		pirate.collision_mask = 0
		message.text = "Walk over to grab the parcel."
	_update_hud()

func _dodge() -> void:
	if active and dodge_recovery <= 0:
		dodge_time = .23
		dodge_recovery = .65
		invulnerable = maxf(invulnerable, .27)

func _reset() -> void:
	get_tree().reload_current_scene()

func _actor(at: Vector3) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
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

func _person(actor: CharacterBody3D, shirt: Color, hair: Color, hood: bool) -> Node3D:
	var model := Node3D.new()
	actor.add_child(model)
	var skin := Color("#c18a68")
	_box(model, Vector3(0, .72, 0), Vector3(.51, .56, .33), shirt)
	_box(model, Vector3(0, 1.2, 0), Vector3(.43, .44, .42), shirt if hood else skin)
	_box(model, Vector3(0, 1.13, -.213), Vector3(.31, .22, .07), skin)
	if hood:
		_box(model, Vector3(0, 1.16, -.255), Vector3(.32, .065, .035), Color("#191923"))
	else:
		_box(model, Vector3(0, 1.41, 0), Vector3(.46, .12, .45), hair)
	for side in [-1.0, 1.0]:
		_box(model, Vector3(side * .31, .7, -.025), Vector3(.14, .47, .17), shirt)
		_box(model, Vector3(side * .14, .28, 0), Vector3(.22, .48, .235), Color("#262c3c"))
		_box(model, Vector3(side * .14, .09, -.065), Vector3(.23, .135, .36), Color("#292732") if hood else Color("#993f3b"))
	return model

func _box(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color, collision := false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .92
	visual.material_override = material
	parent.add_child(visual)
	visual.position = at
	if collision:
		var body := StaticBody3D.new()
		var shape := BoxShape3D.new()
		var hit := CollisionShape3D.new()
		shape.size = dimensions
		hit.shape = shape
		visual.add_child(body)
		body.add_child(hit)
	return visual

func _build_street() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#c99483")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#ebc8ba")
	world.environment.ambient_light_energy = .68
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-53, -32, 0)
	sun.light_color = Color("#ffdbb6")
	sun.light_energy = 1.08
	sun.shadow_enabled = true
	add_child(sun)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 11, 13)
	camera.look_at(Vector3(0, 0, -.3))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13
	camera.make_current()
	_box(self, Vector3(0, -.16, 0), Vector3(16, .32, 11), Color("#72815c"), true)
	_box(self, Vector3(0, .02, 2.85), Vector3(16, .04, 1.7), Color("#c2a794"), true)
	_box(self, Vector3(0, .03, 4.5), Vector3(16, .06, 1.6), Color("#555265"), true)
	_box(self, Vector3(0, 1.4, -4.6), Vector3(10.6, 2.8, 2.4), Color("#965e50"), true)
	_box(self, Vector3(0, 2.83, -4.55), Vector3(11.1, .32, 2.8), Color("#453741"))
	_box(self, Vector3(0, .12, -2.93), Vector3(5.7, .24, 1.3), Color("#a78062"), true)
	_box(self, Vector3(0, 1.06, -3.374), Vector3(1.4, 2.1, .1), Color("#462f3e"))
	for x in [-3.2, 3.2]:
		_box(self, Vector3(x, 1.53, -3.376), Vector3(1.5, 1.02, .12), Color("#e9ba75"))
		_box(self, Vector3(x, 1.53, -3.304), Vector3(.073, 1.02, .035), Color("#715063"))
	for x in [-6.9, 6.9]:
		_box(self, Vector3(x, .65, 0), Vector3(.32, 1.3, 11), Color("#614e49"), true)
	_box(self, Vector3(0, .6, 5.39), Vector3(15, 1.2, .23), Color("#625c6c"), true)
	_box(self, Vector3(0, .7, -5.51), Vector3(15, 1.4, .25), Color("#51414a"), true)
	_box(self, Vector3(1.66, .31, -.74), Vector3(1.06, .62, .68), Color("#79665c"), true)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	status = Label.new()
	status.position = Vector2(22, 14)
	status.add_theme_font_size_override("font_size", 23)
	layer.add_child(status)
	message = Label.new()
	message.position = Vector2(22, 46)
	message.text = "Stop the Porch Pirate and recover the parcel."
	layer.add_child(message)
	var hint := Label.new()
	hint.position = Vector2(22, 511)
	hint.text = "WASD or arrows · Space to hit · Shift to dodge · R to retry"
	layer.add_child(hint)
	_button(layer, "↑", Vector2(73, 383), "up")
	_button(layer, "←", Vector2(18, 438), "left")
	_button(layer, "↓", Vector2(73, 438), "down")
	_button(layer, "→", Vector2(128, 438), "right")
	_button(layer, "Hit", Vector2(869, 405), "attack")
	_button(layer, "Dodge", Vector2(804, 456), "dodge")
	_button(layer, "Retry", Vector2(884, 15), "reset")

func _button(layer: CanvasLayer, caption: String, at: Vector2, action: String) -> void:
	var button := Button.new()
	button.position = at
	button.size = Vector2(54, 51)
	button.focus_mode = Control.FOCUS_NONE
	button.text = caption
	layer.add_child(button)
	match action:
		"attack": button.button_down.connect(func() -> void: attack_requested = true)
		"dodge": button.button_down.connect(_dodge)
		"reset": button.pressed.connect(_reset)
		_:
			button.button_down.connect(func() -> void: touch[action] = true)
			button.button_up.connect(func() -> void: touch.erase(action))

func _update_hud() -> void:
	status.text = "DUFF QUEST   ·   DUFF %d/%d   ·   PIRATE %d/%d" % [player_hp, PLAYER_HP, pirate_hp, PIRATE_HP]
