extends SceneTree
## Bake the Red Right Hand swing (`burn`) from Duff's own right straight (`jab`, Meshy Right Jab from Guard)
## with a big coil added: the hips and shoulders twist back and the fist cocks before the drive.
## Duff Nov 25: "bigger wind-up", the Kung Fu Punch cut "doesn't look like a punch at all", then "even bigger wind-up":
## deeper twist, a crouch, and the cocked fist held before the release.
##   godot --headless --path . --script tools/bake_burn.gd
const SRC := "jab"
const SRC_END := .95      ## the jab's guard -> full extension (.65 s) -> part way back
const COCK := .42         ## jab time where the fist is furthest back: held here
const HOLD := .3          ## seconds the cocked fist is held (the jab freezes, the coil keeps deepening)
const LENGTH := SRC_END + HOLD
const COIL_HIPS := -32.0  ## extra degrees the hips turn away at the top of the coil
const COIL_CHEST := -62.0 ## extra degrees the chest turns away on top of that (right shoulder back)
const DIP := 9.0          ## hips sink this many cm into the coil
const COIL_IN := .42      ## coil 80% here...
const COIL_FULL := COCK + HOLD  ## ...full at the end of the hold...
const COIL_OUT := COCK + HOLD + .2  ## ...and fully released by here (fist lands at .95)
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
			var st := time if time < COCK else (COCK if time < COCK + HOLD else time - HOLD)
			var v = _sample(src, t, st)
			var w := _coil(time)
			if type == Animation.TYPE_ROTATION_3D and bone == "Hips":
				v = Quaternion(Vector3.UP, deg_to_rad(COIL_HIPS * w)) * v
			elif type == Animation.TYPE_POSITION_3D and bone == "Hips":
				v -= Vector3(0, DIP * w, 0)
			elif type == Animation.TYPE_ROTATION_3D and bone == "Spine02":
				# turn the chest about the world up axis, expressed in the hips' frame
				var qh: Quaternion = src.rotation_track_interpolate(hips_rot, st)
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
		return .8 * smoothstep(0, COIL_IN, time)
	if time < COIL_FULL:
		return lerpf(.8, 1.0, (time - COIL_IN) / (COIL_FULL - COIL_IN))
	return 1.0 - smoothstep(COIL_FULL, COIL_OUT, time)

func _sample(a: Animation, t: int, time: float):
	match a.track_get_type(t):
		Animation.TYPE_POSITION_3D: return a.position_track_interpolate(t, time)
		Animation.TYPE_ROTATION_3D: return a.rotation_track_interpolate(t, time)
		Animation.TYPE_SCALE_3D: return a.scale_track_interpolate(t, time)
	return a.value_track_interpolate(t, time)
