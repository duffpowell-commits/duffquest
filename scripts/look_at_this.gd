extends RefCounted
## "Look At This": Madison's ADHD (she shows Duff her phone screen all the time, and cutting in before he finishes is
## hard for her). Lines approved by Duff, Nov 14 2026: never change a line here without his sign-off. Facts are hers:
## her screen is usually reels and texts. The joke is the bit, never her; he gives up the story gladly.
## Talking to her at home from FIRST_DAY on, once (when there's nothing to hand over). No fail state.

const FIRST_DAY: = 3
const HAPPY: = 3.0

const LINES: = [
	"{hero}: \"So at work today, Dolores—\"",
	"{partner}: \"Wait wait wait. Look.\" (phone in my face)",
	"A reel. A guy cannonballs into a kiddie pool. She's already laughing before he lands.",
	"{hero}: \"Anyway, Dolores—\"",
	"{partner}: \"Okay but read this text. Read it. Out loud.\"",
	"I never finish the Dolores story. The kiddie pool guy was better anyway.",
]

static func available(day_count: int, seen: bool) -> bool:
	return not seen and day_count >= FIRST_DAY

## Which screen she's holding up on this line: "reel", "text" or "" (hud.gd draws it over the dialogue).
static func screen(line: String) -> String:
	var l: = line.to_lower()
	if l.contains("wait wait wait. look.") or l.contains("cannonballs into a kiddie pool"):
		return "reel"
	if l.contains("read this text. read it."):
		return "text"
	return ""

## Her lines here use her happy face: she's delighted, it's the best reel she's seen all day.
static func warm(line: String) -> bool:
	return screen(line) != ""
