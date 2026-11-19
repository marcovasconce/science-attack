extends Node
## First combat sector -> HUD arrow -> physical NPC and equipment robot.
const TIBURCIO_LINE := "Finalmente chegaram! Peguem seus equipamentos no robô. Vocês vão precisar de reforços. Esses germes estão por toda parte!"
const ULTIMATE_EXPLANATION_TIME := 7.0
const ULTIMATE_PRAISE_TIME := 5.0
const ULTIMATE_FAREWELL_TIME := 6.0
var unlocked := false
var arrived := false
var talked := false
var robot_inspected := false
var active_interactor := -1
var ultimate_done := false
var ultimate_stage := 0
var ultimate_age := 0.0
var ultimate_used := [false, false]
@onready var arena = get_parent()
@onready var tiburcio = $"../Outpost/Tiburcio"
@onready var robot = $"../Outpost/Robot"
@onready var dialogue = $"../HUD/EncounterDialogue"
@onready var equipment = $"../HUD/EquipmentPanel"
@onready var arrow = $"../HUD/AdvanceArrow"
func _ready() -> void:
	dialogue.closed.connect(_finish_dialogue)
	tiburcio.get_node("Prompt").hide()
	robot.get_node("Prompt").hide()
func is_modal() -> bool:
	return dialogue.active or equipment.visible
func _process(_dt: float) -> void:
	if arena.victory and not unlocked: unlock_route()
	if unlocked:
		for player in arena.players:
			if not player.ai_controlled and player.position.x >= 1390: arrived = true
	arrow.visible = unlocked and (not arrived or arena.elevator.wants_arrow()) and not is_modal() and not arena.controls_locked
	_update_prompt(tiburcio, 64)
	_update_prompt(robot, 100)
func unlock_route() -> void:
	if unlocked: return
	unlocked = true
	arena.open_limit = arena.OUTPOST_LIMIT
	arena.camera_max_x = 1920.0
	arena.get_node("StageBoundaries/East").position.x = arena.OUTPOST_LIMIT
	arena.get_node("HUD/Communicator").hide()
	arena.get_node("GoalMarker").hide()
func _nearby_player(target: Node2D, radius: float):
	var nearest = null
	var distance := radius
	for player in arena.players:
		if player.ai_controlled or player.down: continue
		var d: float = player.global_position.distance_to(target.global_position)
		if d <= distance:
			nearest = player
			distance = d
	return nearest
func _update_prompt(target: Node2D, radius: float) -> void:
	var prompt = target.get_node("Prompt")
	var player = _nearby_player(target, radius) if unlocked and not is_modal() and not arena.controls_locked else null
	prompt.visible = player != null
	if player != null: prompt.set_player(player.player_id)
func try_interact(player) -> bool:
	if not unlocked or arena.controls_locked or player.ai_controlled or player.down: return false
	if player.jump_height > 0 or player.dash > 0: return false
	if player.global_position.distance_to(tiburcio.global_position) <= 64:
		active_interactor = player.player_id
		_pause_for_interaction()
		dialogue.open_line("TIBÚRCIO UNG", TIBURCIO_LINE, player.player_id)
		return true
	if player.global_position.distance_to(robot.global_position) <= 100:
		active_interactor = player.player_id
		_pause_for_interaction()
		equipment.open_panel(player.player_id)
		robot_inspected = true
		return true
	for dummy in get_tree().get_nodes_in_group("training_dummies"):
		if player.global_position.distance_to(dummy.global_position) < 82:
			dummy.prepare_training(player)
			return true
	return false
