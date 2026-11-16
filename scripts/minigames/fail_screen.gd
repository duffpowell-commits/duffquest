extends "res://scripts/minigames/card.gd"

## Fail states (Nov 16): the eviction screen (three Mondays short on rent) and the game over screen
## (knocked out in a story fight or at the gala). Soft fails: the only ways out roll the day (or the week)
## back, never wipe the save. main.gd shows it via fail_screen(); the card's buttons sit along the bottom.

var kind: = "gameover"   # "evicted" | "gameover"

func _draw_game() -> void:
	if veiled:
		draw_rect(Rect2(0, 0, W, H), Color(UiStyle.INK, 0.58))
	else:
		UiStyle.burst(self, Rect2(0, 0, W, H), Color("#3a1622") if kind == "evicted" else Color("#2a1e36"), Vector2(W * 0.5, H * 0.45), 28, t * 0.04)
	# slow red pulse at the edges: something just went badly
	var pulse: = 0.12 + 0.06 * sin(t * 2.2)
	for i in 5:
		var g: = float(i) * 5.0
		draw_rect(Rect2(g, g, W - g * 2.0, H - g * 2.0), Color(UiStyle.BTN_EXIT, pulse * (1.0 - i * 0.18)), false, 5.0)
	if kind == "evicted":
		_draw_evicted()
	else:
		_draw_ko()
	# what happened + what the retry does, on a panel under the title
	var y: = 104.0
	var w1: = 196.0
	var hh: = 0.0
	for l in lines:
		hh += _wrap_h(str(l), w1)
	if hh > 0.0:
		UiStyle.panel(self, Rect2(112, y - 12, w1 + 8, hh + 8), UiStyle.PANEL, 0.92, 1.0)
	for l in lines:
		mtxt(Vector2(116, y), str(l), w1, 8, Color.WHITE)
		y += _wrap_h(str(l), w1)

func _draw_evicted() -> void:
	# boxes on the curb, Duff standing by them
	_duff(Vector2(54, 140), Vector2.DOWN, false)
	prop(Rect2(74, 118, 26, 20), Color("#b88a56"))
	prop(Rect2(78, 100, 20, 18), Color("#c99a62"))
	prop(Rect2(16, 122, 18, 16), Color("#b88a56"))
	draw_line(Vector2(78, 109), Vector2(98, 109), Color(UiStyle.INK, 0.5), 1.0)
	draw_line(Vector2(74, 128), Vector2(100, 128), Color(UiStyle.INK, 0.5), 1.0)
	txt(Vector2(80, 135), "STUFF", 5, Color(UiStyle.INK, 0.7))
	# the notice taped to the door, tilted, with the stamp over it
	draw_set_transform(Vector2(214, 40), deg_to_rad(-3.0), Vector2.ONE)
	prop(Rect2(-84, -30, 168, 62), Color("#f4ead2"), 0.12)
	draw_rect(Rect2(-14, -34, 28, 8), Color("#e8e2c0", 0.8))   # tape
	UiStyle.label(self, Vector2(-80, -17), "NOTICE TO VACATE", 9, UiStyle.INK, 160, HORIZONTAL_ALIGNMENT_CENTER, 0)
	for i in 3:
		draw_line(Vector2(-70, -8 + i * 6), Vector2(70 - i * 18, -8 + i * 6), Color(UiStyle.INK, 0.25), 1.0)
	draw_set_transform(Vector2(220, 52), deg_to_rad(-11.0), Vector2.ONE)
	var s: = 1.0 + maxf(0.0, 0.35 - t) * 1.6   # stamp slams in
	draw_set_transform(Vector2(220, 52), deg_to_rad(-11.0), Vector2(s, s))
	draw_rect(Rect2(-66, -16, 132, 30), Color(UiStyle.BTN_EXIT, 0.9), false, 2.5)
	UiStyle.label(self, Vector2(-66, 8), "EVICTED", 24, UiStyle.BTN_EXIT.lightened(0.1), 132, HORIZONTAL_ALIGNMENT_CENTER, 3)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ko() -> void:
	UiStyle.label(self, Vector2(0, 50), "KNOCKED OUT", 28, UiStyle.GOLD, W, HORIZONTAL_ALIGNMENT_CENTER, 4)
	UiStyle.label(self, Vector2(0, 66), "GAME OVER", 10, UiStyle.CREAM, W, HORIZONTAL_ALIGNMENT_CENTER, 3)
	# Duff flat on his back, stars going round
	var foot: = Vector2(92, 126)
	Art.shadow(self, foot + Vector2(-22, 12), 26.0, 3.5, 0.4)
	draw_set_transform(foot, deg_to_rad(-90.0), Vector2(2, 2))
	Art.person(self, "duff_home", Vector2.ZERO, Vector2.DOWN, 0.0, false, false, Color.WHITE, false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 3:
		var a: = t * 2.4 + i * TAU / 3.0
		var p: = foot + Vector2(-46, -16) + Vector2(cos(a) * 14.0, sin(a) * 4.0)
		_star(p, 3.0 + 0.6 * sin(t * 5.0 + i))

func _duff(foot: Vector2, dir: Vector2, moving: bool) -> void:
	draw_set_transform(foot, 0.0, Vector2(2, 2))
	Art.person(self, "duff_home", Vector2.ZERO, dir, t, moving)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _star(c: Vector2, r: float) -> void:
	var pts: = PackedVector2Array()
	for k in 10:
		var rr: = r if k % 2 == 0 else r * 0.45
		var a: = -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, UiStyle.GOLD)
	pts.append(pts[0])
	draw_polyline(pts, UiStyle.INK, 0.8)
