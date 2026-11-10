extends Node2D
## Enemy / boss / raccoon speech bubbles ("barks"), drawn in one place (Nov 9) instead of by each
## speaker, so they can be laid out together:
##  - at most MAX_VISIBLE on screen; extra ambient chatter is simply dropped (rate limit), and a new
##    ambient bark waits AMBIENT_GAP after the last one. Priority barks (bosses, attack telegraphs)
##    always show: they bump the oldest ambient bubble.
##  - bubbles never overlap each other or a live damage number: each one tries a few spots above /
##    beside its speaker's head (sticking to the last free one so it doesn't jitter) and a thin tail
##    points back to the speaker when it had to move.
##  - z 55: over the world, UNDER combat_fx (z 60), so damage numbers always sit on top.
## Speakers call m.barks.admit(self) from say(); a false return means "dropped" (line_t is zeroed).

const MAX_VISIBLE: = 2
const HARD_MAX: = 3          # priority barks may go one over the cap, never more
const AMBIENT_GAP: = 0.8     # s between two new ambient barks
const WRAP_W: = 100.0        # px; longer lines wrap (max 3 lines)
const FS: = 6                # font size
const LINE_H: = 7.0
const PAD: = 2.0
const GAP: = 2.0             # min space between bubbles / numbers

var m: Node
var fx: Node                 # combat_fx (damage numbers)
var shown: Array = []        # [{sp, prio, since, off, line, lines, size, fresh}]
var clock: = 0.0
var last_ambient: = -100.0
var _wrap_cache: = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 55

static func is_priority(sp: Node) -> bool:
	if sp.is_in_group("boss"):
		return true
	return sp.has_method("telegraphing") and sp.telegraphing()

func _alive(e: Dictionary) -> bool:
	var sp = e["sp"]
	return is_instance_valid(sp) and sp.is_inside_tree() and float(sp.line_t) > 0.0 and str(sp.line) != ""

## Called by a speaker right after it set line/line_t. Returns false if the bark is dropped.
func admit(sp: Node) -> bool:
	shown = shown.filter(_alive)
	var prio: = is_priority(sp)
	for e in shown:
		if e["sp"] == sp:
			e["prio"] = prio
			e["since"] = clock
			return true
	if not prio:
		if shown.size() >= MAX_VISIBLE or clock - last_ambient < AMBIENT_GAP:
			return false
		last_ambient = clock
	else:
		while shown.size() >= MAX_VISIBLE:
			var drop: = _oldest(true)
			if drop < 0:
				if shown.size() < HARD_MAX:
					break
				drop = _oldest(false)
			shown[drop]["sp"].line_t = 0.0
			shown.remove_at(drop)
	shown.append({"sp": sp, "prio": prio, "since": clock, "off": Vector2.ZERO, "fresh": true})
	return true

func _oldest(ambient_only: bool) -> int:
	var best: = -1
	for i in shown.size():
		if ambient_only and shown[i]["prio"]:
			continue
		if best < 0 or float(shown[i]["since"]) < float(shown[best]["since"]):
			best = i
	return best

## How many bubbles are up right now (tests).
func visible_count() -> int:
	return shown.filter(_alive).size()

