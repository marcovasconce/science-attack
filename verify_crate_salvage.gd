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
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	arena.tutorial.step = 4
	for player in arena.players: player.set_physics_process(false)
	var crate = arena.get_node("Breakables/Crate0")
	crate.freeze = true
	crate.set_process(false)
	var build = arena.get_node("BuildSite")
	build.set_process(false)
	var player = arena.players[0]
	check(crate.get_node("Sprite").frame == 0, "Box starts intact")
	check(crate.get_node("Sprite").hframes == 3 and crate.get_node("Sprite").vframes == 2, "Box reads six authored states")
	crate.take_hit(18, 1.0, player)
	check(crate.hp == 14 and crate.get_node("Sprite").frame == 1 and not crate.broken, "First hit leaves the visible damaged sprite")
	check(arena.pieces == 0, "Nonlethal hit does not duplicate loot")
	crate.take_hit(18, 1.0, player)
	await process_frame
	check(crate.broken and crate.visible and crate.get_node("Sprite").frame == 2, "Final hit starts the breakup instead of abruptly hiding the crate")
	check(crate.collision_layer == 0 and crate.get_node("Feet").disabled, "Breaking box immediately releases collision")
	check(arena.pieces == 3 and arena.part_origins.size() == 3, "Box drops three usable pieces")
	crate.take_hit(18, 1.0, player)
	check(arena.pieces == 3, "Broken box cannot grant loot twice")
	for frame in 4:
		crate.break_age = crate.BREAK_DURATION * (frame + 0.05) / 4.0
		crate.sample_visual()
		check(crate.get_node("Sprite").frame == frame + 2, "Four breakup frames play in order")
	arena.controls_locked = true
	var previous_age: float = crate.break_age
	crate._process(1.0)
	build._process(1.0)
	check(crate.break_age == previous_age and arena.part_drop_ages[0] == 0.0, "Help pause freezes breakup and flying loot")
	arena.controls_locked = false
	crate._process(crate.BREAK_DURATION)
	check(not crate.visible, "Crate disappears only after breakup completes")
	build._process(0.2)
	var piece: Sprite2D = build.get_node("Pieces/Piece0")
	check(piece.visible and piece.position.y < arena.part_origins[0].y, "Salvage is visibly airborne after dropping")
	check("construction_salvage" in piece.texture.resource_path, "Construction uses the detailed salvage atlas")
	build._process(1.0)
	check(piece.position.is_equal_approx(arena.part_origins[0]), "Loot lands at its ground position")
	check(build.get_node("Pieces/Piece1").frame == 1 and build.get_node("Pieces/Piece2").frame == 2, "Initial drops have different recognizable materials")
	for fragment in arena.get_node("Debris").get_children():
		check("construction_salvage" in fragment.get_node("Fragment").texture.resource_path, "Physical debris also uses the new detailed art")
	arena.collect_parts(7, Vector2(470, 285))
	build._process(1.0)
	check(build.get_node("Pieces").get_child_count() == 10 and build.get_node("Pieces/Piece9").visible, "Drops beyond eight remain visible")
	arena.tutorial.step = 6
	player.position = Vector2(525, 250)
	arena.players[1].position = Vector2(550, 250)
	arena.interact(player, 1.4)
	var flying: Sprite2D = build.get_node("Pieces/Piece3")
	check(flying.position.y < arena.part_origins[3].y and flying.z_index == 6, "Detailed parts fly along the construction arc")
	arena.interact(player, 2.0)
	check(arena.built and arena.pieces == 2, "Building consumes exactly eight pieces")
	build.sample(1.0)
	check(build.get_node("Pieces/Piece9").position.is_equal_approx(arena.part_origins[9]), "Unused salvage stays on the ground after building")
	check(arena.tutorial.MESSAGES[4].contains("metálica"), "Tutorial describes the new box")
	var burst = arena.spawn_impact(1, Vector2(300, 220), 1.0)
	check(burst.lifetime == 0.28 and burst.frames.size() == 6, "Replacement enemy star has a snappy six-frame animation")
	arena.free()
	if failures.is_empty(): print("PASS: crate damage and breakup, collision, one-time loot, detailed parts, drop/landing, pause, extra salvage, construction and replacement hit star")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
