extends RefCounted

const PHARM_OPEN: = 480.0
const PHARM_CLOSE: = 1260.0
const GROC_OPEN: = 360.0
const GROC_CLOSE: = 1380.0
const DUE: = {"pharmacy": 1140.0, "grocery": 1200.0 }
const HAPPY: = {"pharmacy": 15.0, "grocery": 12.0 }
const MISS_HAPPY: = 10.0
const EARLY_BY: = 720.0
const EARLY_BONUS: = 5.0
const COPAY: = 10
const COPAY_INSURED: = 5
const GAS_MONEY: = 5
const CAKE: = ["cherries", "chocolate", "cream", "flour", "eggs"]

const PRICES: = {
	"honey buns": 2, "flour": 1, "chocolate": 2, "cherries": 3, "eggs": 2, "cream": 2,
	"formula": 10, "diapers": 8, "ensure": 3, "treats": 2,
}
const LABELS: = {
	"honey buns": "Honey buns", "flour": "Flour", "chocolate": "Baking chocolate", "cherries": "Cherries",
	"eggs": "Eggs", "cream": "Heavy cream", "formula": "Formula", "diapers": "Diapers", "ensure": "Ensure",
	"treats": "Cat treats", "meds": "{partner}'s prescription",
}

const SUBS: = {
	"honey buns": [["{grocery} Honey Swirls (store brand)", -1, "Store brand? ...Damn, they're fine. Don't tell anyone."], ["Artisanal honey buns, hand-glazed by a guy named Theo", 4, "These cost HOW much? Theo, you bastard. ...Okay they're incredible."]],
	"cherries": [["Canned cherries", -1, "Canned cherries. Bold. The cake will survive."], ["Organic heirloom cherries", 3, "Heirloom cherries. Look at me, fancy as hell."]],
	"eggs": [["Store-brand eggs (one is suspiciously small)", -1, "One of these eggs is tiny. It's the baby egg."], ["Free-range eggs from very happy chickens", 2, "Happy chickens. Happier than the {fork_nick} staff."]],
	"cream": [["Half and half (close enough?)", -1, "Half and half is not heavy cream, babe. We'll make it work."], ["Fancy grass-fed cream", 2, "Grass-fed. The cows have better health insurance than me."]],
	"formula": [["Store-brand formula (same stuff, says the pediatrician)", -3, "Same ingredients, $3 cheaper. Brand-name tax: 86'd."], ["Premium organic formula", 4, "She'll be the fanciest baby on the block."]],
	"diapers": [["Store-brand diapers", -2, "Store brand diapers. Fingers crossed for no blowouts."], ["The ones with the cartoon she likes", 2, "THE CARTOON ONES. She's going to giggle."]],
	"ensure": [["Store-brand 'Insure' shakes", -1, "'Insure'? Fine. It's vanilla either way."], ["Ensure Max Protein", 2, "Max Protein. Gym Bro would sell this as a course."]],
	"chocolate": [["Chocolate chips", 0, "Chips work. I'm not picky. Okay I'm a little picky."], ["Fancy dark chocolate bar", 3, "Ooh, the good dark chocolate."]],
	"flour": [["Pancake mix (it's basically flour?)", 0, "Pancake mix?! ...the cake will be fluffy, at least."], ["Organic stone-ground flour", 2, "Stone-ground. Like a pioneer with a credit card."]],
	"treats": [["Store-brand cat treats", -1, "{cat3} will judge. {cat1} and {cat2} won't notice."], ["Gourmet salmon cat treats", 2, "{cat3} may finally love you."]],
}
const LISTS: = {
	"cake": ["cherries", "chocolate", "cream", "flour", "eggs"],
	"baby": ["formula", "diapers", "ensure"],
	"pantry": ["eggs", "ensure", "treats"],
}
const LIST_INTROS: = {
	"cake": "Cake night! Can you hit {grocery}? I'll bake you a Black Forest cake.",
	"baby": "{baby} supply run pls. {grocery} is cheaper than Kwik-N-Go.",
	"pantry": "We're out of basically everything. {grocery} run?",
}
const PHARM_ASKS: = [
	"Can you grab my prescription at {pharmacy}? It's under my name. Copay's $10, I'll pay you back.",
	"My refill's ready at {pharmacy}! (It is never actually ready.) Grab it?",
	"{pharmacy} texted that my prescription is ready. Third text. Can you go before they text again?",
	"Prescription pickup at {pharmacy}, pretty please? Bring an Ensure if they have the vanilla.",
]

static func kind_for_day(day: int) -> String:

	return "pharmacy" if day % 3 == 2 else "grocery"

