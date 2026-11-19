extends "res://scripts/germ.gd"
var entry_height := 160.0
var flight_height: float:
	get: return 28.0+entry_height
var fall_speed := 0.0
var body_origin := Vector2.ZERO
func _ready() -> void:
	super._ready()
	body_origin = $Body.position
	$Body.position.y -= entry_height
func can_be_hit(_height: float) -> bool: return entry_height <= 0
func _physics_process(dt: float) -> void:
	if arena.controls_locked or dead: return
	if entry_height > 0:
		fall_speed += 440*dt
		entry_height = maxf(0,entry_height-fall_speed*dt)
		$Body.position = body_origin-Vector2(0,entry_height)
		if entry_height == 0: arena.spawn_impact(0,position,1)
		return
	super._physics_process(dt)
