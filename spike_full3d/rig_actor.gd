class_name RigActor
extends Node3D
## A Meshy character on its real 24-bone humanoid skeleton, driven by real clips
## (models/<who>.glb + models/<who>_clips.res, see tools/bake_clips.gd).
## Faces -Z like the rest of the porch code; set rotation.y to turn it.

const BLEND := .12
const ONE_SHOTS := ["jab", "hook", "dodge", "hit", "ko"]

var skeleton: Skeleton3D
var player: AnimationPlayer
var current := ""
var locked := 0.0  ## seconds a one-shot keeps priority over locomotion

static func make(parent: Node3D, who: String, height := 1.6) -> RigActor:
	var actor := RigActor.new()
	actor.name = who.capitalize()
	parent.add_child(actor)
	var body: Node3D = (load("res://models/%s.glb" % who) as PackedScene).instantiate()
	body.rotation.y = PI  # glTF faces +Z
	actor.add_child(body)
	actor.skeleton = body.find_child("Skeleton3D", true, false)
	var top := actor.skeleton.get_bone_global_rest(actor.skeleton.find_bone("Head")).origin.y
	body.scale = Vector3.ONE * (height / ((top + 14.0) * .01))  # head bone sits ~14 cm under the crown
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
