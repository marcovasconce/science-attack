extends Node
const ARRIVAL_LINE := "Vamos limpar a bancada! A estufa fica logo ali."
const QUIET_TIME := 12.0
var unlocked := true
var message_started := false
var message_finished := false
var puzzle_message_started := false
var puzzle_message_finished := false
var current_message := ""
var pending: Array[Dictionary] = []
var seen: Dictionary = {}
var gap := 0.0
@onready var arena = get_parent()
@onready var dialogue = $"../HUD/EncounterDialogue"

func _ready() -> void:
	dialogue.closed.connect(func(): gap = QUIET_TIME)

func is_modal() -> bool:
	return false

func start_message(_player_id: int) -> void:
	if message_started: return
	message_started = true
	message_finished = true
	arena.elevator.get_node("Hint").hide()
	say("arrival",[ARRIVAL_LINE])

func start_puzzle_message() -> void:
	if puzzle_message_started: return
	puzzle_message_started = true
	puzzle_message_finished = true
	say("generator",["Boa! Montem a máquina com as peças dessas caixas."])

func say(key: String, lines: Array, scope := -1) -> void:
	if seen.has(key) or lines.is_empty(): return
	seen[key] = true
	for line in lines: pending.append({"key":key,"text":line,"scope":scope})
	_show_next()

func _process(dt: float) -> void:
	if arena.controls_locked: return
	gap = maxf(0,gap-dt)
	_show_next()

func _show_next() -> void:
	if dialogue.active or gap > 0 or arena.controls_locked: return
	while not pending.is_empty():
		var message: Dictionary = pending.pop_front()
		# A queued tip must still describe the current objective when it appears.
		if message.scope >= 0 and is_instance_valid(arena.route) and arena.route.step != message.scope: continue
		if message.key == "generator" and is_instance_valid(arena.puzzle) and arena.puzzle.constructed: continue
		if message.key == "lever" and is_instance_valid(arena.puzzle) and arena.puzzle.finished: continue
		current_message = message.key
		dialogue.open_line("TIBÚRCIO",message.text)
		return

func clear() -> void:
	pending.clear()
	if dialogue.active: dialogue.dismiss()
