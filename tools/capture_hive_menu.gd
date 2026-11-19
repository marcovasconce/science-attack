extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 4: await process_frame
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+label+".png")
func run() -> void:
	change_scene_to_file("res://scenes/main_menu.tscn")
	await settle()
	await capture("hive_menu")
	current_scene.show_chapters()
	await capture("hive_chapters")
	preload("res://scripts/chapter_catalog.gd").open(self,30)
	await settle()
	stage = current_scene
	stage.set_process(false)
	stage.set_physics_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.sprite.play(p.equipped_weapon+"_idle")
		p.update_sprite_alignment()
	stage.get_node("Camera2D").position.x = 880
	stage.players[0].position = Vector2(688,293)
	stage.players[1].position = Vector2(636,315)
	for vent in stage.vents: vent.set_process(false)
	stage.vents[0].state = stage.vents[0].State.WARNING
	stage.vents[0].age = 0.4
	stage.vents[0].queue_redraw()
	await capture("hive_drain_warning")
	stage.get_node("Camera2D").position.x = 1070
	stage.players[0].position = Vector2(923,298)
	stage.players[1].position = Vector2(874,320)
	stage.vents[0].state = stage.vents[0].State.ERUPTING
	stage.vents[0].age = 0.6
	stage.vents[0].queue_redraw()
	await capture("hive_geyser")
	preload("res://scripts/chapter_catalog.gd").open(self,25)
	await settle()
	stage = current_scene
	stage.set_process(false)
	stage.exit_lift.set_physics_process(false)
	stage.pieces = 8
	stage.players[0].position = stage.exit_lift.repair_point()
	stage.exit_lift.repair(stage.players[0],3.3)
	for i in 2:
		stage.players[i].set_physics_process(false)
		stage.players[i].position = stage.exit_lift.pads[i].global_position
	stage.get_node("Camera2D").position.x = 5350
	stage.exit_lift._start_ascent()
	stage.exit_lift._advance_ascent(1.7)
	await capture("hive_lift_rails")
	print("PASS: menu, chapters, hive hazards and descending lift captured")
	quit()
