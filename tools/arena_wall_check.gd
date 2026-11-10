extends Node
## Per-arena wall check: pushes Duff up/left/right/down from the arena centre in each listed arena and prints
## where he stops (relative to ARENA_ORIGIN). Run:
##   godot --headless --path . res://tools/arena_wall_check.tscn
const ARENAS: = ["gymbro", "alley", "ghoster", "djvape", "crypto", "willnot", "waffle"]
var game: Node
var m: Node
var frame: = 0

func _ready() -> void:
	game = load("res://main.tscn").instantiate()
	add_child(game)
	m = game

func _physics_process(_d: float) -> void:
	frame += 1
	if frame < 30:
		return
	for a in ARENAS:
		m.in_title = false
		m.close_overlay()
		m.start_story_fight(a)
		if m.arena_id != a:
			m.arena_id = a  # bounty / bet / shift arenas have no story fight: just switch the walls
		if m.arena_id != a:
			print("arena_wall_check: could not start ", a)
		if m.arena_boss:
			m.arena_boss.queue_free()
			m.arena_boss = null
		var res: = []
		for dir in [Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]:
			m.player.position = m.ARENA_ORIGIN + Vector2(160, 110)
			for i in 40:
				m.player.move_and_collide(dir * 8.0)
			res.append(m.player.position - m.ARENA_ORIGIN)
		print("arena_wall_check %s up %s left %s right %s down %s" % [a, res[0], res[1], res[2], res[3]])
		m.arena_id = ""
	get_tree().quit()
