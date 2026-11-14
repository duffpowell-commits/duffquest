extends SceneTree
## Soak test: boots game.tscn (HD layer included: loading screens, fridge calendar, knockouts), starts a
## new game and plays all 30 November days with a seeded bot. Every menu, minigame, shift station, shop,
## street fight, bounty, story boss (with knockout cutscene), Brittany's bet, Waffle Haus, the gala and the
## ending go through the real game code; the bot only stands in for the thumbs.
##   XDG_DATA_HOME=/tmp/xdg godot --headless --path . --fixed-fps 30 --script tools/soak.gd -- --seed=1
## Options: --seed=N  --days=30  --lazy (skips work, cats and bills: rent/overdraft/upset paths)
## Reports SCRIPT ERRORs / push_errors / warnings (via a Logger), softlocks (nothing changes for STALL
## frames), NaN or out-of-range money/energy/happiness, textures the game asked for that don't exist, a
## save -> fresh-scene reload mismatch, and each day reached. Exit code 1 on any issue.
## Never touches the real save: the game writes to user://soak_<seed>.json, erased at the end.
## Batch: tools/soak.sh (several seeds, summary).

const SaveGame: = preload("res://scripts/save_game.gd")
const Card: = preload("res://scripts/minigames/card.gd")
const Daily: = preload("res://scripts/daily.gd")
const Bounties: = preload("res://scripts/bounties.gd")
const Art: = preload("res://scripts/art.gd")
const Life: = preload("res://scripts/life.gd")

const STALL: = 1500                       # frames (50 s at 30 fps) with nothing changing = softlock
const DAY_FRAME_CAP: = 60000              # one in-game day taking longer than this = stuck day
const ESCAPES: = ["leave", "no", "later", "back", "close", "never", "nah"]
const RELOAD_DAY: = 15

class SoakLogger extends Logger:
	var errors: Array = []
	var day: = 0
	var mutex: = Mutex.new()
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		errors.append({"type": ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"][clampi(error_type, 0, 3)],
			"msg": (rationale if rationale != "" else code), "where": "%s:%d %s()" % [file, line, function], "day": day})
		mutex.unlock()
	func _log_message(_message: String, _error: bool) -> void:
		pass

var logger: = SoakLogger.new()
var rng: = RandomNumberGenerator.new()
var seed_n: = 1
var days_target: = 30
var lazy: = false
var save_path: = ""

var game: Node = null
var m: Node = null
var ko_node: Node = null
var load_node: Node = null
var cal_node: Node = null
var ko_seen: = {}
var hd_wait: = 0
var phase: = "boot"
var boot_frames: = 0
var frame: = 0
var day_frames: = 0

var plan: Array = []
var plan_day: = -1
var want: = ""
var mg: Node = null
var mg_frames: = 0
var mg_policy: = ""
var card_node: Node = null
var card_frames: = 0
var dialog_wait: = 0

var target: Node = null
var fight_frames: = 0
var stuck_frames: = 0
var last_dist: = 1e9
var god: = false
var losses: = {}
var special_t: = 0

var last_sig: = ""
var stall_frames: = 0
var issues: Array = []
var assists: Array = []
var days: Array = []
var seen: = {}
var reload_snapshot: = {}
var reload_done: = false
var gala_done: = false
var gala_tries: = 0
var gala_seen_unlock: = false
var ending_morning: = -1   # first morning the story ending had played (the gala invite is due then)
var mode_i: = 0
var last_day: = 0
var ctx_prev: = ""
var money_prev: = 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="): seed_n = int(a.substr(7))
		elif a.begins_with("--days="): days_target = int(a.substr(7))
		elif a == "--lazy": lazy = true
	if Engine.get_frames_per_second() == 0 and not OS.get_cmdline_args().has("--fixed-fps"):
		pass
	seed(seed_n)
	rng.seed = seed_n * 7919
	save_path = "user://soak_%d.json" % seed_n
	SaveGame.erase(save_path)
	OS.add_logger(logger)
	print("soak: seed %d, %d days%s" % [seed_n, days_target, " (lazy)" if lazy else ""])
	_boot_game()

func _boot_game() -> void:
	game = load("res://game.tscn").instantiate()
	root.add_child(game)
	boot_frames = 0

func _find_main() -> Node:
	if game == null or game.get_child_count() == 0:
		return null
	var box: = game.get_child(0)
	if box.get_child_count() == 0 or box.get_child(0).get_child_count() == 0:
		return null
	return box.get_child(0).get_child(0)