func wrap_line(s: String) -> PackedStringArray:
	if _wrap_cache.has(s):
		return _wrap_cache[s]
	var f: = ThemeDB.fallback_font
	var out: = PackedStringArray()
	var cur: = ""
	for w in s.split(" "):
		var nxt: = w if cur == "" else cur + " " + w
		if cur != "" and f.get_string_size(nxt, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x > WRAP_W:
			out.append(cur)
			cur = w
		else:
			cur = nxt
	if cur != "":
		out.append(cur)
	if out.size() > 3:
		out = out.slice(0, 3)
		out[2] = out[2] + "..."
	if _wrap_cache.size() > 200:
		_wrap_cache.clear()
	_wrap_cache[s] = out
	return out

## Bubble bottom-centre for a speaker (where the old per-speaker bubbles sat).
static func anchor(sp: Node2D) -> Vector2:
	var y: = -17.0
	if sp.is_in_group("boss"):
		y = -25.0
	elif sp.get("pet_t") != null:   # raccoon
		y = -15.0
	return sp.global_position + Vector2(0, y)

## Screen rects (world units) of live damage numbers / popup text.
func number_rects() -> Array:
	var out: Array = []
	if fx == null or not is_instance_valid(fx):
		return out
	var f: = ThemeDB.fallback_font
	for it in fx.items:
		if it["type"] != "text":
			continue
		var sz: = float(it["size"]) * 1.3
		var w: = f.get_string_size(str(it["s"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(sz)).x
		var p: Vector2 = it["pos"]
		out.append(Rect2(p.x - w / 2.0 - 1.0, p.y - sz, w + 2.0, sz + 2.0))
	return out

static func _overlap(r: Rect2, obs: Array) -> float:
	var a: = 0.0
	for o in obs:
		var x: Rect2 = (o as Rect2).grow(GAP)
		if r.intersects(x):
			a += r.intersection(x).get_area()
	return a

## World rect the player can actually read: the camera view minus the HUD strips (top panels,
## bottom touch buttons). Bubbles pushed outside it are heavily penalised.
func safe_rect() -> Rect2:
	var vp: = get_viewport()
	if vp == null:
		return Rect2(-1e6, -1e6, 2e6, 2e6)
	var inv: = vp.get_canvas_transform().affine_inverse()
	var vr: = vp.get_visible_rect()
	var r: = Rect2(inv * vr.position, (inv.basis_xform(vr.size)))
	return Rect2(r.position + Vector2(4, r.size.y * 0.22), Vector2(r.size.x - 8, r.size.y * 0.66))

## World rect of the HUD's interact prompt (hud.gd "hint", 320x180 HUD units: y 108..121, centre half
## of the width), empty when no prompt is up. Generous on x since the pill hugs the text.
func hint_rects() -> Array:
	var vp: = get_viewport()
	if vp == null or m == null or str(m.hint) == "" or not m.dialog.is_empty():
		return []
	var inv: = vp.get_canvas_transform().affine_inverse()
	var vr: = vp.get_visible_rect()
	var tl: = inv * (vr.position + vr.size * Vector2(0.2, 107.0 / 180.0))
	var br: = inv * (vr.position + vr.size * Vector2(0.8, 122.0 / 180.0))
	return [Rect2(tl, br - tl)]

func layout(delta: float) -> void:
	shown = shown.filter(_alive)
	shown.sort_custom(func(x, y):
		if x["prio"] != y["prio"]:
			return x["prio"]
		return float(x["since"]) < float(y["since"]))
	var nums: = number_rects()
	var bubbles: Array = hint_rects()   # bubbles dodge the "E / A: ..." prompt pill like another bubble
	var safe: = safe_rect()
	var f: = ThemeDB.fallback_font
	for e in shown:
		var sp: Node2D = e["sp"]
		var s: = str(sp.line)
		if e.get("line", "") != s:
			e["line"] = s
			e["lines"] = wrap_line(s)
			var w: = 0.0
			for ln in e["lines"]:
				w = maxf(w, f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x)
			e["size"] = Vector2(w + PAD * 2.0, (e["lines"] as PackedStringArray).size() * LINE_H + PAD)
		var sz: Vector2 = e["size"]
		var an: = anchor(sp)
		var base: = Rect2(an - Vector2(sz.x / 2.0, sz.y), sz)
		var side: = sz.x / 2.0 + 4.0
		var prev: Vector2 = e["off"]
		var cands: Array = [prev]
		for dy in [0.0, -10.0, -20.0, -30.0]:
			for dx in [0.0, -side, side]:
				cands.append(Vector2(dx, dy))
		var best: = prev
		var best_cost: = INF
		var prev_cost: = INF
		for c in cands:
			var r: = Rect2(base.position + c, sz)
			# bubbles never overlap each other (hard), numbers are soft (they draw on top anyway,
			# outlined), off-screen / under the HUD is hard
			var cost: = _overlap(r, bubbles) * 1000.0 + _overlap(r, nums) * 0.5 + absf(c.y) + absf(c.x) * 0.3
			if not safe.encloses(r):
				cost += 2000.0 + (r.get_area() - (safe.intersection(r).get_area() if safe.intersects(r) else 0.0)) * 10.0
			if c == prev:
				prev_cost = cost
			if cost < best_cost:
				best_cost = cost
				best = c
		if e["fresh"]:
			e["off"] = best
			e["fresh"] = false
		else:
			if best_cost > prev_cost - 40.0 and prev_cost < 1000.0:
				best = prev   # hysteresis: only move when it clearly pays (no hopping as numbers float by)
			e["off"] = prev.lerp(best, clampf(delta * 10.0, 0.0, 1.0))
			if (e["off"] as Vector2).distance_to(best) < 0.3:
				e["off"] = best
		e["rect"] = Rect2(base.position + e["off"], sz)
		bubbles.append(e["rect"])

func _process(delta: float) -> void:
	if not get_tree().paused:
		clock += delta
	layout(delta)
	queue_redraw()

func _draw() -> void:
	var f: = ThemeDB.fallback_font
	for e in shown:
		if not _alive(e) or not e.has("rect"):
			continue
		var sp: Node2D = e["sp"]
		if not sp.is_visible_in_tree():
			continue
		var r: Rect2 = e["rect"]
		var a: = clampf(float(sp.line_t) / 0.15, 0.0, 1.0)
		var an: = anchor(sp)
		var off: Vector2 = e["off"]
		if off.length() > 2.0:
			var tx: = clampf(an.x, r.position.x + 2.0, r.end.x - 2.0)
			draw_line(Vector2(tx, r.end.y), an + Vector2(0, 3), Color(0.1, 0.07, 0.1, 0.7 * a), 2.0)
			draw_line(Vector2(tx, r.end.y), an + Vector2(0, 3), Color(1, 1, 1, 0.9 * a), 1.0)
		draw_rect(r, Color(1, 1, 1, 0.92 * a))
		if sp.has_method("telegraphing") and sp.telegraphing():
			draw_rect(r, Color(0.85, 0.15, 0.15, 0.9 * a), false, 1.0)
		var y: = r.position.y + PAD + 5.0
		for ln in e["lines"]:
			var lw: = f.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x
			draw_string(f, Vector2(r.get_center().x - lw / 2.0, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, Color(0.13, 0.13, 0.13, a))
			y += LINE_H
