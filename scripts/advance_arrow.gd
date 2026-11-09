@tool
extends Control
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
var clock := 0.0
var direction := 1.0
func _process(dt: float) -> void:
	if not visible: return
	clock += dt
	queue_redraw()
func _draw() -> void:
	var panel := PackedVector2Array([Vector2(4,0),Vector2(58,0),Vector2(68,10),Vector2(68,34),Vector2(60,42),Vector2(4,42),Vector2(0,38),Vector2(0,4)])
	draw_colored_polygon(panel, Color("07121f"))
	panel.append(panel[0])
	draw_polyline(panel, Color("55cced"), 2)
	var nudge := roundf(sin(clock * 4) * 2)
	var arrow := PackedVector2Array([Vector2(13,11),Vector2(36,11),Vector2(36,5),Vector2(53,17),Vector2(36,29),Vector2(36,23),Vector2(13,23)])
	for i in arrow.size():
		if direction < 0: arrow[i].x = 68-arrow[i].x
		arrow[i].x += nudge*direction
	draw_colored_polygon(arrow, Color("b2f5ff"))
	draw_rect(Rect2((14 if direction > 0 else 33)+nudge*direction,19,21,3),Color("55cced"))
	draw_string(FONT, Vector2(18,37), "SIGA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
