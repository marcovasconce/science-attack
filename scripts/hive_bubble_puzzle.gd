extends Node2D

signal burst(at: Vector2, tint: Color, size: float)

const HIGH := Color("91ecff")
const LOW := Color("ffd287")
const POP := Color("ff8cc2")
const LAUNCH_HOP := 15.0
const LOW_HOP := 31.0
const HIGH_HOP := 82.0
const SPEED := 115.0
const BUBBLE_RADIUS := 10.0
const STATION_REACH := 32.0
enum Leg { WAITING, LAUNCH, FIRST, SECOND }

var high_settings: Array[bool] = [false, true]
var deck_kick := [0.0, 0.0]
var hints: Array[Label] = []
var solved := false
var leg := Leg.WAITING
var center_at := Vector2.ZERO
var age := 0.0
var duration := 0.0
var hop := 0.0
var cooldown := 0.35
var flashed_gate: Sprite2D
var flash_clock := 0.0
@onready var ball: Sprite2D = $Bubble
@onready var checkpoints: Array[Marker2D] = [$Nozzle, $SpringA/Contact, $SpringB/Contact, $Cup]
@onready var gates: Array[Sprite2D] = [$LowBarrier, $HighBarrier]
@onready var springs: Array[Node2D] = [$SpringA, $SpringB]

func _ready() -> void:
	hints = [$InteractHint, $InteractHint.duplicate() as Label]
	add_child(hints[1])
	for i in springs.size(): _update_spring(i)

func nearby_spring(at: Vector2) -> int:
	for i in springs.size():
		if absf(at.x - springs[i].global_position.x) <= STATION_REACH: return i
	return -1

func adjust(station: int) -> void:
	if solved or station < 0: return
	GameAudio.effect("lever", springs[station].global_position)
	high_settings[station] = not high_settings[station]
	_update_spring(station)

func hide_hints() -> void:
	for hint in hints: hint.hide()

func update_hints(players: Array) -> void:
	hide_hints()
	if solved: return
	var used := -1
	for player in players:
		if player.ai_controlled or player.down: continue
		var station := nearby_spring(player.global_position)
		if station < 0 or station == used: continue
		var hint := hints[player.player_id]
		hint.position = springs[station].position + Vector2(-5, 48)
		var key := "E" if player.player_id == 0 else "U"
		GameInput.label_hint(hint, player.player_id, "interact", key)
		hint.show()
		used = station

func tick(dt: float, players: Array) -> void:
	for i in springs.size():
		deck_kick[i] = move_toward(deck_kick[i], 0.0, dt * 5.0)
		springs[i].get_node("Deck").position.y = -23.0 + deck_kick[i] * 7.0
	if flash_clock > 0:
		flash_clock = maxf(0.0, flash_clock - dt)
		flashed_gate.self_modulate = Color.WHITE.lerp(POP, flash_clock / 0.35)
	if solved: return
	if leg == Leg.WAITING:
		if not players.any(func(p): return not p.down and absf(p.global_position.x - global_position.x) <= 200.0): return
		cooldown -= dt
		if cooldown <= 0.0:
			_start_leg(Leg.LAUNCH, LAUNCH_HOP)
			ball.show()
		return

	age = minf(age + dt, duration)
	var progress := age / duration
	var next := _point_on_leg(progress)
	if leg in [Leg.FIRST, Leg.SECOND]:
		var gate := gates[leg - Leg.FIRST]
		var bounds := gate.transform * gate.get_rect()
		if Rect2(next - Vector2.ONE * BUBBLE_RADIUS, Vector2.ONE * BUBBLE_RADIUS * 2).intersects(bounds):
			_pop(next, gate)
			return
	center_at = next
	ball.position = center_at
	if age < duration: return
	if leg == Leg.SECOND:
		solved = true
		ball.hide()
		hide_hints()
		$GoalLight.self_modulate = Color("b1ffc4")
		burst.emit(to_global(center_at), Color("b1ffc4"), 1.45)
		return
	var station := leg - Leg.LAUNCH
	GameAudio.effect("bounce", to_global(center_at))
	deck_kick[station] = 1.0
	burst.emit(to_global(center_at + Vector2(0, 11)), HIGH if high_settings[station] else LOW, 0.54)
	_start_leg(Leg.FIRST if station == 0 else Leg.SECOND, HIGH_HOP if high_settings[station] else LOW_HOP)

func _start_leg(next_leg: Leg, height: float) -> void:
	leg = next_leg
	age = 0.0
	hop = height
	var index := leg - Leg.LAUNCH
	duration = (checkpoints[index + 1].global_position.x - checkpoints[index].global_position.x) / SPEED
	center_at = _point_on_leg(0.0)
	ball.position = center_at

func _point_on_leg(progress: float) -> Vector2:
	var index := leg - Leg.LAUNCH
	var start := to_local(checkpoints[index].global_position)
	var finish := to_local(checkpoints[index + 1].global_position)
	return start.lerp(finish, progress) - Vector2(0, 4.0 * hop * progress * (1.0 - progress))

func _pop(at: Vector2, gate: Sprite2D) -> void:
	GameAudio.effect("bubble", to_global(at))
	burst.emit(to_global(at), POP, 0.82)
	flashed_gate = gate
	flash_clock = 0.35
	gate.self_modulate = POP
	ball.hide()
	leg = Leg.WAITING
	cooldown = 0.65

func _update_spring(station: int) -> void:
	var spring := springs[station]
	var high := high_settings[station]
	spring.get_node("Arrow").self_modulate = HIGH if high else LOW
	spring.get_node("BoostArrow").visible = high
