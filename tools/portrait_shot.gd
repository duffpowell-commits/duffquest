extends Node
## Renders the dialogue box with every HD portrait and mood, for checking by eye.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/portrait_shot.tscn
## -> /tmp/portraits/NN.png (contact sheet assembled outside)

const CASES: = [
	["I got promoted! Heck yeah.", 80.0],
	["So where was I.", 80.0],
	["Some thief stole my package off the porch.", 80.0],
	["{partner}: Love you, babe.", 95.0],
	["{partner}: Ugh. Seriously?", 60.0],
	["{partner}: You said six. It's nine.", 20.0],
	["{baby} giggles at the cat.", 80.0],
	["{baby} stares at the ceiling fan.", 80.0],
	["{baby} wails at 3 AM.", 80.0],
	["Brittany: Hey! Best day ever!", 80.0],
	["Brittany: Okay.", 80.0],
	["Brittany: You stole my fries? Unbelievable.", 80.0],
	["Elon Husk: Funding secured.", 80.0],
	["Elon Husk: WHO SHORTED MY JETPACK?!", 80.0],
	["Jeff Bozos: Two-day delivery. On you.", 80.0],
	["Jeff Bozos: NO RETURNS!", 80.0],
	["Bill Fences: Please wait. Updating.", 80.0],
	["Bill Fences: FATAL EXCEPTION!!", 80.0],
	["The Donald: Tremendous. Huge.", 80.0],
	["The Donald: TARIFF! TARIFF!", 80.0],
	["Bruce Willnot: Yippee.", 80.0],
	["Bruce Willnot: GET OFF MY FLOOR!", 80.0],
]
var frame: = 0
var game: Node
var main: Node

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/portraits")
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
	if frame == 180:
		main = game.find_child("Main", true, false)
		if main == null:
			for c in game.find_children("*", "", true, false):
				if c.get("dialog") != null and c.get("hud") != null:
					main = c
					break
	var i: = (frame - 200) / 10
	if frame >= 200 and i < CASES.size():
		if (frame - 200) % 10 == 0:
			main.happiness = CASES[i][1]
			main.dialog.clear()
			main.dialog.append(CASES[i][0])
		elif (frame - 200) % 10 == 8:
			get_viewport().get_texture().get_image().save_png("/tmp/portraits/%02d.png" % i)
	if frame == 200 + CASES.size() * 10 + 5:
		get_tree().quit()
