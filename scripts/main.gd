extends Node2D

const WORLD: = Vector2(640, 360)
const PlayerScript: = preload("res://scripts/player.gd")
const RaccoonScript: = preload("res://scripts/raccoon.gd")
const HudScript: = preload("res://scripts/hud.gd")
const TouchScript: = preload("res://scripts/touch_controls.gd")
const TouchTutScript: = preload("res://scripts/touch_tutorial.gd")
const IsoTest: = preload("res://scripts/iso/iso_test.gd")
const Ground: = preload("res://scripts/ground.gd")
const Dressing: = preload("res://scripts/dressing.gd")
const ShiftScript: = preload("res://scripts/shift.gd")
const Daily: = preload("res://scripts/daily.gd")
const CatScript: = preload("res://scripts/cat.gd")
const SaveGame: = preload("res://scripts/save_game.gd")
const Cast: = preload("res://scripts/cast.gd")
const Card: = preload("res://scripts/minigames/card.gd")
const ExtraPack: = preload("res://scripts/extra_pack.gd")
const ShopScript: = preload("res://scripts/minigames/shop.gd")
const BabyScript: = preload("res://scripts/minigames/baby.gd")
const StealthScript: = preload("res://scripts/minigames/stealth.gd")
const EnemyScript: = preload("res://scripts/enemy.gd")
const Gear: = preload("res://scripts/gear.gd")
const WL: = preload("res://scripts/wordle_logic.gd")
const WordleScript: = preload("res://scripts/minigames/wordle.gd")
const GearScreen: = preload("res://scripts/minigames/gear_screen.gd")
const MashScript: = preload("res://scripts/minigames/mash.gd")
const Market: = preload("res://scripts/market.gd")
const PhoneScript: = preload("res://scripts/minigames/phone.gd")
const EndingScript: = preload("res://scripts/minigames/ending.gd")
const BossScript: = preload("res://scripts/boss.gd")
const KnockoutScript: = preload("res://scripts/knockout.gd")
const WaffleScript: = preload("res://scripts/waffle.gd")
const Bounties: = preload("res://scripts/bounties.gd")
const SideQuests: = preload("res://scripts/side_quests.gd")
const UiStyle: = preload("res://scripts/ui_style.gd")
const Errands: = preload("res://scripts/errands.gd")
const Buffs: = preload("res://scripts/buffs.gd")
const Dates: = preload("res://scripts/dates.gd")
const Transit: = preload("res://scripts/transit.gd")
const FunFacts: = preload("res://scripts/fun_facts.gd")
const Art: = preload("res://scripts/art.gd")
const AudioScript: = preload("res://scripts/audio.gd")
const CombatScript: = preload("res://scripts/combat.gd")
const CombatFX: = preload("res://scripts/combat_fx.gd")
const BarksScript: = preload("res://scripts/barks.gd")
const JuiceScript: = preload("res://scripts/juice.gd")
const CombatUI: = preload("res://scripts/combat_ui.gd")
const Life: = preload("res://scripts/life.gd")
const Moods: = preload("res://scripts/moods.gd")
const Mornings: = preload("res://scripts/mornings.gd")
const SymphonyScript: = preload("res://scripts/minigames/symphony.gd")
const AkaruiScript: = preload("res://scripts/minigames/akarui.gd")
const PlasmaScript: = preload("res://scripts/minigames/plasma.gd")
const BackwalkScript: = preload("res://scripts/minigames/backwalk.gd")
const BlackheadScript: = preload("res://scripts/minigames/blackheads.gd")
const PharmacyScript: = preload("res://scripts/minigames/pharmacy.gd")
const GroceryScript: = preload("res://scripts/minigames/grocery.gd")
const SettingsScript: = preload("res://scripts/minigames/settings.gd")
const CreditsScript: = preload("res://scripts/minigames/credits.gd")
const ShowTellScript: = preload("res://scripts/minigames/show_tell.gd")

const DAY_NAMES: = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const INSPECTOR_QUIPS: = ["Inspector Tiny: \"Raccoon contact detected. That's a write-up AND a vibe check.\"", "Inspector Tiny scribbles: 'Subject walks. Has no car. Suspicious.'", "Inspector Tiny: \"My quota is 12 violations a day. You're my 12. Congrats.\"", "Inspector Tiny is still here. Writing. On a clipboard he bought himself."]
const LATE_NOTICES: = [
	"LATE NOTICE: \"Dear Valued Revenue Stream, rent is non-negotiable. My boat is not.\" -Your Landlord",
	"LATE NOTICE: OPPD says electricity is 'a premium experience.' {partner} holds the flashlight while I read it. \"We'll figure it out, babe. We always do.\"",
	"LATE NOTICE: So it's taped to my door. Guy owns 41 doors and fixes zero of them.",
	"LATE NOTICE: \"Late fee: $15. Fee-processing fee: $4. Fee-anxiety fee: priceless.\" {cat3} could not care less.",
]
const KNOCK_LINES: = ["{cat1} knocks a mug off the counter. Looks me dead in the eye the whole time.", "{cat2} pushes the remote off the couch. On purpose. I watched.", "{cat1}'s on the counter. Again. He knows.", "{cat2} knocks over the trash. Now it's a crime scene."]
const RENT: = 110
const BILLS: = 40
const LATE_FEE: = 15
const AUTOSAVE_EVERY: = 180.0
const MIN_PER_SEC: = 2.0
## Balance (Duff, Nov 10: "soften them"). Was a flat 0.2/s (~6 per game hour) with no floor, so one errand
## trip could eat its own reward. Story gates were 50/60/65/70/75, now 45/50/55/60/65.
const WAIT_DRAIN: = 0.08          # happiness per real second while {partner} waits on a want (~2.4 per game hour)
const WAIT_DRAIN_WEEK1: = 0.04    # first 7 days
const WAIT_FLOOR: = 40.0          # waiting alone never drags her below this (Buffs.MIN_HAPPY)

const FORK_DOOR: = Vector2(535, 318)
const WAFFLE_SIGN_PT: = Vector2(606, 150)
const BOARD_PT: = Vector2(578, 318)
const WAFFLE_MIN_SHIFTS: = 3
const BRITT_POS: = Vector2(288, 140)

const AUTO_DOORS: = ["home_door", "door_out", "shop", "fork", "pharmacy", "grocery", "plasma"]
const AUTO_DOOR_R: = 9.0
const AUTO_REARM_R: = 20.0
const HOME_DOOR: = Vector2(95, 118)
const SHOP_PT: = Vector2(536, 124)   # Kwik glass doors (centre of the Nov 12 painted storefront)
const BUNS_POS: = SHOP_PT
const ENSURE_POS: = Vector2(172, 212)
const PHARM_R: = Rect2(345, 306, 76, 38)
const GROC_R: = Rect2(176, 290, 110, 48)
const PHARM_DOOR: = Vector2(383, 352)
const GROC_DOOR: = Vector2(231, 346)
const RACCOON_HOME: = Vector2(384, 128)
const RACCOON_SPOTS: = [Vector2(384, 128), Vector2(165, 350), Vector2(625, 225)]
const PORCH_PT: = Vector2(122, 117)
const NEIGHBOR_DOOR: = Vector2(230, 104)   # side quest "porch": the suspect's front door
## Side quest "alley" (Lost & Found): the three hidden things and the return box (Seen Cafe paper box).
const LOST_SPOTS: = {"ring": Vector2(327, 168), "collar": Vector2(500, 136), "shoe": Vector2(186, 262)}
const LOSTBOX_PT: = Vector2(258, 156)
const PIRATE_NAMES: = ["{pirate_1}", "{pirate_2}", "{pirate_3}", "{pirate_4}", "{pirate_5}", "{pirate_6}"]
const RACCOON_GIFTS: = [["a dollar (slightly damp)", "money", 1], ["a honey bun, still sealed. Somehow.", "honey buns", 1], ["a cat treat. {cat3} would approve.", "treats", 1], ["a bent fork (1 scrap)", "scrap", 1]]
const RACCOON_GAGS: = ["The raccoon pats my hand back. Best customer service in Omaha, and it works for trash.", "It shows me a french fry. Found it in the dumpster behind a $19 burger place. Same fry.", "It chitters like a hustle podcast. Pretty sure it's selling me a course.", "It washes my hand. Cleaner than half the line cooks I've worked with."]
const GALA_ORIGIN: = Vector2(400, 440)
const GALA_SIZE: = Vector2(320, 180)
const GALA_SPAWN: = Vector2(560, 590)
const BOSS_ORDER: = ["husk", "bozos", "fences", "baron", "donald"]
## The gala invite lands on this story day's morning (Duff, Nov 9: the $100k fund gate was
## unreachable in 30 days). Open from then to the end of the month and after.
const GALA_DAY: = 24
const ARENA_ORIGIN: = Vector2(760, 440)
const ARENA_SIZE: = Vector2(320, 180)
const ARENA_SPAWN: = Vector2(920, 590)
const FINAL_TIME: = 250.0   # was 210; Willnot has +20% HP since Nov 13

const STORY: = [
	{"id": "ghoster", "name": "{ex_1}", "day": 2, "happy": 45.0, "place": "SEEN CAFE", "r": Rect2(205, 108, 60, 40), "c": "#5a6a8a",
		"cash": 60, "scrap": 8, "ach": "Left On Read", "where": "the Seen Cafe (by the neighbor's)",
		"tip": "{partner}: Ugh. {ex_1} watched my story. Twelve times. He's lurking at the Seen Cafe. Make him go away?" },
	{"id": "gymbro", "name": "{ex_2}", "day": 4, "happy": 50.0, "place": "IRON TEMPLE GYM", "r": Rect2(400, 40, 55, 50), "c": "#8a3a5a",
		"cash": 90, "scrap": 10, "ach": "Skipped Leg Day", "where": "Iron Temple Gym (north road)",
		"tip": "{partner}: {ex_2} keeps posting gym selfies tagged 'thinking of what I lost'. He's at Iron Temple. Don't hit him while he flexes, it doesn't work." },
	{"id": "djvape", "name": "{ex_3}", "day": 6, "happy": 55.0, "place": "CLUB CLOUD 9", "r": Rect2(350, 232, 80, 52), "c": "#5a2a8a",
		"cash": 120, "scrap": 12, "ach": "Dropped The Beat", "where": "Club Cloud 9 (south of the crossroads)",
		"tip": "{partner}: {ex_3} dedicated a SoundCloud track to me. It's called 'Her Loss (Mango Ice Remix)'. She's spinning at Club Cloud 9. Roll through the bass drop." },
	{"id": "crypto", "name": "{ex_4}", "day": 9, "happy": 60.0, "place": "THE MINING RIG", "r": Rect2(200, 228, 58, 42), "c": "#3a5a3a",
		"cash": 160, "scrap": 15, "ach": "Rug Pulled The Rug Puller", "where": "The Mining Rig (garage by HOA HQ)",
		"tip": "{partner}: {ex_4} DMed me a 'business opportunity'. Again. His garage 'mining rig' is by HOA HQ. Don't stand on any rugs." },
	{"id": "willnot", "name": "{ex_final}", "day": 12, "happy": 65.0, "place": "{FINAL_TOWER}", "r": Rect2(340, 6, 52, 80), "c": "#4a4a5a",
		"cash": 500, "scrap": 25, "ach": "Forty Floors, Zero Shoes", "where": "{final_tower} (the tower up north)",
		"tip": "{partner}: Babe. All my exes are hiding out in {final_tower} with some guy named {ex_final}. No shoes. Lots of attitude. Clock's ticking, apparently." },
]
const TIERS: = [[0, 1.0, "Line Cook"], [5, 1.6, "Lead Line Cook"], [12, 2.5, "Sous Chef"], [21, 3.8, "Chef de Cuisine"], [32, 5.5, "Executive Chef"], [45, 8.0, "Celebrity Chef"]]
const FUND_HAPPY_CAP: = 15.0
const PETE_FIRST_DAY: = 7
const PETE_REST_DAYS: = 3
const PROJ_KINDS: = ["complaint", "citation", "flipflop", "firework", "post", "coin", "tariff", "tariff_bit", "rocket", "laser", "seen", "dumbbell", "bullet"]
const DROPS: = {
	"pirate": [1, 3, 0.3, 1], "scammer": [3, 6, 0.3, 1], "karen": [2, 4, 0.35, 1], "hoa": [3, 5, 0.6, 2],
	"hustler": [1, 3, 0.2, 1], "pete": [12, 20, 1.0, 5],
	"drone": [0, 1, 0.15, 1], "butler": [1, 3, 0.25, 1], "nft": [0, 2, 0.2, 1],
	"drunk": [1, 4, 0.3, 1], "heckler": [2, 5, 0.3, 1], "kid": [0, 1, 0.1, 1],
}
const DEFEAT_LINES: = {
	"drunk": "This drunk naps it off on booth 4. Leaves his tab: $%d and an apology on a napkin.",
	"heckler": "Bachelor bro goes down. The groomsmen chip in $%d for 'damages.' WOOOO (quietly).",
	"kid": "Kid crashes off the sugar and falls asleep standing up. I find $%d in birthday money.",
	"scammer": "I bonk the scammer. His LLC dissolves on contact. I get $%d back.",
	"karen": "Karen storms off to demand a manager of the sidewalk. Drops $%d in expired coupons.",
	"karen_buddy": "Linda leaves to start a Facebook group about me. +$%d",
	"hoa": "HOA enforcer goes down. His power was always just a laminated sheet. +$%d",
	"hustler": "I bonk the hustler. The 'opportunity'? MLM essential oils. +$%d",
	"pete": "Palm Beach Pete: 'My accountant will hear about this!' Drops $%d and a timeshare brochure.",
	"drone": "I swat a tip drone. It still takes its thirty percent. +$%d",
	"butler": "I bonk the butler. He unionizes on the spot and tips me $%d.",
	"nft": "NFT bonked. Floor price: $%d. Roadmap: also the floor.",
	"pirate": "Porch pirate goes down. Shoulda got a real job, like gig work. Oh wait. +$%d",
}
const OUTSIDE_SPAWN: = Vector2(95, 130)

const INT_ORIGIN: = Vector2(0, 440)
const INT_SIZE: = Vector2(320, 180)
const BED_R: = Rect2(12, 482, 56, 36)
const CRIB_R: = Rect2(76, 482, 30, 26)
const SHOWER_R: = Rect2(272, 482, 36, 40)
const FRIDGE_R: = Rect2(120, 482, 24, 36)
const COUNTER_R: = Rect2(144, 482, 92, 37)
const COUCH_R: = Rect2(20, 576, 72, 22)
const BOWLS_R: = Rect2(135, 592, 18, 6)
const BED_PT: = Vector2(30, 530)
const CRIB_PT: = Vector2(91, 518)
const SHOWER_PT: = Vector2(290, 532)
const KITCHEN_PT: = Vector2(200, 528)
const FRIDGE_PT: = Vector2(131, 515)
const COUCH_PT: = Vector2(56, 566)
const BOWLS_PT: = Vector2(144, 588)
const FREYA_PT: = Vector2(72, 526)
const MADISON_POS: = Vector2(110, 572)
const MAT_R: = Rect2(166, 540, 44, 16)
const MAIL_R: = Rect2(212, 576, 18, 10)
const MAIL_PT: = Vector2(222, 562)
const PLASMA_R: = Rect2(392, 100, 72, 40)
const PLASMA_DOOR: = Vector2(428, 148)
const MAT_PT: = Vector2(186, 548)
const MIRROR_R: = Rect2(272, 532, 17, 40)
const MIRROR_PT: = Vector2(262, 556)
const INT_DOOR_PT: = Vector2(160, 602)
const SIDE_TABLE_R: = Rect2(207, 574, 44, 26)
const DRESSER_R: = Rect2(290, 576, 22, 26)
const CAT_TREE_R: = Rect2(113, 600, 14, 12)
const INT_SPAWN: = Vector2(160, 594)
const HOME_SPAWN: = Vector2(40, 536)

const QUEST_NEEDS: = {
	"honey buns": {"honey buns": 1 },
	"formula": {"formula": 1 },
	"diapers": {"diapers": 1 },
	"cake": {"cherries": 1, "chocolate": 1, "cream": 1, "flour": 1, "eggs": 1 },
}

var buildings: = [
	{"r": Rect2(40, 40, 110, 70), "c": Color("#8a5a44"), "n": "HOME", "art": "sf_home" },
	{"r": Rect2(190, 40, 80, 60), "c": Color("#6b6b6b"), "n": "NEIGHBOR", "art": "sf_neighbor" },
	{"r": Rect2(470, 40, 130, 70), "c": Color("#3f6fb0"), "n": "KWIK-N-GO", "art": "sf_kwik" },
	{"r": Rect2(460, 240, 150, 70), "c": Color("#a03a3a"), "n": "{FORK}", "art": "sf_fork" },
	{"r": Rect2(40, 240, 120, 70), "c": Color("#5d4a7a"), "n": "HOA HQ", "art": "sf_hoa" },
	{"r": Rect2(205, 108, 60, 40), "c": Color("#5a6a8a"), "n": "SEEN CAFE", "art": "sf_seen", "story": "ghoster" },
	{"r": Rect2(400, 40, 55, 50), "c": Color("#8a3a5a"), "n": "IRON TEMPLE", "art": "sf_iron", "story": "gymbro" },
	{"r": Rect2(350, 232, 80, 52), "c": Color("#5a2a8a"), "n": "CLUB CLOUD 9", "art": "sf_club", "story": "djvape" },
	{"r": Rect2(200, 228, 58, 42), "c": Color("#3a5a3a"), "n": "MINING RIG", "art": "sf_mining", "story": "crypto" },
	{"r": Rect2(340, 6, 52, 80), "c": Color("#4a4a5a"), "n": "{FINAL_TOWER}", "art": "sf_plaza", "story": "willnot" },
	{"r": PHARM_R, "c": Color("#d8d8e0"), "n": "{PHARMACY}", "art": "sf_walgrumps", "errand": "pharmacy" },
	{"r": GROC_R, "c": Color("#c8323a"), "n": "{GROCERY}", "art": "sf_hywhee", "errand": "grocery" },
	{"r": PLASMA_R, "c": Color("#c05a6a"), "n": "{PLASMA_SIGN}", "art": "sf_plazmart", "small": true },
]
## street dressing (data/town_dressing.json); trees = trunk points, used for spawn spacing
var dressing: Array = Dressing.load_items()
var trees: Array = Dressing.tree_points(dressing)

var skip_title: = false
var life_events: = true
var save_path: = SaveGame.DEFAULT_PATH

var player: CharacterBody2D
var raccoons: Array = []
var raccoon_gift_day: = -1
var raccoon_pets: = 0
var porch_pkg: = false
var porch_day: = -1
var touch: Node2D
var tut: Node2D   # touch_tutorial.gd (three control cards, phones only)
var hud: Node2D
var audio: Node = null
var combat: Node = null
var cam: Camera2D
var juice: Node

const UI_SCALE: = 2.0
var cats: Array = []

var in_title: = false
var in_shift: = false
var shift: Node = null
var shift_layer: CanvasLayer = null
var overlay_layer: CanvasLayer = null
var overlay_node: Node = null

var location: = "outside"
var day_i: = 4
var day_count: = 1
var clock: = 420.0
var money: = 40
var energy: = 100.0
var happiness: = 60.0
var quest: = 0
var quest_kind: = ""
var last_quest_kind: = ""
var inventory: = {}
var leftovers: Array = []
var achievements: Array = []
var fryer_smell: = false
var shifts_worked: = 0
var rent_debt: = 0
var weeks_paid: = 0
var late_notices: = 0
var cats_fed_day: = -1
var couch_day: = -1
var crib_day: = -1
var freya_trust: = 0
var freya_treat_day: = -1
var inspector_follow: = false
var inspector_t: = 0.0
var gear: = Gear.new_state()
var shades: = false
var wordle: = {}
var wordle_seed: = 0
var kills: = {}
var market: = Market.new_state(1)
var brokerage: = Market.new_account(true)
var college: = Market.new_account(true)
var threads: = {"sister": [], "gala": [], "madison": [] }
var unread: = {"sister": false, "gala": false, "madison": false }
var errand: = Errands.new_errand()
var errand_stats: = Errands.new_stats()
var buffs: Dictionary = {}
var buff_days: Dictionary = {}
var meal_day: = -1
var cha_line_day: = -1
var _speed_on: = false

var date_invite: Dictionary = Dates.new_invite()
var date_stats: Dictionary = Dates.new_stats()
var glow_day: = -1
var plasma: Dictionary = Life.new_plasma()
var mood: Dictionary = Moods.new_mood()
var couch_night: = false
var morning: Dictionary = Mornings.new_state()   # Madison's slow / migraine / good mornings (mornings.gd)
var quest_wait: = 0.0
var restless_seen: Dictionary = {}
var restless_level: = 0
var restless_t: = 0.0
var sigh_t: = 0.0
var bills: Array = []
var owed: Array = []
var plans: Array = []
var rent_bump: = 0
var formula_spike_day: = -1
var event_days: Dictionary = {}
var phone_cracked: = false
var bills_paid: = 0
var has_car: = false
var bus_pass_until: = -1
var bus_rides: = 0
var last_text_day: = -1
var gala_unlocked: = false
var gala_beaten: = false
var gala_runs: = 0
var fund_happy_day: = -1
var fund_happy_today: = 0.0

var inspector_quip_t: = 0.0
var inspector_pos: = Vector2.ZERO
var barks: Node   # speech bubbles for enemies/bosses/raccoons (scripts/barks.gd)
var dialog: Array[String] = []
var ko_kind: = ""                           # boss knockout cutscene playing (knockout.gd, HD layer)
var _ko_boss: Node = null                   # boss whose knockout already played
var loading_req: = 0                        # bumped to ask loading_screen.gd for a loading screen
var loading_on: = false                     # a loading screen is up
var _drawn_loc: = ""                        # location the world canvas was last drawn for
var no_loading: = false                     # tools: skip loading screens
var hint: = ""
var routine_played: = false   # true after the first full bedtime routine; unlocks the BEDTIME skip card
var toast: = ""
var toast_t: = 0.0
var save_flash_t: = 0.0
var ensure_respawn: = 0.0
var autosave_t: = AUTOSAVE_EVERY
var knock_t: = 35.0
var night_report: Array = []
var spawn_t: = 20.0
var pete_cd: = 0.0
var pete_last_spawn_day: = -99
var pete_defeated_day: = -99
var last_wordle: Node = null
var gala_stage: = -1
var gala_boss: Node = null
var story: = {"beaten": [], "announced": [], "ending_seen": false, "attempts": 0, "cold_open": false }
var arena_id: = "":
	set(v):
		arena_id = v
		_sync_arena_walls()
# Extra walls for arenas whose art has furniture past the shared bands (relative to ARENA_ORIGIN, world units).
const ARENA_EXTRA_WALLS: = {
	"gymbro": [Rect2(0, 0, 320, 56)],  # ChatGPT C2 gym: racks along the back wall only
	# Painted arenas (Canva, Nov 10; tools/arena_import): back-wall furniture depth + perspective side walls.
	"alley": [Rect2(0, 0, 320, 56), Rect2(0, 0, 24, 96), Rect2(296, 0, 24, 96)],
	"ghoster": [Rect2(0, 0, 320, 56), Rect2(0, 0, 16, 90), Rect2(304, 0, 16, 90)],
	"djvape": [Rect2(0, 0, 320, 50), Rect2(126, 0, 68, 54), Rect2(0, 0, 20, 80), Rect2(300, 0, 20, 80)],
	"crypto": [Rect2(0, 0, 320, 54), Rect2(274, 0, 28, 64), Rect2(0, 0, 20, 80), Rect2(300, 0, 20, 80)],
	"willnot": [Rect2(0, 0, 320, 58), Rect2(0, 60, 20, 100), Rect2(300, 60, 20, 100)],
	"waffle": [Rect2(0, 0, 320, 74)],  # grill line; GRILLS (waffle.gd) sit on its front edge
}
var _arena_extra_bodies: = {}
var arena_mode: = ""
var bounty_id: = ""
var bounties: = {"beaten": [], "day": -1 }
var side_quests: = {}                  # side_quests.gd state (journal = phone Notes)
var show_hidden_quests: = false        # dev only: list + mark quests that aren't "ready" yet
var dlg_line: = ""                     # dialog typewriter: the line being revealed ...
var dlg_chars: = 0.0                   # ... and how many characters show so far
const DLG_CPS: = 70.0
var waffle_data: = {"shifts": 0, "regular_beaten": 0, "best": 0 }
var waffle_node: Node = null
var bet: = {"day": -1, "won": 0, "lost": 0 }
## Best grade ever per shift station ("fryer": "S"). An S unlocks Autopilot (B) for that station.
var station_best: Dictionary = {}
## Daily life (scripts/daily.gd): today's random event id, no-repeat list, Falcor thread state.
var daily: Dictionary = Daily.new_state()
var calendar_req: = 0                       # bumped to ask fridge_calendar.gd to show the month
var calendar_on: = false                    # fridge calendar is up (world frozen)
var calendar_pending: = false               # show it once the morning loading screen is gone
var door_armed: = {}
var door_loc: = ""
var bet_kind: = ""
var bet_stake: = 0
var bet_t: = 0.0
var bet_hits: = 0
var bet_kills: = 0
var bet_hurt: = 0
var bet_spawn: = 0.0
var arena_boss: Node = null
var final_timer: = 0.0
var finale_t: = 0.0
var t: = 0.0
var fact_i: = randi()   # next fun fact (Palahniuk layer, M9); random start, then in order, no repeats

func _ready() -> void:
	add_child(preload("res://scripts/hd_presentation.gd").new())
	_setup_input()
	for b in buildings:
		b["vis"] = _art_rect(b)
		_add_wall(Rect2(b["vis"].position, Vector2(b["vis"].size.x, b["r"].end.y - b["vis"].position.y)))
	for it in dressing:
		if it["wall"] != null:
			_add_wall(it["wall"])
		# tucked behind a storefront (art overlaps it, ground above its base): stays in main._draw
		var ar: = Dressing.art_rect(it)
		for b in buildings:
			if ar.has_area() and ar.intersects(b["vis"]) and it["p"].y < (b["r"] as Rect2).end.y:
				it["behind_building"] = true
	_add_wall(Rect2(-10, -10, WORLD.x + 20, 10))
	_add_wall(Rect2(-10, WORLD.y, WORLD.x + 20, 10))
	_add_wall(Rect2(-10, 0, 10, WORLD.y))
	_add_wall(Rect2(WORLD.x, 0, 10, WORLD.y))

	_add_wall(Rect2(0, 440, 320, 8))
	_add_wall(Rect2(0, 612, 320, 10))
	_add_wall(Rect2(0, 440, 8, 180))
	_add_wall(Rect2(312, 440, 8, 180))
	for r in [BED_R, CRIB_R, SHOWER_R, FRIDGE_R, COUNTER_R, COUCH_R, MIRROR_R, SIDE_TABLE_R, DRESSER_R, CAT_TREE_R]:
		_add_wall(r)
	_add_wall(Rect2(MADISON_POS - Vector2(4, 0), Vector2(8, 6)))

	_add_wall(Rect2(ARENA_ORIGIN.x, ARENA_ORIGIN.y, ARENA_SIZE.x, 30))
	_add_wall(Rect2(ARENA_ORIGIN.x, ARENA_ORIGIN.y + ARENA_SIZE.y - 8, ARENA_SIZE.x, 10))
	_add_wall(Rect2(ARENA_ORIGIN.x, ARENA_ORIGIN.y, 8, ARENA_SIZE.y))
	_add_wall(Rect2(ARENA_ORIGIN.x + ARENA_SIZE.x - 8, ARENA_ORIGIN.y, 8, ARENA_SIZE.y))
	for k in ARENA_EXTRA_WALLS:
		_arena_extra_bodies[k] = []
		for r in ARENA_EXTRA_WALLS[k]:
			_arena_extra_bodies[k].append(_add_wall(Rect2(ARENA_ORIGIN + r.position, r.size)))
	_sync_arena_walls()

	_add_wall(Rect2(GALA_ORIGIN.x, GALA_ORIGIN.y, GALA_SIZE.x, 30))
	_add_wall(Rect2(GALA_ORIGIN.x, GALA_ORIGIN.y + GALA_SIZE.y - 8, GALA_SIZE.x, 10))
	_add_wall(Rect2(GALA_ORIGIN.x, GALA_ORIGIN.y, 8, GALA_SIZE.y))
	_add_wall(Rect2(GALA_ORIGIN.x + GALA_SIZE.x - 8, GALA_ORIGIN.y, 8, GALA_SIZE.y))

	player = PlayerScript.new()
	player.position = OUTSIDE_SPAWN
	player.attacked.connect(_on_player_attack)
	add_child(player)
	var dfront: = preload("res://scripts/dressing_front.gd").new()
	dfront.m = self
	dfront.name = "DepthSort"   # y-sorts dressing + actors outdoors (z 0, see dressing_front.gd)
	add_child(dfront)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(UI_SCALE, UI_SCALE)
	player.add_child(cam)
	_set_camera()

	for spec in [["{cat1}", Color("#e08a2a"), Vector2(200, 560)], ["{cat2}", Color("#f0a848"), Vector2(250, 550)]]:
		var c: = CatScript.new()
		c.cat_name = spec[0]
		c.col = spec[1]
		c.position = spec[2]
		c.target = player
		c.m = self
		c.room = Rect2(20, 535, 280, 60)
		add_child(c)
		cats.append(c)

	_spawn_raccoons()

	audio = AudioScript.new()
	audio.name = "Audio"
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio)
	combat = CombatScript.new()
	combat.name = "Combat"
	combat.m = self
	add_child(combat)
	var cfx: = CombatFX.new()
	cfx.c = combat
	add_child(cfx)
	combat.fx = cfx
	barks = BarksScript.new()
	barks.name = "Barks"
	barks.m = self
	barks.fx = cfx
	add_child(barks)
	juice = JuiceScript.new()
	juice.name = "Juice"
	juice.m = self
	juice.fx = cfx
	add_child(juice)
	var layer: = ui_layer()
	add_child(layer)
	hud = HudScript.new()
	hud.m = self
	layer.add_child(hud)
	var cui: = CombatUI.new()
	cui.m = self
	cui.c = combat
	layer.add_child(cui)
	combat.ui = cui
	var wl: = WorldLabels.new()
	wl.m = self
	wl.name = "WorldLabels"
	wl.z_index = 50
	add_child(wl)
	touch = TouchScript.new()
	touch.player = player
	touch.m = self
	touch.a_pressed.connect(_on_a)
	touch.b_pressed.connect(_on_roll)
	touch.g_pressed.connect(open_gear)
	touch.p_pressed.connect(open_phone)
	touch.drawer_pressed.connect(func () -> void:
		if not busy():
			hud.toggle_drawer())
	touch.s_pressed.connect(func () -> void:
		if not busy() and dialog.is_empty():
			combat.special_pressed())
	touch.s_released.connect(func () -> void: combat.special_released())
	touch.swap_pressed.connect(func () -> void:
		if not busy():
			combat.swap())
	touch.d_pressed.connect(func () -> void:
		if not busy() and dialog.is_empty():
			combat.demon_pressed())
	layer.add_child(touch)
	tut = TouchTutScript.new()
	tut.visible = false
	touch.add_child(tut)

	if _check_debug_hash():
		return
	if skip_title:
		_after_world(func () -> void: new_game(false), 0)
	else:
		show_title()

func _setup_input() -> void:
	var map: = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_ENTER], "attack": [KEY_SPACE, KEY_J],
		"roll": [KEY_SHIFT, KEY_K, KEY_L], "gear": [KEY_I],
		"special": [KEY_F, KEY_U], "swap_special": [KEY_Q], "demon": [KEY_R], "stats": [KEY_T], "phone": [KEY_P], "drawer": [KEY_TAB], "settings": [KEY_O, KEY_ESCAPE],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for k in map[action]:
				var ev: = InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(action, ev)

func _sync_arena_walls() -> void:
	for k in _arena_extra_bodies:
		for b in _arena_extra_bodies[k]:
			b.collision_layer = 1 if k == arena_id else 0

func _add_wall(r: Rect2) -> StaticBody2D:
	var body: = StaticBody2D.new()
	body.collision_layer = 1
	var cs: = CollisionShape2D.new()
	var shape: = RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.get_center()
	body.add_child(cs)
	add_child(body)
	return body

func _set_camera() -> void:
	if location == "arena":
		cam.limit_left = int(ARENA_ORIGIN.x)
		cam.limit_top = int(ARENA_ORIGIN.y)
		cam.limit_right = int(ARENA_ORIGIN.x + ARENA_SIZE.x)
		cam.limit_bottom = int(ARENA_ORIGIN.y + ARENA_SIZE.y)
	elif location == "gala":
		cam.limit_left = int(GALA_ORIGIN.x)
		cam.limit_top = int(GALA_ORIGIN.y)
		cam.limit_right = int(GALA_ORIGIN.x + GALA_SIZE.x)
		cam.limit_bottom = int(GALA_ORIGIN.y + GALA_SIZE.y)
	elif location == "home":
		cam.limit_left = int(INT_ORIGIN.x)
		cam.limit_top = int(INT_ORIGIN.y)
		cam.limit_right = int(INT_ORIGIN.x + INT_SIZE.x)
		cam.limit_bottom = int(INT_ORIGIN.y + INT_SIZE.y)
	else:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(WORLD.x)
		cam.limit_bottom = int(WORLD.y)
	cam.reset_smoothing()

