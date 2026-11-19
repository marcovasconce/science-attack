extends Node2D
## Fixed structural backing stays in place as the cabin travels through it.
@export var bottom_y := -18.0
func _draw() -> void:
	draw_rect(Rect2(-120,-520,240,520+bottom_y),Color("101d28"))
	for y in range(-520,int(bottom_y)-48,52):
		draw_rect(Rect2(-105,y,210,48),Color("233b48"))
		draw_rect(Rect2(-104,y+2,208,2),Color("395662"))
		draw_rect(Rect2(-84,y+11,168,28),Color("1a303d"))
		for x in [-100,96]: draw_rect(Rect2(x,y+7,4,4),Color("678494"))
	for x in [-114,108]:
		draw_rect(Rect2(x-3,-520,12,520+bottom_y),Color("091622"))
		draw_rect(Rect2(x,-520,6,520+bottom_y),Color("547889"))
		draw_rect(Rect2(x,-520,2,520+bottom_y),Color("8cabb5"))
		for y in range(-508,int(bottom_y)-6,32): draw_rect(Rect2(x-2,y,10,5),Color("344e60"))
	for x in [-48,-42,40,46]: draw_rect(Rect2(x,-520,2,520+bottom_y),Color("080f18"))