func _find_hd(file: String) -> Node:
	for layer in game.get_children():
		if layer is CanvasLayer:
			for n in layer.get_children():
				if n.get_script() and str(n.get_script().resource_path).ends_with(file):
					return n
	return null

func issue(kind: String, msg: String) -> void:
	var d: = int(m.day_count) if m else 0
	issues.append({"kind": kind, "msg": msg, "day": d, "frame": frame})
	print("ISSUE [%s] day %d frame %d: %s" % [kind, d, frame, msg])

func assist(msg: String) -> void:
	assists.append("day %d: %s" % [int(m.day_count), msg])

func cover(k: String) -> void:
	seen[k] = int(seen.get(k, 0)) + 1

# ------------------------------------------------------------------ main loop

func _process(_delta: float) -> bool:
	frame += 1
	match phase:
		"boot", "reload":
			boot_frames += 1
			if boot_frames < 8:
				return false
			m = _find_main()
			if m == null:
				if boot_frames > 120:
					issue("boot", "main scene never appeared")
					return _finish()
				return false
			ko_node = _find_hd("knockout.gd")
			load_node = _find_hd("loading_screen.gd")
			cal_node = _find_hd("fridge_calendar.gd")
			m.save_path = save_path              # never the real save
			m.close_overlay()
			m.in_title = false
			if phase == "boot":
				m.new_game(true)
				cover("new_game")
			else:
				m.load_game()
				cover("reload")
				_compare_reload()
			phase = "run"
			last_day = int(m.day_count)
			_day_reached()
			return false
		"done":
			return true
	_check_values()
	if int(m.day_count) != last_day:
		last_day = int(m.day_count)
		day_frames = 0
		_day_reached()
		if int(m.day_count) > days_target:
			return _finish()
	day_frames += 1
	if day_frames > DAY_FRAME_CAP:
		issue("stuck_day", "day %d ran %d frames; forcing sleep. %s" % [int(m.day_count), day_frames, _dump()])
		day_frames = 0
		_recover()
		if not m.busy():
			m.go_to_sleep(false)
	# 4 h of game time: Nov 13 combat got harder (DMG_TAKEN 1.25, story exes +20% HP), so the bot needs ~3.1 h for 30 days.
	if frame > 30 * 60 * 60 * 4:
		issue("budget", "frame budget exhausted at day %d" % int(m.day_count))
		return _finish()
	_stall_check()
	ctx_prev = "%s ui=%s/%s event=%s" % [m.location, _cls(m.shift.current if m.in_shift and m.shift else m.overlay_node), str((m.shift.current if m.in_shift and m.shift else m.overlay_node).get("heading")) if (m.in_shift and m.shift and m.shift.current) or m.overlay_node else "", m.today_event()]
	money_prev = int(m.money)
	_drive()
	return false

func _day_reached() -> void:
	logger.day = int(m.day_count)
	var d: = int(m.day_count)
	var line: = "day %2d %-9s $%-5d E%3d H%3d lvl %d  beaten %s  bounties %s  %s" % [d, m.DAY_NAMES[int(m.day_i) % 7], int(m.money), int(m.energy), int(m.happiness), int(m.combat.level),
		",".join(m.story["beaten"]), ",".join(m.bounties["beaten"]), ("event " + m.today_event()) if m.today_event() != "" else ""]
	days.append(line)
	print(line)

# ------------------------------------------------------------------ checks

func _check_values() -> void:
	for k in ["money", "energy", "happiness", "clock"]:
		var v: float = float(m.get(k))
		if is_nan(v) or is_inf(v):
			issue("nan", "%s is %s" % [k, str(v)])
			m.set(k, 50 if k == "money" else 50.0)
	if int(m.money) < 0:
		issue("negative", "money %d (was $%d; last frame: %s)" % [int(m.money), money_prev, ctx_prev])
		m.money = 0
	if float(m.energy) < 0.0 or float(m.energy) > 100.0001:
		issue("range", "energy %.2f" % float(m.energy))
		m.energy = clampf(float(m.energy), 0.0, 100.0)
	if float(m.happiness) < 0.0 or float(m.happiness) > 100.0001:
		issue("range", "happiness %.2f" % float(m.happiness))
		m.happiness = clampf(float(m.happiness), 0.0, 100.0)
	for k in m.inventory:
		if int(m.inventory[k]) < 0:
			issue("negative", "inventory %s = %d" % [k, int(m.inventory[k])])
			m.inventory[k] = 0
	if int(m.gear.get("scraps", 0)) < 0:
		issue("negative", "scraps %d" % int(m.gear["scraps"]))

