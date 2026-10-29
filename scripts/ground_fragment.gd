extends RigidBody2D
## Fragments land and remain as floor decoration for the rest of the stage.
var flight_time := 0.0
var landed := false
func _physics_process(dt: float) -> void:
	if freeze or landed: return
	flight_time+=dt
	$Fragment.position.y=-sin(minf(1,flight_time/0.5)*PI)*12
	position.y=clampf(position.y,192,327)
	if flight_time>=0.8:
		landed=true
		linear_velocity=Vector2.ZERO
		angular_velocity=0
		$Fragment.position.y=0
		set_deferred("freeze",true)
