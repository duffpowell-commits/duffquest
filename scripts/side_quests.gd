extends RefCounted
const Cast: = preload("res://scripts/cast.gd")
## Side quests: one save-safe state dict for every hand-made side quest.
## Pure data + static helpers (same pattern as bounties.gd / errands.gd), so tests can drive it headless.
##
## State (saved under "side_quests"):
##   {"<id>": {"stage": int, "status": "" | "active" | "done", "choice": String, "clues": [String], "new": bool}}
## stage 0 = not started. While active, stage N (1-based) points at STAGES[N - 1].
## Unknown ids, bad types and out-of-range stages are dropped or clamped by clean(), so an old or hand-edited
## save can never crash the loader, and a quest removed from LIST simply disappears.
##
## "ready": false keeps a quest hidden from players (no journal row, no marker) until its content is wired up.
## Tests and the dev warp can still drive it.

const LIST: = [
	{
		"id": "porch", "kind": "mystery", "title": "Who Took The Porch?", "giver": "madison", "ready": true, "from_day": 2,
		"pitch": "Third package this month. {partner} wants a name.",
		"stages": [
			{"text": "Ask around. Somebody on this block saw something.", "at": "brittany"},
			{"text": "Check the porch. Thieves leave crumbs. Sometimes literal crumbs.", "at": "porch"},
			{"text": "Orange dust, a gas-station receipt, one address. Knock on the neighbor's door.", "at": "neighbor"},
		],
	},
	{
		"id": "grease", "kind": "bounty", "title": "The Grease Trap", "giver": "bounty_board", "ready": true, "from_day": 4,
		"pitch": "Something lives behind the Fork's fryer. It has opinions.",
		"stages": [
			{"text": "Read the 86 List entry. Nobody signed it.", "at": "bounty_board"},
			{"text": "Come back to the 86 List after close (10 PM to 5 AM). It only comes out at night.", "at": "bounty_board"},
		],
	},
	{
		"id": "gig", "kind": "character", "title": "{coworker}'s Side Gig", "giver": "brittany", "ready": true, "from_day": 5,
		"pitch": "{coworker} needs a favor. It's probably legal.",
		"stages": [
			{"text": "Hear {coworker} out. All of it. Even the PowerPoint.", "at": "brittany"},
			{"text": "Pick a side. She's watching which one.", "at": "brittany"},
			{"text": "Sleep on it. Tomorrow, tell {coworker} how it went.", "at": "brittany"},
		],
		"choices": ["cover", "rat"],
	},
	{
		"id": "alley", "kind": "explore", "title": "Lost & Found, Omaha", "giver": "mail", "ready": true, "from_day": 3,
		"pitch": "A flyer in the mail. Someone lost something in this neighborhood. Three somethings.",
		"stages": [
			{"text": "Find Gail's three things: a ring 'where the street drinks', a cat collar 'in the bin by the gas station', a left shoe 'look up, by the bus stop'.", "at": ""},
			{"text": "Bring it all to the green paper box outside the Seen Cafe.", "at": "lostbox"},
		],
	},
]

const STATUSES: = ["", "active", "done"]

static func entry(id: String) -> Dictionary:
	for e in LIST:
		if str(e["id"]) == id:
			return e
	return {}

static func ids() -> Array:
	return LIST.map(func (e): return str(e["id"]))

static func stage_count(id: String) -> int:
	return (entry(id).get("stages", []) as Array).size()

static func blank() -> Dictionary:
	return {"stage": 0, "status": "", "choice": "", "clues": [], "new": false}

static func new_state() -> Dictionary:
	return {}

## Never trust a save: keep known quests only, coerce every field, clamp the stage.
static func clean(d) -> Dictionary:
	var out: = new_state()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	for k in d:
		var id: = str(k)
		if entry(id).is_empty() or typeof(d[k]) != TYPE_DICTIONARY:
			continue
		var src: Dictionary = d[k]
		var q: = blank()
		var stv: = str(src.get("status", ""))
		q["status"] = stv if stv in STATUSES else ""
		q["stage"] = clampi(int(src.get("stage", 0)), 0, stage_count(id))
		if q["status"] == "" :
			q["stage"] = 0
		elif q["status"] == "active" and int(q["stage"]) == 0:
			q["stage"] = 1
		var ch: = str(src.get("choice", ""))
		q["choice"] = ch if ch in (entry(id).get("choices", []) as Array) else ""
		var cl = src.get("clues", [])
		if typeof(cl) == TYPE_ARRAY:
			for c in cl:
				if not (q["clues"] as Array).has(str(c)):
					(q["clues"] as Array).append(str(c))
		q["new"] = bool(src.get("new", false))
		out[id] = q
	return out

static func get_q(st: Dictionary, id: String) -> Dictionary:
	return st.get(id, blank())

static func status(st: Dictionary, id: String) -> String:
	return str(get_q(st, id)["status"])

