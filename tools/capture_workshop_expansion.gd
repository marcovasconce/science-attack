extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	set_meta("hive_chapter",true)
	change_scene_to_file("res://scenes/gameplay/hive_stage.tscn")
	for i in 6: await process_frame
	stage = current_scene
	stage.set_process(false)
	stage.set_physics_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
	for vent in stage.vents: vent.set_process(false)
	var camera = stage.get_node("Camera2D")
	camera.zoom = Vector2.ONE*stage.EXPLORE_ZOOM
	camera.position.x = stage.bubble_puzzle.position.x-10
	stage.players[0].position = stage.bubble_puzzle.position+Vector2(-80,14)
	stage.players[1].position = stage.bubble_puzzle.position+Vector2(55,27)
	stage._process(0.001)
	camera.position.x = stage.bubble_puzzle.position.x-10
	await capture("oficina_ampliada")
	stage.workshop_radio.hide()
	stage.bubble_puzzle.solved = true
	stage._tick_arsenal(1)
	for p in stage.players:
		p.specials.cancel()
		p.sprite.play(p.equipped_weapon+"_idle")
		p.update_sprite_alignment()
	await capture("oficina_maquinas")
	camera.position.x = 1530
	stage.players[0].position = Vector2(1445,280)
	stage.players[1].position = Vector2(1530,285)
	stage.players[0].facing = 1
	stage.players[0].energy = 50
	stage.players[0].specials.try_activate()
	stage.players[0].specials.tick(0.3)
	stage.players[0].sprite.play("brush_spin")
	stage.players[0].update_sprite_alignment()
	await capture("escova_giro_laranja")
	stage.players[0].specials.cancel()
	stage.players[0].energy = 100
	stage.players[0].specials.try_activate()
	stage.players[0].specials.tick(0.79)
	stage.players[0].sprite.play("brush_ultimate")
	stage.players[0].update_sprite_alignment()
	await capture("escova_tnt_bolhas")
	stage.players[0].specials.cancel()
	stage.players[1].energy = 50
	stage.players[1].facing = 1
	stage.players[1].specials.try_activate()
	stage.players[1].specials.tick(0.32)
	stage.players[1].sprite.play("bubbles_ultimate")
	stage.players[1].update_sprite_alignment()
	await capture("arma_jato_rapido")
	stage.players[1].specials.cancel()
	stage.open_limit = stage.room_right
	stage.players[0].position = Vector2(stage.KING_WEST+100,260)
	stage.players[1].position = Vector2(stage.KING_WEST+150,300)
	stage._begin_king()
	stage.king.set_physics_process(false)
	stage._update_camera(1)
	await capture("colmeia_arena_ampliada")
	print("PASS: workshop, orange spin, TNT bubbles, quick beam and expanded king arena captured")
	quit()

