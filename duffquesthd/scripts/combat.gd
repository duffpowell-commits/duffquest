extends Node



const AudioScript: = preload("res://scripts/audio.gd")
const Shot: = preload("res://scripts/player_shot.gd")
const FX: = preload("res://scripts/combat_fx.gd")

const MAX_LEVEL: = 20
const POINTS_PER_LEVEL: = 3
const HEAT_BASE: = 100.0
const HEAT_REGEN: = 3.0
const HEAT_PER_HIT: = 5.0
const HEAT_PER_FINISHER: = 10.0
const DEMON_DRAIN: = 10.0
const DEMON_DMG: = 1.5
const DEMON_SPEED: = 1.3
const CRASH_TIME: = 4.0
const CRASH_SPEED: = 0.7
const DEMON_UNLOCK_LEVEL: = 10

const SPECIALS: = [
	{"id": "spatter", "name": "Searing Spatter", "short": "Spatter", "lvl": 1, "cost": 15.0, 
		"desc": "Flick three drops of fryer grease. Ranged."}, 
	{"id": "pinwheel", "name": "Platter Pinwheel", "short": "Pinwheel", "lvl": 2, "cost": 20.0, 
		"desc": "A plate spins out and comes back. Hits both ways."}, 
	{"id": "julienne", "name": "Julienne Jamboree", "short": "Julienne", "lvl": 3, "cost": 25.0, 
		"desc": "Dash through the crowd. A beat later, everyone you passed gets sliced."}, 
	{"id": "holler", "name": "Heard-Chef Holler", "short": "Holler", "lvl": 4, "cost": 30.0, 
		"desc": "HEARD, CHEF! Stuns everyone close and swats thrown junk."}, 
	{"id": "counter", "name": "Cast-Iron Counter", "short": "Counter", "lvl": 5, "cost": 10.0, 
		"desc": "Skillet up. Get hit in the window and it bounces back."}, 
	{"id": "brulee", "name": "Brulee Blitz", "short": "Brulee", "lvl": 6, "cost": 30.0, 
		"desc": "Torch ring around you for 4s. Anyone who touches it gets caramelized."}, 
	{"id": "feast", "name": "Family-Meal Feast", "short": "Feast", "lvl": 7, "cost": 45.0, 
		"desc": "Scarf a plate: +Energy and harder hits for a bit. You're open while you eat."}, 
	{"id": "salamander", "name": "Salamander Supernova", "short": "Salamander", "lvl": 8, "cost": 35.0, 
		"desc": "Hold to charge, release a broiler beam."}, 
	{"id": "snare", "name": "Sous-Vide Snare", "short": "Sous-Vide", "lvl": 9, "cost": 20.0, 
		"desc": "Vacuum-seal the nearest enemy for 3s. Set it and forget it."}, 
	{"id": "tempura", "name": "Tempura Tornado", "short": "Tempura", "lvl": 10, "cost": 35.0, 
		"desc": "Spin the fryer basket: pulls enemies in and batters them."}, 
	{"id": "eightysix", "name": "Eighty-Six Execution", "short": "86", "lvl": 12, "cost": 100.0, 
		"desc": "Full Heat. Kitchen's closed."}, 
	{"id": "hashbrown", "name": "Hash Brown Hurricane", "short": "Hash Brown", "lvl": 1, "cost": 30.0, "unlock": "hashbrown", 
		"desc": "Scattered (ring of shreds), smothered (slows them), covered (second ring). Earned at Waffle Haus."}, 
]

const XP: = {
	"scammer": 5, "karen": 8, "karen_buddy": 4, "hoa": 12, "hustler": 3, "pete": 50, "drone": 3, "butler": 4, 
	"nft": 3, "pirate": 6, "boss_gala": 120, "boss_story": 80, 
	"drunk": 6, "heckler": 7, "kid": 2, "boss_bounty": 70, "boss_regular": 110, 
}
const ENEMY_LEVEL: = {"kid": 2, "drunk": 5, "heckler": 6, "nft": 1, "hustler": 1, "drone": 2, "scammer": 2, "pirate": 3, "butler": 4, "karen": 4, "hoa": 6, "pete": 9}

