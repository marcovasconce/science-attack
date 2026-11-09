extends Node2D
const FRAMES = preload("res://assets/animations/germ_poses.tres")
var variant := "green"
var frame := 0
var motion_time := 0.0
var walking := 0.0

func _draw() -> void:
	var texture: AtlasTexture = FRAMES.get_frame_texture(variant,frame)
	var size: Vector2 = texture.get_meta("draw_size")
	# Normalize the source crops so a taller laugh frame does not pop upward.
	size *= (46.0 if variant == "red" else 28.0)/size.y
	var breath := sin(motion_time*TAU*1.15)
	size *= Vector2(1.0-breath*0.025,1.0+breath*0.025)
	var sway := sin(motion_time*TAU*2.4)*walking
	var foot := Vector2(24+sway*0.7,52-absf(sway)*0.7)
	draw_texture_rect(texture,Rect2(foot-Vector2(size.x*0.5,size.y),size),false)