func _spawn_raccoons() -> void:
	for spot in RACCOON_SPOTS:
		var rc: = RaccoonScript.new()
		rc.position = spot + Vector2(10, 4)
		rc.target = player
		add_child(rc)
		rc.set_physics_process(location == "outside")
		raccoons.append(rc)

const TITLE_HELP_TOUCH: = ["Move: drag anywhere on the left half.  A: talk or use when someone's close, otherwise bonk (tap fast for a 3-hit combo).  B: dodge roll.  G: gear.  Phone: the phone icon up top.", " ", "S: special, from Seniority Lv 2 (hold to charge).  <>: swap special.  D: Demon Time.  Tap the top bar for money, bills and stats."]
const TITLE_HELP: = ["Move: WASD / arrows / joystick.  Use: E or A.  Bonk: Space (or A), mash for a 3-hit combo.  Dodge roll: Shift or B.  Gear: I or G.  Phone: P or the phone icon.", " ", "Special (from Lv 2): F or S (hold to charge).  Swap special: Q or <>.  Demon Time: R or D.  Spend stat points: T."]

func show_title() -> void:
	in_title = true
	var opts: Array = []
	# Title art (bg_title) carries the screen, so only the tagline sits on it; controls live behind "How to play".
	var lines: Array = ["Keep {partner} happy. Pay the rent. Survive 3 AM. Don't let the landlord win."]
	var d: = SaveGame.read(save_path)
	if not d.is_empty():
		opts.append(["continue", "Continue: Day %d (%s), $%d" % [int(d.get("day_count", 1)), DAY_NAMES[int(d.get("day_i", 4)) % 7].substr(0, 3), int(d.get("money", 0))], KEY_1])
		opts.append(["new", "New Game", KEY_2])
	else:
		opts.append(["new", "New Game", KEY_1])
	opts.append(["settings", "Settings (sound)", KEY_3 if opts.size() > 1 else KEY_2])
	opts.append(["help", "How to play", KEY_4 if opts.size() > 2 else KEY_3])
	_menu("{GAME_TITLE}", lines, opts, func (id: String) -> void:
		if id == "settings":
			open_settings()
		elif id == "help":
			var hopts: Array = [["back", "Back", KEY_1]]
			if Cast.touch:
				hopts.push_front(["cards", "Show me the buttons", KEY_2])
			_menu("How to play", TITLE_HELP_TOUCH if Cast.touch else TITLE_HELP, hopts, func (b: String) -> void:
				if b == "cards":
					tut.done.connect(show_title, CONNECT_ONE_SHOT)
					tut.start()
				else:
					show_title())
		elif id == "continue":
			_after_world(func () -> void:
				in_title = false
				load_game())
		elif SaveGame.exists(save_path):
			_menu("Start over?", ["This overwrites your saved game. {partner} will not remember the honey buns."], [["yes", "Yes, new game", KEY_1], ["no", "Never mind", KEY_2]],
				func (id2: String) -> void:
					if id2 == "yes":
						_after_world(func () -> void:
							in_title = false
							new_game(true), 0)
					else:
						show_title())
		else:
			_after_world(func () -> void:
				in_title = false
				new_game(true), 0), "title")

## Web: the art comes in packs right after boot (scripts/extra_pack.gd). New Game needs only street.pck (need 0:
## the cold open's street, Duff and the porch pirates); a saved game, the Fork, arenas and minigames need world.pck
## too (need 1). Starting before the pack lands would mean an invisible Duff, so hold on a "Loading Omaha" card
## until it's mounted. Back runs `back` (the title by default). Everywhere else (and once it's in) this just runs cb.
func _after_world(cb: Callable, need: int = 1, back: Callable = show_title) -> void:
	if ExtraPack.ready_for(need):
		cb.call()
		return
	var c: = Card.new()
	c.backdrop = "title" if in_title else ""
	c.heading = "Loading Omaha..."
	c.lines = ["Unpacking the neighbors..."]
	c.opts = [["back", "Back", KEY_1]]
	c.chosen.connect(func (_id: String) -> void:
		close_overlay()
		back.call())
	open_overlay(c)
	var tick: = func (tk: Callable) -> void:
		if not is_instance_valid(c) or not c.is_inside_tree():
			return   # backed out
		if ExtraPack.ready_for(need):
			close_overlay()
			cb.call()
			return
		var pr: float = ExtraPack.progress
		c.lines = [ExtraPack.retrying if ExtraPack.retrying != "" else
			"Unpacking the neighbors. " + ("%d%%" % int(pr * 100.0) if pr >= 0.0 else "%.1f MB" % ExtraPack.got_mb)]
		c.queue_redraw()
		get_tree().create_timer(0.25).timeout.connect(tk.bind(tk))
	get_tree().create_timer(0.25).timeout.connect(tick.bind(tick))

## Web, right after a new game: world.pck may still be streaming in. The Fork, arenas, the gala and minigames
## need it, so they wait on the loading card (Back just closes it). True = held; the caller returns.
func _world_gate(cb: Callable) -> bool:
	if ExtraPack.world_ready:
		return false
	_after_world(cb, 1, func () -> void: pass)
	return true

func new_game(write_save: bool = true) -> void:
	from_dict({})
	wordle_seed = randi()
	market = Market.new_state(randi())
	jen_text_daily()
	errand_new_day()
	daily_new_day()
	cold_open()
	if write_save:
		save_game()
	maybe_touch_tutorial()

## Nov 13: a new game opens on a fight, not a rules dump. A porch pirate jogs at {partner}'s package; one line
## says so, then the player has control. The rules come after he's down (or gone). On the web this plays on
## street.pck alone while world.pck streams in (extra_pack.gd). story.cold_open marks it running, so a save made
## mid-fight still gets the rules on Continue.
const COLD_OPEN_FROM: = Vector2(196, 152)   # sidewalk under the Seen Cafe: on screen, a clear run at the porch
func cold_open() -> void:
	porch_pkg = true
	porch_day = day_count
	story["cold_open"] = true
	var e: = spawn_enemy("pirate", COLD_OPEN_FROM)
	e.pname = PIRATE_NAMES[0]
	e.set_meta("cold_open", true)
	toast_t = 0.0   # the morning's "*bzzt* texts" toast can wait; the phone badge still shows it
	_say(["7 AM, day one. {partner}'s package is on the porch. A guy in a hoodie and sunglasses is jogging straight at it. Not today. %s" % ("Tap A to bonk him." if Cast.touch else "WASD or arrows to walk, Space to bonk him.")])

## The rules, after the cold open's pirate is down (won) or gone with the package.
func cold_open_rules(won: bool) -> Array:
	story["cold_open"] = false
	var lines: Array = []
	if not won and not porch_pkg:
		lines.append("He's gone. With the package. Great start. {partner} is going to hear about this.")
	lines.append("So here's the deal. Keep {partner} happy. Pay the rent. Guard the porch. Three rules. I'm already 0 for 1.")
	lines.append("{partner}'s inside on the couch, top-left house, and she's got that look." + (" Bring her that package." if won or porch_pkg else " She wants something. Probably a honey bun."))
	lines.append("Every Monday, rent, bills and the family basics: $%d. This first Monday it's prorated to $%d. {fork} (bottom-right) needs a cook, even this weekend. They always need a cook." % [weekly_base(), int(ceil(weekly_base() / 2.0))])
	return lines

## First new game on a phone: the three control cards, before the intro talk. Once per install.
func maybe_touch_tutorial() -> void:
	if Cast.touch and tut != null and not TouchTutScript.seen():
		tut.start()

func to_dict() -> Dictionary:
	return {
		"location": location, "px": player.position.x, "py": player.position.y,
		"day_i": day_i, "day_count": day_count, "clock": clock, "money": money, "energy": energy, "happiness": happiness,
		"quest": quest, "quest_kind": quest_kind, "last_quest_kind": last_quest_kind, "inventory": inventory.duplicate(),
		"leftovers": leftovers.duplicate(), "achievements": achievements.duplicate(), "fryer_smell": fryer_smell,
		"shifts_worked": shifts_worked, "station_best": station_best.duplicate(), "daily": daily.duplicate(true), "rent_debt": rent_debt, "weeks_paid": weeks_paid, "late_notices": late_notices,
		"cats_fed_day": cats_fed_day, "couch_day": couch_day, "crib_day": crib_day, "freya_trust": freya_trust,
		"freya_treat_day": freya_treat_day, "inspector_follow": inspector_follow, "inspector_t": inspector_t,
		"gear": gear.duplicate(true), "shades": shades, "wordle": wordle.duplicate(true), "wordle_seed": wordle_seed, "kills": kills.duplicate(),
		"pete_last_spawn_day": pete_last_spawn_day, "pete_defeated_day": pete_defeated_day,
		"raccoon_gift_day": raccoon_gift_day, "raccoon_pets": raccoon_pets, "porch_pkg": porch_pkg, "porch_day": porch_day,
		"story": story.duplicate(true), "bounties": bounties.duplicate(true), "side_quests": side_quests.duplicate(true), "waffle": waffle_data.duplicate(), "bet": bet.duplicate(),
		"errand": errand.duplicate(true), "errand_stats": errand_stats.duplicate(),
		"buffs": buffs.duplicate(true), "buff_days": buff_days.duplicate(), "meal_day": meal_day, "cha_line_day": cha_line_day,
		"date_invite": date_invite.duplicate(), "date_stats": date_stats.duplicate(), "glow_day": glow_day,
		"plasma": plasma.duplicate(true), "mood": mood.duplicate(), "couch_night": couch_night, "morning": morning.duplicate(), "routine_played": routine_played, "quest_wait": quest_wait,
		"bills": bills.duplicate(true), "owed": owed.duplicate(true), "plans": plans.duplicate(true), "rent_bump": rent_bump,
		"formula_spike_day": formula_spike_day, "event_days": event_days.duplicate(), "phone_cracked": phone_cracked, "bills_paid": bills_paid,
		"has_car": has_car, "bus_pass_until": bus_pass_until, "bus_rides": bus_rides,
		"market": market.duplicate(true), "brokerage": brokerage.duplicate(true), "college": college.duplicate(true),
		"threads": threads.duplicate(true), "unread": unread.duplicate(), "last_text_day": last_text_day,
		"gala_unlocked": gala_unlocked, "gala_beaten": gala_beaten, "gala_runs": gala_runs,
		"fund_happy_day": fund_happy_day, "fund_happy_today": fund_happy_today,
		"combat": combat.to_dict(),
	}

func from_dict(d: Dictionary) -> void:
	combat.from_dict(d.get("combat", {}))
	location = str(d.get("location", "outside"))
	if location == "gala" or location == "arena":
		location = "outside"
		d["px"] = OUTSIDE_SPAWN.x
		d["py"] = OUTSIDE_SPAWN.y
	day_i = int(d.get("day_i", 4))
	day_count = int(d.get("day_count", 1))
	clock = float(d.get("clock", 420.0))
	money = int(d.get("money", 40))
	energy = float(d.get("energy", 100.0))
	happiness = float(d.get("happiness", 60.0))
	quest = int(d.get("quest", 0))
	quest_kind = str(d.get("quest_kind", ""))
	last_quest_kind = str(d.get("last_quest_kind", ""))
	inventory = {}
	var inv: Dictionary = d.get("inventory", {})
	for k in inv:
		inventory[str(k)] = int(inv[k])
	leftovers = (d.get("leftovers", []) as Array).duplicate()
	achievements = (d.get("achievements", []) as Array).duplicate()
	var old_ach: int = achievements.find("Yippee-Ki-Yay, Chef")
	if old_ach >= 0:
		achievements[old_ach] = "Forty Floors, Zero Shoes"
	var britt_ach: int = achievements.find("Brittany Owes Me")   # stored by name before the {coworker} token
	if britt_ach >= 0:
		achievements[britt_ach] = "{coworker} Owes Me"
	var narc_ach: int = achievements.find("Narc of the Fork")   # stored by name before the {fork_nick} token
	if narc_ach >= 0:
		achievements[narc_ach] = "Narc of the {fork_nick}"
	fryer_smell = bool(d.get("fryer_smell", false))
	shifts_worked = int(d.get("shifts_worked", 0))
	rent_debt = int(d.get("rent_debt", 0))
	weeks_paid = int(d.get("weeks_paid", 0))
	late_notices = int(d.get("late_notices", 0))
	cats_fed_day = int(d.get("cats_fed_day", -1))
	couch_day = int(d.get("couch_day", -1))
	crib_day = int(d.get("crib_day", -1))
	freya_trust = int(d.get("freya_trust", 0))
	freya_treat_day = int(d.get("freya_treat_day", -1))
	inspector_follow = bool(d.get("inspector_follow", false))
	inspector_t = float(d.get("inspector_t", 0.0))
	gear = SaveGame.clean_gear(d.get("gear", {}))
	wordle = SaveGame.clean_wordle(d.get("wordle", {}))
	wordle_seed = int(d.get("wordle_seed", 0))
	kills = {}
	story = SaveGame.clean_story(d.get("story", {}))
	bounties = Bounties.clean(d.get("bounties", {}))
	side_quests = SideQuests.clean(d.get("side_quests", {}))
	daily = Daily.clean(d.get("daily", {}))
	var sb = d.get("station_best", {})
	station_best = sb.duplicate() if typeof(sb) == TYPE_DICTIONARY else {}
	var bd = d.get("bet", {})
	bet = {"day": -1, "won": 0, "lost": 0 }
	if typeof(bd) == TYPE_DICTIONARY:
		for k in bet:
			bet[k] = int(bd.get(k, bet[k]))
	var wd = d.get("waffle", {})
	waffle_data = {"shifts": 0, "regular_beaten": 0, "best": 0 }
	if typeof(wd) == TYPE_DICTIONARY:
		for k in waffle_data:
			waffle_data[k] = maxi(0, int(wd.get(k, 0)))
	errand = Errands.clean(d.get("errand", {}))
	errand_stats = Errands.clean_stats(d.get("errand_stats", {}))
	buffs = Buffs.clean(d.get("buffs", {}))
	buff_days = Buffs.clean_days(d.get("buff_days", {}))
	meal_day = int(d.get("meal_day", -1))
	cha_line_day = int(d.get("cha_line_day", -1))
	date_invite = Dates.clean_invite(d.get("date_invite", {}))
	date_stats = Dates.clean_stats(d.get("date_stats", {}))
	glow_day = int(d.get("glow_day", -1))
	plasma = Life.clean_plasma(d.get("plasma", {}))
	mood = Moods.clean_mood(d.get("mood", {}))
	couch_night = bool(d.get("couch_night", false))
	morning = Mornings.clean(d.get("morning", {}))
	routine_played = bool(d.get("routine_played", int(d.get("day_count", 1)) > 1))   # old saves: past night one
	quest_wait = float(d.get("quest_wait", 0.0))
	bills = Life.clean_list(d.get("bills", []), ["day", "due"])
	owed = Life.clean_list(d.get("owed", []), ["day", "fee", "text"])
	plans = Life.clean_list(d.get("plans", []), ["per", "left"])
	rent_bump = int(d.get("rent_bump", 0))
	formula_spike_day = int(d.get("formula_spike_day", -1))
	has_car = bool(d.get("has_car", false))
	bus_pass_until = int(d.get("bus_pass_until", -1))
	bus_rides = int(d.get("bus_rides", 0))
	event_days = {}
	var evd = d.get("event_days", {})
	if typeof(evd) == TYPE_DICTIONARY:
		for k in evd:
			event_days[str(k)] = int(evd[k])
	phone_cracked = bool(d.get("phone_cracked", false))
	bills_paid = int(d.get("bills_paid", 0))
	restless_seen = {}
	arena_id = ""
	arena_mode = ""
	arena_boss = null
	finale_t = 0.0
	pete_last_spawn_day = int(d.get("pete_last_spawn_day", -99))
	pete_defeated_day = int(d.get("pete_defeated_day", -99))
	raccoon_gift_day = int(d.get("raccoon_gift_day", -1))
	raccoon_pets = int(d.get("raccoon_pets", 0))
	porch_pkg = bool(d.get("porch_pkg", false))
	porch_day = int(d.get("porch_day", -1))
	shades = bool(d.get("shades", false))
	var kd: Dictionary = d.get("kills", {})
	for k in kd:
		var kk: = "baron" if str(k) == "schnitzel" else str(k)
		kills[kk] = int(kills.get(kk, 0)) + int(kd[k])
	market = Market.clean_state(d.get("market", {}), wordle_seed + 7)
	brokerage = Market.clean_account(d.get("brokerage", {}))
	college = Market.clean_account(d.get("college", {}))
	threads = SaveGame.clean_threads(d.get("threads", {}))
	unread = {"sister": false, "gala": false, "madison": false }
	var ud: Dictionary = d.get("unread", {})
	for k in ud:
		unread[str(k)] = bool(ud[k])
	last_text_day = int(d.get("last_text_day", -1))
	gala_unlocked = bool(d.get("gala_unlocked", false))
	gala_beaten = bool(d.get("gala_beaten", false))
	gala_runs = int(d.get("gala_runs", 0))
	if not gala_unlocked and gala_due():
		check_gala_unlock(false)   # save from before the day-24 gate, already past the invite morning
	fund_happy_day = int(d.get("fund_happy_day", -1))
	fund_happy_today = float(d.get("fund_happy_today", 0.0))
	gala_stage = -1
	gala_boss = null
	clear_enemies()
	apply_gear()
	var default_pos: = INT_SPAWN if location == "home" else OUTSIDE_SPAWN
	player.position = Vector2(float(d.get("px", default_pos.x)), float(d.get("py", default_pos.y)))
	inspector_pos = player.position
	dialog.clear()
	_set_camera()
	_sync_world()

func save_game(manual: bool = false) -> bool:
	var ok: = SaveGame.write(to_dict(), save_path)
	save_flash_t = 1.5
	autosave_t = AUTOSAVE_EVERY
	if manual:
		_toast("Game saved." if ok else "Save failed?! Well, shit. Tell {hero}.")
	return ok

func load_game() -> bool:
	var d: = SaveGame.read(save_path)
	if d.is_empty():
		new_game(true)
		return false
	from_dict(d)
	_say(["So where was I. Day %d, %s, %s." % [day_count, DAY_NAMES[day_i % 7], clock_text()], next_fact()])
	if bool(story.get("cold_open", false)):
		_say(cold_open_rules(false))
	jen_text_daily()
	_say(errand_new_day())
	return true

func _sync_world() -> void:
	for rc in raccoons:
		if is_instance_valid(rc):
			rc.set_physics_process(location == "outside" and not busy())
	var live: = location in ["outside", "gala", "arena"] and not busy() and finale_t <= 0.0
	for n in get_tree().get_nodes_in_group("hostile"):
		n.set_physics_process(live)
	for c in cats:
		c.hungry = cats_fed_day != day_count
		c.set_process(location == "home" and not busy())
	player.carrying = int(inventory.get("honey buns", 0)) > 0

static func ui_layer() -> CanvasLayer:

	var l: = CanvasLayer.new()
	l.scale = Vector2(UI_SCALE, UI_SCALE)
	return l

func busy() -> bool:
	return in_title or in_shift or overlay_node != null or ko_kind != "" or loading_on or calendar_on or (tut != null and tut.active())

## Loading screen (loading_screen.gd on the HD layer). Freezes the world until it's dismissed.
func show_loading() -> void:
	if no_loading:
		return
	loading_on = true
	loading_req += 1
	player.frozen = true
	_sync_world()

func loading_done() -> void:
	loading_on = false
	if calendar_pending:
		calendar_pending = false
		show_calendar()
	_sync_world()

## Fridge calendar (fridge_calendar.gd on the HD layer). Freezes the world until tapped away.
func show_calendar() -> void:
	if no_loading:
		return
	calendar_on = true
	calendar_req += 1
	player.frozen = true
	_sync_world()

func calendar_done() -> void:
	calendar_on = false
	_sync_world()

## Called by knockout.gd when the cutscene ends: run the normal defeat flow.
func knockout_done() -> void:
	ko_kind = ""
	_sync_world()
	if is_instance_valid(_ko_boss):
		boss_defeated(_ko_boss)

func open_overlay(node: Node) -> void:
	close_overlay()
	overlay_layer = ui_layer()
	overlay_layer.layer = 10
	add_child(overlay_layer)
	overlay_node = node
	overlay_layer.add_child(node)
	player.frozen = true
	touch.set_process_input(false)
	touch.visible = false
	hud.visible = false
	_sync_world()

func close_overlay() -> void:
	if overlay_layer and is_instance_valid(overlay_layer):
		overlay_layer.queue_free()
	overlay_layer = null
	overlay_node = null
	if not in_shift:
		hud.visible = true
		touch.set_process_input(true)
		touch.visible = TouchScript.default_visible() or bool(touch.get("used"))
		Cast.touch = touch.visible
	_sync_world()

func _menu(heading: String, lines: Array, opts: Array, cb: Callable, backdrop: String = "") -> void:
	var c: = Card.new()
	c.backdrop = backdrop
	c.heading = Cast.N(heading)
	c.lines = lines.map(func (l): return Cast.N(str(l)))
	var o2: Array = []
	for o in opts:
		var oo: Array = (o as Array).duplicate()
		oo[1] = Cast.N(str(oo[1]))
		o2.append(oo)
	c.opts = o2
	c.chosen.connect(func (id: String) -> void:
		close_overlay()
		cb.call(id))
	open_overlay(c)

func _run_game(node: Node, cb: Callable) -> void:
	if not node is SettingsScript and _world_gate(func () -> void: _run_game(node, cb)):
		return
	node.finished.connect(func (score: float, notes: Array) -> void:
		close_overlay()
		cb.call(node, score, notes))
	open_overlay(node)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_released("special"):
		combat.special_released()
	if busy() or combat.cinematic:
		return
	if dialog.is_empty():
		if e.is_action_pressed("special"):
			combat.special_pressed()
			return
		if e.is_action_pressed("swap_special"):
			combat.swap()
			return
		if e.is_action_pressed("demon"):
			combat.demon_pressed()
			return
		if e.is_action_pressed("stats"):
			if combat.points > 0:
				combat.open_allocation()
			else:
				_toast("Seniority Lv %d. STR %d  DEF %d  HEAT %d  GRIT %d. No points to spend." % [combat.level, combat.stats["str"], combat.stats["def"], combat.stats["heat"], combat.stats["grit"]])
			return
	if e.is_action_pressed("interact"):
		_on_interact()
	elif e.is_action_pressed("attack"):
		_on_attack()
	elif e.is_action_pressed("roll"):
		_on_roll()
	elif e.is_action_pressed("gear"):
		open_gear()
	elif e.is_action_pressed("phone"):
		open_phone()
	elif e.is_action_pressed("drawer"):
		hud.toggle_drawer()
	elif e.is_action_pressed("settings"):
		open_settings()

## One tap on a talking line: finish the typewriter first, then move to the next line.
func advance_dialog() -> void:
	if dialog.is_empty():
		return
	if dlg_line == str(dialog[0]) and dlg_chars < dialog_len():
		dlg_chars = 100000.0
		return
	dialog.pop_front()

func dialog_len() -> int:
	return Cast.T(str(dialog[0])).length() if not dialog.is_empty() else 0

func _tick_dialog(delta: float) -> void:
	if dialog.is_empty():
		dlg_line = ""
		return
	if str(dialog[0]) != dlg_line:
		dlg_line = str(dialog[0])
		dlg_chars = 0.0
	dlg_chars += DLG_CPS * delta

func _on_attack() -> void:
	if busy():
		return
	if not dialog.is_empty():
		advance_dialog()
		return
	if combat.locked_out():
		return
	player.swing()

func _on_a() -> void:

	if busy():
		return
	if not dialog.is_empty():
		advance_dialog()
		return
	var it: = nearest_interactable()
	if not it.is_empty():
		interact(str(it["id"]))
	else:
		player.swing()

func _on_roll() -> void:
	if busy():
		return
	if not dialog.is_empty():
		advance_dialog()
		return
	player.roll()

func player_atk() -> float:
	var atk: = Gear.attack(gear)
	if buff_active("strength"):
		atk *= Buffs.STR_MULT
	if drained():
		atk *= Life.DRAIN_DMG
	return atk

func _on_player_attack(pos: Vector2, dir: Vector2) -> void:
	var sp: = Gear.w_special(gear)
	var step: int = player.combo_step
	var fin: bool = player.is_finisher()
	var atk: float = player_atk() * combat.dmg_mult() * ([1.0, 1.1, 1.25, 1.35][mini(step, 3)] if not fin else 1.7)
	var sweep: = sp in ["sweep", "golden"]
	var center: = player.global_position if sweep else pos
	var reach: = (24.0 if sweep else 16.0) + (4.0 if fin else 0.0)

	var hit_sp: = sp
	if fin and sp in ["quick", "", "execute", "golden", "sweep"]:
		hit_sp = "flip"
	var targets: Array = []
	for rc in raccoons:
		if is_instance_valid(rc) and rc.global_position.distance_to(center) < reach:
			rc.bonked(player.global_position)
			_toast("Whoa. I don't bonk friends. That raccoon's the only one in town not trying to charge me.")
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and e.global_position.distance_to(center) < reach + (4.0 if e.kind == "pete" else (8.0 if e.is_in_group("boss") else 0.0)):
			targets.append(e)
	if not targets.is_empty():
		AudioScript.sfx("bonk")
	for e in targets:
		var dmg: = atk
		var e_sp: = hit_sp
		if (sp == "execute" or sp == "golden") and randf() < 0.25:
			dmg *= 2.0
			if not e_sp in ["flip", "stun", "pierce"]:
				e_sp = "crit"
			_toast("CRIT! The Cleaver hungers." if sp == "execute" else "CRIT! Generational damage. Like their wealth, but useful.")
		if sp == "golden":
			money += 1
		var hd: Vector2 = (e.global_position - player.global_position).normalized() if sweep else dir
		combat.hit(e, hd, dmg, e_sp, combat.finisher_heat() if fin else combat.HEAT_PER_HIT)
		if sp == "execute":
			energy = minf(energy_cap(), energy + energy_gain(2.0))
	for pr in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(pr) and pr.global_position.distance_to(center) < reach + 2.0:
			pr.queue_free()
			_toast("Swatted it. Complaint escalated to nobody.")

func interactables() -> Array:
	if location == "arena" and arena_mode == "waffle" and waffle_node != null:
		var gl: Array = []
		for g in 3:
			gl.append({"id": "grill_%d" % g, "pos": ARENA_ORIGIN + WaffleScript.GRILLS[g], "r": 18.0, "label": waffle_node.grill_label(g) })
		return gl
	if location == "gala" or location == "arena":
		return []
	if location == "home":
		return [
			{"id": "madison", "pos": madison_spot(), "r": 22.0, "label": "Talk to {partner}" },
			{"id": "bed", "pos": BED_PT, "r": 16.0, "label": "Bed (sleep / save)" },
			{"id": "freya", "pos": FREYA_PT, "r": 14.0, "label": "{cat3} (under the bed)" },
			{"id": "crib", "pos": CRIB_PT, "r": 16.0, "label": "Check on {baby}" },
			{"id": "shower", "pos": SHOWER_PT, "r": 18.0, "label": "Shower" },
			{"id": "kitchen", "pos": KITCHEN_PT, "r": 20.0, "label": "Kitchen" },
			{"id": "fridge", "pos": FRIDGE_PT, "r": 13.0, "label": "Fridge calendar" },
			{"id": "couch", "pos": COUCH_PT, "r": 18.0, "label": "Couch time with {partner}" },
			{"id": "backwalk", "pos": MAT_PT, "r": 14.0, "label": "Back walk from {partner} (SPEED)" },
			{"id": "mirror", "pos": MIRROR_PT, "r": 13.0, "label": "Mirror (blackheads / cologne)" },
			{"id": "mail", "pos": MAIL_PT, "r": 12.0, "label": "Mail table (%d)" % bills.size() if not bills.is_empty() else "Mail table" },
			{"id": "bowls", "pos": BOWLS_PT, "r": 16.0, "label": "Feed the cats" },
			{"id": "door_out", "pos": INT_DOOR_PT, "r": 16.0, "label": "Go outside" },
		]
	return [
		{"id": "home_door", "pos": HOME_DOOR, "r": 16.0, "label": "Go inside" },
		{"id": "shop", "pos": SHOP_PT, "r": 16.0, "label": "Shop at Kwik-N-Go" },
		{"id": "fork", "pos": FORK_DOOR, "r": 16.0, "label": "Clock in at {fork}" },
		{"id": "brittany", "pos": BRITT_POS, "r": 16.0, "label": "{coworker} (she's got a bet)" if int(bet["day"]) != day_count else "{coworker}" },
		{"id": "bounty_board", "pos": BOARD_PT, "r": 14.0, "label": "The 86 List (bounty board)" },
		{"id": "waffle_sign", "pos": WAFFLE_SIGN_PT, "r": 16.0, "label": "Waffle Haus (graveyard shift)" },
		{"id": "pharmacy", "pos": PHARM_DOOR, "r": 16.0, "label": "Enter {pharmacy}" },
		{"id": "grocery", "pos": GROC_DOOR, "r": 16.0, "label": "Enter {grocery}" },
		{"id": "plasma", "pos": PLASMA_DOOR, "r": 16.0, "label": "Enter {plasma}" },
	] + story_doors() + raccoon_spots() + bus_stops() + quest_interactables()

func nearest_interactable() -> Dictionary:
	var best: = {}
	var bd: = 1000000000.0
	for it in interactables():
		var d: = player.position.distance_to(it["pos"])
		if d < float(it["r"]) and d < bd:
			bd = d
			best = it
	return best

func _on_interact() -> void:
	if busy():
		return
	if not dialog.is_empty():
		advance_dialog()
		return
	var it: = nearest_interactable()
	if it.is_empty():
		return
	interact(str(it["id"]))

func interact(id: String) -> void:
	if id.begins_with("grill_") and waffle_node != null:
		waffle_node.use_grill(int(id.substr(6)))
		return
	match id:
		"bounty_board":
			if not quest_talk("bounty_board"):
				bounty_menu()
		"brittany":
			if not quest_talk("brittany"):
				bet_menu()
		"waffle_sign": waffle_menu()
		"home_door": enter_home()
		"door_out": leave_home()
		"shop": open_shop()
		"fork": try_shift()
		"madison": _talk_to_madison()
		"bed": bed_menu()
		"freya":
			AudioScript.sfx("hiss")
			freya_menu()
		"crib": check_crib()
		"fridge": show_calendar()
		"shower": shower()
		"kitchen": kitchen()
		"couch": couch_time()
		"backwalk": start_backwalk()
		"mirror": mirror_menu()
		"mail":
			if not quest_talk("mail"):
				mail_menu()
		"plasma": open_plasma()
		"bowls": feed_cats()
		"pharmacy": open_pharmacy()
		"grocery": open_grocery()
		_:
			if id.begins_with("story_"):
				story_menu(id.substr(6))
			elif id.begins_with("raccoon_"):
				pet_raccoon(int(id.substr(8)))
			elif id.begins_with("bus_"):
				bus_menu(id.substr(4))
			elif id.begins_with("quest_"):
				quest_talk(id.substr(6))

func enter_home() -> void:
	AudioScript.sfx("door")
	location = "home"
	player.position = INT_SPAWN
	_set_camera()
	_sync_world()
	save_game()

func leave_home() -> void:
	AudioScript.sfx("door")
	location = "outside"
	player.position = OUTSIDE_SPAWN
	_set_camera()
	_sync_world()
	save_game()

func open_shop() -> void:
	var s: = ShopScript.new()
	s.m = self
	_run_game(s, func (_n: Node, _s: float, _notes: Array) -> void:
		advance_clock(10.0)
		_sync_world())

func shower() -> void:
	advance_clock(20.0)
	if fryer_smell:
		fryer_smell = false
		_toast("So I scrub the fryer off me. Water burns at 160. Fryer oil runs at 350. My forearms do the math.")
	else:
		_toast("I'm already clean, man. Water bill's high enough.")

func check_crib() -> void:
	if morning_hard_pending() and not bool(morning["fed"]):
		morning["fed"] = true
		if crib_day != day_count:
			crib_day = day_count
			energy = minf(energy_cap(), energy + energy_gain(5.0))
		_say([Mornings.feed_line(str(morning["kind"]))])
		return
	if crib_day != day_count:
		crib_day = day_count
		energy = minf(energy_cap(), energy + energy_gain(5.0))
		_toast("{baby} gurgles at me. That's it. That's the whole reason. +5 Energy")
	else:
		_toast("She's asleep. Behind. BEHIND. Backing away slow.")

