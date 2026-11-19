extends Control
## Deterministic bubbles cover every screen tile, then pop to reveal the cleaned sewer.
var coverage := 0.0
var age := 0.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	hide()
func update_cover(amount: float, time: float) -> void:
	coverage = clampf(amount,0,1)
	age = time
	visible = coverage > 0
	queue_redraw()
func _draw() -> void:
	if coverage <= 0: return
	# Opaque soap under the overlapping bubbles guarantees full coverage at the peak.
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.77,0.95,1.0,smoothstep(0.62,1.0,coverage)))
	var columns := ceili(size.x/48)+1
	var rows := ceili(size.y/42)+1
	for row in rows:
		for col in columns:
			var delay := float((col*7+row*3)%9)*0.018
			var swell := clampf((coverage-delay)/0.82,0,1)
			if swell == 0: continue
			var center := Vector2(col*48+(row%2)*24,row*42)
			center += Vector2((col*13+row*7)%23-11,(col*11+row*17)%19-9)
			center += Vector2(sin(age*1.5+row+col)*5,cos(age*1.2+col)*4)
			var radius := (25+((col*7+row*11)%18))*swell
			var poly := PackedVector2Array()
			for k in 17: poly.append((center+Vector2.from_angle(k*TAU/16)*radius).round())
			draw_colored_polygon(poly,Color("b4e8f5") if (col+row)%2 else Color("d8f8ff"))
			draw_polyline(poly,Color("f4ffff"),2,false)
			draw_arc(center, radius*0.75,3.4,4.6,6,Color.WHITE,3,false)
			draw_rect(Rect2((center+Vector2(radius*0.42,radius*0.42)).round(),Vector2(3,3)),Color("b6b8ed"))

