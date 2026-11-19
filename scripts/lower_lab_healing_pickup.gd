extends Node2D
const FLASK = preload("res://assets/ui/healing_flask.svg")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
var age := 0.0
var collected := false
var feedback_age := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	add_to_group("healing_pickups")
	z_index = 1

func _process(dt: float) -> void:
	if arena.controls_locked: return
	age += dt
	if collected:
		feedback_age += dt
		if feedback_age > 1: queue_free()
	elif age > 0.7:
		# Human players get first choice when both occupy the pickup.
		for player in arena.players:
			if player.down or player.jump_height > 15: continue
			if absf(player.position.x-position.x) > 28 or absf(player.position.y-position.y) > 19: continue
			player.healing_flasks += 1
			collected = true
			break
	queue_redraw()

func _draw() -> void:
	if collected:
		draw_string(FONT,Vector2(-32,-35-feedback_age*14),"+1 CURA",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(0.7,1,0.8,1-feedback_age))
		return
	var lift := 36*sin(minf(1,age/0.7)*PI) if age < 0.7 else 2*sin(age*4)
	draw_circle(Vector2.ZERO,10,Color(0.03,0.08,0.09,0.3))
	draw_texture_rect(FLASK,Rect2(-10,-30-lift,20,28),false)