func couch_time() -> void:
	var ph: = phase()
	if ph != "Evening":
		_say(["{partner}: Couch time is for the evening, chef. %s" % ("Go make money." if ph != "Night" else "It's the middle of the night. Go to bed.")])
		return
	if couch_day == day_count:
		_say(["{partner}: Again? ...Yeah, okay. Scoot over, babe."])
		return
	couch_day = day_count
	gain_happy(15.0)
	advance_clock(60.0)
	var cl: Array = ["Me and {partner} veg out on the couch. She steals the blanket. {cat1} sits on the remote like he pays the cable bill.", "+15 Happiness"]
	cl.append_array(make_up())
	_say(cl)

func feed_cats() -> void:
	if cats_fed_day == day_count:
		_toast("They already ate. They're lying to my face. Professionals.")
		return
	cats_fed_day = day_count
	AudioScript.sfx("meow")
	_sync_world()
	_toast("{cat1} and {cat2} inhale it. {cat3} waits till I leave the room.")

func kitchen() -> void:
	if morning_hard_pending() and not bool(morning["coffee"]):
		morning["coffee"] = true
		_say([Mornings.COFFEE])
		return
	var opts: Array = []
	if int(inventory.get("cake", 0)) > 0:
		opts.append(["cake", "Eat Black Forest cake (+60 Energy)", KEY_1])
	if int(inventory.get("ensure", 0)) > 0:
		opts.append(["ensure", "Drink an Ensure (+40 Energy)", KEY_2])
	if meal_available():
		opts.append(["meal", "Eat what {partner} cooked (+25 Energy, STRENGTH)", KEY_3])
	if opts.is_empty():
		var have: Array = []
		for k in QUEST_NEEDS["cake"]:
			if int(inventory.get(k, 0)) > 0:
				have.append(k)
		_say(["Fridge is 86'd. One sad pickle. Even he looks tired.",
			"{partner} says she'll bake Black Forest cake if I bring cherries, chocolate, cream, flour and eggs (Kwik-N-Go). Got: %s" % (", ".join(have) if not have.is_empty() else "nothing")])
		return
	opts.append(["no", "Never mind", KEY_ESCAPE])
	_menu("KITCHEN", ["What are we having, chef?"], opts, func (id: String) -> void: use_item(id))

func use_item(id: String) -> void:
	if id == "meal":
		eat_her_meal()
		return
	if int(inventory.get(id, 0)) <= 0:
		return
	if id == "cake":
		inventory["cake"] -= 1
		energy = minf(energy_cap(), energy + energy_gain(60.0))
		var msg: = "I eat {partner}'s Black Forest cake. Cherries. Chocolate. Love. Hell of a girl. +60 Energy"
		if grant_buff("strength", Buffs.STRENGTH_MINS):
			msg += ". STRENGTH up: +25% damage for 5 hrs"
		_toast(msg)
	elif id == "ensure":
		inventory["ensure"] -= 1
		energy = minf(energy_cap(), energy + energy_gain(40.0))
		_toast("I crack a vanilla Ensure. Breakfast of champions and grandmas. +40 Energy")

func freya_menu() -> void:
	var treats: = int(inventory.get("treats", 0))
	_menu("{CAT3}", ["A long-haired tabby glares at me from under the bed. Trust: %s" % ("<3 ".repeat(freya_trust).strip_edges() if freya_trust > 0 else "none. zero. nada.")],
		[["pet", "Pet her (brave)", KEY_1], ["treat", "Give a treat (%d)" % treats, KEY_2], ["leave", "Leave her alone", KEY_3]],
		func (id: String) -> void:
			if id == "pet":
				freya_pet(randf())
			elif id == "treat":
				freya_treat())

func freya_treat() -> void:
	if int(inventory.get("treats", 0)) <= 0:
		_toast("No treats. {cat3} clocks me as a fraud the second I walk in.")
		return
	inventory["treats"] -= 1
	if freya_treat_day != day_count:
		freya_treat_day = day_count
		freya_trust += 1
		_toast("{cat3} takes the treat and hisses 'thank you.' Rude. I love her. Trust +1")
	else:
		_toast("She eats it. But trust, man, that's earned one day at a time.")

func freya_pet(roll: float) -> void:
	if freya_trust >= 5:
		if not achievements.has("{cat3} Approves"):
			achievements.append("{cat3} Approves")
			_say(["{cat3}... head-bumps my hand. Once. Then leaves like it never happened.", "ACHIEVEMENT UNLOCKED: {cat3} Approves"])
		else:
			_toast("{cat3} tolerates exactly three pets. I get three.")
		return
	var swipe_chance: = 0.85 if freya_trust < 3 else 0.45
	if roll < swipe_chance:
		energy = maxf(1.0, energy - 5.0)
		_toast("{cat3} swipes. Three tiny red lines. Honestly? I earned that. -5 Energy")
	else:
		_toast("{cat3} lets me get one pet in. Then hisses to save face.")

func bed_menu() -> void:
	var can_sleep: = clock >= 1200.0 or clock < 300.0
	var opts: Array = []
	if can_sleep:
		opts.append(["sleep", "Sleep (end the day)", KEY_1])
	opts.append(["save", "Save game", KEY_2])
	opts.append(["no", "Never mind", KEY_3])
	var lines: Array = ["%s, %s." % [DAY_NAMES[day_i % 7], clock_text()]]
	if not can_sleep:
		lines.append("Too early to sleep. {partner}: \"It's %s, {hero}.\" (bed opens at 8 PM)" % clock_text())
	_menu("BED", lines, opts, func (id: String) -> void:
		if id == "sleep":
			go_to_sleep(false)
		elif id == "save":
			save_game(true))

func go_to_sleep(passed_out: bool) -> void:
	night_report = []
	if passed_out:
		night_report.append("I pass out at 2 AM. Floor. Fully dressed. My body quit without notice. {partner} drags me to bed. -5 Happiness")
		happiness = maxf(0.0, happiness - 5.0)
	if cats_fed_day != day_count:
		night_report.append("Nobody feeds the cats. They yowl till 1 AM. -5 Happiness")
		happiness = maxf(0.0, happiness - 5.0)
	if mood_kind() == "upset":
		couch_night = true
		night_report.append(Moods.COUCH_LINE)
	location = "home"
	player.position = HOME_SPAWN
	_set_camera()
	if passed_out or couch_night:
		if couch_night:
			night_report.append("No Show & Tell tonight. But she still leaves her phone face-up on my side of the bed. Just in case.")
		_start_baby_shift()
		return
	if not routine_played:   # first night: play it all once so the routine makes sense
		_play_night_routine()
		return
	_menu("BEDTIME", ["Show & Tell with {partner}, the 3 AM shift, then the creak-free crawl to bed.",
		"Skip it and I wing the whole night on autopilot. Safe, but smaller payoff."],
		[["play", "Play tonight", KEY_1], ["skip", "Skip: autopilot", KEY_2]],
		func (c: String) -> void:
			if c == "skip":
				_skip_night_routine()
			else:
				_play_night_routine())

func _play_night_routine() -> void:
	var st: = ShowTellScript.new()
	st.ctx = {"seed": day_count * 7919 + int(wordle_seed) }
	_run_game(st, _after_show_tell)

## IGN review: the nightly trio ran every night with no skip. Autopilot = a middling Show & Tell
## (+8, below a good game's +10..12), one bottle + one diaper used, sneak to bed clean. Running out
## of supplies still costs exactly what it costs in the real minigame.
func _skip_night_routine() -> void:
	var gain: = 8.0
	happiness = minf(100.0, happiness + gain)
	night_report.append("Autopilot Show & Tell. I nod at every plushie. She knows. She lets it slide. +%d Happiness" % int(gain))
	var formula: = int(inventory.get("formula", 0))
	var diapers: = int(inventory.get("diapers", 0))
	if formula > 0:
		inventory["formula"] = formula - 1
	else:
		happiness = maxf(0.0, happiness - 15.0)
		night_report.append("3 AM and no formula. {partner} has to make a gas station run. -15 Happiness")
	if diapers > 0:
		inventory["diapers"] = diapers - 1
	else:
		happiness = maxf(0.0, happiness - 10.0)
		night_report.append("Out of diapers. Dish towel diaper. -10 Happiness")
	night_report.append("3 AM shift on autopilot: bottle, diaper, rock, bed. I don't remember any of it.")
	_wake(0)

func _after_show_tell(_n: Node, score: float, _notes: Array) -> void:
	routine_played = true
	var gain: = roundf(3.0 + 9.0 * score)
	happiness = minf(100.0, happiness + gain)
	var pct: = int(round(score * 100.0))
	if score >= 0.8:
		night_report.append("Show & Tell: %d%%. She falls asleep mid-reel on my shoulder. I don't move for an hour. +%d Happiness" % [pct, int(gain)])
	elif score >= 0.5:
		night_report.append("Show & Tell: %d%%. \"You're cute when you pretend to care about plushies.\" +%d Happiness" % [pct, int(gain)])
	else:
		night_report.append("Show & Tell: %d%%. I doze off twice. She covers me up anyway. +%d Happiness" % [pct, int(gain)])
	_start_baby_shift()

func _start_baby_shift() -> void:
	var b: = BabyScript.new()
	b.ctx = {"formula": int(inventory.get("formula", 0)), "diapers": int(inventory.get("diapers", 0)) }
	_run_game(b, _after_baby)

func _after_baby(b: Node, score: float, notes: Array) -> void:
	inventory["formula"] = int(inventory.get("formula", 0)) - int(b.used_formula)
	inventory["diapers"] = int(inventory.get("diapers", 0)) - int(b.used_diapers)
	var penalty: = 0
	if b.no_formula:
		happiness = maxf(0.0, happiness - 15.0)
		night_report.append("3 AM and no formula. {partner} has to make a gas station run. -15 Happiness")
	if b.no_diaper:
		happiness = maxf(0.0, happiness - 10.0)
		night_report.append("Out of diapers. Dish towel diaper. -10 Happiness")
	if not b.success:
		happiness = maxf(0.0, happiness - 10.0)
		penalty += 15
		night_report.append("{baby} wakes {partner} up. -10 Happiness")
		_wake(penalty)
		return
	night_report.append("3 AM shift: handled. {baby}'s out. Now I just gotta hit the bed without one creak. Easy. (It's never easy.)")
	var s: = StealthScript.new()
	_run_game(s, func (_n: Node, sc: float, _notes: Array) -> void:
		if sc <= 0.0:
			night_report.append("CREAK. She's up. I sleep on the floor by the crib. My back and I are no longer speaking. -15 Energy tomorrow")
			_wake(penalty + 15)
		else:
			night_report.append("I make it to bed like a ninja. Full night's sleep. Write that down, it won't happen again.")
			_wake(penalty))

func _wake(energy_penalty: int) -> void:
	clear_enemies()
	spawn_t = 20.0
	day_i += 1
	day_count += 1
	clock = 420.0
	energy = clampf(100.0 - energy_penalty, 30.0, 100.0)
	var couch_lines: Array = []
	if couch_night:
		couch_night = false
		energy = minf(energy, Moods.COUCH_ENERGY)
		mood = Moods.new_mood().merged({"last_fussy": int(mood["last_fussy"]) }, true)
		couch_lines.append(Moods.COUCH_WAKE)
	location = "home"
	player.position = HOME_SPAWN
	_set_camera()
	var lines: Array = night_report.duplicate()
	var card: = str(Daily.entry(day_count).get("card", ""))
	lines.append("Day %d, %s. %s" % [day_count, DAY_NAMES[day_i % 7], card if card != "" else "Coffee. Then everything else."])
	calendar_pending = not no_loading
	show_loading()
	lines.append_array(daily_new_day())
	lines.append_array(couch_lines)
	lines.append_array(mood_new_day())
	lines.append_array(morning_new_day(not couch_lines.is_empty()))
	if couch_lines.is_empty() and str(morning["kind"]) == "":
		lines.append_array(kindness_new_day())
	if day_i % 7 == 0:
		lines.append_array(market_week())
		lines.append_array(pay_rent())
	jen_text_daily()
	var missed: = errand_new_day()
	if not missed.is_empty():
		lines = missed + lines
	lines.append(errand_brief())
	lines.append_array(curveball_new_day())
	lines.append_array(date_new_day())
	restless_seen = {}
	quest_wait = 0.0
	if porch_delivery():
		lines.append("{partner}: \"My package says delivered. Grab it off the porch before the porch pirates do?\"")
	if story_ready_unannounced() != "":
		lines.append("{partner}'s got something to tell me. (Talk to her.)")
	lines.append_array(calendar_day_lines())
	lines.append_array(gala_new_day())
	lines = lines.filter(func (l): return str(l) != "")
	if calendar_event() == "falcor" and str(daily["falcor"]) == "":
		falcor_scene(lines)
	elif morning_today() == "good" and str(morning["done"]) == "":
		good_morning_scene(lines)
	else:
		_say(lines)
	_sync_world()
	save_game()

const KINDNESS: = [
	["lunch", "{partner} packed my lunch. Note on the bag: \"Don't let them 86 you. Love, {partner}\" +15 Energy"],
	["coffee", "{partner} makes my coffee exactly how I like it. Doesn't even ask. +10 Energy"],
	["mirror", "I find a sticky note on the mirror: \"You're doing great, babe. The landlord is a goblin.\" I keep it in my wallet. Next to no money. +5 Energy"],
	["kiss", "{partner} kisses me on the way out. \"Go get 'em, chef.\" (Heat starts full today.)"],
	["proud", ""],
]
const PROUD_TEXTS: = [
	"proud of you. no follow-up question. just that",
	"thinking about you. also we need paper towels. mostly the first thing",
	"you're a good dad. i know you're tired. i see it",
	"don't work too hard babe. ok work a little hard. rent",
]
const LEVEL_CHEERS: = [
	"saw you bonk the hoa guy through the window. my hero lol",
	"babe. BABE. you leveled up?? dinner's on me (it's leftovers)",
	"proud of you. now come home in one piece",
	"{baby} watched you through the window and clapped. (she was hitting the glass. still counts)",
]

func kindness_new_day() -> Array:
	var chance: = 0.5 if happiness >= 40.0 else 0.25
	if randf() > chance:
		return []
	var pick: Array = KINDNESS.pick_random()
	match str(pick[0]):
		"lunch":
			energy = minf(energy_cap(), energy + 15.0)
		"coffee":
			energy = minf(energy_cap(), energy + 10.0)
		"mirror":
			energy = minf(energy_cap(), energy + 5.0)
		"kiss":
			combat.heat = combat.heat_max()
		"proud":
			text("madison", "madison", PROUD_TEXTS.pick_random())
			unread["madison"] = true
			return ["*bzzt* {partner} texts me something sweet. (P = phone)"]
	return [str(pick[1])]

func cheer_level_up() -> void:
	if randf() < 0.6:
		text("madison", "madison", LEVEL_CHEERS.pick_random())
		unread["madison"] = true

func weekly_base() -> int:

	return RENT + rent_bump + BILLS + Life.HOUSEHOLD + plan_due()

func plan_due() -> int:
	var t: = 0
	for pl in plans:
		t += int(pl["per"])
	return t

func _tick_plans() -> void:
	for pl in plans:
		pl["left"] = int(pl["left"]) - 1
	plans = plans.filter(func (pl): return int(pl["left"]) > 0)

## Week one is prorated (Nov 10, review fix): a new game starts Friday with $40, so a full $195 on the first
## Monday was a guaranteed late notice. The first Monday (story day <= 7, nothing paid yet) bills half.
func first_week_prorate() -> bool:
	return weeks_paid == 0 and late_notices == 0 and day_count <= 7

func pay_rent() -> Array:
	var base: = weekly_base()
	var prorated: = first_week_prorate()
	if prorated:
		base = int(ceil(base / 2.0))
	var due: = base + rent_debt
	var parts: = "rent $%d, bills $%d, family basics $%d%s" % [RENT + rent_bump, BILLS, Life.HOUSEHOLD, (", payment plans $%d" % plan_due()) if plan_due() > 0 else ""]
	_tick_plans()
	if money >= due:
		money -= due
		rent_debt = 0
		weeks_paid += 1
		if prorated:
			return ["Monday. Rent is due. Rent is always due.",
				"First week's prorated, since I moved in on a Friday. I pay $%d, half of the usual. $%d left. Next Monday it's the full $%d." % [due, money, weekly_base()]]
		return ["Monday. Rent is due. Rent is always due.",
			"I pay $%d (%s%s). $%d left. Landlord's third boat thanks me." % [due, parts, (", back rent $%d" % (due - base)) if due > base else "", money]]
	var partial: = maxi(0, money)
	money -= partial
	rent_debt = due - partial + LATE_FEE
	late_notices += 1
	happiness = maxf(0.0, happiness - 20.0)
	set_upset("rent")
	return [LATE_NOTICES[(late_notices - 1) % LATE_NOTICES.size()],
		"Can't cover $%d (%s). I pay what I've got ($%d). Late fee $%d, because being broke is expensive. Owe $%d next Monday. {partner}'s stressed. -20 Happiness" % [due, parts, partial, LATE_FEE, rent_debt]]

func rent_due() -> int:
	return (int(ceil(weekly_base() / 2.0)) if first_week_prorate() else weekly_base()) + rent_debt

func days_until_rent() -> int:
	var d: = (7 - day_i % 7) % 7
	return 7 if d == 0 else d

func phase() -> String:
	var c: = fmod(clock, 1440.0)
	if c >= 300.0 and c < 660.0: return "Morning"
	if c >= 660.0 and c < 1020.0: return "Shift"
	if c >= 1020.0 and c < 1320.0: return "Evening"
	return "Night"

func clock_text() -> String:
	var c: = int(fmod(clock, 1440.0))
	var h: = c / 60
	var mi: = c % 60
	var ap: = "AM" if h < 12 else "PM"
	var h12: = h % 12
	if h12 == 0: h12 = 12
	return "%d:%02d %s" % [h12, mi, ap]

func advance_clock(minutes: float) -> void:
	clock += minutes

func _talk_to_madison() -> void:
	if morning_talk():
		return
	var pre: Array = []
	var sl: = story_announce()
	if not sl.is_empty():
		_say(sl)
		return
	if quest_talk("madison"):
		return
	var giving: = errand_deliverable() or int(inventory.get("package", 0)) > 0 or (quest == 1 and has_all(QUEST_NEEDS[quest_kind]))
	var fussy_fine: = false
	if giving and mood_kind() == "fussy":
		var bnc: = bounce()
		if bnc != "":
			_say([bnc])
			return
		fussy_fine = true
	if errand_deliverable():
		var el: = errand_deliver()
		if fussy_fine:
			el.push_front(Moods.FUSSY_FINE)
		el.append_array(make_up())
		_say(el)
		return
	if int(inventory.get("package", 0)) > 0:
		var pl: = deliver_package()
		pl.append_array(make_up())
		_say(pl)
		return
	if date_ready():
		date_menu()
		return
	if mood_kind() == "upset":
		pre.append(str(Moods.UPSET.get(str(mood["cause"]), {}).get("line", "{partner}'s upset with me.")))
	elif mood_kind() == "fussy":
		pre.append(Moods.FUSSY_FINE if fussy_fine else "{partner}: \"I don't know what I want. Don't ask me what I want.\" (One of those days. Not your fault.)")
	if charisma() > 0 and cha_line_day != day_count:
		cha_line_day = day_count
		pre.append(CHA_LINES[day_count % CHA_LINES.size()])
	if fryer_smell and charisma() > 0:
		fryer_smell = false
		pre.append("{partner}: Fryer grease... and {cologne}? Somehow it works. (No penalty.)")
	elif fryer_smell:
		fryer_smell = false
		happiness = maxf(0.0, happiness - 5.0)
		pre.append("{partner}: Mmm. Fryer cologne. Shower, then cuddles. That's the deal. -5 Happiness")
		set_upset("fryer")
	if not leftovers.is_empty():
		for lo in leftovers:
			if lo == "cake slice":
				gain_happy(15.0)
				pre.append("{partner}: Black Forest cake from work?! Marry me. Again. Or for the first time. +15 Happiness")
			elif lo == "bakery honey buns":
				gain_happy(20.0)
				pre.append("{partner}: BAKERY honey buns?! The fancy ones! +20 Happiness")
				if quest == 1 and quest_kind == "honey buns":
					quest = 3
					pre.append("Honey bun run: complete. Ticket closed.")
		leftovers.clear()
		_say(pre)
		return
	if quest == 1:
		if has_all(QUEST_NEEDS[quest_kind]):
			pre.append_array(complete_quest())
			pre.append_array(make_up())
		else:
			pre.append(_mood_line())
			pre.append("Still need: %s" % ", ".join(missing(QUEST_NEEDS[quest_kind])))
	else:
		pre.append_array(start_quest(_next_quest_kind()))
	_say(pre)

func _mood_line() -> String:
	var asks: = {"honey buns": "honey buns", "formula": "formula for {baby}", "diapers": "diapers", "cake": "the cake stuff" }
	var thing: String = asks.get(quest_kind, "that thing")
	if happiness >= 70.0: return "{partner}: Still waiting on the %s, cutie." % thing
	if happiness >= 40.0: return "{partner}: Hey you. Don't forget the %s, okay? Love you." % thing
	return "{partner}: Hi, hello, I love you. Where's the %s, babe?" % thing

func _next_quest_kind() -> String:
	if last_quest_kind == "":
		return "honey buns"
	var pool: = ["formula", "formula", "diapers", "diapers", "honey buns", "cake", "cake"]
	pool.erase(last_quest_kind)
	pool.erase(last_quest_kind)
	return pool[randi() % pool.size()]

func start_quest(kind: String) -> Array:
	quest = 1
	quest_kind = kind
	quest_wait = 0.0
	match kind:
		"honey buns":
			return ["{partner}: Babe. BABE. I need honey buns. Not want. NEED.", "New quest: honey buns from Kwik-N-Go ($3)"]
		"formula":
			return ["{partner}: We're almost out of formula, hon. Grab some? I'll owe you a 3 AM shift.", "New quest: formula from Kwik-N-Go ($12)"]
		"diapers":
			return ["{partner}: Diapers. We're down to the ones with the cartoon that scares her.", "New quest: diapers from Kwik-N-Go ($10)"]
		"cake":
			return ["{partner}: You look like death. Bring me cherries, chocolate, cream, flour and eggs and I'll bake you a Black Forest cake.", "New quest: Black Forest cake ingredients (Kwik-N-Go, $13 total)"]
	return []

func complete_quest() -> Array:
	for k in QUEST_NEEDS[quest_kind]:
		inventory[k] = int(inventory.get(k, 0)) - int(QUEST_NEEDS[quest_kind][k])
	var lines: Array = []
	match quest_kind:
		"honey buns":
			gain_happy(30.0)
			lines = ["{partner}: HONEY BUNS! I'd fight a landlord for you. Don't tell {baby}.", "{cat3} watches from under the bed. Not impressed. At all.", "+30 Happiness"]
		"formula":
			inventory["formula"] = int(inventory.get("formula", 0)) + 1
			gain_happy(15.0)
			lines = ["{partner}: Formula! {baby}'s covered. Look at you, being a dad.", "(I stash it in the pantry for the 3 AM feeding.) +15 Happiness"]
		"diapers":
			inventory["diapers"] = int(inventory.get("diapers", 0)) + 1
			gain_happy(15.0)
			lines = ["{partner}: Diapers! The good ones! I could kiss you. Later. Wash your hands.", "+15 Happiness"]
		"cake":
			inventory["cake"] = int(inventory.get("cake", 0)) + 1
			gain_happy(10.0)
			lines = ["{partner} bakes a Black Forest cake. For ME. The whole house smells incredible.", "Got: Black Forest cake (eat it in the kitchen for +60 Energy). +10 Happiness"]
	last_quest_kind = quest_kind
	quest = 3
	player.carrying = int(inventory.get("honey buns", 0)) > 0
	return lines

func has_all(needs: Dictionary) -> bool:
	return missing(needs).is_empty()

func missing(needs: Dictionary) -> Array:
	var out: Array = []
	for k in needs:
		if int(inventory.get(k, 0)) < int(needs[k]):
			out.append(k)
	return out

func mood_word() -> String:
	if happiness >= 70.0: return "Happy"
	elif happiness >= 40.0: return "Meh"
	return "Pissed"

func wait_drain() -> float:
	return WAIT_DRAIN_WEEK1 if day_count <= 7 else WAIT_DRAIN

func quest_text() -> String:
	if date_ready():
		return "DATE NIGHT: talk to {partner} (sitter first)"
	var et: = errand_quest_text()
	if et != "":
		return et
	var dq: = date_quest_text()
	if dq != "":
		return dq
	if quest == 1:
		var m: = missing(QUEST_NEEDS[quest_kind])
		if m.is_empty():
			return "Bring the %s to {partner}" % ("cake stuff" if quest_kind == "cake" else quest_kind)
		return "Get: " + ", ".join(m)
	var sq: = story_quest_text()
	if sq != "" and quest != 1:
		return sq
	if quest == 3:
		return "{partner} is happy (for now)"
	return "Talk to {partner} (inside)"

func _pass_out() -> void:
	location = "home"
	player.position = HOME_SPAWN
	_set_camera()
	_sync_world()
	energy = 40.0
	happiness = maxf(0.0, happiness - 10.0)
	advance_clock(120.0)
	_say(["Passed out on the sidewalk. Classy.", "{partner} has to drag me home. -10 Happiness. Note to self: eat something, dumbass."])

func _say(lines: Array) -> void:
	for l in lines:
		dialog.append(Cast.N(str(l)))

func _toast(s: String) -> void:
	toast = Cast.N(s)
	toast_t = 2.5

func music_track() -> String:

	if in_title:
		return "home"
	if in_shift:
		return "kitchen"
	if overlay_node != null and str(overlay_node.get("music")) != "":
		return str(overlay_node.get("music"))
	match location:
		"gala": return "gala"
		"arena": return "willnot" if arena_id == "willnot" else ("kitchen" if arena_mode == "waffle" else "boss")
		"home": return "home"
	return "neighborhood"

func open_settings() -> void:
	var was_title: = in_title
	var g: = SettingsScript.new()
	g.audio = audio
	g.dev = dev_tools_on() and not was_title
	_run_game(g, func (n: Node, _s: float, _x: Array) -> void:
		if str(n.get("action")) == "credits":
			open_credits(was_title)
		elif was_title:
			show_title()
		elif str(n.get("action")) == "dev_quests":
			dev_quest_menu())

## Settings > "Credits & legal" (credits.gd): Back returns to Settings (and from there to the title, if
## that's where Settings was opened).
func open_credits(from_title: bool = false) -> void:
	_run_game(CreditsScript.new(), func (_n: Node, _s: float, _x: Array) -> void:
		in_title = from_title
		open_settings())

## Dev tools exist only in debug builds (running from the Godot editor, phone or desktop). Export
## builds (itch, the dev APK release preset) never show them.
func dev_tools_on() -> bool:
	return OS.is_debug_build()

## Dev: pick a side quest, then a stage; the quest jumps there and Duff warps to whoever the stage needs.
func dev_quest_menu() -> void:
	var opts: Array = []
	var keys: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]
	var i: = 0
	for e in SideQuests.LIST:
		var id: = str(e["id"])
		var stv: = SideQuests.status(side_quests, id)
		opts.append([id, "%s %s %d/%d" % [str(e["title"]).substr(0, 18), {"": "-", "active": ">", "done": "OK"}[stv], SideQuests.stage(side_quests, id), SideQuests.stage_count(id)], keys[i]])
		i += 1
	opts.append(["hidden", "Hidden quests: %s" % ("SHOWN" if show_hidden_quests else "hidden"), KEY_H])
	opts.append(["leave", "Close", KEY_ESCAPE])
	_menu("DEV: SIDE QUESTS", ["Jump any side quest to any stage and test every branch."], opts, func (id: String) -> void:
		if id == "hidden":
			show_hidden_quests = not show_hidden_quests
			dev_quest_menu()
		elif id != "leave":
			_dev_quest_stage_menu(id))

func _dev_quest_stage_menu(id: String) -> void:
	var e: = SideQuests.entry(id)
	var opts: Array = [["0", "Reset (not started)", KEY_0]]
	var st: Array = e["stages"]
	for i in st.size():
		opts.append([str(i + 1), "%d: %s" % [i + 1, str(st[i]["text"]).substr(0, 24)], [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6][mini(i, 5)]])
	opts.append([str(st.size() + 1), "Done", KEY_D])
	for ch in e.get("choices", []):
		opts.append(["c_" + str(ch), "Done, chose '%s'" % str(ch), KEY_NONE])
	opts.append(["leave", "Back", KEY_ESCAPE])
	_menu("DEV: " + str(e["title"]), [str(e["pitch"])], opts, func (pick: String) -> void:
		if pick == "leave":
			dev_quest_menu()
		elif pick.begins_with("c_"):
			SideQuests.finish(side_quests, id, pick.substr(2))
			_toast("DEV: %s done, choice %s" % [id, pick.substr(2)])
		else:
			dev_warp_quest(id, int(pick)))

func dev_warp_quest(id: String, to_stage: int) -> void:
	if SideQuests.entry(id).is_empty():
		_toast("DEV: no side quest '%s'" % id)
		return
	show_hidden_quests = true
	SideQuests.warp(side_quests, id, to_stage)
	var who: = str(SideQuests.entry(id).get("giver", ""))
	if SideQuests.is_active(side_quests, id):
		var at: = str((SideQuests.entry(id)["stages"] as Array)[SideQuests.stage(side_quests, id) - 1].get("at", ""))
		if at != "":
			who = at
	var spot = quest_spots().get(who)
	if spot != null:
		if str(spot[0]) == "home" and location != "home":
			enter_home()
		elif str(spot[0]) == "outside" and location == "home":
			leave_home()
		if str(spot[0]) == location:
			player.position = (spot[1] as Vector2) + Vector2(0, 40)
	_toast("DEV: %s -> %s %d/%d" % [id, SideQuests.status(side_quests, id) if SideQuests.status(side_quests, id) != "" else "reset", SideQuests.stage(side_quests, id), SideQuests.stage_count(id)])

## Sprite scale on painted fight floors (arenas, gala); bosses already draw at 1.45 (boss.gd).
const STAGE_SCALE: = 1.45

## Painted boss floor (story/bounty/bet arenas, gala). Not the Waffle Haus shift: its NPCs stay 1x.
func on_fight_floor() -> bool:
	return location == "gala" or (location == "arena" and arena_mode != "waffle")

func _process(delta: float) -> void:
	t += delta
	if player != null:
		player.at_home = location == "home"
		player.shades = shades
		player.stage_scale = STAGE_SCALE if on_fight_floor() else 1.0
	if audio != null:
		AudioScript.music(music_track())
	toast_t = maxf(0.0, toast_t - delta)
	ping_t = maxf(0.0, ping_t - delta)
	sigh_t = maxf(0.0, sigh_t - delta)
	save_flash_t = maxf(0.0, save_flash_t - delta)
	_tick_dialog(delta)
	_update_world_cover()
	if location != _drawn_loc:
		queue_redraw()
	if busy():
		return
	player.frozen = not dialog.is_empty()
	if dialog.is_empty() and not location in ["gala", "arena"]:
		clock += MIN_PER_SEC * delta
		autosave_t -= delta
		if autosave_t <= 0.0:
			save_game()
		_update_inspector(delta)
		if quest == 1 and happiness > WAIT_FLOOR:   # waiting on a want: slow leak, never past the floor
			happiness = maxf(WAIT_FLOOR, happiness - wait_drain() * delta)
		if errand_overdue():
			errand_miss(false)
		if (buff_active("speed") or drained()) != _speed_on:
			apply_gear()
		if quest == 1:
			quest_wait += MIN_PER_SEC * delta
			if quest_wait >= Moods.QUEST_WARN[2] and mood_kind() != "upset" and str(mood.get("cause", "")) != "promise":
				set_upset("promise")
		if drained() and energy > Life.DRAIN_MAX:
			energy = Life.DRAIN_MAX
		fussy_swap()
		morning_tick()
		restless_t -= delta
		if restless_t <= 0.0:
			restless_t = 1.0
			restless_notify()
		if happiness <= 0.0:
			happiness = 30.0
			_say(["{partner}'s really hurt. I'm on the couch tonight. She still tosses me the good blanket.", "Mood reset to 30. Make it right, chef."])
		if energy <= 0.0 and not location in ["gala", "arena"]:
			_pass_out()
		if clock >= 1560.0:
			go_to_sleep(true)
			return
		if location == "home":
			knock_t -= delta
			if knock_t <= 0.0:
				knock_t = randf_range(30.0, 50.0)
				_toast(KNOCK_LINES[randi() % KNOCK_LINES.size()])
	if location == "gala" and dialog.is_empty() and energy <= 0.0:
		gala_lose()
	if location == "arena":
		_arena_process(delta)
	_auto_doors()
	var it: = nearest_interactable()
	hint = (("A: " if Cast.touch else "E / A: ") + str(it["label"])) if not it.is_empty() else ""
	if location == "gala":
		hint = ""
	if location == "outside" and phase() == "Night" and hint == "":
		hint = "It's late. Go home to bed."
	if location == "outside":
		var p: = player.global_position
		if ensure_respawn <= 0.0 and p.distance_to(ENSURE_POS) < 10.0:
			energy = minf(energy_cap(), energy + energy_gain(40.0))
			ensure_respawn = 30.0
			_toast("There's an Ensure on the bench. I don't ask questions. I chug it. +40 Energy")
		ensure_respawn = maxf(0.0, ensure_respawn - delta)
		_director(delta)
		if porch_pkg and p.distance_to(PORCH_PT) < 12.0:
			porch_pkg = false
			inventory["package"] = int(inventory.get("package", 0)) + 1
			_toast("I grab {partner}'s package before the pirates do. Not today, assholes.")
	queue_redraw()

