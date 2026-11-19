extends Node2D
## Each frame contains the king, closed-eye captive, mouth and flowing goo.
const FPS := 7.5
const FRAME_COUNT := 6
var age := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")

func _process(dt: float) -> void:
	if not visible or arena.get_node("HUD/ControlsPanel").visible: return
	age += dt
	$Hover.position.y = roundf(sin(age * 3.4) * 3)
	$Hover/Sprite.frame = int(age * FPS) % FRAME_COUNT

func _draw() -> void:
	draw_rect(Rect2(-34, 0, 68, 4), Color(0.025, 0.08, 0.03, 0.25))
	draw_rect(Rect2(-24, -2, 48, 8), Color(0.025, 0.08, 0.03, 0.2))
