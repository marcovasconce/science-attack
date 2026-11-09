@tool
extends Control
@export var action_text := "FALAR"
var key_text := "E"
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
func _draw() -> void:
	var width := 34 + action_text.length() * 8
	draw_rect(Rect2(0,0,width,22), Color("080e21"))
	draw_rect(Rect2(1,1,width-2,20), Color("5489d6"))
	draw_rect(Rect2(3,3,width-6,16), Color("102346"))
	draw_rect(Rect2(5,4,18,14), Color("b2d9ff"))
	draw_string(FONT,Vector2(10,15),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("102346"))
	draw_string(FONT,Vector2(29,15),action_text,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
func set_player(player_id: int) -> void:
	key_text = "E" if player_id == 0 else "U"
	queue_redraw()
