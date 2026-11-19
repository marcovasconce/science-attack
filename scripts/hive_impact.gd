extends Sprite2D

const ART = preload("res://assets/third_party/ansimuz_hive/explosion-1.png")
const DURATION := 0.38
var age := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	texture = ART
	hframes = 8
	region_enabled = false

func _process(dt: float) -> void:
	if arena.get_node("HUD/ControlsPanel").visible: return
	age += dt
	if age >= DURATION:
		queue_free()
	else:
		frame = mini(7, int(age / DURATION * hframes))
