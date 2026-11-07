extends RefCounted


const KINDS: = {
	"speed": {"label": "SPD", "name": "Back walk", "color": "#5ad0ff", "desc": "+20% move speed"}, 
	"strength": {"label": "STR", "name": "Her cooking", "color": "#ff8a5a", "desc": "+25% damage"}, 
	"defense": {"label": "DEF", "name": "Pore-fect skin", "color": "#8aff8a", "desc": "-25% damage taken"}, 
	"charisma": {"label": "CHA", "name": "{cologne}", "color": "#ffd0f0", "desc": "20% off, bigger tips, +25% happiness gains"}, 
}
const ORDER: = ["speed", "strength", "defense", "charisma"]
const SPEED_MULT: = 1.2
const STR_MULT: = 1.25
const DEF_MULT: = 0.75
const CHA_HAPPY: = 1.25
const CHA_PRICE: = 0.8
const CHA_GROCERY: = 0.9
const CHA_TIP: = 0.5
const CHARISMA_MINS: = 360.0
const STRENGTH_MINS: = 300.0
const MIN_HAPPY: = 40.0
const COLOGNE_PRICE: = 12
const COLOGNE_SPRAYS: = 3

static func clean(b) -> Dictionary:
	var out: = {}
	if typeof(b) != TYPE_DICTIONARY:
		return out
	for k in b:
		if str(k) in KINDS and typeof(b[k]) == TYPE_DICTIONARY:
			out[str(k)] = {"day": int(b[k].get("day", -1)), "ends": float(b[k].get("ends", 0.0))}
	return out

static func clean_days(d) -> Dictionary:
	var out: = {}
	if typeof(d) != TYPE_DICTIONARY:
		return out
	for k in d:
		if str(k) in KINDS:
			out[str(k)] = int(d[k])
	return out

static func duration(base_mins: float, score: float) -> float:

	return base_mins * (0.5 + 0.5 * clampf(score, 0.0, 1.0))
