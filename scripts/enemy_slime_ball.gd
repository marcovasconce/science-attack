extends Node2D
const TEXTURE = preload("res://assets/enemies/slime_ball.png")
const SPEED := 172.0
const DAMAGE := 10
var height := 70.0
var velocity := Vector2.ZERO
var height_velocity := 0.0
var age := 0.0
var popping := false
var pop_age := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	add_to_group("enemy_projectiles")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func aim_at(target: Vector2) -> void:
	var distance := position.distance_to(target)
	var duration := maxf(0.35,distance/SPEED)
	velocity = (target-position)/duration
	height_velocity = (26-height)/duration

func _physics_process(dt: float) -> void:
	if arena.controls_locked: return
	if popping:
		pop_age += dt
		if pop_age >= 0.2: queue_free()
		queue_redraw()
		return
	age += dt
	var start := position
	var start_height := height
	var finish := start+velocity*dt
	var end_height := height+height_velocity*dt
	var best_t := 1.01
	var victim: Node2D = null
	var query := PhysicsRayQueryParameters2D.create(start,finish,1)
	query.hit_from_inside = true
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): best_t = start.distance_to(wall.position)/maxf(0.001,start.distance_to(finish))
	for player in arena.players:
		if player.down: continue
		var center_height: float = 26+player.jump_height
		var a := Vector3(start.x-player.position.x,start.y-player.position.y,start_height-center_height)/Vector3(21,17,23)
		var b := Vector3(finish.x-player.position.x,finish.y-player.position.y,end_height-center_height)/Vector3(21,17,23)
		var segment := b-a
		var t := clampf(-a.dot(segment)/maxf(0.00001,segment.length_squared()),0,1)
		if (a+segment*t).length_squared() <= 1 and t < best_t:
			best_t = t
			victim = player
	if best_t <= 1:
		position = start.lerp(finish,best_t)
		height = lerpf(start_height,end_height,best_t)
		popping = true
		if victim != null: victim.take_hit(DAMAGE,start)
	else:
		position = finish
		height = end_height
		if age > 4 or height < 4 or position.x < 8 or position.x > arena.world_limit-8: popping = true
	queue_redraw()

func _draw() -> void:
	var cell := TEXTURE.get_size()/Vector2(4,1)
	var frame := int(age*12)%4
	var size := Vector2(24,28)
	if popping: size = Vector2(24+pop_age*70,28-pop_age*90)
	var at := Vector2(0,-height)-size/2
	draw_texture_rect_region(TEXTURE,Rect2(at,size),Rect2(Vector2(frame*cell.x,0),cell),Color(1,1,1,1-pop_age/0.2))
