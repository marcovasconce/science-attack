extends CharacterBody2D

@export var player_id := 0
@export var ai_controlled := false
@export var tint := Color("80eaff")
var hp := 100
var facing := 1.0
var attack_time := 0.0
var attack_duration := 0.0
var combo := 0
var buffered := false
var hit_targets: Array = []
var invulnerable := 0.0
var stun := 0.0
var jump_height := 0.0
var jump_speed := 0.0
var dash := 0.0
var down := false
var revive_progress := 0.0
var energy := 100.0
var ai_clock := 0.0
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	$PlayerMarker.text="P%d" % (player_id+1) if not ai_controlled else "IA"

func _physics_process(dt: float) -> void:
	invulnerable = maxf(0, invulnerable-dt)
	stun = maxf(0, stun-dt)
	ai_clock += dt
	if arena.controls_locked:
		velocity=Vector2.ZERO
		return
	var prefix := "p%d_" % player_id
	var direction := Input.get_vector(prefix+"left",prefix+"right",prefix+"up",prefix+"down")
	var attack := Input.is_action_just_pressed(prefix+"attack")
	var jump := Input.is_action_just_pressed(prefix+"jump")
	var dodge := Input.is_action_just_pressed(prefix+"dodge")
	var interact := Input.is_action_pressed(prefix+"interact")
	if ai_controlled:
		var target = arena.nearest_enemy(position)
		var destination: Vector2 = arena.players[0].position + Vector2(36,20)
		if target != null:
			destination = target.position - Vector2(28 * signf(target.position.x-position.x),0)
			attack = absf(target.position.x-position.x)<58 and absf(target.position.y-position.y)<18 and arena.tutorial.step>=5
		var offset := destination-position
		direction = offset.normalized() if offset.length()>12 else Vector2.ZERO
		interact = true
		if arena.players[0].down:
			direction = (arena.players[0].position-position).normalized() if position.distance_to(arena.players[0].position)>26 else Vector2.ZERO
	if down:
		sprite.play("death")
		return
	if interact:
		arena.interact(self,dt)
	if attack and stun<=0:
		if attack_time>0:
			buffered = true
		else:
			start_attack()
	if jump and jump_height<=0 and stun<=0:
		arena.tutorial.record_action("jump", self)
		jump_speed = 235
	if dodge and dash<=0:
		arena.tutorial.record_action("dodge", self)
		dash = 0.24

		invulnerable = 0.3
	energy = minf(100,energy+dt*5)
	jump_height += jump_speed*dt
	jump_speed -= 650*dt
	if jump_height<0:
		jump_height=0
		jump_speed=0
	if absf(direction.x)>0.1 and attack_time<=0:
		facing = signf(direction.x)
	var speed := 145.0
	if Input.is_action_pressed(prefix+"run"): speed=185
	if dash>0:
		dash-=dt
		direction=Vector2(facing,0)
		speed=300
	if attack_time>0: speed*=0.25
	if stun>0: speed=0
	velocity = direction * Vector2(speed,speed*0.66)
	set_collision_mask_value(4,jump_height<20)
	move_and_slide()
	var pushing := false
	for index in get_slide_collision_count():
		var body=get_slide_collision(index).get_collider()
		if body is RigidBody2D and not body.freeze:
			body.apply_central_force(direction*450)
			pushing=direction.length()>0.1
	if velocity.length()>5: arena.tutorial.record_action("move", self)
	position.x=clampf(position.x,20,arena.open_limit)
	position.y=clampf(position.y,190,326)
	if attack_time>0:
		attack_time-=dt
		if attack_time < attack_duration*0.65 and attack_time>attack_duration*0.15:
			arena.strike(self,combo,hit_targets)
		if attack_time<=0 and buffered:
			buffered=false
			start_attack()
	var animation := "idle"
	if velocity.length()>5: animation="run"
	if pushing: animation="push"
	if jump_height>0: animation="jump"
	if attack_time>0: animation="heavy" if combo==3 else "attack"
	if stun>0: animation="hurt"
	sprite.play(animation)
	sprite.flip_h=facing<0
	$Visual.position.y=-jump_height
	modulate.a=0.5 if invulnerable>0 and int(ai_clock*20)%2==0 else 1.0
	$PlayerMarker.text="P%d" % (player_id+1) if not ai_controlled else "IA"

func start_attack() -> void:
	arena.tutorial.record_action("attack", self)
	combo=combo%3+1
	attack_duration=0.43 if combo<3 else 0.55
	attack_time=attack_duration
	hit_targets.clear()
	sprite.stop()

func take_hit(amount: int, source: Vector2) -> void:
	if invulnerable>0 or down or jump_height>30: return
	hp=maxi(0,hp-amount)
	invulnerable=0.8
	stun=0.25
	position.x+=signf(position.x-source.x)*12
	if hp==0:
		down=true
		sprite.stop()
