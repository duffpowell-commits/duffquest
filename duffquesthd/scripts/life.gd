extends RefCounted


const PLASMA_PROMO: = [50, 60, 70, 80, 100]
const PLASMA_BASE: = 35
const PLASMA_SECOND: = 15
const PLASMA_GAP: = 2
const PLASMA_WEEK_MAX: = 2
const PLASMA_OPEN: = [480.0, 1080.0]
const PLASMA_MINUTES: = 90.0
const PLASMA_MIN_ENERGY: = 30.0
const DRAIN_SPEED: = 0.85
const DRAIN_DMG: = 0.85
const DRAIN_TAKEN: = 1.15
const DRAIN_REGEN: = 0.75
const DRAIN_MAX: = 80.0

static func new_plasma() -> Dictionary:
	return {"visits": 0, "days": [], "weeks": [], "drained_day": -1}

static func clean_plasma(d) -> Dictionary:
	var out: = new_plasma()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	out["visits"] = int(d.get("visits", 0))
	out["drained_day"] = int(d.get("drained_day", -1))
	for k in ["days", "weeks"]:
		var a: Array = []
		if typeof(d.get(k)) == TYPE_ARRAY:
			for x in d[k]:
				a.append(int(x))
		out[k] = a
	return out

static func week_of(day_i: int) -> int:
	return day_i / 7

static func donations_this_week(p: Dictionary, day_i: int) -> int:
	var w: = week_of(day_i)
	var n: = 0
	for x in p["weeks"]:
		if int(x) == w:
			n += 1
	return n

static func plasma_block(p: Dictionary, day: int, day_i: int, clock: float, energy: float) -> String:

	var c: = fmod(clock, 1440.0)
	if c < PLASMA_OPEN[0] or c >= PLASMA_OPEN[1]:
		return "closed"
	var days: Array = p["days"]
	if not days.is_empty() and day - int(days[-1]) < PLASMA_GAP:
		return "gap"
	if donations_this_week(p, day_i) >= PLASMA_WEEK_MAX:
		return "week"
	if energy < PLASMA_MIN_ENERGY:
		return "energy"
	return ""

static func plasma_pay(p: Dictionary, day_i: int) -> int:
	var v: = int(p["visits"])
	var base: int = PLASMA_PROMO[v] if v < PLASMA_PROMO.size() else PLASMA_BASE
	if v >= PLASMA_PROMO.size() and donations_this_week(p, day_i) == 1:
		base += PLASMA_SECOND
	return base


