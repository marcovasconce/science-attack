extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/lower_lab_"+label+".png")
func freeze_effects(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): freeze_effects(child)
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.king.set_process(false)
	stage.dialogue.set_process(false)
	stage.elevator._physics_process(3)
	stage.king.hide()
	stage.beat = stage.Beat.CLEARED
	stage.open_limit = 3140
	stage.controls_locked = false
	stage._update_objective()
	for player in stage.players:
		player.set_physics_process(false)
		player.sprite.play(player.equipped_weapon+"_idle")
		player.update_sprite_alignment()
	for puddle in stage.corridor.puddles: puddle.set_physics_process(false)
	stage.players[0].position = Vector2(1230,293)
	stage.players[1].position = Vector2(1165,320)
	stage.get_node("Camera2D").position = Vector2(1360,180)
	for i in 35: await process_frame
	await capture("damaged_corridor")
	stage.players[0].position = Vector2(2440,279)
	stage.players[1].position = Vector2(2375,302)
	stage.get_node("Camera2D").position = Vector2(2470,180)
	stage._update_terminal_prompt()
	await capture("locked_door")
	stage._open_terminal(0)
	stage._process(0.3)
	await capture("terminal_zoom")
	stage._process(0.31)
	stage.puzzle.set_process(false)
	stage.puzzle._process(0.7)
	await capture("system_boot")
	stage.puzzle._process(0.8)
	await capture("tiburcio_puzzle")
	stage.puzzle.select_tile(0)
	await capture("puzzle_selected")
	stage.puzzle.select_tile(0)
	for slot in 9:
		if stage.puzzle.tiles[slot] == slot: continue
		var other: int = stage.puzzle.tiles.find(slot)
		stage.puzzle.select_tile(slot)
		stage.puzzle.select_tile(other)
	await capture("puzzle_solved")
	stage.puzzle._process(1.01)
	stage._process(0.51)
	stage.corridor.door.set_process(false)
	stage.corridor.door._process(1.3)
	stage.players[0].position = Vector2(2680,295)
	stage.players[1].position = Vector2(2600,315)
	await capture("door_open")
	if "--sequence" in OS.get_cmdline_user_args():
		stage.players[0].position = Vector2(1230,293)
		stage.players[1].position = Vector2(1165,320)
		stage.get_node("Camera2D").position = Vector2(1360,180)
		DirAccess.make_dir_recursive_absolute("res://.godot/corridor_frames")
		freeze_effects(stage.corridor)
		for frame in 48:
			for effect in stage.corridor.get_children():
				if effect.get_script() == stage.corridor.Effect: effect._process(1.0/24)
			for puddle in stage.corridor.puddles:
				puddle._physics_process(1.0/24)
				puddle.get_child(1)._process(1.0/24)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/corridor_frames/%03d.png" % frame)
	quit()