func _sig() -> String:
	var b: Node = m.current_boss()
	var cur: Node = m.shift.current if m.in_shift and m.shift else null
	var ui: Node = cur if cur else m.overlay_node
	return str([m.day_count, int(m.clock), m.location, m.dialog.size(), m.in_shift, ui.get_instance_id() if ui else 0,
		int(ui.get("t")) if ui and ui.get("t") != null else 0, m.ko_kind, ko_node.get("beat") if ko_node else 0,
		m.loading_on, m.calendar_on, m.money, int(b.hp) if b else 0, int(m.waffle_node.t) if m.waffle_node else 0,
		m.live_enemies().size(), int(m.player.position.x), int(m.player.position.y), int(m.finale_t * 10)])

func _stall_check() -> void:
	var s: = _sig()
	if s == last_sig:
		stall_frames += 1
		if stall_frames >= STALL:
			issue("softlock", "nothing changed for %d frames. %s" % [STALL, _dump()])
			stall_frames = 0
			_recover()
	else:
		stall_frames = 0
		last_sig = s

func _dump() -> String:
	var ui: Node = m.shift.current if m.in_shift and m.shift else m.overlay_node
	return "loc=%s clock=%s busy=%s shift=%s ui=%s heading=%s dialog=%d ko=%s loading=%s cal=%s arena=%s/%s boss=%s enemies=%d title=%s tut=%s" % [
		m.location, m.clock_text(), m.busy(), m.in_shift, _cls(ui), str(ui.get("heading")) if ui else "", m.dialog.size(),
		m.ko_kind, m.loading_on, m.calendar_on, m.arena_mode, m.arena_id, _cls(m.current_boss()), m.live_enemies().size(), m.in_title, m.tut != null and m.tut.active()]

func _cls(n: Node) -> String:
	if n == null:
		return "-"
	var s: Script = n.get_script()
	return str(s.resource_path).get_file().get_basename() if s else n.get_class()

func _recover() -> void:
	if m.ko_kind != "":
		m.knockout_done()
	if m.loading_on:
		m.loading_done()
	if m.calendar_on:
		m.calendar_done()
	if m.in_shift:
		m.end_shift({"left": true})
	if m.overlay_node:
		if m.overlay_node.has_method("finish") and not (m.overlay_node is Card):
			m.overlay_node.finish(0.5)
		else:
			m.close_overlay()
	m.dialog.clear()
	var b: Node = m.current_boss()
	if b:
		b.take_hit(Vector2.RIGHT, 9999.0)

# ------------------------------------------------------------------ the bot

func _drive() -> void:
	# HD layer: a player taps these away. First knockout of each boss plays in full (every SFX cue),
	# repeats get tapped through beat by beat; loading screens and the calendar get a tap after ~1 s.
	if m.ko_kind != "":
		var k: = str(m.ko_kind)
		cover("ko:" + k)
		if ko_seen.has(k) and ko_node and float(ko_node.get("bt")) > 1.0:
			ko_node._next()
		return
	if m.tut != null and m.tut.active():   # phone control cards (touch only): a player taps each one away
		cover("touch_tutorial")
		if float(m.tut.t) > 0.8:
			m.tut.next()
		return
	if m.loading_on:
		cover("loading_screen")
		if load_node and float(load_node.get("_t")) > 1.0:
			load_node.set("_t", maxf(float(load_node.get("_t")), load_node.HOLD - load_node.FADE))
		return
	if m.calendar_on:
		cover("fridge_calendar")
		if cal_node and float(cal_node.get("_t")) > 1.2:
			cal_node._close()
		return
	if m.in_shift:
		if m.shift and m.shift.current:
			_handle_ui(m.shift.current)
		return
	if m.overlay_node:
		_handle_ui(m.overlay_node)
		return
	card_node = null
	mg = null
	for k in seen:
		if str(k).begins_with("ko:"):
			ko_seen[str(k).substr(3)] = true
	if m.in_title:
		return
	if not m.dialog.is_empty():
		dialog_wait += 1
		if dialog_wait >= 3:
			dialog_wait = 0
			m.dialog.pop_front()
		return
	if m.finale_t > 0.0:
		cover("finale")
		return
	if m.location == "arena" and m.arena_mode == "waffle":
		_waffle()
	if _fight():
		return
	_release_stick()
	if m.location in ["arena", "gala"]:
		return
	_idle()

