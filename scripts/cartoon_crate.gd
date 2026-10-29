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
	arena.pieces+=3
	arena.tutorial.record_action("crate",player)
	arena.effects.append({"p":position+Vector2(0,-18),"t":0.3})
	for chunk in $Debris.get_children():
		chunk.reparent(arena.get_node("Debris"))
		chunk.visible=true
		chunk.freeze=false
		chunk.apply_central_impulse(Vector2(-90 if chunk.name=="Left" else 90,-30))
		var fade=chunk.create_tween()
		fade.tween_interval(0.6)
		fade.tween_property(chunk,"modulate:a",0.0,0.6)
		fade.tween_callback(chunk.queue_free)
