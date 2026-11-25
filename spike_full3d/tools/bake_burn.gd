extends SceneTree
## Bake the Red Right Hand swing (`burn`) from Duff's own right straight (`jab`, Meshy Right Jab from Guard)
## with a big coil added: the hips and shoulders twist back and the fist cocks before the drive.
## Duff Nov 25: "bigger wind-up" and the Kung Fu Punch cut "doesn't look like a punch at all".
##   godot --headless --path . --script tools/bake_burn.gd
const SRC := "jab"
const LENGTH := .95       ## the jab's guard -> full extension (.65 s) -> part way back
const COIL_HIPS := -20.0  ## extra degrees the hips turn away at the top of the coil
const COIL_CHEST := -40.0 ## extra degrees the chest turns away on top of that (right shoulder back)
const COIL_IN := .42      ## coil is full here...
const COIL_HOLD := .47    ## ...held to here...
const COIL_OUT := .62     ## ...and fully released by here (fist lands at .65)
const STEP := 1.0 / 30

func _initialize() -> void:
	var lib: AnimationLibrary = load("res://models/duff_clips.res")
	var src := lib.get_animation(SRC)
	var hips_rot := src.find_track(NodePath("Armature/Skeleton3D:Hips"), Animation.TYPE_ROTATION_3D)
	var anim := Animation.new()
	anim.length = LENGTH
	anim.loop_mode = Animation.LOOP_NONE
	for t in src.get_track_count():
		var type := src.track_get_type(t)
		var bone := str(src.track_get_path(t)).get_slice(":", 1)
		var nt := anim.add_track(type)
		anim.track_set_path(nt, src.track_get_path(t))
		anim.track_set_interpolation_type(nt, src.track_get_interpolation_type(t))
		var time := 0.0
		while time <= LENGTH + .001:
			var v = _sample(src, t, time)
			var w := _coil(time)
			if type == Animation.TYPE_ROTATION_3D and bone == "Hips":
				v = Quaternion(Vector3.UP, deg_to_rad(COIL_HIPS * w)) * v
			elif type == Animation.TYPE_ROTATION_3D and bone == "Spine02":
				# turn the chest about the world up axis, expressed in the hips' frame
				var qh: Quaternion = src.rotation_track_interpolate(hips_rot, time)
				v = qh.inverse() * Quaternion(Vector3.UP, deg_to_rad(COIL_CHEST * w)) * qh * v
			anim.track_insert_key(nt, minf(time, LENGTH), v)
			time += STEP
	if lib.has_animation("burn"):
		lib.remove_animation("burn")
	lib.add_animation("burn", anim)
	print("burn %.2fs tracks=%d clips=%s" % [anim.length, anim.get_track_count(), lib.get_animation_list()])
	ResourceSaver.save(lib, "res://models/duff_clips.res")
	quit()

func _coil(time: float) -> float:
	if time < COIL_IN:
		return smoothstep(0, COIL_IN, time)
	if time < COIL_HOLD:
		return 1.0
	return 1.0 - smoothstep(COIL_HOLD, COIL_OUT, time)

func _sample(a: Animation, t: int, time: float):
	match a.track_get_type(t):
		Animation.TYPE_POSITION_3D: return a.position_track_interpolate(t, time)
		Animation.TYPE_ROTATION_3D: return a.rotation_track_interpolate(t, time)
		Animation.TYPE_SCALE_3D: return a.scale_track_interpolate(t, time)
	return a.value_track_interpolate(t, time)
