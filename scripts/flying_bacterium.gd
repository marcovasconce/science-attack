extends CharacterBody2D
## A fly-through attack: keep crossing the screen after contact, never orbit a player.
const SHEET = preload("res://assets/enemies/flying_bacteria.png")
var hp := 1
var max_hp := 1
var dead := false
var speed := 205.0
var phase := 0.0
var age := 0.0
var lane_y := 260.0
var hit_players: Array[int] = []
var passed_players: Array[int] = []
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 16
	phase = float(get_instance_id() % 31) * 0.2
	lane_y = position.y
	$Sprite.texture = SHEET
	$Sprite.hframes = 4

func _physics_process(dt: float) -> void:
	if dead or arena.controls_locked: return
	phase += dt
	age += dt
	var start := position
	velocity = Vector2(-speed, 0)
	move_and_collide(Vector2(-speed*dt,lane_y+sin(phase*3.2)*5-position.y))
	$Sprite.frame = int(phase * 10) % 4
	$Sprite.position.y = -36 + roundf(sin(phase * 5) * 4)
	$Sprite.flip_h = false
	for player in arena.players:
		if position.x < player.position.x and player.player_id not in passed_players:
			passed_players.append(player.player_id)
		if player.down or player.player_id in hit_players: continue
		# Sweep the whole movement segment so fast flies cannot tunnel through a player.
		var a: Vector2 = (start - player.position) / Vector2(27, 18)
		var b: Vector2 = (position - player.position) / Vector2(27, 18)
		if Geometry2D.get_closest_point_to_segment(Vector2.ZERO, a, b).length_squared() <= 1.0:
			hit_players.append(player.player_id)
			player.take_hit(6, start)
	if position.x < arena.get_node("Camera2D").position.x - 390 or age >= 9.0:
		dead = true
		arena.flyer_passed()
		queue_free()

func take_hit(damage: int, _direction: float) -> void:
	if dead or damage <= 0: return
	hp = 0
	dead = true
	arena.germ_defeated(position)
	queue_free()
