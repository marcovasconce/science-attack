extends SceneTree
var stage
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.finale.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.open_limit = 3140
	for p in stage.players:
		p.set_physics_process(false)
		p.ai_controlled = false
	var p = stage.players[0]
	stage.players[1].position = Vector2(2500,310)
	p.position = Vector2(3100,280)
	var fly = stage.YellowScene.instantiate()
	fly.position = Vector2(3120,280)
	stage.get_node("Actors").add_child(fly)
	fly.set_physics_process(false)
	fly.cooldown = 100
	for i in 90:
		await physics_frame
		fly._physics_process(1.0/60)
	check(fly.position.x < 3136 and fly.position.x > 3125,"High yellow flyer cannot retreat past the mixed encounter barrier")
	fly.take_hit(1,1)
	fly.knockback = 1000
	fly._physics_process(0.5)
	check(fly.position.x < 3136,"Even a large falling knockback cannot tunnel through the barrier")
	fly.flight = fly.Flight.LOW
	fly.state_age = 1
	fly.low_remaining = 10
	for i in 40:
		await physics_frame
		fly._physics_process(1.0/60)
	check(fly.position.x < 3136,"Low flight also stays inside the encounter")
	p.position = fly.position-Vector2(50,0)
	p.equip_weapon("brush")
	p.facing = 1
	var hp: int = fly.hp
	stage.strike(p,1,[])
	check(fly.hp < hp,"A flyer stopped by the wall stays reachable by the player's attacks")
	var west_wall = stage.finale.wall("FlyerRegressionWest",2800)
	fly.position = Vector2(2840,280)
	fly.flight = fly.Flight.HIGH
	fly.stun = 0
	p.position = Vector2(2870,280)
	for i in 90:
		await physics_frame
		fly._physics_process(1.0/60)
	check(fly.position.x > 2819 and fly.position.x < 2825,"The same collision works on the left side of a barrier")
	fly.take_hit(1,-1)
	fly.knockback = -1000
	fly._physics_process(0.5)
	check(fly.position.x > 2819,"Leftward knockback also respects the wall")
	stage.finale.set_wall(west_wall,false)
	await physics_frame
	fly.flight = fly.Flight.FALLING
	fly.flight_height = 76
	fly.fall_speed = 0
	fly._physics_process(0.1)
	check(fly.position.x < 2800,"Releasing a barrier genuinely reopens the path")
	fly.free()
	# Incoming swarm flies spawn inside the boundary and still reach the player.
	stage.beat = stage.Beat.WAVE
	stage.wave = 1
	stage.get_node("Camera2D").position.x = 1000
	p.position = Vector2(900,260)
	stage._spawn_flyer()
	var swarm = get_first_node_in_group("swarm_flyers")
	swarm.set_physics_process(false)
	check(swarm.position.x < stage.swarm_barrier.position.x-30,"Swarm spawn remains on the playable side even at the camera limit")
	swarm.lane_y = 260
	swarm.position.y = 260
	p.invulnerable = 0
	p.hp = 100
	await physics_frame
	swarm._physics_process(0.7)
	check(p.hp == 94 and swarm.position.x < p.position.x,"Incoming swarm still crosses the player's lane and deals contact damage")
	swarm.free()
	print("PASS: " if failures.is_empty() else "FAIL: ",checks," flyer barrier checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
