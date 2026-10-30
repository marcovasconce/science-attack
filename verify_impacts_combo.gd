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
	arena.tutorial.step = 7
	arena.controls_locked = false
	arena.open_limit = 1230
	arena.get_node("WakeSequence").pause()
	for actor in arena.players: actor.set_physics_process(false)
	var player = arena.players[0]
	var partner = arena.players[1]
	var fx = arena.get_node("ImpactEffects")
	var crate = arena.get_node("Breakables/Crate0")
	crate.freeze = true
	player.position = crate.position - Vector2(30, 0)
	player.facing = 1
	var targets: Array = []
	arena.strike(player, 1, targets)
	check(crate.hp == 14 and fx.get_child_count() == 1, "A nonlethal crate hit emits a blue impact")
	var blue = fx.get_child(0)
	blue.set_process(false)
	check(blue.kind == 0 and blue.frames.size() == 6, "Crate effect has six sprite frames")
	arena.strike(player, 1, targets)
	check(fx.get_child_count() == 1 and crate.hp == 14, "Same swing cannot duplicate impact or damage")
	targets.clear()
	arena.strike(player, 1, targets)
	check(crate.broken and fx.get_child_count() == 2, "Destruction still shows its impact")
	check(player.hit_combo == 0, "Crates do not inflate the enemy hit combo")
	var enemy = arena.GermScene.instantiate()
	enemy.hp = 1000
	enemy.position = Vector2(300, 260)
	arena.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	player.position = Vector2(270, 260)
	targets.clear()
	arena.strike(player, 1, targets)
	check(player.hit_combo == 1 and fx.get_child_count() == 3, "Enemy hit increments the attacker's counter and emits one effect")
	var fire = fx.get_child(2)
	fire.set_process(false)
	check(fire.kind == 1 and fire.frames.size() == 6, "Enemy uses the new white-yellow star animation")
	check(fire.global_position.is_equal_approx(Vector2(288, 236)), "Impact stays at contact before enemy knockback")
	arena.strike(player, 1, targets)
	check(player.hit_combo == 1 and fx.get_child_count() == 3, "One target counts once per swing")
	player.update_hit_combo(4.9)
	player.start_attack()
	check(player.hit_combo == 1 and player.combo_idle_time == 0, "Starting an attack renews the timeout without adding a hit")
	player.update_hit_combo(5.0)
	check(player.hit_combo == 1, "Combo survives exactly five seconds")
	player.update_hit_combo(0.01)
	check(player.hit_combo == 0, "Combo expires after more than five seconds without attacking")
	player.register_combo_hit()
	partner.register_combo_hit()
	partner.register_combo_hit()
	player.invulnerable = 1
	player.take_hit(10, Vector2.ZERO)
	check(player.hit_combo == 1, "Invulnerability does not erase combo")
	player.invulnerable = 0
	player.take_hit(10, Vector2.ZERO)
	check(player.hit_combo == 0 and partner.hit_combo == 2, "Actual damage erases only the hurt player's combo")
	player.register_combo_hit()
	arena.controls_locked = true
	player.update_hit_combo(20.0)
	var age_before: float = blue.age
	blue._process(1.0)
	check(player.hit_combo == 1 and blue.age == age_before, "Pause freezes both combo and visual effect")
	arena.controls_locked = false
	for effect in [blue, fire]:
		for frame in 6:
			effect.sample((frame + 0.1) * effect.lifetime / 6.0)
			check(effect.frame_index == frame, "All frames play in chronological order")
			var region: Rect2 = effect.frames[frame].region
			check(region.position == Vector2((frame % 3) * 512, (frame / 3) * 512), "Atlas cells use exact aligned grid regions")
			effect._process(0.0)
	blue._process(blue.lifetime)
	check(blue.is_queued_for_deletion(), "Finished effects clean themselves up")
	var hud = arena.get_node("HUD/TeamHUD")
	hud.set_process(false)
	for two_players in [true, false, true]:
		partner.ai_controlled = not two_players
		hud._process(0.2)
		check(player.hit_combo == 1 and partner.hit_combo == 2, "Mode switches preserve individual counters")
		for panel_name in ["Primary", "Partner"]:
			var panel = hud.get_node(panel_name)
			check(panel.size.x < 248 and panel.size.y < 68, "HUD size is slightly reduced")
			var counter: Label = panel.get_node("HitCombo")
			check(counter.visible == not panel.compact, "Only full human panels show their combo")
			if not counter.visible: continue
			check(counter.text == ("x1" if panel_name == "Primary" else "x2"), "Each label reads its player's count")
			check(not counter.get_global_rect().intersects(arena.get_node("HUD/Communicator").get_global_rect()), "Counter does not cover tutorial")
			check(Rect2(0, 0, 640, 360).encloses(counter.get_global_rect()), "Counter stays inside the screen")
	check(not arena.has_node("HUD/Combo"), "Old HITS label removed")
	enemy.hp = 1
	enemy.position = Vector2(300, 260)
	player.position = Vector2(270, 260)
	targets.clear()
	arena.strike(player, 1, targets)
	var final_burst = fx.get_child(fx.get_child_count() - 1)
	final_burst.set_process(false)
	await process_frame
	check(not is_instance_valid(enemy) and is_instance_valid(final_burst), "Finishing effect survives deletion of the enemy")
	arena.free()
	if failures.is_empty(): print("PASS: smaller HUD, individual yellow combos, timeout, damage, invulnerability, pause, mode changes, real impacts, six frames and cleanup")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
