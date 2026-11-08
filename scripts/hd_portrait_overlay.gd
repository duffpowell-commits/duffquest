extends Node2D
## Draws the HD cartoon dialogue portraits at the screen's real resolution, on top of the
## pixel game (which renders at 640×360 inside a SubViewport, see game.gd). Reads the dialogue
## state from main/hud and puts the face exactly where the HUD's portrait box is.
const Art: = preload("res://scripts/art.gd")
const Cast: = preload("res://scripts/cast.gd")

const UI_SCALE: = 2.0                       # main.gd UI_SCALE: HUD units -> 640×360 px
var main: Node                               # main.gd instance
var _tex: = {}

func _process(_d: float) -> void:
	queue_redraw()

func _portrait(who: String) -> Texture2D:
	if not _tex.has(who):
		var p: = "res://assets/art/portraits_hd/%s.png" % who
		_tex[who] = load(p) if ResourceLoader.exists(p) else null
	return _tex[who]

func _draw() -> void:
	if main == null or main.dialog.is_empty():
		return
	var line: String = Cast.T(str(main.dialog[0]))
	var who: String = Art.portrait_for(line, Cast.T("{hero}"), Cast.T("{partner}"), Cast.T("{baby}"))
	if who == "":
		return
	var tex: = _portrait(who)
	if tex == null:
		return
	var r: Rect2 = main.hud.layout()["dialog"]
	var pr: = Rect2((r.position + Vector2(6, 9)) * UI_SCALE, Vector2(48, 48) * UI_SCALE)
	var mood: = Art.hd_mood(who, line, float(main.energy), float(main.happiness), str(main.mood_kind()))
	var cell: = float(tex.get_height())
	# face a touch bigger than the box and rising out of its top edge, like a cartoon cut-in
	var size: = pr.size * 1.18
	var dst: = Rect2(Vector2(pr.get_center().x - size.x * 0.5, pr.end.y - size.y), size)
	draw_texture_rect_region(tex, dst, Rect2(mood * cell, 0, cell, cell))
	if who == "duff" and bool(main.shades):
		# sunglasses gag: a dark band across the eyes (eyes sit ~38% down the face cell)
		var ey: = dst.position.y + dst.size.y * 0.36
		draw_rect(Rect2(dst.position.x + dst.size.x * 0.30, ey, dst.size.x * 0.46, dst.size.y * 0.075), Color(0.05, 0.05, 0.08, 0.95))
