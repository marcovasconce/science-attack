extends SceneTree
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.get_node("WakeSequence").seek(3.6, true)
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	arena.tutorial.step = 6
	arena.open_limit = 1230
	for p in arena.players: p.set_physics_process(false)
	var player = arena.players[0]
	var partner = arena.players[1]
	var site = arena.get_node("BuildSite")
	site.set_process(false)
	partner.position = Vector2(510, 280)
	await physics_frame
	for y in [192, 250, 326]:
		player.position = Vector2(550, y)
		player.collision_mask = 1 # Same world collision retained during jump/dash.
		var collision = player.move_and_collide(Vector2(260, 0))
		check(collision != null and collision.get_collider() == arena.get_node("Gate"), "Unbuilt gap must block the whole walkable depth")
		check(player.position.x < 580, "Player must remain on the near bank")
	player.position = Vector2(530, 250)
	partner.position = Vector2(510, 280)
	arena.collect_parts(7, Vector2(420, 275))
	arena.interact(player, 10.0)
	check(arena.build_progress == 0 and not arena.built, "Seven screws cannot build the bridge")
	arena.collect_parts(2, Vector2(470, 305))
	site._process(1.0)
	check("construction_bolts" in site.get_node("Pieces/Piece0").texture.resource_path, "Crate rewards must render as screws")
	arena.interact(player, 1.4)
	check(arena.get_node("Bridge/Deck0").visible and not arena.get_node("Bridge/Deck1").visible, "First section installs from the near bank")
	await physics_frame
	player.position = Vector2(550, 250)
	check(player.move_and_collide(Vector2(260, 0)) != null, "Partial bridge still prevents crossing")
	var retained: float = arena.build_progress
	arena._process(0.3)
	check(is_equal_approx(arena.build_progress, retained), "Releasing build retains progress")
	player.position = Vector2(530, 250)
	arena.interact(player, 1.1)
	check(arena.get_node("Bridge/Deck1").visible and not arena.get_node("Bridge/Deck2").visible, "Middle section appears second")
	arena.interact(player, 0.7)
	await physics_frame
	await physics_frame
	check(arena.built and arena.pieces == 1, "Completion consumes exactly eight screws")
	check(arena.get_node("Gate/Collision").disabled, "Completed bridge opens physical passage")
	check(arena.get_node("Bridge/Deck2").visible, "Final section joins far bank")
	player.position = Vector2(550, 250)
	check(player.move_and_collide(Vector2(260, 0)) == null and player.position.x > 760, "Player crosses the actual completed bridge")
	site.sample(1.0)
	check(site.get_node("Pieces/Piece8").position.is_equal_approx(arena.part_origins[8]), "Extra screws remain on the floor")
	for i in 3:
		var deck = arena.get_node("Bridge/Deck%d" % i)
		check(deck.texture is AtlasTexture and "metal_bridge" in deck.texture.atlas.resource_path, "Deck sections use the metal bridge art")
		check(not site.get_node("Blueprint").get_child(i).visible, "Construction guides disappear after assembly")
	var box = arena.get_node("HUD/Communicator")
	for two_players in [false, true]:
		partner.ai_controlled = not two_players
		arena._on_hud_layout_changed(two_players)
		for step in range(1, 7):
			arena.tutorial.step = step
			arena.tutorial.next_delay = 0.0
			arena.tutorial._process(0.0)
			await process_frame
			box._process(3.0)
			var message: Label = box.get_node("Message")
			var key: Label = box.get_node("Key")
			check(message.get_theme_font("font").font_name == "Press Start 2P", "Tutorial uses the opening's pixel font")
			check(message.position.y + message.size.y < key.position.y, "Tutorial text stays above key prompt")
			check(key.position.x + key.size.x <= box.size.x - 10, "Key prompt fits in both HUD layouts")
			check(message.get_line_count() <= 2, "Tutorial messages fit in two lines")
	check(not arena.has_node("LabFurniture") and not arena.has_node("Terminal"), "Reference furniture is removed")
	if failures.is_empty(): print("PASS: blocked gap at all depths, real crossing after assembly, staged steel bridge, eight screws, spare drops, pause/resume and intro-style tutorial in solo/co-op")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
