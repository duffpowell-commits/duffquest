extends Node
## In-game shot of one boss arena (fight view), for M7 backdrop checks. Run:
##   (ids: a boss arena, "bounty:<id>" (alley bounty fight), "gala:<boss>" (gala ex fight), "move:<bounty>:<attack>:<frames>" (fire one boss attack, shoot N frames later), "title", "home", "hint" (home, standing by Madison), "dolores" (her dialogue line), "waffle" (Waffle Haus shift), "quest"/"type"/"notes" (side-quest marker, typewriter mid-line, phone Notes), "porch"/"chad" (porch mystery: '?' on the neighbor door / the suspect fleeing), "grease86" (Grease Trap '?' on the 86 List at night; the fight itself is "bounty:grease"), "gig" (Brittany's Side Gig choice card), "lost" (Lost & Found hunt: glints at the storm drain), "at:X,Y[,MIN]" (outdoors at a world point, optional clock minute), or "fryer"/"sandwich" = the kitchen station with food in it)
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- gymbro
## -> /tmp/qa/arena_<id>.png   (id "title" = the title screen -> /tmp/qa/title.png)
var game: Node
var m: Node
var frame: = 0
var id: = "gymbro"

func _ready() -> void:
	var a: = OS.get_cmdline_user_args()
	if a.size() > 0:
		id = a[0]
	DirAccess.make_dir_recursive_absolute("/tmp/qa")
	game = load("res://game.tscn").instantiate()
	add_child(game)

func _key(k: int) -> void:
	for p in [true, false]:
		var e: = InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)

