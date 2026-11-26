extends RefCounted
## Every foe in the 3D slice, as data (Phase 2 refactor step 2, Nov 26 2026). foe_brain.gd runs any of
## them; a new foe is a new entry here (plus its model in models/), not a new script. Names and lines
## follow the main game's scripts/boss.gd ("mike", "sendback"). Times are seconds, distances metres.
##
## Keys (all optional unless marked):
##   name*, model*, height*, hp*, speed*, radius*, stop* (walks in to this gap), reach* (jabs from here), spawn*
##   rage_speed       walk speed once raged (default: speed)
##   step_around      side-step when the planter (or any wall) is between him and Duff
##   opening          his answer to Duff's opening line (the first foe of a fight)
##   jab*             {tele, clip, rest, rage_rest, shove (m/s push on Duff), cool_after (ranged move ready this soon)}
##   ranged           {range (only from this far), every, rage_every (x every), first (cool on arrival)}
##   throw            {state, tele, line, prop (make_<prop>), count, rage_count, fan, rage_fan, speed,
##                     radius, up (release height), yaw (face the flight), wobble [rate, angle]}
##   charge           {tele, line, speed, time, dizzy}
##   rage             {line, time}: at half HP he taunts (armoured) and comes back faster
##   guard            {after (clean hits), time, rage_time (x time), rest, shove, line, prop}: a shield
##                    only specials break; a smash costs him smash_bonus more and the special dizzies him
##   special_dizzy    seconds dizzy after any special lands
##   smash_line       what he says when the shield breaks
##   dizzy_free       while dizzy: no rage, no shield (he rages when he stands back up instead)
##   armoured         states that block every punch and kick (specials still go through)
##   teach            [button, line]: the button his fight teaches (ringed until used) and the one line about it
##   waits            the tutorial foe: won't swing until Duff has thrown a punch (or a kick or the special)
##   reads_mashing    false = never blocks a mashed flurry (the tutorial foe). Default true
##   counter_from_taunt  a blocked hit during his taunt still gets an instant counter jab
##   arrive           {line, line_time, message, music}: walking in (not for the foe who starts the fight)
##   ko               {line, line_time, message}: going down

const FOES := {
	"pirate": {
		"name": "Porch Pirate", "model": "pirate", "height": 1.4, "hp": 5, "speed": 2.1, "radius": .42,
		"stop": 1.0, "reach": 1.15, "spawn": Vector3(3, 0, -1),
		"opening": "Just browsing your porch, boss.",
		"jab": {"tele": .55, "clip": "jab", "rest": 1.25},  # the tutorial foe: slow, readable (Nov 26 tune)
		"reads_mashing": false,  # never blocks a mashed flurry, so a first-timer's A always lands
		"teach": ["a", "Tap A to punch."], "waits": true,
		"ko": {"message": "Walk over to grab the parcel."},
	},
	"mike": {
		"name": "Marketplace Mike", "model": "mike", "height": 1.65, "hp": 8, "speed": 1.9, "rage_speed": 2.5,
		"radius": .5, "stop": 1.05, "reach": 1.2, "spawn": Vector3(5.6, 0, 3.4), "step_around": true,
		"jab": {"tele": .5, "clip": "jab", "rest": 1.35, "rage_rest": 1.0, "shove": 6.0, "cool_after": .6},
		"ranged": {"range": 2.2, "every": 3.0, "rage_every": .85, "first": 2.2},  # Nov 26 first-timer (5/10): fairer Mike
		"throw": {"state": "post", "tele": .8, "line": "Listed: one Duff. Used. Fair condition.", "prop": "obo_sign",
			"count": 1, "speed": 6.5, "radius": .55, "up": 1.05, "yaw": false, "wobble": [14.0, .35]},
		"charge": {"tele": .9, "line": "Cash only! No lowballers!", "speed": 7.2, "time": .85, "dizzy": 1.2},
		"rage": {"line": "Price drop! Everything must go! Starting with YOU!", "time": 1.2},
		"armoured": ["taunt"],
		"counter_from_taunt": true,
		"teach": ["k", "He blocks a flurry. K kicks through his guard."],
		"arrive": {"line": "That pirate was my best guy. Porch box goes for twelve bucks. Or best offer.", "line_time": 4.0,
			"message": "Marketplace Mike wants the parcel back.", "music": "mus_boss"},
		"ko": {"line": "Okay. Mark me as sold.", "message": "Parcel recovered. Somebody else is coming up the walk..."},
	},
	"sendback": {
		"name": "Sir Sends-It-Back", "model": "sendback", "height": 1.75, "hp": 10, "speed": 1.7, "rage_speed": 2.2,
		"radius": .5, "stop": 1.05, "reach": 1.2, "spawn": Vector3(-5.6, 0, 3.4), "step_around": true,
		"jab": {"tele": .48, "clip": "hook", "rest": 1.25, "rage_rest": .95},
		"ranged": {"range": 2.2, "every": 3.0, "rage_every": .85, "first": 2.2},
		"throw": {"state": "cards_tele", "tele": .75, "line": "This is TOO medium. One star.", "prop": "review_card",
			"count": 3, "rage_count": 5, "fan": .36, "rage_fan": .8, "speed": 6.0, "radius": .45, "up": 1.1, "yaw": true,
			"wobble": [16.0, .4]},
		"charge": {"tele": .8, "line": "I'm coming BACK there.", "speed": 6.8, "time": .85, "dizzy": 1.1},
		"rage": {"line": "I want a refund. On this FIGHT.", "time": 1.2},
		"guard": {"after": 2, "time": 2.6, "rage_time": 1.4, "rest": 3.0, "shove": 6.0, "line": "Sent BACK.",
			"prop": "cloche", "smash_bonus": 1},
		"special_dizzy": 1.8,
		"teach": ["r", "Only R breaks his cloche. Land hits to fill the R ring."],
		"smash_line": "My CLOCHE!",
		"dizzy_free": true,
		"armoured": ["plate", "taunt"],
		"arrive": {"line": "Excuse me. My delivery was left on the WRONG porch. It's cold. I'm sending it back. Through you.",
			"line_time": 4.2, "message": "Only a special breaks his cloche."},
		"ko": {"line": "...This beating is cooked perfectly. Five stars. Still not tipping.", "line_time": 3.0},
	},
}
