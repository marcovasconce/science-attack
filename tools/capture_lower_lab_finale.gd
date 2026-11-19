extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/lower_lab_"+label+".png")
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.king.set_process(false)
	stage.finale.set_process(false)
	stage.elevator._physics_process(3)
	for player in stage.players:
		player.set_physics_process(false)
		player.sprite.play(player.equipped_weapon+"_idle")
		player.update_sprite_alignment()
	await capture("shaft_rails")
	stage.players[0].position = Vector2(2790,280)
	stage.players[1].position = Vector2(2720,310)
	stage.get_node("Camera2D").position = Vector2(2820,180)
	stage.amanda_hint.announce()
	await capture("amanda_flying_hint")
	stage.amanda_hint.remaining = 0
	stage.amanda_hint.hide()
	stage.beat = stage.Beat.FINISHED
	stage.finale._process(0.01)
	stage.players[0].position = Vector2(3310,270)
	stage.finale._process(0.01)
	stage.players[0].position = stage.finale.locker_at+Vector2(0,52)
	stage.players[1].position = Vector2(3130,295)
	stage.get_node("Camera2D").position = Vector2(3290,180)
	stage.finale._process(0.01)
	await capture("soap_locker")
	stage.finale.interact(stage.players[0])
	stage.players[0].position = Vector2(3300,275)
	stage.players[1].position = Vector2(3235,315)
	stage.finale.interact(stage.players[0])
	stage.finale._process(1.35)
	await capture("soap_foam")
	if "--sequence" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.godot/cleaning_frames")
		stage.finale.age = 0
		for frame in 90:
			stage.finale._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/cleaning_frames/%03d.png" % frame)
	stage.finale._process(1.7)
	await capture("slime_cleaned")
	stage.finale.begin_boss()
	stage.finale.boss.set_physics_process(false)
	stage.get_node("Camera2D").position = Vector2(stage.finale.CENTER,180)
	stage.get_node("Camera2D").zoom = Vector2.ONE*stage.finale.CAMERA_ZOOM
	stage.get_node("Camera2D").offset = Vector2.ZERO
	stage.finale._process(1.2)
	await capture("boss_intro")
	stage.finale.start_fight()
	stage.finale.boss._physics_process(0.3)
	await capture("boss_windup")
	stage.finale.boss._physics_process(0.8)
	stage.finale.boss._physics_process(0.4)
	await capture("boss_charge")
	stage.finale.boss._physics_process(1)
	for tnt in get_nodes_in_group("boss_tnt"):
		tnt.set_physics_process(false)
		tnt._physics_process(0.65)
	await capture("boss_tnt")
	stage.finale.boss.take_explosion(680)
	stage.finale.boss._physics_process(0.15)
	await capture("boss_red_health")
	if "--sequence" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.godot/finale_frames")
		for tnt in get_nodes_in_group("boss_tnt"): tnt.free()
		stage.finale.boss.hp = 1300
		stage.finale.boss.position = Vector2(stage.finale.RIGHT-100,280)
		stage.finale.boss.wind_up()
		stage.players[0].position = Vector2(4160,316)
		stage.players[1].position = Vector2(4100,212)
		for frame in 180:
			stage.finale.boss._physics_process(1.0/30)
			stage.update_camera_shake(1.0/30)
			for tnt in get_nodes_in_group("boss_tnt"):
				tnt.set_physics_process(false)
				tnt._physics_process(1.0/30)
			stage.finale._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/finale_frames/%03d.png" % frame)
	quit()
