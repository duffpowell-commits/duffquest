extends Node3D
## A Meshy character on its real 24-bone humanoid skeleton, driven by real clips
## (models/<who>.glb + models/<who>_clips.res, see tools/bake_clips.gd).
## Faces -Z like the rest of the porch code; set rotation.y to turn it.

const BLEND := .12
const TURN_RATE := 16.0  ## rad/s: a half turn takes about a fifth of a second (no more one-frame snaps)
const RUN_FROM := 1.25   ## run once ground speed passes this x the walk clip's own speed (walk again under .85 of it)
## Crown-to-chin of each unit-scale model in metres (hair, hood and bun included), measured from
## front renders (tools/cast_shot.gd --heads). Duff's head is the yardstick for the whole cast.
const HEAD := {"duff": .344, "mike": .402, "pirate": .452, "sendback": .322, "camper": .418,
	"coupon": .512, "allergy": .312, "madison": .271, "brittany": .251}
## Duff's head in the game world (his model is fitted to DUFF height in porch.gd).
const DUFF_HEAD := .365

var skeleton: Skeleton3D
var player: AnimationPlayer
var current := ""
var locked := 0.0  ## seconds a one-shot keeps priority over locomotion
var who := ""
var ground := {}       ## clip -> metres a second its planted feet cover at speed 1 (measured from the clip)
var turn_target := 0.0
var turn_hold := 0.0   ## > 0 while turn_to steers the body

## No class_name: the main project parse-checks every .gd from its own root, where this folder is
## .gdignored, so a global class here would not resolve. porch.gd preloads this script instead.
static func make(parent: Node3D, who: String, height := 1.6) -> Node3D:
	var actor = (load("res://rig_actor.gd") as GDScript).new()
	actor.name = who.capitalize()
	parent.add_child(actor)
	var body: Node3D = (load("res://models/%s.glb" % who) as PackedScene).instantiate()
	body.rotation.y = PI  # glTF faces +Z
	actor.add_child(body)
	actor.skeleton = body.find_child("Skeleton3D", true, false)
	var top: float = actor.skeleton.get_bone_global_rest(actor.skeleton.find_bone("Head")).origin.y
	body.scale = Vector3.ONE * (height / ((top + 14.0) * .01))  # head bone sits ~14 cm under the crown
	actor.who = who
	actor.player = body.find_child("AnimationPlayer", true, false)
	actor.player.add_animation_library("rig", load("res://models/%s_clips.res" % who))
	actor.player.playback_default_blend_time = BLEND
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for clip in ["walking", "running"]:
		actor.ground[clip] = actor._ground_speed(clip)
	actor.play("idle")
	return actor

func _process(delta: float) -> void:
	locked = maxf(0, locked - delta)
	if turn_hold > 0:
		turn_hold -= delta
		var gap := wrapf(turn_target - rotation.y, -PI, PI)
		rotation.y += clampf(gap, -TURN_RATE * delta, TURN_RATE * delta)

## Turn (not snap) to face `yaw`. Call it every frame while the body should be steering; a direct
## rotation.y set (a homing punch, a throw) still snaps, and wins once the calls stop.
## Face `yaw` at once (aim, dash, a door): also drops any turn still in progress, so it doesn't swing back.
func face(yaw: float) -> void:
	rotation.y = yaw
	turn_target = yaw
	turn_hold = 0.0

func turn_to(yaw: float) -> void:
	turn_target = yaw
	turn_hold = .2

## Walk / run at `speed` m/s of real ground movement: the clip runs exactly as fast as the body moves,
## so the planted foot stays put (no skating). Walk or run is picked by speed, with a little hysteresis.
func move_at(speed: float) -> void:
	if locked > 0 or current == "ko":
		return
	var walk: float = ground.get("walking", 1.3)
	var clip := "idle"
	if speed > walk * RUN_FROM or (current == "running" and speed > walk * RUN_FROM * .85):
		clip = "running"
	elif speed > .12:
		clip = "walking"
	play(clip)
	player.speed_scale = clampf(speed / ground.get(clip, 1.0), .45, 1.8) if clip != "idle" else 1.0

