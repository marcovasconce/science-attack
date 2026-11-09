extends SceneTree
var stage: Node2D

func _initialize() -> void: call_deferred("run")

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/generator_"+name+".png")

func run() -> void:
	stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3.0)
	stage.encounter.message_started = true
	stage.encounter.message_finished = true
	var puzzle = stage.puzzle
	puzzle.set_process(false)
	var p = stage.players[0]
	var q = stage.players[1]
	for actor in stage.players:
		actor.set_physics_process(false)
		actor.sprite.play(actor.equipped_weapon+"_idle")
		actor.sprite.pause()
		actor.update_sprite_alignment()
	for crate in stage.get_node("Breakables").get_children():
		crate.freeze = true
		crate.set_process(false)
	for tube in get_nodes_in_group("test_tubes"): tube.set_process(false)
	p.position = Vector2(2055,282)
	q.position = Vector2(2025,315)
	stage.get_node("Camera2D").position = Vector2(2080,180)
	stage.get_node("Environment").follow_camera(2080)
	await capture("01_crates_in_scenery")
	stage.spawn_index = 2
	stage._process(0)
	stage.encounter.dialogue._process(0.2)
	await capture("02_instructions")
	stage.encounter.clear()
	for crate in stage.get_node("Breakables").get_children():
		p.position = crate.position-Vector2(50,0)
		p.facing = 1
		for hit in 4:
			if not crate.broken: stage.strike(p,3,[])
		crate._process(0.5)
	await process_frame
	for debris in stage.get_node("Debris").get_children():
		debris._physics_process(1.0)
		debris.freeze = true
	for effect in stage.get_node("ImpactEffects").get_children(): effect.queue_free()
	p.position = puzzle.BUILD_POINT
	q.position = puzzle.BUILD_POINT+Vector2(-40,17)
	var ready_age := 0.0
	var completed_age := 0.0
	var captured_partial := false
	var captured_assembled := false
	var captured_lever := false
	var record := "--sequence" in OS.get_cmdline_user_args()
	if record: DirAccess.make_dir_recursive_absolute("res://.godot/generator_frames")
	for frame in 390:
		var dt := 1.0/30.0
		if frame >= 15 and not puzzle.constructed:
			stage.interact(p,dt)
		elif puzzle.constructed and not puzzle.activating and not puzzle.finished:
			ready_age += dt
			p.position = puzzle.BUILD_POINT.lerp(puzzle.LEVER_POINT,smoothstep(0.25,1.0,ready_age))
			q.position = p.position+Vector2(-40,17)
			if ready_age >= 1.2: puzzle.pull_lever(p)
		puzzle._process(dt)
		stage._process(dt)
		for actor in stage.players:
			var animation: String = "build" if puzzle.is_building(actor) else actor.equipped_weapon+"_idle"
			actor.sprite.animation = animation
			actor.sprite.frame = int(frame/2)%actor.sprite.sprite_frames.get_frame_count(animation)
			actor.update_sprite_alignment()
		if frame == 12: await capture("03_salvage_and_marker")
		if puzzle.snapped_parts >= 4 and not captured_partial:
			captured_partial = true
			await capture("04_single_point_build")
		if puzzle.constructed and not captured_assembled:
			captured_assembled = true
			await capture("05_ready_for_lever")
		if puzzle.activating and puzzle.startup_age >= 0.25 and not captured_lever:
			captured_lever = true
			await capture("06_lever_moving")
		if puzzle.finished:
			completed_age += dt
			if completed_age >= 1.5:
				await capture("07_running")
				break
		await process_frame
		await RenderingServer.frame_post_draw
		if record: root.get_texture().get_image().save_png("res://.godot/generator_frames/%04d.png" % frame)
	# An actor walking in front of the machine must render in front of its art.
	p.position = Vector2(2225,231)
	q.position = Vector2(2180,269)
	await capture("08_foreground_character")
	print("Captured authored crates, progressive single-point construction, lever pull, lights, gears and foreground layering.")
	quit()
