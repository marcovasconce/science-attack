extends Node2D
@onready var route = get_parent()

func _draw() -> void:
	if route.step < route.Step.DEFENSE: return
	# Independent foreground layer: tank sprites cannot cover this indicator.
	var progress: float = clampf(route.charge/(route.WAVE_CHARGE*3),0,1)
	draw_style_box(_frame(),Rect2(0,0,204,12))
	draw_rect(Rect2(3,3,198*progress,6),Color("61ddf5"))

func _frame() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("102346")
	box.border_color = Color("a9e8ed")
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	return box