const STATS: = {
	"str": {"label": "STR", "name": "Strength", "desc": "+8% damage per point"}, 
	"def": {"label": "DEF", "name": "Defense", "desc": "-4% damage taken per point (max -50%)"}, 
	"heat": {"label": "HEAT", "name": "Heat", "desc": "+10 max Heat, +10% Heat regen per point"}, 
	"grit": {"label": "GRIT", "name": "Grit", "desc": "+1 Energy back per kill per point, quicker rolls"}, 
}

var m: Node = null
var fx: Node2D = null
var ui: Node2D = null

var level: = 1
var xp: = 0
var points: = 0
var stats: = {"str": 0, "def": 0, "heat": 0, "grit": 0}
var heat: = 50.0
var selected: = 0
var demon_unlocked: = false
var demon_t: = 0.0
var crash_t: = 0.0
var counter_t: = 0.0
var feast_t: = 0.0
var fed_t: = 0.0
var charging: = false
var charge_t: = 0.0
var cinematic: = false
var dash_t: = 0.0
var julienne_marks: Array = []
var julienne_hit_t: = 0.0
var brulee_t: = 0.0
var brulee_tick: = 0.0
var tempura_t: = 0.0
var tempura_tick: = 0.0
var snared: Array = []
var _alloc_check: = 0.0
var _menu_open: = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS



func to_dict() -> Dictionary:
	return {"level": level, "xp": xp, "points": points, "stats": stats.duplicate(), "heat": heat, 
		"selected": selected, "demon_unlocked": demon_unlocked, "extra_unlocks": extra_unlocks.duplicate()}

func from_dict(d) -> void :
	if typeof(d) != TYPE_DICTIONARY:
		return
	level = clampi(int(d.get("level", 1)), 1, MAX_LEVEL)
	xp = maxi(0, int(d.get("xp", 0)))
	points = maxi(0, int(d.get("points", 0)))
	var s = d.get("stats", {})
	if typeof(s) == TYPE_DICTIONARY:
		for k in stats:
			stats[k] = maxi(0, int(s.get(k, 0)))
	heat = clampf(float(d.get("heat", 50.0)), 0.0, heat_max())
	selected = int(d.get("selected", 0))
	demon_unlocked = bool(d.get("demon_unlocked", false)) or level >= DEMON_UNLOCK_LEVEL
	var xu = d.get("extra_unlocks", [])
	extra_unlocks = (xu as Array).duplicate() if typeof(xu) == TYPE_ARRAY else []
	_fix_selected()

func reset() -> void :
	from_dict({})



func heat_max() -> float:
	return HEAT_BASE + 10.0 * stats["heat"]

func xp_to_next() -> int:
	return 15 + 10 * level

func dmg_mult() -> float:
	var k: float = 1.0 + 0.08 * stats["str"]
	if demon_t > 0.0:
		k *= DEMON_DMG
	if fed_t > 0.0:
		k *= 1.2
	return k

func taken_mult() -> float:
	return 1.0 - minf(0.5, 0.04 * stats["def"])

func speed_mult() -> float:
	if demon_t > 0.0:
		return DEMON_SPEED
	if crash_t > 0.0:
		return CRASH_SPEED
	if charging:
		return 0.35
	if tempura_t > 0.0:
		return 0.6
	return 1.0

func roll_mult() -> float:
	return maxf(0.6, 1.0 - 0.04 * stats["grit"])

func cost_of(sp: Dictionary) -> float:
	var c: = float(sp["cost"])
	if demon_t > 0.0 and sp["id"] != "eightysix":
		c *= 0.5
	return c

var extra_unlocks: Array = []

func unlocked() -> Array:
	return SPECIALS.filter( func(s): return level >= int(s["lvl"]) and ( not s.has("unlock") or extra_unlocks.has(s["unlock"])))

func grant_special(id: String) -> bool:
	if extra_unlocks.has(id):
		return false
	extra_unlocks.append(id)
	return true

func current() -> Dictionary:
	var u: = unlocked()
	return u[clampi(selected, 0, u.size() - 1)] if not u.is_empty() else {}