func try_shift() -> void:
	var c: = fmod(clock, 1440.0)
	if c >= 1320.0 or c < 360.0:
		_say(["{fork_nick}'s closed. Even Grill-Boy went home, and he lives in the walk-in. (Open 6 AM - 10 PM)"])
		return
	if calendar_event() == "thanksgiving":
		_say(["The {fork_nick}'s closed for Thanksgiving. First time in history. Chef's 'with family,' which means golf."])
		return
	if Daily.is_weekend(day_i % 7) and not first_weekend():
		_say(["It's the weekend. The schedule says I'm off. The {fork_nick} can lose money without me for once."])
		return
	start_shift()

## The first weekend the Fork is short-staffed and takes Duff (Nov 10, review fix): two extra shifts before the
## first Monday, so a new player can actually make rent.
func first_weekend() -> bool:
	return day_count <= 3

func start_shift() -> void:
	if in_shift or _world_gate(start_shift):
		return
	show_loading()
	in_shift = true
	player.shoes = "black"
	inspector_follow = false
	player.frozen = true
	touch.set_process_input(false)
	touch.visible = false
	hud.visible = false
	_sync_world()
	shift_layer = ui_layer()
	shift_layer.layer = 10
	add_child(shift_layer)
	shift = ShiftScript.new()
	shift.m = self
	shift.day_name = DAY_NAMES[day_i % 7]
	shift.modes = Daily.shift_modes(today_event())
	if Daily.inspector(today_event()):
		shift.force["inspector"] = true
	shift.shift_over.connect(end_shift)
	shift_layer.add_child(shift)
	shift.start()

func end_shift(r: Dictionary) -> void:
	if shift_layer:
		shift_layer.queue_free()
	shift_layer = null
	shift = null
	in_shift = false
	player.shoes = "red"
	close_overlay()
	if r.get("left", false):
		return
	apply_shift_result(r)
	save_game()

## Muscle memory: remember the best grade per station (autopilot runs don't count).
func record_station_bests(res: Array) -> void:
	for x in res:
		if typeof(x) != TYPE_DICTIONARY or str(x.get("kind", "")) != "station" or bool(x.get("autopilot", false)):
			continue
		var k: = str(x["key"])
		if ShiftScript.grade_rank(str(x["grade"])) > ShiftScript.grade_rank(str(station_best.get(k, "F"))) or not station_best.has(k):
			station_best[k] = str(x["grade"])

func apply_shift_result(r: Dictionary) -> void:
	AudioScript.sfx("cash")
	var dmul: = Daily.shift_pay(today_event())
	if dmul != 1.0:
		r["total"] = int(round(int(r["total"]) * dmul))
	money += int(r["total"])
	var cha_tips: = charisma_tips(int(r.get("tips", 0)))
	money += cha_tips
	energy = clampf(energy - int(r["energy_cost"]) - int(r["injuries"]) + int(r["meal"]), 0.0, 100.0)
	energy = maxf(energy, 1.0)
	record_station_bests(r.get("results", []))
	advance_clock({"full": 360.0, "quick": 180.0, "rush": 240.0 }.get(str(r.get("mode", "full")), 300.0))
	for lo in r["leftovers"]:
		leftovers.append(lo)
	fryer_smell = true
	var old_title: = pay_title()
	shifts_worked += 1
	if pay_title() != old_title:
		_say(["PROMOTED! I'm %s at the {fork_nick} now. Pay x%.1f. HR calls it 'a growth journey.' I call it a raise." % [pay_title(), pay_mult()], "Rent hasn't gone up. Yet. Landlords smell a raise the way sharks smell blood. I gotta invest it fast."])
	if r["achievement"] != "" and not achievements.has(r["achievement"]):
		achievements.append(r["achievement"])
	if r["inspector"] == "fail":
		inspector_follow = true
		inspector_t = 180.0
		inspector_quip_t = 6.0
		inspector_pos = player.position + Vector2(-14, 6)
	var msg: = "Shift grade %s. +$%d. It's %s and I clock out. My feet are toast." % [r["grade"], r["total"], clock_text()]
	if cha_tips > 0:
		msg += " (+$%d tips: I smell like {cologne})" % cha_tips
	if r["achievement"] != "":
		msg += " ACHIEVEMENT: Chef's Kiss!"
	_toast(msg)

func _update_inspector(delta: float) -> void:
	if not inspector_follow:
		return
	inspector_t -= delta
	inspector_pos = inspector_pos.lerp(player.position + Vector2(-14, 6), clampf(delta * 3.0, 0, 1))
	inspector_quip_t -= delta
	if inspector_quip_t <= 0.0:
		inspector_quip_t = 20.0
		_toast(INSPECTOR_QUIPS[randi() % INSPECTOR_QUIPS.size()])
	if inspector_t <= 0.0:
		inspector_follow = false
		_toast("The inspector finally goes home. To inspect his feelings, probably.")

func _check_debug_hash() -> bool:

	if not OS.has_feature("web"):
		return false
	var h: = str(JavaScriptBridge.eval("window.location.hash"))
	if not h.begins_with("#dq="):
		return false
	_after_world(func () -> void:
		new_game(false)
		debug_station.call_deferred(h.substr(4)))
	return true

func debug_station(k: String) -> void:
	dialog.clear()
	if k.begins_with("quest:"):   # #dq=quest:<id>:<stage>  (stage 0 = reset, past the end = done)
		var parts: = k.split(":")
		dev_warp_quest(parts[1] if parts.size() > 1 else "", int(parts[2]) if parts.size() > 2 else 1)
		return
	match k:
		"home":
			enter_home()
			return
		"shop":
			open_shop()
			return
		"baby":
			go_to_sleep(false)
			return
		"stealth":
			_run_game(StealthScript.new(), func (_n: Node, _s: float, _x: Array) -> void: pass)
			return
		"wordle":
			start_wordle(false)
			return
		"gear":
			gear["scraps"] = 40
			Gear.grant_piece(gear)
			Gear.grant_piece(gear)
			apply_gear()
			open_gear()
			return
		"enemies":
			day_count = 4
			player.position = Vector2(330, 130)
			var offs: = [Vector2(-70, -40), Vector2(80, -30), Vector2(-60, 50), Vector2(70, 45)]
			var kinds: = ["scammer", "karen", "hoa", "hustler"]
			for i in 4:
				spawn_enemy(kinds[i], player.position + offs[i])
			spawn_driver()
			return
		"pete":
			player.position = Vector2(400, 250)
			spawn_enemy("pete", Vector2(460, 250))
			return
		"mash":
			_run_game(MashScript.new(), func (_n: Node, _s: float, _x: Array) -> void: pass)
			return
		"deal":
			var e: = spawn_enemy("scammer", player.position + Vector2(10, 0))
			scammer_deal(e)
			return
		"phone":
			open_phone()
			return
		"settings":
			open_settings()
			return
		"iso_test":

			var iso: Node = IsoTest.new()
			iso.set("m", self)
			open_overlay(iso)
			return
		"say_madison", "say_madison_upset", "say_octavia":
			if k == "say_madison_upset":
				mood["kind"] = "upset"
				mood["cause"] = "promise"
				mood["day"] = day_count
				happiness = 30.0
			else:
				happiness = 85.0
			_say([{"say_madison": "{partner}: You remembered?! Come here. Honey bun first, then you. <3",
				"say_madison_upset": "{partner}: You said six. It's nine. ...Your plate's in the microwave. I'm still mad. Eat.",
				"say_octavia": "{baby} grabs my beard and giggles. Fine. She can have it." }[k]])
			return
		"say_smirk", "say_tired", "say_happy", "say_shades", "say_clean", "say_home":

			if k == "say_home":
				enter_home()
			shades = k == "say_shades"
			Cast.clean = k == "say_clean"
			_say([{"say_smirk": "{fork_nick}'s 86'd on honey buns again. I'll handle it.",
				"say_tired": "Landlord raised rent. Insurance denied the claim. Bus is late. Damn.",
				"say_happy": "PROMOTED! Lead Line Cook! Love you, Madison!",
				"say_shades": "Round shades on. Cosmetic only. Still the coolest line cook in Omaha.",
				"say_clean": "Well, shit. Not today, assholes. Hell no.",
				"say_home": "White tank, home sweet home. {baby} gurgles at me. That's the whole reason." }[k]])
			return
		"ending":
			start_ending()
			return
		"pharmacy", "pharmacy_wait", "pharmacy_insurance", "pharmacy_ready":
			debug_errand("pharmacy")
			clock = 600.0
			var oc: String = {"pharmacy": "", "pharmacy_wait": "not_ready", "pharmacy_insurance": "insurance", "pharmacy_ready": "ready" }[k]
			open_pharmacy({"outcome": oc, "start": "counter" } if oc != "" else {"ahead": 9 })
			return
		"grocery", "grocery_checkout", "grocery_bagging":
			debug_errand("grocery")
			clock = 600.0
			open_grocery({"start": k.substr(8), "price_check": true } if k != "grocery" else {})
			return
		"symphony", "akarui", "symphony_concert", "akarui_bill":
			var dk: = "symphony" if k.begins_with("symphony") else "akarui"
			day_count = maxi(day_count, 5)
			money = 300
			happiness = 70.0
			enter_home()
			dialog.clear()
			clock = 1080.0
			invite_date(dk)
			var ex: = {}
			if k == "symphony_concert":
				ex = {"start": "concert" }
			elif k == "akarui_bill":
				ex = {"start": "bill" }
			start_date(dk, "jen", ex)
			return
		"plasma":
			clock = 600.0
			location = "outside"
			player.position = PLASMA_DOOR + Vector2(0, 6)
			_set_camera()
			open_plasma()
			return
		"drained":
			clock = 700.0
			plasma["drained_day"] = day_count
			apply_gear()
			player.position = PLASMA_DOOR + Vector2(0, 10)
			_set_camera()
			return
		"fussy", "upset", "restless":
			enter_home()
			dialog.clear()
			clock = 800.0
			if k == "fussy":
				start_fussy()
			elif k == "upset":
				set_upset("errand")
			else:
				quest = 1
				quest_kind = "honey buns"
				quest_wait = 370.0
			player.position = MADISON_POS + Vector2(24, 0)
			return
		"mail", "bills":
			enter_home()
			dialog.clear()
			clock = 900.0
			deliver_curveball("medical")
			deliver_curveball("sneakers")
			player.position = MAIL_PT
			if k == "mail":
				mail_menu()
			return
		"buffs", "backwalk", "blackheads":
			enter_home()
			dialog.clear()
			clock = 1080.0
			happiness = 70.0
			inventory["cologne"] = 3
			if k == "buffs":
				for bk in Buffs.ORDER:
					grant_buff(bk, 300.0 if bk != "charisma" else Buffs.CHARISMA_MINS)
				dialog.clear()
				toast_t = 0.0
				player.position = MAT_PT + Vector2(0, 10)
			elif k == "backwalk":
				start_backwalk()
			else:
				start_blackheads()
			return
		"stores":
			clock = 600.0
			player.position = Vector2(300, 326)
			_set_camera()
			return
		"errand_text":
			open_phone("thread_madison")
			return
		"stonks", "fund":
			money = 600
			for i in 6:
				Market.tick(market)
			open_phone(k)
			return
		"thread":
			open_phone("thread_sister")
			return
		"rich":
			college["cash"] = Market.GOAL + 5.0
			check_fund_goal()
			open_phone("fund")
			return
		"gala":
			gala_unlocked = true
			start_gala()
			dialog.clear()
			return
		"savetest":
			money = 777
			day_count = 3
			inventory["cake"] = 1
			enter_home()
			_toast("savetest: wrote $777, day 3")
			return
	if k.begins_with("story_") and story_index(k.substr(6)) >= 0:
		var si: = story_index(k.substr(6))
		for j in si:
			(story["beaten"] as Array).append(STORY[j]["id"])
		(story["announced"] as Array).append(STORY[si]["id"])
		day_count = int(STORY[si]["day"])
		happiness = 90.0
		start_story_fight(k.substr(6))
		dialog.clear()
		return
	if k == "boss_schnitzel":
		k = "boss_baron"
	if k.begins_with("boss_") and BOSS_ORDER.has(k.substr(5)):
		gala_unlocked = true
		start_gala(BOSS_ORDER.find(k.substr(5)))
		dialog.clear()
		return
	start_shift()
	if k == "menu":
		return
	if k == "rush" or k == "quick" or k == "full":
		shift.begin(k)
		return
	shift.mode = "full"
	if k == "report":
		for key in ["quiz", "prep", "pickles", "fryer", "temp", "sandwich", "salad", "garnish"]:
			shift.results.append({"key": key, "name": shift.NAMES[key], "score": 0.95, "grade": "S", "notes": [], "bonus": 0, "kind": "station" })
		shift.bonus_total = 0
		shift._finish_shift()
		return
	# Straight into the station (debug/QA): skip the NEXT STATION card M10's shuffle put in front of it.
	shift._play({"key": k, "ctx": {"eighty_six": true, "steal": true } if k in ["sandwich", "salad"] else {} })

## Only the place Duff is in gets drawn: town, home, gala and arena never share the screen (each
## has its own camera limits), and one canvas item holding all four cost ~150 draw calls a frame
## on phones. _process() redraws on a location change even while busy (perf, Nov 9).
func _draw() -> void:
	_drawn_loc = location
	match location:
		"home":
			_draw_inside()
		"gala":
			_draw_gala()
		"arena":
			_draw_arena()
		_:
			_draw_outside()

## An opaque full-screen menu/minigame (every minigame.gd overlay paints its whole 320x180 first)
## hides the world: stop drawing it and its screen shader until the overlay closes. Looks identical.
func _update_world_cover() -> void:
	var cover: = overlay_node != null and is_instance_valid(overlay_node) and overlay_node.has_method("_draw_backdrop")
	if visible == cover:
		visible = not cover
		var hd: = get_node_or_null("HD2DPresentation")
		if hd:
			hd.set_world_shown(not cover)

func _draw_outside() -> void:
	var f: = ThemeDB.fallback_font

	# ground is built from Grok's tiles (data/town_ground.txt); map_objects now only holds the old
	# bus-stop sign (trees/props replaced by street dressing, tools/import_dressing.py)
	var gt: = Ground.texture()
	draw_texture_rect(gt, Rect2(Ground.origin() / 2.0, gt.get_size() / 2.0), false)
	Art.image(self, "map_objects", Vector2.ZERO)
	# storefronts (Grok, Nov 8): one sprite per footprint, drawn at the rect; shut places get dimmed
	# street dressing (Grok, Nov 8) is y-sorted WITH the actors by scripts/dressing_front.gd (Nov 9);
	# only items tucked behind a storefront are drawn here, sorted with the storefronts
	var layer: Array = []
	for b in buildings:
		layer.append([(b["r"] as Rect2).end.y, b])
	for it in dressing:
		if it.get("behind_building", false):
			layer.append([it["p"].y, it])
	layer.sort_custom(func(x, y): return x[0] < y[0])
	for e in layer:
		var b: Dictionary = e[1]
		if not b.has("r"):
			Dressing.draw_item(self, b)
			continue
		var r: Rect2 = b["r"]
		var shut: bool = (b.has("story") and not story_beaten(str(b["story"])) and not story_available(str(b["story"]))) or (b.has("errand") and not Errands.is_open(str(b["errand"]), clock))
		Art.image(self, str(b.get("art", "")), r.position, Color(0.72, 0.72, 0.78) if shut else Color.WHITE)

	_draw_porch_and_cans()
	_draw_waffle_sign_and_board(f)
	if ensure_respawn <= 0.0:
		Art.image(self, "ensure", ENSURE_POS + Vector2(0, 4))

	# dusk/night darkening now lives in hd_presentation.gd (clock-driven grade + door lights)
	# the inspector and Brittany are drawn outdoors by y-sorted proxies (dressing_front.gd)

func _draw_inspector() -> void:
	draw_inspector_at(self, Vector2.ZERO)

## ofs: world -> the canvas item's local space (proxies pass -their position)
func draw_inspector_at(ci: CanvasItem, ofs: Vector2) -> void:
	var to: = player.global_position - inspector_pos if player else Vector2.DOWN
	Art.person(ci, "ch_inspector", inspector_pos + Vector2(0, 6) + ofs, to, t, to.length() > 26.0)

