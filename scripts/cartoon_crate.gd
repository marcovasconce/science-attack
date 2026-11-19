extends RigidBody2D
## Intact -> dented -> four-frame breakup; collisions stop on the final hit.
const BREAK_DURATION := 0.44
@export var hp := 32
@export var drops_salvage := true
var broken := false
var break_age := 0.0
var hit_age := 0.0
var hit_direction := 1.0
var sprite_scale := Vector2.ONE
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	var cell_height: float = $Sprite.texture.get_height() / 2.0
	sprite_scale = Vector2.ONE * 64.0 / cell_height
	$Sprite.scale = sprite_scale
	sample_visual()

func _physics_process(_dt: float) -> void:
	if broken: return
	position.x = clampf(position.x, 32, arena.world_limit - 10)
	position.y = clampf(position.y, 200, 320)
	if arena.controls_locked: linear_velocity = Vector2.ZERO

func _process(dt: float) -> void:
	if arena.controls_locked: return
	hit_age = maxf(0.0, hit_age - dt)
	if broken: break_age += dt
	sample_visual()

func sample_visual() -> void:
	if broken:
		$Sprite.frame = mini(5, 2 + int(break_age / BREAK_DURATION * 4.0))
		$Sprite.position = Vector2(0, -20)
		$Sprite.scale = sprite_scale
		$Shadow.visible = false
		visible = break_age < BREAK_DURATION
	else:
		$Sprite.frame = 1 if hp < 32 else 0
		var recoil := sin(hit_age / 0.18 * PI)
		$Sprite.position = Vector2(hit_direction * recoil * 2, -20)
		$Sprite.scale = sprite_scale * Vector2(1.0 + recoil * 0.08, 1.0 - recoil * 0.06)

func take_hit(damage: int, direction: float, player) -> void:
	if broken or damage <= 0: return
	arena.spawn_impact(0, global_position + Vector2(-direction * 14, -24), direction)
	hp = maxi(0, hp - damage)
	hit_age = 0.18
	hit_direction = direction
	apply_central_impulse(Vector2(direction * 75, 0))
	$Health.visible = hp > 0 and hp < 32
	$Health.value = hp
	if hp > 0:
		sample_visual()
		return
	broken = true
	linear_velocity = Vector2.ZERO
	set_deferred("freeze", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	$Feet.set_deferred("disabled", true)
	sample_visual()
	if drops_salvage: arena.collect_parts(3, position)
	arena.tutorial.record_action("crate", player)
	for chunk in $Debris.get_children():
		chunk.reparent(arena.get_node("Debris"))
		chunk.global_position = global_position + Vector2(-10 if chunk.name == "Left" else 10, 0)
		chunk.visible = true
		chunk.freeze = false
		chunk.apply_central_impulse(Vector2(-90 if chunk.name == "Left" else 90, -30))
		chunk.angular_velocity = -2 if chunk.name == "Left" else 2