func _fix_selected() -> void :
	selected = clampi(selected, 0, maxi(0, unlocked().size() - 1))

func demon_ready() -> bool:
	return demon_unlocked and demon_t <= 0.0 and crash_t <= 0.0 and heat >= heat_max() - 0.01

func locked_out() -> bool:
	return cinematic or feast_t > 0.0 or dash_t > 0.0

func countering() -> bool:
	return counter_t > 0.0



func _process(delta: float) -> void :
	if m == null or m.player == null:
		return
	var paused: = get_tree().paused
	if not paused and not m.busy():
		_tick(delta)
	if cinematic:
		m.player.queue_redraw()
	if ui:
		ui.queue_redraw()

func _tick(delta: float) -> void :
	var p: Node = m.player
	if demon_t > 0.0:
		demon_t -= delta
		heat = maxf(0.0, heat - DEMON_DRAIN * delta)
		if heat <= 0.0:
			_end_demon()
	elif crash_t > 0.0:
		crash_t -= delta
		if crash_t <= 0.0:
			m.apply_gear()
	elif not charging:
		heat = minf(heat_max(), heat + HEAT_REGEN * (1.0 + 0.1 * stats["heat"]) * delta)
	if counter_t > 0.0:
		counter_t -= delta
		_counter_scan()
	if fed_t > 0.0:
		fed_t -= delta
	if feast_t > 0.0:
		feast_t -= delta
		if feast_t <= 0.0:
			p.frozen = false
			_finish_feast()
	_tick_moves(delta)
	if charging:
		charge_t += delta
		var sp: = _find("salamander")
		if heat < cost_of(sp):
			charging = false
			m.apply_gear()
	p.demon = demon_t > 0.0
	p.charge = clampf(charge_t / 1.6, 0.0, 1.0) if charging else 0.0
	_alloc_check -= delta
	if _alloc_check <= 0.0:
		_alloc_check = 0.5
		_maybe_allocate()




func hit(e: Node, dir: Vector2, dmg: float, special: String = "", gain_heat: float = HEAT_PER_HIT) -> float:
	if not is_instance_valid(e) or e.is_queued_for_deletion():
		return 0.0
	var pos: Vector2 = e.global_position
	var dealt: float = e.take_hit(dir, dmg, special)
	if dealt > 0.0:
		if m.get("arena_mode") == "bet":
			m.bet_hits += 1
		if fx:
			fx.number(pos + Vector2(0, -14), dealt, special == "crit" or dmg >= 10.0)
		if demon_t <= 0.0:
			heat = minf(heat_max(), heat + gain_heat)
		else:
			heat = minf(heat_max(), heat + gain_heat * 0.5)
	return dealt

func finisher_heat() -> float:
	return HEAT_PER_FINISHER



func gain_xp(kind: String, enemy_level: int = -1) -> void :
	var base: int = int(XP.get(kind, 4))
	if enemy_level < 0:
		enemy_level = int(ENEMY_LEVEL.get(kind, 3))

	var gap: = level - enemy_level
	var k: = 1.0 if gap < 4 else maxf(0.25, 1.0 - 0.15 * (gap - 3))
	var got: = maxi(1, int(round(base * k)))
	if level >= MAX_LEVEL:
		return
	xp += got
	if fx and m.player:
		fx.text(m.player.global_position + Vector2(0, -26), "+%d XP" % got, Color("#9fe0ff"))
	while xp >= xp_to_next() and level < MAX_LEVEL:
		xp -= xp_to_next()
		_level_up()
	if stats["grit"] > 0 and kind.substr(0, 4) != "boss":
		m.energy = minf(m.energy_cap(), m.energy + stats["grit"])

func _level_up() -> void :
	level += 1
	points += POINTS_PER_LEVEL
	heat = heat_max()
	m.energy = minf(m.energy_cap(), m.energy + 15.0)
	AudioScript.sfx("achievement")
	var msg: = "SENIORITY UP! Lv %d. +3 stat points, Heat refilled, +15 Energy." % level
	for s in SPECIALS:
		if int(s["lvl"]) == level:
			msg += " NEW MOVE: %s." % s["name"]
	if level == DEMON_UNLOCK_LEVEL and not demon_unlocked:
		demon_unlocked = true
		msg += " Something wakes up at 2am... DEMON TIME unlocked (full Heat, press R / D)."
	m._toast(msg)
	m.cheer_level_up()
	if ui:
		ui.banner("SENIORITY UP!  Lv %d" % level, Color("#ffd060"), 1.6)

