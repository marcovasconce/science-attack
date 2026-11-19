extends RefCounted
## Shared by the title screen and the development phase selector.
const PHASES := ["res://scenes/laboratory_intro.tscn","res://scenes/gameplay/micro_arena.tscn","res://scenes/gameplay/tabletop_stage.tscn","res://scenes/gameplay/lower_lab_stage.tscn","res://scenes/gameplay/shaft_descent.tscn","res://scenes/gameplay/hive_stage.tscn"]
const NAMES := ["Introdução","Tutorial","Fase 1: bancada","Fase 2: setor inferior","Descida à Colmeia","Fase 3: Colmeia"]
const SECTORS := ["Canos e água","Passagem do vapor","Depósito","Máquina de limpeza","Frasco limpo","Descida ao laboratório"]
const LOWER_SECTORS := ["Enxame de bactérias","Quebra-cabeça de Tibúrcio","Emboscada da porta","Gosma e sabonete","Guardião do Rei","Consertar o elevador"]
const Route = preload("res://scripts/tabletop_route.gd")
const Party = preload("res://scripts/party_transfer.gd")
static func valid(id: int) -> bool:
	return (id >= 0 and id < PHASES.size()) or (id >= 10 and id < 10+SECTORS.size()) or (id >= 20 and id < 20+LOWER_SECTORS.size()) or id == 30
static func path_for(id: int) -> String:
	if not valid(id): return ""
	return PHASES[5 if id == 30 else (3 if id >= 20 else (2 if id >= 10 else id))]
static func reset(tree: SceneTree) -> void:
	for key in ["party_state","tabletop_entry_state","tabletop_checkpoint","tabletop_retry","lower_lab_entry_state","shaft_entry_state","hive_entry_state","lower_lab_chapter","hive_chapter","hive_king_checkpoint","hive_king_retry"]:
		if tree.has_meta(key): tree.remove_meta(key)
static func open(tree: SceneTree, id: int, preserve_party := false) -> Error:
	if not valid(id): return ERR_INVALID_PARAMETER
	var party: Array[Dictionary] = []
	if preserve_party and is_instance_valid(tree.current_scene) and tree.current_scene.is_in_group("arena"):
		party = Party.capture(tree.current_scene)
		if id < 2: tree.set_meta("local_coop", not tree.current_scene.players[1].ai_controlled)
	reset(tree)
	if id >= 10:
		for player in party:
			player["hp"] = maxi(40,player["hp"])
			player["down"] = false
	if id >= 10 and id < 20:
		tree.set_meta("tabletop_entry_state",party.duplicate(true))
		tree.set_meta("tabletop_checkpoint",sector_checkpoint(id-10,party))
		tree.set_meta("tabletop_retry",true)
	elif id in [3, 4, 5, 30] or id in range(20, 26):
		if party.is_empty(): party.append({})
		party[0]["clean_sample"] = true
		tree.set_meta("party_state", party)
	elif id >= 2 and not party.is_empty(): tree.set_meta("party_state",party)
	if id >= 20 and id < 30: tree.set_meta("lower_lab_chapter",id-20)
	if id == 30: tree.set_meta("hive_chapter",true)
	return tree.change_scene_to_file(path_for(id))
static func sector_checkpoint(sector: int, party: Array) -> Dictionary:
	var steps := [Route.Step.PIPES,Route.Step.STEAM,Route.Step.EXPLORE,Route.Step.EXPLORE,Route.Step.SAMPLE,Route.Step.EXIT]
	var positions := [Vector2(2660,286),Vector2(3320,286),Vector2(4580,291),Vector2(5370,292),Vector2(5500,292),Vector2(6460,290)]
	return {"name":SECTORS[sector],"at":positions[sector],"party":party,"step":steps[sector],"drained":sector>=1,"passage":sector>=2,"batteries":[false,false],"supplies":[false,false],"records":[false,false,false],"sample":sector>=5,"ambushes":[sector>=2,sector>=2],"seen":{}}
