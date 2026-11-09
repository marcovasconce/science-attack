@tool
extends Node2D
const ART = preload("res://assets/environment/tabletop_laboratory.png")
const WORLD_WIDTH := 7200.0
var camera_left := 0.0

func follow_camera(camera_x: float) -> void:
	camera_left = camera_x-320
	queue_redraw()

func _draw() -> void:
	# One foreground worktop; the distant room scrolls more slowly behind it.
	var room_start := camera_left-fposmod(camera_left*0.35,1280.0)
	for i in 2:
		draw_texture_rect_region(ART,Rect2(room_start+i*1280,0,1280,188),Rect2(0,0,2172,374))
	for i in 3:
		draw_texture_rect_region(ART,Rect2(i*2400,188,2400,146),Rect2(0,374,2172,258))
		draw_texture_rect_region(ART,Rect2(i*2400,334,2400,26),Rect2(0,632,2172,92))
