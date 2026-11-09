extends SceneTree
var arena: Node2D
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	if not arena.elevator.is_transitioning():
		arena.encounter._process(0)
		arena.get_node("HUD/Goal").text = arena.encounter.objective_text()
	for player in arena.players: player.get_node("PlayerMarker").text = "P%d" % (player.player_id+1)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+name+".png")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	var lift = arena.elevator
	lift.next_scene_path = ""
	lift.set_physics_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	arena.built = true
	arena.encounter.unlock_route()
	arena.encounter.arrived = true
	for player in arena.players:
		player.set_physics_process(false)
		player.ai_controlled = false
		player.equip_weapon("brush" if player.player_id==0 else "bubbles")
		player.position = Vector2(2240+player.player_id*50,300)
	for crate in arena.get_node("Breakables").get_children(): crate.freeze = true
	lift._physics_process(0)
	arena.encounter._process(0)
	arena._process(0)
	arena.get_node("Camera2D").position.x = 2490
	await capture("elevator_route")
	arena.players[0].position = lift.pads[0].global_position
	lift._physics_process(0.1)
	arena.encounter._process(0)
	arena.get_node("Camera2D").position.x = 2550
	await capture("elevator_one_ready")
	arena.players[1].position = lift.pads[1].global_position
	lift._physics_process(0.1)
	await capture("elevator_both_ready")
	lift._physics_process(0.31)
	lift._physics_process(0.8)
	await capture("elevator_ascending")
	lift._physics_process(2)
	await capture("elevator_loading")
	lift._physics_process(0.7)
	await capture("elevator_next_phase")
	var sprite_image: Image = load("res://assets/environment/cooperative_elevator.png").get_image()
	print("Elevator PNG: ",sprite_image.get_size()," alpha bounds: ",sprite_image.get_used_rect())
	print("Captured route, one/two plates, ascent, loading and next-stage handoff.")
	quit()
