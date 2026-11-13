extends RefCounted
## Madison's mornings (EDS + migraines). Approved line by line by Duff, Nov 13 2026: never change a line here without
## his sign-off. She has Ehlers-Danlos syndrome; her hip is the big joint and she gets a lot of migraines.
##  - "slow": she's in bed, hurting. Duff feeds {baby}, makes two coffees, brings hers to the nightstand for her meds.
##  - "migraine": same chores, room dark and quiet.
##  - "good": she's up making the coffee herself (she does that on good days so she doesn't feel useless). Let her.
## Skipping a slow/migraine morning is never punished: she gets up on her own and texts. Nothing here makes her the joke.
## Pure data + roll; main.gd owns the state dict (`morning`) and the scene.

const SLOW_CHANCE: = 0.26      # about 2 hard mornings a week with MIGRAINE_CHANCE (never two mornings in a row)
const MIGRAINE_CHANCE: = 0.14
const GOOD_CHANCE: = 0.15      # about 1 a week
const FIRST_DAY: = 2           # day 1 is the tutorial morning
const SELF_UP_AT: = 600.0      # 10 AM: not brought yet -> she gets herself up and texts
const UP_DELAY: = 90.0         # minutes after the coffee before she's out of bed
const SLOW_HAPPY: = 8.0
const GOOD_HAPPY: = 5.0

const SLOW_CARDS: = [
	"Slow morning. {partner}'s awake. She just isn't moving yet. Her hip slipped in her sleep again.",
	"Slow morning. Her hip's been arguing with her since four AM. The hip is winning.",
]
const SLOW_BED: = [
	"{partner}: \"Morning. Don't look at me. I'm a bag of loose parts today.\"",
	"{partner}: \"Can you do {baby} first? She's louder than my knees.\"",
]
const SLOW_LATER: = [
	"{partner}: \"Meds kicked in. I'm about sixty percent person. The rest is coffee.\"",
	"{partner}: \"Okay. I'm upright. Nobody clap.\"",
]
const SLOW_BRING: = [
	"I set her coffee next to the pill case. She sits up in stages. Wince, breathe, wince. I don't help unless she asks. She asks.",
	"{partner}: \"Thank you, babe. You're my favorite person before nine AM.\"",
]
const SLOW_SKIP_TEXT: = "made it to the kitchen on my own. took my meds. love u"

const MIGRAINE_CARD: = "Migraine morning. Blinds down, {partner} under the blanket. The light is too loud."
const MIGRAINE_BED: = "{partner}: \"Head's splitting. Keep it dark? And quiet. And {baby} somewhere... quieter.\""
const MIGRAINE_FEED: = "I feed {baby} in the kitchen with the door shut. She takes it as a personal challenge."
const MIGRAINE_BRING: = [
	"Coffee and meds on the nightstand. I don't turn the light on. I find her hand in the dark.",
	"{partner}: \"Thank you. Don't talk. I mean that lovingly.\"",
]
const MIGRAINE_LATER: = "{partner}: \"Room stopped tilting. Kiss me before it changes its mind.\""
const MIGRAINE_SKIP_TEXT: = "head's bad. took my meds. it's dark in here and i'm ok. love u"

const FEED: = "Bottle first. {baby} drinks like she's got somewhere to be."
const COFFEE: = "Two mugs. Hers with cream and sugar. Mine with honey."

const GOOD_CARD: = "Good morning. An actually good one. {partner}'s already in the kitchen."
const GOOD_ASK: = "{partner}: \"Sit. I'm making it today. Don't you dare get up.\""
const GOOD_SIT: = [
	"{partner}: \"Two mugs, no spills, both knees showing up for work. Look at me.\"",
	"I sit. I let her. It tastes better when she makes it. I know why.",
]
const GOOD_TAKEOVER: = [
	"{partner}: \"Babe. I've got it. Let me have the coffee.\"",
	"I sit down. She's right.",
]

## Phrases that put her portrait on the tired/hurting face instead of the smile.
const PAIN_PHRASES: = ["loose parts", "louder than my knees", "head's splitting", "don't talk"]

static func new_state() -> Dictionary:
	return {"day": -1, "kind": "", "fed": false, "coffee": false, "done": "", "up_at": -1.0, "later_said": false, "pick": 0}

## Old saves have no "morning" key: they load as "no morning today".
static func clean(d) -> Dictionary:
	var out: = new_state()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	out["day"] = int(d.get("day", -1))
	out["kind"] = str(d.get("kind", "")) if str(d.get("kind", "")) in ["", "slow", "migraine", "good"] else ""
	out["fed"] = bool(d.get("fed", false))
	out["coffee"] = bool(d.get("coffee", false))
	out["done"] = str(d.get("done", "")) if str(d.get("done", "")) in ["", "brought", "self", "sit", "takeover"] else ""
	out["up_at"] = float(d.get("up_at", -1.0))
	out["later_said"] = bool(d.get("later_said", false))
	out["pick"] = clampi(int(d.get("pick", 0)), 0, 1)
	return out

## Today's morning kind ("" = an ordinary morning). Deterministic per (seed, day). `eligible` is main.gd's call
## (not fussy, not upset, no couch night, no special calendar morning). Never two in a row.
static func roll(day_count: int, seed_v: int, eligible: bool, last_day: int) -> String:
	if not eligible or day_count < FIRST_DAY or last_day == day_count - 1:
		return ""
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash([seed_v, day_count, "morning"])
	var r: = rng.randf()
	if r < SLOW_CHANCE:
		return "slow"
	if r < SLOW_CHANCE + MIGRAINE_CHANCE:
		return "migraine"
	if r < SLOW_CHANCE + MIGRAINE_CHANCE + GOOD_CHANCE:
		return "good"
	return ""

static func hard(kind: String) -> bool:
	return kind in ["slow", "migraine"]

static func wake_lines(kind: String, pick: int) -> Array:
	match kind:
		"slow":
			return [SLOW_CARDS[pick % 2], SLOW_BED[pick % 2], "(Bottle for {baby}, coffee from the kitchen, then bring it to her.)"]
		"migraine":
			return [MIGRAINE_CARD, MIGRAINE_BED, "(Bottle for {baby}, coffee from the kitchen, then bring it to her.)"]
		"good":
			return [GOOD_CARD]
	return []

static func bed_line(kind: String, pick: int) -> String:
	return MIGRAINE_BED if kind == "migraine" else SLOW_BED[pick % 2]

static func feed_line(kind: String) -> String:
	return MIGRAINE_FEED if kind == "migraine" else FEED

static func bring_lines(kind: String) -> Array:
	return MIGRAINE_BRING.duplicate() if kind == "migraine" else SLOW_BRING.duplicate()

static func later_line(kind: String, pick: int) -> String:
	return MIGRAINE_LATER if kind == "migraine" else SLOW_LATER[pick % 2]

static func skip_text(kind: String) -> String:
	return MIGRAINE_SKIP_TEXT if kind == "migraine" else SLOW_SKIP_TEXT

static func pained(line: String) -> bool:
	var l: = line.to_lower()
	for p in PAIN_PHRASES:
		if l.contains(p):
			return true
	return false
