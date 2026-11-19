extends SceneTree
var stage: Node2D
var route: Node2D

func _initialize() -> void: call_deferred("run")

func tick(dt: float) -> void:
	route._process(dt)
	stage.encounter.dialogue._process(dt)
	stage.encounter._process(dt)
	stage.get_node("HUD/Goal").text = route.objective_text()
	stage.get_node("HUD/Goal").visible = not stage.encounter.dialogue.active
	for actor in stage.players: actor.update_sprite_alignment()

func view_at(x: float, at: Vector2) -> void:
	stage.get_node("Camera2D").position = Vector2(x,180)
	stage.get_node("Environment").follow_camera(x)
	stage.players[0].position = at
	stage.players[1].position = at+Vector2(-42,20)
	stage.get_node("HUD/AdvanceArrow").hide()

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/kids_"+label+".png")

func run() -> void:
	stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.elevator.get_node("Hint").hide()
	stage.puzzle.set_process(false)
	stage.puzzle.restore_running()
	stage.encounter.message_started = true
	stage.encounter.message_finished = true
	stage.encounter.set_process(false)
	stage.encounter.dialogue.set_process(false)
	route = stage.route
	route.set_process(false)
	for actor in stage.players:
		actor.set_physics_process(false)
		actor.sprite.play(actor.equipped_weapon+"_idle")
		actor.sprite.pause()
	for crate in stage.get_node("Breakables").get_children(): crate.freeze = true
	route.powered = true
	route.step = route.Step.PIPES
	route.get_node("PowerGate").openness = 1
	route._set_limit(3090)
	view_at(2880,route.VALVE_POINTS[0])
	stage.players[0].position = route.PUMP_POINT
	route.try_action(stage.players[0])
	var sequence := "--sequence" in OS.get_cmdline_user_args()
	if sequence: DirAccess.make_dir_recursive_absolute("res://.godot/kids_water_frames")
	for frame in 450:
		var p = stage.players[0]
		var goal: Vector2 = route.VALVE_POINTS[0 if frame < 70 else (1 if frame < 175 else 2)]
		var walking: bool = p.position.distance_to(goal) > 1
		p.position = p.position.move_toward(goal,145.0/30)
		stage.players[1].position = stage.players[1].position.move_toward(p.position+Vector2(-42,20),145.0/30)
		for actor in stage.players:
			actor.sprite.animation = actor.equipped_weapon+("_run" if walking else "_idle")
			actor.sprite.frame = (frame/4)%actor.sprite.sprite_frames.get_frame_count(actor.sprite.animation)
		if frame in [15,25,35]: route.turn_valve(0,p)
		if frame == 100: route.turn_valve(1,p)
		if frame == 205: route.turn_valve(2,p)
		tick(1.0/30)
		if frame == 12: await capture("01_radio_and_dry_pipes")
		if frame == 78: await capture("02_partial_water")
		if frame == 175: await capture("03_water_stops")
		if frame == 250: await capture("04_water_reaches_tank")
		if frame == 330: await capture("05_full_tank")
		if sequence:
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/kids_water_frames/%04d.png" % frame)
	stage.encounter.clear()
	stage.encounter.gap = 0
	view_at(3690,Vector2(3650,295))
	route.steam_clock = 3.1
	tick(0)
	await capture("06_steam")
	for germ in get_nodes_in_group("germs"): germ.free()
	route.ambushes = [true,true]
	tick(0.1)
	stage.encounter.clear()
	stage.encounter.gap = 0
	view_at(4840,Vector2(4800,302))
	tick(1)
	await capture("07_storage_without_puzzles")
	var box = route.get_node("Supply1")
	box.set_process(false)
	stage.players[0].position = box.position-Vector2(55,0)
	stage.players[0].facing = 1
	stage.strike(stage.players[0],3,[])
	box._process(0.3)
	await capture("07b_supply_loot_rising")
	box._process(0.5)
	await capture("07c_supply_loot_landed")
	route.get_node("PassageGate").openness = 0.5
	view_at(4390,Vector2(4310,300))
	await capture("07d_gate_descending")
	route.get_node("PassageGate").openness = 1
	stage.encounter.clear()
	stage.encounter.gap = 0
	view_at(5520,route.CONSOLE_POINT)
	route.try_action(stage.players[0])
	for enemy in get_nodes_in_group("germs"): enemy.set_physics_process(false)
	tick(5)
	await capture("08_cleaner_and_radio")
	stage.players[1].ai_controlled = false
	stage.get_node("HUD/TeamHUD")._apply_mode()
	tick(0)
	await capture("08b_two_players_radio")
	stage.players[1].ai_controlled = true
	stage.get_node("HUD/TeamHUD")._apply_mode()
	for enemy in get_nodes_in_group("germs"): enemy.free()
	stage.encounter.clear()
	route.step = route.Step.SAMPLE
	route.charge = 30
	route.purify_age = 2.5
	view_at(5520,Vector2(5490,310))
	tick(0)
	await capture("09_clean_bottle")
	route.sample_taken = true
	route.step = route.Step.EXIT
	route.get_node("ExitGate").openness = 1
	view_at(6850,Vector2(6810,300))
	tick(0)
	var lift = route.get_node("ExitElevator")
	lift.set_physics_process(false)
	lift._physics_process(0)
	await capture("10_exit")
	stage.players[0].position = lift.pads[0].global_position
	stage.players[1].position = lift.pads[1].global_position
	lift._physics_process(0.41)
	await capture("11_elevator_boarded")
	lift._physics_process(0.8)
	await capture("12_elevator_descending")
	lift._physics_process(2.0)
	await capture("13_elevator_loading")
	for frame in 300:
		await process_frame
		if ResourceLoader.load_threaded_get_status(lift.next_scene_path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS: break
	lift._physics_process(0.7)
	for frame in 4: await process_frame
	stage = current_scene
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	await capture("14_lower_lab_arrival")
	print("PASS: simpler route captures saved as art/previews/kids_*.png")
	quit()
