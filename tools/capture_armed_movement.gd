extends SceneTree
var arena: Node2D
var serial := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	arena.open_limit = 2230
	arena.built = true
	arena.get_node("BuildSite").set_process(false)
	arena.get_node("BuildSite").sample(1)
	arena.encounter.unlock_route()
	arena.encounter.talked = true
	arena.encounter.robot_inspected = true
	arena.get_node("Gate/Collision").disabled = true
	for path in ["HUD/Communicator","GoalMarker","HUD/Goal"]: arena.get_node(path).hide()
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
		crate.hide()
	for player in arena.players:
		player.set_physics_process(false)
		player.ai_controlled = false
		player.position = Vector2(1830,230+player.player_id*78)
		player.facing = 1
	arena.get_node("Camera2D").position.x = 1920
	DirAccess.make_dir_recursive_absolute("res://.godot/armed_frames")
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	for weapon in ["brush","bubbles"]:
		for player in arena.players:
			player.position.x = 1830
			player.equip_weapon(weapon)
			player._physics_process(0)
		for frame in 24:
			await simulate()
			await capture("")
		await capture("res://art/previews/"+weapon+"_armed_idle.png",false)
		Input.action_press("p0_right")
		Input.action_press("p1_right")
		for frame in 24:
			await simulate()
			if frame == 17: await capture("res://art/previews/"+weapon+"_armed_walk.png",false)
			await capture("")
		Input.action_release("p0_right")
		Input.action_release("p1_right")
		Input.action_press("p0_left")
		Input.action_press("p1_left")
		for frame in 24:
			await simulate()
			await capture("")
		Input.action_release("p0_left")
		Input.action_release("p1_left")
		for player in arena.players:
			player.position.x = 2025 if weapon == "brush" else 1870
			player.facing = 1
		Input.action_press("p0_attack")
		Input.action_press("p1_attack")
		for frame in 50:
			await simulate()
			if frame == 22: await capture("res://art/previews/"+weapon+"_held_attack.png",false)
			await capture("")
		Input.action_release("p0_attack")
		Input.action_release("p1_attack")
		for frame in 14:
			await simulate()
			await capture("")
	print("Captured %d actual frames: armed idle, walking in both directions, held brush combo, slower soap gun." % serial)
	quit()
func simulate() -> void:
	for substep in 3:
		await physics_frame
		for player in arena.players: player._physics_process(1.0/60.0)
		for shot in arena.get_node("Projectiles").get_children():
			shot.set_physics_process(false)
			shot._physics_process(1.0/60.0)
func capture(path: String, sequence: bool = true) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/armed_frames/%03d.png" % serial if path.is_empty() else path)
	if sequence: serial += 1

