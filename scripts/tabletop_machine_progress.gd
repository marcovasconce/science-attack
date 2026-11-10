extends Node2D
@onready var route = get_parent()

func _draw() -> void:
	if route.step < route.Step.DEFENSE: return
	var progress: float = clampf(route.charge/(route.WAVE_CHARGE*3),0,1)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("17364b")
	frame.border_color = Color("76adb4")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(2)
	draw_style_box(frame,Rect2(0,0,146,8))
	draw_rect(Rect2(2,2,142*progress,4),Color("67dfbd"))
