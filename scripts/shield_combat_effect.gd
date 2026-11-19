extends Node2D
## Standalone sprite animation survives the death/removal of the struck object.
enum Kind { EXPLOSION, BLOCK }
const EXPLOSION_ART = preload("res://assets/effects/tnt_explosion.png")
const BLOCK_ART = preload("res://assets/effects/shield_block_impact.png")
var kind := Kind.EXPLOSION
var facing := -1.0
var age := 0.0
var frame := 0
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	z_index = 2
	add_to_group("shield_block_fx" if kind == Kind.BLOCK else "tnt_explosion_fx")

func _process(dt: float) -> void:
	if is_instance_valid(arena) and arena.controls_locked: return
	age += dt
	var count := 8 if kind == Kind.EXPLOSION else 4
	frame = mini(count-1,int(age*(14 if kind == Kind.EXPLOSION else 18)))
	if age >= count/float(14 if kind == Kind.EXPLOSION else 18): queue_free()
	queue_redraw()

func _draw() -> void:
	if kind == Kind.EXPLOSION:
		draw_texture_rect_region(EXPLOSION_ART,Rect2(-90,-90,180,180),Rect2(Vector2(frame%4,frame/4)*64,Vector2.ONE*64))
	else:
		draw_set_transform(Vector2.ZERO,0,Vector2(-facing,1))
		draw_texture_rect_region(BLOCK_ART,Rect2(-36,-48,72,96),Rect2(frame*48,0,48,64))
