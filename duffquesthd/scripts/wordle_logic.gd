extends RefCounted


const VALID_PATH: = "res://data/words5.txt"
const THEMED_PATH: = "res://data/answers_themed.txt"
const COMMON_PATH: = "res://data/answers_common.txt"
const GRAY: = 0
const YELLOW: = 1
const GREEN: = 2
const THEMED_CHANCE: = 0.4

static var _valid: Dictionary = {}
static var _themed: PackedStringArray = []
static var _common: PackedStringArray = []

static func _load_list(path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("word list missing: " + path)
		return out
	for line in f.get_as_text().split("\n"):
		var w: = line.strip_edges().to_upper()
		if w.length() == 5:
			out.append(w)
	f.close()
	return out

static func ensure_loaded() -> void :
	if not _valid.is_empty():
		return
	for w in _load_list(VALID_PATH):
		_valid[w] = true
	_themed = _load_list(THEMED_PATH)
	_common = _load_list(COMMON_PATH)
	for w in _themed:
		_valid[w] = true
	for w in _common:
		_valid[w] = true

static func valid_count() -> int:
	ensure_loaded()
	return _valid.size()

static func themed() -> PackedStringArray:
	ensure_loaded()
	return _themed

static func common() -> PackedStringArray:
	ensure_loaded()
	return _common

static func is_valid(w: String) -> bool:
	ensure_loaded()
	return _valid.has(w.to_upper())

static func score(guess: String, answer: String) -> Array:


	var g: = guess.to_upper()
	var a: = answer.to_upper()
	var res: Array = [GRAY, GRAY, GRAY, GRAY, GRAY]
	var left: = {}
	for i in 5:
		if g[i] == a[i]:
			res[i] = GREEN
		else:
			left[a[i]] = int(left.get(a[i], 0)) + 1
	for i in 5:
		if res[i] == GREEN:
			continue
		var c: = g[i]
		if int(left.get(c, 0)) > 0:
			res[i] = YELLOW
			left[c] = int(left[c]) - 1
	return res

static func pick_answer(seed_val: int, avoid: Array = []) -> String:
	ensure_loaded()
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_val
	for _try in 30:
		var pool: = _themed if (rng.randf() < THEMED_CHANCE or _common.is_empty()) else _common
		if pool.is_empty():
			return "SAUTE"
		var w: String = pool[rng.randi() % pool.size()]
		if not avoid.has(w):
			return w
	return _themed[rng.randi() % _themed.size()] if not _themed.is_empty() else "SAUTE"

static func reward(guesses: int, practice: bool, streak: int) -> Dictionary:


	var r: = {"gear": 0, "scraps": 0, "money": 0, "tier": "fail"}
	if guesses <= 0:
		return r
	if practice:
		r["scraps"] = [0, 6, 6, 4, 4, 2, 2][guesses]
		r["tier"] = "practice"
		return r
	match guesses:
		1: r = {"gear": 1, "scraps": 15, "money": 0, "tier": "legendary"}
		2: r = {"gear": 1, "scraps": 8, "money": 0, "tier": "top"}
		3: r = {"gear": 0, "scraps": 14, "money": 0, "tier": "materials"}
		4: r = {"gear": 0, "scraps": 10, "money": 0, "tier": "materials"}
		5: r = {"gear": 0, "scraps": 5, "money": 5, "tier": "small"}
		6: r = {"gear": 0, "scraps": 3, "money": 5, "tier": "small"}
	r["scraps"] = int(r["scraps"]) + 2 * mini(streak - 1, 5)
	if streak > 0 and streak % 5 == 0:
		r["gear"] = int(r["gear"]) + 1
	return r
