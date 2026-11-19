extends Node2D
const WALL = preload("res://assets/environment/lower_lab/shaft_wall.png")
const DECK = preload("res://assets/environment/lower_lab/shaft_deck.png")
var travel := 0.0
func _process(_dt: float) -> void: queue_redraw()
func _draw() -> void:
	var offset := fposmod(travel*74,320)
	# Moving the fixed shaft upward makes the standing platform visibly descend.
	for i in range(-1,2): draw_texture(WALL,Vector2(0,i*320-offset))
	for rail in [148,465]:
		for i in 4:
			var y := fposmod(i*103-travel*74,400)-40
			draw_rect(Rect2(rail,y,3,18),Color("83a243"))
			draw_rect(Rect2(rail+2,y+14,2,7),Color("a2d54a"))
	draw_texture(DECK,Vector2(0,184))