func _release_stick() -> void:
	m.player.joy_vec = Vector2.ZERO

## Cards: take the option the bot asked for, else a mostly-sensible random one.
func _handle_ui(n: Node) -> void:
	if n is Card:
		if n != card_node:
			card_node = n
			card_frames = 0
			cover("card:" + str(n.heading).substr(0, 24))
		card_frames += 1
		if card_frames < 4 or bool(n.done):
			return
		var ids: Array = []
		for b in n.buttons:
			if b["enabled"]:
				ids.append(str(b["id"]))
		if ids.is_empty():
			if card_frames > 120:
				issue("dead_card", "card '%s' has no enabled options" % str(n.heading))
				n.chosen.emit("")
			return
		var pick: = _pick(n, ids)
		want = ""
		n.press(pick)
		return
	if n != mg:
		mg = n
		mg_frames = 0
		var tl: = float(n.get("time_limit")) if n.get("time_limit") != null else 0.0
		var r: = rng.randf()
		mg_policy = "solve" if r < 0.65 else ("monkey" if r < 0.85 or tl <= 0.0 or tl > 60.0 else "timeout")
		cover("mg:" + _cls(n))
	mg_frames += 1
	if not n.has_method("finish") or bool(n.get("done")):
		return
	match mg_policy:
		"solve":
			if mg_frames == 8:
				if _has_solver(n):
					n.debug_solve(rng.randf() < 0.8)
				else:
					mg_policy = "monkey"
			elif mg_frames > 40:
				n.finish(rng.randf_range(0.4, 1.0))
		"monkey":
			if mg_frames % 7 == 0 and mg_frames < 120:
				var bs: Array = (n.buttons as Array).filter(func (b): return b["enabled"])
				if not bs.is_empty():
					n.press(str(bs[rng.randi() % bs.size()]["id"]))
			elif mg_frames >= 120:
				n.finish(rng.randf())
		"timeout":
			if float(n.t) > float(n.time_limit) + 3.0:
				issue("timeout", "%s didn't finish on its own after its %.0fs limit" % [_cls(n), float(n.time_limit)])
				n.finish(0.0)
			elif mg_frames > 30 * 300:
				n.finish(0.0)

func _has_solver(n: Node) -> bool:
	var s: Script = n.get_script()
	while s:
		if s.source_code.contains("func debug_solve") and not str(s.resource_path).ends_with("minigame.gd"):
			return true
		s = s.get_base_script()
	return false

func _pick(c: Node, ids: Array) -> String:
	if want != "" and want in ids:
		return want
	var h: = str(c.heading)
	if h.begins_with("THE TWISTED FORK"):
		var modes: = ["full", "quick", "rush"]
		for i in 3:
			var md: String = modes[(mode_i + i) % 3]
			if md in ids:
				mode_i += 1
				cover("shift_mode:" + md)
				return md
	if "auto" in ids and rng.randf() < 0.5:
		cover("autopilot")
		return "auto"
	var real: = ids.filter(func (i): return not (str(i) in ESCAPES))
	if real.is_empty() or rng.randf() < 0.12:
		return ids[rng.randi() % ids.size()]
	return real[rng.randi() % real.size()]

