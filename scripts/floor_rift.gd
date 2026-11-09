@tool
extends Node2D
## A visible opening in the metal floor; the arena's Gate body blocks its span.
func _draw() -> void:
	var opening := PackedVector2Array([Vector2(580, 178), Vector2(614, 181), Vector2(640, 176), Vector2(684, 180), Vector2(720, 177), Vector2(760, 180), Vector2(766, 207), Vector2(760, 232), Vector2(765, 259), Vector2(759, 288), Vector2(765, 319), Vector2(760, 364), Vector2(580, 364), Vector2(576, 332), Vector2(582, 302), Vector2(575, 277), Vector2(580, 246), Vector2(575, 215)])
	draw_colored_polygon(opening, Color("080e18"))
	draw_rect(Rect2(585, 185, 170, 182), Color("0c1823"))
	draw_colored_polygon(PackedVector2Array([Vector2(580, 180), Vector2(600, 196), Vector2(600, 360), Vector2(580, 360), Vector2(575, 277), Vector2(580, 246), Vector2(575, 215)]), Color("172c38"))
	draw_colored_polygon(PackedVector2Array([Vector2(760, 180), Vector2(742, 198), Vector2(742, 360), Vector2(760, 360), Vector2(765, 319), Vector2(759, 288), Vector2(765, 259), Vector2(760, 232), Vector2(766, 207)]), Color("13232f"))
	for y in [207, 252, 303, 344]:
		draw_rect(Rect2(585, y, 7, 3), Color("2b4350"))
		draw_rect(Rect2(750, y + 4, 7, 3), Color("273f4b"))
	var rim := opening.duplicate()
	rim.append(opening[0])
	draw_polyline(rim, Color("617b83"), 3.0)
	draw_polyline(PackedVector2Array([Vector2(578, 181), Vector2(574, 210), Vector2(580, 244), Vector2(573, 277), Vector2(580, 302), Vector2(574, 332), Vector2(578, 360)]), Color("91a6a4"), 1.0)
