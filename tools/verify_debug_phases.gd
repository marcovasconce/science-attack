extends SceneTree

func _initialize() -> void: call_deferred("run")

func settle() -> void:
	for frame in 4: await process_frame

func run() -> void:
	var debug = root.get_node("DebugPhases")
	assert(change_scene_to_file(debug.PHASES[0]) == OK)
	await settle()
	debug.skip_next()
	debug.skip_next()
	await settle()
	assert(current_scene.scene_file_path == debug.PHASES[1], "Repeated requests must skip only once")
	current_scene.players[0].equip_weapon("bubbles")
	current_scene.players[0].hp = 73
	current_scene.players[1].equip_weapon("brush")
	debug.skip_next()
	await settle()
	assert(current_scene.scene_file_path == debug.PHASES[2])
	assert(current_scene.players[0].equipped_weapon == "bubbles" and current_scene.players[0].hp == 73, "Debug skip must preserve the party")
	assert(current_scene.players[1].equipped_weapon == "brush")
	debug.skip_next()
	await settle()
	assert(current_scene.scene_file_path == debug.PHASES[0], "Last phase wraps to the introduction")
	assert(not has_meta("tabletop_entry_state") and not has_meta("party_state"))
	debug.go_to_phase(2)
	await settle()
	assert(current_scene.players[0].equipped_weapon == "brush" and current_scene.players[0].hp == 100, "Direct entry must use a fresh playable party")
	for sector in debug.SECTORS.size():
		debug.go_to_phase(10+sector)
		await settle()
		assert(current_scene.scene_file_path == debug.PHASES[2] and current_scene.puzzle.finished,"Each sector starts with the running generator")
		assert(current_scene.route.drained == (sector>=1) and current_scene.route.passage_open == (sector>=2),"Sector shortcut restores only its prerequisite gates")
		assert(current_scene.route.sample_taken == (sector>=5),"Shortcuts keep later objectives available to test")
	debug.go_to_phase(2)
	await settle()
	assert(not current_scene.route.powered and not has_meta("tabletop_checkpoint") and not has_meta("tabletop_retry"),"Fresh phase selection clears sector checkpoints")
	print("PASS: debug phase skip, duplicate request guard, party transfer, wraparound, all six simpler sector shortcuts and checkpoint reset")
	quit()
