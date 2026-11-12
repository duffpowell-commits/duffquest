extends "res://scripts/minigames/minigame.gd"

const WL: = preload("res://scripts/wordle_logic.gd")
const ROWS: = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
const C_EMPTY: = Color("#2a2836")
const C_GRAY: = Color("#3a3a40")
const C_YELLOW: = Color("#c9a83a")
const C_GREEN: = Color("#5aa050")
const C_KEY: = Color("#5a5868")
const QUIPS: = [
	"{sister}: Clock's not ticking. Unlike your metabolism.",
	"{sister}: Bold opener. Wrong, but bold.",
	"{sister}: You're cooking. Like, badly, but cooking.",
	"{sister}: Halfway. {baby} could do this. She eats crayons.",
	"{sister}: Two left. I'm already typing the group chat.",
	"{sister}: Last one. No pressure. (So much pressure.)",
]

var answer: = "SAUTE"
var practice: = false
var streak: = 0
var guesses: Array = []
var results: Array = []
var cur: = ""
var letter_state: = {}
var ended: = false
var end_t: = 0.0
var solved_in: = 0
var shake_t: = 0.0

func _setup() -> void:
	title = "JEN'S WORDLE - %s" % ("PRACTICE" if practice else "DAILY")
	time_limit = 0.0
	space_is_pen = false
	answer = answer.to_upper()
	var y: = 111.0
	for r in ROWS.size():
		var row: String = ROWS[r]
		var x: = 5.0 + (r * 15.0 if r < 2 else 0.0)
		if r == 2:
			add_button("ENTER", Rect2(5, y, 45, 21), "ENTER", KEY_ENTER, Color("#2e5aa8"))
			x = 52.0
		for i in row.length():
			var ch: = row[i]
			add_button(ch, Rect2(x + i * 31.0, y, 30, 21), ch, OS.find_keycode_from_string(ch), C_KEY)
		if r == 2:
			add_button("DEL", Rect2(270, y, 45, 21), "DEL", KEY_BACKSPACE, Color("#7a4a4a"))
		y += 23.0
	add_button("giveup", Rect2(262, 94, 54, 13), "give up", KEY_ESCAPE, Color("#4a3a3a"))

func type_letter(ch: String) -> void:
	if ended or cur.length() >= 5:
		return
	cur += ch.to_upper()

func backspace() -> void:
	if not ended and cur.length() > 0:
		cur = cur.substr(0, cur.length() - 1)

func type_word(w: String) -> void:
	cur = ""
	for ch in w.to_upper():
		type_letter(ch)

func submit() -> bool:

	if ended:
		return false
	if cur.length() < 5:
		flash("Five letters, genius.", Color("#e6a640"), 1.2)
		shake_t = 0.3
		return false
	if not WL.is_valid(cur):
		flash("'%s' isn't a word. {sister}: \"Spell much?\"" % cur, Color("#e06a4a"), 1.5)
		shake_t = 0.3
		return false
	var res: = WL.score(cur, answer)
	guesses.append(cur)
	results.append(res)
	for i in 5:
		var ch: = cur[i]
		letter_state[ch] = maxi(int(letter_state.get(ch, -1)), int(res[i]))
	_recolor_keys()
	cur = ""
	if guesses[-1] == answer:
		solved_in = guesses.size()
		_end("Got it in %d! {sister} is visibly annoyed." % solved_in, Color("#c0d890"))
	elif guesses.size() >= 6:
		solved_in = 0
		_end("It was %s. {sister} is already texting Mom." % answer, Color("#e06a4a"))
	return true

func give_up() -> void:
	if ended:
		return
	solved_in = 0
	_end("Gave up. It was %s. {sister}: \"Coward.\"" % answer, Color("#e06a4a"))

func _end(msg: String, col: Color) -> void:
	ended = true
	end_t = 2.4
	flash(msg, col, 2.4)

func _recolor_keys() -> void:
	for ch in letter_state:
		var b: = get_button(ch)
		if b.is_empty():
			continue
		b["col"] = [C_GRAY, C_YELLOW, C_GREEN][int(letter_state[ch])]

