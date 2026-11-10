extends SceneTree
var stage: Node2D
var route: Node2D

func _initialize() -> void: call_deferred("run")

func tick(seconds: float) -> void:
	for frame in int(ceil(seconds*60)):
		route._process(1.0/60)
		for enemy in get_nodes_in_group("germs"): enemy.set_physics_process(false)

func capture(label: String, x: float) -> void:
	stage.get_node("Camera2D").position = Vector2(x,180)
	stage.get_node("Environment").follow_camera(x)
	stage.get_node("HUD/Goal").text = route.objective_text()
	stage.encounter.clear()
	stage.get_node("HUD/AdvanceArrow").hide()
	route._sync_visuals(0)
	for actor in stage.players: actor.update_sprite_alignment()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/lab_"+label+".png")

func run() -> void:
	stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.puzzle.set_process(false)
	stage.puzzle.restore_running()
	stage.encounter.set_process(false)
	stage.encounter.dialogue.set_process(false)
	route = stage.route
	route.set_process(false)
	for actor in stage.players: actor.set_physics_process(false)
	for crate in stage.get_node("Breakables").get_children(): crate.freeze = true
	stage.players[0].position = Vector2(2200,290)
	stage.players[1].position = Vector2(2150,310)
	stage.puzzle._process(0.3)
	await capture("01_generator",2225)
	route.begin_power()
	tick(1.5)
	stage.players[0].position = Vector2(2760,300)
	stage.players[1].position = Vector2(2720,318)
	await capture("02_empty",2930)
	stage.players[0].position = route.PUMP_POINT
	route.try_action(stage.players[0])
	tick(1.5)
	await capture("03_collect",2930)
	tick(1.6)
	await capture("04_danger",2930)
	for i in 3:
		stage.players[0].position = route.VALVE_POINTS[i]
		while route.valves[i] != 0: route.turn_valve(i,stage.players[0])
	for i in 900:
		tick(1.0/60)
		if route.step == route.Step.DRAIN: break
	tick(1.4)
	await capture("05_rinse",2930)
	tick(2)
	await capture("06_clean",2930)
	route.steam_clock = 3.2
	stage.players[0].position = Vector2(3620,299)
	stage.players[1].position = Vector2(3590,320)
	await capture("07_steam",3690)
	stage.players[0].position = Vector2(4780,300)
	stage.players[1].position = Vector2(4735,319)
	await capture("07b_storage",4770)
	route.step = route.Step.EXPLORE
	stage.players[0].position = route.CONSOLE_POINT
	stage.players[1].position = route.CONSOLE_POINT+Vector2(-45,24)
	await capture("08_cleaner_idle",5530)
	route.try_action(stage.players[0])
	tick(4)
	await capture("09_cleaner_active",5530)
	for wave in 2:
		tick(6.1 if wave == 0 else 10.1)
		for enemy in get_nodes_in_group("germs"): enemy.free()
		tick(0.02)
		await capture("09b_cleaner_wave%d" % (wave+1),5530)
	for enemy in get_nodes_in_group("germs"): enemy.free()
	route.step = route.Step.PURIFY
	route.charge = 30
	tick(1.2)
	await capture("10_cleaner_rinse",5530)
	tick(1.5)
	await capture("11_cleaner_done",5530)
	print("PASS: 14 laboratory machine captures saved")
	quit()
