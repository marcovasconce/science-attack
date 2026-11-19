extends Node2D

var clock := 0.0

func _process(delta: float) -> void:
	if SceneFx.reduced_motion: return
	clock += delta
	queue_redraw()

func _draw() -> void:
	for i in 2:
		var angle := (-0.49 if i == 0 else 0.5) + sin(clock * 0.9 + i) * 0.065
		var ink := Color("9cecff") if i == 0 else Color("c5bbff")
		draw_set_transform(Vector2.ZERO, angle, Vector2(1.0, 0.38))
		draw_arc(Vector2.ZERO, 114.0, 0.0, TAU, 64, Color(ink, 0.67), 3.0)
		var phase := clock * (1.3 if i == 0 else -1.5) + i * 1.9
		var point := Vector2.from_angle(phase) * 114.0
		draw_circle(point, 7.0, Color(ink, 0.38))
		draw_circle(point, 4.0, ink)
