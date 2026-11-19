extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/lower_lab_" + label + ".png")
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.king.set_process(false)
	stage.dialogue.set_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.sprite.play(p.equipped_weapon + "_idle")
		p.update_sprite_alignment()
	stage.elevator._physics_process(3)
	stage._process(0)
	await capture("arrival")
	stage.players[0].position = Vector2(328,320)
	stage.players[1].position = Vector2(302,326)
	await capture("elevator_foreground_fixed")
	stage.players[0].position = Vector2(550,280)
	stage.players[1].position = Vector2(490,307)
	stage._process(0.1)
	stage._process(0.9)
	stage.dialogue._process(4)
	stage.king.age = 0
	stage.king._process(0)
	await capture("abduction")
	stage.king._process(2.0 / stage.king.FPS)
	await capture("king_talking")
	if "--sequence" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.godot/king_captive_frames")
		for frame in 72:
			stage.king._process(1.0/24)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/king_captive_frames/%03d.png" % frame)
	stage.dialogue.advance()
	for i in 120:
		stage._process(1.0/60)
		if stage.beat == stage.Beat.WARNING: break
	await capture("warning")
	stage._process(1.0)
	for p in stage.players: p.invulnerable = 1000
	for i in 720:
		stage._process(1.0/60)
		for enemy in get_nodes_in_group("germs"):
			enemy.set_physics_process(false)
			enemy._physics_process(1.0/60)
		await process_frame
		if i == 210: await capture("wave")
		if stage.beat == stage.Beat.WARNING:
			await capture("second_warning")
			break
	stage._process(1.0)
	for i in 210:
		stage._process(1.0/60)
		for enemy in get_nodes_in_group("germs"):
			enemy.set_physics_process(false)
			enemy._physics_process(1.0/60)
		await process_frame
	await capture("second_wave")
	quit()
