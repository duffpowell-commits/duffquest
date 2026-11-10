extends Node
## Renders every beat of a boss knockout cutscene. Run:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/ko_shot.tscn -- gymbro
## Video: add --fixed-fps 30 --write-movie /tmp/ko.avi --resolution 1280x720 and "-- gymbro video"
## -> /tmp/qa/ko_<boss>_<n>_<beat>.png (one shot per beat, ~1.4 s in) + /tmp/qa/loading.png
## Gore: "-- gymbro gore" (with --fixed-fps 30) -> /tmp/qa/ko_gore_<boss>_<n>.png, 3 frames of the x-ray hit
## and 3 of the finisher, fixed seed so reruns match. Sheet: python3 tools/ko_gore_sheet.py <boss>.
var game: Node
var m: Node
var ko: Node
var frame: = 0
var id: = "gymbro"
var shots: = 0
var video: = false                          # "-- gymbro video": play in real time (record with --write-movie)
var end_t: = -1
var gore: = false                           # "-- gymbro gore": shoot the blood frames
const GORE_SHOTS: = [[2, 0.10], [2, 0.30], [2, 0.60], [3, 0.40], [3, 0.80], [3, 1.20]]   # [beat, bt]
var gore_i: = 0

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		id = a[0]
	video = a.size() > 1 and a[1] == "video"
	gore = a.size() > 1 and a[1] == "gore"
	DirAccess.make_dir_recursive_absolute("/tmp/qa")
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _key(k: int) -> void:
	for p in [true, false]:
		var e: = InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)

func _find(n: Node, script_path: String) -> Node:
	for c in n.get_children():
		if c.get_script() and (c.get_script() as Script).resource_path == script_path:
			return c
		var r: = _find(c, script_path)
		if r:
			return r
	return null

func _process(_d: float) -> void:
	frame += 1
	if frame > 2000:
		get_tree().quit()
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		m.show_loading()
	if frame == 240:
		if not video:
			get_viewport().get_texture().get_image().save_png("/tmp/qa/loading.png")
		m.no_loading = true
		var ls: = _find(game, "res://scripts/loading_screen.gd")
		ls._finish()
		if id in ["ghoster", "gymbro", "djvape", "crypto", "willnot"]:
			m.start_story_fight(id)
	if frame == 250:
		m.dialog.clear()
		if m.arena_boss:
			m.boss_defeated(m.arena_boss)
		else:                                # bounty/waffle bosses: play the cutscene on its own
			m.ko_kind = id
		ko = _find(game, "res://scripts/knockout.gd")
		ko.fixed_seed = 1234
	if frame > 250 and ko and gore:
		if not ko.playing():
			return
		if ko.beat < 2:
			ko._next()
			return
		var s: Array = GORE_SHOTS[gore_i]
		if ko.beat < int(s[0]):
			ko._next()
			return
		if ko.bt >= float(s[1]):
			get_viewport().get_texture().get_image().save_png("/tmp/qa/ko_gore_%s_%d.png" % [id, gore_i])
			gore_i += 1
			if gore_i >= GORE_SHOTS.size():
				get_tree().quit()
		return
	if frame > 250 and ko and video:
		if not ko.playing():
			if end_t < 0:
				end_t = frame
			if frame > end_t + 75:           # 2.5 s of the normal win screen after it
				get_tree().quit()
		return
	if frame > 250 and ko:
		if not ko.playing():
			get_viewport().get_texture().get_image().save_png("/tmp/qa/ko_%s_after.png" % id)
			get_tree().quit()
			return
		ko.bt = minf(ko.bt, 2.0)            # hold each beat (under the 2.4 s minimum hold, so short beats never end themselves); we step them ourselves
		if frame % 100 == 0:
			get_viewport().get_texture().get_image().save_png("/tmp/qa/ko_%s_%d_%s.png" % [id, ko.beat, ko.BEATS[ko.beat]])
			ko._next()
