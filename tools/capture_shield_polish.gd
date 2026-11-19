extends SceneTree
var stage
var boss
var sequence := 0
func _initialize() -> void: call_deferred("run")
func capture(label := "") -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	frame.save_png("res://.godot/shield_polish_frames/%03d.png" % sequence)
	if not label.is_empty(): frame.save_png("res://art/previews/shield_polish_"+label+".png")
	sequence += 1
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	var finale = stage.finale
	finale.set_process(false)
	stage.beat = stage.Beat.FINISHED
	finale.cleaned = true
	finale.state = finale.State.OPEN
	for player in stage.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	finale.begin_boss()
	boss = finale.boss
	boss.set_physics_process(false)
	finale._process(1.2)
	finale.boss_hud.intro = false
	stage.get_node("Camera2D").position = Vector2(finale.CENTER,180)
	stage.get_node("Camera2D").zoom = Vector2.ONE*finale.CAMERA_ZOOM
	stage.get_node("Camera2D").offset = Vector2.ZERO
	boss.position = Vector2(finale.CENTER+80,280)
	var p = stage.players[0]
	p.position = boss.position-Vector2(160,0)
	stage.players[1].position = Vector2(finale.CENTER-120,315)
	DirAccess.make_dir_recursive_absolute("res://.godot/shield_polish_frames")
	for i in 24:
		boss._physics_process(1.0/30)
		await capture("idle" if i == 12 else "")
	finale.start_fight()
	boss.state = boss.State.RECOVER
	boss.age = 0
	p.position = boss.position-Vector2(60,0)
	var captured_bash := false
	for i in 84:
		boss._physics_process(1.0/30)
		p._physics_process(1.0/30)
		var label := ""
		if boss.state == boss.State.SHIELD_BASH and boss.sprite.frame == 10 and not captured_bash:
			captured_bash = true
			label = "bash"
		await capture(label)
	assert(captured_bash,"Real proximity must trigger the visible shield bash")
	boss._apply_damage(boss.MAX_HP)
	for i in 96:
		if is_instance_valid(boss): boss._physics_process(1.0/30)
		await capture("defeat" if i == 19 else ("blink" if i == 25 else ""))
	print("PASS: captured idle, proximity-triggered shield push, four collapse poses and disappearance; ",sequence," frames")
	quit()
