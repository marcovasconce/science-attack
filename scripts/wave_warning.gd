extends Control
## Pixel biohazard emblem: five quick pulses, exactly one second in total.
const DURATION := 1.0
var elapsed := 0.0
var running := false

func start() -> void:
	elapsed = 0
	running = true
	show()
	queue_redraw()

func advance(dt: float) -> bool:
	if not running: return false
	elapsed = minf(DURATION, elapsed + dt)
	visible = elapsed < DURATION and int(elapsed * 10) % 2 == 0
	if elapsed >= DURATION:
		running = false
		hide()
		return true
	return false

func _draw() -> void:
	var ink := Color("270f1b")
	var red := Color("ff393b")
	# Three hooked lobes around the central warning cell, inspired by biohazard.
	var lobe := PackedVector2Array([Vector2(-8,-7), Vector2(-16,-13), Vector2(-17,-21), Vector2(-10,-27), Vector2(-9,-20), Vector2(-5,-17), Vector2(5,-17), Vector2(9,-20), Vector2(10,-27), Vector2(17,-21), Vector2(16,-13), Vector2(8,-7)])
	for i in 3:
		var shape := PackedVector2Array()
		for point in lobe: shape.append(Vector2(28,29) + point.rotated(i * TAU / 3).snapped(Vector2(2,2)) * 0.85)
		draw_colored_polygon(shape, red)
		shape.append(shape[0])
		draw_polyline(shape, ink, 3)
	draw_rect(Rect2(23,24,10,10), ink)
	draw_rect(Rect2(25,26,6,6), red)

