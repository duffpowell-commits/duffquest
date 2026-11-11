extends "res://scripts/minigames/minigame.gd"

const Bank: = preload("res://scripts/minigames/quiz_bank.gd")
const Q_TIME: = 15.0

var count: = 5
var picks: Array = []
var idx: = 0
var order: Array = []
var correct: = 0
var phase: = "ask"
var q_t: = 0.0
var fb_t: = 0.0
var chosen: = -1

func _setup() -> void:
	title = "Pre-shift Lineup Quiz"
	time_limit = 0.0
	space_is_pen = false
	var ids: = range(Bank.BANK.size())
	ids.shuffle()
	picks = ids.slice(0, count)
	var rects: = [Rect2(6, 96, 151, 37), Rect2(163, 96, 151, 37), Rect2(6, 138, 151, 37), Rect2(163, 138, 151, 37)]
	var keys: = [KEY_1, KEY_2, KEY_3, KEY_4]
	var badge_cols: = [UiStyle.GOLD, UiStyle.PINK, UiStyle.TEAL, Color("#8a6ad0")]
	for i in 4:
		var b: = add_button("c%d" % i, rects[i], "", keys[i])
		b["badge"] = str(i + 1)
		b["badge_col"] = badge_cols[i]
	_load_q()

func current() -> Dictionary:
	return Bank.BANK[picks[mini(idx, count - 1)]]

func _load_q() -> void:
	order = [0, 1, 2, 3]
	order.shuffle()
	var q: = current()
	for i in 4:
		var b: = get_button("c%d" % i)
		b["label"] = str(q["a"][order[i]])   # card_button word-wraps with the real font
		b["col"] = Color("#57504e")
	phase = "ask"
	q_t = 0.0
	chosen = -1

func _wrap(s: String, w: float) -> String:
	if font == null or font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= w:
		return s
	var words: = s.split(" ")
	var a: = ""
	var i: = 0
	while i < words.size() and font.get_string_size(a + " " + words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= w:
		a = (a + " " + words[i]).strip_edges()
		i += 1
	return a + "\n" + " ".join(words.slice(i))

func answer(i: int) -> void:

	if phase != "ask":
		return
	chosen = i
	var right: = i >= 0 and int(order[i]) == 0
	if right:
		correct += 1
	for k in 4:
		var b: = get_button("c%d" % k)
		if int(order[k]) == 0:
			b["col"] = Color("#4e7a3a")
		elif k == i:
			b["col"] = Color("#a43a2c")
	var why: String = current()["why"]
	if right:
		flash("Correct! " + why, Color("#c0d890"), 2.4)
	else:
		flash(("Too slow! " if i < 0 else "Nope. ") + why, Color("#e06a4a"), 2.4)
		notes.append("Missed: " + str(current()["q"]))
	phase = "feedback"
	fb_t = 2.4

func _advance() -> void:
	idx += 1
	flash_t = 0.0
	if idx >= count:
		finish(float(correct) / count)
	else:
		_load_q()

func _tick(delta: float) -> void:
	if phase == "ask":
		q_t += delta
		if q_t >= Q_TIME:
			answer(-1)
	else:
		fb_t -= delta
		if fb_t <= 0.0:
			_advance()

func _on_button(id: String) -> void:
	if phase == "feedback":
		_advance()
		return
	answer(int(id.substr(1)))

func debug_solve(good: bool) -> void:
	while not done:
		var slot: = order.find(0)
		answer(slot if good else (slot + 1) % 4)
		_advance()

func _draw_game() -> void:
	txt(Vector2(4, 24), "Question %d/%d" % [mini(idx + 1, count), count], 8, Color(1, 1, 1, 0.6))
	if phase == "ask":
		bar(Rect2(200, 18, 114, 5), 1.0 - q_t / Q_TIME, Color("#e6a640"))
	# the question on the lineup clipboard: cream paper, ink border, gold clip
	var qr: = Rect2(6, 30, 308, 58)
	UiStyle.prop(self, qr, UiStyle.CREAM, 1.0 / 1.5, 0.12)
	prop(Rect2(144, 26, 32, 7), UiStyle.GOLD, 0.0)
	mtxt(Vector2(12, 46), str(current()["q"]), 296, 9, UiStyle.INK, 4)
	txt(Vector2(260, 9), "%d correct" % correct, 8, Color("#c0d890"))
