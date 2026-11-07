extends "res://scripts/minigames/minigame.gd"

var oil: = 350.0
var setpoint: = 350.0
var baskets: Array = []
var oil_good: = 0.0
var oil_total: = 0.0

func _setup() -> void:
	title = "Fryer Station"
	time_limit = 26.0
	var fries: = {"n": "Fries", "cook": 6.0, "drop": 30.0, "state": "ready", "prog": 0.0, "score": 0.0, "key": KEY_1 }
	var wings: = {"n": "Wings", "cook": 9.0, "drop": 20.0, "state": "ready", "prog": 0.0, "score": 0.0, "key": KEY_2 }
	if ctx.get("fixit", false):
		title = "Re-fire Brayden's Burnt Wings"
		baskets = [wings]
		time_limit = 18.0
	elif rush():
		baskets = [fries if randf() < 0.5 else wings]
		time_limit = 16.0
	else:
		baskets = [fries, wings]
	for i in baskets.size():
		var b: Dictionary = baskets[i]
		add_button("b%d" % i, Rect2(8 + i * 82, 150, 78, 24), "DROP %s" % b["n"], b["key"], Color("#9c5a2c"))
	add_button("down", Rect2(200, 150, 54, 24), "HEAT -", KEY_Z)
	add_button("up", Rect2(258, 150, 54, 24), "HEAT +", KEY_X)

func set_heat(v: float) -> void:
	setpoint = clampf(v, 300.0, 400.0)

func toggle(i: int) -> void:
	var b: Dictionary = baskets[i]
	if b["state"] == "ready":
		if oil >= 390.0:
			hurt(5, "Oil's at %d°F and you dropped a basket. Splatter burn! -5 Energy" % int(oil))
		b["state"] = "in"
		AudioScript.sfx("fryer")
		oil -= float(b["drop"])
		get_button("b%d" % i)["label"] = "PULL %s" % b["n"]
	elif b["state"] == "in":
		_pull(i)

func _pull(i: int) -> void:
	var b: Dictionary = baskets[i]
	var p: float = b["prog"]
	var s: = 0.0
	if p >= 0.92 and p <= 1.1:
		s = 1.0
		flash("%s: golden. Chef's kiss." % b["n"], Color("#c0d890"))
	elif p >= 0.8 and p < 0.92:
		s = 0.7
		flash("%s: a little pale." % b["n"], Color("#e6a640"))
	elif p > 1.1 and p <= 1.25:
		s = 0.7
		flash("%s: dark but servable." % b["n"], Color("#e6a640"))
	elif p < 0.8:
		s = 0.25
		var msg: = "Wings must hit 165°F. Those are raw." if b["n"] == "Wings" else "Limp, raw fries. Sad as a gig worker's pension."
		notes.append(msg)
		flash(msg, Color("#e06a4a"))
	else:
		s = 0.05
		notes.append("%s burnt to a crisp." % b["n"])
		flash("%s: charcoal." % b["n"], Color("#e06a4a"))
	b["score"] = s
	b["state"] = "out"
	get_button("b%d" % i)["enabled"] = false
	get_button("b%d" % i)["label"] = "%s DONE" % b["n"]
	_check_done()

func _check_done() -> void:
	for b in baskets:
		if b["state"] != "out":
			return
	_done()

func _done() -> void:
	var total: = 0.0
	for b in baskets:
		total += float(b["score"])
	var oil_score: = oil_good / oil_total if oil_total > 0.0 else 1.0
	if oil_score < 0.6:
		notes.append("Oil temp was all over the place (keep it 350-375°F).")
	var sc: = (total / baskets.size()) * 0.75 + oil_score * 0.25
	if ctx.get("fixit", false) and sc >= 0.65:
		bonus = 5
		notes.append("Saved Brayden's wings: +$5")
	finish(sc)

func _timeout() -> void:
	for i in baskets.size():
		if baskets[i]["state"] == "in":
			_pull(i)
	_done()