func unlock_demon(reason: String) -> void :
	if demon_unlocked:
		return
	demon_unlocked = true
	m._toast("%s DEMON TIME unlocked. Fill your Heat and press R (or the D button)." % reason)


func _maybe_allocate() -> void :
	if points <= 0 or _menu_open or m.busy() or cinematic or not m.dialog.is_empty():
		return
	if m.location in ["arena", "gala"]:
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.global_position.distance_to(m.player.global_position) < 120.0:
			return
	open_allocation()

func open_allocation() -> void :
	if points <= 0:
		return
	_menu_open = true
	var lines: Array = ["Seniority Lv %d. %d point%s to spend." % [level, points, "" if points == 1 else "s"], 
		"STR %d   DEF %d   HEAT %d   GRIT %d" % [stats["str"], stats["def"], stats["heat"], stats["grit"]]]
	var opts: Array = []
	var keys: = [KEY_1, KEY_2, KEY_3, KEY_4]
	var i: = 0
	for k in ["str", "def", "heat", "grit"]:
		opts.append([k, "%s: %s" % [STATS[k]["name"], STATS[k]["desc"]], keys[i]])
		i += 1
	opts.append(["later", "Later (press T anytime)", KEY_5])
	m._menu("Spend stat points", lines, opts, _on_alloc)

func _on_alloc(id: String) -> void :
	_menu_open = false
	if id in stats and points > 0:
		stats[id] += 1
		points -= 1
		heat = minf(heat, heat_max())
		AudioScript.sfx("select")
		if points > 0:
			call_deferred("open_allocation")
	elif id == "later":
		_alloc_check = 60.0



func swap() -> void :
	if charging or locked_out():
		return
	var u: = unlocked()
	if u.size() <= 1:
		return
	selected = (selected + 1) % u.size()
	AudioScript.sfx("select")
	m._toast("Special: %s (%d Heat). %s" % [u[selected]["name"], int(cost_of(u[selected])), u[selected]["desc"]])

func special_pressed() -> void :
	if locked_out() or m.player.frozen or m.player.rolling():
		return
	var sp: = current()
	if sp.is_empty():
		return
	if heat < cost_of(sp):
		AudioScript.sfx("fail")
		if fx:
			fx.text(m.player.global_position + Vector2(0, -24), "Need %d Heat" % int(cost_of(sp)), Color("#ff8060"))
		return
	match str(sp["id"]):
		"spatter": _spatter(sp)
		"pinwheel": _pinwheel(sp)
		"holler": _holler(sp)
		"counter": _counter(sp)
		"feast": _feast(sp)
		"salamander":
			charging = true
			charge_t = 0.0
			AudioScript.sfx("tele")
			m.apply_gear()
		"eightysix": _eighty_six(sp)
		"julienne": _julienne(sp)
		"brulee": _brulee(sp)
		"tempura": _tempura(sp)
		"snare": _snare(sp)
		"hashbrown": _hashbrown(sp)

func special_released() -> void :
	if not charging:
		return
	charging = false
	m.apply_gear()
	if charge_t < 0.35:
		if fx:
			fx.text(m.player.global_position + Vector2(0, -24), "Hold to charge!", Color("#ffc060"))
		return
	_salamander(_find("salamander"), clampf(charge_t / 1.6, 0.25, 1.0))

func demon_pressed() -> void :
	if not demon_unlocked:
		m._toast("Not yet. Something in you is still asleep. (Reach Seniority Lv %d or beat a story boss.)" % DEMON_UNLOCK_LEVEL)
		return
	if demon_t > 0.0 or crash_t > 0.0:
		return
	if heat < heat_max() - 0.01:
		AudioScript.sfx("fail")
		m._toast("Demon Time needs a FULL Heat meter.")
		return
	demon_t = 999.0
	AudioScript.sfx("explosion")
	if ui:
		ui.demon_card()
	m.apply_gear()

