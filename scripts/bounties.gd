extends RefCounted

const LIST: = [
	{"id": "sendback", "lvl": 2, "cash": 40, "scrap": 2, "crime": "This guy sends back 11 steaks in one night. Eats all 11." },
	{"id": "coupon", "lvl": 4, "cash": 55, "scrap": 2, "crime": "Tries to pay with a Blockbuster coupon. Twice." },
	{"id": "allergy", "lvl": 5, "cash": 65, "scrap": 3, "crime": "Says he's 'deathly allergic' to onions. Orders the onion rings." },
	{"id": "camper", "lvl": 6, "cash": 75, "scrap": 3, "crime": "One coffee. Four hours. Unplugs the walk-in to charge his laptop." },
	{"id": "bdaydad", "lvl": 8, "cash": 100, "scrap": 4, "crime": "Party of 19. No reservation. Separate checks. Bites a busser (okay, his kid does)." },
	{"id": "dasher", "lvl": 10, "cash": 180, "scrap": 6, "crime": "Steak, lobster, 3 shakes, pie to go. Pays with footsteps.", "needs_all": true },
]
const REMATCH_CUT: = 0.25
const ACH_ALL: = "86'd Them All"

static func entry(id: String) -> Dictionary:
	for e in LIST:
		if str(e["id"]) == id:
			return e
	return {}

static func clean(d) -> Dictionary:
	var out: = {"beaten": [], "day": -1 }
	if typeof(d) != TYPE_DICTIONARY:
		return out
	var b = d.get("beaten", [])
	if typeof(b) == TYPE_ARRAY:
		for id in b:
			if not entry(str(id)).is_empty() and not (out["beaten"] as Array).has(str(id)):
				(out["beaten"] as Array).append(str(id))
	out["day"] = int(d.get("day", -1))
	return out

static func locked_reason(e: Dictionary, level: int, beaten: Array) -> String:
	if level < int(e["lvl"]):
		return "Seniority Lv %d" % int(e["lvl"])
	if bool(e.get("needs_all", false)):
		for o in LIST:
			if str(o["id"]) != str(e["id"]) and not beaten.has(str(o["id"])):
				return "86 everyone else first"
	return ""

static func payout(e: Dictionary, first: bool) -> Dictionary:
	var k: = 1.0 if first else REMATCH_CUT
	return {"cash": int(round(int(e["cash"]) * k)), "scrap": int(e["scrap"]) if first else 1 }
