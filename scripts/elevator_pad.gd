@tool
extends Node2D
## Pixel pressure plate. Its color is driven by a grounded player's feet.
@export var occupied := false:
	set(value):
		occupied = value
		queue_redraw()

func _draw() -> void:
	var base := Color("236b48") if occupied else Color("7d2534")
	var light := Color("73f5a1") if occupied else Color("ff6678")
	draw_rect(Rect2(-27,-12,54,27),Color("071522"))
	draw_rect(Rect2(-25,-10,50,22),Color("718b9c"))
	draw_rect(Rect2(-22,-8,44,18),base)
	draw_rect(Rect2(-20,-7,40,3),light)
	draw_rect(Rect2(-20,7,40,2),light)
	for x in [-24,22]:
		for y in [-9,10]: draw_rect(Rect2(x,y,2,2),Color("c2d7dc"))
	if occupied:
		draw_polyline(PackedVector2Array([Vector2(-6,0),Vector2(-2,4),Vector2(7,-4)]),light,2)
	else:
		draw_rect(Rect2(-5,-1,10,3),light)
