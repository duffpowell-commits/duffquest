extends Node
## Renders every beat of a boss knockout cutscene. Run:
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/ko_shot.tscn -- gymbro
## Video: add --fixed-fps 30 --write-movie /tmp/ko.avi --resolution 1280x720 and "-- gymbro video"
## -> /tmp/qa/ko_<boss>_<n>_<beat>.png (one shot per beat, ~1.4 s in) + /tmp/qa/loading.png
var game: Node
var m: Node
var ko: Node
var frame: = 0
var id: = "gymbro"
var shots: = 0
var video: = false                          # "-- gymbro video": play in real time (record with --write-movie)
var end_t: = -1

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		id = a[0]
	video = a.size() > 1 and a[1] == "video"
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
		ko.bt = minf(ko.bt, 3.0)            # hold each beat; we step them ourselves
		if frame % 100 == 0:
			get_viewport().get_texture().get_image().save_png("/tmp/qa/ko_%s_%d_%s.png" % [id, ko.beat, ko.BEATS[ko.beat]])
			ko._next()
