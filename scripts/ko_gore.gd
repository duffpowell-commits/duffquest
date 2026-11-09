extends Node2D
## Cartoon gore for the knockout cutscenes (art rule H2: spit, cartoon blood, teeth; no organs, no
## dismemberment). Canva blocks blood, so it lives here, in code. knockout.gd adds this node only when
## the "Cartoon gore" setting is ON, and frees it when the cutscene ends, so OFF = no gore node at all.
##
## Everything is a pure function of (seed, beat, seconds into the beat): the particle list is rebuilt
## from a seeded RNG when the beat changes and each particle's position is worked out from its spawn
## time, so a render at the same bt is the same picture every time (and skipping a beat just drops it).
##
## Look: chunky flat red teardrops with a thick ink outline and a white glint, a lighter spit arc out
## of the mouth, a molar or two tumbling end over end, and a jagged red splat star at the impact.
## Hits fire on the same seconds as the KO SFX_CUES (crack on the x-ray, snaps + boom on the finisher).

const RED: = Color("#e0192b")
const RED_DARK: = Color("#8c0a18")
const SPIT: = Color("#f2546a")
const GLINT: = Color("#fff4f0")
const TOOTH: = Color("#fffbe8")
const INK: = Color(0.03, 0.02, 0.04)

## beat -> [[seconds into beat, size, impact index, (optional) spray dir in degrees]];
## size "big" = spray + spit + teeth, "small" = spray.
## Times match knockout.gd SFX_CUES (tests check that).
const HITS: = {
	"xray": [[0.0, "big", 0]],
	"finisher": [[0.0, "small", 0], [0.35, "small", 1], [0.70, "small", 2], [1.05, "big", 2, -115.0]],
}
## Default impact points as a share of the stage rect (x, y), spray direction in degrees (0 = right,
## -90 = up), spit/teeth direction "spit" (degrees, default -12: out sideways so the arc stays on screen).
## Override per boss in data/knockouts.json: "impact": {"xray": {"at": [x, y], "mouth": [x, y],
## "dir": deg, "spit": deg}, "finisher": {"at": [[x, y], [x, y], [x, y]], "dir": deg}}.
const DEFAULTS: = {
	"xray": {"at": [[0.56, 0.42]], "dir": -25.0},
	"finisher": {"at": [[0.24, 0.22], [0.62, 0.30], [0.90, 0.48]], "dir": -20.0, "spread": 0.5},
}
const TOOTH_POLY: = [Vector2(-1.0, -0.75), Vector2(-0.6, -1.0), Vector2(0.0, -0.8), Vector2(0.6, -1.0),
	Vector2(1.0, -0.75), Vector2(1.0, 0.1), Vector2(0.72, 0.42), Vector2(0.58, 1.05), Vector2(0.26, 1.05),
	Vector2(0.12, 0.48), Vector2(-0.12, 0.48), Vector2(-0.26, 1.05), Vector2(-0.58, 1.05),
	Vector2(-0.72, 0.42), Vector2(-1.0, 0.1)]

var seed_base: = 0
var beat_name: = ""
var bt: = 0.0
var stage: = Rect2()
var offset: = Vector2.ZERO               # the cutscene's screen shake, so the blood shakes with the art
var impact: = {}                         # this boss's override from knockouts.json ({} = defaults)
var parts: Array = []                    # particle dicts for the current beat
var _built: = ""

## Called by knockout.gd every frame.
func sync(beat: String, t: float, stage_rect: Rect2, off: Vector2) -> void:
	var key: = "%s|%s" % [beat, stage_rect]
	if key != _built:
		_built = key
		beat_name = beat
		stage = stage_rect
		parts = build(beat)
	bt = t
	offset = off
	queue_redraw()

func _cfg(beat: String) -> Dictionary:
	var d: Dictionary = (DEFAULTS.get(beat, {}) as Dictionary).duplicate()
	var o: Variant = impact.get(beat, null)
	if o is Dictionary:
		for k in o:
			d[k] = o[k]
	var at: Variant = d.get("at", [[0.5, 0.5]])
	if at is Array and (at as Array).size() == 2 and not ((at as Array)[0] is Array):
		at = [at]                            # a single [x, y] is fine too
	d["at"] = at
	return d

