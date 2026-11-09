extends Node2D
## Draws the HD cartoon dialogue portraits at the screen's real resolution, on top of the
## pixel game (which renders at 640×360 inside a SubViewport, see game.gd). Reads the dialogue
## state from main/hud and puts the face exactly where the HUD's portrait box is.
const Art: = preload("res://scripts/art.gd")
const Cast: = preload("res://scripts/cast.gd")

const UI_SCALE: = 2.0                       # main.gd UI_SCALE: HUD units -> 640×360 px
var main: Node                               # main.gd instance
var _tex: = {}
var _splash_boss: = ""                      # boss whose intro splash is up
var _splash_t: = 0.0                        # seconds since it appeared (slide-in)
const SPLASH_IN: = 0.28
const CARD_LIFT: = 0.13                     # share of the screen the intro card is lifted

func _process(d: float) -> void:
	_splash_t += d
	queue_redraw()

func _splash(boss: String) -> Texture2D:
	var key: = "intro_" + boss
	if not _tex.has(key):
		var p: = "res://assets/art/boss_intro/%s.png" % boss
		_tex[key] = load(p) if Art.has_intro_card(boss) else null
	return _tex[key]

## Boss intro card: Place's full-bleed "burst" card (Duff's pick, Nov 8) fills the screen and slides
## in from the right; the dialogue box stays visible on top (the card is drawn around it, not over it).
func _draw_splash(boss: String, box: Rect2) -> void:
	var tex: = _splash(boss)
	if tex == null:
		return
	if boss != _splash_boss:
		_splash_boss = boss
		_splash_t = 0.0
	var k: = clampf(_splash_t / SPLASH_IN, 0.0, 1.0)
	var e: = 1.0 - pow(1.0 - k, 3.0)                        # ease-out cubic
	var vp: = get_viewport_rect().size
	# Names on the cards run down to 70% of the card height; the dialogue box starts at 60% of the
	# screen. Lift the card by CARD_LIFT so every name clears the box, and fill the strip it leaves
	# at the bottom with an ink letterbox bar (comic panel look).
	var card: = Rect2(Vector2((1.0 - e) * vp.x, -vp.y * CARD_LIFT), vp)
	var bar_y: = card.end.y
	var slide: = Rect2(Vector2((1.0 - e) * vp.x, 0), vp)
	var bar: = Rect2(0, bar_y, vp.x, vp.y - bar_y).intersection(slide)
	var line: = Rect2(card.position.x, bar_y - 1.5, vp.x, 3.0)
	# everything is drawn only in the four strips around the dialogue box, never over it
	for strip in [Rect2(0, 0, vp.x, box.position.y), Rect2(0, box.end.y, vp.x, vp.y - box.end.y),
			Rect2(0, box.position.y, box.position.x, box.size.y), Rect2(box.end.x, box.position.y, vp.x - box.end.x, box.size.y)]:
		_blit(tex, card, strip)
		_fill(bar.intersection(strip), Color(0.06, 0.04, 0.08))
		_fill(line.intersection(strip), Color(0.02, 0.01, 0.03))

func _fill(r: Rect2, c: Color) -> void:
	if r.has_area():
		draw_rect(r, c)

## Draw the part of `tex` (stretched over `card`) that falls inside `clip`.
func _blit(tex: Texture2D, card: Rect2, clip: Rect2) -> void:
	var r: = card.intersection(clip)
	if not r.has_area():
		return
	var sc: = tex.get_size() / card.size
	draw_texture_rect_region(tex, r, Rect2((r.position - card.position) * sc, r.size * sc))

func _portrait(who: String) -> Texture2D:
	if not _tex.has(who):
		var p: = "res://assets/art/portraits_hd/%s.png" % who
		_tex[who] = load(p) if ResourceLoader.exists(p) else null
	return _tex[who]

func _draw() -> void:
	if main == null or main.dialog.is_empty():
		_splash_boss = ""
		return
	var line: String = Cast.T(str(main.dialog[0]))
	var r: Rect2 = main.hud.layout()["dialog"]
	var intro: = Art.boss_intro_for(line)
	if intro != "":
		_draw_splash(intro, Rect2(r.position * UI_SCALE, r.size * UI_SCALE))
	else:
		_splash_boss = ""
	var who: String = Art.portrait_for(line, Cast.T("{hero}"), Cast.T("{partner}"), Cast.T("{baby}"))
	if who == "":
		return
	var tex: = _portrait(who)
	if tex == null:
		return
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
