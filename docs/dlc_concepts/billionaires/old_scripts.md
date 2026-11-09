# Billionaire parody gala bosses (retired Nov 9, 2026)

Kept for a possible DLC. In the main game these four slots became Madison's gala exes
(`docs/gala_exes_art_brief.md`). Art in this folder is a COPY of what shipped up to commit dce5959
(portraits_hd, burst intro cards with the old names lettered, ch_ sheets, KO stills). Masters: `grok_art/2026-11-09-parody-bosses/`,
`grok_art/2026-11-08-bosses/`; the rejected cartoon-head sheets are one folder up (`../*_cartoon_sheet.png`).

DLC note: these are real-billionaire parodies. Before any store release, check Google Play's policy on
real people (impersonation / public figures) and keep the faces made up (art rule P1).

## boss.gd entries (verbatim)
```gdscript
	"husk": {"name": "Elon Husk", "hp": 260.0, "attacks": ["posting", "rocket"],
		"intro": "Elon Husk: I bought this gala at 4 AM. Also your landlord. Also the concept of Tuesday.",
		"taunts": ["Free speech means I talk and you get rate-limited.", "Your apron is now a paid subscription.", "Self-punching in two weeks. It's been nine years.", "I'm not a billionaire. I'm a meme with a lawyer."],
		"rage": "Elon Husk: Fine. I'm posting a poll about whether you deserve to live.",
		"defeat": "Elon Husk: Losing builds character. I'll buy one tomorrow." },
	"bozos": {"name": "Jeff Bozos", "hp": 280.0, "attacks": ["drones", "shine"],
		"intro": "Jeff Bozos: Your beating ships today! Bathroom breaks not included for the driver.",
		"taunts": ["My warehouse workers get TWO pee bottles. Generous.", "Customers who fought me also bought: medical debt.", "I went to space so I'd never hear 'union' again.", "Your rating dropped to four stars. You're fired."],
		"rage": "Jeff Bozos: Activating surge pain! Now 30% more efficient!",
		"defeat": "Jeff Bozos: Fine. I'll write it off. I write EVERYTHING off." },
	"fences": {"name": "Bill Fences", "hp": 280.0, "attacks": ["bsod", "update"],
		"intro": "Bill Fences: Hello, user. Your defeat has been installed without consent.",
		"taunts": ["Restarting your life to apply updates.", "I solved poverty in a TED Talk. You're welcome.", "Your license for 'breathing' has expired.", "This beating is 64% complete. Estimated time: forever."],
		"rage": "Bill Fences: Initiating philanthropy! It's tax-deductible violence!",
		"defeat": "Bill Fences: Fatal error. I'll start a foundation about it." },
	"donald": {"name": "The Donald", "hp": 360.0, "attacks": ["tariff", "wall"],
		"intro": "The Donald: Tremendous gala. Paid for by a charity I may or may not have closed.",
		"taunts": ["Nobody's ever been sued more. Big league.", "Tariffs on spatulas. You'll pay. I won't.", "Your apron? Very low ratings. Sad.", "I declared bankruptcy six times. Ask me how I'm still rich."],
		"rage": "The Donald: Everybody's saying I'm winning. Mostly me. I'm saying it.",
		"defeat": "The Donald: Rigged! I'm counting this as a win anyway. Tremendous loss." },
# shared TELE lines
	"husk": {"name": "Elon Husk", "hp": 260.0, "attacks": ["posting", "rocket"],
	"bozos": {"name": "Jeff Bozos", "hp": 280.0, "attacks": ["drones", "shine"],
	"fences": {"name": "Bill Fences", "hp": 280.0, "attacks": ["bsod", "update"],
	"sendback": {"name": "Sir Sends-It-Back", "hp": 130.0, "attacks": ["posting", "charge"],
		"labels": {"post": "1 STAR" }, "tele": {"posting": "This is TOO medium.", "charge": "I'm coming BACK there." },
	"posting": [0.6, "Hold on, just posting..."], "rocket": [0.35, "LAUNCH!"],
	"drones": [0.7, "Same-day harm incoming!"], "shine": [0.2, "*belt buckle gleams*"],
	"bsod": [0.8, "Have you tried turning it off and on?"], "update": [0.5, "Mandatory update!"],
	"tariff": [0.8, "TARIFF! (You pay it.)"], "wall": [0.4, "A beautiful wall. Somebody else's money."],
const ATTACK_SFX: = {"rocket": "whoosh", "shine": "laser", "spray": "gun", "coins": "coin", "drones": "whoosh", "bsod": "fail", "tariff": "honk", "nft": "coin", "drop": "explosion", "vape": "hiss" }
		"posting":
		"drones":
		"bsod":
```

