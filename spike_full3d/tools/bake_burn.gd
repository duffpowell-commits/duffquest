extends SceneTree
## Bake the Red Right Hand swing: cut the stepping right straight (3.0-3.5 s) out of Meshy's Kung Fu
## Punch routine (action 96), turn it so the fist points straight ahead (the routine throws it
## sideways), and pin the hips so the game drives the dash.
##   godot --headless --path . --script tools/bake_burn.gd   (needs models/clips/duff_burn.glb)
const FROM := 3.0
const TO := 3.5
const TURN := 84.0  ## degrees: the fist points -84 deg off forward at full extension (3.42 s)
func _initialize() -> void:
	var lib: AnimationLibrary = load("res://models/duff_clips.res")
	var scene: Node = (load("res://models/clips/duff_burn.glb") as PackedScene).instantiate()
	var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var src := player.get_animation(player.get_animation_list()[0])
	var anim := Animation.new()
	anim.length = TO - FROM
	anim.loop_mode = Animation.LOOP_NONE
	for t in src.get_track_count():
		var nt := anim.add_track(src.track_get_type(t))
		anim.track_set_path(nt, src.track_get_path(t))
		anim.track_set_interpolation_type(nt, src.track_get_interpolation_type(t))
		var is_hips := src.track_get_type(t) == Animation.TYPE_POSITION_3D and str(src.track_get_path(t)).ends_with(":Hips")
		var times := [FROM]
		for k in src.track_get_key_count(t):
			var kt := src.track_get_key_time(t, k)
			if kt > FROM and kt < TO:
				times.append(kt)
		times.append(TO)
		var is_hip_turn := src.track_get_type(t) == Animation.TYPE_ROTATION_3D and str(src.track_get_path(t)).ends_with(":Hips")
		for kt in times:
			var v = _sample(src, t, kt)
			if is_hips:
				v = Vector3(0, v.y, 0)  # the routine wanders 1.5 m off its root; keep the body over the feet
			if is_hip_turn:
				v = Quaternion(Vector3.UP, deg_to_rad(TURN)) * v
			anim.track_insert_key(nt, kt - FROM, v)
	if lib.has_animation("burn"):
		lib.remove_animation("burn")
	lib.add_animation("burn", anim)
	print("burn %.2fs tracks=%d clips=%s" % [anim.length, anim.get_track_count(), lib.get_animation_list()])
	ResourceSaver.save(lib, "res://models/duff_clips.res")
	scene.free()
	quit()

func _sample(a: Animation, t: int, time: float):
	match a.track_get_type(t):
		Animation.TYPE_POSITION_3D: return a.position_track_interpolate(t, time)
		Animation.TYPE_ROTATION_3D: return a.rotation_track_interpolate(t, time)
		Animation.TYPE_SCALE_3D: return a.scale_track_interpolate(t, time)
	return a.value_track_interpolate(t, time)
