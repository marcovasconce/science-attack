extends SceneTree
var failures: Array[String] = []
var stage
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok: failures.append(text)
func run() -> void:
	set_meta("hive_chapter",true)
	stage = load("res://scenes/gameplay/hive_stage.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_process(false)
	stage.set_physics_process(false)
	var king = stage.king
	king.set_physics_process(false)
	for player in stage.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	for vent in stage.vents: vent.set_process(false)
	for gate in [stage.west_gate,stage.east_gate,stage.king_gate]+stage.sector_gates:
		check(not gate.visible and gate.get_node("Body").collision_layer == 0,"All old gates are invisible and noncolliding")
	check(stage.get_node("ProgressBarrier").get_child_count() == 1,"One active progression plane replaces old gates")
	var p = stage.players[0]
	for lane in [195.0,260.0,322.0]:
		p.position = Vector2(stage.open_limit-25,lane)
		await physics_frame
		p.move_and_collide(Vector2(150,0))
		check(p.position.x < stage.open_limit,"Invisible barrier blocks every lane")
	# The same physical plane follows the current sector instead of leaving hidden old doors.
	stage.bubble_puzzle.solved = true
	stage._tick_arsenal(1.0)
	stage._sync_progress_barrier()
	check(stage.progress_barrier.position.x == stage.WAVE_EAST+14,"Progression barrier moves after upgrade")
	p.position = Vector2(stage.west_gate.position.x-25,260)
	await physics_frame
	p.move_and_collide(Vector2(130,0))
	check(p.position.x > stage.west_gate.position.x,"Former door location no longer blocks movement")
	stage.open_limit = stage.room_right
	stage._sync_progress_barrier()
	check(stage.progress_barrier.collision_layer == 0,"Progress plane deactivates once final arena is open")
	# New impact origin affects only upgraded ground finisher and mirrors left.
	p.position = Vector2(6300,270)
	p.equip_weapon("brush")
	p.weapon_upgraded = true
	p.combo = 3
	p.airborne_attack = false
	p.facing = 1
	check(p.melee_origin() == p.position+Vector2(30,0),"Finisher impact moves 30 pixels forward")
	p.facing = -1
	check(p.melee_origin() == p.position-Vector2(30,0),"Finisher origin mirrors left")
	p.combo = 2
	check(p.melee_origin() == p.position,"Earlier combo strikes retain original origin")
	p.combo = 3
	p.airborne_attack = true
	check(p.melee_origin() == p.position,"Airborne strike keeps existing origin")
	p.airborne_attack = false
	p.facing = 1
	var targets: Array = []
	for distance in [205.0,-55.0,230.0]:
		var germ = stage.GermScene.instantiate()
		stage.get_node("Actors").add_child(germ)
		germ.position = p.position+Vector2(distance,0)
		germ.hp = 500
		germ.set_physics_process(false)
		targets.append(germ)
	stage.strike(p,3,[])
	check(targets[0].hp < 500 and targets[1].hp == 500 and targets[2].hp == 500,"Actual finisher damage shifts forward without extending behind")
	for target_actor in targets: target_actor.free()
	stage._begin_king()
	king.position = Vector2(6350,275)
	for actor in stage.players:
		actor.position = Vector2(6250,275)
		actor.hp = 100
		actor.invulnerable = 0
	king.state = king.State.WINDUP
	king.move = king.Move.CRASH
	king.clock = 0.6
	king._pose()
	check(king.sprite.frame == 3,"Ground-pound windup shows both raised arms")
	king.crash_at = Vector2(6250,275)
	king._attack()
	king._physics_process(0.1)
	check(p.hp == 100 and king.sprite.frame == 4,"Arms descend before contact damage")
	stage.players[1].jump_height = 40
	king._physics_process(0.05)
	check(p.hp == 81 and stage.players[1].hp == 100,"Ground-pound contact keeps jump escape and damage timing")
	check(king.sprite.frame == 5,"Ground contact uses two-fist slammed pose")
	var waves := 0
	for effect in stage.get_node("ImpactEffects").get_children():
		if effect.get_script() == preload("res://scripts/combat_ground_wave.gd"): waves += 1
	check(waves == 1,"One visible shockwave per ground contact")
	stage.controls_locked = true
	var saved_clock: float = king.clock
	king._physics_process(1)
	check(king.clock == saved_clock,"Combat animation pauses with controls")
	stage.controls_locked = false
	for move in [king.Move.BUBBLE,king.Move.VACUUM,king.Move.PRESSURE]:
		king.slam_age = 99
		king.state = king.State.WINDUP
		king.move = move
		king._pose()
		check(king.sprite.frame in [7,8,9],"Special attacks have distinct new poses")
	king.phase = 2
	king.hp = 1
	king.state = king.State.RECOVER
	king.take_hit(100,1)
	king._physics_process(0.8)
	check(king.dead and king.sprite.frame == 15 and stage.beat == stage.Beat.CAPTURE,"Defeat settles into horizontal lying sprite before antidote")
	check(not stage.victory and not stage.get_node("HUD/Finale").visible,"Defeat does not display early victory")
	p.position = stage.jar.position
	stage.players[1].down = true
	stage.players[1].hp = 0
	stage._seal_king(p)
	var finale = stage.finale
	stage._animate_seal(0.25)
	check(stage.controls_locked and not stage.clean_sample and p.sprite.animation == &"antidote_throw","Antidote is consumed once and throw animation starts")
	check(finale.bottle.global_position.y < finale.start.y,"Antidote travels in an arc")
	stage._animate_seal(1.10)
	check(finale.overlay.coverage == 1 and finale.cleaned,"Full-screen foam covers the palette change")
	check(not stage.victory and not stage.king.visible,"King is neutralized under foam, victory still withheld")
	stage._animate_seal(0.99)
	check(finale.overlay.coverage == 1,"Screen remains fully covered for one second")
	stage._animate_seal(0.25)
	check(finale.overlay.coverage > 0 and finale.overlay.coverage < 1,"Foam reveals scene after full second")
	check(stage.get_node("Scenery/Floor/Stone0_0").material == finale.clean_material,"Blue clean palette affects actual scenery")
	check(stage.players[0].sprite.material != finale.clean_material,"Player palette remains unchanged")
	stage._animate_seal(0.75)
	check(stage.players[0].position.distance_to(stage.players[1].position) < 200,"Both players approach one another")
	check(not stage.players[1].down and stage.players[1].hp > 0,"A downed partner joins the victory celebration")
	stage._animate_seal(1.2)
	check(finale.high_five != null and finale.high_five.contact_played,"High-five reaches hand contact with sparkle cue")
	check(not stage.victory and not stage.get_node("HUD/Finale").visible,"Victory waits for high-five to finish")
	stage._animate_seal(1.5)
	check(stage.victory and stage.beat == stage.Beat.END and stage.get_node("HUD/Finale").visible,"Victory appears after the complete celebration")
	check(not finale.overlay.visible and stage.get_node("Actors/Tiburcio").visible,"Final scene is clean and Tiburcio is rescued")
	stage._animate_seal(100)
	check(finale.complete and finale.high_five != null,"Final sequence is idempotent")
	if failures.is_empty(): print("PASS: single invisible barrier; forward mirrored finisher; king windup/contact/new poses/defeat; antidote arc; exact one-second foam cover; blue scenery; both heroes high-five before victory")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

