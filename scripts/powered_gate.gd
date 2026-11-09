@tool
extends Node2D
var openness := 0.0:
	set(value):
		openness = clampf(value,0,1)
		if is_node_ready(): _sync()

func _ready() -> void: _sync()

func _sync() -> void:
	$Well/Barrier.position = Vector2(22,96+174*openness)
	$Body/Collision.set_deferred("disabled",openness >= 0.95)
	$Well/Barrier/Light.modulate = Color("7dffba") if openness >= 0.95 else Color("ffb85c")
