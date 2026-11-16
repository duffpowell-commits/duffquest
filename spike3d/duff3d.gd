extends CharacterBody3D
## Duff in the 3D spike: the shipping 2x sheet (duff_home, 4x4 cells of 128 px) on a camera-facing card.
## Same actions as the 2D game: move_* to walk (8-way), attack (Space/J) to bonk.

signal bonked(at: Vector3, dir: Vector3)

const SPEED: = 5.2          # m/s (2D: ~52 units/s)
const SWING: = 0.22
const U: = 0.1

var sprite: Sprite3D
var facing: = Vector3(0, 0, 1)
var row: = 0                # 0 front, 1 back, 2 right, 3 left (sheet rows)
var walk_t: = 0.0
var swing_t: = 0.0

func _ready() -> void:
	var cs: = CollisionShape3D.new()
	var cap: = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.2
	cs.shape = cap
	cs.position.y = 0.6
	add_child(cs)
	sprite = Sprite3D.new()
	sprite.texture = load("res://art/duff_home.png")
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.centered = false
	sprite.offset = Vector2(-64, -8)            # sheet origin [64, 120]: feet on the node
	sprite.pixel_size = U / 4.0
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.shaded = true
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(sprite)
	# soft contact shadow (Art.shadow() in 2D) so he never floats when the sun is behind a building
	var blob: = MeshInstance3D.new()
	var q: = PlaneMesh.new()
	q.size = Vector2(1.1, 0.7)
	var bm: = StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_texture = _blob_tex()
	bm.albedo_color = Color(0, 0, 0, 0.5)
	q.material = bm
	blob.mesh = q
	blob.position.y = 0.02
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blob)

func _blob_tex() -> Texture2D:
	var g: = Gradient.new()
	g.set_color(0, Color(0, 0, 0, 1))
	g.set_color(1, Color(0, 0, 0, 0))
	var gt: = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	return gt

func _physics_process(delta: float) -> void:
	var v: = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("attack") and swing_t <= 0.0:
		swing_t = SWING
		bonked.emit(position + facing * 1.0, facing)
	if swing_t > 0.0:
		swing_t -= delta
		v *= 0.25
	velocity.x = v.x * SPEED
	velocity.z = v.y * SPEED
	velocity.y -= 20.0 * delta
	move_and_slide()
	if v.length() > 0.1:
		facing = Vector3(v.x, 0, v.y).normalized()
		row = (2 if v.x > 0 else 3) if absf(v.x) > absf(v.y) else (0 if v.y > 0 else 1)
		walk_t += delta * 8.0
	else:
		walk_t = 0.0
	var col: = 3 if swing_t > 0.0 else (0 if walk_t == 0.0 else 1 + int(walk_t) % 2)
	sprite.frame = row * 4 + col