func sim(delta: float) -> void:
	var step: = minf(absf(setpoint - oil), 9.0 * delta)
	oil += signf(setpoint - oil) * step
	var any_in: = false
	for i in baskets.size():
		var b: Dictionary = baskets[i]
		if b["state"] == "in":
			any_in = true
			var factor: = clampf((oil - 250.0) / 100.0, 0.2, 1.6)
			b["prog"] = float(b["prog"]) + delta / float(b["cook"]) * factor
			if float(b["prog"]) > 1.6 and not done:
				_pull(i)
	if any_in:
		oil_total += delta
		if oil >= 335.0 and oil <= 385.0:
			oil_good += delta

func _tick(delta: float) -> void:
	sim(delta)

func _on_button(id: String) -> void:
	match id:
		"down": set_heat(setpoint - 10.0)
		"up": set_heat(setpoint + 10.0)
		_: toggle(int(id.substr(1)))

func debug_solve(good: bool) -> void:
	set_heat(375.0 if good else 400.0)
	oil = setpoint
	for i in baskets.size():
		toggle(i)
	var guard: = 0
	while not done and guard < 2000:
		guard += 1
		sim(0.05)
		for i in baskets.size():
			var b: Dictionary = baskets[i]
			if b["state"] == "in" and ((good and float(b["prog"]) >= 1.0) or (not good and float(b["prog"]) >= 1.4)):
				_pull(i)

func _draw_game() -> void:

	draw_rect(Rect2(20, 30, 180, 100), Color("#888c96"))
	draw_rect(Rect2(28, 38, 164, 70), Color("#c89b3c").darkened(clampf((oil - 340.0) / 120.0, 0, 0.6)))
	if oil > 385.0:
		for i in 5:
			draw_circle(Vector2(40 + i * 35, 34 - fmod(t * 20.0 + i * 7.0, 14.0)), 4, Color(0.8, 0.8, 0.8, 0.4))
		txt(Vector2(28, 28), "SMOKING", 8, Color("#e06a4a"))
	for i in baskets.size():
		var b: Dictionary = baskets[i]
		var bx: = 36 + i * 80
		var p: float = b["prog"]
		var food: = Color("#f5e6a0").lerp(Color("#e0a030"), clampf(p, 0, 1))
		if p > 1.1:
			food = Color("#e0a030").lerp(Color("#2a1a0a"), clampf((p - 1.1) / 0.5, 0, 1))
		var by: = 46.0 if b["state"] == "in" else 20.0
		if b["state"] != "out":
			draw_rect(Rect2(bx, by, 70, 30), Color(0.2, 0.2, 0.2, 0.6))
			for k in 6:
				draw_rect(Rect2(bx + 4 + k * 11, by + 6 + (k % 2) * 6, 8 if b["n"] == "Fries" else 9, 14 if b["n"] == "Fries" else 9), food)
		txt(Vector2(bx, 120), b["n"], 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 70)
		if b["state"] == "in":
			bar(Rect2(bx, 112, 70, 4), p / 1.4, food)
			draw_rect(Rect2(bx + 70 * 0.92 / 1.4, 110, 70 * 0.18 / 1.4, 8), Color(1, 1, 1, 0.25))

	txt(Vector2(212, 30), "OIL", 8, Color(1, 1, 1, 0.7))
	txt(Vector2(212, 48), "%d°F" % int(oil), 16, Color("#c0d890") if oil >= 335.0 and oil <= 385.0 else Color("#e06a4a"))
	txt(Vector2(212, 62), "Set: %d°F" % int(setpoint), 8, Color.WHITE)
	txt(Vector2(212, 78), "Sweet spot", 8, Color(1, 1, 1, 0.6))
	txt(Vector2(212, 88), "350-375°F", 8, Color(1, 1, 1, 0.6))
	mtxt(Vector2(212, 104), "Cold baskets drop the oil. Too hot = smoke + splatter.", 104, 8, Color(1, 1, 1, 0.5), 3)