const START_DAY: = 3
const CHANCE: = 0.3
const GOOD_SHARE: = 0.25
const DECIDE_DAYS: = 3
const OVERDRAFT: = 35
const HOUSEHOLD: = 45
const SPIKE_DAYS: = 7
const SPIKE: = 4
const EVENTS: = {
	"sneakers": {"title": "Your red sneakers gave out", "body": "The left red sneaker's sole is flapping like it's giving a TED talk. I walk everywhere. Need shoes. $55.", "cost": 55, "plan": [3, 22], 
		"ignore": {"days": 3, "fee": 85, "text": "Sole flapped off on Leavenworth. Emergency red sneakers at 'urgent' pricing, plus blister stuff: $%d.", "happy": 0.0, "cause": ""}}, 
	"work_shoes": {"title": "Black work shoes worn bald", "body": "My black non-slip Fork shoes are bald. Chef: \"Shoes are a personal investment in OUR brand.\" Not reimbursed. $70.", "cost": 70, "plan": [3, 27], 
		"ignore": {"days": 3, "fee": 110, "text": "Slid across the line in bald black work shoes. Urgent care + new non-slips: $%d. Workers' comp: 'pending.'", "happy": 0.0, "cause": ""}}, 
	"snow_day": {"title": "Snow day: buses are crawling", "body": "The #18 is 40 minutes late. The rideshare app says 'surge: snow vibes.' $38. Or I walk.", "cost": 38, "plan": [], 
		"ignore": {"days": 0, "fee": 0, "text": "Walked to the Fork in the snow. Toes filed a grievance. HR lost it. -25 Energy.", "happy": 0.0, "cause": "", "energy": 25.0}}, 
	"fare_fine": {"title": "Fare inspector ticket", "body": "Transfer expired four minutes before the inspector got on. He had a quota. $30.", "cost": 30, "plan": [], 
		"ignore": {"days": 7, "fee": 60, "text": "Fare ticket doubled: $%d. Punishing poor people is a growth market.", "happy": 0.0, "cause": ""}}, 
	"missed_bus": {"title": "Missed the bus", "body": "The 7:42 pulled away while I tied my shoe. Late to the Fork. Chef docked $15 'for accountability.'", "loss": 15}, 
	"fare_app": {"title": "Fare app glitch", "body": "RideOmaha app charged me six times. Support chatbot: 'I understand your frustration!' It does not. -$12.", "loss": 12}, 
	"tire": {"title": "Flat tire (minivan)", "body": "Minivan tire's flatter than Grill-Boy's jokes. Tire shop has 'premium air' now.", "cost": 90, "plan": [3, 35], 
		"ignore": {"days": 3, "fee": 160, "text": "Drove on the flat. Now it's a tow AND a rim. Hell. $%d.", "happy": 0.0, "cause": ""}}, 
	"battery": {"title": "Dead battery (minivan)", "body": "Click. Click. Click. Minivan has chosen death. The extended warranty scammer was right.", "cost": 120, "plan": [4, 35], 
		"ignore": {"days": 3, "fee": 150, "text": "Stranded at the Fork. Tow + battery: $%d. Tow guy charged a 'vibe fee.'", "happy": 0.0, "cause": ""}}, 
	"pediatrician": {"title": "Pediatrician copay", "body": "{baby}'s checkup: perfect baby, $40 copay.", "cost": 40, "plan": [], 
		"ignore": {"days": 7, "fee": 65, "text": "Copay went to collections. Now it's $%d. {partner} took the call. Collections guy said 'per my last voicemail.'", "happy": 5.0, "cause": "bill"}}, 
	"medical": {"title": "Surprise medical bill", "body": "Urgent care from the knife slip. Insurance 'reviewed' it and decided fingers are elective. $180.", "cost": 180, "plan": [5, 42], 
		"ignore": {"days": 7, "fee": 250, "text": "Medical bill in collections: $%d. They called {partner}. At work. With hold music.", "happy": 10.0, "cause": "bill"}}, 
	"phone": {"title": "Cracked phone screen", "body": "You dropped the {phone}. It landed screen-first, like toast.", "cost": 80, "plan": [], 
		"ignore": {"days": 0, "fee": 0, "text": "", "happy": 0.0, "cause": ""}}, 
	"vet": {"title": "Vet visit for the cats", "body": "Checkups for all three cats: $75. Plus a $20 'behavioral surcharge' because {cat3} bit the vet. Worth it.", "cost": 95, "plan": [3, 36], 
		"ignore": {"days": 2, "fee": 0, "text": "Skipped the vet. The cats know. -5 Happiness, {cat3} trust -1.", "happy": 5.0, "cause": "", "trust": 1}}, 
	"parking": {"title": "Parking ticket (minivan)", "body": "Parked in a loading zone for 'four minutes.' The city's ticket robot disagrees. $30.", "cost": 30, "plan": [], 
		"ignore": {"days": 7, "fee": 60, "text": "Parking ticket doubled: $%d. Robot got a bonus.", "happy": 0.0, "cause": ""}}, 
	"rent_hike": {"title": "Rent increase notice", "body": "Landlord is 'aligning with market synergies.' The market is three landlords in a group chat. Rent +$15/week next Monday.", "cost": 0, "plan": [], "hike": 15}, 
	"catering": {"title": "Side gig: catering", "body": "Chef's 'side hustle' needs a hand at a wedding tonight. $80 cash, 4 hours, -30 Energy. Exposure included.", "gig": 80}, 
	"formula_spike": {"title": "Formula prices spike", "body": "Formula is $4 more everywhere. 'Shortage.' Record profits, though. Weird.", "info": true}, 
	"tax_refund": {"title": "Tax refund!", "body": "The IRS remembered I exist, in a GOOD way. Billionaires get this every day. +$120.", "gain": 120}, 
	"found20": {"title": "Found $20", "body": "A $20 bill in last winter's coat. Past you is a hero.", "gain": 20}, 
}
const BAD: = ["sneakers", "work_shoes", "snow_day", "fare_fine", "missed_bus", "fare_app", "pediatrician", "medical", "phone", "vet", "rent_hike", "formula_spike", "catering"]
const CAR_BAD: = ["tire", "battery", "parking"]
const GOOD: = ["tax_refund", "found20", "catering"]
const COOLDOWN: = 7

static func roll_event(day: int, seed_v: int, last: Dictionary, has_car: bool = false) -> String:
	if day < START_DAY:
		return ""
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(seed_v * 31 + day * 7177)
	if rng.randf() >= CHANCE:
		return ""
	var bad: Array = BAD + (CAR_BAD if has_car else [])
	var pool: Array = (GOOD if rng.randf() < GOOD_SHARE else bad).filter( func(id): return day - int(last.get(id, -99)) >= COOLDOWN)
	if pool.is_empty():
		return ""
	return str(pool[rng.randi() % pool.size()])

static func choices(id: String) -> Array:
	var e: Dictionary = EVENTS[id]
	var out: Array = []
	if e.has("hike"):
		return [["accept", "Accept it. Hate it."], ["negotiate", "Negotiate (CHARISMA helps)"]]
	if e.has("gig"):
		return [["accept", "Take the gig (+$%d, 4 hrs, -30 Energy)" % int(e["gig"])], ["decline", "Pass"]]
	if int(e.get("cost", 0)) > 0:
		out.append(["pay", "Pay now ($%d)" % int(e["cost"])])
	var pl: Array = e.get("plan", [])
	if not pl.is_empty():
		out.append(["plan", "Payment plan: $%d/wk x %d ($%d total)" % [int(pl[1]), int(pl[0]), int(pl[0]) * int(pl[1])]])
	if e.has("ignore"):
		out.append(["ignore", {"phone": "Live with the crack (free)", "snow_day": "Walk it (-25 Energy)"}.get(id, "Ignore it")])
	return out

static func clean_list(a, need: Array = []) -> Array:

	var out: Array = []
	if typeof(a) != TYPE_ARRAY:
		return out
	for x in a:
		if typeof(x) == TYPE_DICTIONARY and EVENTS.has(str(x.get("id", ""))) and need.all( func(k): return (x as Dictionary).has(k)):
			var d: = {}
			for k in x:
				var v = x[k]
				d[str(k)] = int(v) if typeof(v) == TYPE_FLOAT and str(k) != "happy" else v
			out.append(d)
	return out
