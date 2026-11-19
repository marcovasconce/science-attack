extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	set_meta("hive_chapter",true)
	var stage = load("res://scenes/gameplay/hive_stage.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	stage.set_physics_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
	for vent in stage.vents: vent.set_process(false)
	check(stage.world_limit == 6786 and stage.floor_min == 190,"Expanded length and depth")
	check(stage.get_node("Scenery/Floor/Stone106_0") != null,"Floor covers enlarged map")
	check(stage.west_gate.openness == 0 and stage.open_limit < stage.WAVE_ENTRY,"Workshop is closed before upgrading")
	stage.players[0].position.x = stage.bubble_puzzle.position.x-90
	stage.players[1].position.x = stage.bubble_puzzle.position.x+40
	stage._process(0.016)
	check(stage.workshop_radio.visible and stage.workshop_radio.speaker == "DRA. AMANDA","Workshop arrival shows Amanda")
	check(stage.workshop_radio.words == "rápido! vamos usar o material de emergencia e melhorar nossos equipamentos!","Requested dialogue preserved")
	stage._begin_assault()
	check(stage.beat == stage.Beat.WORKSHOP,"Wave cannot bypass mandatory upgrade")
	stage.players[0].position.x = stage.open_limit-1
	Input.action_press("p0_right")
	stage.players[0]._physics_process(0.25)
	Input.action_release("p0_right")
	check(stage.players[0].position.x <= stage.open_limit,"Player movement obeys closed workshop")
	stage.players[0].position.x = stage.bubble_puzzle.position.x-75
	var puzzle = stage.bubble_puzzle
	# Exercise both actual switches and the full bubble trajectory.
	puzzle.adjust(0)
	puzzle.adjust(1)
	for frame in 600:
		puzzle.tick(1.0/60,stage.players)
		if puzzle.solved: break
	check(puzzle.solved,"Reskinned bubble puzzle remains solvable")
	stage._tick_arsenal(0.4)
	check(not stage.arsenal_claimed and stage.open_limit < stage.WAVE_ENTRY,"Gate stays closed through forge animation")
	stage._tick_arsenal(0.5)
	check(stage._weapons_ready() and stage.players[0].weapon_upgraded and stage.players[1].weapon_upgraded,"Both weapons upgrade together")
	check(stage.open_limit == stage.WAVE_EAST,"Upgrade unlocks route")
	stage._physics_process(0.5)
	check(stage.west_gate.openness == 1,"Physical workshop door opens")
	stage._begin_assault()
	check(stage.beat == stage.Beat.ASSAULT,"Upgraded party can start combat")
	for wave in 2:
		stage._start_next_assault()
		for enemy in get_nodes_in_group("germs"):
			if enemy == stage.king: continue
			check(enemy.position.x > stage.WAVE_WEST and enemy.position.x < stage.WAVE_EAST,"Intro enemies follow expanded layout")
			enemy.free()
		stage.remaining = 0
	stage._start_next_assault()
	for index in 4:
		stage._start_sewer_room()
		stage._sewer_wave()
		for enemy in get_nodes_in_group("germs"):
			if enemy == stage.king: continue
			check(enemy.position.x > stage.room_left and enemy.position.x < stage.open_limit,"Sector enemies spawn inside new boundaries")
			enemy.free()
		stage.remaining = 0
		stage._open_next_sector()
	check(stage.sector == 4 and stage.open_limit == stage.room_right,"All four sectors unlock next expanded rooms")
	stage.players[0].position = Vector2(stage.KING_WEST+100,260)
	stage.players[1].position = Vector2(stage.KING_WEST+150,300)
	stage._begin_king()
	stage._update_camera(1)
	var camera: Camera2D = stage.get_node("Camera2D")
	check(stage.room_right-stage.KING_WEST == 840 and 640/camera.zoom.x >= 840,"King arena and camera provide full fight width")
	check(stage.king.position.x > stage.KING_WEST and stage.king.position.x < stage.room_right,"King remapped to final arena")
	stage._king_reinforcements()
	for enemy in get_nodes_in_group("germs"):
		if enemy == stage.king: continue
		check(enemy.position.x > stage.KING_WEST and enemy.position.x < stage.room_right,"King reinforcements use new arena")
	stage._restore_king_checkpoint()
	check(stage._weapons_ready() and stage.players[0].position.x > stage.KING_WEST,"Boss retry preserves upgrades and new spawn")
	if failures.is_empty(): print("PASS: expanded map, physical workshop gate, Amanda dialogue, real puzzle solution, both upgrades, all sectors, king camera and checkpoint")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