## knockouts.json entries (verbatim)
```json
{
  "husk": {
    "move": "SHIFT CHANGE",
    "stance": "Two hundred million people are watching his stream. Hector from the dish pit is watching mine. Hector isn't even watching. He's eating my fries.",
    "slip": "Rocket punch. Slow. Everything's slow after a double. I lean six inches left. The chat spams laughing faces. For once, the chat is right.",
    "xray": "The jaw is the only bone in the skull that moves. My elbow shows it somewhere new to go.",
    "finisher": "Like. Subscribe. Lie down.",
    "crowd": "Brittany: \"Viewers are dropping, Duff! Two hundred million. Forty million. Okay, it's mostly bots now.\"",
    "closer": "Stream ended. Viewers: zero. I fix my apron. Somewhere a market dips. Nobody I know owns any of it.",
    "live": true
  },
  "bozos": {
    "move": "SAME-DAY DELIVERY",
    "stance": "Order status: out for delivery. The package is me. He owns seventeen houses. I own a bus pass and a cat who thinks I'm staff.",
    "slip": "Drones. A whole fleet. I duck the first. The second hits the third. The fourth starts talking about a union.",
    "xray": "Two hinges hold a jaw on. His were assembled overseas. My knee comes up from below, and both hinges quit on the same shift.",
    "finisher": "You can't automate this. I checked. It's still just a guy with a spatula and nothing to lose.",
    "crowd": "Dolores: \"Return to sender. No refunds. Store policy.\"",
    "closer": "Status: delivered. Left at front door. Signed for by my left hook.",
    "live": true
  },
  "fences": {
    "move": "HARD REBOOT",
    "stance": "Error: punch not found. He's buffering. I'm not. I tap my chest twice and wait. Patience is free. Everything else, he sells you.",
    "slip": "Blue screen. The whole room goes blue. I've rebooted a register at 2 AM with ketchup on both thumbs. This is nothing.",
    "xray": "The spine is thirty-three vertebrae stacked like dirty plates. I clear the stack. Top to bottom. The way Dolores taught me.",
    "finisher": "Ctrl. Alt. Delete. Three hits, in order, no updates required.",
    "crowd": "Earl: \"Kid didn't even spill his coffee.\"",
    "closer": "Do you want to save your changes? He doesn't answer. Nobody ever does.",
    "live": true
  },
  "donald": {
    "move": "TARIFF THIS",
    "stance": "He's talking. Six minutes now. No commas. I wait for one. I'm still waiting. I step in on a vowel.",
    "slip": "A wall goes up. Big. Beautiful. Somebody else paid for it. I walk around the end. Every wall has an end.",
    "xray": "The human hand has twenty-seven bones. His are smaller than mine. Everybody says so. My fist says so the loudest.",
    "finisher": "Big league. Tremendous. The best knockout anybody's ever seen. People are saying.",
    "crowd": "Dolores: \"First time all night that man stopped talking. Somebody frame it.\"",
    "closer": "He calls it a landslide. Best loss in history. I call it Tuesday and clock back in.",
    "live": true
  }
}
```

## main.gd gala lines that referenced them
```
"post": "Hit by a hot take. 400k likes, zero facts.", "rocket": "Rocket strike! A 'rapid unscheduled disassembly.' Of me.",
"tariff": "TARIFF'D. My face now costs 25% more and I'm the one paying.", "tariff_bit": "Shrapnel from a tariff.", "wall": "Bonked by a beautiful wall.",
"boss": "Body-checked by a billionaire. Classic. They never touch anything they can't buy.",
_toast("Security takes my phone. 'Only billionaires may post, sir.'")
_say(["So a limo picks me up. Smells like money, shrimp and tax evasion.", "THE ELITE GALA. A butler takes my phone and my dignity. Bet he sells both to a tip line.", "Five billionaires. One line cook. Alright. Heard. Let's fucking cook."])
var lines: Array = [line, "I clear THE ELITE GALA. The billionaires flee to their New Zealand bunkers. Don't let the door hit ya."]
lines.append("{partner}: You beat up billionaires?? ...Put the spatula in the dishwasher.")
```
