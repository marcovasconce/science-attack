extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").pause()
	var lift = arena.elevator
	lift.set_physics_process(false)
	for player in arena.players:
		player.set_physics_process(false)
		player.equip_weapon("brush" if player.player_id==0 else "bubbles")
		player.hp = 64+player.player_id
		player.energy = 50
		player.healing_flasks = 3
	lift.rider_origins.assign([arena.players[0].position,arena.players[1].position])
	lift.state = lift.State.ASCENDING
	lift.next_scene_path = "res://scenes/missing_next_phase.tscn"
	lift._physics_process(3)
	lift._physics_process(0.7)
	check(lift.state==lift.State.COMPLETE and "NÃO FOI" in lift.loading_label.text,"A missing configured destination offers a clear recoverable failure")
	# Exercise the real second stage and its consumption of the transferred party.
	lift.state = lift.State.ASCENDING
	lift.loading_time = 0
	lift.next_scene_path = "res://scenes/gameplay/tabletop_stage.tscn"
	lift._physics_process(3)
	for attempt in 120:
		await process_frame
		if ResourceLoader.load_threaded_get_status(lift.next_scene_path)!=ResourceLoader.THREAD_LOAD_IN_PROGRESS: break
	lift._physics_process(0.7)
	for frame in 3: await process_frame
	check(current_scene!=null and current_scene.name=="TabletopStage","The real second stage becomes the active scene")
	var party: Array = current_scene.players
	check(party.size()==2 and not has_meta("party_state"),"The next stage consumes the two-character transfer")
	if party.size()==2:
		check(party[0].equipped_weapon=="brush" and party[1].equipped_weapon=="bubbles","Loadout survives the scene handoff")
		check(party[0].hp==64 and party[1].hp==65 and party[0].energy==50 and party[1].healing_flasks==3,"Health, energy and flasks survive the scene handoff")
		check(not party[0].ai_controlled and party[1].ai_controlled,"Solo/co-op mode survives the scene handoff")
		check(current_scene.controls_locked and not current_scene.elevator.arrived,"The new stage begins inside the closed arrival lift")
	if failures.is_empty(): print("PASS: missing-destination recovery, threaded loading, actual scene change and party-state handoff")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
