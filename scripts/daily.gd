extends RefCounted
## Daily life layer: fridge calendar days (data/calendar.json) + one random daily event
## (data/daily_events.json). Pure functions; main.gd keeps the state dict and applies effects.
## Spec: docs/daily_life.md. One headline per day: a calendar headline beats a random event,
## and either one blocks the old bill roll (main.curveball_new_day) that morning.

const MONTH_LEN: = 30
const MONTHS: = ["NOVEMBER", "DECEMBER", "JANUARY", "FEBRUARY", "MARCH", "APRIL"]
const WEEKEND: = [5, 6]          # main.DAY_NAMES index: 5 Saturday, 6 Sunday

static var _cal: Dictionary = {}
static var _ev: Dictionary = {}

static func calendar() -> Dictionary:
	if _cal.is_empty():
		_cal = _read("res://data/calendar.json")
	return _cal

static func events_data() -> Dictionary:
	if _ev.is_empty():
		_ev = _read("res://data/daily_events.json")
	return _ev

static func _read(path: String) -> Dictionary:
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

static func new_state() -> Dictionary:
	return {"day": -1, "id": "", "recent": [], "falcor": ""}

static func clean(d) -> Dictionary:
	var out: = new_state()
	if typeof(d) == TYPE_DICTIONARY:
		out["day"] = int(d.get("day", -1))
		out["id"] = str(d.get("id", ""))
		out["falcor"] = str(d.get("falcor", ""))
		var r = d.get("recent", [])
		if typeof(r) == TYPE_ARRAY:
			for x in r:
				out["recent"].append(str(x))
	return out

## 1-based day of the month for a 1-based day_count.
static func day_of_month(day_count: int) -> int:
	return (maxi(day_count, 1) - 1) % MONTH_LEN + 1

static func month_name(day_count: int) -> String:
	return MONTHS[((maxi(day_count, 1) - 1) / MONTH_LEN) % MONTHS.size()]

static func is_weekend(weekday: int) -> bool:
	return weekday % 7 in WEEKEND

## Calendar entry for this day (only the first month is handwritten), or {}.
static func entry(day_count: int) -> Dictionary:
	if day_count < 1 or day_count > MONTH_LEN:
		return {}
	return calendar().get("days", {}).get(str(day_count), {})

static func event(id: String) -> Dictionary:
	for e in events_data().get("events", []):
		if str(e["id"]) == id:
			return e
	return {}

## Pick today's random event id ("" = quiet day). Deterministic per (seed, day).
static func roll(day_count: int, weekday: int, recent: Array, beaten: int, seed_v: int) -> String:
	if bool(entry(day_count).get("headline", false)):
		return ""
	var data: = events_data()
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash([seed_v, day_count, "daily"])
	if rng.randf() >= float(data.get("chance", 0.75)):
		return ""
	var pool: = "weekend" if is_weekend(weekday) else "weekday"
	var cands: Array = []
	var total: = 0.0
	for e in data.get("events", []):
		if str(e.get("pool", "weekday")) != pool or recent.has(str(e["id"])):
			continue
		if beaten < int(e.get("needs_beaten", 0)):
			continue
		cands.append(e)
		total += float(e.get("weight", 1))
	if cands.is_empty():
		return ""
	var pick: = rng.randf() * total
	for e in cands:
		pick -= float(e.get("weight", 1))
		if pick <= 0.0:
			return str(e["id"])
	return str(cands[-1]["id"])

## Push today's id onto the no-repeat list.
static func remember(recent: Array, id: String) -> Array:
	var out: = recent.duplicate()
	if id != "":
		out.append(id)
	var keep: = int(events_data().get("no_repeat", 5))
	while out.size() > keep:
		out.pop_front()
	return out

## Effect lookups (1.0 / [] / false when no event today).
static func shift_pay(id: String) -> float:
	return float(event(id).get("shift_pay", 1.0)) if id != "" else 1.0

static func walk(id: String) -> float:
	return float(event(id).get("walk", 1.0)) if id != "" else 1.0

static func spawn(id: String) -> float:
	return maxf(0.25, float(event(id).get("spawn", 1.0))) if id != "" else 1.0

static func shift_modes(id: String) -> Array:
	return event(id).get("shift_modes", []) if id != "" else []

static func inspector(id: String) -> bool:
	return bool(event(id).get("inspector", false)) if id != "" else false
