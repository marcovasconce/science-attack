extends Node
var step := 7
var unlocked := true
func record_action(_action: String, _player) -> void: pass
func is_modal() -> bool: return get_parent().transitioning
func is_transitioning() -> bool: return get_parent().transitioning
func ai_boarding_destination(_player) -> Variant: return null
