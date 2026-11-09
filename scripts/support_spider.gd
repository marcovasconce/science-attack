extends StaticBody2D
var phase := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")
func _process(dt: float) -> void:
	if arena.controls_locked: return
	phase += dt
	$Sprite.position.y = -51 + sin(phase * 1.8) * 0.6
