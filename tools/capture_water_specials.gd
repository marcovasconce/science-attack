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
	var max_player = arena.players[0]
	var amanda = arena.players[1]
	max_player.position = Vector2(1860,266)
	amanda.position = Vector2(1960,318)
	max_player.equip_weapon("bubbles")
	amanda.equip_weapon("brush")
	max_player.energy = 50
	amanda.energy = 100
	arena.get_node("Camera2D").position.x = 1920
	DirAccess.make_dir_recursive_absolute("res://.godot/water_frames")
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	for frame in 12:
		await simulate()
		await capture("")
	max_player.energy = 50
	assert(max_player.specials.try_activate())
	for frame in 46:
		await simulate()
		if frame == 17: await capture("res://art/previews/giant_bubble_half.png",false)
		await capture("")
	max_player.energy = 100
	assert(max_player.specials.try_activate())
	for frame in 78:
		await simulate()
		if frame == 28: await capture("res://art/previews/soap_water_beam.png",false)
		await capture("")
	max_player.position = Vector2(1860,318)
	amanda.position = Vector2(2030,266)
	amanda.energy = 100
	assert(amanda.specials.try_activate())
	for frame in 32:
		await simulate()
		if frame == 15: await capture("res://art/previews/brush_water_impact.png",false)
		await capture("")
	for frame in 12:
		await simulate()
		await capture("")
	print("Captured %d frames: giant bubble at half bar, three-second water beam and dramatic brush impact." % serial)
	quit()
func simulate() -> void:
	for substep in 3:
		await physics_frame
		for player in arena.players: player._physics_process(1.0/60.0)
		for shot in arena.get_node("Projectiles").get_children():
			shot.set_physics_process(false)
			shot._physics_process(1.0/60.0)
		arena.update_camera_shake(1.0/60.0)
func capture(path: String, sequence: bool = true) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/water_frames/%03d.png" % serial if path.is_empty() else path)
	if sequence: serial += 1

