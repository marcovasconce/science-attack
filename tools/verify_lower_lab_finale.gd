extends SceneTree
var stage
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.finale.set_process(false)
	stage.elevator._physics_process(3)
	var p = stage.players[0]
	var q = stage.players[1]
	for player in stage.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	var finale = stage.finale
	check(stage.elevator.get_node("ShaftDetails").visible,"Lower elevator retains structural backing and rails")
	check(stage.world_limit == 5680 and stage.get_node("Environment/Floor4").visible,"The full extension has floor, wall and collision coverage")
	var crates: Array = stage.get_node("Breakables").get_children().filter(func(crate): return not crate.drops_salvage)
	check(crates.size() == 9,"Nine breakable healing crates populate random safe slots")
	var points: Array[Vector2] = []
	for crate in crates:
		points.append(crate.position)
		crate.freeze = true
		check(crate.position.x > 800 and crate.position.x < 3900 and not crate.drops_salvage,"Supply crates use the corridor and do not drop construction parts")
	crates[0].loot_roll = 0.4999
	crates[1].loot_roll = 0.5
	crates[0].take_hit(99,1,p)
	crates[0].take_hit(99,1,p)
	crates[1].take_hit(99,1,p)
	check(get_nodes_in_group("healing_pickups").size() == 1,"The exact 50% boundary produces one potion and repeated hits do not reroll")
	var pickup = get_first_node_in_group("healing_pickups")
	pickup.set_process(false)
	p.position = pickup.position
	q.position = p.position+Vector2(90,0)
	var flasks: int = p.healing_flasks
	pickup._process(0.8)
	pickup._process(0.1)
	check(p.healing_flasks == flasks+1 and pickup.collected,"Walking onto the potion adds exactly one healing flask")
	for crate in crates: crate.free()
	stage._spawn_supplies()
	var changed := false
	for crate in stage.get_node("Breakables").get_children():
		if crate.position not in points: changed = true
	check(changed,"New supply spawns select fresh positions")
	# A nine-cycle has a known minimum of eight transpositions; verify all tiles displaced.
	var misplaced := 0
	for i in 9:
		if stage.puzzle.tiles[i] != i: misplaced += 1
	var visited: Array[int] = []
	var next := 0
	while next not in visited:
		visited.append(next)
		next = stage.puzzle.tiles[next]
	check(misplaced == 9 and visited.size() == 9,"Harder puzzle needs eight swaps with no piece initially correct")
	var saved: Array = stage.puzzle.tiles.duplicate()
	stage.puzzle.open(0)
	stage.puzzle.close(false)
	stage.puzzle.open(0)
	check(stage.puzzle.tiles == saved,"Reopening preserves puzzle progress rather than rerolling")
	stage.puzzle.close(false)
	# Check actual solid geometry even while jumping, independently of position clamps.
	p.position = Vector2(1000,260)
	p.jump_height = 40
	await physics_frame
	p.move_and_collide(Vector2(180,0))
	check(p.position.x < 1045,"The swarm barrier stops a jumping player from advancing")
	check(stage.swarm_barrier.collision_layer == 16 and p.get_collision_mask_value(5),"The invisible boundary uses the shared actor barrier layer")
	p.jump_height = 0
	p.position = Vector2(970,260)
	var passing_flyer = load("res://scenes/actors/flying_bacterium.tscn").instantiate()
	passing_flyer.position = Vector2(1010,260)
	passing_flyer.speed = -200
	stage.get_node("Actors").add_child(passing_flyer)
	passing_flyer.set_physics_process(false)
	await physics_frame
	passing_flyer._physics_process(0.4)
	check(passing_flyer.position.x < 1037,"A swarm flyer cannot cross the active invisible barrier")
	passing_flyer.speed = 200
	p.position = Vector2(1000,260)
	p.hp = 100
	p.invulnerable = 0
	passing_flyer._physics_process(0.3)
	check(passing_flyer.position.x < 1010 and p.hp == 94,"Flyers remain inside the combat area and can still hit players")
	passing_flyer.free()
	p.position = Vector2(1025,260)
	finale.set_wall(stage.swarm_barrier,false)
	await physics_frame
	p.move_and_collide(Vector2(120,0))
	check(p.position.x > 1100,"Swarm completion releases the invisible barrier")
	check(not stage.amanda_hint.visible and not stage.amanda_hint.shown,"Amanda's hint waits for the relevant flying enemy")
	stage.amanda_hint.announce()
	var hint_time: float = stage.amanda_hint.remaining
	stage.amanda_hint.announce()
	check(stage.amanda_hint.visible and not stage.controls_locked and stage.amanda_hint.remaining == hint_time,"Amanda's short hint is nonblocking and appears only once")
	stage.amanda_hint._process(5)
	check(not stage.amanda_hint.visible,"Amanda's hint clears automatically")
	p.jump_height = 0
	p.position = finale.locker_at+Vector2(0,52)
	check(not finale.interact(p) and not finale.soap_taken,"Soap cannot be taken before the post-puzzle enemies are defeated")
	stage.beat = stage.Beat.FINISHED
	q.position = Vector2(3080,280)
	finale._process(0.01)
	await physics_frame
	check(finale.state == finale.State.READY and finale.locker.material == null and finale.mixed_wall.collision_layer == 0,"Defeating the mixed group opens the route to discover the blockage")
	p.position = Vector2(3310,270)
	finale._process(0.01)
	check(not finale.interact(p) and not finale.cleaned,"The slime cannot be cleaned without soap")
	p.move_and_collide(Vector2(350,0))
	check(p.position.x < 3350,"Contamination physically blocks every lane of the corridor")
	p.position = finale.locker_at+Vector2(0,52)
	check(finale.interact(p) and finale.has_soap and finale.soap_taken,"E at the locker takes the shared soap")
	check(not finale.interact(p),"The locker cannot dispense duplicate soap")
	p.position = Vector2(3310,270)
	finale._process(0.01)
	check(finale.interact(p) and stage.controls_locked and finale.state == finale.State.CLEANING,"E at the contaminated area starts the cleaning animation")
	finale._process(1.5)
	check(not finale.cleaned and finale.slime_wall.collision_layer == 16,"Collision remains until the foam animation finishes")
	finale._process(1.51)
	await physics_frame
	check(finale.cleaned and not finale.has_soap and not stage.controls_locked and finale.slime_wall.collision_layer == 0,"Finished cleaning consumes soap, removes the blockage and restores controls")
	p.move_and_collide(Vector2(260,0))
	check(p.position.x > 3510,"Players can physically walk through the cleaned passage")
	q.position = Vector2(3700,300)
	p.position = Vector2(4050,260)
	finale._process(0.01)
	var boss = finale.boss
	boss.set_physics_process(false)
	await physics_frame
	check(finale.state == finale.State.RUMBLE and stage.controls_locked and stage.shake_remaining > 0,"Advancing triggers the camera rumble before the mini boss")
	check(q.position.x > finale.LEFT and finale.left_barrier.collision_layer == 16 and finale.right_barrier.collision_layer == 16,"Both characters enter before the arena seals on both sides")
	finale._process(1.2)
	check(finale.state == finale.State.INTRO and boss.visible and finale.boss_hud.intro,"Mini boss appears with its brief dialogue and portrait health bar")
	finale.start_fight()
	check(boss.state == boss.State.WINDUP and not stage.controls_locked,"The boss immediately prepares the first shield charge after speaking")
	finale.rng.seed = 421337
	for i in 200:
		finale.drop_tnt()
		for crate in get_nodes_in_group("boss_tnt"): crate.free()
	check(finale.impacts == 200 and finale.tnt_drops >= 35 and finale.tnt_drops <= 65,"TNT appears on about one quarter of the boss attacks")
	finale.impacts = 0
	finale.tnt_drops = 0
	finale.rng.seed = 421337
	p.position = boss.position-Vector2(50,0)
	p.facing = 1
	p.equip_weapon("brush")
	var hp_before: int = boss.hp
	stage.strike(p,1,[])
	check(boss.hp < hp_before and boss.state == boss.State.WINDUP,"Real brush attacks damage the boss without cancelling its windup")
	p.equip_weapon("bubbles")
	p.position = boss.position-Vector2(150,0)
	hp_before = boss.hp
	var shot = stage.spawn_bubble(p)
	shot.set_physics_process(false)
	shot._physics_process(0.6)
	check(boss.hp < hp_before and shot.popping,"Real soap projectiles can hit the shield boss")
	shot.free()
	hp_before = boss.hp
	stage.special_area(p,boss.position,80,30,30)
	check(boss.hp == hp_before-3,"Frontal area specials respect the shield's 90% damage reduction")
	check(boss.state != boss.State.SHIELD_BASH,"Repeated distant attacks do not trigger the close-range shield push")
	p.position = boss.position-Vector2(60,0)
	q.position = boss.position+Vector2(180,40)
	boss.state = boss.State.RECOVER
	boss.age = 0
	boss.close_times.clear()
	for i in 16: boss._physics_process(0.1)
	check(boss.state == boss.State.SHIELD_BASH,"Sustained close proximity triggers the shield push")
	p.hp = 100
	p.invulnerable = 0
	boss._physics_process(0.37)
	check(p.hp == 94 and p.push_velocity.x < 0,"The shield push deals only six damage and pushes away from the boss")
	var age_before: float = boss.age
	stage.controls_locked = true
	boss._physics_process(2)
	check(boss.age == age_before,"Boss telegraphs pause during a modal or help screen")
	stage.controls_locked = false
	p.push_velocity = Vector2.ZERO
	p.position = Vector2(3980,260)
	p.jump_height = 40
	p.move_and_collide(Vector2(-180,0))
	check(p.position.x > finale.LEFT+10,"West boss wall cannot be crossed with a jump")
	p.position = Vector2(finale.RIGHT-40,260)
	p.move_and_collide(Vector2(180,0))
	check(p.position.x < finale.RIGHT-10,"East boss wall cannot be crossed with a jump")
	p.jump_height = 0
	p.position = Vector2(4200,280)
	p.hp = 100
	p.invulnerable = 0
	boss.position.y = 280
	boss.wind_up()
	boss._physics_process(1.06)
	check(boss.state == boss.State.CHARGE,"The visible charge-up leads into a shield dash")
	boss._physics_process(1.5)
	check(boss.state == boss.State.IMPACT and boss.position.x == finale.LEFT+62,"The shield charge reaches the opposite wall without overshooting")
	check(p.hp == 77,"Swept shield damage catches a player even across a long physics step")
	check(finale.impacts == 1 and get_nodes_in_group("boss_tnt").size() in [0,3] and stage.shake_remaining > 0,"The wall impact shakes the screen and only sometimes drops TNT")
	while get_nodes_in_group("boss_tnt").is_empty(): finale.drop_tnt()
	var bombs: Array = get_nodes_in_group("boss_tnt")
	for bomb in bombs:
		bomb.set_physics_process(false)
		check(bomb.position.x > finale.LEFT+45 and bomb.position.x < finale.RIGHT-45 and bomb.position.y >= 213 and bomb.position.y <= 317,"Every TNT landing zone stays inside the arena")
	var bomb = bombs[0]
	check(not bomb.landed and bomb.height > 0,"TNT starts above the marked floor position")
	for i in 15: bomb._physics_process(0.1)
	check(bomb.landed and not bomb.broken,"TNT falls and stays intact on the floor")
	boss.position = bomb.position
	p.position = bomb.position
	p.invulnerable = 0
	p.hp = 100
	var old_hp: int = boss.hp
	bomb.take_hit(1,1,p)
	bomb.explode()
	check(bomb.broken and boss.hp == old_hp-320 and p.hp == 86,"Hitting landed TNT explodes once and bypasses the boss shield")
	boss.take_explosion(500)
	check(boss.hp < boss.LAYER_HP and not boss.dead,"Exhausting the orange layer continues on the red health layer")
	boss.position = Vector2(finale.LEFT+62,280)
	boss.wind_up()
	check(boss.direction == 1 and boss.sprite.flip_h,"The next charge turns to cross toward the other wall")
	var dodge: Vector2 = finale.ai_destination(q,Vector2(4300,280))
	q.position.y = boss.position.y
	dodge = finale.ai_destination(q,Vector2(4300,280))
	check(absf(dodge.y-boss.position.y) >= 40,"The companion moves out of the telegraphed shield lane")
	boss.take_hit(9999,1)
	await process_frame
	check(finale.state == finale.State.DONE and stage.victory and not finale.boss_hud.visible,"Depleting red health wins the encounter and hides the boss bar")
	check(get_nodes_in_group("boss_tnt").is_empty() and finale.left_barrier.collision_layer == 0 and finale.right_barrier.collision_layer == 0,"Victory clears remaining TNT and releases both arena walls")
	var count: int = finale.impacts
	finale.drop_tnt()
	check(finale.impacts == count,"A defeated boss cannot spawn further TNT")
	p.hp = 3
	Input.action_press("restart")
	stage._process(0.01)
	Input.action_release("restart")
	for i in 4: await process_frame
	stage = current_scene
	check(stage.beat == stage.Beat.ARRIVAL and stage.finale.state == stage.finale.State.LOCKED and not stage.finale.cleaned and not stage.finale.soap_taken,"Actual F2 clears the completed boss and soap progression")
	check(stage.players[0].hp == 100 and get_nodes_in_group("boss_tnt").is_empty() and stage.get_node("Breakables").get_child_count() == 12,"Retry restores entry health, fresh supplies and an empty boss arena")
	print("PASS: " if failures.is_empty() else "FAIL: ",checks," lower-lab finale checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)


