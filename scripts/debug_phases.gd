extends CanvasLayer
## Development-only navigation, available even during cutscenes and modal screens.
const PHASES := ["res://scenes/laboratory_intro.tscn", "res://scenes/gameplay/micro_arena.tscn", "res://scenes/gameplay/tabletop_stage.tscn"]
const NAMES := ["Introdução", "Fase 1: treinamento", "Fase 2: bancada"]
const ROUTE_SCRIPT = preload("res://scripts/tabletop_route.gd")
const SECTORS := ["Canos e água","Passagem do vapor","Depósito","Máquina de limpeza","Frasco limpo","Acesso à estufa"]
var switching := false

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var row := HBoxContainer.new()
	row.position = Vector2(160,337)
	add_child(row)
	var next := Button.new()
	next.text = "DEBUG: PULAR FASE [F6]"
	next.add_theme_font_size_override("font_size",11)
	next.focus_mode = Control.FOCUS_NONE
	next.tooltip_text = "Avançar para a próxima fase. Na última, volta à introdução."
	next.pressed.connect(skip_next)
	row.add_child(next)
	var menu := MenuButton.new()
	menu.text = "ESCOLHER FASE"
	menu.add_theme_font_size_override("font_size",11)
	menu.focus_mode = Control.FOCUS_NONE
	row.add_child(menu)
	for i in PHASES.size(): menu.get_popup().add_item(NAMES[i],i)
	menu.get_popup().add_separator("SETORES DA BANCADA")
	for i in SECTORS.size(): menu.get_popup().add_item(SECTORS[i],10+i)
	menu.get_popup().id_pressed.connect(go_to_phase)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
		skip_next()
		get_viewport().set_input_as_handled()

func skip_next() -> void:
	var scene := get_tree().current_scene
	var index := PHASES.find(scene.scene_file_path) if is_instance_valid(scene) else -1
	go_to_phase((index+1) % PHASES.size())

func go_to_phase(index: int) -> void:
	if switching: return
	if index >= 10 and index < 10+SECTORS.size():
		switching = true
		_change_phase.call_deferred(2,index-10)
		return
	if index < 0 or index >= PHASES.size(): return
	switching = true
	_change_phase.call_deferred(index)

func _change_phase(index: int, sector := -1) -> void:
	var tree := get_tree()
	var scene := tree.current_scene
	var party: Array[Dictionary] = []
	if is_instance_valid(scene) and scene.is_in_group("arena"):
		for player in scene.players:
			party.append({"player_id":player.player_id,"weapon":player.equipped_weapon,"hp":player.hp,"max_hp":player.max_hp,"energy":player.energy,"healing_flasks":player.healing_flasks,"flask_heal_amount":player.flask_heal_amount,"ai_controlled":player.ai_controlled})
	# Clear old checkpoints so a direct jump cannot inherit a stale previous run.
	for key in ["party_state", "tabletop_entry_state", "tabletop_checkpoint", "tabletop_retry"]:
		if tree.has_meta(key): tree.remove_meta(key)
	if sector >= 0:
		for actor in party: actor["hp"] = maxi(40,actor["hp"])
		tree.set_meta("tabletop_entry_state",party.duplicate(true))
		tree.set_meta("tabletop_checkpoint",_sector_checkpoint(sector,party))
		tree.set_meta("tabletop_retry",true)
	elif index == 2 and not party.is_empty(): tree.set_meta("party_state",party)
	var result := tree.change_scene_to_file(PHASES[index])
	if result != OK: push_error("Debug: não foi possível abrir a fase: %s" % PHASES[index])
	await tree.process_frame
	switching = false

func _sector_checkpoint(sector: int, party: Array) -> Dictionary:
	var steps := [ROUTE_SCRIPT.Step.PIPES,ROUTE_SCRIPT.Step.STEAM,ROUTE_SCRIPT.Step.EXPLORE,ROUTE_SCRIPT.Step.EXPLORE,ROUTE_SCRIPT.Step.SAMPLE,ROUTE_SCRIPT.Step.EXIT]
	var positions := [Vector2(2660,286),Vector2(3320,286),Vector2(4580,291),Vector2(5370,292),Vector2(5500,292),Vector2(6460,290)]
	return {"name":SECTORS[sector],"at":positions[sector],"party":party,"step":steps[sector],"drained":sector>=1,"passage":sector>=2,"batteries":[false,false],"supplies":[false,false],"records":[false,false,false],"sample":sector>=5,"ambushes":[sector>=2,sector>=2],"seen":{}}
