extends RefCounted
## "Too Loud": Madison's autism (noise overload, masking, the crash after). Lines approved by Duff, Nov 14 2026:
## never change a line here without his sign-off. Facts are hers: noise is the trigger, headphones help, she masks
## in public and crashes after, and what she wants to talk about at length is herself (her day, all of it, in order).
## First Saturday trip to Hy-Whee from FIRST_DAY on, once. No fail state: if the meter fills, they leave the cart.

const FIRST_DAY: = 6
const SATURDAY: = 5   # main.DAY_NAMES index
const HAPPY: = 5.0

const STORE: = [
	"Saturday at {grocery}. Carts, the intercom, a crying kid, and a man testing every squeaky toy in aisle 5.",
	"{partner}: \"I'm good. Totally good.\"",
	"Her smile is doing all the work.",
]
const CALM: = [
	"Headphones on. Her shoulders drop an inch.",
	"{partner}: \"Okay. Creamer, then we leave. Don't make eye contact with the squeaky-toy guy.\"",
]
## Meter filled before the headphones turned up. Duff OK'd the shape ("just leave the cart and go"); words pending.
const BAIL: = [
	"No headphones in time. I park the cart in the cereal aisle. We walk out. Nobody needs creamer that bad.",
]
const HOME: = [
	"The mask comes off in the car. The rest comes off face down on the couch.",
	"{partner}: \"Ask me about my day. All of it. In order.\"",
	"{hero}: \"How was your day?\"",
	"She tells me. Forty minutes. I don't touch my phone once.",
]

static func available(day_count: int, day_i: int, seen: bool) -> bool:
	return not seen and day_count >= FIRST_DAY and day_i % 7 == SATURDAY

## Her lines here use her happy face: the masking smile in the store, relief after, warm on the couch.
const WARM_PHRASES: = ["totally good", "creamer, then we leave", "ask me about my day"]

static func warm(line: String) -> bool:
	var l: = line.to_lower()
	for p in WARM_PHRASES:
		if l.contains(p):
			return true
	return false
