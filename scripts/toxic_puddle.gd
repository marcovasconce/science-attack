extends Node2D
const DAMAGE := 8
const COOLDOWN := 1.0
var radius := Vector2(52,17)
var timers: Dictionary = {}
var age := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")

func contains_feet(point: Vector2) -> bool:
	return ((point - global_position) / radius).length_squared() <= 1.0

func _physics_process(dt: float) -> void:
	if arena.controls_locked: return
	age += dt
	queue_redraw()
	for player in arena.players:
		var id: int = player.player_id
		timers[id] = maxf(0, float(timers.get(id, 0.0)) - dt)
		if player.down or not contains_feet(player.global_position): continue
		if timers[id] <= 0 and player.jump_height <= 30 and player.invulnerable <= 0:
			player.take_hit(DAMAGE, global_position + Vector2(0,12))
			timers[id] = COOLDOWN

func _draw() -> void:
	# Bubbles pulse independently of the separate rising vapor particles.
	for i in 3:
		var t := fmod(age * 0.8 + i * 0.31, 1.0)
		if t < 0.7:
			var size := 2 + floorf(t*5)
			draw_rect(Rect2(-28 + i*25,-4 + (i%2)*7,size,size),Color("e3f77b"),false,1)
