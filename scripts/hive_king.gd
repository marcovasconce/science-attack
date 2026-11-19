extends Node2D

signal health_changed(hp: int, maximum: int)
signal enraged
signal exhausted

const MAX_HP := 10000
const PHASE_MARK := 5300
const CRASH_DEPTH := 33.0
const RoyalBubble = preload("res://scripts/royal_bubble.gd")
const VACUUM_RADIUS := Vector2(98, 36)
enum State { DORMANT, APPROACH, WINDUP, ATTACK, RECOVER, ROAR, TIRED }
enum Move { CRASH, BUBBLE, VACUUM, PRESSURE, DOUBLE_CRASH }

var hp := MAX_HP
var dead := false
var flight_height := 56.0
var phase := 1
var state := State.DORMANT
var move := Move.CRASH
var turns := 0
var clock := 0.0
var animation_age := 0.0
var hurt_time := 0.0
var recovery_bonus := 0.0
var face := -1.0
var crash_at := Vector2.ZERO
var marks: Array[Vector2] = []
var next_burst := 0
var pressure_vents: Array = []
var first_crash_done := false
@onready var charge: Sprite2D = $Charge
@onready var arena = get_tree().get_first_node_in_group("arena")
@onready var sprite: Sprite2D = $Sprite
@onready var lane: TextureRect = $Warning/Lane
@onready var stamps: Array[Sprite2D] = [$Warning/First, $Warning/Second, $Warning/Third]

func begin() -> void:
	GameAudio.effect("laugh")
	show()
	add_to_group("germs")
	_set_state(State.APPROACH)
	health_changed.emit(hp, MAX_HP)

func _physics_process(dt: float) -> void:
	if arena.controls_locked or state in [State.DORMANT, State.TIRED]: return
	clock += dt
	animation_age += dt
	hurt_time = maxf(0.0, hurt_time - dt)
	match state:
		State.APPROACH:
			var target = arena.nearest_player(position)
			if target == null: return
			var toward: Vector2 = target.position - position
			if absf(toward.x) > 8: face = signf(toward.x)
			if absf(toward.x) > 134:
				position.x = move_toward(position.x, target.position.x - face * 119.0, dt * (113.0 if phase == 1 else 158.0))
			position.y = move_toward(position.y, target.position.y, dt * 53.0)
			if clock >= (0.64 if turns == 0 or phase == 2 else 0.9): _warn(target.position)
		State.WINDUP:
			if clock >= (0.84 if phase == 1 else 0.64): _attack()
		State.ATTACK:
			if move == Move.VACUUM: _tick_vacuum(dt)
			elif move == Move.PRESSURE: _tick_pressure()
			elif move == Move.DOUBLE_CRASH: _tick_double_crash()
		State.RECOVER:
			if clock >= (0.89 if phase == 1 else 0.66) + recovery_bonus: _set_state(State.APPROACH)
		State.ROAR:
			if clock >= 1.68: _set_state(State.APPROACH)
	_pose()

func _warn(target: Vector2) -> void:
	var pattern := [Move.CRASH, Move.BUBBLE, Move.VACUUM] if phase == 1 else [Move.PRESSURE, Move.DOUBLE_CRASH, Move.BUBBLE, Move.VACUUM, Move.DOUBLE_CRASH]
	move = pattern[turns % pattern.size()]
	turns += 1
	GameAudio.effect("warn", global_position)
	crash_at = arena.king_floor(target)
	marks.clear()
	match move:
		Move.CRASH, Move.DOUBLE_CRASH:
			marks.append(crash_at)
			if move == Move.DOUBLE_CRASH:
				var step := 138.0 if crash_at.x < (arena.room_left + arena.room_right) * 0.5 else -138.0
				marks.append(arena.king_floor(crash_at + Vector2(step, 41 if crash_at.y < 276 else -41)))
			_show_circles(Vector2(125, CRASH_DEPTH), Color("ff9159"))
			GameAudio.effect("lever")
		Move.VACUUM:
			marks.append(position)
			_show_circles(VACUUM_RADIUS, Color("73ffe7"))
			GameAudio.effect("solar", position)
		Move.BUBBLE:
			charge.modulate = Color("fff385")
			charge.scale = Vector2.ONE * 0.1
			charge.show()
			GameAudio.effect("bounce", position)
		Move.PRESSURE:
			pressure_vents.assign(arena.royal_vents())
			next_burst = 0
			pressure_vents[0].trigger()
	_set_state(State.WINDUP)

