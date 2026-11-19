extends Node2D

const ART = preload("res://assets/third_party/alejandrohaibi/bubble.png")
var king
var flight_target := Vector2.ZERO
var dead := false
var flight_height := 28.0
var returned := false
var age := 0.0
var velocity := Vector2.ZERO
var visual := Sprite2D.new()
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	add_to_group("germs")
	add_to_group("royal_bubbles")
	var crop := AtlasTexture.new()
	crop.atlas = ART
	crop.region = Rect2(14, 14, 38, 38)
	visual.texture = crop
	visual.position.y = -flight_height
	visual.scale = Vector2.ONE * 1.65
	visual.modulate = Color("fff089")
	add_child(visual)
	var direction := position.direction_to(flight_target)
	if direction.length_squared() < 0.1: direction = Vector2.LEFT
	velocity = direction * 146.0

func _physics_process(dt: float) -> void:
	if arena.controls_locked or dead: return
	age += dt
	if returned:
		position = position.move_toward(king.position, 535.0 * dt)
		if position.distance_to(king.position) <= 23.0:
			king.reflected_bubble()
			_pop()
		return
	position += velocity * dt
	visual.rotation = age * 0.75 if not SceneFx.reduced_motion else 0.0
	if position.x < arena.room_left + 18.0 or position.x > arena.room_right - 16.0:
		velocity.x = -velocity.x
		position.x = clampf(position.x, arena.room_left + 18.0, arena.room_right - 16.0)
	if position.y < 237.0 or position.y > 316.0:
		velocity.y = -velocity.y
		position.y = clampf(position.y, 237.0, 316.0)
	if age > 4.3:
		_pop()
		return
	for player in arena.players:
		if player.down or player.invulnerable > 0 or player.jump_height > 32.0: continue
		if absf(position.x - player.position.x) < 23.0 and absf(position.y - player.position.y) < 17.0:
			player.take_hit(16, position)
			_pop()
			return

func can_be_hit(_height: float) -> bool:
	return not returned and not dead

func take_hit(_damage: int, _direction: float) -> void:
	if not can_be_hit(0.0): return
	returned = true
	remove_from_group("germs")
	visual.modulate = Color("89fff5")
	GameAudio.effect("bounce", global_position)

func _pop() -> void:
	dead = true
	GameAudio.effect("bubble", global_position)
	var burst: Node2D = arena.spawn_impact(1, position - Vector2(0, flight_height), 1)
	burst.modulate = visual.modulate
	queue_free()