func _pause_for_interaction() -> void:
	arena.controls_locked = true
	arena.get_node("HUD/Communicator").hide()
	tiburcio.get_node("Prompt").hide()
	robot.get_node("Prompt").hide()
	arrow.hide()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if equipment.visible and equipment.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if equipment.visible and event.is_action_pressed("ui_cancel"):
		close_equipment()
		get_viewport().set_input_as_handled()
		return
	for player in arena.players:
		if player.ai_controlled or player.down: continue
		if not GameInput.event_for(event, player.player_id, "interact"): continue
		if is_modal():
			if player.player_id != active_interactor: return
			if dialogue.active: dialogue.advance()
			else: close_equipment()
			get_viewport().set_input_as_handled()
			return
		if try_interact(player):
			get_viewport().set_input_as_handled()
		return
func _finish_dialogue() -> void:
	talked = true
	_resume_gameplay()
func close_equipment() -> void:
	equipment.hide()
	_resume_gameplay()
func _resume_gameplay() -> void:
	active_interactor = -1
	arena.controls_locked = arena.get_node("HUD/ControlsPanel").visible or arena.tutorial.step == 0
func objective_text() -> String:
	if arena.elevator.both_equipped():
		if not ultimate_done: return "TESTE SUA ULTIMATE"
		return "SIGA AO ELEVADOR" if arena.elevator.wants_arrow() else arena.elevator.boarding_hint()
	return "FALE COM TIBÚRCIO" if not talked else "EQUIPE A DUPLA"

func record_ultimate(player) -> void:
	if ultimate_stage != 2 or ultimate_done or player.ai_controlled: return
	ultimate_used[player.player_id] = true

func update_ultimate_lesson(dt: float) -> void:
	var bubble: Control = arena.get_node("HUD/Communicator")
	if ultimate_done or not unlocked or not arena.elevator.both_equipped(): return
	if is_modal() or arena.controls_locked: return
	# Wait for any existing ability before supplying the one-time practice charge.
	if ultimate_stage == 0:
		for player in arena.players:
			if player.specials.active: return
		ultimate_stage = 1
		ultimate_age = 0
	ultimate_age += dt
	bubble.show()
	var message: Label = bubble.get_node("Message")
	var key: Label = bubble.get_node("Key")
	GameInput.clear_hint(key)
	if ultimate_stage == 1:
		message.text = "Meia barra: especial.\nBarra cheia: ultimate!"
		key.text = "OLHE A BARRA AZUL"
		if ultimate_age >= ULTIMATE_EXPLANATION_TIME:
			for player in arena.players:
				if not player.ai_controlled and not ultimate_used[player.player_id]: player.energy = 100
			ultimate_stage = 2
			ultimate_age = 0
	elif ultimate_stage == 2:
		var pending: Array = []
		var casting := false
		for player in arena.players:
			if player.ai_controlled: continue
			casting = casting or player.specials.active
			if not ultimate_used[player.player_id]: pending.append(player)
		message.text = "Enchi a barra para o treino.\nUse sua ultimate!"
		key.text = " / ".join(pending.map(func(player): return "Q" if player.player_id == 0 else "I"))
		if not pending.is_empty():
			var players := pending.map(func(player): return player.player_id)
			var keys := pending.map(func(player): return "Q" if player.player_id == 0 else "I")
			GameInput.multi_hint(key, players, "special", keys, key.text)
		if pending.is_empty():
			message.text = "Isso! Essa é a sua ultimate!"
			key.text = "BOA!"
			if not casting:
				ultimate_stage = 4
				ultimate_age = 0
		elif ultimate_age >= 14.0:
			message.text = "Acerte para ganhar energia.\nEspere a barra encher!"
	elif ultimate_stage == 4:
		message.text = "Isso! Essa é a sua ultimate!"
		key.text = "BOA!"
		if ultimate_age >= ULTIMATE_PRAISE_TIME:
			ultimate_stage = 3
			ultimate_age = 0
	elif ultimate_stage == 3:
		message.text = "Guarde essa força!\nVamos ao elevador!"
		key.text = "VAMOS!"
		if ultimate_age >= ULTIMATE_FAREWELL_TIME:
			ultimate_done = true
			bubble.hide()