func _show_circles(radius: Vector2, tone: Color) -> void:
	for i in marks.size():
		stamps[i].global_position = marks[i]
		stamps[i].scale = radius * 2.0 / stamps[i].texture.get_size()
		stamps[i].modulate = tone
		stamps[i].show()

func _attack() -> void:
	_set_state(State.ATTACK)
	match move:
		Move.CRASH:
			position = crash_at
			_hit_area(position, Vector2(125, CRASH_DEPTH), 19, 2.15)
			_recover(0.28)
		Move.DOUBLE_CRASH:
			first_crash_done = false
			_tick_double_crash()
		Move.BUBBLE:
			var orb := RoyalBubble.new()
			orb.king = self
			orb.flight_target = crash_at
			orb.position = position
			get_parent().add_child(orb)
			GameAudio.effect("nova", global_position)
			_recover(1.25)
		Move.VACUUM:
			GameAudio.effect("solar", global_position)
			lane.hide()
		Move.PRESSURE:
			next_burst = 1

func _tick_double_crash() -> void:
	if not first_crash_done:
		first_crash_done = true
		position = marks[0]
		stamps[0].hide()
		_hit_area(position, Vector2(125, CRASH_DEPTH), 18, 2.4)
	elif clock >= 0.84:
		position = marks[1]
		_hit_area(position, Vector2(125, CRASH_DEPTH), 22, 3.0)
		_recover(0.9)

func _tick_vacuum(dt: float) -> void:
	for player in arena.players:
		if player.down or player.jump_height >= 18.0 or player.dash > 0.0: continue
		var difference: Vector2 = position - player.position
		if difference.length() < 310.0:
			player.push_velocity += difference.normalized() * 940.0 * dt + difference.normalized() * 20.0
	if not SceneFx.reduced_motion and int(clock * 15.0) != int((clock - dt) * 15.0):
		var at := position + Vector2.from_angle(clock * TAU * 2.3) * Vector2(208, 49)
		var mist: Node2D = arena.spawn_impact(1, at - Vector2(0, 6), face)
		mist.modulate = Color("a7ffb9")
		mist.scale = Vector2.ONE * 0.65
		var drift := mist.create_tween()
		drift.tween_property(mist, "global_position", position - Vector2(0, 20), 0.35)
	if clock >= 1.12:
		_hit_area(position, VACUUM_RADIUS, 22, 2.7)
		_recover(0.62)

func _tick_pressure() -> void:
	if next_burst < pressure_vents.size() and clock >= next_burst * 0.47 - 0.12:
		pressure_vents[next_burst].trigger()
		next_burst += 1
	if clock >= 1.24: _recover(0.85)

func reflected_bubble() -> void:
	if dead or state == State.ROAR: return
	take_hit(475, 0)
	if dead or state == State.ROAR: return
	_recover(1.50)
	arena.start_camera_shake(5, 0.26)

func _hit_area(at: Vector2, radius: Vector2, damage: int, size: float) -> void:
	GameAudio.effect("spit" if move == Move.VACUUM else "slam", at)
	for player in arena.players:
		if player.down or player.jump_height > 20.0: continue
		var offset: Vector2 = (player.position - at) / radius
		if offset.length_squared() <= 1.0: player.take_hit(damage, at)
	var splash: Node2D = arena.spawn_impact(1, at - Vector2(0, 20.0), face)
	splash.scale = Vector2(size * 1.4, size)
	splash.modulate = Color("91ffee") if move == Move.VACUUM else Color("ffd066")
	for offset in [-1.0, 0.0, 1.0]:
		var spray: Node2D = arena.spawn_impact(1, at + Vector2(radius.x * offset * 0.58, -7), face)
		spray.scale = Vector2(2.5, 1.0) if move != Move.VACUUM else Vector2(1.2, 1.9)
		spray.modulate = splash.modulate
	arena.start_camera_shake(5 if move in [Move.CRASH, Move.DOUBLE_CRASH] else 4, 0.26)

