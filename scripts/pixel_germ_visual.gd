extends Node2D
## All germ art is sampled on a fixed logical pixel grid, then displayed at 2x.
const Pose = preload("res://scripts/pixel_germ_pose.gd")
var canvas: SubViewport
var pose: Node2D
var display: Sprite2D
var frame := -1
var motion_sample := -1

func setup(variant: String) -> void:
	canvas = SubViewport.new()
	canvas.size = Vector2i(48,56)
	canvas.transparent_bg = true
	canvas.disable_3d = true
	canvas.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(canvas)
	pose = Pose.new()
	pose.variant = variant
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded; void fragment(){if(COLOR.a<0.8){discard;} COLOR.a=1.0;}"
	var material := ShaderMaterial.new()
	material.shader = shader
	pose.material = material
	canvas.add_child(pose)
	display = Sprite2D.new()
	display.texture = canvas.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.scale = Vector2(2,2)
	display.position = Vector2(0,-48)
	add_child(display)
	sync(0,false)
	queue_redraw()

func sync(time: float, flipped: bool, walking := 0.0) -> void:
	# Evenly spaced facial poses return through intermediate frames. The body
	# breathes and sways at 30 Hz on the original logical pixel grid.
	var index: int = [0,1,2,3,2,1][int(time*8)%6]
	display.flip_h = flipped
	var sample_index := int(time*30)
	if index == frame and sample_index == motion_sample: return
	motion_sample = sample_index
	canvas.render_target_update_mode = SubViewport.UPDATE_ONCE
	frame = index
	pose.frame = index
	pose.motion_time = time
	pose.walking = walking
	pose.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-18,0,36,4),Color(0.04,0.1,0.12,0.28))
	draw_rect(Rect2(-12,-2,24,8),Color(0.04,0.1,0.12,0.16))
