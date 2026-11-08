extends Node
## M9 check: boots game.tscn, new game, then shows Palahniuk-layer lines in the real dialogue box.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/voice_shot.tscn
## -> /tmp/voice/*.png ; python3 tools/voice_sheet.py -> docs/renders/palahniuk_voice.png

const OUT: = "/tmp/voice/"
const FunFacts: = preload("res://scripts/fun_facts.gd")
var LINES: = [
	"So here's the deal. Keep {partner} happy. Pay the rent. Guard the porch. That's the whole religion. Heard.",
	"I pass out at 2 AM. Floor. Fully dressed. My body quit without notice. {partner} drags me to bed. -5 Happiness",
	"I get knocked out. Me and the sidewalk get acquainted. {partner} scrapes me off the curb. Again. Hell of a girl.",
	"Monday. Rent is due. Rent is always due.",
	FunFacts.FACTS[2],
	FunFacts.FACTS[0],
]
var frame: = 0
var game: Node
var m: Node
var i: = 0
var wait: = 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _key(k: int) -> void:
	for p in [true, false]:
		var e: = InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)

func _process(_d: float) -> void:
	frame += 1
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame < 200:
		return
	if m == null:
		m = game.get_child(0).get_child(0).get_child(0)
	if wait > 0:
		wait -= 1
		if wait == 0:
			get_viewport().get_texture().get_image().save_png(OUT + "v%d.png" % i)
			i += 1
		return
	if i >= LINES.size():
		print("voice_shot: done")
		get_tree().quit()
		return
	m.close_overlay()
	m.dialog.clear()
	m.toast_t = 0.0
	m._say([LINES[i]])
	wait = 10