func _finish_now() -> void:
	finish((7.0 - solved_in) / 6.0 if solved_in > 0 else 0.0)

func _on_button(id: String) -> void:
	if ended:
		_finish_now()
		return
	match id:
		"ENTER": submit()
		"DEL": backspace()
		"giveup": give_up()
		_: type_letter(id)

func _pointer_down(_p: Vector2) -> void:
	if ended:
		_finish_now()

func _tick(delta: float) -> void:
	show_cursor = false
	shake_t = maxf(0.0, shake_t - delta)
	if ended:
		end_t -= delta
		if end_t <= 0.0:
			_finish_now()

func debug_solve(good: bool) -> void:
	if good:
		type_word(answer)
		submit()
	else:
		var tries: = 0
		for w in WL.common():
			if ended or tries > 50:
				break
			if w != answer:
				type_word(w)
				submit()
				tries += 1
	_finish_now()

## Painted letter tile (kf_letter_tile): plain wood when unscored, tinted grey / yellow / green once scored.
## st = -1 unscored, else 0 gray, 1 yellow, 2 green. False if the art is missing (caller draws the flat prop).
func _tile(r: Rect2, st: int, ch: String, size: int) -> bool:
	var tx: = Art.tex("kf_letter_tile")
	if tx == null:
		return false
	var mod: Color = [Color.WHITE, Color(0.5, 0.5, 0.56), C_YELLOW.lightened(0.35), C_GREEN.lightened(0.3)][st + 1]
	draw_texture_rect(tx, r.grow(1.0), false, mod)
	if ch != "":
		var ink: = UiStyle.INK if st < 0 or st == 1 else Color.WHITE
		txt(Vector2(r.position.x, r.position.y + r.size.y * 0.5 + size * 0.36), ch, size, ink, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	return true

## Letter keys wear the same tile, in the colour Wordle has learned for that letter.
func _draw_top() -> void:
	for b in buttons:
		var id: = str(b["id"])
		if id.length() != 1:
			continue
		var r: Rect2 = b["rect"]
		if b.get("down", false):
			r.position += Vector2(1, 1)
		_tile(r, int(letter_state[id]) if letter_state.has(id) else -1, id, 9)

func _draw_game() -> void:
	var x0: = 8.0 + (sin(shake_t * 60.0) * 3.0 if shake_t > 0.0 else 0.0)
	for r in 6:
		for c in 5:
			var rect: = Rect2(x0 + c * 15.0, 15.0 + r * 15.0, 13, 13)
			var col: = C_EMPTY
			var ch: = ""
			if r < guesses.size():
				ch = str(guesses[r])[c]
				col = [C_GRAY, C_YELLOW, C_GREEN][int(results[r][c])]
			elif r == guesses.size() and c < cur.length():
				ch = cur[c]
			var st: = int(results[r][c]) if r < guesses.size() else -1
			if not _tile(rect, st, ch, 9):
				prop(rect, col)
				if ch != "":
					txt(Vector2(rect.position.x, rect.position.y + 10), ch, 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 13)
			if r == guesses.size() and not ended:
				draw_rect(rect, Color(1, 1, 1, 0.35), false, 1.0)

	Art.image(self, "av_jen", Vector2(90, 16))
	var quip: String = QUIPS[mini(guesses.size(), 5)]
	mtxt(Vector2(118, 22), quip, 196, 8, Color("#e6e6f0"), 3)
	txt(Vector2(100, 62), ("Practice round: small rewards, no streak." if practice else "Daily. Streak: %d. 1-2 guesses = new gear." % streak), 7, Color("#f2c66a"))
	txt(Vector2(100, 74), "Guess %d of 6" % mini(guesses.size() + 1, 6), 7, Color(1, 1, 1, 0.7))
	txt(Vector2(100, 86), "Type, tap, or click. Enter = guess.", 6, Color(1, 1, 1, 0.5))
