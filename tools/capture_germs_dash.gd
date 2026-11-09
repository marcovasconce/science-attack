extends SceneTree
var arena: Node2D
var germs: Array = []
var serial := 0
var clock := 0.0
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
	arena.get_node("Actors/TrainingDummy").hide()
	for path in ["HUD/Communicator","GoalMarker","HUD/Goal"]: arena.get_node(path).hide()
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
		crate.hide()
	for player in arena.players:
		player.set_physics_process(false)
		player.ai_controlled = false
		player.equip_weapon("bubbles")
		player.position = Vector2(1980,245+player.player_id*65)
	for index in 2:
		var germ = load("res://scenes/actors/germ.tscn").instantiate()
		germ.variant = "green" if index == 0 else "red"
		germ.position = Vector2(2090+index*100,245+index*48)
		arena.get_node("Actors").add_child(germ)
		germ.set_physics_process(false)
		germs.append(germ)
	arena.get_node("Camera2D").position.x = 1920
	DirAccess.make_dir_recursive_absolute("res://.godot/germ_dash_frames")
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	for frame in 28:
		await simulate()
		await capture("")
	Input.action_press("p0_left")
	Input.action_press("p1_left")
	for frame in 20:
		await simulate()
		if frame == 10: await capture("res://art/previews/gun_walk_fixed.png",false)
		await capture("")
	Input.action_release("p0_left")
	Input.action_release("p1_left")
	for player in arena.players:
		player.facing = 1
		player.dash = 0.24
	for frame in 12:
		await simulate()
		if frame == 1: await capture("res://art/previews/subtle_dash.png",false)
		await capture("")
	for frame in 18:
		await simulate()
		await capture("")
	arena.players[0].equip_weapon("brush")
	arena.players[0].position = Vector2(1920,260)
	arena.players[1].position = Vector2(1810,320)
	arena.players[0].energy = 100
	arena.players[0].specials.try_activate()
	for frame in 32:
		await simulate()
		if frame == 15: await capture("res://art/previews/brush_water_ripple.png",false)
		await capture("")
	for frame in 24:
		await simulate()
		await capture("")
	print("Captured %d frames: germ animation, corrected walking guns, dash, smaller watery impact." % serial)
	quit()
func simulate() -> void:
	for substep in 3:
		await physics_frame
		clock += 1.0/60.0
		for player in arena.players: player._physics_process(1.0/60.0)
		for germ in germs:
			if is_instance_valid(germ): germ.pixel_visual.sync(clock,false)
		arena.update_camera_shake(1.0/60.0)
func capture(path: String, sequence: bool = true) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/germ_dash_frames/%03d.png" % serial if path.is_empty() else path)
	if sequence: serial += 1
