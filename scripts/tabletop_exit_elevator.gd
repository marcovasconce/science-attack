extends "res://scripts/cooperative_elevator.gd"
## Reuses the cabin and boarding checks for the descent to the lower laboratory.
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
		$Hint.visible = available and absf(arena.camera_center().x-position.x) < 180
		$Hint.text = boarding_hint()

