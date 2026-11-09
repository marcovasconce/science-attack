extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.get_node("WakeSequence").play("wake")
	arena.get_node("WakeSequence").seek(3.6, true)
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	arena.tutorial.step = 6
	for actor in arena.players:
		actor.set_physics_process(false)
	arena.players[0].position = Vector2(530,250)
	arena.players[1].position = Vector2(500,285)
	arena.collect_parts(8,Vector2(460,275))
	var site = arena.get_node("BuildSite")
	site.set_process(false)
	arena.interact(arena.players[0],0.4)
	assert(site.snapped_units == 1 and site.bursts.size() == 1, "First socket must emit one burst")
	site.sample(arena.build_progress / arena.BUILD_DURATION)
	assert(site.bursts.size() == 1, "Repeated sampling must not duplicate impacts")
	for frame in 20:
		arena.interact(arena.players[0],0.08)
		site._process(0.08)
		site.update_camera(0.08,Vector2(515,267.5))
	assert(arena.get_node("Camera2D").zoom.x > 1.1, "Construction must move the camera")
	var saved_progress: float = arena.build_progress
	arena.build_grace = 0
	for frame in 45:
		site._process(1.0 / 60.0)
		site.update_camera(1.0 / 60.0,Vector2(515,267.5))
	assert(arena.get_node("Camera2D").zoom.is_equal_approx(Vector2.ONE), "Releasing build must restore the camera")
	assert(arena.build_progress == saved_progress, "Releasing build must retain assembled pieces")
	arena.build_grace = 0.2
	site.update_camera(0.4,Vector2(515,267.5))
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/previews/build_snap_feedback.png")
	arena.interact(arena.players[0],2.0)
	assert(arena.built and arena.pieces == 0 and site.snapped_units == 8, "Completion must consume eight pieces once")
	assert(site.completion_hold > 0, "Final assembly must briefly hold its framing")
	for frame in 90:
		site._process(1.0 / 60.0)
		site.update_camera(1.0 / 60.0,Vector2(515,267.5))
	assert(site.bursts.is_empty(), "Particles must expire")
	assert(arena.get_node("Camera2D").zoom.is_equal_approx(Vector2.ONE), "Camera must return after completion")
	assert(arena.get_node("Bridge/Deck2").position.is_equal_approx(site.deck_origins[2]), "Bridge must settle in its original position")
	site.sample(0.0)
	assert(site.snapped_units == 0 and site.bursts.is_empty(), "Rewinding must reset feedback")
	print("PASS: unique socket impacts, build camera, completion hold, settled bridge, particle cleanup and rewind")
	quit()