func _end_demon() -> void :
	demon_t = 0.0
	crash_t = CRASH_TIME
	m.player.demon = false
	m._toast("The Crash. 2am energy, 6am consequences.")
	m.apply_gear()



func _find(id: String) -> Dictionary:
	for s in SPECIALS:
		if s["id"] == id:
			return s
	return {}

func _pay(sp: Dictionary) -> void :
	heat -= cost_of(sp)

func _atk() -> float:
	return m.player_atk() * dmg_mult()

func _shot(kind: String, pos: Vector2, vel: Vector2, dmg: float) -> Node2D:
	var s: = Shot.new()
	s.c = self
	s.kind = kind
	s.dmg = dmg
	s.vel = vel
	s.owner_ref = m.player
	s.global_position = pos
	m.add_child(s)
	return s

func _spatter(sp: Dictionary) -> void :
	_pay(sp)
	var p: Node = m.player
	var f: Vector2 = p.facing.normalized()
	for a in [-0.22, 0.0, 0.22]:
		_shot("grease", p.global_position + f * 8.0, f.rotated(a) * 170.0, _atk() * 1.0)
	AudioScript.sfx("fryer", 1.4)
	p.swing_t = 0.12


func _hashbrown(sp: Dictionary) -> void :
	_pay(sp)
	var p: Node = m.player
	var c0: Vector2 = p.global_position
	for i in 10:
		_shot("hashbrown", c0, Vector2.from_angle(TAU * i / 10.0) * 140.0, _atk() * 1.2)
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and e.global_position.distance_to(c0) < 70.0 and e.kind != "driver":
			e.stun = maxf(float(e.stun), 0.5 if e.is_in_group("boss") else 1.2)
	AudioScript.sfx("fryer", 1.1)
	if fx:
		fx.text(c0 + Vector2(0, -26), "SCATTERED!", Color("#f0c040"))
	p.swing_t = 0.2
	get_tree().create_timer(0.35, false).timeout.connect( func() -> void :
		if not is_instance_valid(p):
			return
		var c1: Vector2 = p.global_position
		for i in 10:
			_shot("hashbrown", c1, Vector2.from_angle(TAU * (i + 0.5) / 10.0) * 140.0, _atk() * 1.2)
		if fx:
			fx.text(c1 + Vector2(0, -26), "COVERED!", Color("#f0c040")))

func _pinwheel(sp: Dictionary) -> void :
	_pay(sp)
	var p: Node = m.player
	var s: = _shot("plate", p.global_position + p.facing * 6.0, p.facing.normalized() * 150.0, _atk() * 1.5)
	s.boomerang = true
	AudioScript.sfx("whoosh")
	p.swing_t = 0.15

func _holler(sp: Dictionary) -> void :
	_pay(sp)
	var p: Node = m.player
	var c: Vector2 = p.global_position
	AudioScript.sfx("honk", 0.7)
	if fx:
		fx.ring(c, 62.0, Color("#ffe080"))
		fx.text(c + Vector2(0, -30), "HEARD, CHEF!", Color("#ffe080"), 1.2, 9)
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.global_position.distance_to(c) < 62.0:
			hit(e, (e.global_position - c).normalized(), _atk() * 0.5, "stun", 0.0)
			if not e.is_in_group("boss"):
				e.stun = 1.6
	for pr in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(pr) and pr.global_position.distance_to(c) < 62.0:
			pr.queue_free()

func _counter(sp: Dictionary) -> void :
	_pay(sp)
	counter_t = 0.4
	m.player.counter_pose = 0.4
	AudioScript.sfx("swing", 0.6)


func counter_success(from: Vector2, kind: String) -> void :
	var p: Node = m.player
	counter_t = 0.0
	AudioScript.sfx("bonk", 0.6)
	heat = minf(heat_max(), heat + 15.0)
	var d: Vector2 = (from - p.global_position).normalized()
	if d == Vector2.ZERO:
		d = p.facing
	if fx:
		fx.text(p.global_position + Vector2(0, -24), "PANG!", Color("#ffffff"), 0.8, 9)
		fx.ring(p.global_position, 18.0, Color("#ffffff"))
	_shot("reflect", p.global_position + d * 8.0, d * 220.0, _atk() * 2.0)
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < 22.0:
			hit(e, d, _atk() * 1.5, "stun", 0.0)

