extends Node2D
const Art: = preload("res://scripts/art.gd")
## Before/after sheet of every Duff outfit (4 facings each). Old sheets are read from OLD_DIR (PNG files
## exported from git), the new ones through Art like the game does.
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2560x1440 res://tools/outfit_shot.tscn -- OLD_DIR
## -> /tmp/qa/outfits.png

const OUTFITS: = [["apron", "duff_apron_red", "Apron (kitchen line only)"], ["home", "duff_home", "Casual tee (default, home)"],
	["clogs", "duff_clogs_red", "Clogs"], ["sleeves", "duff_sleeves_red", "Sleeves"], ["coat", "duff_coat_red", "Chef coat"],
	["dad", "duff_dad_red", "Dad jacket"]]
var old_dir: = "/tmp/claude-0/sp/old"
var frames: = 0
var old_tx: = {}   # textures must outlive _draw, or the canvas draws them white

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		old_dir = a[0]
	for o in OUTFITS:
		var img: = Image.load_from_file("%s/duff_%s.png" % [old_dir, "home" if o[0] == "home" else o[0] + "_red"])
		if img != null:
			old_tx[o[0]] = ImageTexture.create_from_image(img)

func _process(_d: float) -> void:
	frames += 1
	queue_redraw()
	if frames == 8:
		DirAccess.make_dir_recursive_absolute("/tmp/qa")
		get_viewport().get_texture().get_image().save_png("/tmp/qa/outfits.png")
		get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#2b2838"))
	var f: = ThemeDB.fallback_font
	draw_string(f, Vector2(8, 12), "Duff outfits: top row = old sheet, bottom row = new 2x", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.85))
	for i in OUTFITS.size():
		var o: Array = OUTFITS[i]
		var bx: = 8.0 + float(i % 3) * 210.0
		var by: = 22.0 + float(i / 3) * 168.0
		draw_rect(Rect2(bx - 3, by - 2, 204, 164), Color(1, 1, 1, 0.05))
		draw_string(f, Vector2(bx, by + 8), str(o[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#f2c66a"))
		var tx: ImageTexture = old_tx.get(o[0])
		for d in 4:
			var feet: = Vector2(bx + 24.0 + d * 50.0, by + 78.0)
			draw_set_transform(feet, 0.0, Vector2(2, 2))
			if tx != null:   # old: 64 px cells, origin (32, 60), 2 texels per unit
				draw_texture_rect_region(tx, Rect2(Vector2(-16, -30), Vector2(32, 32)), Rect2(0, d * 64, 64, 64))
			draw_set_transform(feet + Vector2(0, 74), 0.0, Vector2(2, 2))
			Art.frame(self, str(o[1]), Vector2.ZERO, 0, d)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
