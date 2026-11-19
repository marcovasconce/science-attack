extends Node2D
## Each survivor must occupy a distinct plate before the cabin departs.
const Party = preload("res://scripts/party_transfer.gd")
signal departure_started
signal next_phase_requested
enum State { WAITING, ASCENDING, LOADING, COMPLETE }
const BOARD_TIME := 0.4
const ASCENT_TIME := 2.6
const ASCENT_HEIGHT := 230.0
@export_file("*.tscn") var next_scene_path := ""
@export var travels_down := false
var state := State.WAITING
var available := false
var ready_time := 0.0
var travel_time := 0.0
var loading_time := 0.0
var occupants: Array = [null,null]
var rider_origins: Array[Vector2] = []
var load_requested := false
@onready var arena = get_tree().get_first_node_in_group("arena")
@onready var cabin: Node2D = $Cabin
@onready var pads: Array = [$Cabin/LeftPad,$Cabin/RightPad]
@onready var black: ColorRect = $Transition/Black
@onready var loading_label: Label = $Transition/Black/Message

func both_equipped() -> bool:
	if arena.players.size()!=2: return false
	for player in arena.players:
		if player.equipped_weapon not in ["brush","bubbles"]: return false
	return true

func is_transitioning() -> bool:
	return state != State.WAITING

func can_unlock() -> bool:
	return arena.encounter.unlocked and arena.encounter.ultimate_done and both_equipped()

func unlock_route() -> void:
	available = true
	arena.open_limit = arena.world_limit
	arena.camera_max_x = arena.world_limit-310
	arena.get_node("StageBoundaries/East").position.x = arena.world_limit

func prepare_departure_ui() -> void:
	arena.encounter.arrow.hide()
	arena.get_node("HUD/Goal").hide()

func wants_arrow() -> bool:
	if not available or is_transitioning(): return false
	for player in arena.players:
		if not player.ai_controlled and not player.down and player.global_position.x < global_position.x-130: return true
	return false

func plate_for(player) -> int:
	if player.down or player.hp<=0 or player.jump_height>0.01 or player.jump_speed>0: return -1
	for i in pads.size():
		var offset: Vector2 = player.global_position-pads[i].global_position
		if absf(offset.x)<=23 and absf(offset.y)<=10: return i
	return -1

func ai_boarding_destination(player) -> Variant:
	if not available or is_transitioning() or player.down: return null
	var human = arena.players[0]
	var human_plate := plate_for(human)
	if human_plate<0: return null
	# Approach through the open front instead of walking into a side column.
	if absf(player.global_position.x-global_position.x)>104:
		if player.global_position.y<global_position.y-4:
			return Vector2(player.global_position.x,global_position.y)
		return Vector2(clampf(player.global_position.x,global_position.x-96,global_position.x+96),global_position.y)
	return pads[1-human_plate].global_position

func boarding_hint() -> String:
	if arena.players[0].down != arena.players[1].down: return "PISE EM UMA MARCA"
	return "UM EM CADA MARCA"

func _physics_process(dt: float) -> void:
	if state == State.ASCENDING:
		_advance_ascent(dt)
		return
	if state == State.LOADING:
		_update_loading(dt)
		return
	if state != State.WAITING: return
	if not available and can_unlock(): unlock_route()
	if arena.controls_locked:
		ready_time = 0
		return
	occupants = [null,null]
	for player in arena.players:
		var plate := plate_for(player)
		if plate>=0 and occupants[plate]==null: occupants[plate] = player
	for i in pads.size(): pads[i].occupied = occupants[i]!=null
	var boarded := 2 - occupants.count(null)
	var required := 2 if not arena.players[0].down and not arena.players[1].down else 1
	var ready: bool = available and both_equipped() and boarded == required
	if ready:
		for player in occupants:
			if player != null and not player.can_assemble(): ready = false
	ready_time = ready_time+dt if ready else 0.0
	$Hint.text = "PRONTOS!" if ready else (boarding_hint() if available else ("TESTEM AS ULTIMATES" if both_equipped() else "EQUIPEM AS DUAS ARMAS"))
	if ready_time>=BOARD_TIME: _start_ascent()

func _start_ascent() -> void:
	state = State.ASCENDING
	travel_time = 0
	arena.controls_locked = true
	prepare_departure_ui()
	$Hint.hide()
	rider_origins.clear()
	for player in arena.players:
		if player.down:
			var free_plate := 0 if occupants[0] == null else 1
			player.global_position = pads[free_plate].global_position
		rider_origins.append(player.global_position)
		player.velocity = Vector2.ZERO
		player.buffered = false
		player.dash = 0
		player.dash_visual.clear()
		player.get_node("Visual").rotation = 0
		if not player.down: player.sprite.play(player.equipped_weapon+"_idle")
		player.update_sprite_alignment()
	departure_started.emit()

func _advance_ascent(dt: float) -> void:
	travel_time = minf(ASCENT_TIME,travel_time+dt)
	var progress := travel_time/ASCENT_TIME
	var rise := ASCENT_HEIGHT*smoothstep(0.0,1.0,progress) * (-1.0 if travels_down else 1.0)
	cabin.position.y = -rise
	for i in arena.players.size(): arena.players[i].global_position = rider_origins[i]-Vector2(0,rise)
	SceneFx.paint(black, smoothstep(0.42,0.94,progress), SceneFx.WIPE, Vector2.UP)
	if progress>=1:
		state = State.LOADING
		black.color.a = 1
		loading_label.text = "CARREGANDO..."
		loading_label.show()
		next_phase_requested.emit()
		if not next_scene_path.is_empty() and ResourceLoader.exists(next_scene_path):
			load_requested = ResourceLoader.load_threaded_request(next_scene_path)==OK

func _update_loading(dt: float) -> void:
	loading_time += dt
	if loading_time<0.6: return
	if next_scene_path.is_empty():
		# No second stage exists yet. End on black without a fake endless load.
		_finish_without_scene("PRÓXIMA FASE EM BREVE")
		return
	if load_requested:
		var status := ResourceLoader.load_threaded_get_status(next_scene_path)
		if status==ResourceLoader.THREAD_LOAD_IN_PROGRESS: return
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			var next_scene = ResourceLoader.load_threaded_get(next_scene_path)
			# Preserve loadout and resources for the next stage to consume.
			get_tree().set_meta("party_state", Party.capture(arena))
			if next_scene is PackedScene and get_tree().change_scene_to_packed(next_scene)==OK:
				state = State.COMPLETE
				return
	_finish_without_scene("NÃO FOI POSSÍVEL CARREGAR A FASE")

func _finish_without_scene(message: String) -> void:
	state = State.COMPLETE
	loading_label.text = message+"\n\nF2  REINICIAR"
