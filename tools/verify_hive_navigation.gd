extends SceneTree
const Chapters = preload("res://scripts/chapter_catalog.gd")
const Party = preload("res://scripts/party_transfer.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
func frames(count: int) -> void:
	for i in count: await physics_frame
func press(player_id: int, action: String) -> void:
	var key := "p%d_%s" % [player_id, action]
	Input.action_press(key)
	await frames(3)
	Input.action_release(key)
	await frames(3)
func force_clear() -> void:
	for germ in get_nodes_in_group("germs"): germ.take_hit(1000, 1.0)
	await frames(63)
func run() -> void:
	Chapters.open(self, 30)
	await frames(40)
	var hive = current_scene
	if not is_instance_valid(hive) or not "beat" in hive:
		push_error("Hive scene failed to load")
		quit(2)
		return
	var p = hive.players[0]
	var a = hive.players[1]
	check(not hive.controls_locked and hive.world_limit == 4044 and hive.clean_sample, "Shortcut starts inside workshop with the campaign prerequisite")
	check(Party.capture(hive)[0].clean_sample, "Party snapshots carry the jar")

	p.position = Vector2(500, 279)
	await press(0, "interact")
	p.position = Vector2(620, 279)
	await press(0, "interact")
	await frames(255)
	check(hive.bubble_puzzle.solved and hive.arsenal_claimed and p.weapon_upgraded and a.weapon_upgraded, "Real spring inputs unlock both weapons")
	p.position = Vector2(841, 258)
	a.position = Vector2(815, 309)
	await frames(55)
	check(hive.beat == hive.Beat.ASSAULT and hive.assault == 1 and hive.remaining == 4, "Both players enter the first assault")

	await force_clear()
	check(hive.assault == 2 and hive.remaining == 5 and hive.east_gate.openness == 0, "Second wave keeps the exit sealed")
	await force_clear()
	check(hive.beat == hive.Beat.APPROACH_KING and hive.east_gate.openness > 0, "Clearing the waves releases the exit")
	for sector in hive.SECTORS.size():
		await frames(28)
		Input.action_press("p0_right")
		for i in 440:
			if hive.beat == hive.Beat.SEWER_WAVES: break
			await physics_frame
		Input.action_release("p0_right")
		await frames(37)
		check(hive.beat == hive.Beat.SEWER_WAVES and hive.sector == sector and hive.remaining > 0, "Each added room starts from player movement")
		if sector >= 2:
			check(not get_nodes_in_group("swarm_flyers").is_empty(), "Later waves include flying enemies")
		if sector == 1:
			var west = hive.get_node("Drains/PressureWest")
			var middle = hive.get_node("Drains/PressureOutlet")
			var east = hive.get_node("Drains/ReturnEast")
			hive._tick_pressure_room(1.0)
			check(west.state == west.State.WARNING and middle.state == middle.State.REST, "Pressure begins at the west drain")
			hive._tick_pressure_room(2.4)
			check(middle.state == middle.State.WARNING and east.state == east.State.REST, "Pressure crosses to the other lane")
			await force_clear()
			hive._tick_pressure_room(1.0)
			check(east.state == east.State.WARNING and hive.sector_gates[1].openness == 0, "Second wave reverses the sweep while the exit stays closed")
			await force_clear()
			await frames(26)
			check(hive.sector == 2 and hive.sector_gates[1].openness > 0.95, "Clearing the station opens its exit automatically")
		else:
			await force_clear()
			await force_clear()
	await frames(28)
	Input.action_press("p0_right")
	for i in 600:
		if hive.beat == hive.Beat.KING: break
		await physics_frame
	Input.action_release("p0_right")
	check(hive.captive.visible and hive.get_node("HUD/BossTitle").visible and hive.king.MAX_HP == 10000, "Boss entrance shows the hostage and full health bar")
	for i in 120:
		if hive.king.state == hive.king.State.WINDUP: break
		await physics_frame
	await frames(13)
	check(hive.beat == hive.Beat.KING and hive.king.is_in_group("germs") and hive.king.state == hive.king.State.WINDUP, "King starts with a visible windup")

	hive.ultimate_camera("solar")
	await frames(9)
	check(hive.get_node("Camera2D").zoom.x > 1, "Solar bumps camera zoom")
	hive.ultimate_camera("nova")
	await frames(6)
	check(hive.get_node("Camera2D").zoom.x > 1, "Nova bumps camera zoom")
	var king = hive.king
	var old_hp: int = p.hp
	p.position = king.crash_at
	var mouth: Vector2 = king.crash_at
	await frames(29)
	check(king.state == king.State.RECOVER and p.hp < old_hp, "Staying inside the announced slam takes a hit")
	check(hive.king_floor(mouth) == mouth, "Slam stays inside the arena")
	var before_burst: int = king.hp
	king.take_hit(650, 1)
	check(king.hp > king.PHASE_MARK and king.hp < before_burst, "A full special-sized hit leaves the first phase standing")
	king.turns = 2
	king._warn(p.position)
	king._attack()
	p.position = king.position + Vector2(100, 0)
	p.jump_height = 0
	p.dash = 0
	p.push_velocity = Vector2.ZERO
	king._tick_vacuum(0.03)
	check(p.push_velocity.x < 0, "Redemoinho pulls grounded players toward the king")
	p.push_velocity = Vector2.ZERO
	p.jump_height = 25
	king._tick_vacuum(0.03)
	check(p.push_velocity == Vector2.ZERO, "Jumping resists the suction")
	p.jump_height = 0
	king.turns = 1
	king._warn(p.position)
	king._attack()
	var orb = get_first_node_in_group("royal_bubbles")
	check(is_instance_valid(orb), "The royal bubble spawns as an attackable target")
	var hp_before_bubble: int = king.hp
	orb.position = king.position + Vector2(36, 0)
	orb.take_hit(40, 1)
	await frames(8)
	check(king.hp < hp_before_bubble and king.recovery_bonus >= 1.5, "An attack returns the royal bubble and forces a long stun")
	king.take_hit(10000, 1)
	check(king.phase == 2 and king.hp == king.PHASE_MARK and not king.dead, "The phase threshold cannot be skipped by burst damage")
	await frames(113)
	var has_adds := get_nodes_in_group("germs").size() >= 2
	check(has_adds and king.state != king.State.ROAR, "The second phase brings reinforcements")
	king.turns = 0
	king._warn(p.position)
	check(hive.get_node("Drains/RoyalWest").state == hive.vents.back().State.WARNING, "The first drain warns before the attack")
	king._attack()
	await frames(54)
	check(hive.royal_vents().all(func(drain): return drain.state != drain.State.REST), "The other royal drains fire in sequence")
	var vent = hive.get_node("Drains/RoyalValve")
	king.position = vent.position
	vent.state = vent.State.ERUPTING
	vent.age = 0.6
	var before_jet: int = king.hp
	vent._process(0.01)
	vent._process(0.01)
	check(king.hp < before_jet and king.state == king.State.RECOVER and king.recovery_bonus > 0, "Royal drain interrupts the boss and opens a longer attack window")
	var after_jet: int = king.hp
	vent._process(0.01)
	check(king.hp == after_jet, "A single eruption only hits the king once")
	king.take_hit(10000, 1)
	check(hive.beat == hive.Beat.CAPTURE and not hive.victory and hive.clean_sample and hive.jar.visible, "Zero HP opens capture without ending the game")
	await frames(8)

	p.position = hive.jar.position + Vector2(-30, 5)
	await press(0,"interact")
	check(hive.beat == hive.Beat.SEAL and not hive.clean_sample, "Real interaction uses the single carried jar")
	await frames(95)
	check(hive.beat == hive.Beat.END and hive.victory and not hive.captive.visible and hive.get_node("Actors/Tiburcio").visible and hive.get_node("HUD/Finale").visible, "Sealing the king rescues Tiburcio and shows the ending")

	hive.get_node("HUD/Finale/Panel/Content/Menu").pressed.emit()
	await frames(8)
	check(current_scene.scene_file_path == "res://scenes/main_menu.tscn" and not has_meta("hive_king_checkpoint"), "Ending returns to menu and clears campaign checkpoint")
	print("PASS" if failures == 0 else "FAIL", ": ", checks, " ending flow checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)

