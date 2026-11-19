extends Sprite2D

const FRAMES := [
	preload("res://assets/third_party/ansimuz_sewers/front-water1.png"),
	preload("res://assets/third_party/ansimuz_sewers/front-water2.png"),
	preload("res://assets/third_party/ansimuz_sewers/front-water3.png"),
	preload("res://assets/third_party/ansimuz_sewers/front-water4.png"),
]
var elapsed := 0.0

func _process(dt: float) -> void:
	elapsed = fmod(elapsed + dt, 0.8)
	texture = FRAMES[int(elapsed / 0.2) % FRAMES.size()]
