extends Node2D
signal wall_slam
signal defeated
enum State { IDLE, WINDUP, CHARGE, IMPACT, RECOVER, SHIELD_BASH, DEAD }
const LAYER_HP := 650
const MAX_HP := LAYER_HP*2
const ART = preload("res://assets/enemies/shield_germ_v2.png")
const Effect = preload("res://scripts/shield_combat_effect.gd")
const SHIELD_DAMAGE_SCALE := 0.1
const BASH_CLOSE_TIME := 1.5
const BASH_CLOSE_RANGE := 80.0
const BASH_COOLDOWN := 3.5
const BASH_RANGE := 104.0
const BASH_DAMAGE := 6
const CHARGE_DAMAGE := 23
var hp := MAX_HP
var max_hp := MAX_HP
var dead := false
var state := State.IDLE
var age := 0.0
var clock := 0.0
var flash := 0.0
var idle_clock := 0.0
var combat_active := false
var close_times: Dictionary = {}
var next_bash_time := 0.0
var bash_applied := false
var trail_points: Array[Dictionary] = []
const TRAIL_LIFETIME := 0.5
var direction := -1.0
var left_wall := 3940.0
var right_wall := 4740.0
var hit_players: Array[int] = []
var sprite: Sprite2D
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	add_to_group("germs")
	add_to_group("shield_boss")
	sprite = Sprite2D.new()
	sprite.texture = ART
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.position = Vector2(0,-78)
	sprite.scale = Vector2.ONE*1.5
	sprite.modulate = Color.WHITE
	add_child(sprite)

func start_fight() -> void:
	if not combat_active:
		combat_active = true
		wind_up()

func wind_up() -> void:
	state = State.WINDUP
	_use_action_art()
	age = 0
	hit_players.clear()
	# Every attack crosses the arena, instead of turning midway to track a player.
	direction = -1 if position.x > (left_wall+right_wall)*0.5 else 1
	sprite.flip_h = direction > 0

func _physics_process(dt: float) -> void:
	if state == State.DEAD:
		clock += dt
		age += dt
		_update_death_animation()
		queue_redraw()
		return
	# The idle also plays during the introduction, while player input is locked.
	if state == State.IDLE and visible and not arena.get_node("HUD/ControlsPanel").visible:
		if not arena.controls_locked or not combat_active:
			idle_clock += dt
			sprite.frame = int(idle_clock*6)%4
	if arena.controls_locked: return
	if arena.players[0].down and arena.players[1].down: return
	clock += dt
	age += dt
	flash = maxf(0,flash-dt)
	_update_close_pressure(dt)
	for point in trail_points: point.age += dt
	while not trail_points.is_empty() and trail_points[0].age > TRAIL_LIFETIME: trail_points.pop_front()
	match state:
		State.WINDUP:
			var target = arena.nearest_player(position)
			if target != null and age < 0.55:
				position.y = move_toward(position.y,clampf(target.position.y,208,315),dt*95)
			sprite.frame = 4
			sprite.position.x = roundf(sin(age*65)*2)
			if age >= (1.05 if hp > LAYER_HP else 0.85):
				state = State.CHARGE
				age = 0
				close_times.clear()
		State.CHARGE:
			var previous := position
			trail_points.append({"position":Vector2(previous.x,previous.y-78),"age":0.0})
			var finish := Vector2(clampf(position.x+direction*520*dt,left_wall+62,right_wall-62),position.y)
			_sweep_tnt(previous,finish)
			if dead: return
			position = finish
			sprite.frame = 5 if int(age*12)%2 == 0 else 6
			for player in arena.players:
				if player.player_id in hit_players or player.down: continue
				var closest := Geometry2D.get_closest_point_to_segment(player.position,previous,position)
				if absf(closest.x-player.position.x) < 58 and absf(position.y-player.position.y) < 25:
					hit_players.append(player.player_id)
					player.take_hit(CHARGE_DAMAGE,Vector2(player.position.x-direction*40,position.y))
			if (direction < 0 and position.x <= left_wall+62) or (direction > 0 and position.x >= right_wall-62):
				state = State.IMPACT
				age = 0
				arena.start_camera_shake(7,0.28)
				wall_slam.emit()
		State.IMPACT:
			sprite.frame = 7
			if age >= 0.3:
				state = State.RECOVER
				age = 0
		State.RECOVER:
			sprite.frame = 11
			if age >= 1.2:
				state = State.IDLE
				age = 0
		State.SHIELD_BASH:
			# Drawn anticipation, thrust, bright shield arc, and return; no rectangle overlay.
			if age < 0.28:
				sprite.frame = 8
				sprite.position.x = -direction*7*smoothstep(0,0.28,age)
			elif age < 0.38:
				sprite.frame = 9
				sprite.position.x = direction*lerpf(-7,22,smoothstep(0.28,0.38,age))
			elif age < 0.52:
				sprite.frame = 10
				sprite.position.x = direction*22
			else:
				sprite.frame = 11
				sprite.position.x = direction*22*(1-smoothstep(0.52,0.8,age))
			if age >= 0.36 and not bash_applied:
				bash_applied = true
				for player in arena.players:
					if player.down or player.player_id in hit_players: continue
					var offset: Vector2 = player.global_position-global_position
					if offset.x*direction >= -12 and offset.x*direction <= BASH_RANGE and absf(offset.y) <= 48:
						hit_players.append(player.player_id)
						player.receive_shield_push(BASH_DAMAGE,global_position-Vector2(direction*30,0),direction)
			if age >= 0.8:
				state = State.RECOVER
				age = 0
		State.IDLE:
			if combat_active and age >= 0.8: wind_up()
	if state not in [State.WINDUP,State.SHIELD_BASH]: sprite.position.x = 0
	sprite.modulate = Color(1.45,1.55,1.0) if flash > 0 else Color.WHITE
	queue_redraw()

