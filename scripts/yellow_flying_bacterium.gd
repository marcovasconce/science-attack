extends CharacterBody2D
## Altitude is separate from the floor lane, as it is for jumping players.
const SHEET = preload("res://assets/enemies/yellow_flying_bacteria.png")
const Goo = preload("res://scripts/enemy_slime_ball.gd")
const MAX_HEALTH := 195
const HIGH_HEIGHT := 76.0
const LOW_HEIGHT := 29.0
const LOW_DURATION := 10.0
enum Flight { HIGH, FALLING, GROUNDED, LOW, RISING }
var dive_after := 0.0
var hp := MAX_HEALTH
var max_hp := MAX_HEALTH
var dead := false
var flight := Flight.HIGH
var flight_height := HIGH_HEIGHT
var fall_speed := 0.0
var low_remaining := 0.0
var state_age := 0.0
var age := 0.0
var cooldown := 1.6
var windup := 0.0
var stun := 0.0
var knockback := 0.0
var aim := Vector2.ZERO
var sprite: Sprite2D
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 0
	# Flying changes attack height, not the floor collision used by encounter walls.
	collision_mask = 1 | 16
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 4
	sprite.scale = Vector2(1.5,1.5)
	add_child(sprite)
	_sync_visual()

func requires_air_attack() -> bool:
	return flight_height > 52

func can_be_hit(attack_height: float) -> bool:
	return not dead and absf(attack_height-flight_height) <= 29

func _physics_process(dt: float) -> void:
	if dead or arena.controls_locked: return
	age += dt
	state_age += dt
	stun = maxf(0,stun-dt)
	match flight:
		Flight.FALLING:
			fall_speed += 360*dt
			flight_height = maxf(13,flight_height-fall_speed*dt)
			move_and_collide(Vector2(knockback*dt,0))
			if flight_height <= 13:
				flight = Flight.GROUNDED
				state_age = 0
		Flight.GROUNDED:
			if state_age >= 0.35:
				flight = Flight.LOW
				state_age = 0
				low_remaining = LOW_DURATION
				cooldown = 1.1
		Flight.LOW:
			flight_height = lerpf(13,LOW_HEIGHT,minf(1,state_age/0.25))
			low_remaining = maxf(0,low_remaining-dt)
			if low_remaining <= 0:
				flight = Flight.RISING
				state_age = 0
		Flight.RISING:
			flight_height = lerpf(LOW_HEIGHT,HIGH_HEIGHT,smoothstep(0,0.65,state_age))
			if state_age >= 0.65:
				flight = Flight.HIGH
				state_age = 0
		Flight.HIGH:
			flight_height = HIGH_HEIGHT
			if dive_after > 0.0 and state_age >= dive_after:
				flight = Flight.FALLING
				state_age = 0.0
				fall_speed = 38.0
				knockback = 0.0
	if flight in [Flight.HIGH,Flight.LOW,Flight.RISING]: _hunt(dt)
	position.x = clampf(position.x,40,arena.world_limit-40)
	position.y = clampf(position.y,198,321)
	_sync_visual()

func _hunt(dt: float) -> void:
	var target = arena.nearest_player(position)
	if target == null: return
	var offset: Vector2 = target.position-position
	sprite.flip_h = offset.x > 0
	if windup > 0:
		windup = maxf(0,windup-dt)
		if windup <= 0:
			var shot := Goo.new()
			shot.position = position
			shot.height = flight_height-6
			shot.aim_at(aim)
			arena.get_node("Projectiles").add_child(shot)
			cooldown = 2.4
		return
	var direction := Vector2.ZERO
	if absf(offset.x) > 225: direction.x = signf(offset.x)
	elif absf(offset.x) < 145: direction.x = -signf(offset.x)
	if absf(offset.y) > 12: direction.y = signf(offset.y)*0.55
	velocity = direction * (68 if flight == Flight.LOW else 84) if stun <= 0 else Vector2.ZERO
	move_and_slide()
	cooldown -= dt
	if cooldown <= 0 and stun <= 0 and absf(offset.x) < 380 and absf(offset.y) < 35:
		aim = target.position
		windup = 0.48

func take_hit(damage: int, direction: float) -> void:
	if dead or damage <= 0: return
	hp = maxi(0,hp-damage)
	windup = 0
	stun = 0.22
	if hp <= 0:
		dead = true
		arena.germ_defeated(position)
		queue_free()
		return
	if flight in [Flight.HIGH,Flight.RISING]:
		flight = Flight.FALLING
		state_age = 0
		fall_speed = 20
		knockback = direction*60
	# Hits while low never reset the ten-second opportunity.
	_sync_visual()

func _sync_visual() -> void:
	if sprite == null: return
	var wobble := sin(age*6)*3 if flight in [Flight.HIGH,Flight.LOW] else 0.0
	sprite.position = Vector2(0,-flight_height+roundf(wobble))
	sprite.frame = int(age*12)%4 if flight in [Flight.HIGH,Flight.LOW,Flight.RISING] else 2
	sprite.rotation = sin(state_age*16)*0.45 if flight == Flight.FALLING else 0.0
	sprite.scale = Vector2(1.75,0.75) if flight == Flight.GROUNDED else Vector2(1.5,1.5)
	if windup > 0: sprite.scale *= 1.0+sin(age*28)*0.05
	sprite.modulate = Color(1.7,1.5,1.1) if stun > 0 else Color.WHITE
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-18,-2,36,5),Color(0.02,0.06,0.03,0.25))
	var bar := Vector2(-20,-flight_height-38)
	draw_rect(Rect2(bar,Vector2(40,4)),Color("2a242c"))
	draw_rect(Rect2(bar+Vector2.ONE,Vector2(38*float(hp)/max_hp,2)),Color("ffdb59"))
	if flight == Flight.GROUNDED:
		for i in 5:
			var x := (i-2)*(7+state_age*28)
			draw_rect(Rect2(x,-2-state_age*15,3,3),Color(0.9,0.8,0.4,1-state_age/0.4))
