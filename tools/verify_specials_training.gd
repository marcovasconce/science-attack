extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	for p in arena.players: p.set_physics_process(false)
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
	var dummy = arena.get_node("Actors/TrainingDummy")
	var p = arena.players[0]
	var partner = arena.players[1]
	check(not dummy.is_in_group("germs") and arena.nearest_enemy(dummy.position) == null,"Training dummy cannot block tutorial victory or attract combat AI")
	arena.encounter.unlock_route()
	await physics_frame
	await process_frame
	p.position = dummy.position-Vector2(60,0)
	partner.position = Vector2(1840,320)
	p.equip_weapon("brush")
	p.facing = 1
	check(InputMap.action_get_events("p0_special")[0].physical_keycode == KEY_Q,"Q activates P1 special")
	check(InputMap.action_get_events("p1_special")[0].physical_keycode == KEY_I,"I activates P2 special")
	check(InputMap.action_get_events("p0_heal")[0].physical_keycode == KEY_R,"Healing uses R independently from special Q")
	for actor in arena.players:
		for weapon in ["brush","bubbles"]:
			check(actor.sprite.sprite_frames.get_frame_count(weapon+"_idle") == 8 and actor.sprite.sprite_frames.get_animation_loop(weapon+"_idle"),"Each weapon has a breathing hold loop for each original avatar")
	var hp: int = p.hp
	var flasks: int = p.healing_flasks
	p.energy = 49
	check(not p.specials.try_activate() and p.energy == 49,"Under half a bar cannot activate or consume energy")
	p.energy = 75
	check(p.specials.try_activate() and p.specials.kind == "brush1" and p.energy == 25,"Between half and full uses the 50-energy special")
	check(not p.specials.try_activate() and p.energy == 25,"Active special cannot be retriggered or double charged")
	p.specials.cancel()
	p.energy = 50
	dummy.total_damage = 0
	dummy.hits = 0
	Input.action_press("p0_special")
	p._physics_process(0.01)
	Input.action_release("p0_special")
	check(p.specials.active and p.sprite.animation == &"brush_spin" and p.energy == 0,"Physical special action starts spin without healing or refilling energy")
	p.specials.tick(2.99)
	check(p.specials.active and is_equal_approx(p.specials.elapsed,3),"Spin is still active halfway through six seconds")
	arena.controls_locked = true
	p.specials.tick(3)
	check(is_equal_approx(p.specials.elapsed,3),"Menu pauses special duration and damage pulses")
	arena.controls_locked = false
	p.specials.tick(3)
	check(not p.specials.active and is_equal_approx(p.specials.elapsed,6),"Spin ends at six active seconds")
	check(dummy.hits == 15 and dummy.total_damage == 150,"Spin hits the persistent dummy on fifteen controlled pulses")
	check(p.energy == 0 and p.hp == hp and p.healing_flasks == flasks,"Special hits cannot recharge themselves or use healing inventory")
	check(arena.defeated == 0 and arena.pieces == 0 and not dummy.dead,"Dummy is immortal and gives no tutorial kills or building drops")
	dummy.prepare_training(p)
	check(p.energy == 100 and dummy.total_damage == 0,"Training interaction loads full energy and clears damage")
	dummy.prepare_training(p)
	check(p.energy == 50,"Training interaction can load exactly half a bar")
	p.energy = 100
	check(p.specials.try_activate() and p.specials.kind == "brush2" and p.energy == 0,"Full brush bar selects the distinct stronger attack and spends 100")
	p.specials.tick(1.4)
	check(dummy.total_damage == 165,"Strong brush waves deal more damage in a shorter burst")
	p.energy = 50
	p.specials.try_activate()
	for frame in 360: p.specials.tick(1.0/60.0)
	check(not p.specials.active and p.specials.elapsed == 6.0,"Six seconds of real 60 Hz updates end the spin without a floating-point extra frame")
	partner.ai_controlled = false
	partner.equip_weapon("bubbles")
	partner.energy = 50
	partner.position = dummy.position-Vector2(180,0)
	partner.facing = 1
	Input.action_press("p1_special")
	partner._physics_process(0.01)
	Input.action_release("p1_special")
	check(partner.specials.kind == "bubbles1" and partner.energy == 0 and p.energy == 0,"P2 independently starts the bubble special")
	partner.specials.tick(0.35)
	var shots = arena.get_node("Projectiles").get_children()
	check(shots.size() == 1 and shots[0].giant and shots[0].radius == 28,"Half bar now launches the giant bubble")
	shots[0].set_physics_process(false)
	partner.specials.cancel()
	var before: int = dummy.total_damage
	shots[0]._physics_process(1.0)
	check(dummy.total_damage == before+140 and shots[0].popping,"Giant bubble bursts once even after the cast ends")
	shots[0]._physics_process(0.05)
	check(dummy.total_damage == before+140 and partner.energy == 0,"Giant pop cannot damage twice or refill energy")
	shots[0].free()
	partner.energy = 100
	check(partner.specials.try_activate() and partner.specials.kind == "bubbles2","Full bubble bar selects the continuous water beam")
	before = dummy.total_damage
	partner.specials.tick(1.0)
	check(dummy.total_damage > before and partner.energy == 0 and partner.specials.active,"Water beam deals repeated damage without recharging")
	check(arena.get_node("Projectiles").get_child_count() == 0,"Full beam no longer launches the giant bubble")
	partner.equip_weapon("brush")
	check(not partner.specials.active,"Changing equipment clears an active special")
	p.energy = 100
	arena.controls_locked = true
	check(not p.specials.try_activate() and p.energy == 100,"No special can start in a modal")
	arena.controls_locked = false
	p.down = true
	check(not p.specials.try_activate() and p.energy == 100,"Downed players cannot activate specials")
	p.down = false
	var hud = arena.get_node("HUD/TeamHUD")
	var help_panel = arena.get_node("HUD/ControlsPanel")
	var keys = help_panel.get_node("Keys")
	check(keys.position.y+keys.get_combined_minimum_size().y <= help_panel.size.y,"All controls including special keys fit inside the help panel")
	for coop in [true,false]:
		partner.ai_controlled = not coop
		hud._process(0)
		for name in ["Primary","Partner"]:
			var panel = hud.get_node(name)
			var bar = panel.get_node("Special")
			var divider = panel.get_node("SpecialDivider")
			check(is_equal_approx(divider.position.x+divider.size.x*0.5,bar.position.x+bar.size.x*0.5),"Special divider is exactly centered in full and compact HUDs")
	if failures.is_empty(): print("PASS: weapon idles, Q/I vs H/O, energy thresholds and independence, six-second spin, controlled pulses, no self-refill, strong brush, both bubble specials, training dummy, pause/downed/cancel rules and HUD midpoint")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
