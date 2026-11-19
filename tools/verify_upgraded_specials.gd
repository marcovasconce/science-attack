extends SceneTree
const Water = preload("res://scripts/pixel_water_effect.gd")
var failures: Array[String] = []
var arena: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	arena.encounter.unlock_route()
	arena.open_limit = 2230
	for actor in arena.players:
		actor.set_physics_process(false)
		actor.ai_controlled = false
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
	var p = arena.players[0]
	var partner = arena.players[1]
	var dummy = arena.get_node("Actors/TrainingDummy")
	var gate = arena.get_node("Gate/Collision")
	gate.disabled = true
	p.position = Vector2(1860,266)
	partner.position = Vector2(2000,266)
	p.equip_weapon("bubbles")
	p.facing = 1
	await physics_frame
	await process_frame
	p.energy = 75
	check(p.specials.try_activate() and p.energy == 25 and p.specials.kind == "bubbles1","Half-bar skill spends 50 and selects giant bubble")
	p.specials.tick(0.35)
	var shots = arena.get_node("Projectiles").get_children()
	check(shots.size() == 1 and shots[0].giant,"Half bar spawns one giant bubble")
	shots[0].set_physics_process(false)
	p.specials.tick(1.0)
	check(arena.get_node("Projectiles").get_child_count() == 1,"Half-bar skill does not repeat its projectile")
	shots[0]._physics_process(1.5)
	check(dummy.total_damage == 140 and p.energy == 25,"Giant bubble retains its area damage without energy refund")
	shots[0].free()
	dummy.total_damage = 0
	dummy.hits = 0
	p.energy = 100
	check(p.specials.try_activate() and p.energy == 0 and p.specials.kind == "bubbles2","Full bar selects beam and spends exactly 100")
	check(is_equal_approx(p.specials.duration-p.specials.BEAM_WINDUP,3.0),"Visible beam channel lasts three seconds after brief windup")
	p.specials.tick(0.24)
	check(dummy.hits == 0,"No invisible damage during windup")
	p.specials.tick(0.11)
	check(dummy.hits == 1 and dummy.total_damage == 30,"Damage starts once the jet opens")
	arena.controls_locked = true
	var paused: float = p.specials.elapsed
	p.specials.tick(2.0)
	check(p.specials.elapsed == paused and dummy.hits == 1,"Pausing freezes water animation and damage together")
	arena.controls_locked = false
	for frame in 174: p.specials.tick(1.0/60.0)
	check(not p.specials.active and is_equal_approx(p.specials.elapsed,3.25),"Beam ends after windup plus exactly three seconds at 60 Hz")
	check(dummy.hits == 20 and dummy.total_damage == 600,"Full beam has twenty controlled damage pulses (600 on stationary dummy)")
	check(p.energy == 0 and partner.hp == 100,"Beam never refunds energy or damages the other player")
	p.specials.tick(5)
	check(dummy.hits == 20 and not p.specials.water_display.visible,"No lingering beam or damage after ending")
	check(arena.defeated == 0 and arena.pieces == 0,"Training receives no enemy kills or salvage rewards")
	# A solid gap wall must clip both the visual beam and its damage.
	p.position = Vector2(500,266)
	dummy.position = Vector2(620,266)
	gate.disabled = false
	await physics_frame
	await process_frame
	p.energy = 100
	p.specials.try_activate()
	var previous: int = dummy.total_damage
	p.specials.tick(0.5)
	check(p.specials.beam_length < 40 and dummy.total_damage == previous,"Gate blocks the beam's range and damage")
	gate.disabled = true
	await physics_frame
	await process_frame
	p.specials.tick(0.15)
	check(p.specials.beam_length > 400 and dummy.total_damage > previous,"Beam reaches the same target when the wall is removed")
	p.specials.cancel()
	# Aim locks while braced; left-facing, lane and behind-player rules remain valid.
	p.position = Vector2(1000,266)
	dummy.position = Vector2(800,266)
	p.facing = -1
	p.energy = 100
	p.specials.try_activate()
	previous = dummy.total_damage
	p.specials.tick(0.35)
	check(dummy.total_damage == previous+30 and p.specials.water_display.scale.x == -2,"Beam damage and pixel art mirror left")
	var original_position: Vector2 = p.position
	Input.action_press("p0_right")
	Input.action_press("p0_attack")
	await physics_frame
	p._physics_process(0.05)
	Input.action_release("p0_right")
	Input.action_release("p0_attack")
	check(p.position == original_position and p.facing == -1 and arena.get_node("Projectiles").get_child_count() == 0,"Channel braces the player, locks aim and suppresses normal fire")
	dummy.position.y += 50
	previous = dummy.total_damage
	p.specials.tick(0.2)
	check(dummy.total_damage == previous,"Beam respects depth lanes")
	dummy.position = Vector2(1100,266)
	p.specials.tick(0.2)
	check(dummy.total_damage == previous,"Beam does not damage targets behind the player")
	p.equip_weapon("brush")
	check(not p.specials.active and not p.specials.water_display.visible,"Changing equipment clears beam visual and damage")
	# Brush's existing gameplay remains; the impact now gets a short world-only shake.
	p.position = Vector2(1940,266)
	dummy.position = Vector2(2000,266)
	dummy.total_damage = 0
	p.energy = 100
	p.specials.try_activate()
	var hud_position: Vector2 = arena.get_node("HUD/TeamHUD").position
	p.specials.tick(0.5)
	check(dummy.total_damage == 100 and arena.shake_remaining > 0 and p.specials.water_display.visible,"Brush impact keeps its damage and triggers splash plus shake")
	arena.update_camera_shake(0.05)
	check(arena.get_node("Camera2D").offset != Vector2.ZERO and arena.get_node("HUD/TeamHUD").position == hud_position,"Short shake moves world camera but leaves HUD fixed")
	var remaining: float = arena.shake_remaining
	arena.controls_locked = true
	arena.update_camera_shake(1.0)
	check(arena.shake_remaining == remaining,"Pause freezes shake timing")
	arena.controls_locked = false
	arena.update_camera_shake(0.5)
	check(arena.get_node("Camera2D").offset == Vector2.ZERO and arena.shake_remaining == 0,"Camera returns exactly to neutral after the short tremor")
	p.specials.tick(0.9)
	check(dummy.total_damage == 165 and not p.specials.active,"Brush ultimate retains both original area hits and duration")
	check(Water.BEAM.get_frame_count("effect") == 6 and Water.SPLASH.get_frame_count("effect") == 6,"Both water effects have six authored animation frames")
	# Upgrade-specific behavior is checked against the same stationary damage dummy.
	p.specials.cancel()
	p.equip_weapon("bubbles")
	p.weapon_upgraded = true
	p.position = Vector2(1860,266)
	p.facing = 1
	dummy.position = Vector2(2000,266)
	dummy.total_damage = 0
	dummy.hits = 0
	p.energy = 75
	check(p.specials.try_activate() and p.specials.kind == "bubbles_quick" and p.energy == 25,"Upgraded half bar selects quick beam and costs 50")
	p.specials.tick(0.119)
	check(dummy.hits == 0,"Quick beam has no pre-windup damage")
	p.specials.tick(0.111)
	check(dummy.hits == 1 and p.specials.beam_length <= 420 and p.specials.locks_aim(),"Quick beam clips range, braces aim and starts promptly")
	arena.controls_locked = true
	paused = p.specials.elapsed
	p.specials.tick(1)
	check(p.specials.elapsed == paused,"Quick beam pauses with game")
	arena.controls_locked = false
	p.specials.tick(1)
	check(not p.specials.active and dummy.hits == 6 and dummy.total_damage == 180,"Quick beam ends in 0.82 seconds with six pulses")
	check(p.energy == 25 and not p.specials.water_display.visible,"Quick beam charges once and cleans up")
	# Facing, obstacles and lanes still use the original beam's collision path.
	p.position = Vector2(500,266)
	dummy.position = Vector2(620,266)
	gate.disabled = false
	await physics_frame
	await process_frame
	p.energy = 50
	p.specials.try_activate()
	previous = dummy.total_damage
	p.specials.tick(0.3)
	check(p.specials.beam_length < 40 and dummy.total_damage == previous,"Quick beam cannot damage through a solid gate")
	p.specials.cancel()
	gate.disabled = true
	await physics_frame
	await process_frame
	p.equip_weapon("brush")
	p.weapon_upgraded = true
	p.position = Vector2(1700,266)
	dummy.position = Vector2(1810,310)
	dummy.total_damage = 0
	p.energy = 50
	p.specials.try_activate()
	p.specials.tick(0.05)
	check(dummy.total_damage == 10 and p.specials.water_display.visible and p.specials.water_canvas.mode == "brush1","Orange upgraded spin reaches wider radius and depth with visible effect")
	p.specials.cancel()
	p.weapon_upgraded = false
	p.energy = 50
	p.specials.try_activate()
	previous = dummy.total_damage
	p.specials.tick(0.05)
	check(dummy.total_damage == previous and not p.specials.water_display.visible,"Normal brush retains original smaller radius")
	p.specials.cancel()
	p.weapon_upgraded = true
	p.energy = 100
	dummy.position = Vector2(1812,266)
	p.specials.try_activate()
	p.specials.tick(0.8)
	check(p.specials.kind == "solar" and p.specials.water_canvas.TNT.resource_path.ends_with("tnt_explosion.png"),"Upgraded ultimate uses exact miniboss TNT animation")
	p.specials.cancel()
	if failures.is_empty(): print("PASS: upgraded quick beam, orange wider spin, TNT atlas, and original giant bubble at half energy, three-second full water beam, 600 damage/20 pulses, wall and lane clipping, left aim, bracing, pause, no friendly damage/refund, cancellation, dramatic brush splash and brief HUD-safe shake")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)