func _process(_d: float) -> void:
	frame += 1
	if id == "title":
		if frame == 30:
			get_viewport().get_texture().get_image().save_png("/tmp/qa/title.png")
			get_tree().quit()
		return
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		m.close_overlay()
		m.dialog.clear()
		m.no_loading = true
		if id.begins_with("at:"):  # at:X,Y = stand Duff at that outdoor world point
			var xy: = id.substr(3).split(",")
			if m.location != "outside":
				m.leave_home()
				m.dialog.clear()
			m.player.position = Vector2(float(xy[0]), float(xy[1]))
		elif id in ["quest", "type", "notes"]:  # side quests: '?' over Brittany / a typewriter line mid-reveal / phone Notes
			m.dev_warp_quest("porch", 1)
			m.SideQuests.add_clue(m.side_quests, "porch", "orange crumbs")
			m.SideQuests.start(m.side_quests, "gig")
			m.dialog.clear()
		elif id == "lost":  # Lost & Found: hunting, collar found, standing at the storm drain (glints + label)
			m.clock = 600.0
			m.dev_warp_quest("alley", 1)
			m.SideQuests.add_clue(m.side_quests, "alley", "collar")
			if m.location != "outside":
				m.leave_home()
			m.player.position = m.LOST_SPOTS["ring"] + Vector2(-10, 6)
			m.dialog.clear()
		elif id == "gig":  # Brittany's Side Gig: the cover-or-rat choice card
			m.clock = 600.0
			m.dev_warp_quest("gig", 2)
			m.dialog.clear()
		elif id == "grease86":  # Grease Trap stage 2: '?' over the 86 List
			m.dev_warp_quest("grease", 2)
			m.dialog.clear()
		elif id in ["porch", "chad"]:  # porch mystery stage 3: '?' on the neighbor's door / Cheeto Chad bolting
			m.clock = 600.0
			m.dev_warp_quest("porch", 3)
			m.dialog.clear()
		elif id.begins_with("morning_"):  # Madison's mornings: morning_slow / _migraine / _good / _bring (coffee lines)
			m.debug_station("home")
			m.dialog.clear()
			var mk: = id.substr(8)
			m.dev_morning("slow" if mk == "bring" else mk)
			if mk == "good":
				m.good_morning_scene(m.Mornings.wake_lines("good", 0))
			elif mk == "bring":
				m.morning["fed"] = true
				m.morning["coffee"] = true
				m.player.position = m.madison_spot() + Vector2(22, 4)
			else:
				m.player.position = m.CRIB_PT + Vector2(10, 14)
		elif id == "dolores":
			m._say(["Dolores (31 years in): \"Three grills, hon. Fire 'em, plate 'em, don't let 'em burn. And don't let the drunks hug you. They mean it.\""])
		elif id == "waffle":  # Waffle Haus shift (Dolores behind the counter)
			m.start_waffle()
		elif id in ["fryer", "sandwich", "home"]:
			m.debug_station(id)
		elif id == "hint":  # home, Duff next to Madison so the "E / A: Talk to" prompt shows
			m.debug_station("home")
		elif id.begins_with("gala:"):  # a gala ex fight on the painted gala floor, e.g. gala:husk
			m.debug_station("boss_" + id.substr(5))
		elif id.begins_with("move:"):  # move:<bounty>:<attack>:<frames> = fire that attack, shoot <frames> later
			m.start_bounty(id.split(":")[1])
		elif id.begins_with("bounty:"):  # a bounty fight in the alley behind the Fork, e.g. bounty:sendback
			m.start_bounty(id.substr(7))
		else:
			m.start_story_fight(id)
	if frame == 215 and id in ["fryer", "sandwich", "waffle"]:
		_key(KEY_SPACE)  # past the NEXT STATION card
	if frame == 260 and id in ["fryer", "sandwich"]:
		var g: Node = _find_game(m)
		if g and id == "sandwich":
			g.built = g.ORDER.duplicate()
		elif g:
			g.toggle(0)
			g.baskets[0]["prog"] = 0.8
			g.baskets[1]["prog"] = 1.5

	if frame >= 200 and id.begins_with("at:") and id.count(",") == 2:  # at:X,Y,MIN = also set the clock
		m.clock = float(id.split(",")[2])
		m.dialog.clear()
	if frame == 236 and id == "chad":
		m.quest_talk("neighbor")
	if frame >= 236 and id == "grease86":
		m.clock = 1380.0
		m.dialog.clear()
		m.player.position = m.BOARD_PT + Vector2(-4, 6)
	if frame == 240 and id == "gig":
		m.toast_t = 0.0
		m.quest_talk("brittany")
	if frame == 262 and id == "chad":
		m.dialog.clear()
	if frame >= 240 and id in ["quest", "type", "porch", "chad", "grease86", "lost"]:
		m.toast_t = 0.0   # the DEV warp toast would sit on top of the marker
	if frame == 250 and id == "type":
		m._say(["Brittany: Package thief? Oh, I've SEEN him. Tall. Orange fingers. Smells like a gas station hot case."])
	if frame == 230 and id == "notes":
		m.open_phone("notes")
	if frame == 236 and id == "morning_bring":
		m.morning_talk()
	if frame == 230 and id in ["home", "waffle", "hint"]:
		m.dialog.clear()
		if id == "hint":
			m.player.position = m.MADISON_POS + Vector2(16, 4)
	if frame == 230 and not id in ["fryer", "sandwich", "home", "dolores", "waffle", "hint", "quest", "type", "notes", "porch", "chad", "grease86", "gig", "lost"] and not id.begins_with("at:") and not id.begins_with("morning_"):
		m.dialog.clear()
		m.player.position = (m.GALA_SPAWN + Vector2(40, -10)) if id.begins_with("gala:") else m.ARENA_ORIGIN + Vector2(200, 140)
	if id.begins_with("move:"):
		var mv: = id.split(":")
		if frame == 240 and m.arena_boss != null:
			var b: Node = m.arena_boss
			b.state = "roam"
			b.cur = mv[2]
			b._attack(m.player.global_position - b.global_position)
		if frame == 240 + int(mv[3]):
			get_viewport().get_texture().get_image().save_png("/tmp/qa/arena_%s.png" % id.replace(":", "_"))
			get_tree().quit()
		return
	if frame == 280:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/arena_%s.png" % id)  # fryer/sandwich: the station
		get_tree().quit()

func _find_game(n: Node) -> Node:
	for c in n.get_children():
		if c.has_method("_draw_game") and (c.get("built") != null or c.get("baskets") != null):
			return c
		var r: = _find_game(c)
		if r:
			return r
	return null
