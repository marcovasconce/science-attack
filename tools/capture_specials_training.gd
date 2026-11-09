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
		crate.hide()
	for p in arena.players:
		p.set_physics_process(false)
		p.ai_controlled = false
	var max_player = arena.players[0]
	var amanda = arena.players[1]
	max_player.position = Vector2(1990,265)
	amanda.position = Vector2(1960,315)
	max_player.equip_weapon("brush")
	amanda.equip_weapon("bubbles")
	max_player.energy = 50
	amanda.energy = 100
	for p in arena.players: p._physics_process(0)
	arena.get_node("Camera2D").position.x = 1920
	var dummy = arena.get_node("Actors/TrainingDummy")
	dummy.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://.godot/specials_frames")
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	if "--controls-only" in OS.get_cmdline_user_args():
		arena.get_node("HUD/ControlsPanel").show()
		await capture("res://art/previews/specials_controls.png")
		quit()
		return
	for frame in 32:
		for p in arena.players:
			p.sprite.play(p.equipped_weapon+"_idle")
			p.sprite.frame = (frame/4)%8
			p.sprite.pause()
			p.update_sprite_alignment()
		dummy._process(0.05)
		if frame == 10: await capture("res://art/previews/weapon_idles_dummy.png")
		await sequence()
	max_player.position.x = 2035
	max_player.specials.try_activate()
	assert(max_player.specials.kind == "brush1" and max_player.specials.active)
	for frame in 120:
		await simulate(0.05)
		if frame == 22: await capture("res://art/previews/brush_spin_special.png")
		await sequence()
	max_player.energy = 100
	max_player.specials.try_activate()
	assert(max_player.specials.kind == "brush2" and max_player.specials.active)
	for frame in 28:
		await simulate(0.05)
		if frame == 19: await capture("res://art/previews/brush_ultimate.png")
		await sequence()
	amanda.position = Vector2(1910,266)
	max_player.position = Vector2(1995,317)
	amanda.energy = 50
	amanda.specials.try_activate()
	assert(amanda.specials.kind == "bubbles1" and amanda.specials.active)
	for frame in 60:
		await simulate(0.05)
		if frame == 22: await capture("res://art/previews/giant_bubble_half.png")
		await sequence()
	for shot in arena.get_node("Projectiles").get_children(): shot.queue_free()
	amanda.energy = 100
	amanda.specials.try_activate()
	assert(amanda.specials.kind == "bubbles2" and amanda.specials.active)
	for frame in 78:
		await simulate(0.05)
		if frame == 13: await capture("res://art/previews/soap_water_beam.png")
		await sequence()
	arena.get_node("HUD/ControlsPanel").show()
	await capture("res://art/previews/specials_controls.png")
	print("Captured %d frames: holding idles, training robot, six-second spin, strong brush, giant bubble and continuous water beam." % serial)
	quit()
func simulate(_dt: float) -> void:
	for substep in 3:
		await physics_frame
		for p in arena.players: p._physics_process(1.0/60.0)
		for shot in arena.get_node("Projectiles").get_children():
			shot.set_physics_process(false)
			shot._physics_process(1.0/60.0)
		arena.get_node("Actors/TrainingDummy")._process(1.0/60.0)
func sequence() -> void:
	await capture("res://.godot/specials_frames/%03d.png" % serial)
	serial += 1
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
