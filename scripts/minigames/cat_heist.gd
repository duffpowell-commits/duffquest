extends "res://scripts/minigames/stealth.gd"
## Side quest "The Cats' Heist": same floor, same sleeping baby, same cats on patrol. The goal is the cats' stash
## under the bed (where {cat3} lives), and the thing they took tonight is drawn on it.

var item: = "keys"
const ITEMS: = {"keys": "MY KEYS", "wallet": "MY WALLET", "binky": "THE BINKY"}

func _setup() -> void:
	super._setup()
	title = "THE CATS' STASH"
	goal_label = "STASH: " + str(ITEMS.get(item, "???"))

func howto() -> Array:
	return [
		{"i": "", "v": "tap", "s": "Tap a lit tile next to you to step (or arrows). The stash is under the bed."},
		{"i": "", "v": "read", "s": "Warped boards creak. The cats are guarding it. Step around both."},
		{"i": "", "v": "beat", "s": "Tiptoe: one step at a time. Wake the baby and it's over."}]