## How fast a clip's planted foot slides back under the body (m/s at speed 1, world units): the
## ground speed the clip was animated for. Measured once from the real clip, so any new body is right.
func _ground_speed(clip: String) -> float:
	if not has_clip(clip):
		return 1.0
	var anim := player.get_animation("rig/" + clip)
	var feet := [skeleton.find_bone("LeftFoot"), skeleton.find_bone("RightFoot")]
	var steps := 48
	var at := []
	var to_actor := Transform3D.IDENTITY  # skeleton space -> this actor's space (works before it is in the tree)
	var node: Node = skeleton
	while node != self:
		to_actor = (node as Node3D).transform * to_actor
		node = node.get_parent()
	player.play("rig/" + clip, 0)
	for i in steps + 1:
		player.seek(anim.length * i / steps, true)
		var pair := []
		for foot in feet:
			pair.append(to_actor * skeleton.get_bone_global_pose(foot).origin)
		at.append(pair)
	var low := INF
	for pair in at:
		low = minf(low, minf(pair[0].y, pair[1].y))
	var total := 0.0
	var count := 0
	for i in steps:
		for f in 2:
			var a: Vector3 = at[i][f]
			var b: Vector3 = at[i + 1][f]
			if a.y < low + .03 and b.y < low + .03:  # this foot is planted: it slides back at ground speed
				total += Vector2(b.x - a.x, b.z - a.z).length()
				count += 1
	player.stop()
	return total / (count * anim.length / steps) if count > 0 else 1.0

## Locomotion picks idle / walk / run from 0..1 pace unless a one-shot is still playing.
func move(pace: float) -> void:
	if locked > 0 or current == "ko":
		return
	var clip := "idle"
	if pace > .62:
		clip = "running"
	elif pace > .08:
		clip = "walking"
	play(clip)
	if clip != "idle":
		player.speed_scale = clampf(pace / (.95 if clip == "running" else .5), .6, 1.4)
	else:
		player.speed_scale = 1.0

## Play a one-shot squeezed into `seconds` of game time (the gameplay timing wins).
func strike(clip: String, seconds := 0.0) -> void:
	var length := player.get_animation("rig/" + clip).length
	player.speed_scale = length / seconds if seconds > 0 else 1.0
	locked = seconds if seconds > 0 else length
	play(clip, true)

func play(clip: String, restart := false) -> void:
	if clip == current and not restart:
		return
	current = clip
	player.play("rig/" + clip, BLEND if clip != "ko" else .06)
	if restart:
		player.seek(0, true)

func has_clip(clip: String) -> bool:
	return player.has_animation("rig/" + clip)

## Something held against a bone (the pirate's parcel).
func attach(bone: String, node: Node3D, offset: Transform3D) -> void:
	var socket := BoneAttachment3D.new()
	socket.bone_name = bone
	skeleton.add_child(socket)
	var holder := Node3D.new()
	socket.add_child(holder)
	holder.transform = offset
	holder.scale = Vector3.ONE / skeleton.get_parent().global_transform.basis.get_scale()
	node.reparent(holder, false)

## Scale the whole body so its head is Duff's size (height follows the character's proportions).
func fit_body_to_head(head := DUFF_HEAD) -> void:
	var body := get_child(0) as Node3D
	body.scale = Vector3.ONE * (head / HEAD.get(who, head))

## Keep the body's height but scale just the head bone so the head is Duff's size.
## Meshy clips carry no scale tracks, so the bone scale stays put while clips play.
func fit_head_bone(head := DUFF_HEAD) -> void:
	var body := get_child(0) as Node3D
	var now: float = HEAD.get(who, head) * body.scale.y
	var bone := skeleton.find_bone("Head")
	skeleton.set_bone_pose_scale(bone, Vector3.ONE * (head / now))
