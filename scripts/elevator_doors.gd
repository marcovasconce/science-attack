@tool
extends Control
## Two sliding steel panels clipped inside the existing cabin's doorway.
@export_range(0,1) var openness := 0.0:
	set(value):
		openness = clampf(value,0,1)
		queue_redraw()

func _draw() -> void:
	var half := size.x*0.5
	for side in 2:
		var x := -half*openness if side==0 else half+half*openness
		var rect := Rect2(x,0,half,size.y)
		draw_rect(rect,Color("091826"))
		draw_rect(rect.grow(-2),Color("405f73"))
		draw_rect(Rect2(x+5,5,half-10,size.y-10),Color("2b435a"))
		draw_line(Vector2(x+5,5),Vector2(x+half-5,5),Color("88abb9"),2)
		for y in [20,29,38]: draw_rect(Rect2(x+15,y,half-30,3),Color("122738"))
		var edge := x+half-7 if side==0 else x+5
		draw_rect(Rect2(edge,5,2,size.y-10),Color("5ce8e2"))
		for offset in range(10,int(half)-8,20):
			draw_colored_polygon(PackedVector2Array([Vector2(x+offset,size.y-24),Vector2(x+offset+10,size.y-24),Vector2(x+offset+2,size.y-12),Vector2(x+offset-8,size.y-12)]),Color("edbd4c"))
