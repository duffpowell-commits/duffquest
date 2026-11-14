extends Node2D
const Art: = preload("res://scripts/art.gd")
## Before/after sheet for a sprite batch (4 facings each, idle frame + action frame).
## Old sheets are PNGs in OLD_DIR named like the sheet id (export them from git first); any cell size works
## because every sheet spans the same 32x32 world units. New ones draw through Art like the game.
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 2560x1440 res://tools/cast_shot.tscn -- OLD_DIR id[:Label] ...
## -> /tmp/qa/cast.png

var old_dir: = "/tmp/claude-0/sp/old"
var ids: = []
var frames: = 0
var old_tx: = {}   # textures must outlive _draw, or the canvas draws them white

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		old_dir = a[0]
	for i in range(1, a.size()):
		var p: PackedStringArray = a[i].split(":")
		ids.append([p[0], p[1] if p.size() > 1 else p[0]])
	for e in ids:
		var img: = Image.load_from_file("%s/%s.png" % [old_dir, e[0]])
		if img != null:
			old_tx[e[0]] = ImageTexture.create_from_image(img)

func _process(_d: float) -> void:
	frames += 1
	queue_redraw()
	if frames == 8:
		DirAccess.make_dir_recursive_absolute("/tmp/qa")
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cast.png")
		get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#2b2838"))
	var f: = ThemeDB.fallback_font
	draw_string(f, Vector2(8, 12), "Top row = old sheet, bottom row = new. Facings down, up, right, left, then the action frame.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.85))
	var per_row: = 2
	for i in ids.size():
		var e: Array = ids[i]
		var bx: = 8.0 + float(i % per_row) * 316.0
		var by: = 22.0 + float(i / per_row) * 168.0
		draw_rect(Rect2(bx - 3, by - 2, 310, 164), Color(1, 1, 1, 0.05))
		draw_string(f, Vector2(bx, by + 8), str(e[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#f2c66a"))
		var tx: ImageTexture = old_tx.get(e[0])
		var cell: = 64.0
		if tx != null:
			cell = tx.get_width() / 4.0
		for k in 5:
			var d: = k if k < 4 else 0
			var col: = 0 if k < 4 else 3
			var feet: = Vector2(bx + 30.0 + k * 60.0, by + 78.0)
			draw_set_transform(feet, 0.0, Vector2(2, 2))
			if tx != null:
				draw_texture_rect_region(tx, Rect2(Vector2(-16, -30), Vector2(32, 32)), Rect2(col * cell, d * cell, cell, cell))
			draw_set_transform(feet + Vector2(0, 74), 0.0, Vector2(2, 2))
			Art.frame(self, str(e[0]), Vector2.ZERO, col, d)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