## Fight whatever is closest. Returns true while fighting.
func _fight() -> bool:
	var pl: Node2D = m.player
	var best: Node2D = null
	var bd: = 1e9
	var range_r: = 1e9 if m.location in ["arena", "gala"] else 110.0
	for e in m.live_enemies():
		if e.get("hidden_t") != null and float(e.hidden_t) > 0.0:
			continue
		var d: = pl.global_position.distance_to(e.global_position)
		if d < bd and d < range_r:
			bd = d
			best = e
	if best == null:
		target = null
		return false
	if best != target:
		target = best
		fight_frames = 0
		stuck_frames = 0
		last_dist = 1e9
		cover("fight:" + str(best.kind))
	fight_frames += 1
	if god:
		m.energy = 100.0
	var to: Vector2 = best.global_position - pl.global_position
	if to.length() > 13.0:
		pl.joy_vec = to.normalized()
		if to.length() >= last_dist - 0.2:
			stuck_frames += 1
		else:
			stuck_frames = 0
		last_dist = to.length()
		if stuck_frames > 40:
			pl.global_position = best.global_position - to.normalized() * 11.0
			stuck_frames = 0
			last_dist = 1e9
	else:
		pl.joy_vec = Vector2.ZERO
		pl.facing = to.normalized() if to.length() > 0.5 else Vector2.DOWN
		if fight_frames % 6 == 0:
			m._on_attack()
	if fight_frames % 97 == 0:
		m._on_roll()
	special_t -= 1
	if fight_frames % 211 == 0 and m.combat.points <= 0:
		m.combat.special_pressed()
		special_t = 12
	if special_t == 0:
		m.combat.special_released()
	if fight_frames % 401 == 0:
		m.combat.demon_pressed()
	if fight_frames > 30 * 120 and fight_frames % 30 == 0:
		if fight_frames == 30 * 120 + 30:
			assist("fight vs %s ran past 2 min, bot chips in damage" % str(best.kind))
		best.take_hit(to.normalized(), 30.0)
	return true

func _waffle() -> void:
	var w: Node = m.waffle_node
	if w == null or frame % 10 != 0:
		return
	cover("waffle")
	for g in 3:
		var idx: int = w.grills[g]
		if idx >= 0 and str(w.tickets[idx]["state"]) == "ready":
			w.use_grill(g)
		elif idx < 0 and w._waiting() > 0:
			w.use_grill(g)

# ------------------------------------------------------------------ the day plan

func _idle() -> void:
	if plan_day != int(m.day_count):
		plan_day = int(m.day_count)
		_build_plan()
	if plan.is_empty():
		_evening()
		return
	var step: Array = plan.pop_front()
	want = str(step[1]) if step.size() > 1 else ""
	(step[0] as Callable).call()

func _at_home() -> void:
	if m.location != "home":
		m.enter_home()

func _outside() -> void:
	if m.location != "outside":
		m.leave_home()

func _build_plan() -> void:
	plan = []
	var d: = int(m.day_count)
	var weekend: bool = Daily.is_weekend(int(m.day_i) % 7)
	_check_gala_gate(d)
	if d == RELOAD_DAY and not reload_done:
		plan.append([_reload])
		return
	plan.append([_at_home])
	if d == 1 or rng.randf() < 0.3:
		plan.append([func (): m.interact("fridge")])
	if not lazy or rng.randf() < 0.3:
		plan.append([func (): m.interact("bowls")])
	plan.append([func (): m.interact("madison")])
	for id in ["crib", "shower", "kitchen", "mirror", "freya", "backwalk", "couch"]:
		if rng.randf() < 0.25:
			plan.append([m.interact.bind(id)])
	if not lazy and not m.bills.is_empty():
		plan.append([func (): m.interact("mail")])
	plan.append([_outside])
	_story_steps()
	if d >= 2 and not lazy:
		plan.append([_bounty_step])
	if not weekend and not lazy:
		plan.append([func (): m.interact("fork")])
	elif rng.randf() < 0.3:
		plan.append([func (): m.interact("fork")])   # weekend / Thanksgiving: closed message
	var shops: = ["shop", "pharmacy", "grocery", "plasma"]
	plan.append([m.interact.bind(shops[d % 4])])
	if rng.randf() < 0.5:
		plan.append([m.interact.bind(shops[(d + 2) % 4])])
	plan.append([_street_fight])
	if rng.randf() < 0.35:
		plan.append([func (): m.interact("brittany")])
	if rng.randf() < 0.3:
		plan.append([func (): m.open_phone()])
	if not m.wordle_daily_done() and rng.randf() < 0.6:
		plan.append([func (): m.start_wordle(false)])
	if rng.randf() < 0.2:
		plan.append([func (): m.bus_menu(str(m.bus_stops()[rng.randi() % m.bus_stops().size()]["id"]).substr(4))])
	if rng.randf() < 0.15:
		plan.append([func (): m.open_gear()])
	if m.gala_unlocked and not m.gala_beaten and not gala_done:
		plan.append([_gala])
	plan.append([_at_home])
	plan.append([func (): if m.fryer_smell and not lazy: m.interact("shower")])
	plan.append([func (): m.interact("madison")])

