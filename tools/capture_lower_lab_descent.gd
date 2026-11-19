extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.route.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	var lift = stage.route.get_node("ExitElevator")
	lift.set_physics_process(false)
	lift.next_scene_path = ""
	lift.available = true
	for player in stage.players:
		player.set_physics_process(false)
		player.position = lift.pads[player.player_id].global_position
		player.sprite.play(player.equipped_weapon+"_idle")
	stage.get_node("Camera2D").position = Vector2(lift.position.x,180)
	lift._start_ascent()
	lift._advance_ascent(1.1)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/lower_lab_elevator_descending.png")
	quit()