static func make(day: int, seed_v: int) -> Dictionary:
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(seed_v * 7919 + day * 104729)
	var kind: = kind_for_day(day)
	var e: = new_errand()
	e["day"] = day
	e["kind"] = kind
	e["due"] = float(DUE[kind])
	e["status"] = "active"
	if kind == "pharmacy":
		e["items"] = {"meds": 1 }
		e["ask"] = PHARM_ASKS[rng.randi() % PHARM_ASKS.size()]
		return e
	var names: = LISTS.keys()
	var ln: String = "cake" if day == 1 else str(names[rng.randi() % names.size()])
	var items: = {}
	for it in LISTS[ln]:
		items[it] = 1
	if rng.randf() < 0.6 or ln != "cake":
		items["honey buns"] = 1
	e["list"] = ln
	e["items"] = items
	e["budget"] = budget_for(items)
	e["oos"] = str(items.keys()[rng.randi() % items.size()]) if rng.randf() < 0.75 else ""
	e["ask"] = LIST_INTROS[ln]
	return e

static func new_errand() -> Dictionary:
	return {"day": -1, "kind": "", "status": "", "due": 0.0, "items": {}, "budget": 0, "list": "", "oos": "", "ask": "",
		"got": {}, "spent": 0, "copay": 0, "subs": 0, "sub_notes": [], "skipped": [], "card_strain": false }

static func list_cost(items: Dictionary) -> int:
	var s: = 0
	for k in items:
		s += int(PRICES.get(k, 0)) * int(items[k])
	return s

static func budget_for(items: Dictionary) -> int:
	return int(ceil((list_cost(items) + 3) / 5.0)) * 5

static func list_text(e: Dictionary) -> String:
	var parts: Array = []
	for k in e.get("items", {}):
		parts.append(str(LABELS.get(k, k)).to_lower() if k != "meds" else str(LABELS[k]))
	return ", ".join(parts)

static func due_text(e: Dictionary) -> String:
	var c: = int(float(e.get("due", 0.0)))
	var h: = (c / 60) % 12
	return "%d %s" % [12 if h == 0 else h, "PM" if c >= 720 else "AM"]

static func is_open(kind: String, clock: float) -> bool:
	var c: = fmod(clock, 1440.0)
	if kind == "pharmacy":
		return c >= PHARM_OPEN and c < PHARM_CLOSE
	return c >= GROC_OPEN and c < GROC_CLOSE

static func pending(e: Dictionary) -> bool:
	return str(e.get("status", "")) in ["active", "fetched"]

static func reward(e: Dictionary, delivered_frac: float, clock: float) -> float:

	var h: = float(HAPPY.get(str(e.get("kind", "grocery")), 12.0)) * clampf(delivered_frac, 0.0, 1.0)
	h -= float(int(e.get("subs", 0)))
	if bool(e.get("card_strain", false)):
		h -= 3.0
	h = maxf(3.0, h)
	if fmod(clock, 1440.0) < EARLY_BY and delivered_frac >= 1.0:
		h += EARLY_BONUS
	return h

static func clean(e) -> Dictionary:
	var out: = new_errand()
	if typeof(e) != TYPE_DICTIONARY:
		return out
	for k in ["kind", "status", "list", "oos", "ask"]:
		out[k] = str(e.get(k, out[k]))
	if not out["kind"] in ["", "pharmacy", "grocery"] or not out["status"] in ["", "active", "fetched", "done", "missed", "late"]:
		return new_errand()
	for k in ["day", "budget", "spent", "copay", "subs"]:
		out[k] = int(e.get(k, out[k]))
	out["due"] = float(e.get("due", 0.0))
	out["card_strain"] = bool(e.get("card_strain", false))
	for k in ["items", "got"]:
		var src = e.get(k, {})
		var dd: = {}
		if typeof(src) == TYPE_DICTIONARY:
			for i in src:
				dd[str(i)] = int(src[i])
		out[k] = dd
	for k in ["skipped", "sub_notes"]:
		var arr = e.get(k, [])
		var aa: Array = []
		if typeof(arr) == TYPE_ARRAY:
			for x in arr:
				aa.append(str(x))
		out[k] = aa
	return out

static func new_stats() -> Dictionary:
	return {"done": 0, "missed": 0, "streak": 0, "best": 0, "pharmacy": 0, "grocery": 0, "coupons": 0, "phone_trees": 0, "bagging": 0 }

static func clean_stats(s) -> Dictionary:
	var out: = new_stats()
	if typeof(s) != TYPE_DICTIONARY:
		return out
	for k in out:
		out[k] = int(s.get(k, 0))
	return out