func _use_action_art() -> void:
	sprite.frame = 4
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.texture = ART

func _update_close_pressure(dt: float) -> void:
	# Consecutive proximity per player, never a count of attacks against the shield.
	if not combat_active or clock < next_bash_time or state not in [State.IDLE,State.WINDUP,State.RECOVER]:
		close_times.clear()
		return
	for player in arena.players:
		var offset: Vector2 = player.global_position-global_position
		var close: bool = not player.down and offset.x*direction >= -8 and offset.x*direction <= BASH_CLOSE_RANGE and absf(offset.y) <= 32
		var duration: float = float(close_times.get(player.player_id,0.0))+dt if close else 0.0
		close_times[player.player_id] = duration
		if duration >= BASH_CLOSE_TIME:
			state = State.SHIELD_BASH
			age = 0
			sprite.frame = 8
			sprite.flip_h = direction > 0
			hit_players.clear()
			bash_applied = false
			next_bash_time = clock+BASH_COOLDOWN
			close_times.clear()
			return

func _sweep_tnt(start: Vector2, finish: Vector2) -> void:
	var contacts: Array[Dictionary] = []
	var travel := absf(finish.x-start.x)
	for crate in get_tree().get_nodes_in_group("boss_tnt"):
		if crate.broken or not crate.landed or crate.is_queued_for_deletion(): continue
		if absf(crate.position.y-start.y) > 31: continue
		var ahead: float = (crate.position.x-start.x)*direction
		if ahead < -52 or ahead > travel+52: continue
		contacts.append({"crate":crate,"distance":maxf(0,ahead-52)})
	contacts.sort_custom(func(a,b): return a.distance < b.distance)
	for hit in contacts:
		if not is_instance_valid(hit.crate) or hit.crate.broken: continue
		# Resolve at contact, so the blast hits the boss even in a large physics step.
		position = start+Vector2(direction*hit.distance,0)
		hit.crate.explode()
		if dead: return

func is_shield_hit(origin: Vector2, attack_direction: float) -> bool:
	var side := origin.x-global_position.x
	return side*direction > 0 if absf(side) > 1 else attack_direction*direction < 0

