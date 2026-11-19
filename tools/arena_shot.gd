extends Node
## In-game shot of one boss arena (fight view), for M7 backdrop checks. Run:
##   (ids: a boss arena, "bounty:<id>" (alley bounty fight), "gala:<boss>" (gala ex fight), "gala_say:<boss>" ({partner}'s setup line as the ex walks in), "ask" ({partner} asks for diapers), "move:<bounty>:<attack>:<frames>" (fire one boss attack, shoot N frames later), "title", "home", "hint" (home, standing by Madison), "dolores" (her dialogue line), "waffle" (Waffle Haus shift), "look"/"look_text" (her phone over the dialogue), "quest"/"type"/"notes" (side-quest marker, typewriter mid-line, phone Notes), "porch"/"chad" (porch mystery: '?' on the neighbor door / the suspect fleeing), "grease86" (Grease Trap '?' on the 86 List at night; the fight itself is "bounty:grease"), "gig" (Brittany's Side Gig choice card), "backdoor"/"lunch_pick"/"cover"/"double" (round-two quests: back-door '?', choice cards), "qfight:brayden"/"qfight:earljr"/"qfight:king" (quest alley fights), "dolores_book"/"chef_day"/"heist"/"trivia"/"watch"/"king_boxes" (Nov 19 content), "lost" (Lost & Found hunt: glints at the storm drain), "at:X,Y[,MIN]" (outdoors at a world point, optional clock minute), or "fryer"/"sandwich" = the kitchen station with food in it)
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://tools/arena_shot.tscn -- gymbro
## -> /tmp/qa/arena_<id>.png   (id "title" = the title screen -> /tmp/qa/title.png)
var _street: Array = []
var game: Node
var m: Node
var frame: = 0
var _bench_t: = 0
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
	if id.begins_with("cold"):
		_cold()
		return
	if frame in [40, 80, 110, 140]:
		_key(KEY_1 if frame == 40 else KEY_ENTER)
	if frame == 200:
		m = game.get_child(0).get_child(0).get_child(0)
		if "--3d" in OS.get_cmdline_user_args() and m.AudioScript.inst != null:   # 3D town view (scripts/view3d/)
			m.AudioScript.inst.set_view3d(true)
		if "--2d" in OS.get_cmdline_user_args() and m.AudioScript.inst != null:   # the flat view (Settings > 3D view off)
			m.AudioScript.inst.set_view3d(false)
		if "--lite" in OS.get_cmdline_user_args():   # lite graphics (perf_guard), e.g. to compare 3D full vs lite
			game.get_node("PerfGuard").force_low(true)
		if "--shades" in OS.get_cmdline_user_args():   # Duff in his round shades (gear screen toggle)
			m.shades = true
			m.player.shades = true
		if "--maxpad" in OS.get_cmdline_user_args():   # every touch button on screen (specials, swap, demon) for layout checks
			m.combat.level = 10
			m.combat.demon_unlocked = true
			m.combat.heat = 100.0
		m.close_overlay()
		m.dialog.clear()
		m.no_loading = true
		m.clear_enemies()   # the new game's cold-open pirate (shoot it with id "cold")
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
		elif id in ["backdoor", "cover", "lunch_pick", "double"]:  # round-two quests: '?' on the Fork back door / choice cards
			m.clock = 600.0
			m.SideQuests.finish(m.side_quests, "gig", "cover")
			if id == "backdoor":
				m.dev_warp_quest("lunch", 1)
			elif id == "lunch_pick":
				m.dev_warp_quest("lunch", 3)
			elif id == "cover":
				m.SideQuests.finish(m.side_quests, "lunch", "truth")
				m.dev_warp_quest("cover", 1)
			else:
				m.money = 180
				m.dev_warp_quest("double", 1)
			m.dialog.clear()
		elif id in ["dolores_book", "chef_day", "heist", "trivia", "watch", "king_boxes"]:  # Nov 19 content: Dolores's book card /
			# Chef's Bad Week card / cat heist floor / trivia clipboard / a watch request spot / the King's runners
			m.clock = 600.0
			m.SideQuests.finish(m.side_quests, "porch")
			if id == "dolores_book":
				m.waffle_data["shifts"] = 2
				m.money = 120
			elif id == "chef_day":
				m.day_i = 1
				m.dev_warp_quest("chef", 2)
			elif id == "king_boxes":
				m.dev_warp_quest("king", 2)
			m.dialog.clear()
		elif id == "gig":  # Brittany's Side Gig: the cover-or-rat choice card
			m.clock = 600.0
			m.dev_warp_quest("gig", 2)
			m.dialog.clear()
		elif id == "evicted":  # fail state: three short Mondays (rolls back to last Monday)
			m.debug_station("home")
			m.dialog.clear()
		elif id == "gameover":  # fail state: KO'd in a story fight (rolls back to this morning)
			m.start_story_fight(str(m.STORY[0]["id"]))
			m.dialog.clear()
		elif id == "grease86":  # Grease Trap stage 2: '?' over the 86 List
			m.dev_warp_quest("grease", 2)
			m.dialog.clear()
		elif id in ["porch", "chad"]:  # porch mystery stage 3: '?' on the neighbor's door / Cheeto Chad bolting
			m.clock = 600.0
			m.dev_warp_quest("porch", 3)
			m.dialog.clear()
		elif id in ["loud", "loud_bag", "loud_home"]:  # "Too Loud": store lines / the noise game mid-climb / the couch crash
			m.dialog.clear()
			m.day_count = m.TooLoud.FIRST_DAY
			m.day_i = m.TooLoud.SATURDAY
			m.too_loud_seen = false
			if id == "loud_home":
				m.debug_station("home")
			else:
				if m.location != "outside":
					m.leave_home()
				m.player.position = m.GROC_DOOR + Vector2(0, 14)
		elif id in ["look", "look_text"]:  # "Look At This": her reel over the dialogue / the text she makes me read
			m.debug_station("home")
			m.dialog.clear()
			m.day_count = m.LookAtThis.FIRST_DAY
			m.look_seen = false
			m.player.position = m.MADISON_POS + Vector2(16, 4)
		elif id in ["zebra", "zebra_talk"]:  # "The Zebra": plush + print at home / her diagnosis lines
			m.debug_station("home")
			m.dialog.clear()
			m.day_count = m.Zebra.FIRST_DAY
			m.zebra_seen = false
			m.player.position = m.ZEBRA_PT + Vector2(0, 2)
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
		elif id == "street":
			pass   # set up below at frame 200
		elif id == "dolores":
			m._say(["Dolores (31 years in): \"Three grills, hon. Fire 'em, plate 'em, don't let 'em burn. And don't let the drunks hug you. They mean it.\""])
		elif id == "waffle":  # Waffle Haus shift (Dolores behind the counter)
			m.start_waffle()
		elif id in ["fryer", "sandwich", "home", "prep"]:
			m.debug_station(id)
		elif id == "hint":  # home, Duff next to Madison so the "E / A: Talk to" prompt shows
			m.debug_station("home")
		elif id == "ask":  # store shot: home, {partner} asks for an errand (diapers) over the dialogue box
			m.debug_station("home")
		elif id.begins_with("gala_say:"):  # store shot: a gala ex walks in, {partner}'s setup line over the floor
			m.debug_station("boss_" + id.substr(9))
		elif id.begins_with("gala:"):  # a gala ex fight on the painted gala floor, e.g. gala:husk
			m.debug_station("boss_" + id.substr(5))
		elif id.begins_with("move:"):  # move:<bounty>:<attack>:<frames> = fire that attack, shoot <frames> later
			m.start_bounty(id.split(":")[1])
		elif id.begins_with("bounty:"):  # a bounty fight in the alley behind the Fork, e.g. bounty:sendback
			m.start_bounty(id.substr(7))
		elif id.begins_with("qfight:"):  # a {coworker} quest fight: qfight:brayden (lunch thief) / qfight:earljr (double or nothing)
			m.double_stake = 100
			m.start_quest_fight(id.substr(7))
		else:
			m.start_story_fight(id)
	if frame == 215 and id in ["fryer", "sandwich", "waffle", "prep"]:
		_key(KEY_SPACE)  # past the NEXT STATION card
	if frame == 260 and id in ["fryer", "sandwich"]:
		var g: Node = _find_game(m)
		if g and id == "sandwich":
			g.built = g.ORDER.duplicate()
			g.steal_armed = false     # keep the ticket on the rail for the shot
			g.stolen = false
		elif g:
			g.toggle(0)
			g.baskets[0]["prog"] = 0.8
			g.baskets[1]["prog"] = 1.5

	if id == "street":  # night street fight: two thugs on Duff, a swing and a crit landing as the shot is taken
		if frame == 200:
			if m.location != "outside":
				m.leave_home()
			m.dialog.clear()
			m.clock = 1260.0
			m.player.position = Vector2(300, 215)
			m.player.facing = Vector2.RIGHT
			_street = [m.spawn_enemy("karen", Vector2(322, 214)), m.spawn_enemy("hustler", Vector2(276, 226))]
		if frame in [262, 270, 278] and _street.size() > 0 and is_instance_valid(_street[0]):
			m.player.swing()
			m.combat.hit(_street[0], Vector2.RIGHT, 0.6 if frame == 278 else 0.3, "crit" if frame == 278 else "")
		if frame >= 240:
			m.dialog.clear()
	if frame >= 200 and id.begins_with("at:") and id.count(",") == 2:  # at:X,Y,MIN = also set the clock
		m.clock = float(id.split(",")[2])
		m.dialog.clear()
	if frame == 236 and id == "evicted":
		m._evicted()
	if frame == 236 and id == "gameover":
		m.player.position = m.ARENA_ORIGIN + Vector2(200, 140)
	if frame == 250 and id == "gameover":
		m.getup_day = m.day_count   # today's free get-up already spent
		m.story_lose("I get knocked out. Me and the sidewalk get acquainted.")
	if frame == 236 and id == "chad":
		m.quest_talk("neighbor")
	if frame >= 236 and id == "grease86":
		m.clock = 1380.0
		m.dialog.clear()
		m.player.position = m.BOARD_PT + Vector2(-4, 6)
	if frame == 240 and id == "dolores_book":
		m.toast_t = 0.0
		m.dolores_book()
	if frame == 240 and id == "chef_day":
		m.toast_t = 0.0
		m.quest_talk("fork")
	if frame == 240 and id == "heist":
		m.toast_t = 0.0
		var g = m.CatHeistScript.new()
		g.item = "wallet"
		m._run_game(g, func (_n, _s, _x) -> void: pass)
	if frame == 240 and id == "trivia":
		m.toast_t = 0.0
		m._run_game(m.TriviaScript.new(), func (_n, _s, _x) -> void: pass)
	if frame >= 236 and id == "watch":
		m.toast_t = 0.0
		m.dialog.clear()
		m.player.position = Vector2(m.watch_today()["pos"]) + Vector2(-12, 8)
	if frame >= 236 and id == "king_boxes":
		m.toast_t = 0.0
		m.dialog.clear()
		m.player.position = m.KING_SPOTS["north"] + Vector2(-14, 8)
	if frame == 240 and id == "gig":
		m.toast_t = 0.0
		m.quest_talk("brittany")
	if frame >= 236 and id == "backdoor":
		m.dialog.clear()
		m.toast_t = 0.0
		m.player.position = m.BACKDOOR_PT + Vector2(14, 10)
	if frame == 240 and id in ["cover", "lunch_pick", "double"]:
		m.toast_t = 0.0
		m.dialog.clear()
		m.quest_talk("brittany")
	if frame == 262 and id == "chad":
		m.dialog.clear()
	if frame >= 240 and id in ["quest", "type", "porch", "chad", "grease86", "lost"]:
		m.toast_t = 0.0   # the DEV warp toast would sit on top of the marker
	if frame == 250 and id == "type":
		m._say(["Brittany: Package thief? Oh, I've SEEN him. Tall. Orange fingers. Smells like a gas station hot case."])
	if frame == 230 and id == "notes":
		m.dialog.clear()   # a quest line queued since frame 200 would block the phone
		m.close_overlay()
		m.open_phone("notes")
	if frame == 232 and id == "loud":
		m.too_loud_story()
	if frame == 232 and id == "loud_bag":
		m.too_loud_story()
		m.dialog.clear()
		m.after_dialog.call()
		m.after_dialog = Callable()
	if frame == 240 and id == "loud_bag" and m.overlay_node != null:
		m.overlay_node.t = 7.0
	if frame == 262 and id == "loud_bag" and m.overlay_node != null:
		m.overlay_node.get_button("diapers")["enabled"] = false   # one wrong grab already, no flash over the shot
	if frame == 232 and id == "loud_home":
		m._too_loud_home()
		for i in 1:
			m.advance_dialog()
	if frame == 236 and id.begins_with("look"):
		m.look_story()
		for i in (4 if id == "look_text" else 1):
			m.advance_dialog()
	if frame >= 237 and id.begins_with("look"):
		m.dlg_chars = 100000.0
	if frame == 236 and id == "zebra_talk":
		m.zebra_story()
	if frame == 250 and id == "zebra_talk":
		for i in 3:
			m.advance_dialog()
	if frame == 236 and id == "ask":
		m.dialog.clear()
		m.player.position = m.MADISON_POS + Vector2(16, 4)
		m._say([m.start_quest("diapers")[0]])
	if frame == 236 and id.begins_with("gala_say:"):
		m.dialog.clear()
		m.player.position = m.GALA_SPAWN + Vector2(40, -10)
		m._say([str(m.BossScript.BOSSES[id.substr(9)].get("setup", ""))])
	if frame >= 237 and (id == "ask" or id.begins_with("gala_say:")):
		m.dlg_chars = 100000.0
	if frame == 236 and id == "morning_bring":
		m.morning_talk()
	if frame == 230 and id in ["home", "waffle", "hint"]:
		m.dialog.clear()
		if id == "hint":
			m.player.position = m.MADISON_POS + Vector2(16, 4)
	if frame == 230 and not id in ["street", "prep", "fryer", "sandwich", "home", "dolores", "waffle", "hint", "quest", "type", "notes", "porch", "chad", "grease86", "gig", "lost", "evicted", "gameover", "backdoor", "cover", "lunch_pick", "double", "dolores_book", "chef_day", "heist", "trivia", "watch", "king_boxes"] and not id.begins_with("at:") and not id.begins_with("morning_") and not id.begins_with("zebra") and not id.begins_with("loud") and not id.begins_with("look") and id != "ask" and not id.begins_with("gala_say:"):
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
	if frame == 230:
		_bench_t = Time.get_ticks_usec()
	if frame == 270 and _bench_t > 0:   # 40 frames of the live scene: render cost per frame (--fixed-fps 0 for real time)
		print("BENCH ms/frame %.1f" % ((Time.get_ticks_usec() - _bench_t) / 40000.0))
	if frame == 280:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/arena_%s.png" % id)  # fryer/sandwich: the station
		if m.view3d != null and m.view3d_on:   # --3d: the 3D layer alone, for checking what's 2D and what's 3D
			m.view3d.snapshot().save_png("/tmp/qa/arena_%s_3donly.png" % id)
			m.view3d.vp.get_texture().get_image().save_png("/tmp/qa/arena_%s_3dfull.png" % id)
		get_tree().quit()

