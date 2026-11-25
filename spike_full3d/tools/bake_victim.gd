extends SceneTree
## Bake the thrown-foe clips for Return to Sender (Duff's call Nov 25: the held guy "looks very badly
## animated") onto Duff's rig, then copy them to every foe's library. One purchase plays on everyone:
## all Meshy rigs share the same 24 bones; only the hips height scales to each body.
##   flail: Meshy "Fall 2" (503), looped: kicking and waving while Duff carries him.
##   flyup: Meshy "BeHit FlyUp" (7), cut to the tumble and the flat landing; the game flies the arc,
##          so the clip's own jump is flattened.
##   godot --headless --path . --script tools/bake_victim.gd   (needs models/clips/duff_flail.glb, duff_flyup.glb)
const FOES := ["pirate", "mike", "sendback", "camper", "coupon", "allergy", "madison", "brittany"]
const FLYUP_END := 1.4    ## landed flat by ~.9 s; keep a beat of lying there
const FLYUP_TOP := 107.0  ## hips height (cm) at the start: the clip's jump above this is cut

func _initialize() -> void:
	var lib: AnimationLibrary = load("res://models/duff_clips.res")
	var flail := _clip("duff_flail")
	flail.loop_mode = Animation.LOOP_LINEAR
	_pin_hips(flail, 99999.0)
	var flyup := _cut(_clip("duff_flyup"), FLYUP_END)
	flyup.loop_mode = Animation.LOOP_NONE
	_pin_hips(flyup, FLYUP_TOP)
	for pair in [["flail", flail], ["flyup", flyup]]:
		if lib.has_animation(pair[0]):
			lib.remove_animation(pair[0])
		lib.add_animation(pair[0], pair[1])
	ResourceSaver.save(lib, "res://models/duff_clips.res")
	var duff_hips := _hips_height("duff")
	for who in FOES:
		var path := "res://models/%s_clips.res" % who
		if not ResourceLoader.exists(path) or not ResourceLoader.exists("res://models/%s.glb" % who):
			continue
		var own: AnimationLibrary = load(path)
		var ratio := _hips_height(who) / duff_hips
		for pair in [["flail", flail], ["flyup", flyup]]:
			var anim := (pair[1] as Animation).duplicate(true) as Animation
			for t in _hips_tracks(anim):
				for k in anim.track_get_key_count(t):
					anim.track_set_key_value(t, k, anim.track_get_key_value(t, k) * Vector3(1, ratio, 1))
			if own.has_animation(pair[0]):
				own.remove_animation(pair[0])
			own.add_animation(pair[0], anim)
		ResourceSaver.save(own, path)
		print("%s: flail + flyup (hips x%.2f)" % [who, ratio])
	print("VICTIM CLIPS DONE flail %.2fs flyup %.2fs" % [flail.length, flyup.length])
	quit()

func _clip(file: String) -> Animation:
	var scene: Node = (load("res://models/clips/%s.glb" % file) as PackedScene).instantiate()
	var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var anim := player.get_animation(player.get_animation_list()[0]).duplicate(true) as Animation
	scene.free()
	return anim

func _cut(anim: Animation, end: float) -> Animation:
	for t in anim.get_track_count():
		for k in range(anim.track_get_key_count(t) - 1, -1, -1):
			if anim.track_get_key_time(t, k) > end:
				anim.track_remove_key(t, k)
	anim.length = end
	return anim

## Hips stay over the feet (the game moves the body) and never rise above `top`.
func _pin_hips(anim: Animation, top: float) -> void:
	for t in _hips_tracks(anim):
		for k in anim.track_get_key_count(t):
			var v: Vector3 = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, Vector3(0, minf(v.y, top), 0))

func _hips_tracks(anim: Animation) -> Array:
	var out := []
	for t in anim.get_track_count():
		if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and str(anim.track_get_path(t)).ends_with(":Hips"):
			out.append(t)
	return out

func _hips_height(who: String) -> float:
	var scene: Node = (load("res://models/%s.glb" % who) as PackedScene).instantiate()
	var sk := scene.find_child("Skeleton3D", true, false) as Skeleton3D
	var y := sk.get_bone_rest(sk.find_bone("Hips")).origin.y
	scene.free()
	return y
