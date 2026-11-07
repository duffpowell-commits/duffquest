extends RefCounted

const FUSSY_CHANCE: = 0.15
const FUSSY_GAP: = 3
const BOUNCES: = 2
const COUCH_ENERGY: = 70.0
const QUEST_WARN: = [240.0, 360.0, 480.0]
const ERRAND_WARN: = [120.0, 45.0]

const RUNAROUND: = [
	"{partner}: \"Sorry, my brain's mush today. Ask me again in a bit?\"",
	"{partner}: \"I'm so tired I forgot what I was saying. Give me five minutes and a kiss.\"",
	"{partner}: \"Can you put it over there? No, there. ...Sorry. Thank you for being patient with me, hon.\"",
	"{partner}: \"Actually, I wanted the other thing. There is no other thing. I KNOW.\"",
]
const FUSSY_FINE: = "{partner}: \"Thank you, babe. Sorry. It's one of those days. You're the good part of it.\""
const FUSSY_TEXTS: = [
	"idk. nothing. everything. not you, just one of those days",
	"sorry in advance for today. my brain is soup",
	"everything is annoying today. you're fine. the toaster is on thin ice",
]
const FUSSY_SWAP: = "actually can u get %s instead of %s? no wait. yes. sorry"
const FUSSY_BUFF: = "{partner}: \"Not right now, love. ...Okay, ask me one more time. Nicely.\""

const UPSET: = {
	"errand": {"text": "You said you'd get it. %s came and went. Everything okay?", "line": "{partner}: \"I needed you today.\" (I missed her errand.)" },
	"date": {"text": "I had a whole outfit picked out in my head. Rain check? Don't make me wear it alone.", "line": "{partner}: \"I was ready at seven. It's okay. Just... next time.\" (I skipped the date.)", "hit": 8.0 },
	"fryer": {"text": "", "line": "{partner} cracks a window and kisses my cheek anyway. (I come home smelling like the fryer.)" },
	"rent": {"text": "Late notice on the door, babe. I took it down before the neighbors saw. We'll fix it.", "line": "{partner}'s up doing the budget app at midnight. Again. (Rent's late.)" },
	"promise": {"text": "hey. you said you'd bring it this morning. you ok?", "line": "{partner}: \"It's okay. I know you're running on fumes. Tomorrow?\" (I forgot what you promised.)", "hit": 10.0 },
	"bill": {"text": "collections called me at work lol. we gotta open the mail babe. together tonight?", "line": "{partner} sets a collections letter on the counter. 'Let's open the mail together, okay?' (I ignored a bill.)" },
}
const MAKEUP: = "{partner}: \"...Okay. We're okay. Don't do it again.\" (Made up.)"

const MAKEUP_LINES: = [
	"{partner}: \"...Okay. We're okay. Don't do it again, babe.\" (Made up.)",
	"{partner}: \"I'm sorry too. I snapped at you and you didn't deserve all of it.\" (Made up.)",
	"{partner}: \"C'mere. We're a team. Teams fight about dumb stuff.\" (Made up.)",
	"{partner}: \"I missed you. Even while I was mad. ESPECIALLY while I was mad.\" (Made up.)",
]
const COUCH_LINE: = "{partner} points at the couch, then brings me her good pillow. {cat1} sleeps on my face."
const COUCH_WAKE: = "Couch night. My back's a question mark. (Energy capped at 70.) She makes me coffee anyway. We're okay."

const SHORT_REPLIES: = ["tired babe. love you tho", "long day. hug later?", "brain's fried. you're not", "ok. love you", "mhm. come home soon"]

static func new_mood() -> Dictionary:
	return {"kind": "", "day": -1, "cause": "", "bounces": 0, "swapped": false, "last_fussy": -99 }

static func clean_mood(d) -> Dictionary:
	var out: = new_mood()
	if typeof(d) != TYPE_DICTIONARY:
		return out
	out["kind"] = str(d.get("kind", "")) if str(d.get("kind", "")) in ["", "fussy", "upset"] else ""
	out["cause"] = str(d.get("cause", ""))
	for k in ["day", "bounces", "last_fussy"]:
		out[k] = int(d.get(k, out[k]))
	out["swapped"] = bool(d.get("swapped", false))
	return out

static func roll_fussy(day: int, seed_v: int, last_fussy: int) -> bool:
	if day < 2 or day - last_fussy < FUSSY_GAP:
		return false
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(seed_v * 53 + day * 3571)
	return rng.randf() < FUSSY_CHANCE
