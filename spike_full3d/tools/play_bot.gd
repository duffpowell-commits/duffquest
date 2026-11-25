extends SceneTree
## Plays the porch like a person: real key events only (WASD, Space, Shift), ~0.25 s reaction time,
## no cheats. Logs what happened and saves a frame every half second for review.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/play_bot.gd -- <outdir> [skill]
## skill: good (dodges tells) | mash (walks in and mashes hit)

var out := "/tmp/play"
var skill := "good"
var log := []
var t := 0.0
var held := {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		skill = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("_run")

func _key(code: Key, down: bool) -> void:
	if held.get(code, false) == down:
		return
	held[code] = down
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = down
	Input.parse_input_event(e)

func _tap(code: Key) -> void:
	_key(code, true)
	await physics_frame
	_key(code, false)

func _steer(dir: Vector3) -> void:
	_key(KEY_D, dir.x > .3)
	_key(KEY_A, dir.x < -.3)
	_key(KEY_S, dir.z > .3)
	_key(KEY_W, dir.z < -.3)

func _note(s: String) -> void:
	log.append("%5.1fs %s" % [t, s])

func _run() -> void:
	change_scene_to_file("res://porch.tscn")
	await scene_changed
	var s = current_scene
	var shot := 0.0
	var react := 0.0
	var last_hp: int = s.player_hp
	var last_state := ""
	var seen_tell := false
	var swing_cd := 0.0
	var phase := "pirate"
	while t < 90.0:
		await physics_frame
		var now := Time.get_ticks_msec() / 1000.0
		var dt := now - _last
		_last = now
		t += dt
		swing_cd -= dt
		shot -= dt
		if shot <= 0:
			shot = .5
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_jpg("%s/f%04d.jpg" % [out, int(t * 10)], .8)
		s = current_scene
		if s.player_hp != last_hp:
			_note("Duff hit -> %d HP (foe %s)" % [s.player_hp, phase])
			last_hp = s.player_hp
		if not s.active:
			_note("encounter over: %s" % s.message.text)
			break
		if s.mike_state != last_state:
			_note("mike state %s" % s.mike_state)
			last_state = s.mike_state
		var foe = s.current_foe()
		var to: Vector3
		if s.pirate_hp > 0:
			phase = "pirate"
			to = s.pirate.position - s.player.position
		elif s.mike_state == "away":
			phase = "parcel"
			to = s.package.global_position - s.player.position
		elif s.mike_state == "ko":
			_note("Mike KO")
			_steer(Vector3.ZERO)
			for i in 90:
				await physics_frame
			break
		else:
			phase = "mike"
			to = s.mike.position - s.player.position
		to.y = 0
		var dist := to.length()
		# react to Mike's tells after a human delay
		var telling: bool = phase == "mike" and s.mike_state in ["post", "charge_tele"]
		if telling and not seen_tell:
			seen_tell = true
			react = .25
		if not telling:
			seen_tell = false
		if skill == "good" and react > 0:
			react -= dt
			if react <= 0:
				_note("dodge the %s" % s.mike_state)
				_steer(Vector3(-to.z, 0, to.x).normalized())  # sidestep
				await _tap(KEY_SHIFT)
				continue
		var reach := .3 if phase == "parcel" else 1.0
		if dist > reach:
			_steer(to.normalized())
		else:
			_steer(Vector3.ZERO)
			if swing_cd <= 0:
				# face the foe with a tap of the key towards it, then swing
				_steer(to.normalized())
				await physics_frame
				_steer(Vector3.ZERO)
				await _tap(KEY_SPACE)
				swing_cd = .45 if skill == "good" else .2
		if phase == "pirate" and s.pirate_hp != _pirate_last:
			_note("pirate hit -> %d" % s.pirate_hp)
			_pirate_last = s.pirate_hp
		if phase == "mike" and s.mike_hp != _mike_last:
			_note("Mike hit -> %d" % s.mike_hp)
			_mike_last = s.mike_hp
	_steer(Vector3.ZERO)
	_note("end: Duff %d HP, pirate %d, Mike %d (%s)" % [s.player_hp, s.pirate_hp, s.mike_hp, s.mike_state])
	var f := FileAccess.open(out + "/log.txt", FileAccess.WRITE)
	f.store_string("\n".join(log))
	print("\n".join(log))
	print("PLAY BOT DONE")
	quit()

var _last := Time.get_ticks_msec() / 1000.0
var _pirate_last := 3
var _mike_last := 6
