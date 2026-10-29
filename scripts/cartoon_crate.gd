extends RigidBody2D
## A ground-plane body: the visual has height, the collision stays at its feet.
@export var hp := 32
var broken := false
@onready var arena = get_tree().get_first_node_in_group("arena")

func _physics_process(_dt: float) -> void:
	if broken: return
	position.x=clampf(position.x,32,1240)
	position.y=clampf(position.y,200,320)
	if arena.controls_locked: linear_velocity=Vector2.ZERO

func take_hit(damage: int, direction: float, player) -> void:
	if broken: return
	hp-=damage
	apply_central_impulse(Vector2(direction*75,0))
	$Health.visible=hp<32
	$Health.value=maxi(0,hp)
	var tween=create_tween()
	$Sprite.scale=Vector2(0.65,0.50)
	tween.tween_property($Sprite,"scale",Vector2(0.58,0.58),0.15)
	if hp>0: return
	broken=true
	visible=false
	set_deferred("freeze",true)
	set_deferred("collision_layer",0)
	set_deferred("collision_mask",0)
	$Feet.set_deferred("disabled",true)
	arena.collect_parts(3,position)
	arena.tutorial.record_action("crate",player)
	arena.effects.append({"p":position+Vector2(0,-18),"t":0.3})
	for chunk in $Debris.get_children():
		chunk.reparent(arena.get_node("Debris"))
		chunk.global_position=global_position+Vector2(-10 if chunk.name=="Left" else 10,0)
		chunk.visible=true
		chunk.freeze=false
		chunk.apply_central_impulse(Vector2(-90 if chunk.name=="Left" else 90,-30))
		chunk.angular_velocity=-2 if chunk.name=="Left" else 2
