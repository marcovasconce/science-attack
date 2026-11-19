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
	stage.dialogue.set_process(false)
	stage.corridor.door.set_process(false)
	stage.elevator._physics_process(3)
	stage.beat = stage.Beat.CLEARED
	stage.open_limit = 3140
	stage.get_node("HUD/AdvanceArrow").hide()
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
		p.invulnerable = 1000
		p.sprite.play(p.equipped_weapon+"_idle")
		p.update_sprite_alignment()
	var p = stage.players[0]
	var q = stage.players[1]
	p.position = Vector2(2440,279)
	q.position = Vector2(2375,302)
	stage.get_node("Camera2D").position = Vector2(2470,180)
	await capture("side_door_closed")
	stage.puzzle_complete = true
	stage.corridor.door.unlock()
	stage.corridor.door._process(0.65)
	await capture("side_door_opening")
	stage.corridor.door._process(0.65)
	await capture("side_door_open")
	p.position = Vector2(2780,278)
	q.position = Vector2(2720,307)
	stage.get_node("Camera2D").position = Vector2(2880,180)
	for i in 540:
		await physics_frame
		stage.mixed_clock -= 1.0/60
		if stage.mixed_clock <= 0 and stage.mixed_spawned < stage.MIXED_ORDER.size():
			stage._spawn_mixed_enemy()
			stage.mixed_clock += 0.6
		for enemy in get_nodes_in_group("germs"):
			enemy.set_physics_process(false)
			enemy._physics_process(1.0/60)
		for shot in stage.get_node("Projectiles").get_children():
			shot.set_physics_process(false)
			shot._physics_process(1.0/60)
		if i == 330: await capture("mixed_encounter")
	await capture("slime_attack")
	for enemy in get_nodes_in_group("germs"): enemy.free()
	for shot in stage.get_node("Projectiles").get_children(): shot.free()
	p.position = Vector2(2875,285)
	q.position = Vector2(2800,315)
	p.jump_height = 0
	p.facing = 1
	var fly = stage.YellowScene.instantiate()
	fly.position = Vector2(2930,285)
	stage.get_node("Actors").add_child(fly)
	fly.set_physics_process(false)
	fly.cooldown = 20
	await capture("yellow_high")
	DirAccess.make_dir_recursive_absolute("res://.godot/yellow_flyer_frames")
	for frame in 120:
		await physics_frame
		if frame < 24:
			fly.age += 1.0/24
			fly._sync_visual()
		else:
			if frame == 24:
				p.jump_height = 34
				p.get_node("Visual").position.y = -34
				p.start_attack()
				stage.strike(p,1,[])
				await capture("yellow_air_hit")
			fly._physics_process(1.0/24)
			if frame == 29: await capture("yellow_falling")
			if frame == 36:
				p.jump_height = 0
				p.get_node("Visual").position.y = 0
				p.sprite.play("brush_idle")
			if frame == 42: await capture("yellow_grounded")
			if frame == 60: await capture("yellow_low")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/yellow_flyer_frames/%03d.png" % frame)
	quit()
