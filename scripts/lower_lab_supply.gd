extends "res://scripts/cartoon_crate.gd"
## A single independent 50% roll per destroyed box; never rerolled by extra hits.
const Pickup = preload("res://scripts/lower_lab_healing_pickup.gd")
var loot_rolled := false
var loot_roll := -1.0

func _ready() -> void:
	drops_salvage = false
	super._ready()

func take_hit(damage: int, direction: float, player) -> void:
	super.take_hit(damage,direction,player)
	if not broken or loot_rolled: return
	loot_rolled = true
	if loot_roll < 0: loot_roll = randf()
	if loot_roll >= 0.5: return
	var pickup := Pickup.new()
	pickup.position = global_position
	arena.add_child(pickup)
