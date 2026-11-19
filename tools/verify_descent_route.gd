extends SceneTree
var stage
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func freeze() -> void:
	stage.set_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
func run() -> void:
	set_meta("party_state",[{"hp":67,"max_hp":120,"weapon":"brush","healing_flasks":3,"energy":42,"pieces":13,"ai_controlled":false},{"hp":83,"weapon":"bubbles","healing_flasks":2,"energy":64,"pieces":13,"ai_controlled":true}])
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	freeze()
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.finale.set_process(false)
	stage.exit_lift.set_physics_process(false)
	var finale = stage.finale
	var p = stage.players[0]
	var q = stage.players[1]
	check(stage.pieces == 13,"Parts carried from the previous stage reach the lower laboratory")
	check(int(finale.locker_at.x) in [2910,3060,3180],"Soap selects one of three nearby lockers behind the slime")
	stage.beat = stage.Beat.FINISHED
	p.position = Vector2(3100,260)
	finale._process(0.01)
	check(not finale.soap_search_started and finale.locker.material == null,"The soap search waits until the party discovers the blockage")
	p.position = Vector2(3310,270)
	finale._process(0.01)
	check(finale.soap_search_started and stage.journey_radio.words == finale.SOAP_LINE,"Reaching the larger slime triggers Amanda's exact requested line")
	var outlined := 0
	for locker in stage.corridor.lockers:
		if locker.material != null: outlined += 1
	check(outlined == 1 and finale.locker_at.x < p.position.x-100,"Exactly one locker is outlined and requires backtracking")
	check(not finale.interact(p),"Slime cannot be cleaned before fetching the soap")
	p.position = finale.locker_at+Vector2(0,52)
	check(finale.interact(p) and finale.has_soap,"The chosen random locker gives the soap")
	check(not finale.interact(p),"The soap cannot be duplicated")
	p.position = Vector2(3310,270)
	check(finale.interact(p),"Returning to the blockage begins cleaning")
	finale._process(3.1)
	check(finale.cleaned and not stage.controls_locked,"Larger slime clears through the existing bubble animation")
	var lift = stage.exit_lift
	p.position = lift.repair_point()
	stage.interact(p,1)
	check(lift.repair_progress == 0,"The lift cannot be repaired before the mini boss is defeated")
	finale.state = finale.State.DONE
	lift._physics_process(0.1)
	check(stage.journey_radio.speaker == "MAX" and stage.journey_radio.words == lift.MAX_LINE,"Approaching after the boss shows Max's requested repair line")
	stage.pieces = 7
	stage.interact(p,1)
	check(lift.repair_progress == 0 and stage.pieces == 7,"Insufficient parts cannot start or partially charge the repair")
	var salvage: Array = stage.get_node("Breakables").get_children().filter(func(crate): return crate.drops_salvage)
	check(salvage.size() == 3,"Three reachable salvage crates guarantee enough parts for the repair")
	for crate in salvage: crate.take_hit(99,1,p)
	check(stage.pieces == 16,"The three crates provide nine real inventory parts")
	for i in 15:
		await physics_frame
		stage.interact(p,0.1)
	check(not lift.repaired and stage.pieces == 8 and stage.is_assembling(p),"Repair progresses while held and reserves the parts at the start")
	stage.controls_locked = true
	var progress: float = lift.repair_progress
	stage.interact(p,2)
	check(lift.repair_progress == progress,"Repair freezes during pause")
	stage.controls_locked = false
	Input.action_press("p0_interact")
	p._physics_process(0)
	check(p.sprite.animation == &"build" and p.facing > 0,"The repair uses the construction animation facing the elevator")
	Input.action_release("p0_interact")
	p._physics_process(0)
	check(not stage.is_assembling(p) and lift.repair_progress == progress,"Releasing the repair stops the animation and preserves progress")
	for i in 19:
		await physics_frame
		stage.interact(p,0.1)
	check(lift.repaired and stage.pieces == 8,"Finishing keeps the single charge for eight reserved parts")
	stage.interact(p,5)
	check(stage.pieces == 8,"Repeated interaction cannot spend repair parts again")
	lift._physics_process(1)
	p.position = lift.pads[0].global_position
	q.position = lift.position+Vector2(-200,0)
	q.ai_controlled = true
	check(lift.ai_boarding_destination(q) != null and stage.ai_puzzle_destination(q) != null,"The AI companion gets a route into the repaired elevator")
	q.invulnerable = 0
	q.take_hit(q.hp,p.position)
	for player in stage.players:
		player.attack_time = 0
		player.stun = 0
		player.dash = 0
		player.jump_height = 0
		player.jump_speed = 0
	lift._physics_process(0.41)
	check(lift.is_transitioning() and stage.controls_locked,"One occupied mark starts departure when the companion is down")
	lift._physics_process(0.91)
	check(lift.doors.openness == 0 and lift.state == lift.State.ASCENDING,"The doors visibly close before the loading handoff")
	lift._physics_process(2.0)
	for i in 120:
		await process_frame
		if ResourceLoader.load_threaded_get_status(lift.next_scene_path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS: break
	lift._physics_process(0.7)
	for i in 4: await process_frame
	stage = current_scene
	check(stage.scene_file_path.ends_with("shaft_descent.tscn"),"The repaired lift actually opens the playable descent scene")
	freeze()
	check(stage.players[0].hp == 67 and stage.players[0].max_hp == 120 and stage.players[0].healing_flasks == 3 and stage.pieces == 8,"Health, flasks, maximum health and remaining parts survive boarding")
	var revived = stage.players[1]
	check(not revived.down and revived.hp == revived.max_hp and revived.healing_flasks == 2,"The next stage revives a downed rider and preserves supplies")
	stage.auto_transfer = false
	stage._process(1.2)
	check(stage.ride == stage.Ride.DESCENDING and not stage.controls_locked,"Descent gives control back for combat")
	stage._process(2)
	check(stage.spawned == 2 and stage.composition.red == 1 and stage.composition.yellow == 1,"The first attack mixes a red bacterium and an airborne yellow one")
	for enemy in get_nodes_in_group("germs"): enemy.set_physics_process(false)
	var elapsed: float = stage.elapsed
	stage.get_node("HUD/ControlsPanel").show()
	stage.controls_locked = true
	stage._process(10)
	check(stage.elapsed == elapsed,"Help pauses the forty-second trip and enemy schedule")
	stage.get_node("HUD/ControlsPanel").hide()
	stage.controls_locked = false
	for i in 12: stage._process(0.5)
	check(get_nodes_in_group("germs").size() <= 8,"The small platform caps simultaneous enemies at eight")
	for enemy in get_nodes_in_group("germs"): enemy.free()
	while stage.elapsed < 39.5:
		stage._process(0.5)
		for enemy in get_nodes_in_group("germs"): enemy.free()
	check(stage.composition.red+stage.composition.yellow > stage.composition.green*4,"Reds and flyers dominate the descent encounters")
	stage._process(0.49)
	check(stage.elapsed < 40 and stage.ride == stage.Ride.DESCENDING,"The ride does not end before forty seconds")
	stage._process(0.02)
	check(stage.elapsed == 40 and stage.ride == stage.Ride.ARRIVED and stage.controls_locked,"Exactly forty seconds ends combat and begins arrival")
	stage.players[0].hp = 59
	stage.players[0].energy = 31
	stage.players[1].ai_controlled = true
	stage.players[1].invulnerable = 0
	stage.players[1].take_hit(stage.players[1].hp,stage.players[0].position)
	stage.auto_transfer = true
	stage._process(1.4)
	for i in 4: await process_frame
	stage = current_scene
	check(stage.scene_file_path.ends_with("hive_stage.tscn"),"The end of the descent actually loads the final hive stage")
	freeze()
	check(stage.players[0].hp == 59 and stage.players[0].energy == 31 and stage.pieces == 8,"Combat resources are preserved into the hive")
	check(not stage.players[1].down and stage.players[1].hp == stage.players[1].max_hp,"Arrival in the hive also revives the downed player")
	check(not stage.players[1].get_node("PlayerMarker").visible,"The hive has no overhead player marker")
	stage.get_node("HUD/TeamHUD")._process(0)
	check(stage.get_node("HUD/TeamHUD/Partner/Name").text == "AMANDA","The hive HUD shows the character name")
	stage.arrival_lift._physics_process(2.5)
	stage._process(2.5)
	check(not stage.controls_locked and stage.world_limit == 4044,"The hive elevator opens into the sewer combat stage")
	print("PASS: " if failures.is_empty() else "FAIL: ",checks," soap / repair / descent / hive checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
