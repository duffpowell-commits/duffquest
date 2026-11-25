extends SceneTree
## Gives a new Meshy body the cast's clips for free. Every Meshy rig has the same 24 bones, so a
## clip made for Duff or Mike plays on anyone; only the hips height has to be scaled to the new
## body. Walk and run come with each rig (models/clips/<who>_walking|running.glb, free).
## Run after a new body lands in models/:
##   godot --headless --path . --import && godot --headless --path . --script tools/share_clips.gd
## Writes models/<who>_clips.res, the same thing rig_actor.gd loads for Duff, Mike and the Pirate.

## who -> [[source character, clip], ...]; the clip keeps its name.
const CAST := {
	"sendback": [["duff", "idle"], ["duff", "jab"], ["duff", "hook"], ["duff", "dodge"], ["duff", "hit"],
		["duff", "ko"], ["mike", "charge"], ["mike", "taunt"], ["mike", "throw"]],
	"camper": [["duff", "idle"], ["duff", "jab"], ["duff", "hook"], ["duff", "hit"], ["duff", "ko"],
		["mike", "throw"], ["mike", "taunt"]],
	"coupon": [["duff", "idle"], ["duff", "jab"], ["duff", "hit"], ["duff", "ko"], ["mike", "throw"],
		["mike", "taunt"]],
	"allergy": [["duff", "idle"], ["duff", "jab"], ["duff", "dodge"], ["duff", "hit"], ["duff", "ko"],
		["mike", "taunt"], ["mike", "throw"]],
	# Madison and Brittany (Nov 25, from their approved art; Duff OK'd the public repo): the moves a
	# home / block scene needs, plus fight reactions.
	"madison": [["duff", "idle"], ["duff", "jab"], ["duff", "dodge"], ["duff", "hit"], ["duff", "ko"],
		["mike", "taunt"], ["mike", "throw"]],
	"brittany": [["duff", "idle"], ["duff", "jab"], ["duff", "dodge"], ["duff", "hit"], ["duff", "ko"],
		["mike", "taunt"], ["mike", "throw"]],
}
const LOOPS := ["idle", "walking", "running", "charge"]

func _initialize() -> void:
	var made := 0
	for who in CAST:
		if not ResourceLoader.exists("res://models/%s.glb" % who):
			print("skip %s: no models/%s.glb yet" % [who, who])
			continue
		var hips := _hips_height(who)
		var cache := {}
		var lib := AnimationLibrary.new()
		for pick in CAST[who]:
			var src_path := "res://models/%s_clips.res" % pick[0]
			if not ResourceLoader.exists(src_path):
				push_error("missing %s: bake it first (tools/bake_clips.gd)" % src_path)
				continue
			var src: AnimationLibrary = load(src_path)
			if not src.has_animation(pick[1]):
				push_error("%s has no clip %s" % [pick[0], pick[1]])
				continue
			var anim := src.get_animation(pick[1]).duplicate(true) as Animation
			if not cache.has(pick[0]):
				cache[pick[0]] = _hips_height(pick[0])
			_scale_hips(anim, hips / cache[pick[0]])
			lib.add_animation(pick[1], anim)
		for own in ["walking", "running"]:
			var path := "res://models/clips/%s_%s.glb" % [who, own]
			if not ResourceLoader.exists(path):
				continue
			var scene: Node = (load(path) as PackedScene).instantiate()
			var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
			var anim := player.get_animation(player.get_animation_list()[0]).duplicate(true) as Animation
			anim.loop_mode = Animation.LOOP_LINEAR
			_pin_hips(anim)
			lib.add_animation(own, anim)
			scene.free()
		for clip in lib.get_animation_list():
			lib.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if clip in LOOPS else Animation.LOOP_NONE
		ResourceSaver.save(lib, "res://models/%s_clips.res" % who)
		print("%s: %s (hips %.3f)" % [who, ", ".join(lib.get_animation_list()), hips])
		made += 1
	print("SHARE CLIPS DONE %d" % made)
	quit()

func _hips_height(who: String) -> float:
	var scene: Node = (load("res://models/%s.glb" % who) as PackedScene).instantiate()
	var sk := scene.find_child("Skeleton3D", true, false) as Skeleton3D
	var y := sk.get_bone_rest(sk.find_bone("Hips")).origin.y
	scene.free()
	return y

func _hips_tracks(anim: Animation) -> Array:
	var out := []
	for t in anim.get_track_count():
		if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and str(anim.track_get_path(t)).ends_with(":Hips"):
			out.append(t)
	return out

## A shorter body crouches the same amount, not the same centimetres.
func _scale_hips(anim: Animation, ratio: float) -> void:
	for t in _hips_tracks(anim):
		for k in anim.track_get_key_count(t):
			anim.track_set_key_value(t, k, anim.track_get_key_value(t, k) * ratio)

## Keep clips in place (same as bake_clips.gd): the game moves the body.
func _pin_hips(anim: Animation) -> void:
	for t in _hips_tracks(anim):
		var first: Vector3 = anim.track_get_key_value(t, 0)
		for k in anim.track_get_key_count(t):
			var v: Vector3 = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))
