extends SceneTree
var stage
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func yellow(at: Vector2):
	var enemy = stage.YellowScene.instantiate()
	enemy.position = at
	stage.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	return enemy
func clear_shots() -> void:
	for shot in stage.get_node("Projectiles").get_children(): shot.free()
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.king.set_process(false)
	stage.dialogue.set_process(false)
	stage.corridor.door.set_process(false)
	for p in stage.players: p.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.beat = stage.Beat.CLEARED
	stage.open_limit = 3140
	stage.get_node("Camera2D").position = Vector2(2790,180)
	var p = stage.players[0]
	var q = stage.players[1]
	p.position = Vector2(2800,280)
	q.position = Vector2(2770,310)
	q.ai_controlled = false
	var door = stage.corridor.door
	check(door.SIZE.x <= 32 and door.collision.shape.size.x <= 20,"Door is a narrow side-profile barrier visually and physically")
	stage._start_mixed_encounter()
	check(not stage.mixed_started,"Encounter cannot start before the puzzle is solved")
	stage.puzzle_complete = true
	door.unlock()
	door._process(0.7)
	check(not stage.mixed_started and not door.collision.disabled,"Enemies wait until the door is open")
	door._process(0.6)
	check(stage.mixed_started and stage.beat == stage.Beat.MIXED and not stage.victory,"Opening the door starts the mixed encounter exactly then")
	stage._process(7.3)
	var counts := {"green":0,"red":0,"yellow":0}
	for enemy in get_nodes_in_group("germs"):
		enemy.set_physics_process(false)
		if enemy.has_method("requires_air_attack"): counts.yellow += 1
		else: counts[enemy.variant] += 1
	check(counts == {"green":6,"red":3,"yellow":3},"Post-door group contains six normal, three red and three yellow flying bacteria")
	check(stage.spawned == 0 and stage.mixed_spawned == 12,"Mixed encounter counters do not change the two initial swarms")
	door._process(4)
	stage._start_mixed_encounter()
	stage._process(0.1)
	check(stage.mixed_spawned == 12 and get_nodes_in_group("germs").size() == 12,"Repeated door updates cannot duplicate the group")
	for enemy in get_nodes_in_group("germs"): enemy.free()
	var fly = yellow(Vector2(2850,280))
	check(fly.hp == 195 and fly.hp > 130 and fly.hp < 260,"Yellow health lies strictly between normal green and red")
	check(fly.requires_air_attack() and not fly.can_be_hit(28) and fly.can_be_hit(60),"High flyers require a jumping attack height")
	p.facing = 1
	p.jump_height = 0
	var combo_before: int = p.hit_combo
	var targets: Array = []
	stage.strike(p,1,targets)
	check(fly.hp == 195 and p.hit_combo == combo_before and not targets.has(fly),"Ground melee misses high flyers without false combo credit or consuming the target")
	stage.special_area(p,p.position,150,60,100)
	stage.water_beam_damage(p,1,300,40)
	check(fly.hp == 195,"Ground area specials and water beam also obey altitude")
	p.equip_weapon("bubbles")
	var shot = stage.spawn_bubble(p)
	shot.set_physics_process(false)
	p.jump_height = 35
	shot._physics_process(0.3)
	check(fly.hp == 195 and not shot.popping,"A ground-fired bubble passes under a flyer even if the shooter jumps afterward")
	clear_shots()
	shot = stage.spawn_bubble(p)
	shot.set_physics_process(false)
	p.jump_height = 0
	shot._physics_process(0.3)
	check(fly.hp == 185 and fly.flight == fly.Flight.FALLING,"A jumping bubble hits even after its shooter lands and knocks the flyer down")
	check(shot.popping,"The airborne bubble pops on real contact")
	clear_shots()
	var height_before: float = fly.flight_height
	fly._physics_process(0.12)
	check(fly.flight_height < height_before and fly.sprite.rotation != 0,"Hit reaction visibly descends and tumbles")
	for i in 60:
		fly._physics_process(1.0/60)
		if fly.flight == fly.Flight.GROUNDED: break
	check(fly.flight == fly.Flight.GROUNDED and fly.flight_height == 13 and fly.sprite.scale.y < 1,"Fall ends on the floor with a squash / impact pose")
	fly._physics_process(0.36)
	check(fly.flight == fly.Flight.LOW and fly.low_remaining == 10,"After landing, the low-flight interval starts at ten seconds")
	fly._physics_process(0.3)
	check(not fly.requires_air_attack() and fly.can_be_hit(28),"Low flight is reachable without jumping")
	p.equip_weapon("brush")
	p.position = fly.position-Vector2(50,0)
	p.jump_height = 0
	p.facing = 1
	var hp_before: int = fly.hp
	var low_before: float = fly.low_remaining
	stage.strike(p,1,[])
	check(fly.hp < hp_before and fly.flight == fly.Flight.LOW and fly.low_remaining == low_before,"Ground attacks hurt low flyers without refreshing the ten-second timer")
	stage.controls_locked = true
	height_before = fly.flight_height
	fly._physics_process(5)
	check(fly.low_remaining == low_before and fly.flight_height == height_before,"Pausing freezes the low-flight timer and height")
	stage.controls_locked = false
	fly._physics_process(low_before-0.01)
	check(fly.flight == fly.Flight.LOW and fly.low_remaining > 0,"Flyer remains low until the full interval expires")
	fly._physics_process(0.02)
	check(fly.flight == fly.Flight.RISING,"After ten seconds, it begins ascending again")
	fly._physics_process(0.66)
	check(fly.flight == fly.Flight.HIGH and not fly.can_be_hit(28),"Recovered flyer returns to high-flight defense")
	clear_shots()
	# The same combo can land after the jump; a missed floor strike did not blacklist it.
	p.position = fly.position-Vector2(50,0)
	p.jump_height = 32
	hp_before = fly.hp
	stage.strike(p,1,targets)
	check(fly.hp < hp_before and fly.flight == fly.Flight.FALLING,"A real airborne brush strike knocks a recovered flyer down")
	var defeated_before: int = stage.defeated
	fly.take_hit(999,1)
	fly.take_hit(999,1)
	check(fly.dead and stage.defeated == defeated_before+1,"Yellow death resolves once, including while falling")
	await process_frame
	# Spit attack telegraphs, aims at launch and spawns a visible pixel slime ball.
	p.jump_height = 0
	p.position = Vector2(2800,280)
	q.position = Vector2(2700,320)
	fly = yellow(Vector2(3010,280))
	fly.cooldown = 0
	fly._physics_process(0.01)
	check(fly.windup > 0 and get_nodes_in_group("enemy_projectiles").is_empty(),"A short visible windup precedes the slime shot")
	fly._physics_process(0.5)
	check(get_nodes_in_group("enemy_projectiles").size() == 1,"Windup emits one slime projectile")
	shot = get_first_node_in_group("enemy_projectiles")
	shot.set_physics_process(false)
	check(shot.height > 60 and shot.velocity.x < 0 and shot.height_velocity < 0,"High flyer spits toward the player and down from its actual height")
	var before: Vector2 = shot.position
	stage.controls_locked = true
	shot._physics_process(1)
	check(shot.position == before,"Slime shots pause with help and modal screens")
	stage.controls_locked = false
	p.hp = 100
	p.invulnerable = 0
	shot._physics_process(1.3)
	check(p.hp == 90 and shot.popping,"Slime uses swept collision and damages the player at chest height")
	p.invulnerable = 0
	shot._physics_process(0.01)
	check(p.hp == 90,"A popped slime ball cannot damage a second time")
	clear_shots()
	shot = fly.Goo.new()
	shot.position = Vector2(3010,280)
	shot.height = 70
	shot.aim_at(p.position)
	stage.get_node("Projectiles").add_child(shot)
	shot.set_physics_process(false)
	p.position.y = 320
	shot._physics_process(1.3)
	check(p.hp == 90,"Leaving the launch lane avoids a slime ball")
	clear_shots()
	fly.free()
	# Exercise the real companion controller, not just the altitude helper.
	p.position = Vector2(2800,280)
	q.position = Vector2(2770,280)
	q.equip_weapon("bubbles")
	q.ai_controlled = true
	q.jump_height = 0
	q.jump_speed = 0
	q.attack_time = 0
	q.stun = 0
	fly = yellow(Vector2(2980,280))
	for i in 60:
		await physics_frame
		q._physics_process(1.0/60)
		for bubble in stage.get_node("Projectiles").get_children():
			bubble.set_physics_process(false)
			bubble._physics_process(1.0/60)
		if fly.flight == fly.Flight.FALLING: break
	check(fly.hp < 195 and fly.flight == fly.Flight.FALLING,"AI jumps and fires at high flyers in actual combat")
	clear_shots()
	fly.free()
	var ground = stage.GermScene.instantiate()
	ground.position = q.position-Vector2(30,0)
	stage.get_node("Actors").add_child(ground)
	ground.set_physics_process(false)
	check(stage.nearest_enemy(q.position) == ground,"Mixed ground enemies behind the AI remain valid combat targets")
	ground.take_hit(999,1)
	await process_frame
	stage._process(0.01)
	check(stage.beat == stage.Beat.FINISHED and stage.victory,"Defeating the mixed group finishes the encounter")
	var completed_count: int = stage.mixed_spawned
	stage._process(8)
	check(stage.mixed_spawned == completed_count and get_nodes_in_group("germs").is_empty(),"The encounter cannot respawn after completion")
	var fires: Array = []
	for child in stage.corridor.get_children():
		if child.get_script() == stage.corridor.Effect: fires.append(child)
	check(fires.size() == 3 and fires[0].flame.hframes*fires[0].flame.vframes == 12,"Computers now use the twelve reference-based flame frames")
	var frames: Array[int] = []
	for i in 120:
		fires[0]._process(1.0/60)
		if fires[0].flame.frame not in frames: frames.append(fires[0].flame.frame)
	check(frames.size() == 12,"New flames play all twelve animation drawings")
	print("PASS: " if failures.is_empty() else "FAIL: ",checks," yellow flyer / door / fire checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
