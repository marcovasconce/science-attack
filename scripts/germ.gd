extends CharacterBody2D
const PixelVisual = preload("res://scripts/pixel_germ_visual.gd")
const GREEN_HEALTH := 130
const RED_HEALTH := 260
@export_enum("green", "red") var variant := "green"
@export var hp := GREEN_HEALTH
@export var speed := 42.0
var stun := 0.0
var cooldown := 1.0
var dead := false
var phase := 0.0
var max_hp := GREEN_HEALTH
var pixel_visual: Node2D
var walking := 0.0
var facing_left := false
@onready var arena = get_tree().get_first_node_in_group("arena")
func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	set_collision_mask_value(5, true)
	# Preserve explicit tutorial/test health overrides; only red defaults change.
	if variant == "red" and hp == GREEN_HEALTH: hp = RED_HEALTH
	max_hp = hp
	phase = randf() * 1.5
	$Health.max_value = max_hp
	$Health.value = hp
	$Health.position.y = -100 if variant == "red" else -66
	pixel_visual = PixelVisual.new()
	$Body.add_child(pixel_visual)
	pixel_visual.setup(variant)

func _physics_process(dt: float) -> void:
	if dead or arena.controls_locked: return
	phase+=dt
	stun=maxf(0,stun-dt)
	cooldown-=dt
	var target = arena.nearest_player(position)
	if target==null: return
	var offset: Vector2=target.position-position
	velocity=offset.normalized()*Vector2(speed,speed*0.65) if offset.length()>28 and stun<=0 else Vector2.ZERO
	move_and_slide()
	position.y=clampf(position.y,192,325)
	walking = lerpf(walking,clampf(velocity.length()/speed,0,1),1.0-exp(-dt*10.0))
	if absf(offset.x)>6: facing_left = offset.x<0
	pixel_visual.sync(phase,facing_left,walking)
	$Body.modulate=Color(2,2,2) if stun>0 else Color.WHITE
	if absf(offset.x)<33 and absf(offset.y)<16 and cooldown<=0 and stun<=0:
		target.take_hit(4 if arena.tutorial.step<7 else 10,position)
		cooldown=1.25
	$Health.value=hp
func take_hit(damage: int, direction: float) -> void:
	if dead: return
	hp-=damage
	$Health.value=maxi(0,hp)
	stun=0.4
	move_and_collide(Vector2(direction*18,0))
	if hp<=0:
		dead=true
		arena.germ_defeated(position)
		queue_free()
