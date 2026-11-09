extends SceneTree
var arena: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	for player in arena.players:
		player.set_physics_process(false)
		player.sprite.play("idle")
	for crate in arena.get_node("Breakables").get_children(): crate.freeze = true
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.tutorial.age = 5
	arena.controls_locked = false
	arena.built = true
	arena.victory = true
	arena.get_node("Bridge").show()
	arena.get_node("BuildSite").set_process(false)
	arena.get_node("BuildSite").sample(1)
	arena.get_node("Gate/Collision").set_deferred("disabled",true)
	arena.players[0].position = Vector2(1100,260)
	arena.players[1].position = Vector2(1070,300)
	arena.encounter._process(0)
	arena._process(0)
	arena.tutorial._process(0)
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	await capture("advance_right")
	arena.players[0].position = Vector2(1460,266)
	arena.players[1].position = Vector2(1410,304)
	arena.encounter._process(0)
	arena._process(0)
	arena.get_node("Camera2D").position.x = 1600
	await capture("supply_outpost")
	arena.encounter.try_interact(arena.players[0])
	arena.encounter.dialogue._process(10)
	await capture("tiburcio_dialogue")
	arena.encounter.dialogue.advance()
	arena.players[0].position = Vector2(1700,305)
	arena.players[1].position = Vector2(1650,320)
	arena.encounter._process(0)
	arena._process(0)
	arena.get_node("Camera2D").position.x = 1600
	await capture("spider_interaction")
	arena.encounter.try_interact(arena.players[0])
	await capture("equipment_panel")
	arena.encounter.close_equipment()
	arena.players[1].ai_controlled = false
	arena.players[1].position = Vector2(1700,305)
	arena.players[0].position = Vector2(1630,305)
	arena.get_node("HUD/TeamHUD")._process(0)
	arena.encounter._process(0)
	await capture("outpost_coop")
	print("Captured right arrow, supply area, Tibúrcio's speech, four-legged robot, equipment panel and co-op.")
	quit()
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+name+".png")
