extends SceneTree
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	for actor in arena.players: actor.set_physics_process(false)
	arena.get_node("WakeSequence").pause()
	var hud = arena.get_node("HUD/TeamHUD")
	hud.set_process(false)
	var primary = hud.get_node("Primary")
	var secondary = hud.get_node("Partner")
	var player = arena.players[0]
	var partner = arena.players[1]
	check(InputMap.action_get_events("p0_heal")[0].physical_keycode == KEY_Q, "P1 healing key")
	check(InputMap.action_get_events("p1_heal")[0].physical_keycode == KEY_O, "P2 healing key")
	check(not hud.two_players and secondary.compact, "AI uses compact companion row")
	check(primary.position.y < secondary.position.y, "Solo stacks its two portraits")
	check(secondary.get_node("Name").text.begins_with("IA"), "Companion identified as AI")
	player.hp = 60
	check(not player.use_healing_flask() and player.healing_flasks == 5, "Opening locks healing")
	arena.controls_locked = false
	player.energy = 42
	check(player.use_healing_flask() and player.hp == 85 and player.healing_flasks == 4, "Flask restores exactly partial health")
	hud._process(0.016)
	check(primary.get_node("Health").value == 85 and primary.get_node("Count").text == "4", "HUD shows real health and inventory")
	check(primary.get_node("Special").value == 42, "Blue bar follows existing energy state")
	check(player.use_healing_flask() and player.hp == player.max_hp, "Healing never exceeds maximum")
	check(not player.use_healing_flask() and player.healing_flasks == 3, "Full health consumes nothing")
	player.invulnerable = 0
	player.take_hit(40, Vector2.ZERO)
	hud._process(0.016)
	check(primary.get_node("Health").value == 60, "Damage updates health immediately")
	Input.action_press("p0_heal")
	player._physics_process(0.016)
	Input.action_release("p0_heal")
	check(player.hp == 85 and player.healing_flasks == 2, "P1 action actually uses a flask")
	await process_frame
	partner.hp = 30
	partner._physics_process(0.016)
	check(partner.hp == 55 and partner.healing_flasks == 4, "AI heals with its own inventory")
	var saved_hp: int = partner.hp
	Input.action_press("join")
	arena._process(0.0)
	Input.action_release("join")
	hud._process(0.0)
	check(hud.two_players and not secondary.compact, "Enter switches to two complete panels")
	check(primary.position.y == secondary.position.y and primary.position.x < secondary.position.x, "Co-op panels sit side by side")
	check(partner.hp == saved_hp and partner.healing_flasks == 4, "Joining preserves inventory and health")
	check(secondary.get_node("Name").text.begins_with("P2"), "Human partner identified as P2")
	Input.action_press("p1_heal")
	partner._physics_process(0.016)
	Input.action_release("p1_heal")
	check(partner.hp == 80 and partner.healing_flasks == 3 and player.healing_flasks == 2, "P2 healing leaves P1 inventory untouched")
	await process_frame
	Input.action_press("controls")
	arena._process(0.0)
	Input.action_release("controls")
	check(arena.controls_locked and not partner.use_healing_flask(), "Help screen pauses healing")
	arena.get_node("HUD/ControlsPanel").hide()
	arena.controls_locked = false
	player.healing_flasks = 0
	check(not player.use_healing_flask() and player.hp == 85, "Empty stock cannot heal")
	player.healing_flasks = 2
	player.invulnerable = 0
	player.take_hit(200, Vector2.ZERO)
	check(player.down and not player.use_healing_flask() and player.healing_flasks == 2, "Flasks do not replace cooperative revival")
	hud._process(0.0)
	check(primary.get_node("Health").value == 0 and primary.get_node("HealthValue").text == "CAÍDO", "Downed state is visible")
	for two in [true, false]:
		partner.ai_controlled = not two
		hud._process(0.0)
		for panel in [primary, secondary]:
			check(Rect2(Vector2.ZERO, Vector2(640, 360)).encloses(panel.get_global_rect()), "Panel remains within logical viewport")
			for other_path in ["HUD/Communicator", "HUD/Goal", "HUD/HelpButton", "HUD/Pieces"]:
				check(not panel.get_global_rect().intersects(arena.get_node(other_path).get_global_rect()), "HUD does not cover " + other_path)
	check(partner.hp == 80 and partner.healing_flasks == 3, "Returning to AI preserves progress")
	arena.free()
	var fresh = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(fresh)
	check(fresh.players[0].hp == 100 and fresh.players[0].healing_flasks == 5 and fresh.players[1].ai_controlled, "Restart uses default health, inventory and mode")
	fresh.free()
	if failures.is_empty():
		print("PASS: HUD solo/co-op, live stats, join preservation, heal inputs, AI healing, inventory, pause, downed state, restart and layout")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