func _counter_scan() -> void :
	var p: Node = m.player
	for pr in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(pr) and not pr.is_queued_for_deletion() and pr.global_position.distance_to(p.global_position) < 16.0:
			var from: Vector2 = pr.global_position
			pr.queue_free()
			counter_success(from - (p.global_position - from), "projectile")
			return

func _feast(sp: Dictionary) -> void :
	_pay(sp)
	feast_t = 0.9
	m.player.frozen = true
	m.player.eating = 0.9
	AudioScript.sfx("pickup")

func _finish_feast() -> void :
	var heal: float = 25.0 + 2.0 * stats["grit"]
	m.energy = minf(m.energy_cap(), m.energy + heal)
	fed_t = 8.0
	if fx:
		fx.text(m.player.global_position + Vector2(0, -26), "+%d Energy" % int(heal), Color("#a0ff90"))
	m._toast("Family meal. Somebody's grandma's recipe. +%d Energy, hitting harder for 8s." % int(heal))

func _salamander(sp: Dictionary, power: float) -> void :
	_pay(sp)
	var p: Node = m.player
	AudioScript.sfx("laser", 0.7)
	if fx:
		fx.beam(p, p.facing.normalized(), 210.0, 8.0 + 10.0 * power, 0.55, _atk() * (0.5 + 0.6 * power))
	p.swing_t = 0.3

func _julienne(sp: Dictionary) -> void :
	_pay(sp)
	var p: Node = m.player
	julienne_marks.clear()
	dash_t = 0.24
	p.dash_t = 0.3
	p.knock = p.facing.normalized() * 330.0
	AudioScript.sfx("whoosh", 1.3)

func _brulee(sp: Dictionary) -> void :
	_pay(sp)
	brulee_t = 4.0
	brulee_tick = 0.0
	AudioScript.sfx("fryer", 0.6)

func _tempura(sp: Dictionary) -> void :
	_pay(sp)
	tempura_t = 1.6
	tempura_tick = 0.0
	m.apply_gear()
	AudioScript.sfx("whoosh", 0.7)

func _snare(sp: Dictionary) -> void :
	var p: Node = m.player
	var best: Node = null
	var best_score: = 9999.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or e.is_queued_for_deletion() or e.kind == "driver":
			continue
		var rel: Vector2 = e.global_position - p.global_position
		if rel.length() > 95.0:
			continue
		var score: = rel.length() - 25.0 * rel.normalized().dot(p.facing.normalized())
		if score < best_score:
			best_score = score
			best = e
	if best == null:
		AudioScript.sfx("fail")
		m._toast("Nothing in range to vacuum-seal.")
		return
	_pay(sp)
	var dur: = 1.0 if best.is_in_group("boss") else 3.0
	best.stun = dur
	snared.append({"e": best, "t": dur})
	AudioScript.sfx("pickup", 0.6)
	if fx:
		fx.text(best.global_position + Vector2(0, -22), "Set it and forget it.", Color("#a0e8ff"), 1.2, 6)

