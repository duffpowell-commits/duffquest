extends RefCounted


const FARE: = 2
const PASS_PRICE: = 40
const PASS_DAYS: = 30
const EVERY: = 15.0
const RIDE_MIN: = 6.0
const RUN_HOURS: = [330.0, 1410.0]
const CAR_PRICE: = 2500
const CAR_MIN: = 4.0
const STOPS: = {
	"home": {"name": "Home (Elm St)", "pos": Vector2(132, 150)}, 
	"kwik": {"name": "Kwik-N-Go / {plasma}", "pos": Vector2(560, 150)}, 
	"fork": {"name": "The Twisted Fork", "pos": Vector2(600, 202)}, 
	"market": {"name": "{grocery} / {pharmacy}", "pos": Vector2(250, 202)}, 
}
const ORDER: = ["home", "kwik", "fork", "market"]
const RIDE_LINES: = [
	"Guy next to me has a lizard in a tiny hat. Lizard's doing better than me.", 
	"Driver waves me on: \"Just get in, chef.\" Only kind thing the city's done all week.", 
	"Dude on speakerphone is pitching 'Uber for dogs' to an investor. The investor says yes.", 
	"Grandma offers me a butterscotch. I take it. I'm not an animal.", 
	"Ad above my seat: 'Feeling broke? Try our app! 39% APR.' Cool. Cool cool cool.", 
]

static func wait_minutes(clock: float) -> float:
	var c: = fmod(clock, 1440.0)
	var w: = EVERY - fmod(c, EVERY)
	return maxf(2.0, w)

static func running(clock: float) -> bool:
	var c: = fmod(clock, 1440.0)
	return c >= RUN_HOURS[0] and c < RUN_HOURS[1]

static func pass_active(pass_until: int, day: int) -> bool:
	return pass_until >= day

static func fare(people: int, pass_until: int, day: int, has_car: bool) -> int:
	if has_car or pass_active(pass_until, day):
		return 0
	return FARE * people
