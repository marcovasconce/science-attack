extends SceneTree
var failures: Array[String] = []
var checks := 0
var stage
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func freeze() -> void:
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.dialogue.set_process(false)
	stage.king.set_process(false)
	for p in stage.players: p.set_physics_process(false)
func run() -> void:
	set_meta("party_state", [{"weapon":"brush","hp":73,"max_hp":120,"energy":55,"healing_flasks":2,"ai_controlled":false}, {"weapon":"bubbles","hp":64,"energy":75,"healing_flasks":4,"ai_controlled":false}])
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	freeze()
	var p = stage.players[0]
	var q = stage.players[1]
	check(stage.controls_locked and stage.beat == stage.Beat.ARRIVAL,"Arrival is locked until the doors open")
	check(p.hp == 73 and p.max_hp == 120 and p.energy == 55 and p.healing_flasks == 2,"Health, capacity, energy and flasks transfer intact")
	check(p.equipped_weapon == "brush" and q.equipped_weapon == "bubbles" and not q.ai_controlled,"Loadout and local cooperative mode transfer intact")
	check(not has_meta("party_state") and has_meta(stage.ENTRY_META),"Transfer is consumed and retained as a retry snapshot")
	stage.elevator._physics_process(3)
	check(not stage.controls_locked and stage.beat == stage.Beat.EXPLORE,"Doors release control and exploration")
	check(not stage.elevator.get_node("Hint").visible and not stage.has_node("Elevator/Sector"),"Elevator and sector lettering are removed")
	var slime = stage.get_node("Elevator/Slime")
	check(slime.z_index + stage.elevator.z_index < p.z_index,"Elevator slime renders behind the players")
	stage._process(0.1)
	check(not stage.king.visible and stage.spawned == 0,"The abduction and wave do not trigger at the elevator")
	p.position = Vector2(520,285)
	q.position = Vector2(478,305)
	stage._process(0.1)
	check(stage.beat == stage.Beat.REVEAL and stage.controls_locked and stage.king.visible,"Walking ahead reveals the king and locks combat")
	stage._process(0.9)
	check(stage.dialogue.active and stage.beat == stage.Beat.DIALOGUE,"The camera settles before the requested dialogue")
	check(stage.dialogue.get_node("Message").text == stage.KING_LINE,"The king delivers the requested line")
	var composite = stage.king.get_node("Hover/Sprite")
	check(stage.king.get_node("Hover").get_child_count() == 1 and not stage.king.has_node("Hover/Tiburcio"),"King and captive render as one integrated sprite")
	check(composite.hframes * composite.vframes == 6,"Composite has six mouth and dripping-goo animation frames")
	var sheet: Image = composite.texture.get_image()
	check(sheet.get_pixel(0,0).a == 0 and sheet.get_pixel(111,111).a == 0,"Generated sheet has real transparent margins")
	var mouth_a := sheet.get_region(Rect2i(25,40,50,25)).get_data()
	var mouth_b := sheet.get_region(Rect2i(249,40,50,25)).get_data()
	check(mouth_a != mouth_b,"Open-mouth frame has different pixels from grin frame")
	var goo_a := sheet.get_region(Rect2i(32,75,48,34)).get_data()
	var goo_b := sheet.get_region(Rect2i(256,75,48,34)).get_data()
	check(goo_a != goo_b,"Goo elongation is drawn into the frames")
	var frames_seen: Array[int] = []
	for i in 60:
		stage.king._process(1.0 / 60)
		if composite.frame not in frames_seen: frames_seen.append(composite.frame)
	check(frames_seen.size() == 6 and frames_seen.has(0) and frames_seen.has(5),"Animation advances and loops through all six frames")
	stage._process(7.6)
	check(stage.beat == stage.Beat.DIALOGUE and stage.dialogue.active,"Auto advance first reveals all text if reveal has not run")
	stage._process(0.1)
	check(stage.beat == stage.Beat.ESCAPE and stage.controls_locked,"The readable dialogue ends in the escape")
	for i in 120:
		stage._process(1.0/60)
		if stage.beat == stage.Beat.WARNING: break
	check(stage.beat == stage.Beat.WARNING and not stage.king.visible and not stage.controls_locked,"King leaves the screen before warning and player control resume")
	check(stage.warning.visible and stage.spawned == 0,"Warning starts visible before any enemy spawns")
	stage._process(0.1)
	check(not stage.warning.visible,"Warning blinks off at 0.1 seconds")
	stage._process(0.1)
	check(stage.warning.visible,"Warning blinks on at 0.2 seconds")
	stage.get_node("HUD/ControlsPanel").show()
	var before: float = stage.warning.elapsed
	stage._process(3)
	check(stage.warning.elapsed == before and stage.spawned == 0,"Help pauses warning and spawning")
	stage.get_node("HUD/ControlsPanel").hide()
	stage._process(0.79)
	check(stage.beat == stage.Beat.WARNING and stage.spawned == 0,"No enemy appears during the one-second warning")
	stage._process(0.02)
	check(stage.beat == stage.Beat.WAVE and stage.wave == 1 and not stage.warning.visible and not stage.warning.running,"The warning ends after one second")
	stage._process(0.01)
	var fly = get_first_node_in_group("germs")
	fly.set_physics_process(false)
	check(fly.hp == 1 and fly.position.x > stage.get_node("Camera2D").position.x + 320,"First flyer begins outside the screen with one hit point")
	var flight_start: Vector2 = fly.position
	fly._physics_process(0.1)
	check(fly.position.x < flight_start.x and fly.velocity.x < 0,"Flying bacteria cross the screen towards the party")
	stage.controls_locked = true
	var fly_at: Vector2 = fly.position
	fly._physics_process(0.5)
	check(fly.position == fly_at,"Help freezes enemy movement")
	stage.controls_locked = false
	fly.position = p.position + Vector2(55,0)
	p.facing = 1
	stage.strike(p,1,[])
	check(fly.dead and stage.defeated == 1 and p.hit_combo == 1,"One light brush hit defeats a flyer and awards a combo hit")
	fly.take_hit(10,1)
	check(stage.defeated == 1,"Defeat callback cannot count twice")
	await process_frame
	stage._spawn_flyer()
	fly = get_first_node_in_group("germs")
	fly.set_physics_process(false)
	q.position = Vector2(550,305)
	q.facing = 1
	fly.position = q.position + Vector2(65,0)
	var bubble = stage.spawn_bubble(q)
	bubble.set_physics_process(false)
	bubble._physics_process(0.2)
	check(fly.dead and stage.defeated == 2,"One normal soap bubble defeats a flyer through real swept collision")
	await process_frame
	stage._spawn_flyer()
	fly = get_first_node_in_group("germs")
	fly.set_physics_process(false)
	fly.position = p.position + Vector2(80,0)
	stage.special_area(p,p.position,140,65,30)
	check(fly.dead,"Special attacks also defeat flyers")
	await process_frame
	# Real high-speed swept contact: two local players in the same flight lane.
	p.position = Vector2(600,280)
	q.position = Vector2(550,280)
	p.invulnerable = 0
	q.invulnerable = 0
	var hp_before := Vector2(p.hp, q.hp)
	stage._spawn_flyer()
	fly = get_first_node_in_group("germs")
	fly.set_physics_process(false)
	fly.position = Vector2(740,280)
	fly.lane_y = 280
	fly.speed = 520
	fly._physics_process(0.5)
	check(p.hp == hp_before.x - 6 and q.hp == hp_before.y - 6,"Swept fly-through contact damages both players even during a large physics step")
	check(fly.position.x < q.position.x and not fly.dead,"The flyer continues past both players after hitting")
	p.invulnerable = 0
	q.invulnerable = 0
	fly._physics_process(0.1)
	check(p.hp == hp_before.x - 6 and q.hp == hp_before.y - 6 and fly.velocity.x < 0,"Each flyer damages each player only once and never turns back")
	var defeated_before: int = stage.defeated
	fly.position.x = stage.get_node("Camera2D").position.x - 400
	fly._physics_process(0.01)
	check(fly.dead and stage.passed == 1 and stage.defeated == defeated_before,"Passing flyers leave the scene without granting a false kill")
	await process_frame
	stage._spawn_flyer()
	fly = get_first_node_in_group("germs")
	fly.set_physics_process(false)
	fly.position = Vector2(740,280)
	fly.lane_y = 280
	fly.speed = 520
	p.invulnerable = 1
	q.position.y = 325
	hp_before = Vector2(p.hp,q.hp)
	fly._physics_process(0.5)
	check(p.hp == hp_before.x and q.hp == hp_before.y,"Dodging and leaving the flight lane avoid contact damage")
	fly.take_hit(1,1)
	await process_frame
	check(stage.WAVE_SIZES == [48,80],"Two waves are substantially larger, with the second larger still")
	# Resolve the rest of wave one, including enemies that escape instead of dying.
	for i in 100:
		stage._process(0.12)
		for enemy in get_nodes_in_group("germs"):
			enemy.set_physics_process(false)
			if i % 2 == 0: enemy.take_hit(1,1)
			else:
				enemy.position.x = stage.get_node("Camera2D").position.x - 400
				enemy._physics_process(0.01)
		await process_frame
		if stage.beat == stage.Beat.WARNING: break
	check(stage.spawned == 48 and stage.wave == 2 and stage.beat == stage.Beat.WARNING and stage.warning.visible,"Resolving 48 flyers immediately repeats the warning for wave two")
	check(not stage.victory,"Surviving the first wave does not finish the encounter")
	stage._process(0.99)
	check(stage.spawned == 48 and stage.beat == stage.Beat.WARNING,"Second warning also lasts a full second before spawning")
	stage._process(0.02)
	stage._process(0.01)
	check(stage.wave_spawned == 1 and stage.spawned == 49,"The second wave begins only after the second alert")
	stage.get_node("HUD/ControlsPanel").show()
	stage.controls_locked = true
	var spawned_before: int = stage.spawned
	stage._process(2)
	fly = get_first_node_in_group("germs")
	fly.set_physics_process(false)
	flight_start = fly.position
	fly._physics_process(2)
	check(stage.spawned == spawned_before and fly.position == flight_start,"Help freezes the second swarm and its spawn clock")
	stage.get_node("HUD/ControlsPanel").hide()
	stage.controls_locked = false
	for i in 100:
		stage._process(0.08)
		for enemy in get_nodes_in_group("germs"):
			enemy.set_physics_process(false)
			enemy.position.x = stage.get_node("Camera2D").position.x - 400
			enemy._physics_process(0.01)
		await process_frame
		if stage.beat == stage.Beat.CLEARED: break
	check(stage.spawned == 128 and stage.wave_spawned == 80 and stage.beat == stage.Beat.CLEARED and stage.victory,"All 80 second-wave flyers can pass without leaving the encounter stuck")
	check(stage.defeated + stage.passed == 128,"Every flyer resolves exactly once as defeated or passed")
	stage._process(15)
	check(stage.spawned == 128 and stage.wave == 2,"The encounter cannot spawn a third wave or repeat the abduction")
	# A fresh approaching flyer outranks one which has already passed the AI.
	p.position = Vector2(620,280)
	q.position = Vector2(580,280)
	q.ai_controlled = true
	var incoming = stage.FlyingScene.instantiate()
	incoming.position = Vector2(750,280)
	stage.get_node("Actors").add_child(incoming)
	incoming.set_physics_process(false)
	var outgoing = stage.FlyingScene.instantiate()
	outgoing.position = Vector2(560,280)
	stage.get_node("Actors").add_child(outgoing)
	outgoing.set_physics_process(false)
	check(stage.nearest_enemy(q.position) == incoming,"AI ignores the closer flyer behind it")
	q.attack_time = 0
	q.stun = 0
	q._physics_process(1.0/60)
	check(q.facing > 0 and q.velocity.x >= 0,"AI actually faces incoming bugs and holds formation rather than chasing left")
	outgoing._physics_process(0.01)
	q.position.x = 520
	incoming.dead = true
	check(stage.nearest_enemy(q.position) == null,"An escaped flyer is not reacquired even when the AI later moves behind it")
	incoming.queue_free()
	outgoing.queue_free()
	await process_frame
	check(stage.open_limit == 3140 and stage.corridor.puddles.size() == 5,"Clearing the swarm opens the damaged corridor with five hazards")
	for puddle in stage.corridor.puddles: puddle.set_physics_process(false)
	var puddle = stage.corridor.puddles[0]
	p.position = puddle.position
	p.hp = 100
	p.invulnerable = 0
	p.jump_height = 0
	puddle._physics_process(0.01)
	check(p.hp == 92,"Standing on toxic liquid deals eight damage")
	p.invulnerable = 0
	puddle._physics_process(0.4)
	check(p.hp == 92,"Puddle damage has a cooldown instead of draining every frame")
	p.jump_height = 40
	puddle._physics_process(1)
	check(p.hp == 92,"Jumping above the puddle avoids damage")
	p.jump_height = 0
	p.position = puddle.position + Vector2(0,40)
	puddle._physics_process(1)
	check(p.hp == 92,"Walking in the safe lane avoids the puddle")
	p.position = puddle.position
	stage.controls_locked = true
	puddle._physics_process(1)
	check(p.hp == 92,"Modal screens pause hazardous liquid")
	stage.controls_locked = false
	puddle._physics_process(0.01)
	check(p.hp == 84,"Landing in the liquid after the cooldown deals damage again")
	# Follow the real AI around the first pool, keeping its feet in a safe lane.
	p.position = Vector2(1300,285)
	q.position = Vector2(1040,285)
	q.hp = 100
	q.stun = 0
	q.invulnerable = 0
	q.attack_time = 0
	for i in 220:
		await physics_frame
		q._physics_process(1.0/60)
		puddle._physics_process(1.0/60)
	check(q.hp == 100 and q.position.x > 1210,"AI companion walks around toxic liquid while following the player (hp=%d, x=%.1f)" % [q.hp,q.position.x])
	p.position = Vector2(1000,285)
	q.position = Vector2(1280,285)
	stage.ai_detour.clear()
	for i in 220:
		await physics_frame
		q._physics_process(1.0/60)
		puddle._physics_process(1.0/60)
	check(q.hp == 100 and q.position.x < 1070,"AI also avoids the puddle when the player walks back")
	await physics_frame
	var door = stage.corridor.door
	var space = stage.get_world_2d().direct_space_state
	for lane in [200,260,320]:
		var ray := PhysicsRayQueryParameters2D.create(Vector2(2500,lane),Vector2(2750,lane),1)
		var hit: Dictionary = space.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == door.get_node("Body"),"Locked door blocks passage at depth %d" % lane)
	p.position = Vector2(2440,270)
	q.position = Vector2(2390,290)
	stage.beat = stage.Beat.WAVE
	stage._open_terminal(0)
	check(not stage.puzzle.active and stage.beat == stage.Beat.WAVE,"The terminal cannot be used before both waves end")
	stage.beat = stage.Beat.CLEARED
	stage.get_node("Camera2D").position = Vector2(2440,180)
	stage._update_terminal_prompt()
	check(stage.corridor.prompt.visible,"A human player near the terminal sees the interaction key")
	var use_key := InputEventKey.new()
	use_key.physical_keycode = KEY_E
	use_key.pressed = true
	stage._unhandled_input(use_key)
	check(stage.beat == stage.Beat.ZOOM and stage.controls_locked,"E at the terminal begins camera zoom and locks combat")
	stage._process(0.61)
	var puzzle = stage.puzzle
	puzzle.set_process(false)
	check(puzzle.active and puzzle.state == puzzle.State.BOOT and stage.get_node("Camera2D").zoom.x > 2,"Zoom finishes before the short system boot")
	puzzle.select_tile(0)
	check(puzzle.selected == -1,"Boot cannot accept premature tile input")
	puzzle._process(1.41)
	check(puzzle.state == puzzle.State.PLAY and not door.opening,"Boot reveals an unsolved 3x3 puzzle and leaves the gate locked")
	puzzle.select_tile(0)
	puzzle.select_tile(1)
	var preserved: Array = puzzle.tiles.duplicate()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	puzzle._input(escape)
	stage._process(0.51)
	check(stage.beat == stage.Beat.CLEARED and not stage.controls_locked and not door.opening and stage.get_node("Camera2D").zoom == Vector2.ONE,"Escape restores the camera and controls without opening the door")
	q.ai_controlled = false
	q.position = Vector2(2430,275)
	use_key.physical_keycode = KEY_U
	stage._unhandled_input(use_key)
	stage._process(0.61)
	check(puzzle.active and puzzle.owner_id == 1,"Local player two can open the terminal with U")
	puzzle.close(false)
	stage._process(0.51)
	stage._open_terminal(0)
	stage._process(0.61)
	puzzle._process(1.41)
	check(puzzle.tiles == preserved,"Reopening the terminal preserves previous tile swaps")
	# Use actual mouse/key input for the first correction, then complete every tile.
	var first := InputEventMouseButton.new()
	first.pressed = true
	first.button_index = MOUSE_BUTTON_LEFT
	first.position = puzzle.BOARD.position + Vector2(12,12)
	puzzle._input(first)
	check(puzzle.selected == 0,"Mouse clicks select a board piece")
	var confirm := InputEventKey.new()
	confirm.physical_keycode = KEY_E
	confirm.pressed = true
	puzzle._input(confirm)
	check(puzzle.selected == -1,"Keyboard selection can cancel a selected piece")
	for slot in 9:
		if puzzle.tiles[slot] == slot: continue
		var other: int = puzzle.tiles.find(slot)
		puzzle.select_tile(slot)
		puzzle.select_tile(other)
	check(puzzle.solved and puzzle.state == puzzle.State.SUCCESS,"Correct assembly of all nine original sprite pieces completes the puzzle")
	puzzle._process(1.01)
	stage._process(0.51)
	check(stage.puzzle_complete and door.opening and not stage.controls_locked,"Solving restores gameplay and begins opening the physical door")
	door._process(1.3)
	await process_frame
	await physics_frame
	check(door.openness == 1 and door.collision.disabled,"Door retracts and removes its collision only after opening")
	var clear_ray := PhysicsRayQueryParameters2D.create(Vector2(2500,260),Vector2(2750,260),1)
	check(space.intersect_ray(clear_ray).is_empty(),"Players can physically continue beyond the solved door")
	stage._open_terminal(0)
	check(stage.beat == stage.Beat.MIXED and not puzzle.active,"A completed terminal does not reopen or relock the corridor after the new encounter starts")
	p.hp = 4
	p.healing_flasks = 0
	await process_frame
	Input.action_press("restart")
	stage._process(0.01)
	Input.action_release("restart")
	for i in 4: await process_frame
	stage = current_scene
	freeze()
	check(stage.beat == stage.Beat.ARRIVAL and stage.spawned == 0 and stage.players[0].hp == 73 and stage.players[0].healing_flasks == 2,"Actual F2 reload restores the entry party and resets the complete sequence")
	check(not stage.puzzle_complete and not stage.puzzle.active and not stage.corridor.door.collision.disabled,"Restart resets the puzzle, camera modal and locked door")
	print("PASS: " if failures.is_empty() else "FAIL: ", checks, " lower lab checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
