extends SceneTree
const Germ = preload("res://scenes/actors/germ.tscn")
const Armed = preload("res://assets/animations/max_armed_poses.tres")
var failures: Array[String] = []
var arena: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func step(player) -> void:
	await physics_frame
	player._physics_process(1.0/60.0)
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
	for player in arena.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.collision_layer = 0
	var penultimate: AtlasTexture = Armed.get_frame_texture("bubbles_run",4)
	var last: AtlasTexture = Armed.get_frame_texture("bubbles_run",5)
	check(penultimate.region.end.x > 1152 and last.region.position.x >= 1298,"Walking gun retains the full previous muzzle and excludes it from the final frame")
	for wave_index in 2:
		arena.spawn_wave()
		var green_count := 0
		var red_count := 0
		for germ in get_nodes_in_group("germs"):
			germ.set_physics_process(false)
			if germ.variant == "red":
				red_count += 1
				check(germ.hp == 260 and germ.get_node("Health").max_value == 260,"Red health doubled to 260 with a full health bar")
				germ.take_hit(130,0)
				check(not germ.dead and germ.hp == 130,"Red germ survives damage that kills the standard green")
			else:
				green_count += 1
				check(germ.hp == 130,"Green health doubled to 130")
			var frames: Dictionary = {}
			for frame in 6:
				germ.pixel_visual.sync(frame*0.125+0.01,false)
				frames[germ.pixel_visual.frame] = true
			check(frames.size() == 4,"Both variants cycle four distinct facial animation frames")
			germ.pixel_visual.sync(0.01,false)
			var initial_time: float = germ.pixel_visual.pose.motion_time
			germ.pixel_visual.sync(0.06,false)
			check(germ.pixel_visual.frame==0 and germ.pixel_visual.pose.motion_time>initial_time,"Breathing advances between facial poses instead of holding the body still")
			var initial_phase: float = germ.phase
			arena.controls_locked = true
			germ._physics_process(0.1)
			check(germ.phase==initial_phase,"Germ animation pauses with gameplay")
			arena.controls_locked = false
			germ.free()
		check(red_count == 1 and green_count == 3+wave_index,"Wave contains one rarer red and three/four green germs")
	var tutorial_germ = Germ.instantiate()
	tutorial_germ.hp = 72
	arena.get_node("Actors").add_child(tutorial_germ)
	tutorial_germ.set_physics_process(false)
	check(tutorial_germ.hp == 72 and tutorial_germ.max_hp == 72,"Intro enemy keeps its increased tutorial health")
	tutorial_germ.free()
	for player in arena.players:
		for weapon in ["none","brush","bubbles"]:
			if weapon != "none": player.equip_weapon(weapon)
			else: player.equipped_weapon = "none"
			for facing in [-1.0,1.0]:
				player.position = Vector2(1920,player.player_id*55+235)
				player.facing = facing
				var start: Vector2 = player.position
				var action := "p%d_dodge" % player.player_id
				Input.action_press(action)
				await step(player)
				Input.action_release(action)
				for frame in 5: await step(player)
				check(player.dash_visual.ghosts.size() > 0 and absf(player.get_node("Visual").rotation) > 0.05,"P1/P2 dash has visible lean and short afterimages with each weapon, both directions")
				arena.controls_locked = true
				var remaining: float = player.dash
				var age: float = player.dash_visual.ghosts[0].age
				await step(player)
				check(player.dash == remaining and player.dash_visual.ghosts[0].age == age,"Dash visuals freeze together with paused movement")
				arena.controls_locked = false
				for frame in 24: await step(player)
				check(player.dash <= 0 and player.dash_visual.ghosts.is_empty() and player.get_node("Visual").rotation == 0,"Dash restores normal stance and clears its trails")
				check(absf(player.position.x-start.x) > 55 and absf(player.position.x-start.x) < 80,"Visual update preserves original dash distance")
	if failures.is_empty(): print("PASS: green/red 130/260 health, 72 tutorial health, smooth breathing, facial poses, pause, waves and dash regression")
	else:
		for message in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
