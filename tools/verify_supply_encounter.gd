extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void: call_deferred("run")
func press(encounter, action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	encounter._unhandled_input(event)
func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	var encounter = arena.encounter
	var player = arena.players[0]
	var partner = arena.players[1]
	for actor in arena.players: actor.set_physics_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	arena.tutorial.step = 7
	arena.built = true
	arena.defeated = 1
	arena.wave = 1
	arena.open_limit = 1230
	player.position = Vector2(1100,250)
	partner.position = Vector2(1070,285)
	arena.spawn_wave()
	for germ in get_nodes_in_group("germs"): germ.set_physics_process(false)
	arena._process(0)
	encounter._process(0)
	check(not encounter.unlocked and not encounter.arrow.visible,"The route stays closed during the first combat sector")
	for i in 3:
		var box = arena.get_node("Breakables/DamagedCrate%d" % i)
		box._physics_process(0)
		box.sample_visual()
		check(box.position.x > 1280 and box.get_node("Sprite").frame == 1 and box.hp == 14,"New area crates remain damaged and stay in the new bounds")
	player.position = Vector2(1235,250)
	player.collision_mask = 1
	await physics_frame
	check(player.move_and_collide(Vector2(200,0)) != null,"Far edge physically blocks entry before the sector is clear")
	var germs = get_nodes_in_group("germs")
	for i in 4: germs[i].take_hit(germs[i].max_hp,1)
	await process_frame
	arena._process(0)
	encounter._process(0)
	check(not encounter.unlocked,"Leaving one germ alive does not unlock the next area")
	germs[4].take_hit(germs[4].max_hp,1)
	await process_frame
	arena._process(0)
	encounter._process(0)
	check(arena.victory and encounter.unlocked and encounter.arrow.visible,"Last germ unlocks the right-arrow navigation cue")
	check(arena.open_limit == 2230 and arena.camera_max_x == 1920,"Players and camera can reach the new sector")
	await physics_frame
	player.position = Vector2(1235,250)
	check(player.move_and_collide(Vector2(200,0)) == null and player.position.x > 1280,"Players walk naturally into the connected area")
	check(not encounter.try_interact(player),"Distant interaction does nothing")
	player.position = Vector2(1460,266)
	partner.position = Vector2(1475,290)
	encounter._process(0)
	check(not encounter.arrow.visible and encounter.tiburcio.get_node("Prompt").visible,"Arriving replaces the arrow with Tibúrcio's nearby prompt")
	check(not encounter.try_interact(partner),"AI must never initiate dialogue")
	press(encounter,"p0_interact")
	check(encounter.dialogue.active and arena.controls_locked,"E opens dialogue and pauses player control")
	check(not encounter.tiburcio.get_node("Prompt").visible,"Interaction prompts hide immediately during the conversation")
	check(encounter.dialogue.get_node("Speaker").text == "TIBÚRCIO UNG","Dialogue names Tibúrcio Ung")
	check(encounter.dialogue.get_node("Message").text == encounter.TIBURCIO_LINE,"The complete requested line is preserved verbatim")
	encounter.dialogue._process(0.5)
	check(encounter.dialogue.get_node("Message").visible_characters > 0,"Dialogue types while gameplay is paused")
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_E
	echo.pressed = true
	echo.echo = true
	encounter._unhandled_input(echo)
	check(encounter.dialogue.active and not encounter.talked,"Held-key repeats cannot skip the conversation")
	press(encounter,"p0_interact")
	check(encounter.dialogue.active and encounter.dialogue.get_node("Message").visible_characters == encounter.TIBURCIO_LINE.length(),"First press reveals the rest of the text")
	await process_frame
	check(encounter.dialogue.get_node("Message").get_line_count() <= 5,"The full speech fits inside the dialogue frame")
	press(encounter,"p0_interact")
	check(encounter.talked and not encounter.dialogue.active and not arena.controls_locked,"Second press ends the conversation and restores control")
	partner.ai_controlled = false
	partner.position = Vector2(1700,305)
	player.position = Vector2(1600,300)
	encounter._process(0)
	check(encounter.robot.get_node("Prompt").visible and encounter.robot.get_node("Prompt").key_text == "U","P2 receives their own nearby interaction key")
	press(encounter,"p1_interact")
	check(encounter.equipment.visible and encounter.is_modal() and arena.controls_locked,"U opens the equipment panel for local P2")
	Input.action_press("controls")
	Input.action_press("join")
	arena._process(0)
	check(not arena.get_node("HUD/ControlsPanel").visible and not partner.ai_controlled,"Help and join cannot change controls under the equipment modal")
	Input.action_release("controls")
	Input.action_release("join")
	press(encounter,"ui_cancel")
	check(not encounter.equipment.visible and not arena.controls_locked,"Escape closes equipment and restores controls")
	partner.ai_controlled = true
	partner.position = Vector2(1550,310)
	player.position = Vector2(1700,305)
	encounter._process(0)
	check(encounter.robot.get_node("Prompt").key_text == "E","Solo player sees E near the robot")
	press(encounter,"p0_interact")
	check(encounter.equipment.visible,"E opens the robot panel")
	press(encounter,"p0_interact")
	check(not encounter.equipment.visible,"A new E press closes the robot panel")
	player.down = true
	check(not encounter.try_interact(player),"Downed characters cannot open equipment")
	player.down = false
	player.position = Vector2(1950,300)
	encounter._process(0)
	check(not encounter.robot.get_node("Prompt").visible,"Interaction hint disappears outside its radius")
	if failures.is_empty(): print("PASS: last-germ progression, right arrow, physical area transition, damaged crates, exact Tibúrcio dialogue, proximity E/U, no AI/held-repeat triggers, paused modals and equipment panel")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