func _story_steps() -> void:
	var n: Dictionary = m.story_next()
	if n.is_empty():
		return
	var id: = str(n["id"])
	if not m.story_available(id):
		if m.story_ready_unannounced() == "" and int(m.day_count) >= int(n["day"]) + 1 and float(m.happiness) < float(n["happy"]):
			assist("happiness %d -> %d to unlock %s" % [int(m.happiness), int(n["happy"]), id])
			m.happiness = float(n["happy"])
		if m.story_ready_unannounced() != "":
			plan.push_front([func (): m.interact("madison")])   # she tells me where they are
			plan.append([_story_fight.bind(id)])
		return
	plan.append([_story_fight.bind(id)])

func _story_fight(id: String) -> void:
	if not m.story_available(id):
		return
	god = int(losses.get(id, 0)) >= 1
	if god:
		assist("god mode for the %s retry" % id)
	_outside()
	cover("story:" + id)
	want = "go"
	m.story_menu(id)
	plan.push_front([_after_story.bind(id)])

func _after_story(id: String) -> void:
	god = false
	if not m.story_beaten(id):
		losses[id] = int(losses.get(id, 0)) + 1
		cover("story_lose:" + id)
	else:
		cover("story_win:" + id)

func _bounty_step() -> void:
	if int(m.bounties["day"]) == int(m.day_count):
		return
	var pick: = ""
	for e in Bounties.LIST:
		if not (m.bounties["beaten"] as Array).has(str(e["id"])):
			pick = str(e["id"])
			break
	if pick == "":
		pick = str(Bounties.LIST[rng.randi() % Bounties.LIST.size()]["id"])
	_outside()
	var why: = Bounties.locked_reason(Bounties.entry(pick), int(m.combat.level), m.bounties["beaten"])
	if why == "":
		want = pick
		m.bounty_menu()
	else:
		if rng.randf() < 0.3:
			want = pick
			m.bounty_menu()                          # locked: "not yet" line
		else:
			assist("bounty %s forced (%s)" % [pick, why])
			m.start_bounty(pick)
	cover("bounty:" + pick)

func _street_fight() -> void:
	_outside()
	var pool: Array = m.spawn_pool()
	if pool.is_empty():
		pool = ["scammer", "drunk"]
	for i in rng.randi_range(1, 3):
		var k: = str(pool[rng.randi() % pool.size()])
		m.spawn_enemy(k, m.player.position + Vector2(rng.randf_range(-50, 50), rng.randf_range(-30, 30)))
	cover("street_fight")

## The gala opens on its own the morning after the story ending, or on main.GALA_DAY, whichever comes first
## (no fund gate, no bot help).
func _check_gala_gate(d: int) -> void:
	if ending_morning < 0 and bool(m.story.get("ending_seen", false)):
		ending_morning = d
	var due: = int(m.GALA_DAY) if ending_morning < 0 else mini(int(m.GALA_DAY), ending_morning)
	if d < due:
		if m.gala_unlocked:
			issue("gala", "gala unlocked before day %d" % due)
		return
	if not m.gala_unlocked:
		issue("gala", "gala still locked on day %d (due day %d)" % [d, due])
		return
	if gala_seen_unlock:
		return
	gala_seen_unlock = true
	var invite: = false
	for t in m.threads.get("madison", []):
		if str(t.get("text", "")).contains("gala guest list"):
			invite = int(t.get("day", -1)) == due
	if d != due or not invite or (m.threads.get("gala", []) as Array).is_empty():
		issue("gala", "invite didn't land on the day-%d morning (seen day %d, madison text %s)" % [due, d, invite])
	else:
		cover("gala_unlocked_day%d" % d)

## First try straight up; a lost gala gets retried the next day with god mode (logged).
func _gala() -> void:
	gala_done = true
	god = gala_tries >= 1
	if god:
		assist("god mode for the gala retry")
	gala_tries += 1
	m.start_gala(0)
	cover("gala")
	plan.push_front([func ():
		god = false
		if m.gala_beaten:
			cover("gala_won_day%d" % int(m.day_count))
		else:
			cover("gala_lost")
			gala_done = false])

