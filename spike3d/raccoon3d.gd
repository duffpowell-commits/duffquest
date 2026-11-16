extends Node3D
## A trash raccoon to bonk: wanders near home, tumbles away on a hit, comes back.

const U: = 0.1
var home: = Vector3.ZERO
var sprite: Sprite3D
var t: = randf() * 10.0
var vel: = Vector3.ZERO
var down: = 0.0

func _ready() -> void:
	sprite = Sprite3D.new()
	sprite.texture = load("res://art/raccoon.png")
	sprite.hframes = 4
	sprite.vframes = 2
	sprite.centered = false
	sprite.offset = Vector2(-24, -4)            # origin [24, 28] of a 48x32 cell
	sprite.pixel_size = U / 2.0
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(sprite)

func bonk(dir: Vector3) -> bool:
	if down > 0.0:
		return false
	vel = dir * 7.0 + Vector3(0, 5.0, 0)
	down = 1.6
	return true

func _process(delta: float) -> void:
	t += delta
	if down > 0.0:
		down -= delta
		vel.y -= 18.0 * delta
		position += vel * delta
		if position.y < 0.0:
			position.y = 0.0
			vel = vel * Vector3(0.4, -0.35, 0.4)
		sprite.rotation_degrees.z += delta * 900.0 * signf(vel.x + 0.01)
		if down <= 0.0:
			sprite.rotation_degrees.z = 0.0
		return
	var target: = home + Vector3(sin(t * 0.5) * 0.5, 0, cos(t * 0.37) * 0.3)
	var step: = (target - position)
	step.y = 0.0
	position += step.limit_length(1.2 * delta)
	position.y = 0.0
	sprite.frame = (0 if step.x >= 0 else 4) + int(t * 8.0) % 4
