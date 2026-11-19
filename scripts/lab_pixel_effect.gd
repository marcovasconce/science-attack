extends Node2D
## Frame-by-frame reference flames, with separate smoke / toxic-vapor particles.
const FIRE = preload("res://assets/environment/lower_lab/fire_animated.png")
const FIRE_FPS := 12.0
var flame: Sprite2D
@export_enum("fire", "steam") var effect := "fire"
var age := 0.0
var arena: Node

func _ready() -> void:
	arena = get_tree().get_first_node_in_group("arena")
	if effect == "fire":
		flame = Sprite2D.new()
		flame.texture = FIRE
		flame.hframes = 6
		flame.vframes = 2
		flame.position = Vector2(0,-40)
		flame.scale = Vector2(1.25,1.25)
		add_child(flame)

func _process(dt: float) -> void:
	if arena.controls_locked: return
	age += dt
	if flame != null: flame.frame = int(age*FIRE_FPS)%12
	queue_redraw()

func _draw() -> void:
	if effect == "fire":
		for i in 6:
			var t := fmod(age * 0.38 + i / 6.0, 1.0)
			var size := 6.0 + floorf(t * 11)
			draw_rect(Rect2(roundf(sin(t*7+i)*10)-size/2, -42-roundf(t*56), size,size), Color(0.16,0.22,0.21,(1-t)*0.55))
	else:
		for strand in 3:
			for i in 6:
				var t := fmod(age * 0.45 + i / 6.0 + strand * 0.23, 1.0)
				var x := roundf((strand-1)*22 + sin(t*8+strand)*7)
				var size := 2.0 + floorf(t*3)
				draw_rect(Rect2(x,-8-roundf(t*44),size,7), Color(0.78,0.88,0.64,(1-t)*0.55))
