extends SceneTree
var stage: Node2D
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+name+".png")

func motion_frame(index: int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/tabletop_frames/%03d.png" % index)
func run() -> void:
	stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.sprite.pause()
	for tube in get_nodes_in_group("test_tubes"): tube.set_process(false)
	stage.elevator.age = 0
	stage.elevator._physics_process(0.85)
	stage._process(0)
	await capture("tabletop_arrival_closed")
	stage.elevator._physics_process(0.85)
	await capture("tabletop_doors_opening")
	stage.elevator._physics_process(0.8)
	await process_frame
	stage._process(0)
	await capture("tabletop_arrival_open")
	await capture("tabletop_liquid_0")
	for tube in get_nodes_in_group("test_tubes"): tube._process(1.0)
	await capture("tabletop_liquid_1")
	stage.players[0].position.y = 318
	stage._process(0.31)
	stage.encounter.dialogue._process(0.2)
	await capture("tabletop_tiburcio_message")
	stage.encounter.clear()
	stage.players[0].position = Vector2(820,285)
	stage.players[1].position = Vector2(760,310)
	stage._process(0)
	for germ in get_nodes_in_group("germs"): germ.set_physics_process(false)
	await capture("tabletop_pen_and_germs")
	stage.players[0].position = Vector2(1290,305)
	stage.players[1].position = Vector2(1230,310)
	stage._process(0)
	await capture("tabletop_pencil_and_tubes")
	# Reproducible animation preview from actual engine frames, not edited art.
	DirAccess.make_dir_recursive_absolute("res://.godot/tabletop_frames")
	stage.players[0].position = Vector2(149,284)
	stage.players[1].position = Vector2(251,284)
	stage.encounter.message_started = false
	stage.encounter.message_finished = false
	stage.encounter.seen.erase("arrival")
	stage.encounter.gap = 0
	stage.controls_locked = true
	stage.elevator.age = 0.8
	stage.elevator.arrived = false
	stage.elevator.doors.show()
	stage.elevator.get_node("Hint").hide()
	stage._process(0)
	for index in 30:
		stage.elevator._physics_process(0.06)
		for tube in get_nodes_in_group("test_tubes"): tube._process(0.06)
		stage._process(0)
		await motion_frame(index)
	stage.players[0].position.y = 318
	stage._process(0.31)
	stage.encounter.dialogue._process(0.2)
	for index in range(30,45): await motion_frame(index)
	stage.encounter.clear()
	stage.players[0].position = Vector2(1290,305)
	stage.players[1].position = Vector2(1230,310)
	stage._process(0)
	for index in range(45,75):
		for tube in get_nodes_in_group("test_tubes"): tube._process(0.06)
		await motion_frame(index)
	print("Captured real second-stage arrival, opening doors, liquid animation, exact radio line and tabletop exploration.")
	quit()