func _pt(frac: Variant) -> Vector2:
	return stage.position + stage.size * Vector2(float(frac[0]), float(frac[1]))

## Impact point (screen px) for a beat, also used by knockout.gd for the x-ray crack lines.
func impact_point(beat: String, i: int = 0) -> Vector2:
	var at: Array = _cfg(beat)["at"]
	return _pt(at[mini(i, at.size() - 1)])

func build(beat: String) -> Array:
	var out: Array = []
	if not HITS.has(beat) or stage.size.y <= 0.0:
		return out
	var cfg: = _cfg(beat)
	var at: Array = cfg["at"]
	var dir0: = deg_to_rad(float(cfg.get("dir", -25.0)))
	var spit: = deg_to_rad(float(cfg.get("spit", -12.0)))
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_base * 31 + beat.hash()
	var u: = stage.size.y                    # all speeds / sizes are in stage heights
	for h in HITS[beat]:
		var t0: = float(h[0])
		var big: bool = h[1] == "big"
		var dir: = deg_to_rad(float(h[3])) if (h as Array).size() > 3 else dir0
		var p: = _pt(at[mini(int(h[2]), at.size() - 1)])
		var mouth: = _pt(cfg["mouth"]) if cfg.has("mouth") else p
		if beat == "finisher" and not big:
			mouth = p
		out.append({"k": "splat", "t0": t0, "p": p, "r": u * (0.11 if big else 0.07), "rot": rng.randf() * TAU,
			"life": 0.22, "jag": rng.randi()})
		var n: = 20 if big else 7
		var spread: = float(cfg.get("spread", 0.85)) if (h as Array).size() <= 3 else 0.9
		for i in n:                          # the spray: chunky teardrops fanning out from the hit
			var a: = dir + rng.randf_range(-spread, spread)
			var sp: = u * rng.randf_range(0.9, 2.1) * (1.0 if big else 0.8)
			out.append({"k": "drop", "t0": t0 + rng.randf_range(0.0, 0.05), "p": p, "v": Vector2.from_angle(a) * sp,
				"g": u * 2.6, "r": u * rng.randf_range(0.013, 0.032) * (1.0 if big else 0.85),
				"life": rng.randf_range(0.65, 1.15) if big else rng.randf_range(0.3, 0.42),   # small: gone before the next panel cut
				"c": RED if rng.randf() < 0.75 else RED_DARK})
		if not big:
			continue
		for i in 11:                         # spit: a tight arcing stream out of the mouth, a beat late
			var a2: = spit + rng.randf_range(-0.12, 0.12)
			out.append({"k": "drop", "t0": t0 + 0.03 + i * 0.014, "p": mouth, "v": Vector2.from_angle(a2) * u * rng.randf_range(1.1, 1.45),
				"g": u * 2.2, "r": u * rng.randf_range(0.007, 0.014), "life": 0.95, "c": SPIT})
		for i in (2 if beat == "xray" else 1):   # a tooth or two, tumbling
			var a3: = spit - 0.35 + rng.randf_range(-0.15, 0.15) + i * 0.4
			out.append({"k": "tooth", "t0": t0 + 0.04 + i * 0.05, "p": mouth, "v": Vector2.from_angle(a3) * u * rng.randf_range(0.75, 1.0),
				"g": u * 2.4, "s": u * rng.randf_range(0.036, 0.044), "rot": rng.randf() * TAU,
				"spin": rng.randf_range(9.0, 15.0) * (1.0 if rng.randf() < 0.5 else -1.0), "life": 1.5})
	return out

## Particles alive right now (tests and the draw use this).
func alive() -> Array:
	var out: = []
	for q in parts:
		var a: = bt - float(q["t0"])
		if a >= 0.0 and a < float(q["life"]):
			out.append(q)
	return out