func _tick_moves(delta: float) -> void :
	var p: Node = m.player

	if dash_t > 0.0:
		dash_t -= delta
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and not julienne_marks.has(e) and e.global_position.distance_to(p.global_position) < 16.0:
				julienne_marks.append(e)
				if fx:
					fx.cut(e.global_position, p.facing)
		if dash_t <= 0.0:
			julienne_hit_t = 0.35
	if julienne_hit_t > 0.0:
		julienne_hit_t -= delta
		if julienne_hit_t <= 0.0:
			if not julienne_marks.is_empty():
				AudioScript.sfx("hit", 1.4)
			for e in julienne_marks:
				if is_instance_valid(e):
					hit(e, p.facing, _atk() * 2.2, "", 2.0)
			julienne_marks.clear()

	if brulee_t > 0.0:
		brulee_t -= delta
		brulee_tick -= delta
		if brulee_tick <= 0.0:
			brulee_tick = 0.25
			for e in get_tree().get_nodes_in_group("enemy"):
				if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < 24.0 + (8.0 if e.is_in_group("boss") else 0.0):
					hit(e, (e.global_position - p.global_position).normalized(), _atk() * 0.6, "", 1.0)

	if tempura_t > 0.0:
		tempura_t -= delta
		tempura_tick -= delta
		for e in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(e) or e.is_in_group("boss") or e.kind == "driver":
				continue
			var rel: Vector2 = p.global_position - e.global_position
			if rel.length() < 75.0 and rel.length() > 10.0:
				e.knock = rel.normalized() * 70.0
		if tempura_tick <= 0.0:
			tempura_tick = 0.2
			for e in get_tree().get_nodes_in_group("enemy"):
				if is_instance_valid(e) and e.global_position.distance_to(p.global_position) < 26.0 + (8.0 if e.is_in_group("boss") else 0.0):
					hit(e, (e.global_position - p.global_position).normalized(), _atk() * 0.5, "", 1.0)
		if tempura_t <= 0.0:
			m.apply_gear()

	for sn in snared:
		sn["t"] -= delta
		if is_instance_valid(sn["e"]) and sn["t"] > 0.0:
			sn["e"].stun = maxf(sn["e"].stun, 0.05)
	snared = snared.filter( func(sn): return sn["t"] > 0.0 and is_instance_valid(sn["e"]) and not sn["e"].is_queued_for_deletion())


func _eighty_six(sp: Dictionary) -> void :
	var p: Node = m.player
	var target: Node = null
	var best: = 150.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and not e.is_queued_for_deletion() and e.kind != "driver":
			var d: float = e.global_position.distance_to(p.global_position)
			if d < best:
				best = d
				target = e
	if target == null:
		AudioScript.sfx("fail")
		m._toast("Nobody close enough to 86.")
		return
	_pay(sp)
	cinematic = true
	charging = false
	get_tree().paused = true
	p.frozen = true
	var dest: Vector2 = target.global_position - (target.global_position - p.global_position).normalized() * 10.0
	if ui:
		ui.dim(true)
	AudioScript.sfx("tele", 0.5)
	var tw: = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.35)
	tw.tween_property(p, "global_position", dest, 0.7).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback( func() -> void :
		if ui:
			ui.blackout(1.3)
		_flurry_sounds())
	tw.tween_interval(1.35)
	tw.tween_callback( func() -> void : _eighty_six_land(target, dest))
	tw.tween_interval(1.6)
	tw.tween_callback(_eighty_six_end)

func _flurry_sounds() -> void :
	var tw: = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for i in 9:
		tw.tween_callback( func() -> void : AudioScript.sfx(["hit", "swing", "bonk"][i % 3], 0.8 + 0.05 * i))
		tw.tween_interval(0.13)

func _eighty_six_land(target: Node, at: Vector2) -> void :
	var p: Node = m.player
	var atk: = _atk()
	get_tree().paused = false
	for e in get_tree().get_nodes_in_group("enemy").duplicate():
		if not is_instance_valid(e) or e.is_queued_for_deletion() or e.kind == "driver":
			continue
		if e != target and e.global_position.distance_to(at) > 70.0:
			continue
		var dmg: = atk * 20.0
		if e.is_in_group("boss"):
			dmg = maxf(atk * 8.0, float(e.max_hp) * 0.15)
		hit(e, (e.global_position - p.global_position).normalized(), dmg, "flip", 0.0)
	get_tree().paused = true
	p.facing = Vector2.UP
	p.eighty_six = 1.6
	if ui:
		ui.dim(false)
		ui.banner("Kitchen's closed.", Color("#ffffff"), 1.5)
	if fx:
		fx.receipt(p.global_position + Vector2(10, -20))
	AudioScript.sfx("explosion", 0.8)

func _eighty_six_end() -> void :
	get_tree().paused = false
	cinematic = false
	m.player.frozen = false
	m.player.eighty_six = 0.6
	m._toast("86'd. Ticket's on the spike. Kitchen's closed.")