static func stage(st: Dictionary, id: String) -> int:
	return int(get_q(st, id)["stage"])

static func is_active(st: Dictionary, id: String) -> bool:
	return status(st, id) == "active"

static func is_done(st: Dictionary, id: String) -> bool:
	return status(st, id) == "done"

static func _put(st: Dictionary, id: String) -> Dictionary:
	if not st.has(id):
		st[id] = blank()
	return st[id]

## Returns false (and changes nothing) for unknown or already-started quests.
static func start(st: Dictionary, id: String) -> bool:
	if entry(id).is_empty() or status(st, id) != "":
		return false
	var q: = _put(st, id)
	q["status"] = "active"
	q["stage"] = 1
	q["new"] = true
	return true

## Next stage; past the last stage the quest is done.
static func advance(st: Dictionary, id: String) -> void:
	if not is_active(st, id):
		return
	var q: = _put(st, id)
	if int(q["stage"]) >= stage_count(id):
		finish(st, id)
		return
	q["stage"] = int(q["stage"]) + 1
	q["new"] = true

static func finish(st: Dictionary, id: String, choice: String = "") -> void:
	if entry(id).is_empty():
		return
	var q: = _put(st, id)
	q["status"] = "done"
	q["stage"] = stage_count(id)
	if choice != "":
		set_choice(st, id, choice)
	q["new"] = true

static func set_choice(st: Dictionary, id: String, choice: String) -> bool:
	if not choice in (entry(id).get("choices", []) as Array):
		return false
	_put(st, id)["choice"] = choice
	return true

static func choice(st: Dictionary, id: String) -> String:
	return str(get_q(st, id)["choice"])

static func add_clue(st: Dictionary, id: String, clue: String) -> bool:
	if not is_active(st, id):
		return false
	var cl: Array = _put(st, id)["clues"]
	if cl.has(clue):
		return false
	cl.append(clue)
	st[id]["new"] = true
	return true

static func has_clue(st: Dictionary, id: String, clue: String) -> bool:
	return (get_q(st, id)["clues"] as Array).has(clue)

## Dev only: jump a quest to any stage (0 = reset, past the end = done).
static func warp(st: Dictionary, id: String, to_stage: int) -> void:
	if entry(id).is_empty():
		return
	var q: = _put(st, id)
	if to_stage <= 0:
		st[id] = blank()
	elif to_stage > stage_count(id):
		finish(st, id)
	else:
		q["status"] = "active"
		q["stage"] = to_stage
		q["new"] = true

static func visible(id: String, show_hidden: bool) -> bool:
	return show_hidden or bool(entry(id).get("ready", false))

## Can a player be offered this quest today? Ready, not started, and past its first day.
static func offerable(st: Dictionary, id: String, day: int, show_hidden: bool = false) -> bool:
	return visible(id, show_hidden) and status(st, id) == "" and day >= int(entry(id).get("from_day", 1))

## "!" = a giver with a quest to hand out, "?" = the active stage wants you to talk here, "" = nothing.
static func marker_for(st: Dictionary, npc: String, show_hidden: bool = false, day: int = 1 << 30) -> String:
	var bang: = false
	for e in LIST:
		var id: = str(e["id"])
		if not visible(id, show_hidden):
			continue
		match status(st, id):
			"active":
				var s: Array = e["stages"]
				var at: = str(s[stage(st, id) - 1].get("at", ""))
				if at == npc:
					return "?"
			"":
				if str(e.get("giver", "")) == npc and day >= int(e.get("from_day", 1)):
					bang = true
	return "!" if bang else ""

## Rows for the phone Notes app: active first, then done. Not-started quests are not listed.
static func journal(st: Dictionary, show_hidden: bool = false) -> Array:
	var act: Array = []
	var fin: Array = []
	for e in LIST:
		var id: = str(e["id"])
		if not visible(id, show_hidden):
			continue
		var stv: = status(st, id)
		if stv == "":
			continue
		var q: = get_q(st, id)
		var row: = {"id": id, "title": Cast.T(str(e["title"])), "status": stv, "new": bool(q["new"]),
			"step": "", "clues": (q["clues"] as Array).duplicate(), "progress": "%d/%d" % [int(q["stage"]), stage_count(id)]}
		if stv == "active":
			row["step"] = Cast.T(str((e["stages"] as Array)[int(q["stage"]) - 1]["text"]))
			act.append(row)
		else:
			row["step"] = "Done." + ((" (%s)" % str(q["choice"])) if str(q["choice"]) != "" else "")
			fin.append(row)
	return act + fin

static func unread(st: Dictionary, show_hidden: bool = false) -> int:
	var n: = 0
	for id in st:
		if visible(str(id), show_hidden) and bool(st[id].get("new", false)):
			n += 1
	return n

static func mark_read(st: Dictionary) -> void:
	for id in st:
		st[id]["new"] = false
