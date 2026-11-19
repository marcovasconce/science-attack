extends "res://scripts/tabletop_context.gd"
var unlocked := true
func is_modal() -> bool:
	return get_parent().is_cinematic()
