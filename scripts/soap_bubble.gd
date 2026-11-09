extends Node2D
## Swept lane collision keeps fast bubbles from tunnelling through targets.
const SPEED := 300.0
const MAX_DISTANCE := 780.0
const DAMAGE := 10
var speed := SPEED
var damage := DAMAGE
var max_distance := MAX_DISTANCE
var radius := 8.0
var giant := false
var special_shot := false
var shooter: Node2D
var direction := 1.0
var travelled := 0.0
var age := 0.0
var height := 28.0
var popping := false
var pop_age := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")
func _physics_process(dt: float) -> void:
	if arena.controls_locked: return
	if not is_instance_valid(shooter):
		queue_free()
		return
	age += dt
	if popping:
		pop_age += dt
		if pop_age >= 0.18: queue_free()
		queue_redraw()
		return
	var start := global_position
	var finish := start + Vector2(direction * speed * dt,0)
	var best_t := 1.01
	var target: Node2D = null
	var query := PhysicsRayQueryParameters2D.create(start,finish,1)
	query.hit_from_inside = true
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): best_t = start.distance_to(wall.position) / maxf(0.001,start.distance_to(finish))
	var candidates := get_tree().get_nodes_in_group("germs")
	if arena.encounter.unlocked: candidates.append_array(get_tree().get_nodes_in_group("training_dummies"))
	if arena.tutorial.step >= 4: candidates.append_array(arena.breakable_props())
	for body in candidates:
		if not is_instance_valid(body) or body.is_queued_for_deletion(): continue
		if body.is_in_group("germs"):
			if body.dead or (shooter.ai_controlled and arena.tutorial.step < 7): continue
		elif not body.is_in_group("training_dummies") and body.broken: continue
		var offset: Vector2 = body.global_position - start
		if absf(offset.y) > (38 if giant else 21): continue
		var distance_ahead := offset.x * direction
		var extent := 16+maxf(0,radius-8)
		if distance_ahead < -extent or distance_ahead > speed * dt + extent: continue
		var t := maxf(0.0,(distance_ahead - extent) / maxf(0.001,speed * dt))
		if t < best_t:
			best_t = t
			target = body
	if best_t <= 1:
		global_position = start.lerp(finish,best_t)
		if giant:
			arena.special_area(shooter,global_position,140,65,damage)
		elif target != null:
			if target.is_in_group("germs"):
				arena.damage_enemy(shooter,target,damage,direction,global_position+Vector2(0,-height),not special_shot)
			elif target.is_in_group("training_dummies"):
				arena.damage_training(shooter,target,damage,direction,not special_shot)
			else: target.take_hit(damage,direction,shooter)
		popping = true
	else:
		global_position = finish
		travelled += speed * dt
		if travelled >= max_distance or position.x < 8 or position.x > arena.world_limit + 8:
			if giant: arena.special_area(shooter,global_position,140,65,damage)
			popping = true
	queue_redraw()
func _draw() -> void:
	var center := Vector2(0,-height + roundf(sin(age*6)*2))
	if popping:
		var spread := radius + pop_age*(240 if giant else 48)
		for i in 8:
			var p := center + Vector2.from_angle(i*TAU/8)*spread
			draw_rect(Rect2(p.round(),Vector2(2,2)),Color(0.65,0.95,1,1-pop_age/0.18))
		return
	var ring := PackedVector2Array()
	for i in 24: ring.append(center + (Vector2.from_angle(i*TAU/24)*radius).round())
	draw_colored_polygon(ring,Color(0.45,0.83,0.95,0.16))
	ring.append(ring[0])
	draw_polyline(ring,Color("99e8ff"),2 if giant else 1)
	if giant:
		draw_arc(center,radius-5,-2.8,-0.6,16,Color("ecffff"),2,false)
		draw_rect(Rect2(center+Vector2(-15,-16),Vector2(6,4)),Color.WHITE)
	draw_rect(Rect2(center+Vector2(-5,-5),Vector2(3,2)),Color.WHITE)
	draw_rect(Rect2(center+Vector2(-6,-3),Vector2(2,3)),Color("e1ffff"))
	draw_rect(Rect2(center+Vector2(3,5),Vector2(3,1)),Color("ffb7ed"))
