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
	arena.get_node("Gate/Collision").disabled = true
	for path in ["HUD/Communicator","GoalMarker","HUD/Goal"]: arena.get_node(path).hide()
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.hide()
	for p in arena.players:
		p.set_physics_process(false)
		p.ai_controlled = false
		p.equip_weapon("brush")
	arena.players[0].position = Vector2(1820,260)
	arena.players[1].position = Vector2(1960,317)
	arena.get_node("Camera2D").position.x = 1920
	DirAccess.make_dir_recursive_absolute("res://.godot/brush_choreography_frames")
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	# Capture actual physics updates rather than posing stationary actors.
	for round_index in 2:
		for p in arena.players:
			p.facing = 1 if round_index == 0 else -1
			p.chain_grace = 0
		for combo in 3:
			for p in arena.players: p.start_attack()
			var frame := 0
			while arena.players[0].attack_time > 0:
				for substep in 3:
					await physics_frame
					for p in arena.players: p._physics_process(1.0/60.0)
				await capture("res://.godot/brush_choreography_frames/%03d.png" % serial)
				serial += 1
				if round_index == 0 and frame == 5:
					await capture("res://art/previews/brush_choreography_%d.png" % (combo+1))
				frame += 1
		for i in 5:
			for substep in 3:
				await physics_frame
				for p in arena.players: p._physics_process(1.0/60.0)
			await capture("res://.godot/brush_choreography_frames/%03d.png" % serial)
			serial += 1
	for p in arena.players:
		p.facing = 1
		p.jump_height = 18
		p.jump_speed = 190
		p.start_attack()
	for i in 14:
		for substep in 3:
			await physics_frame
			for p in arena.players: p._physics_process(1.0/60.0)
		await capture("res://.godot/brush_choreography_frames/%03d.png" % serial)
		serial += 1
	print("Captured %d frames of actual brush combos, forward steps, left-facing motion and air attacks." % serial)
	quit()
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
