extends SceneTree
var stage
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+label+".png")
func freeze_effects() -> void:
	for effect in stage.get_node("ImpactEffects").get_children(): effect.set_process(false)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	set_meta("hive_chapter",true)
	change_scene_to_file("res://scenes/gameplay/hive_stage.tscn")
	for i in 6: await process_frame
	stage = current_scene
	stage.set_process(false)
	stage.set_physics_process(false)
	stage.king.set_physics_process(false)
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
	for vent in stage.vents: vent.set_process(false)
	var camera: Camera2D = stage.get_node("Camera2D")
	camera.zoom = Vector2.ONE*0.86
	camera.position.x = stage.west_gate.position.x-190
	stage.workshop_radio.hide()
	stage.players[0].position = Vector2(stage.west_gate.position.x-70,280)
	stage.players[1].position = Vector2(stage.west_gate.position.x-150,310)
	await capture("barreira_invisivel")
	stage.open_limit = stage.room_right
	stage.arsenal_claimed = true
	for p in stage.players: p.weapon_upgraded = true
	stage._begin_king()
	var middle: float = (stage.KING_WEST+stage.room_right)*0.5
	camera.position.x = middle
	camera.zoom = Vector2.ONE*0.86
	stage.king.position = Vector2(middle+65,284)
	stage.players[0].position = Vector2(middle-130,284)
	stage.players[1].position = Vector2(middle-200,305)
	stage.king.state = stage.king.State.WINDUP
	stage.king.move = stage.king.Move.CRASH
	stage.king.clock = 0.55
	stage.king._pose()
	await capture("rei_dois_bracos")
	stage.king.crash_at = stage.king.position
	stage.king._attack()
	stage.king._physics_process(0.15)
	freeze_effects()
	for effect in stage.get_node("ImpactEffects").get_children():
		if effect.get_script() == preload("res://scripts/combat_ground_wave.gd"):
			effect.age = 0.23
			effect.queue_redraw()
	await capture("rei_onda_choque")
	for effect in stage.get_node("ImpactEffects").get_children(): effect.queue_free()
	stage.players[0].facing = 1
	stage.players[0].combo = 3
	stage.players[0].attack_duration = 0.6068
	stage.players[0].attack_time = 0.32
	stage.players[0].finisher_pending = true
	stage.players[0]._physics_process(0.03)
	freeze_effects()
	for effect in stage.get_node("ImpactEffects").get_children():
		if effect.get_script() == preload("res://scripts/combat_ground_wave.gd"):
			effect.age = 0.16
			effect.queue_redraw()
	await capture("escova_impacto_frente")
	stage.king.phase = 2
	stage.king.hp = 1
	stage.king.state = stage.king.State.RECOVER
	stage.king.take_hit(100,1)
	stage.king._physics_process(0.8)
	await capture("rei_derrotado")
	stage.players[0].position = stage.jar.position+Vector2(-35,4)
	stage._seal_king(stage.players[0])
	stage._animate_seal(0.25)
	await capture("antidoto_arremesso")
	stage._animate_seal(1.25)
	await capture("final_bolhas")
	stage._animate_seal(1.35)
	await capture("esgoto_limpo")
	stage._animate_seal(1.75)
	await capture("toca_aqui_brilho")
	stage._animate_seal(1.5)
	await capture("vitoria_limpeza")
	print("PASS: invisible gate, king slam, forward finisher, defeat, antidote, foam, blue sewer and high five captured")
	quit()

