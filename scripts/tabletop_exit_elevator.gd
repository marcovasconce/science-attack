extends "res://scripts/cooperative_elevator.gd"
## Reuses the tutorial cabin, boarding checks, companion approach and ascent.
func can_unlock() -> bool:
	return is_instance_valid(arena.route) and arena.route.sample_taken and not arena.route.complete and both_equipped()

func unlock_route() -> void:
	available = true # The route owns the tabletop boundaries and checkpoints.

func prepare_departure_ui() -> void:
	arena.encounter.clear()
	arena.get_node("HUD/AdvanceArrow").hide()
	arena.get_node("HUD/Goal").hide()

func _physics_process(dt: float) -> void:
	if is_instance_valid(arena.route) and arena.route.complete:
		$Hint.hide()
		return
	# Do not evaluate the tutorial's unavailable hint on this stage.
	if state == State.WAITING and not available and not can_unlock():
		$Hint.hide()
		return
	super._physics_process(dt)
	if state == State.WAITING:
		$Hint.visible = available and absf(arena.players[0].position.x-position.x) < 180
		$Hint.text = "UM EM CADA MARCA"

func _advance_ascent(dt: float) -> void:
	super._advance_ascent(dt)
	if state == State.LOADING and next_scene_path.is_empty(): loading_label.text = "RUMO À ESTUFA"

func _finish_without_scene(message: String) -> void:
	if not next_scene_path.is_empty():
		super._finish_without_scene(message)
		return
	state = State.COMPLETE
	# The greenhouse is not authored yet. Finish the chapter after the ride.
	# Restore the cabin so the existing exploration button remains usable.
	cabin.position = Vector2.ZERO
	for i in arena.players.size(): arena.players[i].global_position = rider_origins[i]
	black.color.a = 0
	loading_label.hide()
	arena.route._finish_chapter()
