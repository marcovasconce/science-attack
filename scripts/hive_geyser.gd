extends Node2D
## Warning always lasts one full second. A tall jet must be sidestepped, not jumped.
enum State { REST, WARNING, ERUPTING }
const ART = preload("res://assets/environment/hive/geyser.png")
const JET_TOP := [0, 0, 96, 71, 37, 37, 71, 105]
const WARNING_TIME := 1.0
const ERUPTION_TIME := 1.65
var hit_germs: Array = []
var ceiling_y := 0.0
var state := State.REST
var age := 0.0
@export var rest_time := 3.0
var hit_players: Array = []
@onready var arena = get_tree().get_first_node_in_group("arena")
func _process(dt: float) -> void:
	if arena.controls_locked: return
	if not arena.drain_active(self):
		if state != State.REST:
			state = State.REST
			age = 0
			queue_redraw()
		return
	var before := state
	advance(dt)
	if before != state:
		if state == State.WARNING: GameAudio.effect("warn", global_position)
		if state == State.ERUPTING: GameAudio.effect("jet", global_position)
	if dangerous():
		for germ in get_tree().get_nodes_in_group("germs"):
			if germ.dead or germ in hit_germs or germ.is_in_group("royal_bubbles"): continue
			if absf(germ.position.x-position.x) < 39 and absf(germ.position.y-position.y) < 22:
				hit_germs.append(germ)
				if germ.has_method("hit_by_jet"): germ.hit_by_jet()
				else: germ.take_hit(96, signf(germ.position.x-position.x))
	for player in arena.players:
		if can_hurt(player) and player.invulnerable <= 0:
			hit_players.append(player)
			player.take_hit(12, position, true)
			arena.start_camera_shake(2, 0.16)
	queue_redraw()
func trigger() -> void:
	if state != State.REST: return
	age = 0.0
	state = State.WARNING
	hit_germs.clear()
	hit_players.clear()
	GameAudio.effect("warn", global_position)
	queue_redraw()

func advance(dt: float) -> void:
	age += dt
	var duration: float = rest_time if state == State.REST else (WARNING_TIME if state == State.WARNING else ERUPTION_TIME)
	while age >= duration:
		age -= duration
		state = (state+1)%3 as State
		if state == State.WARNING:
			hit_players.clear()
			hit_germs.clear()
		duration = rest_time if state == State.REST else (WARNING_TIME if state == State.WARNING else ERUPTION_TIME)
func dangerous() -> bool:
	return state == State.ERUPTING and age >= 0.16 and age < 1.45
func can_hurt(player) -> bool:
	return dangerous() and not player.down and player not in hit_players and absf(player.position.x-position.x)<27 and absf(player.position.y-position.y)<18
func frame_index() -> int:
	if state == State.REST: return 0
	if state == State.WARNING: return 1 if int(age*12)%2 == 0 else 0
	if age < 0.12: return 2
	if age < 0.28: return 3
	if age < 1.24: return 4+int(age*10)%2
	return 6 if age < 1.54 else 7

func jet_height() -> float:
	var rise := smoothstep(0.0, 0.36, age)
	var fall := 1.0 - smoothstep(1.24, 1.6, age)
	return maxf(0, global_position.y - ceiling_y - 15.0) * rise * fall

func _draw() -> void:
	var frame := frame_index()
	var origin := Vector2(frame % 4 * 96, floori(frame / 4.0) * 160)
	var base_y := 115 if frame < 4 else 123
	if state == State.WARNING:
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.36))
		draw_arc(Vector2.ZERO, 42, 0, TAU, 24, Color(0.63, 1, 0.18, 0.45 + age * 0.5), 2, false)
		draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(ART, Rect2(-48, -15, 96, 35), Rect2(origin + Vector2(0, base_y - 5), Vector2(96, 35)))
	if state != State.ERUPTING: return
	var height := roundf(jet_height())
	if height <= 0: return
	var top: int = JET_TOP[frame]
	var seam := base_y - 5
	var cap_source := mini(22, seam - top - 5)
	var cap := minf(cap_source, height)
	var peak := -15.0 - height
	draw_texture_rect_region(ART, Rect2(-48, peak, 96, cap), Rect2(origin + Vector2(0, top), Vector2(96, cap_source)))
	if height > cap:
		draw_texture_rect_region(ART, Rect2(-48, peak + cap, 96, height - cap), Rect2(origin + Vector2(0, top + cap_source), Vector2(96, seam - top - cap_source)))
