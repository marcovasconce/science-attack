extends Node2D
const ART = preload("res://assets/environment/lower_lab/tnt_crate.png")
const Effect = preload("res://scripts/shield_combat_effect.gd")
const BOSS_BLAST_DAMAGE := 320
var age := 0.0
var height := 310.0
var fall_speed := 0.0
var landed := false
var broken := false
var blast_age := 0.0
var target_boss: Node2D
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	add_to_group("boss_tnt")
	z_index = 2

func _physics_process(dt: float) -> void:
	if arena.controls_locked: return
	if arena.players[0].down and arena.players[1].down: return
	age += dt
	if broken:
		blast_age += dt
		if blast_age > 0.5: queue_free()
	elif not landed:
		fall_speed += 480*dt
		height = maxf(0,height-fall_speed*dt)
		if height == 0:
			landed = true
			# It becomes a hittable prop only after actually reaching the floor.
			add_to_group("medical_supplies")
	queue_redraw()

func take_hit(damage: int, _direction: float, _player) -> void:
	if landed and not broken and damage > 0: explode()

func explode() -> void:
	if broken or not landed: return
	broken = true
	blast_age = 0
	var effect := Effect.new()
	arena.get_node("ImpactEffects").add_child(effect)
	effect.global_position = global_position+Vector2(0,-32)
	queue_redraw()
	arena.start_camera_shake(3,0.16)
	for player in arena.players:
		if ((player.position-position)/Vector2(72,36)).length_squared() <= 1:
			player.take_hit(14,position)
	if is_instance_valid(target_boss) and not target_boss.dead:
		if ((target_boss.position-position)/Vector2(100,48)).length_squared() <= 1:
			target_boss.take_explosion(BOSS_BLAST_DAMAGE)

func _draw() -> void:
	if broken: return
	var danger := Color(1,0.45,0.15,0.3+0.2*absf(sin(age*9)))
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.5))
	draw_arc(Vector2.ZERO,32,0,TAU,24,danger,2)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(-7,-6),Vector2(7,6),danger,2)
	draw_line(Vector2(-7,6),Vector2(7,-6),danger,2)
	draw_texture_rect(ART,Rect2(-23,-54-height,46,54),false)
