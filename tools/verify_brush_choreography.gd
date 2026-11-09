extends SceneTree
const Motion = preload("res://scripts/brush_motion.gd")
const Pose = preload("res://scripts/pixel_equipment_pose.gd")
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
	for actor in arena.players: actor.set_physics_process(false)
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
	var p = arena.players[0]
	arena.players[1].position = Vector2(60,320)
	p.equip_weapon("brush")
	p.position = Vector2(200,260)
	check(Pose.BRUSH_RECT.size == Vector2(34,8),"The brush is about 20% shorter and narrower")
	for animation in Motion.ANGLES:
		var count: int = p.sprite.sprite_frames.get_frame_count(animation)
		check(count == Motion.ANGLES[animation].size() and count == Motion.LEAN[animation].size(),"Body, weapon and combat timelines have matching frame counts")
		var atlas_paths: Dictionary = {}
		for i in count:
			var texture = p.sprite.sprite_frames.get_frame_texture(animation,i)
			atlas_paths[texture.atlas.resource_path] = true
		check(atlas_paths.size() >= 3 if animation != "brush_air" else true,"Ground swings animate stepping, crouching and recovery with multiple original poses")
	# Sample the real player loop at 60Hz; camera/body effects never teleport the collider.
	for combo_index in 3:
		p.facing = 1
		p.start_attack()
		var start: Vector2 = p.position
		var name: String = p.brush_animation()
		while p.attack_time > 0:
			await physics_frame
			p._physics_process(1.0/60.0)
		check(absf(p.position.x-start.x-float(Motion.STEP_DISTANCE[name][-1])) < 0.1,"Each choreographed step travels its planned distance at 60Hz: %s travelled %.3f" % [name,p.position.x-start.x])
		check(absf(p.position.y-start.y) < 0.01,"A brush step never changes the depth lane")
	p.chain_grace = 0
	p.facing = -1
	p.start_attack()
	var left_start: float = p.position.x
	while p.attack_time > 0:
		await physics_frame
		p._physics_process(1.0/60.0)
	check(absf(p.position.x-left_start+16) < 0.1,"The forward step mirrors correctly to the left")
	p.position = Vector2(560,260)
	p.facing = 1
	arena.get_node("Gate/Collision").disabled = false
	await physics_frame
	p.chain_grace = 0
	p.start_attack()
	while p.attack_time > 0:
		await physics_frame
		p._physics_process(1.0/60.0)
	check(p.position.x <= 561.1,"The unbuilt gap blocks the attack's forward step")
	# A separate wall verifies kinematic collision independently of arena limits.
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.position = Vector2(400,260)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12,120)
	collision.shape = shape
	wall.add_child(collision)
	arena.add_child(wall)
	p.position = Vector2(380,260)
	await physics_frame
	p.chain_grace = 0
	p.start_attack()
	while p.attack_time > 0:
		await physics_frame
		p._physics_process(1.0/60.0)
	check(p.position.x <= 385.1,"The attack step stops at solid walls")
	p.position = Vector2(200,260)
	p.start_attack()
	p._physics_process(0.12)
	var frozen: Vector2 = p.position
	var frozen_time: float = p.attack_time
	arena.controls_locked = true
	p._physics_process(1.0)
	check(p.position == frozen and p.attack_time == frozen_time,"Menu pause freezes choreography and its displacement together")
	arena.controls_locked = false
	p.invulnerable = 0
	p.take_hit(1,Vector2(100,260))
	check(p.attack_time == 0 and not p.buffered,"Taking damage cancels the brush's step and queued continuation")
	var hurt_at: Vector2 = p.position
	p._physics_process(0.1)
	check(p.position == hurt_at,"A hurt player does not continue lunging")
	if failures.is_empty(): print("PASS: smaller brush, coordinated original body poses, 60Hz combo stepping, left mirror, no lane drift, solid-wall/gap collision, pause and damage cancellation")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
