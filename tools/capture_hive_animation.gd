extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	preload("res://scripts/chapter_catalog.gd").open(self,30)
	for i in 4: await process_frame
	var hive = current_scene
	hive.set_process(false)
	hive.set_physics_process(false)
	hive.get_node("Camera2D").position.x = 1065
	hive.players[0].position = Vector2(930,302)
	hive.players[1].position = Vector2(878,320)
	for player in hive.players: player.set_physics_process(false)
	for vent in hive.vents: vent.set_process(false)
	var first = hive.vents[0]
	first.state = first.State.REST
	first.age = 2.5
	DirAccess.make_dir_recursive_absolute("res://.godot/hive_frames")
	for i in 110:
		first.advance(0.04)
		first.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/hive_frames/%03d.png" % i)
	print("PASS: native hive animation captured")
	quit()
