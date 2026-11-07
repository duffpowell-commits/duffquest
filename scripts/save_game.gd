extends RefCounted

const VERSION: = 7
const MAX_THREAD: = 60
const Market: = preload("res://scripts/market.gd")
const Errands: = preload("res://scripts/errands.gd")
const DEFAULT_PATH: = "user://duffquest_save.json"

static func exists(path: String = DEFAULT_PATH) -> bool:
	return FileAccess.file_exists(path)

static func write(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	data["version"] = VERSION
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var f: = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Save failed: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

static func read(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt: = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return migrate(parsed)

static func erase(path: String = DEFAULT_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func migrate(d: Dictionary) -> Dictionary:

	var v: = int(d.get("version", 0))
	if v < 1:

		var inv: Dictionary = d.get("inventory", {})
		if int(d.get("quest", 0)) == 2:
			inv["honey buns"] = int(inv.get("honey buns", 0)) + 1
			d["quest"] = 1
			d["quest_kind"] = "honey buns"
		d["inventory"] = inv
		if not d.has("clock"):
			d["clock"] = 420.0
		if not d.has("location"):
			d["location"] = "outside"
		v = 1
	if v < 2:

		d["gear"] = clean_gear(d.get("gear", {}))
		d["wordle"] = clean_wordle(d.get("wordle", {}))
		if not d.has("wordle_seed"):
			d["wordle_seed"] = int(d.get("saved_at", 12345)) % 100000
		v = 2
	if v < 3:

		var sd: = int(d.get("wordle_seed", 12345))
		d["market"] = Market.new_state(sd + 7)
		d["brokerage"] = Market.new_account(true)
		d["college"] = Market.new_account(true)
		d["threads"] = {"sister": [{"from": "sister", "text": "I moved. Not telling you where. Wordle's on your phone now, nerd. Same streak, same roasts.", "day": int(d.get("day_count", 1)) }], "gala": [] }
		d["unread"] = {"sister": true, "gala": false }
		d["last_text_day"] = -1
		d["gala_unlocked"] = false
		d["gala_beaten"] = false
		d["gala_runs"] = 0
		d["fund_happy_day"] = -1
		d["fund_happy_today"] = 0.0
		var ach: Array = d.get("achievements", [])
		for i in ach.size():
			if str(ach[i]) == "Freya Approves":
				ach[i] = "{cat3} Approves"
		d["achievements"] = ach
		v = 3
	if v < 4:

		d["story"] = clean_story(d.get("story", {}))
		v = 4
	if v < 5:

		d["errand"] = Errands.new_errand()
		d["errand_stats"] = Errands.new_stats()
		var th = d.get("threads", {})
		if typeof(th) == TYPE_DICTIONARY and not (th as Dictionary).has("madison"):
			th["madison"] = []
			d["threads"] = th
		v = 5
	if v < 6:

		d["date_invite"] = {"kind": "", "day": -1, "expires": -1 }
		d["date_stats"] = {"count": 0, "last_day": -99, "akarui": 0, "symphony": 0, "best": 0.0, "sitter_day": -1, "sitter": "" }
		d["glow_day"] = -1
		d["plasma"] = {"visits": 0, "days": [], "weeks": [], "drained_day": -1 }
		d["mood"] = {"kind": "", "day": -1, "cause": "", "bounces": 0, "swapped": false, "last_fussy": -99 }
		d["bills"] = []
		d["owed"] = []
		d["plans"] = []
		d["rent_bump"] = 0
		v = 6
	if v < 7:

		var swap: = {"tire": "sneakers", "battery": "work_shoes", "parking": "fare_fine" }
		for key in ["bills", "owed", "plans"]:
			var arr = d.get(key, [])
			if typeof(arr) == TYPE_ARRAY:
				for x in arr:
					if typeof(x) == TYPE_DICTIONARY and swap.has(str(x.get("id", ""))):
						x["id"] = swap[str(x["id"])]
						if key == "owed":
							x["text"] = "So that old bill comes due: $%d."
		d["has_car"] = false
		d["bus_pass_until"] = -1
		d["bus_rides"] = 0
		v = 7
	d["version"] = v
	return d

static func clean_gear(g) -> Dictionary:

	var out: = {"owned": {"spatula": 0, "apron": 0 }, "weapon": "spatula", "armor": "apron", "scraps": 0 }
	if typeof(g) != TYPE_DICTIONARY or (g as Dictionary).is_empty():
		return out
	var owned: = {}
	var src = g.get("owned", {})
	if typeof(src) == TYPE_DICTIONARY:
		for k in src:
			owned[str(k)] = int(src[k])
	if not owned.has("spatula"):
		owned["spatula"] = 0
	if not owned.has("apron"):
		owned["apron"] = 0
	out["owned"] = owned
	out["weapon"] = str(g.get("weapon", "spatula")) if owned.has(str(g.get("weapon", ""))) else "spatula"
	out["armor"] = str(g.get("armor", "apron")) if owned.has(str(g.get("armor", ""))) else "apron"
	out["scraps"] = int(g.get("scraps", 0))
	return out

static func clean_wordle(w) -> Dictionary:
	var out: = {"day": -1, "practice_day": -1, "streak": 0, "best_streak": 0, "wins": 0, "played": 0, "last_win_day": -99, "dist": [0, 0, 0, 0, 0, 0, 0], "history": [] }
	if typeof(w) != TYPE_DICTIONARY:
		return out
	for k in ["day", "practice_day", "streak", "best_streak", "wins", "played", "last_win_day"]:
		if w.has(k):
			out[k] = int(w[k])
	if w.has("dist") and typeof(w["dist"]) == TYPE_ARRAY and (w["dist"] as Array).size() == 7:
		var dd: Array = []
		for x in w["dist"]:
			dd.append(int(x))
		out["dist"] = dd
	if w.has("history") and typeof(w["history"]) == TYPE_ARRAY:
		var hh: Array = []
		for x in w["history"]:
			hh.append(str(x))
		out["history"] = hh
	return out

static func clean_threads(t) -> Dictionary:
	var out: = {"sister": [], "gala": [], "madison": [] }
	if typeof(t) != TYPE_DICTIONARY:
		return out
	for th in t:
		var arr: Array = []
		if typeof(t[th]) != TYPE_ARRAY:
			continue
		for msg in t[th]:
			if typeof(msg) != TYPE_DICTIONARY:
				continue
			var mm: = {"from": str(msg.get("from", "sys")), "text": str(msg.get("text", "")), "day": int(msg.get("day", 0)) }
			var g = msg.get("grid", [])
			if typeof(g) == TYPE_ARRAY and not g.is_empty():
				var rows: Array = []
				for row in g:
					if typeof(row) == TYPE_ARRAY:
						rows.append(row.map(func (x): return int(x)))
				mm["grid"] = rows
			arr.append(mm)
		while arr.size() > MAX_THREAD:
			arr.pop_front()
		out[str(th)] = arr
	return out

static func clean_story(st) -> Dictionary:
	var out: = {"beaten": [], "announced": [], "ending_seen": false, "attempts": 0 }
	if typeof(st) != TYPE_DICTIONARY:
		return out
	for k in ["beaten", "announced"]:
		var arr = st.get(k, [])
		if typeof(arr) == TYPE_ARRAY:
			for x in arr:
				if str(x) in ["ghoster", "gymbro", "djvape", "crypto", "willnot"] and not (out[k] as Array).has(str(x)):
					(out[k] as Array).append(str(x))
	out["ending_seen"] = bool(st.get("ending_seen", false))
	out["attempts"] = int(st.get("attempts", 0))
	return out
