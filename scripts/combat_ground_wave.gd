extends Node2D
## One readable contact burst; its outline and expanding ring share the damage origin.
const ART = preload("res://assets/effects/king_slime_shockwave.png")
var age := 0.0
var lifetime := 0.8
var brush := false
var radius := Vector2(125,33)
@onready var arena = get_tree().get_first_node_in_group("arena")
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if brush:
		lifetime = 0.56
		radius = Vector2(90,34)
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment(){vec4 c=COLOR;float v=max(c.r,max(c.g,c.b));COLOR=vec4(v,min(v,c.r*0.75+c.g*0.35),min(v,c.b*0.23),c.a);}"
		var palette := ShaderMaterial.new()
		palette.shader = shader
		material = palette
	queue_redraw()
func _process(dt: float) -> void:
	if arena != null and arena.controls_locked: return
	age += dt
	if age >= lifetime: queue_free()
	queue_redraw()
func _draw() -> void:
	var frame := mini(15,int(age/lifetime*16))
	var cell := Vector2(ART.get_size())/4.0
	var size := Vector2(radius.x*2.1,112 if brush else 170)
	# The sheet's ground is at ~91% of cell height, aligned to the actual strike.
	draw_texture_rect_region(ART,Rect2(Vector2(-size.x/2,-size.y*0.91),size),Rect2(Vector2(frame%4,frame/4)*cell,cell))
	var progress := clampf(age/(lifetime*0.68),0,1)
	if progress < 1:
		var ring := PackedVector2Array()
		for i in 33:
			ring.append((Vector2(cos(i*TAU/32),sin(i*TAU/32))*radius*progress).round())
		draw_polyline(ring,Color("173c29"),5,false)
		draw_polyline(ring,Color("e4ffab"),2,false)

