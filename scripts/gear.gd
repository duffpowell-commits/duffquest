extends RefCounted

const MAX_LEVEL: = 5
const WEAPONS: = [
	{"id": "spatula", "name": "Spatula", "tier": 1, "atk": 1.0, "special": "flip", "desc": "Flip: extra knockback" },
	{"id": "skillet", "name": "Cast Iron Skillet", "tier": 2, "atk": 2.0, "special": "stun", "desc": "BONK: stuns enemies" },
	{"id": "knife", "name": "Chef's Knife", "tier": 3, "atk": 2.5, "special": "quick", "desc": "Quick: faster swings" },
	{"id": "tenderizer", "name": "Meat Tenderizer", "tier": 4, "atk": 3.0, "special": "pierce", "desc": "Tenderize: ignores HOA armor" },
	{"id": "flail", "name": "Fryer Basket Flail", "tier": 5, "atk": 3.0, "special": "sweep", "desc": "Flail: hits everything around you" },
	{"id": "cleaver", "name": "Dead Man's Cleaver", "tier": 6, "atk": 5.0, "special": "execute", "desc": "25% crit x2, +2 Energy per hit" },
	{"id": "golden_spatula", "name": "Golden Spatula of Generational Wealth", "short": "Golden Spatula", "tier": 7, "atk": 8.0, "special": "golden", "desc": "Hits all around, 25% crit, +$1 per hit", "gala": true },
]
const ARMOR: = [
	{"id": "apron", "name": "Apron", "tier": 1, "def": 1.0, "special": "", "desc": "Stain-resistant. Allegedly. Like my landlord." },
	{"id": "clogs", "name": "Kitchen Clogs", "tier": 2, "def": 1.5, "special": "fast", "desc": "Non-slip: +15% speed, quicker roll" },
	{"id": "sleeves", "name": "Burn Sleeves", "tier": 3, "def": 2.5, "special": "heatproof", "desc": "Half damage from thrown stuff" },
	{"id": "coat", "name": "Chef's Coat", "tier": 4, "def": 3.5, "special": "pro", "desc": "Citations and scams cost half" },
	{"id": "dad", "name": "Dad Armor (goalie pads)", "tier": 5, "def": 6.0, "special": "goalie", "desc": "No knockback, longer i-frames, -10% speed" },
	{"id": "trust_fund", "name": "Trust Fund Plate Armor", "short": "Trust Fund Plate", "tier": 6, "def": 8.0, "special": "trust", "desc": "No knockback, long i-frames, +10% speed", "gala": true },
]

static func new_state() -> Dictionary:
	return {"owned": {"spatula": 0, "apron": 0 }, "weapon": "spatula", "armor": "apron", "scraps": 0 }

static func find(id: String) -> Dictionary:
	for w in WEAPONS:
		if w["id"] == id:
			return w
	for a in ARMOR:
		if a["id"] == id:
			return a
	return {}

static func slot_of(id: String) -> String:
	for w in WEAPONS:
		if w["id"] == id:
			return "weapon"
	return "armor" if not find(id).is_empty() else ""

static func level(g: Dictionary, id: String) -> int:
	return int((g["owned"] as Dictionary).get(id, -1))

static func owns(g: Dictionary, id: String) -> bool:
	return level(g, id) >= 0

static func weapon(g: Dictionary) -> Dictionary:
	return find(str(g["weapon"]))

static func armor(g: Dictionary) -> Dictionary:
	return find(str(g["armor"]))

static func attack(g: Dictionary) -> float:
	return float(weapon(g)["atk"]) + 0.5 * level(g, str(g["weapon"]))

static func defense(g: Dictionary) -> float:
	return float(armor(g)["def"]) + 0.5 * level(g, str(g["armor"]))

static func reduction(g: Dictionary) -> float:
	return minf(0.75, defense(g) * 0.08)

static func w_special(g: Dictionary) -> String:
	return str(weapon(g)["special"])

static func a_special(g: Dictionary) -> String:
	return str(armor(g)["special"])

static func upgrade_cost(id: String, lvl: int) -> int:
	return 3 + 2 * int(find(id).get("tier", 1)) + 3 * lvl

static func can_upgrade(g: Dictionary, id: String) -> bool:
	var l: = level(g, id)
	return l >= 0 and l < MAX_LEVEL and int(g["scraps"]) >= upgrade_cost(id, l)

static func upgrade(g: Dictionary, id: String) -> bool:
	if not can_upgrade(g, id):
		return false
	var l: = level(g, id)
	g["scraps"] = int(g["scraps"]) - upgrade_cost(id, l)
	g["owned"][id] = l + 1
	return true

static func equip(g: Dictionary, id: String) -> bool:
	if not owns(g, id):
		return false
	g[slot_of(id)] = id
	return true

static func next_unowned(g: Dictionary, allow_endgame: bool = true) -> String:

	var best: = ""
	var best_tier: = 99
	for list in [WEAPONS, ARMOR]:
		for it in list:
			if owns(g, it["id"]):
				continue
			if not allow_endgame and it["id"] == "cleaver":
				continue
			if bool(it.get("gala", false)):
				continue
			if int(it["tier"]) < best_tier:
				best_tier = int(it["tier"])
				best = it["id"]
	return best

static func grant_piece(g: Dictionary, allow_endgame: bool = true) -> String:

	var id: = next_unowned(g, allow_endgame)
	if id == "":
		var bits: Array = []
		for slot in ["weapon", "armor"]:
			var sid: = str(g[slot])
			if level(g, sid) < MAX_LEVEL:
				g["owned"][sid] = level(g, sid) + 1
				bits.append(str(find(sid)["name"]))
		g["scraps"] = int(g["scraps"]) + 10
		return "Free upgrade: %s +1 level, +10 scrap" % (" & ".join(bits) if not bits.is_empty() else "nothing left to upgrade (absolute unit)")
	g["owned"][id] = 0
	var slot: = slot_of(id)
	if int(find(id)["tier"]) > int(find(str(g[slot]))["tier"]):
		g[slot] = id
	return "NEW GEAR: %s (%s)" % [find(id)["name"], find(id)["desc"]]
