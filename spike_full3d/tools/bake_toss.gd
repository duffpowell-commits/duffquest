extends SceneTree
## Bake Return to Sender (`toss`) from Meshy's Over Shoulder Throw (action 421, Duff's pick Nov 25):
## the reach and grab, then the load, turn and throw over the shoulder, with the long hold between them
## cut out, the body turned so the grab faces straight ahead, and a tail that turns him back and stands
## him up into idle so the blend back to locomotion doesn't spin him.
##   godot --headless --path . --script tools/bake_toss.gd   (needs models/clips/duff_toss.glb)
const PARTS := [[.9, 1.45], [1.75, 3.7]]  ## source seconds kept: reach + grab, then load + turn + throw
const TAIL := .4         ## seconds crossfading into idle's first frame
const TURN := -33.0      ## degrees: the grab reaches 33 deg left of forward in the source
const STEP := 1.0 / 30

func _initialize() -> void:
	var lib: AnimationLibrary = load("res://models/duff_clips.res")
	var idle := lib.get_animation("idle")
	var scene: Node = (load("res://models/clips/duff_toss.glb") as PackedScene).instantiate()
	var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var src := player.get_animation(player.get_animation_list()[0])
	var kept := 0.0
	for part in PARTS:
		kept += part[1] - part[0]
	var anim := Animation.new()
	anim.length = kept + TAIL
	anim.loop_mode = Animation.LOOP_NONE
	for t in src.get_track_count():
		var type := src.track_get_type(t)
		var path := src.track_get_path(t)
		var bone := str(path).get_slice(":", 1)
		var nt := anim.add_track(type)
		anim.track_set_path(nt, path)
		anim.track_set_interpolation_type(nt, src.track_get_interpolation_type(t))
		var it := idle.find_track(path, type)
		var time := 0.0
		var last = null
		while time <= anim.length + .001:
			var v
			if time <= kept:
				v = _sample(src, t, _source_time(time))
				if bone == "Hips" and type == Animation.TYPE_POSITION_3D:
					v = Vector3(0, v.y, 0)  # the game moves him, not the clip
				if bone == "Hips" and type == Animation.TYPE_ROTATION_3D:
					v = Quaternion(Vector3.UP, deg_to_rad(TURN)) * v
				last = v
			else:
				var k := smoothstep(0, TAIL, time - kept)
				var to = _sample(idle, it, 0.0) if it >= 0 else last
				v = last.slerp(to, k) if type == Animation.TYPE_ROTATION_3D else last.lerp(to, k)
			anim.track_insert_key(nt, minf(time, anim.length), v)
			time += STEP
	if lib.has_animation("toss"):
		lib.remove_animation("toss")
	lib.add_animation("toss", anim)
	print("toss %.2fs (grab at %.2f, release at %.2f) clips=%s" % [anim.length, _new_time(1.4), _new_time(3.4), lib.get_animation_list()])
	ResourceSaver.save(lib, "res://models/duff_clips.res")
	scene.free()
	quit()

func _source_time(time: float) -> float:
	for part in PARTS:
		var span: float = part[1] - part[0]
		if time <= span:
			return part[0] + time
		time -= span
	return PARTS[-1][1]

func _new_time(source: float) -> float:
	var at := 0.0
	for part in PARTS:
		if source <= part[1]:
			return at + maxf(0, source - part[0])
		at += part[1] - part[0]
	return at

func _sample(a: Animation, t: int, time: float):
	match a.track_get_type(t):
		Animation.TYPE_POSITION_3D: return a.position_track_interpolate(t, time)
		Animation.TYPE_ROTATION_3D: return a.rotation_track_interpolate(t, time)
		Animation.TYPE_SCALE_3D: return a.scale_track_interpolate(t, time)
	return a.value_track_interpolate(t, time)
