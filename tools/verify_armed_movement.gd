extends SceneTree
const Pose = preload("res://scripts/pixel_equipment_pose.gd")
var failures: Array[String] = []
var arena: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func step(player, dt: float = 1.0/60.0) -> void:
	await physics_frame
	player._physics_process(dt)
	for shot in arena.get_node("Projectiles").get_children(): shot.set_physics_process(false)
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
	for player in arena.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.collision_layer = 0
	for poses in [Pose.MAX_ARMED,Pose.AMANDA_ARMED]:
		for weapon in ["brush","bubbles"]:
			check(poses.get_frame_count(weapon+"_idle") == 8 and poses.get_frame_count(weapon+"_run") == 6,"Both weapons have dedicated whole-character idle and walking sprites")
			var distinct: Dictionary = {}
			for index in 6:
				var tex = poses.get_frame_texture(weapon+"_run",index)
				distinct[tex.region] = true
				check(tex.get_meta("draw_size").y <= 31 and tex.get_meta("foot_anchor").y <= 31,"Armed sprites keep the original small pixel scale and foot anchor")
			check(distinct.size() == 6,"Every walk phase uses a different newly drawn sprite")
	for player in arena.players:
		player.position = Vector2(240,230+player.player_id*80)
		player.equip_weapon("brush")
		var action := "p%d_attack" % player.player_id
		var seen: Array[int] = []
		var previous_combo := 0
		Input.action_press(action)
		for frame in 150:
			await step(player)
			if player.combo != previous_combo:
				seen.append(player.combo)
				previous_combo = player.combo
		check(seen == [1,2,3,1,2],"Holding F/J repeats the full three-hit sequence independently: "+str(seen))
		Input.action_release(action)
		var released_combo: int = player.combo
		for frame in 70: await step(player)
		check(player.attack_time <= 0 and player.combo == released_combo and not player.buffered,"Releasing held attack finishes the current stroke without another queued attack")
		player.equip_weapon("brush")
		arena.controls_locked = true
		Input.action_press(action)
		for frame in 3: await step(player)
		check(player.attack_time == 0 and player.combo == 0,"Holding attack cannot start a combo while paused")
		arena.controls_locked = false
		await step(player)
		check(player.combo == 1 and player.attack_time > 0,"Held attack resumes normally when gameplay unlocks")
		Input.action_release(action)
		player.equip_weapon("bubbles")
		player.position.x = 120
		for shot in arena.get_node("Projectiles").get_children(): shot.free()
		Input.action_press(action)
		for frame in 60: await step(player)
		Input.action_release(action)
		var shots: int = arena.get_node("Projectiles").get_child_count()
		check(shots == 4,"Slower automatic fire creates four shots in the first second: "+str(shots))
		for frame in 30: await step(player)
		check(arena.get_node("Projectiles").get_child_count() == shots,"Releasing fire stops new bubbles")
	if failures.is_empty(): print("PASS: new armed sprites, six walking phases, native pixel size/anchors, F/J held three-hit loops, release/paused behavior, slower automatic bubble fire")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)