## Nothing left to do: Waffle Haus some nights, otherwise bed.
func _evening() -> void:
	var c: = fmod(float(m.clock), 1440.0)
	var waffle_night: bool = not lazy and int(m.shifts_worked) >= m.WAFFLE_MIN_SHIFTS and int(m.day_count) % 6 == 0
	if waffle_night and (c >= 1260.0 or c < 60.0):
		_outside()
		want = "go"
		m.waffle_menu()
		cover("waffle_menu")
		return
	if c < (1265.0 if waffle_night else 1205.0) and c >= 300.0:
		m.advance_clock(20.0)                    # skip the idle afternoon
		return
	_at_home()
	if not lazy and int(m.couch_day) != int(m.day_count) and c >= 1020.0 and c < 1320.0:
		cover("couch_evening")
		m.interact("couch")                      # makes up if she's upset: Show & Tell instead of the couch
		return
	cover("bed_mood:" + (m.mood_kind() if m.mood_kind() != "" else "ok"))
	want = "sleep"
	m.bed_menu()

# ------------------------------------------------------------------ save + reload

func _reload() -> void:
	reload_done = true
	m.save_game()
	reload_snapshot = JSON.parse_string(JSON.stringify(m.to_dict()))
	print("soak: day %d: save, free the whole game, boot a fresh one, Continue" % int(m.day_count))
	game.queue_free()
	game = null
	m = null
	ko_node = null
	phase = "reload"
	boot_frames = 0
	call_deferred("_boot_game")

func _compare_reload() -> void:
	var now: Dictionary = JSON.parse_string(JSON.stringify(m.to_dict()))
	var bad: = []
	for k in reload_snapshot:
		if k in ["saved_at", "version", "kills"]:
			continue
		if not now.has(k):
			bad.append(k + " (missing)")
		elif str(now[k]) != str(reload_snapshot[k]):
			bad.append(k)
	if not bad.is_empty():
		issue("reload", "fields differ after save -> reload: %s" % ", ".join(bad))
	plan_day = -1

# ------------------------------------------------------------------ report

func _missing_art() -> Array:
	var out: Array = []
	for k in Art._tex:
		if Art._tex[k] == null and str(k) != "":   # "" = callers probing an optional slot
			out.append(str(k))
	out.sort()
	return out

func _finish() -> bool:
	phase = "done"
	var errs: Array = []
	logger.mutex.lock()
	errs = logger.errors.duplicate()
	logger.mutex.unlock()
	var grouped: = {}
	for e in errs:
		var key: = "%s: %s @ %s" % [e["type"], e["msg"], e["where"]]
		if not grouped.has(key):
			grouped[key] = [0, e["day"]]
		grouped[key][0] += 1
	print("\n===== SOAK REPORT seed %d%s =====" % [seed_n, " lazy" if lazy else ""])
	print("days completed: %d / %d" % [mini(last_day - 1, days_target), days_target])
	print("frames: %d" % frame)
	print("-- engine errors/warnings: %d (%d unique)" % [errs.size(), grouped.size()])
	for k in grouped:
		print("   x%d (first day %d) %s" % [grouped[k][0], grouped[k][1], k])
	print("-- issues: %d" % issues.size())
	for i in issues:
		print("   [%s] day %d: %s" % [i["kind"], i["day"], i["msg"]])
	var miss: = _missing_art()
	print("-- textures asked for but missing: %d %s" % [miss.size(), ", ".join(miss)])
	print("-- assists: %d" % assists.size())
	for a in assists:
		print("   " + a)
	if m:
		print("-- end state: $%d, rent weeks paid %d, late notices %d, rent debt $%d, shifts %d, achievements %d, ending seen %s, gala beaten %s" % [
			int(m.money), int(m.weeks_paid), int(m.late_notices), int(m.rent_debt), int(m.shifts_worked), (m.achievements as Array).size(), m.story.get("ending_seen", false), m.gala_beaten])
	var keys: = seen.keys()
	keys.sort()
	print("-- coverage (%d): %s" % [keys.size(), ", ".join(keys.map(func (k): return "%s x%d" % [k, seen[k]]))])
	if m and last_day > days_target and not m.gala_beaten:
		issue("gala", "gala not beaten by day %d" % days_target)
	var real_errs: = errs.filter(func (e): return e["type"] != "WARNING")
	var ok: = issues.is_empty() and real_errs.is_empty() and last_day > days_target
	print("SOAK %s (seed %d)" % ["PASS" if ok else "FAIL", seed_n])
	if m:
		SaveGame.erase(save_path)
	SaveGame.erase(save_path)
	OS.remove_logger(logger)
	if game:
		game.queue_free()
	quit(0 if ok else 1)
	return true
