extends Node2D
signal opened
const TEXTURE = preload("res://assets/environment/lower_lab/door_side.png")
const SIZE := Vector2(32,258)
var openness := 0.0
var opening := false
var collision: CollisionShape2D
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	collision = CollisionShape2D.new()
	collision.name = "Collision"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18,180)
	collision.shape = shape
	collision.position.y = -88
	body.add_child(collision)

func unlock() -> void:
	opening = true

func _process(dt: float) -> void:
	if not opening or arena.controls_locked or openness >= 1: return
	openness = minf(1,openness + dt * 0.8)
	if openness >= 0.95: collision.set_deferred("disabled",true)
	if openness >= 1: opened.emit()
	queue_redraw()

func _piece(region: Rect2) -> void:
	var pixels := TEXTURE.get_size()
	draw_texture_rect_region(TEXTURE,Rect2(Vector2(-SIZE.x/2,-SIZE.y) + region.position*SIZE,region.size*SIZE),Rect2(region.position*pixels,region.size*pixels))

func _draw() -> void:
	# Edge-on sliding spine, with only the small upper/lower housings fixed.
	_piece(Rect2(0,0,1,0.14))
	_piece(Rect2(0,0.87,1,0.13))
	if openness < 1:
		var destination := Rect2(0,0.14,1,0.73*(1-openness))
		var source := Rect2(0,0.14+0.73*openness,1,0.73*(1-openness))
		var pixels := TEXTURE.get_size()
		draw_texture_rect_region(TEXTURE,Rect2(Vector2(-SIZE.x/2,-SIZE.y)+destination.position*SIZE,destination.size*SIZE),Rect2(source.position*pixels,source.size*pixels))
	draw_rect(Rect2(-4,-SIZE.y+17,8,3),Color("84ffb0") if opening else Color("ff773e"))