func receive_attack(damage: int, origin: Vector2, attack_direction: float) -> bool:
	if dead or not combat_active or arena.controls_locked or damage <= 0: return false
	var blocked := is_shield_hit(origin,attack_direction)
	if blocked:
		var effect := Effect.new()
		effect.kind = Effect.Kind.BLOCK
		effect.facing = direction
		arena.get_node("ImpactEffects").add_child(effect)
		effect.global_position = global_position+Vector2(direction*51,-65)
		_apply_damage(maxi(1,int(round(damage*SHIELD_DAMAGE_SCALE))))
	else:
		_apply_damage(damage)
	return blocked

func take_hit(damage: int, attack_direction: float) -> void:
	receive_attack(damage,global_position-Vector2(attack_direction*60,0),attack_direction)

func take_explosion(damage: int) -> void:
	# Blasts are the weakness: full blast damage from either side of the shield.
	if dead or not combat_active or arena.controls_locked: return
	_apply_damage(damage)

func _apply_damage(damage: int) -> void:
	hp = maxi(0,hp-damage)
	flash = 0.1
	if hp == 0:
		dead = true
		state = State.DEAD
		_use_action_art()
		sprite.frame = 12
		sprite.rotation = 0
		sprite.position = Vector2(0,-78)
		sprite.scale = Vector2.ONE*1.5
		age = 0
		trail_points.clear()
		close_times.clear()
		remove_from_group("germs")
		arena.germ_defeated(position)
		defeated.emit()

func _update_death_animation() -> void:
	# Four actual collapse drawings finish in a prone pose, anchored on the floor.
	sprite.frame = 12+mini(3,int(age/0.16))
	sprite.rotation = 0
	sprite.position = Vector2(0,-78)
	sprite.scale = Vector2.ONE*1.5
	var blink_phase := fposmod(maxf(0,age-0.8),0.36)
	var alpha := 0.15 if age >= 0.8 and blink_phase < 0.12 else 1.0
	if age > 2.4: alpha *= 1.0-clampf((age-2.4)/0.6,0,1)
	sprite.modulate = Color(1,1,1,alpha)
	if age >= 3.0: queue_free()

func _draw() -> void:
	if dead: return
	for point in trail_points:
		var t: float = clampf(point.age/TRAIL_LIFETIME,0,1)
		var at: Vector2 = to_local(point.position)
		var width := roundf(5.0*(1-t)+1)
		var alpha := 0.5*(1-t)
		draw_rect(Rect2(at.round()-Vector2(width*0.5,2),Vector2(width,4)),Color(0.33,0.94,0.31,alpha))
		draw_rect(Rect2(at.round()+Vector2(-width*0.5,-1),Vector2(width*0.55,2)),Color(0.68,1.0,0.43,alpha))
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,46,Color(0.02,0.08,0.05,0.35))
	draw_set_transform(Vector2.ZERO)
	if state == State.WINDUP:
		var finish := left_wall+22-position.x if direction < 0 else right_wall-22-position.x
		for x in range(int(minf(0,finish)),int(maxf(0,finish)),18):
			draw_rect(Rect2(x,-19,10,38),Color(1,0.53,0.1,0.11+0.12*absf(sin(age*8))))
	if state in [State.CHARGE,State.IMPACT]:
		for i in 7:
			var t := fmod(clock*3+i*0.17,1.0)
			draw_rect(Rect2(-direction*(35+t*80),-6-12*sin(t*PI),5,3),Color(0.65,0.78,0.39,1-t))
	if state == State.CHARGE:
		var streak_colors := [Color("62d86c"),Color("8de84e"),Color("b1f76a")]
		for i in 16:
			var t := fposmod(clock*1.7+i*0.137,1.0)
			var length := 10.0+float(i%4)*5.0
			var behind := -direction*(58+t*154)
			if direction > 0: behind -= length
			var y := -111+float(i%6)*13+sin(clock*23+i*1.7)*4
			draw_rect(Rect2(Vector2(roundf(behind),roundf(y)),Vector2(roundf(length),2.0+float(i%3))),streak_colors[i%streak_colors.size()]*Color(1,1,1,0.5*(1-t)))
