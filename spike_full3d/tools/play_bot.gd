extends SceneTree
## Plays the porch like a person: real key events only (WASD, Space, Shift), ~0.25 s reaction time,
## no cheats. Time is game time, so a slow sandbox render plays like a phone at 60.
## Logs what happened and saves a frame every half second for review.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script tools/play_bot.gd -- <outdir> [skill]
## skill: good (dodges the red-ring tells, two hits then waits for the next swing) | mash (walks in and mashes hit)

var out := "/tmp/play"
var skill := "good"
var lines := []
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
	Input.flush_buffered_events()  # deliver now: at sandbox FPS a buffered tap reaches the game a third of a second late

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
	lines.append("%5.1fs %s" % [t, s])

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
		var dt: float = current_scene.clock - _clock  # game time: slow renders don't make it slower
		_clock = current_scene.clock
		t += dt
		swing_cd -= dt
		shot -= dt
		if shot <= 0:
			shot = .5
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_jpg("%s/f%04d.jpg" % [out, int(t * 10)], .8)
		s = current_scene
		if s.blocked != _blocked_last:
			_note("blocked! counter coming")
			_blocked_last = s.blocked
			row = 0
		if s.player_hp != last_hp:
			_note("Duff hit -> %d HP (foe %s)" % [s.player_hp, phase])
			last_hp = s.player_hp
		if not s.active:
			_note("encounter over: %s" % s.message.text)
			break
		if s.mike_state != last_state:
			_note("mike state %s" % s.mike_state)
			last_state = s.mike_state
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
		var telling: bool = s.tell_foe != null  # the red ring under a foe
		if telling and not seen_tell:
			seen_tell = true
			react = .25
		if not telling:
			seen_tell = false
		if skill == "good" and react > 0:
			react -= dt
			if react <= 0:
				var jab: bool = phase == "pirate" or s.mike_state == "jab_tele"
				_note("dodge the %s" % ("jab" if jab else s.mike_state))
				_steer(-to.normalized() if jab else Vector3(-to.z, 0, to.x).normalized())  # back out / sidestep
				await _tap(KEY_SHIFT)
				continue
		var reach := .3 if phase == "parcel" else 1.0
		if dist > reach:
			_steer(to.normalized())
		else:
			_steer(Vector3.ZERO)
			if t - _hit_t > .9:
				row = 0  # a new flurry
			var most := 1 if phase == "mike" and s.mike_raged else 2
			var waiting: bool = skill == "good" and (row >= most or s.mike_state == "taunt")  # then wait for his swing
			if swing_cd <= 0 and not waiting:
				# face the foe with a tap of the key towards it, then swing
				_steer(to.normalized())
				await physics_frame
				_steer(Vector3.ZERO)
				await _tap(KEY_SPACE)
				if skill == "mash":
					await _tap(KEY_SPACE)  # a thumb mashing taps again mid-swing (at sandbox FPS one tap a frame would look like rhythm)
				swing_cd = .45 if skill == "good" else .2
		if phase == "pirate" and s.pirate_hp != _pirate_last:
			_note("pirate hit -> %d" % s.pirate_hp)
			row += 1
			_hit_t = t
			_pirate_last = s.pirate_hp
		if phase == "mike" and s.mike_hp != _mike_last:
			_note("Mike hit -> %d" % s.mike_hp)
			row += 1 if s.mike_state != "dizzy" else 0
			_hit_t = t
			_mike_last = s.mike_hp
	_steer(Vector3.ZERO)
	_note("game time %.1fs, %d FPS" % [s.clock, Engine.get_frames_per_second()])
	_note("end: Duff %d HP, pirate %d, Mike %d (%s)" % [s.player_hp, s.pirate_hp, s.mike_hp, s.mike_state])
	var f := FileAccess.open(out + "/log.txt", FileAccess.WRITE)
	f.store_string("\n".join(lines))
	print("\n".join(lines))
	print("PLAY BOT DONE")
	quit()

var _pirate_last := 5
var _mike_last := 8
var _blocked_last := 0
var _clock := 0.0
var _hit_t := -9.0
var row := 0  ## hits landed in a row (a player counts their own)
