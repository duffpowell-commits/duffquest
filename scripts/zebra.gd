extends RefCounted
## "The Zebra": Madison's diagnosis story (EDS). Approved line by line by Duff, Nov 13 2026: never change a line here
## without his sign-off. Facts are hers: hypermobile joint syndrome as a kid, the Ehlers-Danlos realization in 2020.
## She loves zebras (pictures, plushies); the zebra is the EDS symbol ("think horses, not zebras").
## One look at the plush on the shelf over the bed, any day after FIRST_DAY. The zebra stays in the room for good.

const FIRST_DAY: = 4
const HAPPY: = 5.0

const LINES: = [
	"A zebra on the shelf. One stripe's a little crooked. {partner} says that's the point.",
	"{partner}: \"Med school rule: hear hoofbeats, think horses. I'm the zebra.\"",
	"{partner}: \"When I was a kid they called it hypermobile joint syndrome. Bendy kid. Do the party trick.\"",
	"{partner}: \"Took until 2020 for anyone to say Ehlers-Danlos out loud.\"",
	"{partner}: \"There's a test. Thumb to your wrist, pinkies back, palms flat on the floor. Nine points.\"",
	"{hero}: \"What'd you get?\"",
	"{partner}: \"Enough.\"",
	"Years of \"you're just flexible.\" I straighten the crooked stripe. She bends it back.",
]

static func available(day_count: int, seen: bool) -> bool:
	return not seen and day_count >= FIRST_DAY

## Her story lines always use her happy face (never the furious one, whatever the happiness meter says).
const WARM_PHRASES: = ["i'm the zebra", "hypermobile joint syndrome", "ehlers-danlos out loud", "nine points", "\"enough.\""]

static func warm(line: String) -> bool:
	var l: = line.to_lower()
	for p in WARM_PHRASES:
		if l.contains(p):
			return true
	return false
