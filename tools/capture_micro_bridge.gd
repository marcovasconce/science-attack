extends SceneTree
var arena: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.get_node("WakeSequence").seek(3.6, true)
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	for actor in arena.players:
		actor.set_physics_process(false)
		actor.sprite.play("idle")
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.set_process(false)
	var box = arena.get_node("HUD/Communicator")
	box.set_process(false)
	var site = arena.get_node("BuildSite")
	site.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	DirAccess.make_dir_recursive_absolute("res://.godot/micro_bridge_frames")
	arena.tutorial.step = 4
	arena.players[0].position = Vector2(340, 260)
	arena.players[1].position = Vector2(290, 300)
	arena.tutorial._process(0.0)
	arena._process(0.0)
	box._process(3.0)
	await capture("res://art/previews/microscopic_stage.png")
	for i in 3:
		var crate = arena.get_node("Breakables/Crate%d" % i)
		crate.take_hit(100, 1.0, arena.players[0])
		crate._process(1.0)
	for effect in arena.get_node("ImpactEffects").get_children(): effect.queue_free()
	site._process(1.0)
	arena.tutorial.step = 6
	arena.wave = 1
	arena.tutorial.next_delay = 0
	arena.players[0].position = Vector2(530, 250)
	arena.players[1].position = Vector2(500, 285)
	arena.tutorial._process(0.0)
	arena._process(0.0)
	arena.get_node("Camera2D").position.x = 590
	box._process(3.0)
	await capture("res://art/previews/microscopic_gap.png")
	for frame in 65:
		if frame >= 12 and frame < 53: arena.interact(arena.players[0], arena.BUILD_DURATION / 40.0)
		arena._process(0.0)
		arena.get_node("Camera2D").position.x = 590
		for actor in arena.players:
			actor.sprite.play("build" if not arena.built and frame >= 12 else "idle")
			actor.sprite.frame = frame % 6 if not arena.built and frame >= 12 else 0
			actor.sprite.pause()
		for enemy in get_nodes_in_group("germs"):
			enemy.set_physics_process(false)
		site.sample(arena.build_progress / arena.BUILD_DURATION)
		arena.get_node("HUD/Pieces").text = "%02d" % arena.pieces
		if frame == 31: await capture("res://art/previews/metal_bridge_building.png")
		if frame == 64: await capture("res://art/previews/metal_bridge_complete.png")
		await capture("res://.godot/micro_bridge_frames/%03d.png" % frame)
	arena.players[0].position = Vector2(670, 250)
	arena.players[1].position = Vector2(630, 290)
	arena.tutorial.step = 7
	arena.tutorial._process(0.0)
	box._process(3.0)
	await capture("res://art/previews/metal_bridge_crossing.png")
	arena.players[1].ai_controlled = false
	arena.get_node("HUD/TeamHUD")._process(0.0)
	arena._on_hud_layout_changed(true)
	arena.tutorial.step = 7
	arena.tutorial.next_delay = 0
	arena.tutorial._process(0.0)
	box._process(3.0)
	await capture("res://art/previews/microscopic_coop.png")
	print("Captured microscopic stage, gap, metal bridge assembly/crossing, screws and tutorial solo/co-op.")
	quit()
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
