extends Node3D
## A Meshy character on its real 24-bone humanoid skeleton, driven by real clips
## (models/<who>.glb + models/<who>_clips.res, see tools/bake_clips.gd).
## Faces -Z like the rest of the porch code; set rotation.y to turn it.

const BLEND := .12
## Crown-to-chin of each unit-scale model in metres (hair, hood and bun included), measured from
## front renders (tools/cast_shot.gd --heads). Duff's head is the yardstick for the whole cast.
const HEAD := {"duff": .344, "mike": .402, "pirate": .452, "sendback": .322, "camper": .418,
	"coupon": .512, "allergy": .312}
## Duff's head in the game world (his model is fitted to DUFF height in porch.gd).
const DUFF_HEAD := .365

var skeleton: Skeleton3D
var player: AnimationPlayer
var current := ""
var locked := 0.0  ## seconds a one-shot keeps priority over locomotion
var who := ""

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
	actor.play("idle")
	return actor

func _process(delta: float) -> void:
	locked = maxf(0, locked - delta)

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