func draw_brittany(ci: CanvasItem, ofs: Vector2) -> void:
	Art.person(ci, "ch_brittany", BRITT_POS + Vector2(0, 6) + ofs, player.position - BRITT_POS, t, false, int(t * 0.7) % 4 == 0)
	if int(bet["day"]) != day_count:
		ci.draw_string(ThemeDB.fallback_font, BRITT_POS + ofs + Vector2(-3, -24 + sin(t * 3.0) * 1.5), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#60e060"))

func _draw_inside() -> void:
	var f: = ThemeDB.fallback_font
	var o: = INT_ORIGIN

	Art.image(self, "home_interior", o)
	_draw_mat_and_mirror()

	var bs: = 0 if phase() == "Night" else (3 if happiness >= 70.0 else 1)
	Art.frame(self, "baby", CRIB_R.get_center(), bs, 0)

	if cats_fed_day == day_count:
		draw_rect(Rect2(BOWLS_R.position + Vector2(1, 2), Vector2(4, 2)), Color("#8a5a2a"))
		draw_rect(Rect2(BOWLS_R.position + Vector2(12, 2), Vector2(4, 2)), Color("#8a5a2a"))

	Art.image(self, "freya_peek", Vector2(68, 517))

	var mp: = BED_HEAD if madison_in_bed() else madison_spot()
	if madison_in_bed():
		_draw_madison_in_bed()
	else:
		var look: = (player.global_position - mp) if player and location == "home" else Vector2.DOWN
		Art.person(self, "ch_madison", mp + Vector2(0, 11), look if look.length() < 120.0 else Vector2.DOWN)
	if (quest != 1 or has_all(QUEST_NEEDS.get(quest_kind, {}))) and not morning_hard_pending():
		var bob: = sin(t * 4.0) * 1.5
		draw_string(f, mp + Vector2(-2, -14 + bob), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#ffe08a"))
	if (sigh_t > 0.0 or restless_level >= 2) and hint == "":
		draw_rect(Rect2(mp + Vector2(6, -24), Vector2(30, 10)), Color(1, 1, 1, 0.9))
		draw_string(f, mp + Vector2(8, -16), "*sigh*", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#333333"))
	elif mood_kind() == "fussy":
		draw_string(f, mp + Vector2(6, -14), "~", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#d0b0ff"))
	if phase() == "Night":
		draw_rect(Rect2(o, INT_SIZE), Color(0.05, 0.05, 0.2, 0.3))
	elif madison_in_bed() and str(morning["kind"]) == "migraine":
		draw_rect(Rect2(o, INT_SIZE), Color(0.03, 0.03, 0.1, 0.58))   # blinds down
	if inspector_follow and location == "home":
		_draw_inspector()

const HIT_LINES: = {
	"complaint": "A complaint hits me square in the face. It's about my shoes. They're red, Karen.",
	"citation": "", "driver": "Clipped by a lifted pickup. Truck nuts and no turn signal. Of course.",
	"flipflop": "THWACK. A flip-flop to the face. It's still warm.",
	"firework": "Sparkler'd. Very festive. Very ouch.",
	"pete": "Pete body-slams me. Smells like sunscreen he didn't use and a boat he didn't pay off.",
	"karen": "Karen jabs me with her phone. She's going live.", "hoa": "Bonked with bylaw 4.2.c: 'No joy.'",
	"post": "Hit by a hot take. 400k likes, zero facts.", "rocket": "A sponsored e-scooter lands on me. Use code TYLER for 10% off my spine.",
	"drone": "Tip drone to the face. It asks how my experience was.", "laser": "Blinded by a tip screen. Suggested: 30%.", "bsod": "", "update": "",
	"butler": "A butler pummels me. He's paid $9 an hour to do it. Honestly? Same.", "coin": "Pelted with gold coins. First money's trickled down in years.",
	"tariff": "Cost-cut. Right in the ribs. They're 'lean' now.", "tariff_bit": "Shrapnel from a restructuring.", "wall": "Bonked by a wall of NDAs. Can't say how much it hurt.",
	"boss": "Body-checked by a boss. Classic. They never touch anything they can't buy.",
	"seen": "Left on read. Stings worse than a fryer burn.", "dumbbell": "Dumbbell to the dome. Bro.", "charge": "Bro-charged! He didn't even warm up.",
	"bass": "", "vape": "Mango ice cloud. Hacking up a lung. Sponsored content.", "rug": "RUG PULLED! I hit the floor. My portfolio's right there with me.",
	"bullet": "Bullet spray! Mostly noise, but OW. Damn.", "nft": "Bitten by an NFT. It's worth less than the bite.",
}

func apply_gear() -> void:
	var asp: = Gear.a_special(gear)
	player.weapon_id = str(gear["weapon"])
	player.armor_id = str(gear["armor"])
	player.swing_cd = 0.16 if Gear.w_special(gear) in ["quick", "golden"] else 0.25
	player.speed_mult = {"fast": 1.15, "goalie": 0.9, "trust": 1.1 }.get(asp, 1.0)
	_speed_on = buff_active("speed") or drained()
	if buff_active("speed"):
		player.speed_mult *= Buffs.SPEED_MULT
	if drained():
		player.speed_mult *= Life.DRAIN_SPEED
	player.roll_cd_len = (0.45 if asp in ["fast", "trust"] else 0.7) * combat.roll_mult()
	player.speed_mult *= combat.speed_mult()
	player.speed_mult *= Daily.walk(today_event())
	player.combo_len = 4 if Gear.w_special(gear) in ["quick", "golden"] else 3
	player.iframe_len = 1.2 if asp in ["goalie", "trust"] else 0.8

## Difficulty pass Nov 13 (Duff: "combat is pretty easy"): every hit on Duff lands 25% harder.
const DMG_TAKEN: = 1.25

func hurt_player(amount: float, from: Vector2, kb: float, kind: String) -> bool:

	if busy() or combat.cinematic:
		return false
	if combat.countering():
		combat.counter_success(from, kind)
		return false
	if player.invulnerable() or (player.frozen and combat.feast_t <= 0.0):
		return false
	var dmg: float = amount * DMG_TAKEN * (1.0 - Gear.reduction(gear)) * combat.taken_mult()
	if buff_active("defense"):
		dmg *= Buffs.DEF_MULT
	if glow_active():
		dmg *= Dates.GLOW_DEF
	if drained():
		dmg *= Life.DRAIN_TAKEN
	if kind in PROJ_KINDS and Gear.a_special(gear) == "heatproof":
		dmg *= 0.5
	energy = maxf(0.0, energy - dmg)   # never below 0 (HUD + lose checks use <= 0)
	if arena_mode == "bet":
		bet_hurt += 1
	player.hurt()
	if juice:
		juice.hurt()
	if not Gear.a_special(gear) in ["goalie", "trust"]:
		player.take_knock(from, kb)
	var l: String = HIT_LINES.get(kind, "")
	if l != "":
		_toast("%s -%d Energy" % [l, int(round(dmg))])
	return true

func citation(cost: int) -> void:
	if Gear.a_special(gear) == "pro":
		cost = int(ceil(cost / 2.0))
	var paid: = mini(money, cost)
	money -= paid
	_toast("HOA CITATION: 'Visible joy, unapproved shade of red.' -$%d" % paid)

func open_gear() -> void:
	if busy() or not dialog.is_empty():
		return
	var gs: = GearScreen.new()
	gs.m = self
	_run_game(gs, func (_n: Node, _s: float, _x: Array) -> void:
		apply_gear()
		save_game())

func clear_enemies() -> void:
	for n in get_tree().get_nodes_in_group("hostile"):
		for g in ["hostile", "enemy", "projectile"]:
			if n.is_in_group(g):
				n.remove_from_group(g)
		n.queue_free()

func live_enemies() -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			out.append(e)
	return out

func pete_alive() -> bool:
	for e in live_enemies():
		if e.kind == "pete":
			return true
	return false

func spawn_enemy(kind: String, pos: Vector2, opts: Dictionary = {}) -> Node:
	var e: = EnemyScript.new()
	e.kind = kind
	e.m = self
	e.position = pos
	e.buddy = bool(opts.get("buddy", false))
	if opts.has("lane"):
		e.lane = opts["lane"]
	add_child(e)
	e.set_physics_process(location in ["outside", "gala", "arena"] and not busy())
	return e

func spawn_driver() -> Node:

	var p: = player.position
	var lanes: Array = []
	if absf(p.y - 175.0) < 45.0:
		lanes.append("h")
	if absf(p.x - 315.0) < 45.0:
		lanes.append("v")
	if lanes.is_empty():
		return null
	var axis: String = lanes[randi() % lanes.size()]
	var dir: = 1 if randf() < 0.5 else -1
	var pos: = Vector2(-30.0 if dir > 0 else 670.0, 175.0) if axis == "h" else Vector2(315.0, -30.0 if dir > 0 else 390.0)
	return spawn_enemy("driver", pos, {"lane": {"axis": axis, "dir": dir } })

func spawn_cap() -> int:
	return mini(6, 1 + day_count / 2) + (3 if phase() == "Night" else 0)   # night +3 (was +2, Nov 13)

func spawn_interval() -> float:
	var base: = maxf(10.0, 28.0 - 2.0 * day_count) / Daily.spawn(today_event())
	match phase():
		"Night": return base * 0.6
		"Evening": return base * 0.8
	return base

func spawn_pool() -> Array:
	var pool: Array = ["scammer", "scammer", "hustler", "hustler"]
	if day_count >= 2:
		pool.append_array(["karen", "karen", "driver"])
	if day_count >= 3:
		pool.append_array(["hoa", "hoa"])
	if phase() == "Night":
		pool.append_array(["driver", "scammer", "karen"])
	if pirate_allowed():
		pool.append_array(["pirate", "pirate", "pirate"])
	return pool

func pete_allowed() -> bool:

	return day_count >= PETE_FIRST_DAY and pete_last_spawn_day != day_count and day_count >= pete_defeated_day + PETE_REST_DAYS

func pete_chance() -> float:
	if not pete_allowed():
		return 0.0
	return 0.12 if phase() == "Night" else 0.05

func _director(delta: float) -> void:
	if not dialog.is_empty():
		return
	pete_cd = maxf(0.0, pete_cd - delta)
	spawn_t -= delta
	if spawn_t > 0.0:
		return
	spawn_t = spawn_interval()
	if live_enemies().size() >= spawn_cap():
		return
	if not pete_alive() and randf() < pete_chance():
		spawn_enemy("pete", _random_spawn_point())
		pete_last_spawn_day = day_count
		_toast("Palm Beach Pete rolls into Nebraska. Tax reasons, probably.")
		return
	var pool: = spawn_pool()
	var k: String = pool[randi() % pool.size()]
	if k == "driver":
		if spawn_driver() != null:
			return
		k = "scammer"
	spawn_enemy(k, _random_spawn_point())

## The part of a footprint its storefront sprite actually covers (opaque pixels, world units).
## Walls, labels and plaques use this so you can't bump into empty grass.
func _art_rect(b: Dictionary) -> Rect2:
	var r: Rect2 = b["r"]
	var used: = Art.used_rect(str(b.get("art", "")))
	if used.size.x == 0:
		return r
	var inf: = Art.info(str(b["art"]))
	var k: = Art.density(inf)
	var org: Array = inf.get("origin", [0, 0])
	var top: = r.position - Vector2(float(org[0]), float(org[1])) / k
	return Rect2(top + Vector2(used.position) / k, Vector2(used.size) / k)

func _random_spawn_point() -> Vector2:
	for _i in 40:
		var pt: = Vector2(randf_range(16, WORLD.x - 16), randf_range(16, WORLD.y - 16))
		var d: = pt.distance_to(player.position)
		if d < 110.0 or d > 260.0:
			continue
		var bad: = false
		for b in buildings:
			if (b["r"] as Rect2).grow(10).has_point(pt):
				bad = true
		for tr in trees:
			if pt.distance_to(tr) < 12.0:
				bad = true
		if not bad:
			return pt
	return Vector2(400, 130)

func enemy_touch(e: Node) -> void:
	if busy():
		return
	match e.kind:
		"scammer":
			if randf() < 0.5:
				scammer_steal(e)
			else:
				scammer_deal(e)
		"hustler":
			hustler_trap(e)

func scammer_steal(e: Node) -> void:
	var amt: = mini(money, 5 + day_count)
	if Gear.a_special(gear) == "pro":
		amt = amt / 2
	if amt <= 0:
		e.state = "leave"
		e.st = 3.0
		e.say("Empty pockets? ...Bro, are YOU okay? Want a crypto tip? (He's broke too.)")
		return
	money -= amt
	e.stolen += amt
	e.state = "flee"
	e.st = 6.0
	e.say("Thanks, chief!")
	_toast("The scammer lifts $%d off me! Gotta bonk him before he incorporates!" % amt)

func scammer_deal(e: Node) -> void:
	var price: = 8 if Gear.a_special(gear) == "pro" else 15
	var pitch: = "(Note to self: bonk first, ask never.)"
	if charisma() > 0:
		price = maxi(3, int(round(price * 0.6)))
		pitch = "(He sniffs me. \"Is that {cologne}? For you, friend... discount.\")"
	_menu("THE DEAL", ["Scammer: \"Rolecks watch, $%d. Limited drop. Exclusive. Today only. Every day. Forever.\"" % price, pitch],
		[["buy", "Buy it ($%d)" % price, KEY_1], ["no", "No thanks", KEY_2], ["bonk", "Bonk him", KEY_3]], _on_deal.bind(e, price))

func _on_deal(id: String, e: Node, price: int) -> void:
	if not is_instance_valid(e):
		return
	if id == "buy":
		if money < price:
			_toast("He sees my wallet, feels bad, and walks off. Even the scammers pity line cooks.")
		else:
			money -= price
			inventory["rolecks"] = int(inventory.get("rolecks", 0)) + 1
			_toast("Bought a Rolecks. It's already three hours slow and sending emails. -$%d" % price)
		e.state = "leave"
		e.st = 3.0
	elif id == "no":
		e.state = "leave"
		e.st = 3.0
		e.say("Your loss, chief.")
	else:
		e.take_hit((e.global_position - player.global_position).normalized(), Gear.attack(gear) * 2.0, Gear.w_special(gear))
		_toast("Free bonk. Negotiations are over.")

func hustler_trap(e: Node) -> void:
	_run_game(MashScript.new(), _after_mash.bind(e))

func _after_mash(_n: Node, score: float, _x: Array, e: Node) -> void:
	if score >= 1.0:
		_toast("I break free! Now he's knocking on {sister}'s door. She'll eat him alive.")
	else:
		var cost: = mini(money, 5 if Gear.a_special(gear) == "pro" else 10)
		money -= cost
		energy = maxf(1.0, energy - 5.0)
		_toast("Next thing I know, I'm signed up for Steak-of-the-Month (vegan, auto-renews, no cancel button). Dammit. -$%d, -5 Energy" % cost)
	if is_instance_valid(e):
		e.state = "leave"
		e.st = 2.5

func _roll_scraps(kind: String) -> int:
	var dr: Array = DROPS[kind]
	if randf() < float(dr[2]):
		gear["scraps"] = int(gear["scraps"]) + int(dr[3])
		return int(dr[3])
	return 0

func enemy_defeated(e: Node) -> void:
	if not e.is_in_group("enemy"):
		return
	var key: String = "karen_buddy" if e.kind == "karen" and e.buddy else e.kind
	var dr: Array = DROPS[e.kind]
	var cash: = randi_range(int(dr[0]), int(dr[1]))
	if e.buddy:
		cash = cash / 2
	cash += int(e.stolen)
	money += cash
	kills[e.kind] = int(kills.get(e.kind, 0)) + 1
	if arena_mode == "bet":
		bet_kills += 1
	combat.gain_xp(key)
	var sc: = _roll_scraps(e.kind)
	var msg: String = DEFEAT_LINES[key] % cash
	if e.kind == "pirate":
		msg = pirate_defeated(e, cash)
	if sc > 0:
		msg += " +%d scrap" % sc
	e.remove_from_group("enemy")
	e.remove_from_group("hostile")
	e.queue_free()
	if e.kind == "pete":
		pete_defeated_day = day_count
		var lines: Array = [msg]
		if not achievements.has("Sunburn Survivor"):
			achievements.append("Sunburn Survivor")
			lines.append("ACHIEVEMENT UNLOCKED: Sunburn Survivor (beat Palm Beach Pete. Florida has been notified.)")
		if randf() < 0.2:
			lines.append(Gear.grant_piece(gear, false))
			apply_gear()
		_say(lines)
	elif e.has_meta("quest_porch"):
		_say([msg, porch_quest_won()])
	elif e.has_meta("cold_open"):
		_say([msg] + cold_open_rules(true))
	else:
		_toast(msg)

func enemy_gone(e: Node) -> void:
	if e.has_meta("quest_porch"):
		_toast("Cheeto Chad clears the fence. He lives next door, genius. Knock again.")
	if e.kind == "pirate" and str(e.loot) != "":
		_toast("%s gets away with %s. He's gonna resell it on Marketplace as 'gently loved.'" % [e.display_name(), Cast.T(loot_name(str(e.loot)))])
	if e.has_meta("cold_open"):
		_say(cold_open_rules(false))
	if e.kind == "scammer" and int(e.stolen) > 0:
		_toast("Scammer gets away with $%d. Do I learn my lesson? I do not." % int(e.stolen))
	e.remove_from_group("enemy")
	e.remove_from_group("hostile")
	e.queue_free()

const JEN_DAILY: = [
	"Daily {wordle}'s up, family disappointment. Try not to embarrass us.",
	"You cook for a living and still can't spell SAUTE. Prove me wrong. {wordle}'s up.",
	"{partner} says a porch pirate outran you. Again. Anyway, new {wordle}.",
	"New word. I'll go easy on you. That's a lie. I won't.",
	"Mom called. She asked about me. Not you. Anyway, {wordle}?",
	"Wake up, nerd. Today's word is ready and so is my roast.",
]

func wordle_daily_done() -> bool:
	return int(wordle.get("day", -1)) == day_count

func wordle_practice_done() -> bool:
	return int(wordle.get("practice_day", -1)) == day_count

func wordle_answer(practice: bool) -> String:
	var sd: = hash("%d:%d:%s" % [wordle_seed, day_count, "p" if practice else "d"])
	return WL.pick_answer(sd, wordle.get("history", []))

func start_wordle(practice: bool) -> void:
	var w: = WordleScript.new()
	w.answer = wordle_answer(practice)
	w.practice = practice
	w.streak = int(wordle.get("streak", 0))
	last_wordle = w
	_run_game(w, _after_wordle)

func _jen_reaction(guesses: int, answer: String, practice: bool) -> String:
	if guesses <= 0:
		var roasts: = [
			"{sister}: It was %s. %s, {hero}. I'm telling {partner}.",
			"{sister}: %s. I'm putting this in the family group chat. Mom already reacted with a skull.",
			"{sister}: The word was %s. Even {cat3} knew that one and she hates everyone.",
			"{sister}: %s! Six tries! You spell like you run for the bus: badly and with confidence.",
		]
		var r: String = roasts[randi() % roasts.size()]
		return r % ([answer, answer] if r.count("%s") == 2 else [answer])
	var lines: = ["",
		"{sister}: ONE GUESS?! Did you read my phone? ...Fine. Take this. I found it at a garage sale.",
		"{sister}: Two. Okay, show-off. Mom still likes me better.",
		"{sister}: Three. Respectable. For a guy who eats cereal with a ladle.",
		"{sister}: Four. Mid. Here's some scrap, go chase a porch pirate with it.",
		"{sister}: Five?! {baby} could do better and she eats crayons.",
		"{sister}: SIX. You sweated through your apron for that one.",
	]
	return ("Practice round. " if practice else "") + str(lines[clampi(guesses, 1, 6)])

func finish_wordle(guesses: int, practice: bool, answer: String) -> Array:
	if practice:
		if wordle_practice_done():
			return ["{sister}: You already did practice. Go touch grass. Oh wait."]
		wordle["practice_day"] = day_count
	else:
		if wordle_daily_done():
			return ["{sister}: Nice try. One daily per day, cheater."]
		wordle["day"] = day_count
		wordle["played"] = int(wordle["played"]) + 1
		var dist: Array = wordle["dist"]
		dist[clampi(guesses, 0, 6)] = int(dist[clampi(guesses, 0, 6)]) + 1
		if guesses > 0:
			wordle["streak"] = (int(wordle["streak"]) + 1) if int(wordle["last_win_day"]) == day_count - 1 else 1
			wordle["last_win_day"] = day_count
			wordle["wins"] = int(wordle["wins"]) + 1
			wordle["best_streak"] = maxi(int(wordle["best_streak"]), int(wordle["streak"]))
		else:
			wordle["streak"] = 0
	var hist: Array = wordle["history"]
	hist.append(answer)
	while hist.size() > 40:
		hist.pop_front()
	var streak: = 0 if practice else int(wordle["streak"])
	var r: = WL.reward(guesses, practice, streak)
	var lines: Array = [_jen_reaction(guesses, answer, practice)]
	gear["scraps"] = int(gear["scraps"]) + int(r["scraps"])
	money += int(r["money"])
	var bits: Array = []
	if int(r["scraps"]) > 0:
		bits.append("+%d scrap" % int(r["scraps"]))
	if int(r["money"]) > 0:
		bits.append("+$%d" % int(r["money"]))
	if not bits.is_empty():
		lines.append("Reward: " + ", ".join(bits) + ("  (streak %d bonus included)" % streak if streak > 1 else ""))
	for i in int(r["gear"]):
		lines.append(Gear.grant_piece(gear))
	if streak > 0 and streak % 5 == 0:
		lines.append("%d-DAY STREAK! {sister} grudgingly tosses me an extra gear piece." % streak)
	apply_gear()
	advance_clock(15.0)
	save_game()
	return lines

func pay_tier() -> Array:
	var best: Array = TIERS[0]
	for tr in TIERS:
		if shifts_worked >= int(tr[0]):
			best = tr
	return best

func pay_mult() -> float:
	return float(pay_tier()[1])

func pay_title() -> String:
	return str(pay_tier()[2])

func stun_player(tm: float, msg: String = "") -> bool:
	if busy() or player.rolling() or player.stun_t > 0.0:
		return false
	player.stun_t = tm
	if msg != "":
		_toast(msg)
	return true

var ping_t: = 0.0

func text(th: String, from: String, body: String, grid: Array = []) -> void:
	if from != "me":
		AudioScript.sfx("text")
	var arr: Array = threads.get(th, [])
	var msg: = {"from": from, "text": body, "day": day_count }
	if not grid.is_empty():
		msg["grid"] = grid
	arr.append(msg)
	while arr.size() > SaveGame.MAX_THREAD:
		arr.pop_front()
	threads[th] = arr

func unread_count() -> int:
	var n: = 0
	for k in unread:
		if unread[k]:
			n += 1
	return n

func jen_text_daily() -> bool:

	if last_text_day == day_count:
		return false
	last_text_day = day_count
	text("sister", "sister", JEN_DAILY[day_count % JEN_DAILY.size()])
	if int(wordle.get("streak", 0)) > 1:
		text("sister", "sister", "Streak's at %d. Don't choke." % int(wordle["streak"]))
	unread["sister"] = true
	ping_t = 2.0
	_toast("*bzzt* {sister} texts me: today's {wordle} is up. (P = phone)")
	return true

func _after_wordle(n: Node, _s: float, _x: Array) -> void:
	var solved: = int(n.solved_in)
	var practice: = bool(n.practice)
	var grid: Array = (n.results as Array).duplicate(true)
	text("sister", "me", "%s %s/6" % ["Practice" if practice else "{wordle} day %d" % day_count, str(solved) if solved > 0 else "X"], grid)
	for l in finish_wordle(solved, practice, str(n.answer)):
		var line: = str(l)
		if line.begins_with("{sister}: "):
			text("sister", "sister", line.substr(10))
		elif line.begins_with("Practice round. {sister}: "):
			text("sister", "sister", "Practice round. " + line.substr(26))
		else:
			text("sister", "sys", line)
	unread["sister"] = false
	open_phone("thread_sister")

func open_phone(scr: String = "home") -> void:
	if busy() or not dialog.is_empty():
		return
	if location == "gala":
		_toast("Security takes my phone. 'Only donors may post, sir.' Tyler is posting. Tyler is always posting.")
		return
	if location == "arena":
		_toast("No time to text. Kinda in a boss fight here.")
		return
	var ph: = PhoneScript.new()
	ph.m = self
	ph.screen = scr
	_run_game(ph, _after_phone)

func _after_phone(n: Node, _s: float, _x: Array) -> void:
	save_game()
	match str(n.action):
		"settings":
			open_settings()
		"wordle_daily":
			if not wordle_daily_done():
				start_wordle(false)
		"wordle_practice":
			if not wordle_practice_done():
				start_wordle(true)
		"gala": start_gala()
		"gear": open_gear()

func account(a: String) -> Dictionary:
	return college if a == "college" else brokerage

func account_cash(a: String) -> float:

	if a == "college":
		return float(college["cash"])
	return float(money) + float(brokerage["cash"])

func _sweep_brokerage() -> void:
	var whole: = floori(float(brokerage["cash"]) + 1.0e-06)
	if whole > 0:
		money += whole
		brokerage["cash"] = maxf(0.0, float(brokerage["cash"]) - whole)

func trade_buy(a: String, t: String, amt: float) -> float:
	var ac: = account(a)
	if a == "brokerage":
		brokerage["cash"] = float(brokerage["cash"]) + money
		money = 0
	var cash: = float(ac["cash"])
	var spend: = cash if amt < 0.0 else minf(amt, cash)
	var px: = Market.price(market, t)
	if spend < 0.01 or px <= 0.0:
		if a == "brokerage":
			_sweep_brokerage()
		return 0.0
	Market.buy(ac, t, px, spend)
	ac["cash"] = cash - spend
	if a == "brokerage":
		_sweep_brokerage()
	if a == "college":
		check_fund_goal()
	return spend

func trade_sell(a: String, t: String, frac: float) -> float:
	var ac: = account(a)
	var got: = Market.sell(ac, t, Market.price(market, t), frac)
	if got <= 0.0:
		return 0.0
	ac["cash"] = float(ac["cash"]) + got
	if a == "brokerage":
		_sweep_brokerage()
	return got

func toggle_drip(a: String) -> void:
	var ac: = account(a)
	ac["drip"] = not bool(ac["drip"])

func fund_value() -> float:
	return Market.value(college, market)

func fund_deposit(want: int) -> int:

	var amt: = money if want < 0 else mini(want, money)
	if amt <= 0:
		return 0
	money -= amt
	college["cash"] = float(college["cash"]) + amt
	college["deposited"] = float(college["deposited"]) + amt
	if fund_happy_day != day_count:
		fund_happy_day = day_count
		fund_happy_today = 0.0
	var h: = clampf(amt * 0.03, 0.0, FUND_HAPPY_CAP - fund_happy_today)
	gain_happy(h)
	fund_happy_today += h
	check_fund_goal()
	return amt

func market_week() -> Array:

	var r: = Market.tick(market)
	var lines: Array = []
	var news: Array = r["news"]
	lines.append("STONKS: " + str(news[0]))
	var d1: = Market.pay_dividends(brokerage, market)
	brokerage["cash"] = float(brokerage["cash"]) + float(d1["paid_out"])
	_sweep_brokerage()
	if float(d1["total"]) >= 0.01:
		lines.append("Dividends: $%.2f %s." % [float(d1["total"]), "reinvested (DRIP)" if brokerage["drip"] else "paid to your wallet"])
	var d2: = Market.pay_dividends(college, market)
	if not bool(college["drip"]):
		college["cash"] = float(college["cash"]) + float(d2["paid_out"])
	if float(d2["total"]) >= 0.01:
		lines.append("{baby}'s fund pulls $%.2f in dividends. Fund: $%s" % [float(d2["total"]), PhoneScript._money(fund_value())])
	if check_fund_goal():
		lines.append("{baby}'s fund hits $100,000! {partner} cries. I cry. {cat1} knocks a glass off the counter to mark the occasion.")
	return lines

## Octavia's fund goal: its own long-term score (achievement + a happy bump), no longer the gala key.
func check_fund_goal() -> bool:
	if achievements.has("Fully Funded") or fund_value() < Market.GOAL:
		return false
	achievements.append("Fully Funded")
	gain_happy(30.0)
	_toast("*BZZT* {baby}'s fund hits $100k! College: handled. Me: crying in the kitchen.")
	return true

## Day GALA_DAY morning: the gala invite (Committee thread + Madison's guest-list text).
## Old saves that already have gala_unlocked keep it; saves past the day catch up on load.
## Nov 10 (review fix): beating {ex_final} on story day 12 used to leave the gala locked until day 24, so the
## biggest fights sat behind 12 dead days after the credits. The invite now also lands the morning after the ending.
func gala_due() -> bool:
	return day_count >= GALA_DAY or bool(story.get("ending_seen", false))

func check_gala_unlock(toast: bool = true) -> bool:
	if gala_unlocked or not gala_due():
		return false
	gala_unlocked = true
	text("gala", "gala", "Dear {hero}. A seat opened up at THE ELITE GALA. Our intern mailed your invite by mistake. We honor our mistakes. Barely.")
	text("gala", "gala", "Black tie. Our guests are eager to meet a 'self-made man.' None of them are. -- The Committee")
	text("gala", "sys", "Tap 'Take the limo' when you're ready, any night till the month runs out. Five fights, a heal between each. No phones inside.")
	text("madison", "madison", "babe the gala guest list leaked. FOUR of my exes are on it. they all got rich. how. we're going. i'm wearing the green dress")
	unread["gala"] = true
	unread["madison"] = true
	ping_t = 2.0
	if toast:
		_toast("*BZZT* Gold envelope under the door. THE ELITE GALA. Some unknown number's texting me...")
	return true

## Wake line for the invite morning.
func gala_new_day() -> Array:
	if not check_gala_unlock():
		return []
	return ["A gold envelope's under the door. THE ELITE GALA. {partner}'s already holding up the green dress. (P = phone: 'Take the limo' any night.)"]

func start_gala(first: int = 0) -> void:
	if not gala_unlocked or busy() or _world_gate(func () -> void: start_gala(first)):
		return
	clear_enemies()
	location = "gala"
	player.position = GALA_SPAWN
	_set_camera()
	energy = 100.0
	gala_stage = first
	_say(["So a limo picks me up. Smells like money, shrimp and tax evasion.", "THE ELITE GALA. Charity thing. A butler takes my phone and my dignity. Bet he sells both to a tip line.", "{partner} reads the guest list and goes pale. Four of the names are her exes. All four 'made it.'", "{partner}: Babe. I am SO sorry. In advance. For all of them.", "Four exes. One rich host. One line cook. Alright. Let's fucking cook."])
	_spawn_boss()
	_sync_world()

func _spawn_boss() -> void:
	var b: = BossScript.new()
	b.kind = BOSS_ORDER[gala_stage]
	b.m = self
	b.position = GALA_ORIGIN + Vector2(160, 80)
	add_child(b)
	gala_boss = b
	b.set_physics_process(not busy())
	var setup: = str(BossScript.BOSSES[b.kind].get("setup", ""))       # {partner} reacts to her ex first
	_say(([setup] if setup != "" else []) + [str(BossScript.BOSSES[b.kind]["intro"])])

func boss_defeated(b: Node) -> void:
	if b != _ko_boss and KnockoutScript.is_live(str(b.kind)):
		_ko_boss = b                        # knockout cutscene first; knockout_done() comes back here
		ko_kind = str(b.kind)
		player.frozen = true
		_sync_world()
		return
	if b == arena_boss and arena_boss != null:
		match arena_mode:
			"bounty": grease_defeated(b) if str(b.kind) == "grease" else bounty_defeated(b)
			"waffle": waffle_regular_defeated(b)
			_: story_boss_defeated(b)
		return
	if b != gala_boss or gala_stage < 0:
		return
	var line: = str(BossScript.BOSSES[b.kind]["defeat"])
	kills[b.kind] = int(kills.get(b.kind, 0)) + 1
	combat.gain_xp("boss_gala", combat.level)
	clear_enemies()
	gala_boss = null
	gala_stage += 1
	if gala_stage >= BOSS_ORDER.size():
		gala_win(line)
		return
	energy = 100.0
	_say([line, "Intermission. A butler hands me a shrimp cocktail worth more than my rent. Energy fully restored.",
		"Next up: %s." % str(BossScript.BOSSES[BOSS_ORDER[gala_stage]]["name"])])
	_spawn_boss()

func gala_win(line: String) -> void:
	gala_stage = -1
	var first: = not gala_beaten
	gala_beaten = true
	gala_runs += 1
	var lines: Array = [line, "I clear THE ELITE GALA. Her exes fight over the valet. {gala_ex_1} is still streaming it."]
	if first:
		for id in ["golden_spatula", "trust_fund"]:
			if not Gear.owns(gear, id):
				gear["owned"][id] = 0
			Gear.equip(gear, id)
		lines.append("LOOT: Golden Spatula of Generational Wealth + Trust Fund Plate Armor. Equipped.")
		lines.append("ACHIEVEMENT UNLOCKED: Gala Crasher (wealth redistributed, briefly)")
		if not achievements.has("Gala Crasher"):
			achievements.append("Gala Crasher")
	else:
		money += 250
		gear["scraps"] = int(gear["scraps"]) + 10
		lines.append("Rematch bonus: +$250 in loose cufflinks and +10 scrap. Still more than their tax rate.")
	lines.append("{partner}: You beat up FOUR of my exes in one night?? ...Put the spatula in the dishwasher.")
	apply_gear()
	_leave_gala()
	_say(lines)
	save_game()

func gala_lose() -> void:
	clear_enemies()
	gala_stage = -1
	gala_boss = null
	_leave_gala()
	energy = 40.0
	_say(["Security walks me out. They even take the shrimp back. Turns out the shrimp was a loan.", "Invitation's still good. Gear up and go again."])
	save_game()

func _leave_gala() -> void:
	location = "outside"
	player.position = OUTSIDE_SPAWN
	player.stun_t = 0.0
	_set_camera()
	_sync_world()

func _draw_gala() -> void:
	var o: = GALA_ORIGIN
	var f: = ThemeDB.fallback_font
	Art.image(self, "gala", o)
	draw_string(f, o + Vector2(110, 18), "THE ELITE GALA", HORIZONTAL_ALIGNMENT_CENTER, 100, 8, Color("#ffd23f"))
	for i in 6:
		draw_circle(Vector2(o.x + 30.0 + i * 52.0, o.y + 46), 7, Color(1, 0.9, 0.5, 0.12 + 0.06 * sin(t * 2.0 + i)))

func story_index(id: String) -> int:
	for i in STORY.size():
		if STORY[i]["id"] == id:
			return i
	return -1

func story_beaten(id: String) -> bool:
	return (story["beaten"] as Array).has(id)

func story_next() -> Dictionary:
	for e in STORY:
		if not story_beaten(e["id"]):
			return e
	return {}

func story_conditions_met(id: String) -> bool:

	var i: = story_index(id)
	if i < 0 or story_beaten(id):
		return false
	for j in i:
		if not story_beaten(STORY[j]["id"]):
			return false
	return day_count >= int(STORY[i]["day"]) and happiness >= float(STORY[i]["happy"])

func story_available(id: String) -> bool:

	return (story["announced"] as Array).has(id) and not story_beaten(id)

func story_ready_unannounced() -> String:
	var n: = story_next()
	if n.is_empty() or (story["announced"] as Array).has(n["id"]):
		return ""
	return str(n["id"]) if story_conditions_met(n["id"]) else ""

func story_announce() -> Array:
	var id: = story_ready_unannounced()
	if id == "":
		return []
	(story["announced"] as Array).append(id)
	var e: Dictionary = STORY[story_index(id)]
	_toast("STORY: %s is waiting at %s" % [Cast.T(e["name"]), Cast.T(e["where"])])
	return [str(e["tip"]), "STORY UNLOCKED: confront %s at %s. (Look for the ! on the map.)" % [e["name"], e["where"]]]

func story_quest_text() -> String:
	var n: = story_next()
	if n.is_empty():
		return ""
	if story_available(n["id"]):
		return "Story: beat %s at %s" % [n["name"], n["where"]]
	if story_ready_unannounced() != "":
		return "Story: talk to {partner}"
	if day_count < int(n["day"]):
		return ""
	return "Story: errands get {partner} to %d+ happiness" % int(n["happy"])

func story_doors() -> Array:
	var out: Array = []
	for e in STORY:
		if story_available(e["id"]):
			var r: Rect2 = e["r"]
			out.append({"id": "story_" + str(e["id"]), "pos": Vector2(r.get_center().x, r.end.y + 6.0), "r": 16.0, "label": "Confront " + Cast.T(e["name"]) })
	return out

func story_menu(id: String) -> void:
	if not story_available(id):
		return
	var e: Dictionary = STORY[story_index(id)]
	var lines: Array = ["%s is inside %s." % [e["name"], Cast.T(e["place"])]]
	if id == "willnot":
		lines.append("Final boss. I've got %d seconds before the tower self-destructs. Glass on the floor hurts HIM, not me. Work clogs, baby." % int(FINAL_TIME))
	lines.append("Energy: %d. I go in at full either way, but bring the good gear." % int(energy))
	_menu(Cast.T(e["place"]), lines, [["go", "Go in", KEY_1], ["no", "Not yet", KEY_2]], _on_story_menu.bind(id))

func _on_story_menu(choice: String, id: String) -> void:
	if choice == "go":
		start_story_fight(id)

func start_story_fight(id: String) -> void:
	if busy() or _world_gate(func () -> void: start_story_fight(id)):
		return
	show_loading()
	clear_enemies()
	arena_id = id
	arena_mode = "story"
	location = "arena"
	player.position = ARENA_SPAWN
	player.stun_t = 0.0
	_set_camera()
	energy = 100.0
	story["attempts"] = int(story.get("attempts", 0)) + 1
	var b: = BossScript.new()
	b.kind = id
	b.m = self
	b.position = ARENA_ORIGIN + Vector2(160, 80)
	add_child(b)
	arena_boss = b
	b.set_physics_process(not busy())
	final_timer = FINAL_TIME if id == "willnot" else 0.0
	var pre: Array = []
	if id == "willnot":
		pre = ["So I'm on the 30th floor of {FINAL_TOWER}. Someone rigged the building. Big red clock. Of course there's a big red clock.", "And every ex I ever beat is watching from the cubicles. Mandatory team-building."]
	_say(pre + [str(BossScript.BOSSES[id]["intro"])])
	_sync_world()

func current_boss() -> Node:
	if location == "arena" and arena_boss and is_instance_valid(arena_boss):
		return arena_boss
	if location == "gala" and gala_boss and is_instance_valid(gala_boss):
		return gala_boss
	return null

func _arena_process(delta: float) -> void:
	if not dialog.is_empty():
		return
	if arena_mode == "waffle":
		if energy <= 0.0:
			if waffle_node != null and not waffle_node.done:
				waffle_node.done = true
				end_waffle(waffle_node.result(true))
			return
		if waffle_node != null:
			waffle_node.tick(delta)
		return
	if arena_mode == "bounty":
		if energy <= 0.0:
			bounty_lose()
		return
	if arena_mode == "bet":
		_bet_process(delta)
		return
	if finale_t > 0.0:
		finale_t -= delta
		player.frozen = true
		if finale_t <= 0.0:
			player.frozen = false
			_finish_final()
		return
	if energy <= 0.0:
		story_lose("I get knocked out. Me and the sidewalk get acquainted. {partner} scrapes me off the curb. Again. She doesn't even ask anymore. She just brings the wipes.")
		return
	if arena_id == "willnot" and final_timer > 0.0:
		var before: = final_timer
		final_timer -= delta
		for mark in [60.0, 30.0, 10.0]:
			if before > mark and final_timer <= mark:
				_toast("%d SECONDS TO SELF-DESTRUCT!" % int(mark))
		if final_timer <= 0.0:
			story_lose("BOOM. Tower blows with me in it. I wake up on the lawn, no eyebrows. Building's fine. Insured for triple. Try again.")

func story_lose(msg: String) -> void:
	clear_enemies()
	arena_boss = null
	arena_id = ""
	final_timer = 0.0
	_leave_arena()
	energy = 40.0
	happiness = maxf(0.0, happiness - 5.0)
	_say([msg, "-5 Happiness. The door's still open whenever you're ready."])
	save_game()

func _leave_arena() -> void:
	arena_mode = ""
	location = "outside"
	player.position = OUTSIDE_SPAWN
	player.stun_t = 0.0
	_set_camera()
	_sync_world()

func story_boss_defeated(b: Node) -> void:
	var id: = str(b.kind)
	var e: Dictionary = STORY[story_index(id)]
	var line: = str(BossScript.BOSSES[id]["defeat"])
	kills[id] = int(kills.get(id, 0)) + 1
	combat.gain_xp("boss_story", combat.level)
	combat.unlock_demon("Beating %s lights something up inside me." % Cast.T(str(BossScript.BOSSES[id]["name"])))
	clear_enemies()
	arena_boss = null
	if not story_beaten(id):
		(story["beaten"] as Array).append(id)
	money += int(e["cash"])
	gear["scraps"] = int(gear["scraps"]) + int(e["scrap"])
	var lines: Array = [line, "Dropped: $%d and %d scrap." % [int(e["cash"]), int(e["scrap"])]]
	if id != "willnot":
		lines.append(Gear.grant_piece(gear, false))
	if not achievements.has(str(e["ach"])):
		achievements.append(str(e["ach"]))
		lines.append("ACHIEVEMENT UNLOCKED: %s" % e["ach"])
	apply_gear()
	if id == "willnot":
		final_timer = 0.0
		finale_t = 4.0
		AudioScript.sfx("explosion")
		_toast("THE WHOLE FLOOR IS GOING UP. BEHIND! BEHIND! RUN!")
		_say(lines + ["Detonator clicks. I tie a garden hose around my waist and jump. Normal Tuesday at the {fork_nick}, honestly."])
		save_game()
		return
	gain_happy(15.0)
	lines.append("{partner}: You did WHAT? ...Never do that again. Tell me everything. +15 Happiness")
	arena_id = ""
	_leave_arena()
	_say(lines)
	save_game()

func _finish_final() -> void:
	arena_id = ""
	clear_enemies()
	_leave_arena()
	start_ending()

func start_ending() -> void:
	dialog.clear()
	var en: = EndingScript.new()
	en.shades = shades
	_run_game(en, _after_ending)

func _after_ending(_n: Node, _s: float, _x: Array) -> void:
	story["ending_seen"] = true
	if not achievements.has("Happily Ever After"):
		achievements.append("Happily Ever After")
	happiness = 100.0
	location = "home"
	player.position = INT_SPAWN
	_set_camera()
	_sync_world()
	_say(["Post-game: the days keep going. Rent keeps coming. Stonks and {sister}'s {wordle} are all still here.", "Tomorrow morning there's a gold envelope coming. The real final round is a black-tie party. (Beaten bosses stay beaten.)"])
	if not has_car:
		text("madison", "madison", "we're officially a family now. families have minivans. a used one is $%d. start saving, chef <3 (buy it at any bus stop)" % Transit.CAR_PRICE)
		unread["madison"] = true
	save_game()

func _draw_arena() -> void:
	var o: = ARENA_ORIGIN
	var f: = ThemeDB.fallback_font
	Art.image(self, "arena_" + arena_id, o)
	match arena_id:
		"ghoster":
			_arena_caption(f, o, "SEEN CAFE  -  open 24/7, never replies", Color("#a0c0ff"))
			for p in [Vector2(50, 88), Vector2(255, 88), Vector2(43, 140), Vector2(262, 140)]:  # the four rugs
				draw_string(f, o + p + Vector2(-8, 2), "seen", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.45))
		"crypto":
			_arena_caption(f, o, "HONEYBUNCOIN MINING RIG  (-99.8%)", Color("#ff5050"))
		"alley":
			if arena_mode == "bet":
				_draw_bet_hud(f, o)
			else:
				_arena_caption(f, o, "BEHIND {FORK}  -  86 LIST ENFORCEMENT ZONE", Color("#ffd23f"))
	if finale_t > 0.0:
		var rng: = RandomNumberGenerator.new()
		rng.seed = int(t * 12.0)
		for i in 9:
			var pp: = o + Vector2(rng.randf_range(10, 310), rng.randf_range(30, 170))
			draw_circle(pp, rng.randf_range(10, 26), Color(1, rng.randf_range(0.3, 0.8), 0.1, 0.75))
		draw_rect(Rect2(o, ARENA_SIZE), Color(1, 0.9, 0.6, 0.25 + 0.25 * sin(t * 30.0)))
	draw_rect(Rect2(o, ARENA_SIZE), Color("#888888"), false, 2.0)

## One-line joke caption on a dark strip across the back wall, just under the HUD bar (never on the floor).
func _arena_caption(f: Font, o: Vector2, line: String, c: Color) -> void:
	draw_rect(Rect2(o + Vector2(0, 18), Vector2(ARENA_SIZE.x, 9)), Color(0, 0, 0, 0.55))
	draw_string(f, o + Vector2(0, 25), Cast.T(line), HORIZONTAL_ALIGNMENT_CENTER, ARENA_SIZE.x, 6, c)

const ERRAND_THANKS: = {
	"pharmacy": ["You got it?! You waited in THE line? I'm telling everyone. I'm telling the cats.", "My hero. My prescription hero. Here's your copay back, plus bus fare.", "You survived {pharmacy}. Honestly, that's a story boss."],
	"grocery": ["You got everything?! Look at you, a whole adult.", "The fridge has FOOD in it. I could cry.", "You even got the right eggs. Who ARE you?"],
}
const ERRAND_MISS: = {
	"pharmacy": "It's after 7, babe. I went to {pharmacy} myself. In pajamas. With the baby. {pharmacist} says hi. You owe me a foot rub.",
	"grocery": "Never mind hon, I did the grocery run. {baby} and I had a great time. We missed you. Mostly her. (Me too.)",
}

func _unlock(ach: String) -> String:
	if achievements.has(ach):
		return ""
	achievements.append(ach)
	AudioScript.sfx("achievement")
	return "ACHIEVEMENT UNLOCKED: " + ach

func errand_new_day() -> Array:

	var out: Array = []
	if int(errand.get("day", -1)) == day_count:
		return out
	if Errands.pending(errand):
		out = errand_miss(true)
	errand = Errands.make(day_count, wordle_seed)
	var body: = str(errand["ask"])
	if errand["kind"] == "grocery":
		body += " List: %s. Budget $%d on my card. By %s pls!" % [Errands.list_text(errand), int(errand["budget"]), Errands.due_text(errand)]
	else:
		body += " Need it by %s." % Errands.due_text(errand)
	text("madison", "madison", body)
	unread["madison"] = true
	ping_t = 2.0
	_toast("*bzzt* {partner} texts me an errand. (P = phone)")
	return out

func errand_brief() -> String:
	if not Errands.pending(errand):
		return ""
	if errand["kind"] == "pharmacy":
		return "{partner} texts: prescription pickup at {pharmacy} (south road), by %s." % Errands.due_text(errand)
	return "{partner} sends me a {grocery} list (bottom-left), $%d budget, by %s. It's on my phone." % [int(errand["budget"]), Errands.due_text(errand)]

func errand_quest_text() -> String:
	if not Errands.pending(errand):
		return ""
	var due: = Errands.due_text(errand)
	if errand["status"] == "fetched":
		return "Errand: bring it to {partner} by %s" % due
	if errand["kind"] == "pharmacy":
		return "Errand: Rx at {pharmacy} by %s" % due
	return "Errand: {grocery} list by %s" % due

func errand_overdue() -> bool:
	return Errands.pending(errand) and int(errand["day"]) == day_count and clock >= float(errand["due"]) and not location in ["gala", "arena"] and dialog.is_empty()

func errand_miss(silent: bool) -> Array:
	var kind: = str(errand["kind"])
	errand["status"] = "missed"
	happiness = maxf(0.0, happiness - Errands.MISS_HAPPY)
	errand_stats["missed"] = int(errand_stats["missed"]) + 1
	errand_stats["streak"] = 0
	set_upset("errand")
	text("madison", "madison", ERRAND_MISS.get(kind, "Never mind."))
	unread["madison"] = true
	ping_t = 2.0
	var lines: Array = ["{partner} texts: \"%s\"" % ERRAND_MISS.get(kind, "Never mind."), "Errand missed. -%d Happiness" % int(Errands.MISS_HAPPY)]
	if not (errand["got"] as Dictionary).is_empty():
		lines.append("(I can still bring it home. Late counts for something.)")
	if not silent:
		_say(lines)
	return lines

func errand_deliverable() -> bool:
	var st: = str(errand.get("status", ""))
	return (st == "fetched" or st == "missed") and not (errand["got"] as Dictionary).is_empty()

func errand_deliver() -> Array:
	var kind: = str(errand["kind"])
	var late: = str(errand["status"]) == "missed"
	var items: Dictionary = errand["items"]
	var got: Dictionary = errand["got"]
	var lines: Array = []
	var delivered: = 0
	for id in items:
		if got.has(id) and int(inventory.get(id, 0)) > 0:
			delivered += 1
	var frac: = float(delivered) / float(maxi(1, items.size()))

	if kind == "pharmacy":
		inventory["meds"] = maxi(0, int(inventory.get("meds", 0)) - 1)
	else:
		if got.has("honey buns") and int(inventory.get("honey buns", 0)) > 0:
			inventory["honey buns"] -= 1
			lines.append("{partner} eats a honey bun before I even finish unpacking. Priorities.")
		var cake_ok: = true
		for c in Errands.CAKE:
			if int(inventory.get(c, 0)) <= 0:
				cake_ok = false
		if cake_ok and (got.has("cherries") or got.has("chocolate")):
			for c in Errands.CAKE:
				inventory[c] -= 1
			inventory["cake"] = int(inventory.get("cake", 0)) + 1
			lines.append("She bakes a Black Forest cake. Cherries everywhere. A crime scene, but delicious. (Kitchen: +60 Energy.)")
		lines.append_array(errand["sub_notes"])
	var h: = Errands.reward(errand, frac, clock)
	if late:
		h = 3.0
	gain_happy(h)
	var cash: = 0
	if kind == "pharmacy":
		cash = int(errand["copay"]) + Errands.GAS_MONEY
	else:
		cash = maxi(0, int(errand["budget"]) - int(errand["spent"]))
	money += cash
	errand["status"] = "late" if late else "done"
	var th: Array = ERRAND_THANKS.get(kind, ["Thanks!"])
	var thanks: = "Better late than never, I guess. Thank you." if late else str(th[(int(errand_stats["done"]) + day_count) % th.size()])
	text("madison", "madison", thanks)
	lines.push_front("{partner}: " + thanks)
	var money_line: = ""
	if cash > 0:
		money_line = (" She pays me back $%d." % cash) if kind == "pharmacy" else (" I keep the $%d change." % cash)
	lines.append("Errand %s! +%d Happiness.%s" % ["delivered (late)" if late else "complete", int(h), money_line])
	if not late:
		errand_stats["done"] = int(errand_stats["done"]) + 1
		errand_stats[kind] = int(errand_stats[kind]) + 1
		errand_stats["streak"] = int(errand_stats["streak"]) + 1
		errand_stats["best"] = maxi(int(errand_stats["best"]), int(errand_stats["streak"]))
		if int(errand_stats["streak"]) >= 3:
			lines.append("Errand streak: %d days. {partner}'s telling her friends about me." % int(errand_stats["streak"]))
		var a: = ""
		if kind == "pharmacy":
			a = _unlock("Prescription Courier")
		elif int(errand["budget"]) - int(errand["spent"]) >= 5:
			a = _unlock("Under Budget, Over Achiever")
		if a != "":
			lines.append(a)
		if int(errand_stats["done"]) >= 7:
			var a2: = _unlock("Errand Machine")
			if a2 != "":
				lines.append(a2)
	player.carrying = int(inventory.get("honey buns", 0)) > 0
	save_game()
	return lines

func debug_errand(kind: String) -> void:

	var d: = day_count
	while Errands.kind_for_day(d) != kind:
		d += 1
	errand = Errands.make(d, wordle_seed)
	errand["day"] = day_count

func open_pharmacy(extra: Dictionary = {}) -> void:
	if busy():
		return
	if not Errands.is_open("pharmacy", clock):
		_say(["I get to {pharmacy}: closed (8 AM - 9 PM). Sign says 'Back in 5 minutes.' It's said that since 2019. Damn."])
		return
	var ph: = PharmacyScript.new()
	ph.m = self
	var want: bool = errand["kind"] == "pharmacy" and errand["status"] == "active"
	ph.ctx = {"errand": want, "seed": hash(wordle_seed + day_count * 13) }
	ph.ctx.merge(extra, true)
	_run_game(ph, _after_pharmacy)

func _after_pharmacy(n: Node, _s: float, _x: Array) -> void:
	advance_clock(maxf(10.0, float(n.minutes)))
	energy = maxf(1.0, energy - 4.0)
	var lines: Array = []
	if bool(n.got_meds) and errand["kind"] == "pharmacy" and errand["status"] in ["active", "missed"]:
		inventory["meds"] = int(inventory.get("meds", 0)) + 1
		errand["got"] = {"meds": 1 }
		errand["copay"] = int(n.copay)
		if errand["status"] == "active":
			errand["status"] = "fetched"
		lines.append("I get {partner}'s prescription. Now it's gotta be home by %s." % Errands.due_text(errand))
	if bool(n.phone_tree_beaten):
		errand_stats["phone_trees"] = int(errand_stats["phone_trees"]) + 1
		var a: = _unlock("Hold Music Survivor")
		if a != "":
			lines.append(a)
	if not lines.is_empty():
		_say(lines)
	_sync_world()
	save_game()

func open_grocery(extra: Dictionary = {}) -> void:
	if busy():
		return
	if not Errands.is_open("grocery", clock):
		_say(["{grocery}'s closed (6 AM - 11 PM). One lone cart rolls across the lot, freer than any of us."])
		return
	if errand["kind"] == "grocery" and errand["status"] == "active":
		_start_grocery(true, extra)
		return
	_menu("{GROCERY}", ["{partner} hasn't sent me a list.", "Shop for Black Forest cake stuff anyway? (Your money, cheaper than Kwik-N-Go.)"],
		[["go", "Cake run", KEY_1], ["no", "Never mind", KEY_2]], func (id: String) -> void:
			if id == "go":
				_start_grocery(false, extra))

func _start_grocery(with_errand: bool, extra: Dictionary) -> void:
	var g: = GroceryScript.new()
	g.m = self
	if with_errand:
		g.ctx = {"errand": true, "items": errand["items"], "budget": int(errand["budget"]), "oos": str(errand["oos"]), "seed": hash(wordle_seed + day_count * 17) }
	else:
		var cake: = {}
		for c in Errands.CAKE:
			cake[c] = 1
		g.ctx = {"errand": false, "items": cake, "budget": 0, "oos": "", "seed": hash(wordle_seed + day_count * 19) }
	g.ctx.merge(extra, true)
	_run_game(g, _after_grocery)

func _after_grocery(n: Node, _s: float, _x: Array) -> void:
	advance_clock(10.0 + float(n.shop_t) + float(n.minutes) + 2.0 * (n.scan_list as Array).size())
	energy = maxf(1.0, energy - 6.0)
	var lines: Array = []
	if not bool(n.paid):
		_toast("I walk out empty-handed. The cart judges me. The self-checkout reports me.")
		_sync_world()
		save_game()
		return
	var cart: Dictionary = n.cart
	for id in cart:
		inventory[id] = int(inventory.get(id, 0)) + 1
	if bool(n.has_errand) and errand["kind"] == "grocery" and Errands.pending(errand):
		var got: = {}
		for id in cart:
			got[id] = 1
		errand["got"] = got
		errand["spent"] = int(n.total)
		errand["subs"] = int(n.subs)
		errand["sub_notes"] = (n.sub_notes as Array).duplicate()
		errand["skipped"] = (n.skipped as Array).duplicate()
		errand["card_strain"] = bool(n.card_strain)
		errand["status"] = "fetched"
		lines.append("Bagged and paid. Now it's gotta get home to {partner} by %s." % Errands.due_text(errand))
	errand_stats["coupons"] = int(errand_stats["coupons"]) + int(n.coupon_save)
	if int(errand_stats["coupons"]) >= 10:
		var a: = _unlock("Coupon Clipper")
		if a != "":
			lines.append(a)
	if bool(n.gag_done):
		errand_stats["bagging"] = int(errand_stats["bagging"]) + 1
		var a2: = _unlock("Unexpected Item In Bagging Area")
		if a2 != "":
			lines.append(a2)
	if not lines.is_empty():
		_say(lines)
	player.carrying = int(inventory.get("honey buns", 0)) > 0
	_sync_world()
	save_game()

const CLOSED_NEAR: = 110.0

class WorldLabels extends Node2D:

	var m: Node
	func _process(_d: float) -> void:
		visible = m.location == "outside" or m.location == "home"
		queue_redraw()
	func _draw() -> void:
		if m.location == "outside":
			m.draw_world_labels(self)
		m.draw_quest_markers(self)

func _label(ci: CanvasItem, f: Font, pos: Vector2, s: String, w: float, size: int, col: Color) -> void:
	UiStyle.tag(ci, pos, s, size, col, w, HORIZONTAL_ALIGNMENT_CENTER, 1.0 / 1.5, f)

func _closed_plaque(ci: CanvasItem, r: Rect2, f: Font) -> void:
	# only the shop you're walking up to says CLOSED; a whole street of them was noise
	if player == null or player.position.distance_to(Vector2(r.get_center().x, r.end.y + 22.0)) > CLOSED_NEAR:
		return

	var pr: = Rect2(r.get_center().x - 15.0, r.position.y + 12.0, 30.0, 8.0)
	ci.draw_rect(Rect2(pr.position + Vector2(1.0 / 1.5, 1.0 / 1.5), pr.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(pr, Color("#2b2218"))
	ci.draw_rect(pr, Color("#a43a2c"), false, 1.0 / 1.5)
	ci.draw_line(pr.position + Vector2(5, 0), pr.position + Vector2(9, -3), Color("#8c8478"), 1.0 / 1.5)
	ci.draw_line(pr.position + Vector2(25, 0), pr.position + Vector2(21, -3), Color("#8c8478"), 1.0 / 1.5)
	ci.draw_string(f, Vector2(pr.position.x, pr.position.y + 6.3), "CLOSED", HORIZONTAL_ALIGNMENT_CENTER, pr.size.x, 5, Color("#f0ead8"))

## ---- Side quest: "Who Took The Porch?" (mystery). Stages live in side_quests.gd. ----
## Talk hooks return true when the quest took over the conversation.
func quest_talk(npc: String) -> bool:
	return _porch_talk(npc) or _grease_talk(npc) or _gig_talk(npc) or _alley_talk(npc)

## Lost & Found, Omaha: a flyer in the mail, three things hidden around the block, returned to the Seen Cafe paper box.
## Each find is a clue named after the thing ("ring", "collar", "shoe"); all three advance to the return stage.
const LOST_LINES: = {
	"ring": ["I kneel at the storm drain. Something gold is caught in the grate, just above the dark.",
		"I fish it out with two fingers and a prayer. A wedding ring. Inside it says 'G + R, 1979. NO TAKEBACKS.'"],
	"collar": ["I lift the recycling bin lid. Cans, a pizza box, and a jingle.",
		"A pink cat collar with a bell and a tag: 'MR. BUTTONS. If found, he did this on purpose.'"],
	"shoe": ["I look up. There's a shoe in the pine tree. A left one. Size 11. Laces tied in a perfect bow.",
		"I climb. A branch takes some skin. The shoe is a Sketcher. Somebody's walking in circles out there."],
}

func _alley_talk(npc: String) -> bool:
	var st: = side_quests
	var q: = "alley"
	if npc == "mail" and SideQuests.offerable(st, q, day_count, show_hidden_quests):
		SideQuests.start(st, q)
		_say(["Under the bills: a flyer. Handwritten. Photocopied so many times the letters are going fuzzy.",
			"'LOST. 1) My ring. It went down where the street drinks. 2) Mr. Buttons' collar. Last heard jingling in the bin by the gas station. 3) My LEFT shoe. Long story. Look up, by the bus stop.'",
			"'Bring it all to the green paper box outside the Seen Cafe. There's a reward. It's not much. It's sincere. -- Gail'",
			"New side quest: Lost & Found, Omaha (phone > Notes)."])
		save_game()
		return true
	if not SideQuests.is_active(st, q):
		return false
	if LOST_SPOTS.has(npc) and SideQuests.stage(st, q) == 1 and not SideQuests.has_clue(st, q, npc):
		SideQuests.add_clue(st, q, npc)
		var lines: Array = (LOST_LINES[npc] as Array).duplicate()
		var found: = LOST_SPOTS.keys().filter(func (k): return SideQuests.has_clue(st, q, k)).size()
		if found >= LOST_SPOTS.size():
			SideQuests.advance(st, q)
			lines.append("That's all three. Ring, collar, shoe. Gail's whole bad week in my pockets. Now: the green paper box at the Seen Cafe.")
		else:
			lines.append("Found %d of 3." % found)
		_say(lines)
		save_game()
		return true
	if npc == "lostbox" and SideQuests.stage(st, q) == 2:
		_say(alley_payoff())
		return true
	return false

func alley_payoff() -> Array:
	SideQuests.finish(side_quests, "alley")
	money += 50
	gain_happy(6.0)
	var lines: Array = ["I open the paper box. No papers. Just an envelope with my name spelled wrong. 'DUF.'",
		"I put the ring, the collar and the shoe in. Under the envelope there's $50 and a Polaroid of an old lady and a fat cat, both giving a thumbs up.",
		"On the back: 'Mr. Buttons says thank you. The right shoe is still missing. Don't worry about the right shoe.' +$50, and {partner} wants the Polaroid on the fridge (+happy). Quest done."]
	if not achievements.has("Omaha's Finest"):
		achievements.append("Omaha's Finest")
		lines.append("ACHIEVEMENT UNLOCKED: Omaha's Finest")
	save_game()
	return lines

## Brittany's Side Gig: she's selling the Fork's house ranch on Marketplace. Cover for her or tell Chef.
## The pick is stored as the quest's choice; the payoff lands the next day.
func _gig_talk(npc: String) -> bool:
	var st: = side_quests
	var q: = "gig"
	if npc != "brittany":
		return false
	var wants: = SideQuests.offerable(st, q, day_count, show_hidden_quests) or SideQuests.is_active(st, q)
	if not wants:
		return false
	if phase() == "Night":
		_say(["{coworker}'s gone home. Her car's still here, though. The trunk smells like ranch. Come back in the daytime."])
		return true
	if SideQuests.offerable(st, q, day_count, show_hidden_quests):
		SideQuests.start(st, q)
		_say(["{coworker}: Okay. Don't freak out. I have a side hustle.",
			"{coworker}: It's a business. It has a logo. It has a PowerPoint. Talk to me again when you're ready to have your mind blown.",
			"New side quest: {coworker}'s Side Gig (phone > Notes)."])
		save_game()
		return true
	match SideQuests.stage(st, q):
		1:
			SideQuests.advance(st, q)
			_say(["{coworker} turns her phone sideways. Slide one: {COWORKER_SHORT}'S ARTISANAL RANCH. Slide two: a picture of the {fork_nick}'s ranch bucket.",
				"{coworker}: I fill mason jars from the walk-in. Hand-lettered labels. Eight bucks a jar on Marketplace. I've moved ninety jars.",
				"{coworker}: Chef's counting the ranch buckets. He thinks it's the dishwasher. I need you to say you saw the dishwasher take it. Or don't. Your call. I'm watching."])
			return true
		2:
			_menu("{COWORKER}'S SIDE GIG", ["{coworker} is staring at me. She hasn't blinked in a while.",
				"Chef thinks Manny the dishwasher is stealing ranch. Manny has three kids and a bad knee."],
				[["cover", "Cover for her", KEY_1], ["rat", "Tell Chef the truth", KEY_2], ["later", "Not yet", KEY_ESCAPE]],
				func (ch: String) -> void:
					gig_choose(ch))
			return true
		3:
			if SideQuests.has_clue(st, q, "day:%d" % day_count):
				_say(["{coworker}: It's been, like, an hour. Give it a day. Let the ranch settle."])
				return true
			_say(gig_payoff())
			return true
	return false

func gig_choose(ch: String) -> void:
	if not ch in ["cover", "rat"] or not SideQuests.is_active(side_quests, "gig") or SideQuests.stage(side_quests, "gig") != 2:
		return
	SideQuests.set_choice(side_quests, "gig", ch)
	SideQuests.add_clue(side_quests, "gig", "day:%d" % day_count)
	SideQuests.advance(side_quests, "gig")
	if ch == "cover":
		_say(["I tell Chef I didn't see anything. Which is technically true. I wasn't looking.",
			"{coworker} mouths 'thank you' and makes a heart with her hands. It's a little ranch-sticky."])
	else:
		_say(["I tell Chef. Chef says nothing. Chef goes very quiet and very red and walks into the walk-in and shuts the door.",
			"{coworker} saw the whole thing. She's not mad. She's taking notes."])
	save_game()

func gig_payoff() -> Array:
	var ch: = SideQuests.choice(side_quests, "gig")
	SideQuests.finish(side_quests, "gig", ch)
	var lines: Array = []
	var ach: = ""
	if ch == "rat":
		money += 40
		bet["day"] = day_count  # she's not betting with a narc today
		lines = ["Chef slips me $40 in an envelope marked 'LOYALTY'. Manny keeps his job. {coworker} keeps... nothing. The ranch empire has fallen.",
			"{coworker}: I respect it. I hate it, but I respect it. No bets today. I need to grieve.", "+$40. Quest done."]
		ach = "Narc of the {fork_nick}"
	else:
		money += 60
		gain_happy(5.0)
		lines = ["{coworker} hands me $60 and a mason jar with my name on it. Hand-lettered. 'DUFF'S RESERVE.'",
			"{coworker}: Silent partner. Very silent. If Chef asks, you're allergic to ranch now.", "+$60, one jar of ranch. {partner} loves it on everything (+happy). Quest done."]
		ach = "Ranch Cartel"
	if not achievements.has(ach):
		achievements.append(ach)
		lines.append("ACHIEVEMENT UNLOCKED: %s" % ach)
	save_game()
	return lines

## The Grease Trap: the 86 List grows an unsigned entry; after close the board sends Duff out back to fight it.
func _grease_talk(npc: String) -> bool:
	var st: = side_quests
	var q: = "grease"
	if npc != "bounty_board":
		return false
	if SideQuests.offerable(st, q, day_count, show_hidden_quests):
		SideQuests.start(st, q)
		SideQuests.advance(st, q)
		_say(["New entry on the 86 List. No name. No signature. Just a grease stain shaped like a man.",
			"Chef's handwriting under it: 'Not a customer. Comes out after close. Lives behind the fryer. DO NOT FEED.'",
			"New side quest: The Grease Trap (phone > Notes). Come back after 10 PM."])
		save_game()
		return true
	if not SideQuests.is_active(st, q) or SideQuests.stage(st, q) != 2:
		return false
	if phase() != "Night":
		_say(["The grease stain on the 86 List is dry. Whatever it is, it's sleeping. Come back after 10 PM. (It's %s.)" % clock_text()])
		return true
	if energy < 25.0:
		_say(["I'm too wiped to fight a drain. Eat something. Sleep. The grease will wait. Grease always waits."])
		return true
	start_grease_fight()
	return true

func start_grease_fight() -> void:
	if busy():
		return
	start_bounty("grease")
	_say(["Out back after close. The fryer's off but the floor drain is bubbling. Then it stands up.", str(BossScript.BOSSES["grease"]["intro"])])

func grease_defeated(_b: Node) -> void:
	kills["grease"] = int(kills.get("grease", 0)) + 1
	combat.gain_xp("boss_bounty", maxi(4, combat.level - 1))
	clear_enemies()
	arena_boss = null
	money += 90
	gear["scraps"] = int(gear["scraps"]) + 3
	SideQuests.finish(side_quests, "grease")
	var lines: Array = [str(BossScript.BOSSES["grease"]["defeat"]),
		"It slides back down the drain. Chef leaves $90 and 3 scrap on the pass with a note: 'Told you. DO NOT FEED.' Quest done."]
	if not achievements.has("Fryer Exorcist"):
		achievements.append("Fryer Exorcist")
		lines.append("ACHIEVEMENT UNLOCKED: Fryer Exorcist")
	apply_gear()
	arena_id = ""
	bounty_id = ""
	_leave_arena()
	player.position = BOARD_PT + Vector2(0, 8)
	_set_camera()
	_say(lines)
	save_game()

func _porch_talk(npc: String) -> bool:
	var st: = side_quests
	var q: = "porch"
	if npc == "madison" and SideQuests.offerable(st, q, day_count, show_hidden_quests):
		SideQuests.start(st, q)
		_say(["{partner}: \"Third package this month. THIRD. The tracking says delivered, the porch says nothing.\"",
			"{partner}: \"I don't want a doorbell cam. I want a NAME.\"",
			"New side quest: Who Took The Porch? (phone > Notes). {coworker} sees everything on this block. Start there."])
		save_game()
		return true
	if not SideQuests.is_active(st, q):
		return false
	match [npc, SideQuests.stage(st, q)]:
		["brittany", 1]:
			SideQuests.add_clue(st, q, "orange fingers")
			SideQuests.advance(st, q)
			_say(["{coworker}: Package thief? Oh, I've SEEN him. Tall. Orange fingers. Smells like a gas station hot case.",
				"{coworker}: Didn't see his face. I was filming a reaction video. To a different crime.",
				"Clue: orange fingers. Go check the porch for crumbs."])
			return true
		["porch", 2]:
			SideQuests.add_clue(st, q, "gas-station receipt")
			SideQuests.advance(st, q)
			_say(["Orange dust on the railing. A receipt underneath: one Flamin' Hot bag, two energy drinks, 3:12 AM.",
				"The receipt's got a loyalty number on it. And an address. The house next door.",
				"Clue: gas-station receipt. I know who it is. I always knew. I just didn't want to talk to him."])
			return true
		["neighbor", 3]:
			if phase() == "Night":
				_say(["Lights off next door. He's either asleep or out working. 'Working.' Come back in daylight."])
				return true
			if get_tree().get_nodes_in_group("enemy").any(func (e): return e.has_meta("quest_porch")):
				return true
			_say(["I knock. The door opens two inches. Orange fingers on the frame.",
				"Cheeto Chad: \"Packages? Never heard of 'em. ...Is that a RECEIPT?\"",
				"He bolts. Of course he bolts."])
			var e: = spawn_enemy("pirate", NEIGHBOR_DOOR + Vector2(0, 4))
			e.pname = "Cheeto Chad"
			e.max_hp = 6.0
			e.hp = 6.0
			e.set_meta("quest_porch", true)
			e.state = "flee"
			e.st = 9.0
			return true
	return false

## Only shows up while the porch quest needs it, so the street stays uncluttered.
func quest_interactables() -> Array:
	var out: Array = []
	if SideQuests.is_active(side_quests, "alley"):
		if SideQuests.stage(side_quests, "alley") == 1:
			var labels: = {"ring": "Something glints in the storm drain", "collar": "Something jingles in the recycling", "shoe": "Is that a shoe in the tree?"}
			for k in LOST_SPOTS:
				if not SideQuests.has_clue(side_quests, "alley", k):
					out.append({"id": "quest_" + k, "pos": LOST_SPOTS[k], "r": 14.0, "label": labels[k]})
		else:
			out.append({"id": "quest_lostbox", "pos": LOSTBOX_PT, "r": 12.0, "label": "Green paper box (Gail's drop)"})
	if not SideQuests.is_active(side_quests, "porch"):
		return out
	match SideQuests.stage(side_quests, "porch"):
		2: out.append({"id": "quest_porch", "pos": PORCH_PT, "r": 14.0, "label": "Check the porch for clues"})
		3: out.append({"id": "quest_neighbor", "pos": NEIGHBOR_DOOR, "r": 16.0, "label": "Knock next door"})
	return out

func porch_quest_won() -> String:
	SideQuests.add_clue(side_quests, "porch", "confession")
	SideQuests.finish(side_quests, "porch")
	money += 60
	gain_happy(12.0)
	var msg: = "Chad cracks. Six packages in his garage, still sealed. Even he has standards. +$60. {partner} is going to be insufferable about this (+happy). Quest done."
	if not achievements.has("Neighborhood Watch"):
		achievements.append("Neighborhood Watch")
		msg += "  ACHIEVEMENT: Neighborhood Watch"
	save_game()
	return msg

## Where each side-quest NPC/prop stands, so its !/? marker can float over it.
func quest_spots() -> Dictionary:
	return {
		"madison": ["home", madison_spot() + Vector2(0, -25)],
		"mail": ["home", MAIL_PT + Vector2(0, -14)],
		"brittany": ["outside", BRITT_POS + Vector2(0, -24)],
		"bounty_board": ["outside", BOARD_PT + Vector2(0, -22)],
		"porch": ["outside", PORCH_PT + Vector2(0, -16)],
		"neighbor": ["outside", NEIGHBOR_DOOR + Vector2(0, -26)],
		"lostbox": ["outside", LOSTBOX_PT + Vector2(0, -24)],
	}

func draw_quest_markers(ci: CanvasItem) -> void:
	if not dialog.is_empty():
		return
	var spots: = quest_spots()
	for npc in spots:
		if str(spots[npc][0]) != location:
			continue
		var mk: = SideQuests.marker_for(side_quests, str(npc), show_hidden_quests, day_count)
		if mk != "":
			UiStyle.quest_marker(ci, spots[npc][1] + Vector2(0, sin(t * 3.2) * 1.5), mk)
	# Lost & Found has no '?' while hunting: each unfound thing just glints now and then.
	if location == "outside" and SideQuests.is_active(side_quests, "alley") and SideQuests.stage(side_quests, "alley") == 1:
		var i: = 0
		for k in LOST_SPOTS:
			i += 1
			if SideQuests.has_clue(side_quests, "alley", k):
				continue
			var a: = clampf(sin(t * 2.4 + i * 2.1) * 1.6 - 0.6, 0.0, 1.0)
			if a <= 0.0:
				continue
			var p: Vector2 = LOST_SPOTS[k] + Vector2(0, -6)
			var c: = Color(1.0, 0.95, 0.6, a)
			var s: = 2.0 + a * 2.0
			ci.draw_line(p - Vector2(s, 0), p + Vector2(s, 0), c, 1.0)
			ci.draw_line(p - Vector2(0, s), p + Vector2(0, s), c, 1.0)
			ci.draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, a))

func draw_world_labels(ci: CanvasItem) -> void:
	var f: = ThemeDB.fallback_font
	for b in buildings:
		var r: Rect2 = b.get("vis", b["r"])
		# storefronts carry their own sign; only the unsigned houses still get a floating name
		if b.get("art", "") in ["", "sf_home", "sf_neighbor"]:
			_label(ci, f, Vector2(r.position.x, r.position.y - 3), Cast.T(b["n"]), r.size.x, 8 if not (b.has("story") or b.has("errand") or b.has("small")) else 6, Color.WHITE)
		r = Rect2(r.position - Vector2(0, 22), r.size)
		if b.has("errand"):
			_draw_errand_sign(ci, b, r, f)
		if b.has("story"):
			var sid: String = b["story"]
			if story_beaten(sid):
				_label(ci, f, Vector2(r.position.x, r.position.y + 19), "CLEARED", r.size.x, 6, Color("#c0d890"))
			elif story_available(sid):
				var by: = sin(t * 5.0) * 2.0
				ci.draw_string(f, Vector2(r.get_center().x - 3, r.position.y - 2 + by), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e6a640"))
			else:
				_closed_plaque(ci, r, f)
	var fork: Rect2 = buildings[3].get("vis", buildings[3]["r"])
	_label(ci, f, Vector2(fork.position.x, fork.position.y - 3), "NOW HIRING (you)", fork.size.x, 7, UiStyle.CREAM)

func _draw_errand_sign(ci: CanvasItem, b: Dictionary, r: Rect2, f: Font) -> void:
	var kind: String = b["errand"]
	var open: = Errands.is_open(kind, clock)
	if not open:
		_closed_plaque(ci, r, f)
	if open and errand["kind"] == kind and errand["status"] == "active":
		var by: = sin(t * 5.0) * 2.0
		ci.draw_string(f, Vector2(r.get_center().x - 3, r.position.y - 2 + by), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8cc4e8"))

func raccoon_spots() -> Array:
	var out: Array = []
	for i in raccoons.size():
		var rc: Node = raccoons[i]
		if is_instance_valid(rc):
			out.append({"id": "raccoon_%d" % i, "pos": rc.position, "r": 14.0, "label": "Pet the trash goblin (only honest business in town)" })
	return out

func pet_raccoon(i: int) -> void:
	if i < 0 or i >= raccoons.size() or not is_instance_valid(raccoons[i]):
		return
	raccoons[i].pet()
	raccoon_pets += 1
	advance_clock(2.0)
	var lines: Array = []
	if raccoon_gift_day != day_count:
		raccoon_gift_day = day_count
		var g: Array = RACCOON_GIFTS[(day_count + i) % RACCOON_GIFTS.size()]
		match str(g[1]):
			"money": money += int(g[2])
			"scrap": gear["scraps"] = int(gear["scraps"]) + int(g[2])
			_: inventory[str(g[1])] = int(inventory.get(str(g[1]), 0)) + int(g[2])
		lines.append("The raccoon digs through its trash and hands me %s No strings, no subscription. Friendship." % g[0])
	else:
		lines.append(RACCOON_GAGS[raccoon_pets % RACCOON_GAGS.size()])
	if raccoon_pets >= 5:
		var a: = _unlock("Trash Goblin Whisperer")
		if a != "":
			lines.append(a)
	player.carrying = int(inventory.get("honey buns", 0)) > 0
	_say(lines)

const PACKAGE_FLAVOR: = ["a 40-pack of baby wipes", "a phone case with {cat3}'s face on it", "a candle that smells like 'Cozy Sweater'", "a very soft blanket for the couch", "fancy cat food {cat1} will knock over"]
const PIRATE_TAUNTS: = ["Thanks for the package, chief! Leave five stars!", "It's not theft, it's the gig economy!", "It said LEAVE AT DOOR! I'm the door now!", "Two-day shipping, one-second stealing! Disrupting logistics!"]

func porch_delivery() -> bool:

	if porch_day == day_count or day_count < 2:
		return false
	porch_day = day_count
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(wordle_seed * 3 + day_count * 977)
	if rng.randf() >= 0.5:
		return false
	porch_pkg = true
	text("madison", "madison", "My package says delivered! Grab it off the porch before the porch pirates do?")
	unread["madison"] = true
	return true

func deliver_package() -> Array:
	inventory["package"] = maxi(0, int(inventory.get("package", 0)) - 1)
	gain_happy(6.0)
	return ["{partner}: My order! (%s) You're the best. +6 Happiness" % PACKAGE_FLAVOR[(day_count + raccoon_pets) % PACKAGE_FLAVOR.size()]]

func loot_name(id: String) -> String:
	if id == "package":
		return "{partner}'s package"
	if id == "meds":
		return "{partner}'s prescription"
	return "the " + str(Errands.LABELS.get(id, id)).to_lower()

func pirate_bag_loot() -> String:

	if int(inventory.get("meds", 0)) > 0:
		return "meds"
	if int(inventory.get("package", 0)) > 0:
		return "package"
	if errand["status"] == "fetched":
		for id in errand["got"]:
			if id != "meds" and int(inventory.get(id, 0)) > 0:
				return str(id)
	return ""

func pirate_alive() -> bool:
	for e in live_enemies():
		if e.kind == "pirate":
			return true
	return false

func pirate_allowed() -> bool:

	return day_count >= 2 and phase() != "Night" and not pirate_alive() and (porch_pkg or pirate_bag_loot() != "")

func pirate_snatch(e: Node, where: String) -> void:
	var item: = ""
	if where == "porch" and porch_pkg:
		porch_pkg = false
		item = "package"
	elif where == "bag":
		item = pirate_bag_loot()
		if item != "":
			inventory[item] = int(inventory.get(item, 0)) - 1
	if item == "":
		e.state = "leave"
		e.st = 2.5
		e.say("Aw, nothing good.")
		return
	e.loot = item
	e.state = "flee"
	e.st = 16.0 if e.has_meta("cold_open") else 10.0   # a new player's first chase: room to catch him
	e.say(PIRATE_TAUNTS[randi() % PIRATE_TAUNTS.size()])
	player.carrying = int(inventory.get("honey buns", 0)) > 0
	_toast("%s snatches %s! Oh hell no. I give chase." % [e.display_name(), Cast.T(loot_name(item))])

func pirate_defeated(e: Node, cash: int) -> String:
	var loot: = str(e.loot)
	var msg: = "%s is down. +$%d" % [e.display_name(), cash]
	if loot != "":
		inventory[loot] = int(inventory.get(loot, 0)) + 1
		e.loot = ""
		msg = "%s is down! I get %s back. +$%d" % [e.display_name(), Cast.T(loot_name(loot)), cash]
		if not achievements.has("Porch Defender"):
			achievements.append("Porch Defender")
			msg += "  ACHIEVEMENT: Porch Defender (better than the doorbell-cam subscription)"
	player.carrying = int(inventory.get("honey buns", 0)) > 0
	return msg

func _draw_porch_and_cans() -> void:

	if porch_pkg:
		Art.image(self, "package", PORCH_PT + Vector2(0, 4))

const CHA_LINES: = [
	"{partner}: ...why do you smell like a department store? Come here.",
	"{partner}: Is that {cologne}? Okay. OKAY. Who are you trying to impress? (Her. It's her.)",
	"{partner} leans in, takes a sniff, and just forgets what she was mad about.",
]
const MEAL_LINES: = [
	"{partner} made her chicken bake. I eat two plates standing up. +25 Energy",
	"{partner} makes tacos, then watches me eat like a proud nature documentary host. +25 Energy",
	"{partner} makes spaghetti with the good sauce. The jar with the fancy lid, man. +25 Energy",
]

func buff_active(k: String) -> bool:
	if not buffs.has(k):
		return false
	var b: Dictionary = buffs[k]
	return int(b["day"]) == day_count and clock < float(b["ends"])

func buff_left(k: String) -> float:
	return maxf(0.0, float(buffs[k]["ends"]) - clock) if buff_active(k) else 0.0

func buff_used_today(k: String) -> bool:
	return int(buff_days.get(k, -1)) == day_count

func active_buffs() -> Array:
	var out: Array = []
	for k in Buffs.ORDER:
		if buff_active(k):
			out.append(k)
	return out

func grant_buff(k: String, mins: float) -> bool:

	if buff_used_today(k):
		return false
	buff_days[k] = day_count
	buffs[k] = {"day": day_count, "ends": clock + mins }
	apply_gear()
	if Buffs.ORDER.all(func (b): return buff_used_today(str(b))):
		var a: = _unlock("Fully Buffed Boyfriend")
		if a != "":
			_toast(a)
	return true

func charisma() -> int:

	return 1 if buff_active("charisma") else 0

func price_mult() -> float:
	return Buffs.CHA_PRICE if charisma() > 0 else 1.0

func charisma_tips(tips: int) -> int:
	return int(ceil(tips * Buffs.CHA_TIP)) + 2 if charisma() > 0 else 0

func gain_happy(x: float) -> float:
	var g: = x * (Buffs.CHA_HAPPY if charisma() > 0 and x > 0.0 else 1.0)
	if glow_active() and x > 0.0:
		g *= Dates.GLOW_HAPPY
	var before: = happiness
	happiness = clampf(happiness + g, 0.0, 100.0)
	return happiness - before

func _buff_refusal(k: String) -> String:
	if mood_kind() == "upset":
		return "{partner}: \"Absolutely not. You know why.\" (%s)" % upset_reason()
	if mood_kind() == "fussy" and k != "charisma":
		var bnc: = bounce(Moods.FUSSY_BUFF)
		if bnc != "":
			return bnc
	if buff_used_today(k):
		return {"speed": "{partner}: My feet already did their shift today, babe. Tomorrow.",
			"defense": "{partner}: I already got all the good ones today. Let them... ripen.",
			"charisma": "I already reek of {cologne}. Any more and the EPA gets involved.",
			"strength": "Already ate. {partner}: \"There's more tomorrow, greedy. I love that you love it.\"" }.get(k, "Tomorrow.")
	if happiness < Buffs.MIN_HAPPY:
		return "{partner} needs a little more from me first. (Happiness %d/%d. She's been carrying a lot.)" % [int(happiness), int(Buffs.MIN_HAPPY)]
	return ""

func start_backwalk() -> void:
	var no: = _buff_refusal("speed")
	if no != "":
		_say([no])
		return
	_run_game(BackwalkScript.new(), _after_backwalk)

func _after_backwalk(_n: Node, s: float, _x: Array) -> void:
	advance_clock(15.0)
	var mins: = Buffs.duration(240.0, s)
	grant_buff("speed", mins)
	gain_happy(3.0)
	var lines: Array = ["%s SPEED up: +20%% move speed for %s." % ["My spine is a xylophone now." if s >= 0.75 else "Some cracks, some kidney.", _mins_text(mins)]]
	if s >= 1.0:
		var a: = _unlock("Chiropractor's Nightmare")
		if a != "":
			lines.append(a)
	_say(lines)

func mirror_menu() -> void:
	var opts: Array = []
	opts.append(["pop", "Let {partner} pop your blackheads (DEFENSE)", KEY_1])
	var sprays: = int(inventory.get("cologne", 0))
	if sprays > 0:
		opts.append(["spritz", "Spritz {cologne} (%d left) (CHARISMA)" % sprays, KEY_2])
	opts.append(["no", "Never mind", KEY_ESCAPE])
	var body: Array = ["I look like hell. Mirror agrees."]
	if sprays <= 0:
		body.append("({cologne} is sold at {pharmacy} and {grocery}.)")
	_menu("MIRROR", body, opts, func (id: String) -> void:
		if id == "pop":
			start_blackheads()
		elif id == "spritz":
			spritz_cologne())

func start_blackheads() -> void:
	var no: = _buff_refusal("defense")
	if no != "":
		_say([no])
		return
	var g: = BlackheadScript.new()
	g.ctx = {"seed": day_count * 31 + wordle_seed }
	_run_game(g, _after_blackheads)

func _after_blackheads(_n: Node, s: float, _x: Array) -> void:
	advance_clock(10.0)
	var mins: = Buffs.duration(300.0, s)
	grant_buff("defense", mins)
	gain_happy(4.0)
	_say(["{partner} wipes her hands on my shirt, deeply satisfied. Pore-fect skin: DEFENSE up, -25%% damage taken for %s." % _mins_text(mins),
		"{partner}: \"Same time tomorrow. I saw one on your ear.\""])

func spritz_cologne() -> void:
	if int(inventory.get("cologne", 0)) <= 0:
		return
	if buff_used_today("charisma"):
		_say([_buff_refusal("charisma")])
		return
	inventory["cologne"] -= 1
	grant_buff("charisma", Buffs.CHARISMA_MINS)
	advance_clock(1.0)
	var lines: Array = ["*psst psst* I hit myself with {cologne}. Notes of leather, venture capital and Applebee's parking lot. CHARISMA 6 hrs: 20% off stores, bigger tips, +25% {partner} happiness."]
	text("madison", "madison", "who are you trying to impress. it's working. come home")
	unread["madison"] = true
	ping_t = 2.0
	var a: = _unlock("Smells Like Money")
	if a != "":
		lines.append(a)
	_say(lines)

func meal_available() -> bool:
	return meal_day != day_count and clock >= 1020.0 and clock < 1320.0 and happiness >= Buffs.MIN_HAPPY

func eat_her_meal() -> void:
	if not meal_available():
		return
	meal_day = day_count
	energy = minf(energy_cap(), energy + energy_gain(25.0))
	advance_clock(20.0)
	var msg: String = MEAL_LINES[day_count % MEAL_LINES.size()]
	if grant_buff("strength", Buffs.STRENGTH_MINS):
		msg += ". STRENGTH up: +25% damage for 5 hrs"
	_toast(msg)

func _mins_text(mins: float) -> String:
	var h: = int(mins) / 60
	var mm: = int(mins) % 60
	return ("%d hr %02d min" % [h, mm]) if h > 0 else ("%d min" % mm)

func _draw_mat_and_mirror() -> void:

	for i in mini(bills.size(), 4):
		draw_rect(Rect2(MAIL_R.position + Vector2(2 + i * 3, -3 - i), Vector2(8, 5)), Color("#f4f0e0"))
		draw_rect(Rect2(MAIL_R.position + Vector2(2 + i * 3, -3 - i), Vector2(8, 5)), Color("#c03030") if i == 0 else Color("#8a8a8a"), false, 1.0)
	if int(inventory.get("cologne", 0)) > 0:
		draw_rect(Rect2(MIRROR_R.position.x - 4, MIRROR_R.end.y + 1, 4, 6), Color("#e0b040"))

const DATE_THANKS: = {
	"akarui": "best date. you remembered the ICE. who are you. <3",
	"symphony": "I can't believe you didn't fall asleep during the lullaby. (you almost did. I saw.) love you",
}

func glow_active() -> bool:
	return glow_day >= day_count

func date_new_day() -> Array:
	var out: Array = []
	if str(date_invite["kind"]) != "" and int(date_invite["expires"]) < day_count:
		date_invite = Dates.new_invite()
		out.append("{partner} moves date night to 'someday' on the shared calendar. With a sad little face. (I skipped it.)")
		set_upset("date")
	if life_events and str(date_invite["kind"]) == "" and mood_kind() != "upset" and day_count - int(date_stats["last_day"]) >= Dates.COOLDOWN and happiness >= Dates.INVITE_HAPPY:
		var nk: = Dates.next_kind(date_stats, day_count)
		if nk != "":
			invite_date(nk)
			out.append("Phone buzzes. {partner}, about DATE NIGHT. (Check your phone.)")
	return out

func invite_date(kind: String) -> void:
	date_invite = {"kind": kind, "day": day_count, "expires": day_count + Dates.INVITE_DAYS - 1 }
	var body: = "date night?? {date_spot_sushi} downtown, sushi + boba. tonight or tomorrow, we leave between 5 and 9. figure out who's watching {baby} <3"
	if kind == "symphony":
		body = "I got us {orchestra} tickets at {symphony_hall}!! ($%d, you're paying. kidding. you're paying.) tonight or tomorrow, leave by 9. dress NICE. and find a sitter" % Dates.TICKETS
	text("madison", "madison", body)
	unread["madison"] = true
	ping_t = 2.0

func date_ready() -> bool:
	var k: = str(date_invite["kind"])
	return k != "" and location == "home" and day_count >= int(date_invite["day"]) and day_count <= int(date_invite["expires"]) and clock >= Dates.WINDOW[0] and clock < Dates.WINDOW[1]

func date_quest_text() -> String:
	var k: = str(date_invite["kind"])
	if k == "":
		return ""
	if int(date_invite["expires"]) == day_count:
		return "DATE NIGHT tonight: %s (leave 5-9 PM)" % Dates.NAMES[k]
	return "Date night: %s, tonight or tomorrow" % Dates.NAMES[k]

func jen_fee() -> int:
	return 0 if wordle_daily_done() else Dates.JEN_FEE

func date_menu() -> void:
	var k: = str(date_invite["kind"])
	if mood_kind() == "fussy":
		var bnc: = bounce("{partner}: \"Actually... I don't know if I want to go out. No, I do. Ask me again in five minutes.\"")
		if bnc != "":
			_say([bnc])
			return
	var lines: Array = ["{partner}: \"Date night! %s. Who's watching {baby}?\"" % Dates.NAMES[k]]
	if k == "symphony":
		lines.append("Tickets: $%d (I pay at the door)." % Dates.TICKETS)
	_menu("DATE NIGHT", lines, [
		["jen", "Text {sister} to babysit (%s)" % ("free: you did her {wordle}" if jen_fee() == 0 else "$%d: you didn't do her {wordle}" % jen_fee()), KEY_1],
		["sitter", "Book {sitter_app} ($%d)" % Dates.SITTER_COST, KEY_2],
		["none", "No sitter? Just go!", KEY_3],
		["later", "Not yet", KEY_ESCAPE]], func (id: String) -> void:
			if id == "later":
				_say(["{partner}: \"Okay. Don't forget. I mean it.\""])
			else:
				start_date(k, id))

func sitter_cost(how: String) -> int:
	return jen_fee() if how == "jen" else (Dates.SITTER_COST if how == "sitter" else 0)

func start_date(kind: String, how: String, extra: Dictionary = {}) -> bool:
	if how == "none":
		_say(["I can't leave {baby} with the cats. {cat1} is not CPR certified.", "(Text {sister} or book {sitter_app}.)"])
		return false
	var bus: = fare_for(2) * 2 if kind == "akarui" else 0
	var need: = sitter_cost(how) + bus + (Dates.TICKETS if kind == "symphony" else 20)
	if money < need:
		_say(["I've got $%d. Sitter + %s runs about $%d. {partner}: \"...We could just do couch time.\"" % [money, "tickets" if kind == "symphony" else "dinner", need]])
		return false
	money -= sitter_cost(how)
	if how == "jen":
		text("sister", "me", "can you watch {baby} tonight? date night")
		text("sister", "sister", "Did you do my {wordle} today? Yes? Fine. Free. She's my favorite person anyway. Not you. Her." if jen_fee() == 0 else "Did you do my {wordle}? No? $%d. And you're doing it tomorrow. On your way, I'm bringing snacks." % Dates.JEN_FEE)
	date_stats["sitter_day"] = day_count
	date_stats["sitter"] = how
	if kind == "symphony":
		money -= Dates.TICKETS
	money -= bus
	var g: Node = SymphonyScript.new() if kind == "symphony" else AkaruiScript.new()
	g.m = self
	g.ctx = {"seed": hash(wordle_seed + day_count * 17), "audio": not OS.has_feature("headless") and DisplayServer.get_name() != "headless" }
	g.ctx.merge(extra, true)
	_run_game(g, _after_date.bind(kind))
	return true

func _after_date(n: Node, s: float, _x: Array, kind: String) -> void:
	var lines: Array = []
	var spent: = int(n.spent)
	if spent > 0:
		lines.append_array(charge(spent, "date night"))
	advance_clock(float(Dates.HOURS[kind]))
	var before: = happiness
	gain_happy(float(Dates.HAPPY[kind]) * (0.5 + 0.5 * s))
	var gained: = happiness - before
	glow_day = day_count + Dates.GLOW_DAYS
	date_stats["count"] = int(date_stats["count"]) + 1
	date_stats[kind] = int(date_stats[kind]) + 1
	date_stats["last_day"] = day_count
	date_stats["best"] = maxf(float(date_stats["best"]), s)
	date_invite = Dates.new_invite()
	location = "home"
	player.position = INT_SPAWN
	_set_camera()
	_sync_world()
	var what: = "{orchestra} night at {symphony_hall}" if kind == "symphony" else "Sushi + boba at {date_spot_sushi}"
	lines.push_front("%s: %s. +%d Happiness%s" % [what, "a TEN" if s >= 0.85 else ("a solid date" if s >= 0.55 else "a 'learning experience'"), int(round(gained)), (" (spent $%d)" % spent) if spent > 0 else ""])
	lines.append("DATE NIGHT GLOW: through tomorrow, +20%% happiness gains and -10%% damage taken. Next date in %d days." % Dates.COOLDOWN)
	if kind == "symphony":
		lines.append(_unlock("Culture Vulture"))
		if not bool(n.clapped_between) and int(n.snores) == 0:
			lines.append(_unlock("Didn't Clap Between Movements"))
	else:
		lines.append(_unlock("Boba Bae"))
		if int(n.order_right) == Dates.SLOTS.size():
			lines.append(_unlock("Remembered Her Order"))
	if int(date_stats["count"]) >= 3:
		lines.append(_unlock("Date Night Regular"))
	lines.append_array(make_up())
	text("madison", "madison", DATE_THANKS[kind] if s >= 0.55 else "that was... a night. thank you for trying <3")
	unread["madison"] = true
	_say(lines.filter(func (l): return str(l) != ""))
	save_game()

func drained() -> bool:
	return int(plasma["drained_day"]) == day_count

func energy_cap() -> float:
	return Life.DRAIN_MAX if drained() else 100.0

func energy_gain(x: float) -> float:
	return x * (Life.DRAIN_REGEN if drained() else 1.0)

func open_plasma() -> void:
	if busy():
		return
	var why: = Life.plasma_block(plasma, day_count, day_i, clock, energy)
	match why:
		"closed":
			_say(["{plasma}'s closed (8 AM - 6 PM). Sign on the door: 'Your blood, our margins!'"])
		"gap":
			_say(["{phlebotomist}: \"Back already? Love the hustle. Corporate says your blood needs 48 hours to 're-monetize.'\""])
		"week":
			_say(["{phlebotomist}: \"Twice this week. FDA says that's your limit. Our shareholders cried. See you Monday.\""])
		"energy":
			_say(["Iron check: fail. {phlebotomist}: \"Your iron is 'honey bun.' Eat something. We need you profitable.\""])
		_:
			var g: = PlasmaScript.new()
			_run_game(g, _after_plasma)

func _after_plasma(_n: Node, s: float, _x: Array) -> void:
	var pay: = Life.plasma_pay(plasma, day_i)
	var promo: = int(plasma["visits"]) < Life.PLASMA_PROMO.size()
	if s >= 1.0:
		pay += 5
	plasma["visits"] = int(plasma["visits"]) + 1
	(plasma["days"] as Array).append(day_count)
	(plasma["weeks"] as Array).append(Life.week_of(day_i))
	plasma["drained_day"] = day_count
	money += pay
	energy = minf(maxf(1.0, energy - 10.0), Life.DRAIN_MAX)
	advance_clock(Life.PLASMA_MINUTES - (20.0 if s >= 1.0 else 0.0))
	apply_gear()
	var lines: Array = ["Donation done! +$%d%s%s. They sell it for 20x that. I get a juice box. Heart-shaped cookie. Yay." % [pay, " (new-donor promo, visit %d of %d)" % [int(plasma["visits"]), Life.PLASMA_PROMO.size()] if promo else "", ", +$5 speedy-donor bonus" if s >= 1.0 else ""],
		"DRAINED rest of today: slower, weaker, I take more damage, food does less, energy capped at %d. Easy does it." % int(Life.DRAIN_MAX)]
	lines.append(_unlock("First-Time Donor"))
	if int(plasma["visits"]) >= 5:
		lines.append(_unlock("Plasma Regular"))
	_say(lines.filter(func (l): return str(l) != ""))

func mood_kind() -> String:
	if str(mood["kind"]) == "fussy" and int(mood["day"]) != day_count:
		return ""
	return str(mood["kind"])

func upset_reason() -> String:
	return {"errand": "I missed her errand.", "date": "I skipped date night.", "fryer": "I came home smelling like the fryer.",
		"rent": "Rent was late.", "promise": "I forgot what I promised.", "bill": "I ignored a bill and collections called her." }.get(str(mood["cause"]), "You know why.")

func set_upset(cause: String) -> void:

	var info: Dictionary = Moods.UPSET.get(cause, {})
	var was: = mood_kind() == "upset"
	mood["kind"] = "upset"
	mood["cause"] = cause
	mood["day"] = day_count
	restless_seen[cause] = 3
	if was:
		return
	happiness = maxf(0.0, happiness - float(info.get("hit", 0.0)))
	var tx: = str(info.get("text", ""))
	if tx != "" and cause != "errand":
		text("madison", "madison", tx)
		unread["madison"] = true
		ping_t = 2.0

func make_up() -> Array:
	if mood_kind() != "upset":
		return []
	mood["kind"] = ""
	mood["cause"] = ""
	quest_wait = minf(quest_wait, Moods.QUEST_WARN[0])
	var out: Array = [Moods.MAKEUP_LINES.pick_random()]
	var a: = _unlock("Made Up")
	if a != "":
		out.append(a)
	return out

func bounce(line: String = "") -> String:

	if mood_kind() != "fussy" or int(mood["bounces"]) <= 0:
		return ""
	mood["bounces"] = int(mood["bounces"]) - 1
	advance_clock(5.0)
	if line != "":
		return line
	return Moods.RUNAROUND[(day_count + int(mood["bounces"])) % Moods.RUNAROUND.size()]

func mood_new_day() -> Array:
	var out: Array = []
	if str(mood["kind"]) == "fussy":
		mood["kind"] = ""
	if mood_kind() == "upset":
		return out
	if life_events and not falcor_grief() and Moods.roll_fussy(day_count, wordle_seed, int(mood["last_fussy"])):
		start_fussy()
		out.append("{partner} wakes up having a rough one. Not my fault. I gotta be gentle with her today.")
	return out

func start_fussy() -> void:
	mood = {"kind": "fussy", "day": day_count, "cause": "", "bounces": Moods.BOUNCES, "swapped": false, "last_fussy": day_count }
	text("madison", "madison", Moods.FUSSY_TEXTS[day_count % Moods.FUSSY_TEXTS.size()])
	unread["madison"] = true
	ping_t = 2.0

func fussy_swap() -> void:

	if mood_kind() != "fussy" or bool(mood["swapped"]) or clock < 720.0:
		return
	if str(errand.get("kind", "")) != "grocery" or str(errand.get("status", "")) != "active":
		return
	mood["swapped"] = true
	var items: Dictionary = errand["items"]
	var got: Dictionary = errand["got"]
	var out_id: = ""
	for k in items:
		if not got.has(k) and k != "honey buns":
			out_id = str(k)
			break
	var in_id: = ""
	for k in ["treats", "ensure", "eggs", "cream", "flour"]:
		if not items.has(k):
			in_id = k
			break
	if out_id == "" or in_id == "":
		return
	items.erase(out_id)
	items[in_id] = 1
	errand["budget"] = Errands.budget_for(items)
	if str(errand.get("oos", "")) == out_id:
		errand["oos"] = ""
	text("madison", "madison", Moods.FUSSY_SWAP % [str(Errands.LABELS.get(in_id, in_id)).to_lower(), str(Errands.LABELS.get(out_id, out_id)).to_lower()])
	unread["madison"] = true
	ping_t = 2.0
	_toast("*bzzt* {partner} changes the list. Again. (No penalty. It's one of those days.)")

const QUEST_HINTS: = {"honey buns": "She keeps eyeing the empty honey bun box. Like it owes her money.", "formula": "She keeps shaking the formula can. Sounds empty, man.",
	"diapers": "She's counting diapers. Out loud. There are two.", "cake": "She's watching a baking show. Aggressively." }

func restless() -> Dictionary:

	if mood_kind() == "upset":
		return {"level": 3, "cause": str(mood["cause"]), "hint": upset_reason() }
	var best: = {"level": 0, "cause": "", "hint": "" }
	var c: Array = []
	if Errands.pending(errand) and str(errand["status"]) in ["active", "fetched"]:
		var left: = float(errand["due"]) - clock
		var hint: = "She keeps checking the clock. That %s run's due at %s." % ["pharmacy" if errand["kind"] == "pharmacy" else "grocery", Errands.due_text(errand)]
		if left <= Moods.ERRAND_WARN[1]:
			c.append([2, "errand", hint])
		elif left <= Moods.ERRAND_WARN[0]:
			c.append([1, "errand", hint])
	if quest == 1:
		var qh: String = QUEST_HINTS.get(quest_kind, "She keeps looking at me like I forgot something.")
		if quest_wait >= Moods.QUEST_WARN[1]:
			c.append([2, "promise", qh])
		elif quest_wait >= Moods.QUEST_WARN[0]:
			c.append([1, "promise", qh])
	if str(date_invite["kind"]) != "" and int(date_invite["expires"]) == day_count and clock >= 1140.0:
		c.append([2 if clock >= 1200.0 else 1, "date", "She's sitting on the couch in her going-out top. Just... sitting."])
	if days_until_rent() == 1 and money < rent_due():
		c.append([2 if clock >= 1200.0 else 1, "rent", "She's doing the budget app with The Face. Rent's due tomorrow and I'm $%d short." % (rent_due() - money)])
	if fryer_smell and location == "home":
		c.append([1, "fryer", "She sniffs the air. Then sniffs it again. (Shower?)"])
	if happiness < 30.0:
		c.append([2, "low", "She's quiet. Long day for her too."])
	for x in c:
		if int(x[0]) > int(best["level"]):
			best = {"level": int(x[0]), "cause": str(x[1]), "hint": str(x[2]) }
	return best

func restless_notify() -> void:
	var r: = restless()
	restless_level = int(r["level"])
	if not life_events:
		return
	var cause: = str(r["cause"])
	if restless_level <= 0 or restless_level >= 3 or int(restless_seen.get(cause, 0)) >= restless_level:
		return
	restless_seen[cause] = restless_level
	if restless_level == 1:
		_toast("{partner}'s getting restless. " + str(r["hint"]))
	else:
		var reply: String = Moods.SHORT_REPLIES[(day_count + cause.length()) % Moods.SHORT_REPLIES.size()]
		text("madison", "madison", reply)
		unread["madison"] = true
		ping_t = 2.0
		sigh_t = 8.0
		_toast("{partner} texts me: \"%s\" %s" % [reply, str(r["hint"])])

func mood_face() -> String:

	if mood_kind() == "upset":
		return "upset"
	if restless_level >= 2:
		return "short"
	if restless_level == 1:
		return "restless"
	if mood_kind() == "fussy":
		return "fussy"
	return "happy" if happiness >= 70.0 else ("meh" if happiness >= 40.0 else "pissed")

func mood_label() -> String:
	return {"upset": "Hurt", "short": "Tired", "restless": "Restless", "fussy": "Rough day", "happy": "Happy", "meh": "Meh", "pissed": "Stressed" }[mood_face()]

func formula_extra() -> int:
	return Life.SPIKE if formula_spike_day >= day_count else 0

func charge(amount: int, why: String) -> Array:

	if amount <= 0:
		return []
	AudioScript.sfx("cash")
	if money >= amount:
		money -= amount
		return []
	var short: = amount - money
	money = 0
	rent_debt += short + Life.OVERDRAFT
	return ["OVERDRAFT on %s: I'm $%d short, so they tack on $%d for the crime of being short. Monday's problem." % [why, short, Life.OVERDRAFT]]

func curveball_new_day() -> Array:
	var out: Array = []
	var still: Array = []
	for o in owed:
		if int(o["day"]) <= day_count:
			var tx: = str(o["text"])
			out.append(tx % int(o["fee"]) if "%d" in tx else tx)
			out.append_array(charge(int(o["fee"]), str(o["id"])))
			if float(o.get("happy", 0.0)) > 0.0:
				happiness = maxf(0.0, happiness - float(o["happy"]))
			if str(o.get("cause", "")) != "":
				set_upset(str(o["cause"]))
		else:
			still.append(o)
	owed = still
	var keep: Array = []
	for b in bills:
		if int(b["due"]) < day_count:
			out.append("I never open the '%s' mail. Unopened, it's a rumor. Opened, it's a verdict. It decides anyway." % str(Life.EVENTS[str(b["id"])]["title"]))
			out.append_array(resolve_bill(str(b["id"]), "auto"))
		else:
			keep.append(b)
	bills = keep
	var id: = Life.roll_event(day_count, wordle_seed, event_days, has_car) if life_events and not daily_headline() else ""
	if id != "":
		out.append_array(deliver_curveball(id))
	return out

func deliver_curveball(id: String) -> Array:
	var e: Dictionary = Life.EVENTS[id]
	event_days[id] = day_count
	if e.has("gain"):
		money += int(e["gain"])
		return ["GOOD NEWS: %s %s" % [e["title"], e["body"]]]
	if e.has("loss"):
		var ll: Array = ["BAD LUCK: %s. %s" % [e["title"], e["body"]]]
		ll.append_array(charge(int(e["loss"]), str(e["title"]).to_lower()))
		return ll
	if e.has("info"):
		formula_spike_day = day_count + Life.SPIKE_DAYS - 1
		return ["NEWS: %s. %s (Kwik-N-Go and the pharmacy aisle.)" % [e["title"], e["body"]]]
	bills.append({"id": id, "day": day_count, "due": day_count if e.has("gig") else day_count + Life.DECIDE_DAYS })
	_toast("New mail: %s. (Mail table by the door.)" % e["title"])
	return ["MAIL: %s. Decide at the mail table by the door%s." % [e["title"], " (today only)" if e.has("gig") else " within %d days" % Life.DECIDE_DAYS]]

func mail_menu() -> void:
	if bills.is_empty():
		_say(["I check the mail. A pizza coupon. A credit card at 34% APR that already loves me. I keep the coupon. It wants nothing back."])
		return
	var b: Dictionary = bills[0]
	var id: = str(b["id"])
	var e: Dictionary = Life.EVENTS[id]
	var opts: Array = []
	var keys: = [KEY_1, KEY_2, KEY_3, KEY_4]
	var ch: = Life.choices(id)
	for i in ch.size():
		opts.append([ch[i][0], ch[i][1], keys[i]])
	opts.append(["later", "Later", KEY_ESCAPE])
	var lines: Array = [str(e["body"])]
	if bills.size() > 1:
		lines.append("(%d more in the pile.)" % (bills.size() - 1))
	_menu(str(e["title"]).to_upper(), lines, opts, func (c: String) -> void:
		if c != "later":
			var res: = resolve_bill(id, c)
			if not res.is_empty():
				_say(res))

func resolve_bill(id: String, choice: String) -> Array:
	var e: Dictionary = Life.EVENTS[id]
	var out: Array = []
	if choice == "auto":
		choice = "accept" if e.has("hike") else ("decline" if e.has("gig") else "ignore")
	match choice:
		"pay":
			if money < int(e["cost"]):
				return ["I've got $%d. It's $%d. (A payment plan costs more. That's the business model.)" % [money, int(e["cost"])]]
			money -= int(e["cost"])
			bills_paid += 1
			out.append("I pay it. %s, $%d. Adulting. Gross." % [e["title"], int(e["cost"])])
			if bills_paid >= 3:
				out.append(_unlock("Adulting"))
			if id == "phone":
				phone_cracked = false
		"plan":
			var pl: Array = e["plan"]
			plans.append({"id": id, "per": int(pl[1]), "left": int(pl[0]) })
			out.append("Payment plan: $%d every Monday for %d weeks ($%d total; $%d of that is them being 'patient' with me)." % [int(pl[1]), int(pl[0]), int(pl[0]) * int(pl[1]), int(pl[0]) * int(pl[1]) - int(e["cost"])])
		"ignore":
			var ig: Dictionary = e["ignore"]
			if id == "phone":
				phone_cracked = true
				out.append("Living with the crack. {phone} has a spiderweb now. It's fine. It's vintage.")
			elif int(ig["fee"]) == 0:
				happiness = maxf(0.0, happiness - float(ig.get("happy", 0.0)))
				freya_trust = maxi(0, freya_trust - int(ig.get("trust", 0)))
				energy = maxf(1.0, energy - float(ig.get("energy", 0.0)))
				out.append(str(ig["text"]))
			else:
				owed.append({"id": id, "day": day_count + int(ig["days"]), "fee": int(ig["fee"]), "text": str(ig["text"]), "happy": float(ig["happy"]), "cause": str(ig["cause"]) })
				out.append("I toss it in the 'later' pile. Later always comes. With interest.")
		"accept":
			if e.has("hike"):
				rent_bump += int(e["hike"])
				out.append("Rent is now $%d a week." % (RENT + rent_bump))
			else:
				if fmod(clock, 1440.0) >= 1080.0 or energy < 35.0:
					return ["I'm too late or too wrecked for a 4-hour catering gig. (Before 6 PM, 35+ Energy.)"]
				money += int(e["gig"])
				energy = maxf(1.0, energy - 30.0)
				fryer_smell = true
				advance_clock(240.0)
				out.append("Catering gig done: +$%d. I smell like a chafing dish. A bride cried at me. Paid, though." % int(e["gig"]))
		"negotiate":
			var rng: = RandomNumberGenerator.new()
			rng.seed = hash(wordle_seed + day_count * 41)
			if charisma() > 0 or rng.randf() < 0.3:
				rent_bump += 5
				out.append("I negotiate%s. Landlord: \"Fine. $5, not $15. Don't tell the other units.\"" % (" (and smell incredible)" if charisma() > 0 else ""))
			else:
				rent_bump += int(e["hike"])
				out.append("He raises it anyway. Says it hurts him more than me. Says it from the boat.")
		"decline":
			out.append("I pass on the gig. My feet send their regards.")
	bills = bills.filter(func (x): return str(x["id"]) != id)
	return out

func car_unlocked() -> bool:
	return bool(story.get("ending_seen", false))

func pass_active() -> bool:
	return Transit.pass_active(bus_pass_until, day_count)

func fare_for(people: int) -> int:
	return Transit.fare(people, bus_pass_until, day_count, has_car)

func bus_stops() -> Array:
	var out: Array = []
	for id in Transit.ORDER:
		out.append({"id": "bus_" + id, "pos": Transit.STOPS[id]["pos"], "r": 14.0, "label": ("Minivan (%s)" if has_car else "Bus stop: %s") % Transit.STOPS[id]["name"] })
	return out

func bus_menu(from: String) -> void:
	if not has_car and not Transit.running(clock):
		_say(["Next bus is 5:30 AM. City budget went to a stadium. Bench is cold. Guess I'm a walker now."])
		return
	var opts: Array = []
	var keys: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
	for id in Transit.ORDER:
		if id != from:
			var cost: = fare_for(1)
			opts.append(["to_" + id, "%s to %s%s" % ["Drive" if has_car else "Ride", Transit.STOPS[id]["name"], "" if has_car else (" ($%d)" % cost if cost > 0 else " (pass)")], keys[opts.size()]])
	if not has_car and not pass_active():
		opts.append(["pass", "Buy a 30-day pass ($%d)" % Transit.PASS_PRICE, keys[opts.size()]])
	if car_unlocked() and not has_car:
		opts.append(["car", "Buy the family minivan ($%d)" % Transit.CAR_PRICE, keys[mini(opts.size(), 4)]])
	opts.append(["walk", "Walk (free)", KEY_ESCAPE])
	var lines: Array = []
	if has_car:
		lines.append("I climb in the family minivan. Smells like goldfish crackers. It's perfect.")
	else:
		lines.append("Next bus in %d min. Fare $%d%s." % [int(Transit.wait_minutes(clock)), Transit.FARE, ", but my pass is good through day %d" % bus_pass_until if pass_active() else ""])
	_menu("BUS STOP: " + str(Transit.STOPS[from]["name"]).to_upper() if not has_car else "MINIVAN", lines, opts, func (c: String) -> void:
		if c == "pass":
			_say(buy_bus_pass())
		elif c == "car":
			_say(buy_car())
		elif c.begins_with("to_"):
			var r: = ride_bus(c.substr(3))
			if not r.is_empty():
				_say(r))

func buy_bus_pass() -> Array:
	if pass_active():
		return ["My pass is already good through day %d." % bus_pass_until]
	if money < Transit.PASS_PRICE:
		return ["The pass is $%d. I've got $%d. Walking builds character, or so the guy in the Tesla says." % [Transit.PASS_PRICE, money]]
	money -= Transit.PASS_PRICE
	bus_pass_until = day_count + Transit.PASS_DAYS - 1
	return ["30-day bus pass: -$%d. Unlimited rides through day %d. Local legend status, baby." % [Transit.PASS_PRICE, bus_pass_until]]

func buy_car() -> Array:
	if not car_unlocked():
		return ["{partner}: \"A car? With what money? We'll get there.\""]
	if has_car:
		return ["I already got the minivan. It's in the driveway. Shining. Sort of."]
	if money < Transit.CAR_PRICE:
		return ["Used minivan's $%d. I've got $%d. Keep saving. (Stonks can help. Or hurt.)" % [Transit.CAR_PRICE, money]]
	money -= Transit.CAR_PRICE
	has_car = true
	gain_happy(20.0)
	var out: Array = ["Bought a used minivan! -$%d. {partner} cries a little. {baby}'s car seat clicks in. +20 Happiness" % Transit.CAR_PRICE,
		"(Free, no-wait trips. Also: car problems are now possible. The dealership calls that 'ownership.')"]
	var a: = _unlock("Minivan Energy")
	if a != "":
		out.append(a)
	return out

func next_fact() -> String:
	fact_i += 1
	return FunFacts.pick(fact_i)

func ride_bus(to: String) -> Array:
	AudioScript.sfx("bus")
	if not Transit.STOPS.has(to):
		return []
	if not has_car and not Transit.running(clock):
		return ["No buses until 5:30 AM."]
	var cost: = fare_for(1)
	if money < cost:
		return ["Fare's $%d. I've got $%d. Walking's free. For now. Don't give 'em ideas." % [cost, money]]
	money -= cost
	var wait: = 0.0 if has_car else Transit.wait_minutes(clock)
	var ride: = Transit.CAR_MIN if has_car else Transit.RIDE_MIN
	advance_clock(wait + ride)
	location = "outside"
	player.position = Transit.STOPS[to]["pos"] + Vector2(0, 8)
	_set_camera()
	_sync_world()
	bus_rides += 1
	var out: Array = []
	if has_car:
		out.append("I drive the minivan to %s. %d minutes. I use my blinker. Like a damn dad." % [Transit.STOPS[to]["name"], int(ride)])
	else:
		out.append("I wait %d min, ride %d min to %s%s. %s" % [int(wait), int(ride), Transit.STOPS[to]["name"], (" (-$%d)" % cost) if cost > 0 else " (pass)", Transit.RIDE_LINES[bus_rides % Transit.RIDE_LINES.size()]])
	if randf() < 0.35:
		out.append(next_fact())
	if bus_rides >= 10:
		var a: = _unlock("Transit Legend")
		if a != "":
			out.append(a)
	return out

func bounty_menu() -> void:
	var lines: Array = ["THE 86 LIST. Chef's handwriting: 'If you see these people, you have my blessing.'"]
	if int(bounties["day"]) == day_count:
		lines.append("(I already ran a bounty today. Chef says one alley fight a day. HR is watching. HR is Chef.)")
	var opts: Array = []
	var keys: = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
	var i: = 0
	for e in Bounties.LIST:
		var id: = str(e["id"])
		var nm: = Cast.T(str(BossScript.BOSSES[id]["name"]))
		var beaten: bool = (bounties["beaten"] as Array).has(id)
		var why: = Bounties.locked_reason(e, combat.level, bounties["beaten"])
		var tag: = ("86'd - rematch $%d" % Bounties.payout(e, false)["cash"]) if beaten else ("$%d" % int(e["cash"]))
		if why != "":
			tag = "LOCKED: " + why
		lines.append("%s - %s" % [nm, str(e["crime"])])
		opts.append([id, "%s (%s)" % [nm, tag], keys[i]])
		i += 1
	opts.append(["leave", "Walk away", KEY_ESCAPE])
	_menu("THE 86 LIST", lines, opts, _on_bounty_menu)

func _on_bounty_menu(id: String) -> void:
	if id == "leave":
		return
	var e: = Bounties.entry(id)
	if e.is_empty():
		return
	var why: = Bounties.locked_reason(e, combat.level, bounties["beaten"])
	if why != "":
		_say(["Not yet. (%s.) This one's above my pay grade. Everything is above my pay grade." % why])
		return
	if int(bounties["day"]) == day_count:
		_say(["I already did one today. My knuckles need a union break."])
		return
	start_bounty(id)

func start_bounty(id: String) -> void:
	if busy() or _world_gate(func () -> void: start_bounty(id)):
		return
	show_loading()
	clear_enemies()
	arena_id = "alley"
	arena_mode = "bounty"
	bounty_id = id
	location = "arena"
	player.position = ARENA_SPAWN
	player.stun_t = 0.0
	_set_camera()
	energy = 100.0
	var b: = BossScript.new()
	b.kind = id
	b.m = self
	b.position = ARENA_ORIGIN + Vector2(160, 80)
	add_child(b)
	arena_boss = b
	b.set_physics_process(not busy())
	if id != "grease":  # the side-quest boss brings its own intro (start_grease_fight)
		_say(["Out back of the {fork_nick}. Dumpster, puddles, a guy from the 86 List. Romantic.", str(BossScript.BOSSES[id]["intro"])])
	_sync_world()

func bounty_defeated(b: Node) -> void:
	var id: = str(b.kind)
	var e: = Bounties.entry(id)
	var first: bool = not (bounties["beaten"] as Array).has(id)
	var pay: = Bounties.payout(e, first)
	kills[id] = int(kills.get(id, 0)) + 1
	combat.gain_xp("boss_bounty", maxi(int(e["lvl"]), combat.level - 1))
	clear_enemies()
	arena_boss = null
	bounties["day"] = day_count
	money += int(pay["cash"])
	gear["scraps"] = int(gear["scraps"]) + int(pay["scrap"])
	var lines: Array = [str(BossScript.BOSSES[id]["defeat"]),
		"86'd. Bounty: $%d and %d scrap.%s" % [int(pay["cash"]), int(pay["scrap"]), "" if first else " (Rematch rate. Chef's cheap.)"]]
	if first:
		(bounties["beaten"] as Array).append(id)
		if id == "dasher":
			lines.append(Gear.grant_piece(gear, false))
		if (bounties["beaten"] as Array).size() >= Bounties.LIST.size() and not achievements.has(Bounties.ACH_ALL):
			achievements.append(Bounties.ACH_ALL)
			lines.append("ACHIEVEMENT UNLOCKED: %s (the whole wall is red X's. Chef framed it.)" % Bounties.ACH_ALL)
	apply_gear()
	arena_id = ""
	bounty_id = ""
	_leave_arena()
	player.position = BOARD_PT + Vector2(0, 8)
	_set_camera()
	_say(lines)
	save_game()

func bounty_lose() -> void:
	var was_grease: = bounty_id == "grease"
	clear_enemies()
	arena_boss = null
	arena_id = ""
	bounty_id = ""
	if not was_grease:
		bounties["day"] = day_count
	_leave_arena()
	player.position = BOARD_PT + Vector2(0, 8)
	_set_camera()
	energy = 35.0
	if was_grease:
		_say(["I wake up face-down by the drain, glazed like a donut. It's gone back under. The stain on the 86 List is still wet.", "Try again another night."])
		save_game()
		return
	_say(["I end up laid out by the dumpster. Grill-Boy finds me on his smoke break and takes a selfie. With me. Not for me.", "Bounty's still up. Try again tomorrow."])
	save_game()

func waffle_regular_tonight() -> bool:
	var n: = int(waffle_data["shifts"]) + 1
	if n < 3:
		return false
	return int(waffle_data["regular_beaten"]) == 0 or n % 3 == 0

func waffle_menu() -> void:
	if shifts_worked < WAFFLE_MIN_SHIFTS:
		_say(["There's a Waffle Haus sign out by the interstate: 'NOW HIRING graveyard cook. Experience required.' They mean the life kind.",
			"(I gotta work %d more shift%s at the {fork_nick} first. They want a resume. My resume is a burn scar.)" % [WAFFLE_MIN_SHIFTS - shifts_worked, "" if WAFFLE_MIN_SHIFTS - shifts_worked == 1 else "s"]])
		return
	var c: = fmod(clock, 1440.0)
	if not (c >= 1260.0 or c < 60.0):
		_say(["Graveyard clock-in is 9 PM to 1 AM. Waffle Haus never closes, but the cook slot does. It's %s." % clock_text()])
		return
	if energy < 25.0:
		_say(["I'm too wiped for a graveyard. Even the coffee can't raise these dead."])
		return
	var lines: Array = ["So there's this WAFFLE HAUS out by the interstate. Open 24/7/365. The sign's never been off. Not even for tornadoes.",
		"Pay: $%d a plate + tips. Fire tickets on a grill (E / A), plate them when READY before they burn. 2 AM the bars close." % WaffleScript.BASE_PAY,
		"No sleep tonight. {partner}'s on baby duty alone and I start tomorrow tired. But it's real money."]
	if waffle_regular_tonight():
		lines.append("Dolores leans through the window: \"Earl's coming in tonight, hon. Earl don't leave till he's ready.\"")
	_menu("WAFFLE HAUS", lines, [["go", "Clock in (graveyard)", KEY_1], ["no", "Not tonight", KEY_2]], func (ch: String) -> void:
		if ch == "go":
			start_waffle())

func start_waffle() -> void:
	if busy() or _world_gate(func () -> void: start_waffle()):
		return
	show_loading()
	clear_enemies()
	arena_id = "waffle"
	arena_mode = "waffle"
	location = "arena"
	player.position = ARENA_ORIGIN + Vector2(160, 95)
	player.stun_t = 0.0
	player.shoes = "black"
	_set_camera()
	energy = minf(energy_cap(), energy + 25.0)
	waffle_node = WaffleScript.new()
	waffle_node.m = self
	waffle_node.regular_night = waffle_regular_tonight()
	add_child(waffle_node)
	_say(["Clocked in at Waffle Haus. Bottomless coffee. Employee perk. Only perk. +25 Energy",
		"Dolores (31 years in): \"Three grills, hon. Fire 'em, plate 'em, don't let 'em burn. And don't let the drunks hug you. They mean it.\""])
	_sync_world()

func waffle_spawn_regular() -> void:
	var b: = BossScript.new()
	b.kind = "regular"
	b.m = self
	b.position = ARENA_ORIGIN + Vector2(160, 150)
	add_child(b)
	arena_boss = b
	b.set_physics_process(not busy())
	_say(["So it's 5 AM. The bell on the door rings once. Dolores sets down a coffee without being asked.", str(BossScript.BOSSES["regular"]["intro"])])

func waffle_regular_defeated(b: Node) -> void:
	kills["regular"] = int(kills.get("regular", 0)) + 1
	combat.gain_xp("boss_regular", maxi(8, combat.level))
	arena_boss = null
	var first: = int(waffle_data["regular_beaten"]) == 0
	waffle_data["regular_beaten"] = int(waffle_data["regular_beaten"]) + 1
	var cash: = 60 if first else 30
	money += cash
	if waffle_node != null:
		waffle_node.on_regular_beaten()
	for e in live_enemies():
		enemy_gone(e)
	var lines: Array = [str(BossScript.BOSSES["regular"]["defeat"]), "Earl leaves $%d under the mug. Exact change. Plus a quarter. That's the tip." % cash]
	if first:
		if combat.grant_special("hashbrown"):
			lines.append("Earl stops at the door: \"Scattered, smothered, covered. Remember it, son.\" NEW SPECIAL: Hash Brown Hurricane (Q to swap).")
		if not achievements.has("Earl Approves"):
			achievements.append("Earl Approves")
			lines.append("ACHIEVEMENT UNLOCKED: Earl Approves")
	_say(lines)

func end_waffle(r: Dictionary) -> void:
	clear_enemies()
	arena_boss = null
	if waffle_node != null:
		waffle_node.queue_free()
	waffle_node = null
	arena_id = ""
	player.shoes = "red"
	_leave_arena()
	money += int(r["pay"])
	waffle_data["shifts"] = int(waffle_data["shifts"]) + 1
	waffle_data["best"] = maxi(int(waffle_data["best"]), int(r["delivered"]))
	var grade: = ShiftScript.grade_for(float(r["score"]))
	night_report = []
	if bool(r["ko"]):
		night_report.append("I get knocked out mid-shift at Waffle Haus. Dolores lets me 'rest my eyes' in booth 6 till sunrise. Half pay: $%d." % int(r["pay"]))
	else:
		night_report.append("Waffle Haus, 6 AM. Grade %s. Served %d of %d. Walked out: %d. Burnt: %d. Took home $%d (tips $%d)." % [grade, int(r["delivered"]), int(r["orders"]), int(r["walked"]), int(r["burnt"]), int(r["pay"]), int(r["tips"])])
		if grade == "S" and not achievements.has("Scattered, Smothered, Covered"):
			achievements.append("Scattered, Smothered, Covered")
			night_report.append("ACHIEVEMENT UNLOCKED: Scattered, Smothered, Covered (S grade on a graveyard)")
	happiness = maxf(0.0, happiness - 6.0)
	night_report.append("I roll home at 6:20 AM smelling like hash browns. {partner} did the 3 AM bottle alone. Note on the fridge: \"Proud of you. Shower. -{partner}\" -6 Happiness")
	_wake(55)

func _draw_waffle_sign_and_board(f: Font) -> void:

	var sp: = WAFFLE_SIGN_PT
	draw_rect(Rect2(sp + Vector2(-1, -20), Vector2(2, 20)), Color("#5a5a66"))
	var lit: = phase() == "Night" or phase() == "Evening"
	var box: = Rect2(sp + Vector2(-13, -33), Vector2(26, 13))
	draw_rect(box.grow(1), Color("#2a1a2e"))
	draw_rect(box, Color("#f8d232") if lit or int(t) % 2 == 0 else Color("#e0b828"))
	draw_string(f, box.position + Vector2(0, 6), "WAFFLE", HORIZONTAL_ALIGNMENT_CENTER, 26, 5, Color("#1a1418"))
	draw_string(f, box.position + Vector2(0, 12), "HAUS", HORIZONTAL_ALIGNMENT_CENTER, 26, 5, Color("#1a1418"))
	if lit:
		draw_rect(box.grow(3), Color(1, 0.85, 0.2, 0.12 + 0.05 * sin(t * 3.0)))
	draw_string(f, sp + Vector2(-14, -17), "-> I-80", HORIZONTAL_ALIGNMENT_CENTER, 28, 4, Color("#f0ead8"))

	var bp: = BOARD_PT + Vector2(-10, -20)
	draw_rect(Rect2(bp - Vector2(1, 1), Vector2(22, 14)), Color("#2a1a2e"))
	draw_rect(Rect2(bp, Vector2(20, 12)), Color("#b8864a"))
	for i in Bounties.LIST.size():
		var pp: = bp + Vector2(1.5 + (i % 3) * 6.2, 1.2 + (i / 3) * 5.4)
		draw_rect(Rect2(pp, Vector2(5, 4.4)), Color("#f4f0e8"))
		if (bounties["beaten"] as Array).has(str(Bounties.LIST[i]["id"])):
			draw_line(pp, pp + Vector2(5, 4.4), Color("#d02020"), 1.0)
			draw_line(pp + Vector2(5, 0), pp + Vector2(0, 4.4), Color("#d02020"), 1.0)
	draw_string(f, bp + Vector2(-4, -1), "86 LIST", HORIZONTAL_ALIGNMENT_CENTER, 28, 4, Color("#ffd23f"))

	# Brittany: drawn by a y-sorted proxy (dressing_front.gd -> draw_brittany)

const BETS: = {
	"nohit": {"name": "No-Hit Run", "goal": 8, "time": 0.0, "pitch": "Beat 8 of these goobers without getting touched ONCE. One hit and I win.",
		"pool": ["scammer", "karen", "hustler", "drunk"], "cap": 3,
		"win": "...Okay, that was actually sick. Don't let it go to your head. Your head's already a lot.",
		"lose": "AND THERE IT IS. Posted. 40 views already. One of them is your mom." },
	"combo": {"name": "Hit Parade", "goal": 45, "time": 45.0, "pitch": "Land 45 hits in 45 seconds. On the HOA guys. They're basically drywall with clipboards.",
		"pool": ["hoa"], "cap": 3,
		"win": "45 hits. You punch like you're mad at a parking ticket. Fine. Take it.",
		"lose": "You swing like a guy opening a pickle jar. Pay up, chef." },
	"speed": {"name": "Speed Run", "goal": 12, "time": 50.0, "pitch": "12 knockouts in 50 seconds. I've got the stopwatch. And the camera. And your $.",
		"pool": ["scammer", "hustler", "drunk", "heckler", "karen"], "cap": 4,
		"win": "Fine! FINE. You're fast. Like, suspiciously fast. Are you on something? Is it coffee? It's coffee.",
		"lose": "Time! You were SO close. Just kidding, you weren't. Venmo me." },
}
const BET_ORDER: = ["nohit", "combo", "speed"]
const BET_INTRO: = ["{coworker}: Okay, chef. I've got a bet. You're gonna lose. I'm gonna film it.",
	"{coworker}: Bet you can't. I'm not elaborating. Bet. You. Can't.",
	"{coworker}: My phone's at 80% and my faith in you is at 12%. Let's go."]

func bet_today() -> String:
	return BET_ORDER[day_count % BET_ORDER.size()]

func bet_menu() -> void:
	if int(bet["day"]) == day_count:
		_say(["{coworker}: We already did one today. I'm editing the video. It's got music now. Sad music. Come back tomorrow."])
		return
	if phase() == "Night":
		_say(["{coworker}'s gone home. She left me a text: \"tomorrow ur going DOWN\""])
		return
	var b: Dictionary = BETS[bet_today()]
	var lines: Array = [BET_INTRO[day_count % BET_INTRO.size()], "TODAY: %s. %s" % [b["name"], b["pitch"]],
		"Win and she pays double. Lose and she keeps the stake. Record vs {coworker}: %d-%d." % [int(bet["won"]), int(bet["lost"])]]
	var opts: Array = []
	if money >= 10:
		opts.append(["10", "Bet $10", KEY_1])
	if money >= 25:
		opts.append(["25", "Bet $25 (she'll scream)", KEY_2])
	if opts.is_empty():
		lines.append("{coworker}: You have $%d. I'm not betting against your lunch money. That's too sad, even for me." % money)
	opts.append(["no", "Nah", KEY_ESCAPE])
	_menu("{COWORKER}'S BET", lines, opts, func (ch: String) -> void:
		if ch in ["10", "25"]:
			start_bet(bet_today(), int(ch)))

func start_bet(kind: String, stake: int) -> void:
	if busy() or _world_gate(func () -> void: start_bet(kind, stake)):
		return
	clear_enemies()
	arena_id = "alley"
	arena_mode = "bet"
	bet_kind = kind
	bet_stake = stake
	bet_t = 0.0
	bet_hits = 0
	bet_kills = 0
	bet_hurt = 0
	bet_spawn = 0.5
	bet["day"] = day_count
	location = "arena"
	player.position = ARENA_SPAWN
	player.stun_t = 0.0
	_set_camera()
	energy = 100.0
	_say(["{coworker} drags me behind the {fork_nick}. \"Best lighting in town. It's the dumpster. The dumpster's the lighting.\"", "{coworker}: %s Go!" % str(BETS[kind]["name"]).to_upper()])
	_sync_world()

func _bet_progress() -> int:
	return bet_hits if bet_kind == "combo" else bet_kills

func _bet_process(delta: float) -> void:
	var b: Dictionary = BETS[bet_kind]
	bet_t += delta
	if energy <= 0.0:
		_end_bet(false, "Knocked out. {coworker}: \"Okay that one's going in the blooper reel AND the main reel.\"")
		return
	if bet_kind == "nohit" and bet_hurt > 0:
		_end_bet(false, "")
		return
	if _bet_progress() >= int(b["goal"]):
		_end_bet(true, "")
		return
	if float(b["time"]) > 0.0 and bet_t >= float(b["time"]):
		_end_bet(false, "")
		return
	bet_spawn -= delta
	var live: = live_enemies()
	if bet_spawn <= 0.0 and live.size() < int(b["cap"]):
		bet_spawn = 1.2
		var pool: Array = b["pool"]
		var corners: = [Vector2(30, 60), Vector2(290, 60), Vector2(30, 160), Vector2(290, 160)]
		spawn_enemy(str(pool[randi() % pool.size()]), ARENA_ORIGIN + corners[randi() % corners.size()])

func _end_bet(won: bool, extra: String) -> void:
	var b: Dictionary = BETS[bet_kind]
	clear_enemies()
	arena_id = ""
	_leave_arena()
	player.position = BRITT_POS + Vector2(0, 16)
	_set_camera()
	var lines: Array = []
	if extra != "":
		lines.append(extra)
	if won:
		money += bet_stake * 2
		bet["won"] = int(bet["won"]) + 1
		lines.append("{coworker}: " + str(b["win"]))
		lines.append("She pays me $%d. Record vs {coworker}: %d-%d." % [bet_stake * 2, int(bet["won"]), int(bet["lost"])])
		combat.gain_xp("boss_bounty", combat.level)
		if int(bet["won"]) >= 5 and not achievements.has("{coworker} Owes Me"):
			achievements.append("{coworker} Owes Me")
			lines.append("ACHIEVEMENT UNLOCKED: {coworker} Owes Me (5 bets won. She says it's rigged.)")
	else:
		money = maxi(0, money - bet_stake)
		bet["lost"] = int(bet["lost"]) + 1
		lines.append("{coworker}: " + str(b["lose"]))
		lines.append("-$%d. Record vs {coworker}: %d-%d." % [bet_stake, int(bet["won"]), int(bet["lost"])])
	bet_kind = ""
	energy = maxf(30.0, energy)
	_say(lines)
	save_game()

func _draw_bet_hud(f: Font, o: Vector2) -> void:
	if bet_kind == "":
		return
	var b: Dictionary = BETS[bet_kind]
	var txt: = "{COWORKER}'S BET: %s   %d / %d" % [str(b["name"]).to_upper(), _bet_progress(), int(b["goal"])]
	if float(b["time"]) > 0.0:
		txt += "   %ds" % int(ceil(maxf(0.0, float(b["time"]) - bet_t)))
	if bet_kind == "nohit":
		txt += "   DON'T GET HIT"
	draw_rect(Rect2(o + Vector2(40, 62), Vector2(240, 10)), Color(0, 0, 0, 0.6))
	draw_string(f, o + Vector2(40, 70), Cast.T(txt), HORIZONTAL_ALIGNMENT_CENTER, 240, 6, Color("#ffd23f"))

	var bp: = o + Vector2(296, 96)
	Art.person(self, "ch_brittany", bp, player.position - bp, t, false, true)
	if int(t * 2.0) % 2 == 0:
		draw_circle(bp + Vector2(-8, -16), 1.5, Color("#ff3030"))
	draw_string(f, bp + Vector2(-18, -26), "REC", HORIZONTAL_ALIGNMENT_CENTER, 24, 5, Color("#ff5050"))

func _auto_doors() -> void:
	if not location in ["outside", "home"] or busy() or not dialog.is_empty() or player.frozen:
		return
	if door_loc != location:
		door_loc = location
		door_armed.clear()
	var v: Vector2 = player.velocity
	for it in interactables():
		var id: = str(it["id"])
		if not (id in AUTO_DOORS or id.begins_with("story_")):
			continue
		var d: = player.position.distance_to(it["pos"])
		if d > AUTO_REARM_R:
			door_armed[id] = true
		elif d < AUTO_DOOR_R and bool(door_armed.get(id, false)) and v.length() > 5.0 and v.dot(it["pos"] - player.position) > -1.0:
			door_armed[id] = false
			interact(id)
			return


# ---------------------------------------------------------------- daily life (docs/daily_life.md)

## Today's random event id ("" if none or it's from another day).
func today_event() -> String:
	return str(daily["id"]) if int(daily["day"]) == day_count else ""

## A calendar headline or a random event owns this morning (the bill roll waits).
func daily_headline() -> bool:
	return bool(Daily.entry(day_count).get("headline", false)) or today_event() != ""

## Morning roll: pick today's event, apply its one-off effects, return lines for the wake report.
func daily_new_day() -> Array:
	if int(daily["day"]) == day_count:
		return []
	var id: = Daily.roll(day_count, day_i % 7, daily["recent"], (story["beaten"] as Array).size(), wordle_seed)
	daily["day"] = day_count
	daily["id"] = id
	daily["recent"] = Daily.remember(daily["recent"], id)
	var out: Array = []
	if id == "":
		return out
	var e: = Daily.event(id)
	energy = clampf(energy + float(e.get("energy", 0)), 1.0, 100.0)
	if float(e.get("happy", 0)) != 0.0:
		gain_happy(float(e.get("happy", 0)))
	money = maxi(0, money + int(e.get("money", 0)))   # farmers_market costs $10; broke = no candle, not -$10
	out.append(str(e.get("card", "")))
	out.append("(%s)" % str(e.get("effect", "")))
	apply_gear()
	return out

## Special handler id for today's calendar square ("falcor", "thanksgiving") or "".
func calendar_event() -> String:
	return str(Daily.entry(day_count).get("event", ""))

## Days 11-13 after Falcor: Madison's quiet. No fussy rolls, a soft line each morning.
const FALCOR_GRIEF: = {
	11: "{partner}'s quiet at breakfast. She feeds {cat1} and {cat2} twice, like she's making up the difference.",
	12: "{partner} holds onto me at the door a little longer than usual. Doesn't say anything about the porch.",
	13: "{partner} laughs at something {baby} does. First real one in three days. I write down the time.",
}

func falcor_grief() -> bool:
	return str(daily["falcor"]) != "" and FALCOR_GRIEF.has(day_count)

## Extra wake lines for special calendar days.
func calendar_day_lines() -> Array:
	var out: Array = []
	if falcor_grief():
		out.append(FALCOR_GRIEF[day_count])
		if day_count == 11:
			text("madison", "madison", "bowl's still on the porch. not ready to move it.")
	if calendar_event() == "thanksgiving" and int(daily.get("thanks_day", -1)) != day_count:
		daily["thanks_day"] = day_count
		gain_happy(10.0)
		energy = minf(100.0, energy + 20.0)
		out.append("Waffle Haus at noon. Dolores brings a pie she says is 'from the case.' It's not from the case. (+10 Happiness, +20 Energy. The {fork_nick}'s closed.)")
	return out

## Day 10: Falcor. Approved text (Duff, Nov 9). Sincere: no jokes at his expense.
const FALCOR_LINES: = [
	"Sunday. {partner}'s on the porch steps before the coffee's done. {stray}'s curled up next to his bowl like he's waiting on seconds. He's not waiting on anything anymore.",
	"I get the shovel. She picks the spot. Neither of us says much.",
	"A stray is a cat that picked you without asking. That's the whole contract. He kept his end.",
]

func falcor_scene(after: Array) -> void:
	spawn_t = 150.0   # nobody on the block till about noon
	_menu("SUNDAY", FALCOR_LINES, [["stay", "Stay with her", KEY_1], ["space", "Give her some space", KEY_2]], func (id: String) -> void:
		daily["falcor"] = id
		var out: Array = []
		if id == "stay":
			gain_happy(10.0)
			advance_clock(180.0)
			out.append("We sit on the steps till the coffee's cold. {partner} talks about the moth. I listen like it's the news. (+10 Happiness. The morning's gone. Worth it.)")
		else:
			out.append("I kiss the top of her head and give her the porch. She nods. Some things you do alone, even when you're not.")
		save_game()
		_say(out + after), "living_night")
	if overlay_node:
		overlay_node.set("backdrop_dim", 0.45)   # quiet room, no party burst

# ---------------------------------------------------------------- Madison's mornings (mornings.gd)

## Today's morning kind, or "".
func morning_today() -> String:
	return str(morning["kind"]) if int(morning["day"]) == day_count else ""

## A slow or migraine morning she hasn't had her coffee on yet.
func morning_hard_pending() -> bool:
	return Mornings.hard(morning_today()) and str(morning["done"]) == ""

## She's in bed: hard morning, coffee not brought yet, or brought and the meds haven't kicked in.
func madison_in_bed() -> bool:
	if not Mornings.hard(morning_today()):
		return false
	return str(morning["done"]) == "" or (str(morning["done"]) == "brought" and clock < float(morning["up_at"]))

## Where Madison is (and where you talk to her): her side of the bed on a hard morning.
func madison_spot() -> Vector2:
	return Vector2(54, 522) if madison_in_bed() else MADISON_POS

const BED_HEAD: = Vector2(28, 484)   # her pillow, in the painted bed

## Morning roll at wake-up. `couch` = Duff slept on the couch last night (no morning scene on top of that).
func morning_new_day(couch: bool) -> Array:
	if int(morning["day"]) == day_count:
		return []
	var ok: = not couch and life_events and mood_kind() == "" and calendar_event() == "" and not falcor_grief() \
		and not bool(Daily.entry(day_count).get("headline", false))
	var last: = int(morning["day"]) if str(morning["kind"]) != "" else -99
	var kind: = Mornings.roll(day_count, wordle_seed, ok, last)
	morning = Mornings.new_state()
	if kind == "":
		return []
	morning["day"] = day_count
	morning["kind"] = kind
	morning["pick"] = (day_count + wordle_seed) % 2
	return Mornings.wake_lines(kind, int(morning["pick"]))

## Good morning: she's making the coffee. Sit down (let her) or take over (she still has it).
func good_morning_scene(after: Array) -> void:
	_menu("GOOD MORNING", after + [Mornings.GOOD_ASK], [["sit", "Sit down", KEY_1], ["takeover", "Take over", KEY_2]], func (id: String) -> void:
		morning["done"] = id
		var out: Array = []
		if id == "sit":
			gain_happy(Mornings.GOOD_HAPPY)
			out = Mornings.GOOD_SIT.duplicate()
			out[-1] = str(out[-1]) + " (+%d Happiness)" % int(Mornings.GOOD_HAPPY)
		else:
			out = Mornings.GOOD_TAKEOVER.duplicate()
		save_game()
		_say(out))

## Talking to her on a hard morning. Returns true if the morning took the conversation.
func morning_talk() -> bool:
	var kind: = morning_today()
	if not Mornings.hard(kind):
		return false
	if str(morning["done"]) == "":
		if not bool(morning["fed"]):
			_say([Mornings.bed_line(kind, int(morning["pick"]))])
		elif not bool(morning["coffee"]):
			_say(["(Coffee first. Kitchen.)"])
		else:
			morning["done"] = "brought"
			morning["up_at"] = clock + Mornings.UP_DELAY
			gain_happy(Mornings.SLOW_HAPPY)
			var bl: = Mornings.bring_lines(kind)
			bl[-1] = str(bl[-1]) + " (+%d Happiness)" % int(Mornings.SLOW_HAPPY)
			_say(bl)
			save_game()
		return true
	if str(morning["done"]) == "brought" and not bool(morning["later_said"]) and clock >= float(morning["up_at"]):
		morning["later_said"] = true
		_say([Mornings.later_line(kind, int(morning["pick"]))])
		return true
	return false

## 10 AM and nobody brought the coffee: she gets herself up and texts. No penalty.
func morning_tick() -> void:
	if morning_hard_pending() and clock >= Mornings.SELF_UP_AT:
		morning["done"] = "self"
		morning["later_said"] = true
		text("madison", "madison", Mornings.skip_text(morning_today()))
		unread["madison"] = true
		ping_t = 2.0

## Her in bed: sprite with the head on the pillow, the bed's own quilt redrawn over her, and the pain showing.
func _draw_madison_in_bed() -> void:
	var head: = BED_HEAD
	Art.person(self, "ch_madison", head + Vector2(0, 22), Vector2.DOWN, 0.0, false, false, Color.WHITE, false)
	var quilt: = Rect2(BED_R.position.x + 2, head.y + 6, BED_R.size.x - 4, 511.0 - head.y - 6)
	_redraw_interior(quilt)
	if str(morning["done"]) == "" and morning_today() == "slow":
		var a: = clampf(sin(t * 2.4) * 1.6 - 0.6, 0.0, 1.0)   # a wince now and then, at the hip
		if a > 0.0:
			var hp: = Vector2(head.x + 9, quilt.position.y + 8)
			for k in 3:
				var ang: = -0.9 + k * 0.9
				draw_line(hp + Vector2(cos(ang), sin(ang)) * 3.0, hp + Vector2(cos(ang), sin(ang)) * 6.0, Color(1.0, 0.45, 0.35, a), 1.0)
	if morning_hard_pending():
		var tgt: = CRIB_PT if not bool(morning["fed"]) else (KITCHEN_PT if not bool(morning["coffee"]) else head)
		UiStyle.quest_marker(self, tgt + Vector2(0, (-14 if tgt == head else -22) + sin(t * 3.2) * 1.5), "!")

## Repaint one world rect of the home interior art on top (tucks her under the quilt).
func _redraw_interior(r: Rect2) -> void:
	var tx: = Art.tex("home_interior")
	if tx == null:
		return
	var inf: = Art.info("home_interior")
	var org: Array = inf.get("origin", [0, 0])
	var k: = Art.density(inf)
	var top_left: = INT_ORIGIN - Vector2(float(org[0]), float(org[1])) / k
	draw_texture_rect_region(tx, r, Rect2((r.position - top_left) * k, r.size * k))

## Dev/render: force a morning kind for today (arena_shot morning_*).
func dev_morning(kind: String) -> void:
	morning = Mornings.new_state()
	morning["day"] = day_count
	morning["kind"] = kind
	clock = 450.0