func _draw() -> void:
	if parts.is_empty():
		return
	draw_set_transform(offset, 0.0, Vector2.ONE)
	var ow: = maxf(2.0, stage.size.y * 0.008)  # ink outline width, scales with the screen
	var clip: = stage.grow(-1.0)
	for q in alive():
		var a: = bt - float(q["t0"])
		match str(q["k"]):
			"splat": _splat(q, a, ow)
			"drop": _drop(q, a, ow, clip)
			"tooth": _tooth(q, a, ow, clip)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _pos(q: Dictionary, a: float) -> Vector2:
	return (q["p"] as Vector2) + (q["v"] as Vector2) * a + Vector2(0, float(q["g"])) * 0.5 * a * a

func _drop(q: Dictionary, a: float, ow: float, clip: Rect2) -> void:
	var pos: = _pos(q, a)
	if not clip.has_point(pos):
		return
	var v: = (q["v"] as Vector2) + Vector2(0, float(q["g"])) * a
	var r: = float(q["r"]) * clampf((float(q["life"]) - a) / 0.25, 0.0, 1.0) * clampf(a / 0.04 + 0.4, 0.0, 1.0)
	if r < 0.8:
		return
	var stretch: = clampf(v.length() / (stage.size.y * 1.2), 0.4, 1.6)
	var d: = v.normalized() if v.length() > 0.01 else Vector2.DOWN
	draw_colored_polygon(_tear(pos, d, r + ow, stretch), INK)
	draw_colored_polygon(_tear(pos, d, r, stretch), q["c"])
	draw_circle(pos - d * r * 0.15 + d.orthogonal() * r * 0.35, r * 0.28, GLINT)

## A teardrop: round front facing the way it flies, pointed tail behind.
func _tear(pos: Vector2, d: Vector2, r: float, stretch: float) -> PackedVector2Array:
	var pts: = PackedVector2Array()
	var base: = d.angle()
	for i in 11:
		var ang: = base - PI * 0.5 + PI * i / 10.0
		pts.append(pos + Vector2.from_angle(ang) * r)
	pts.append(pos - d * r * (1.25 + stretch * 0.75))
	return pts

func _tooth(q: Dictionary, a: float, ow: float, clip: Rect2) -> void:
	var pos: = _pos(q, a)
	if not clip.has_point(pos):
		return
	var s: = float(q["s"]) * clampf((float(q["life"]) - a) / 0.2, 0.0, 1.0)
	if s < 2.0:
		return
	## transformed by hand (a scaled draw transform smears the outline): ink copy grown by the
	## outline width underneath, then the white crown, a red tip on the roots, a shine stripe
	var xf: = Transform2D(float(q["rot"]) + float(q["spin"]) * a, pos)
	var ink: = PackedVector2Array()
	var fill: = PackedVector2Array()
	for v in TOOTH_POLY:
		ink.append(xf * ((v as Vector2) * (s + ow * 1.2)))
		fill.append(xf * ((v as Vector2) * s))
	draw_colored_polygon(ink, INK)
	draw_colored_polygon(fill, TOOTH)
	draw_circle(xf * (Vector2(-0.42, 0.82) * s), s * 0.2, RED)
	draw_circle(xf * (Vector2(0.42, 0.82) * s), s * 0.16, RED)
	draw_line(xf * (Vector2(-0.6, -0.45) * s), xf * (Vector2(-0.15, -0.55) * s), Color("#cfc6b0"), maxf(1.5, s * 0.14))

func _splat(q: Dictionary, a: float, ow: float) -> void:
	## jagged red star at the impact: pops big in 0.05 s, shrinks away by 0.22 s
	var k: = clampf(a / 0.05, 0.0, 1.0) * clampf((float(q["life"]) - a) / 0.15, 0.0, 1.0)
	var r: = float(q["r"]) * k
	if r < 2.0:
		return
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(q["jag"])
	var pts: = PackedVector2Array()
	var n: = 14
	for i in n:
		var rr: = r * (rng.randf_range(0.85, 1.15) if i % 2 == 0 else rng.randf_range(0.38, 0.55))
		pts.append((q["p"] as Vector2) + Vector2.from_angle(float(q["rot"]) + TAU * i / n) * rr)
	draw_colored_polygon(pts, RED)
	var closed: = pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, INK, ow, true)
	draw_circle(q["p"], r * 0.22, RED_DARK)
