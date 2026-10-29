extends CharacterBody2D
@export var hp := 65
@export var speed := 42.0
var stun := 0.0
var cooldown := 1.0
var dead := false
var phase := 0.0
@onready var arena = get_tree().get_first_node_in_group("arena")
func _physics_process(dt: float) -> void:
	if dead: return
	phase+=dt
	stun=maxf(0,stun-dt)
	cooldown-=dt
	var target = arena.nearest_player(position)
	if target==null: return
	var offset: Vector2=target.position-position
	velocity=offset.normalized()*Vector2(speed,speed*0.65) if offset.length()>28 and stun<=0 else Vector2.ZERO
	move_and_slide()
	$Body.scale=Vector2(1+sin(phase*6)*0.06,1-sin(phase*6)*0.06)
	$Body.modulate=Color(2,2,2) if stun>0 else Color.WHITE
	if absf(offset.x)<33 and absf(offset.y)<16 and cooldown<=0 and stun<=0:
		target.take_hit(10,position)
		cooldown=1.25
	$Health.value=hp
func take_hit(damage: int, direction: float) -> void:
	hp-=damage
	stun=0.4
	position.x+=direction*18
	if hp<=0:
		dead=true
		arena.germ_defeated(position)
		queue_free()