## id "cold": the new game's cold open (run with --fixed-fps 30). Saves cold_0 (phone: first control card),
## cold_1 (the one line, the pirate on screen), cold_2 (he has the package and runs, Duff on him), cold_3 (he's
## down, {coworker}'s first-bet card), cold_4 (Marketplace Mike in the alley), cold_5 (the payout + rules).
var _snatch: = -1
func _cold() -> void:
	if frame == 40:
		_key(KEY_1)
	if frame == 100:
		m = game.get_child(0).get_child(0).get_child(0)
		m.no_loading = true
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cold_0.png")
		if m.tut != null and m.tut.active():
			m.tut.finish()
	if frame == 110:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cold_1.png")
		m.dialog.clear()
	if frame > 110 and _snatch < 0 and m.live_enemies().size() > 0 and str(m.live_enemies()[0].loot) != "":
		_snatch = frame
		print("cold open: package snatched %.1f s after the line" % ((frame - 110) / 30.0))
	if _snatch > 0 and frame == _snatch + 12:
		var e: Node = m.live_enemies()[0]
		m.player.position = e.position + Vector2(-22, 2)
		m.cam.reset_smoothing()
	if _snatch > 0 and frame == _snatch + 16:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cold_2.png")
		for e in m.live_enemies():
			e.hp = 0.1
			e.take_hit(Vector2.RIGHT, 1.0)
	if _snatch > 0 and frame == _snatch + 40:
		m.toast_t = 0.0
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cold_3.png")
		print("cold open: dialog after the fight = ", m.dialog)
		m.close_overlay()   # {coworker}'s first bet card: take it
		m.start_first_bet()
	if _snatch > 0 and frame == _snatch + 50:
		m.dialog.clear()
		m.player.position = m.ARENA_ORIGIN + Vector2(120, 110)
	if _snatch > 0 and frame == _snatch + 110:
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cold_4.png")
		m.arena_boss.hp = 0.1
		m.arena_boss.take_hit(Vector2.RIGHT, 1.0)
	if _snatch > 0 and frame == _snatch + 200:
		if m.ko_kind != "":
			print("cold open: knockout cutscene up")
		m.toast_t = 0.0
		get_viewport().get_texture().get_image().save_png("/tmp/qa/cold_5.png")
		print("cold open: after Mike = ", m.dialog, " money ", m.money)
		get_tree().quit()
	if frame == 600:
		print("cold open: no snatch in 16 s")
		get_tree().quit()

func _find_game(n: Node) -> Node:
	for c in n.get_children():
		if c.has_method("_draw_game") and (c.get("built") != null or c.get("baskets") != null):
			return c
		var r: = _find_game(c)
		if r:
			return r
	return null