func hit_by_jet() -> void:
	if not can_be_hit(0): return
	take_hit(96, 0)
	if dead or state == State.ROAR: return
	_recover(0.95)
	var splash: Node2D = arena.spawn_impact(1, global_position - Vector2(0, 42), face)
	splash.modulate = Color("c8ff65")
	splash.scale = Vector2(1.7, 2.0)
	GameAudio.effect("spit", global_position)

func _recover(bonus := 0.0) -> void:
	recovery_bonus = bonus
	_clear_marks()
	_set_state(State.RECOVER)

func _clear_marks() -> void:
	lane.hide()
	charge.hide()
	for stamp in stamps: stamp.hide()

func _set_state(next: State) -> void:
	state = next
	clock = 0.0

func _pose() -> void:
	sprite.flip_h = face < 0.0
	sprite.position.y = -69.0 - sin(animation_age * 7.0) * (0.0 if SceneFx.reduced_motion else 3.0)
	sprite.scale = Vector2(1.73, 1.73)
	sprite.rotation = 0.0
	sprite.modulate = Color("ffc07d") if phase == 2 else Color.WHITE
	if state == State.WINDUP:
		for mark in stamps:
			if mark.visible:
				mark.modulate.a = 0.78 if SceneFx.reduced_motion else 0.65 + 0.35 * absf(sin(clock * 16.0))
		if move == Move.BUBBLE:
			charge.position.x = face * 53.0
			charge.scale = Vector2.ONE * lerpf(0.25, 1.55, clampf(clock / 0.7, 0.0, 1.0))
		sprite.rotation = -face * (0.18 if move == Move.BUBBLE else 0.12)
		sprite.scale.y *= 0.90 if move == Move.BUBBLE else 1.08
		sprite.position.y -= minf(23.0, clock * 38.0) if move in [Move.CRASH, Move.DOUBLE_CRASH] else 0.0
	elif state == State.ATTACK and move == Move.VACUUM:
		sprite.scale = Vector2(1.83, 1.62) + Vector2(0.10, -0.10) * sin(clock * 23.0)
		sprite.rotation = face * 0.12
	elif state == State.RECOVER:
		sprite.scale.y *= 0.92
		sprite.modulate = Color("fff0a2")
	elif state == State.ROAR:
		sprite.position.y -= 17.0 * sin(clampf(clock / 1.12, 0.0, 1.0) * PI)
		sprite.modulate = Color("f7ce9f")
	if hurt_time > 0.0: sprite.modulate = Color(1.8, 1.4, 1.15)

func can_be_hit(_height: float) -> bool:
	return not dead and state not in [State.DORMANT, State.ROAR]

func take_hit(damage: int, _direction: float) -> void:
	if not can_be_hit(0.0) or arena.controls_locked: return
	var scaled := maxi(1, roundi(damage * (1.0 if state == State.RECOVER else 0.72)))
	hurt_time = 0.12
	hp = maxi(0, hp - scaled)
	if phase == 1 and hp <= PHASE_MARK:
		hp = PHASE_MARK
		phase = 2
		turns = 0
		_clear_marks()
		_set_state(State.ROAR)
		GameAudio.effect("laugh")
		enraged.emit()
	elif hp == 0:
		dead = true
		_clear_marks()
		_set_state(State.TIRED)
		sprite.rotation = -0.20
		sprite.scale = Vector2(1.45, 1.17)
		sprite.position.y = -49
		sprite.modulate = Color("c8d2b1")
		exhausted.emit()
	health_changed.emit(hp, MAX_HP)

func escape_point(at: Vector2) -> Variant:
	if state not in [State.WINDUP, State.ATTACK]: return null
	if move not in [Move.CRASH, Move.DOUBLE_CRASH, Move.VACUUM]: return null
	var mark := position if move == Move.VACUUM else crash_at
	if move == Move.DOUBLE_CRASH and state == State.ATTACK: mark = marks[1]
	var half_width := 165.0 if move == Move.VACUUM else 125.0
	if absf(at.x - mark.x) < half_width + 10.0 and absf(at.y - mark.y) < 42.0:
		return arena.king_floor(Vector2(at.x, mark.y + (-54 if mark.y > 276 else 54)))
	return null
