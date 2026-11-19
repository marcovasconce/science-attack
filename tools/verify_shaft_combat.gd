extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage = load("res://scenes/gameplay/shaft_descent.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.auto_transfer = false
	for p in stage.players:
		p.ai_controlled = true
		p.max_hp = 1000
		p.hp = 1000
	Engine.time_scale = 6
	var escaped := false
	var max_count := 0
	while stage.ride != stage.Ride.TRANSFER:
		await physics_frame
		var germs: Array = get_nodes_in_group("germs")
		max_count = maxi(max_count,germs.size())
		for enemy in germs:
			if enemy.position.x < 59 or enemy.position.x > 581: escaped = true
		for p in stage.players:
			if p.position.x < 50 or p.position.x > 590: escaped = true
	Engine.time_scale = 1
	assert(not escaped,"Players and flying/ground enemies must stay on the moving platform")
	assert(max_count <= 8 and stage.spawned >= 10,"The actual battle has sustained waves with a safe simultaneous cap")
	assert(stage.defeated > 0,"Actual companion combat must be able to defeat attackers")
	assert(stage.composition.red > stage.composition.green and stage.composition.yellow > stage.composition.green,"Red and yellow enemies are more frequent than green")
	assert(stage.elapsed == 40 and get_nodes_in_group("germs").is_empty(),"The real-time battle clears enemies when the descent ends")
	# An actual retry restores the entry checkpoint, rather than elapsed time or spent potions.
	stage.players[0].healing_flasks = 0
	Input.action_press("restart")
	stage._process(0.01)
	Input.action_release("restart")
	for i in 4: await process_frame
	stage = current_scene
	assert(stage.elapsed == 0 and stage.spawned == 0 and stage.players[0].healing_flasks == 5,"F2 restarts the entire ride with its original entry inventory")
	stage.set_process(false)
	stage._process(1.2)
	for p in stage.players:
		p.set_physics_process(false)
		p.down = true
	var before: float = stage.elapsed
	stage._process(12)
	assert(stage.elapsed == before and stage.controls_locked,"A defeated party cannot finish the trip automatically")
	print("PASS: actual 40-second combat simulation, platform bounds, wave mix, AI kills, arrival cleanup, retry and party defeat")
	quit()
