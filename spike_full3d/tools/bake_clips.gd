extends SceneTree
## Bakes each Meshy clip GLB in models/clips/ into one AnimationLibrary per character
## (models/<who>_clips.res), so the game ships one rigged mesh + small clip data instead
## of a full mesh copy per clip. Run after adding clips:
##   godot --headless --path . --import && godot --headless --path . --script tools/bake_clips.gd

const LOOPS := ["idle", "walking", "running", "charge"]

func _initialize() -> void:
	for who in ["duff", "pirate", "mike"]:
		var lib := AnimationLibrary.new()
		var dir := DirAccess.open("res://models/clips")
		for file in dir.get_files():
			if not file.begins_with(who + "_") or not file.ends_with(".glb"):
				continue
			var clip := file.get_basename().trim_prefix(who + "_")
			var scene: Node = (load("res://models/clips/" + file) as PackedScene).instantiate()
			var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
			var source := player.get_animation(player.get_animation_list()[0])
			var anim := source.duplicate(true) as Animation
			anim.loop_mode = Animation.LOOP_LINEAR if clip in LOOPS else Animation.LOOP_NONE
			_pin_hips(anim)
			lib.add_animation(clip, anim)
			print("%s %s %.2fs tracks=%d" % [who, clip, anim.length, anim.get_track_count()])
			scene.free()
		ResourceSaver.save(lib, "res://models/%s_clips.res" % who)
	quit()

## Keep clips in place: the game moves the body, so the hips may bob but not travel.
func _pin_hips(anim: Animation) -> void:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not str(anim.track_get_path(t)).ends_with(":Hips"):
			continue
		var first: Vector3 = anim.track_get_key_value(t, 0)
		for k in anim.track_get_key_count(t):
			var v: Vector3 = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))
