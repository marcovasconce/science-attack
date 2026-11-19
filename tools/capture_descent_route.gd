extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+label+".png")
func freeze() -> void:
	stage.set_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
		p.sprite.play(p.equipped_weapon+"_idle")
		p.update_sprite_alignment()
func change_stage(path: String) -> void:
	set_meta("party_state",preload("res://scripts/party_transfer.gd").capture(stage))
	change_scene_to_file(path)
	for i in 3: await process_frame
	stage = current_scene
	freeze()
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	freeze()
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.finale.set_process(false)
	stage.exit_lift.set_physics_process(false)
	stage.journey_radio.set_process(false)
	stage.beat = stage.Beat.FINISHED
	stage.players[0].position = Vector2(3310,270)
	stage.players[1].position = Vector2(3250,305)
	stage.get_node("Camera2D").position.x = 3260
	stage.finale._process(0.1)
	await capture("journey_slime_search")
	stage.players[0].position = stage.finale.locker_at+Vector2(0,52)
	stage.get_node("Camera2D").position.x = stage.finale.locker_at.x+100
	stage.finale._process(0.1)
	await capture("journey_soap_locker")
	stage.finale.interact(stage.players[0])
	stage.players[0].position = Vector2(3310,270)
	stage.finale.interact(stage.players[0])
	stage.finale._process(3.1)
	stage.finale.state = stage.finale.State.DONE
	stage.get_node("Camera2D").position.x = 5310
	stage.players[0].position = stage.exit_lift.repair_point()
	stage.players[1].position = stage.players[0].position+Vector2(-60,20)
	stage.pieces = 12
	stage.exit_lift._physics_process(0.1)
	await capture("journey_broken_elevator")
	stage.exit_lift.repair_progress = 1.5
	stage.exit_lift.repair_grace = 1
	stage.exit_lift._physics_process(0.1)
	await capture("journey_repair_elevator")
	await change_stage("res://scenes/gameplay/shaft_descent.tscn")
	stage._process(1.2)
	stage.elapsed = 8
	stage.spawn_clock = 1
	stage._spawn_attacker()
	stage._spawn_attacker()
	stage._spawn_attacker()
	stage._spawn_attacker()
	for enemy in get_nodes_in_group("germs"):
		enemy.set_physics_process(false)
		if enemy.has_method("requires_air_attack"): enemy.position.x -= 65
		else:
			enemy.entry_height = 0
			enemy.get_node("Body").position = enemy.body_origin
			enemy.position.x += 40
	stage._process(0.01)
	await capture("journey_shaft_battle")
	DirAccess.make_dir_recursive_absolute("res://.godot/descent_preview_frames")
	for i in (0 if "--stills-only" in OS.get_cmdline_user_args() else 120):
		stage._process(1.0/30)
		for enemy in get_nodes_in_group("germs"):
			if enemy.has_method("requires_air_attack"):
				enemy.age += 1.0/30
				enemy._sync_visual()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/descent_preview_frames/%03d.png" % i)
	await change_stage("res://scenes/gameplay/hive_stage.tscn")
	stage.arrival_lift._physics_process(2.5)
	stage._process(1.3)
	await capture("journey_hive_arrival")
	stage.players[0].position = Vector2(1050,285)
	stage.players[1].position = Vector2(990,305)
	stage.get_node("Camera2D").position.x = 960
	await capture("journey_hive_entrance")
	print("PASS: rendered soap search, damaged lift, repair, moving shaft and hive entrance")
	quit()
