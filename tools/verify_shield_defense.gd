extends SceneTree
var stage
var boss
var finale
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func make_tnt(at: Vector2, landed := true):
	var bomb = finale.TNT.new()
	bomb.position = at
	bomb.target_boss = boss
	stage.add_child(bomb)
	bomb.set_physics_process(false)
	if landed:
		bomb.height = 0
		bomb._physics_process(0.01)
	return bomb
func clear_bombs() -> void:
	for bomb in get_nodes_in_group("boss_tnt"): bomb.free()
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	finale = stage.finale
	finale.set_process(false)
	stage.beat = stage.Beat.FINISHED
	finale.state = finale.State.OPEN
	finale.cleaned = true
	for player in stage.players:
		player.set_physics_process(false)
		player.ai_controlled = false
		player.position = Vector2(4100+player.player_id*60,315)
	finale.begin_boss()
	boss = finale.boss
	boss.set_physics_process(false)
	finale._process(1.2)
	check(finale.RIGHT-finale.LEFT == 800,"Arena is widened from 600 to 800 world pixels")
	stage._process(1)
	var camera = stage.get_node("Camera2D")
	check(is_equal_approx(camera.zoom.x,0.78) and camera.position.x == finale.CENTER,"Camera widens to show both arena boundaries")
	var idle_frames: Array[int] = []
	for i in 4:
		boss._physics_process(1.0/6)
		idle_frames.append(boss.sprite.frame)
	check(idle_frames == [1,2,3,0] and boss.sprite.texture == boss.ART,"Four drawn idle poses loop even during the introduction")
	check(stage.controls_locked and not boss.combat_active,"Idle animation during speech does not start combat early")
	finale.start_fight()
	var p = stage.players[0]
	var q = stage.players[1]
	boss.position = Vector2(finale.CENTER,270)
	boss.direction = -1
	var hp: int = boss.hp
	p.position = boss.position-Vector2(60,0)
	stage.damage_enemy(p,boss,100,1,boss.position)
	check(boss.hp == hp-10,"A frontal left-facing shield hit receives only ten percent damage")
	check(get_nodes_in_group("shield_block_fx").size() == 1,"Blocked attacks spawn the special shield impact animation")
	hp = boss.hp
	p.position = boss.position+Vector2(60,0)
	stage.damage_enemy(p,boss,100,-1,boss.position)
	check(boss.hp == hp-100 and get_nodes_in_group("shield_block_fx").size() == 1,"A back hit deals full damage without a shield flash")
	boss.direction = 1
	hp = boss.hp
	stage.damage_enemy(p,boss,100,-1,boss.position)
	check(boss.hp == hp-10,"The shield protection mirrors when the boss faces right")
	p.position = boss.position-Vector2(60,0)
	hp = boss.hp
	stage.damage_enemy(p,boss,100,1,boss.position)
	check(boss.hp == hp-100,"The mirrored back remains vulnerable")
	boss.hp = boss.MAX_HP
	boss.direction = -1
	p.position = boss.position-Vector2(150,0)
	p.facing = 1
	p.equip_weapon("bubbles")
	var shot = stage.spawn_bubble(p)
	shot.set_physics_process(false)
	# Move the shooter after launch: contact side must be taken from the projectile.
	p.position = boss.position+Vector2(90,0)
	shot._physics_process(0.5)
	check(boss.hp == boss.MAX_HP-1 and shot.popping,"A projectile launched at the shield stays blocked if its shooter moves behind")
	shot.free()
	p.position = boss.position+Vector2(150,0)
	p.facing = -1
	shot = stage.spawn_bubble(p)
	shot.set_physics_process(false)
	p.position = boss.position-Vector2(90,0)
	hp = boss.hp
	shot._physics_process(0.5)
	check(boss.hp == hp-10 and shot.popping,"A projectile from the back keeps full damage if its shooter crosses to the front")
	shot.free()
	p.position = boss.position-Vector2(80,0)
	hp = boss.hp
	stage.water_beam_damage(p,1,300,100)
	check(boss.hp == hp-10,"The frontal water beam obeys shield defense")
	p.position = boss.position+Vector2(80,0)
	hp = boss.hp
	stage.special_area(p,p.position,120,35,100)
	check(boss.hp == hp-100,"A rear area special deals full damage")
	var bomb = make_tnt(Vector2(finale.CENTER,310),false)
	check(not bomb.is_in_group("medical_supplies"),"An airborne TNT cannot block ground weapon attacks")
	bomb.take_hit(100,1,p)
	check(not bomb.broken,"An attack cannot detonate TNT before it lands")
	for i in 18: bomb._physics_process(0.1)
	check(bomb.landed and bomb.is_in_group("medical_supplies"),"TNT becomes a weapon target when it reaches the floor")
	bomb._physics_process(60)
	check(not bomb.broken,"TNT never detonates from elapsed time, even after sixty seconds")
	p.position = bomb.position
	bomb._physics_process(0.2)
	check(not bomb.broken,"Walking onto a landed TNT does not detonate it")
	var untouched = make_tnt(bomb.position+Vector2(20,0))
	boss.position = bomb.position+Vector2(40,0)
	boss.direction = -1
	boss.hp = boss.MAX_HP
	p.position += Vector2(180,0)
	q.position = p.position+Vector2(60,0)
	bomb.take_hit(1,1,p)
	bomb.take_hit(1,1,p)
	check(boss.hp == boss.MAX_HP-320 and bomb.broken,"A player-triggered blast damages the shield side for 320 exactly once")
	check(not untouched.broken,"Explosions do not chain-detonate untouched TNT")
	check(get_nodes_in_group("tnt_explosion_fx").size() == 1,"The new eight-frame explosion plays once per TNT")
	clear_bombs()
	# Swept charge contact resolves damage at the collision, not at the final endpoint.
	boss.hp = boss.MAX_HP
	boss.position = Vector2(finale.RIGHT-90,270)
	boss.direction = -1
	boss.state = boss.State.CHARGE
	var hit_bomb = make_tnt(Vector2(finale.CENTER,270))
	var missed_bomb = make_tnt(Vector2(finale.CENTER,318))
	boss._physics_process(2)
	check(hit_bomb.broken and boss.hp == boss.MAX_HP-320,"A fast charge detonates a TNT and receives its explosion at the swept contact")
	check(not missed_bomb.broken,"A TNT outside the charge lane remains intact")
	check(boss.position.x == finale.LEFT+62 and boss.state == boss.State.IMPACT,"The widened arena still stops the charge exactly at the wall")
	clear_bombs()
	boss.position = Vector2(finale.LEFT+62,270)
	boss.direction = 1
	boss.state = boss.State.CHARGE
	hp = boss.hp
	hit_bomb = make_tnt(Vector2(finale.CENTER,270))
	boss._physics_process(2)
	check(hit_bomb.broken and boss.hp == hp-320 and boss.position.x == finale.RIGHT-62,"Swept TNT contact also works on a rightward charge")
	clear_bombs()
	boss.state = boss.State.RECOVER
	boss.age = 0
	boss._physics_process(1.21)
	check(boss.state == boss.State.IDLE,"Wall recovery includes a short animated idle interval")
	boss._physics_process(0.2)
	var saved_frame: int = boss.sprite.frame
	var saved_clock: float = boss.idle_clock
	stage.controls_locked = true
	boss._physics_process(3)
	check(boss.sprite.frame == saved_frame and boss.idle_clock == saved_clock,"The idle loop pauses with the battle")
	stage.controls_locked = false
	boss._physics_process(0.61)
	check(boss.state == boss.State.WINDUP and boss.sprite.texture == boss.ART,"Idle transitions back to the next shield windup")
	# Victory from an explosion must not erase the effect that delivered the last hit.
	boss.hp = 200
	boss.position = Vector2(finale.CENTER,270)
	bomb = make_tnt(boss.position)
	bomb.take_hit(1,1,p)
	await process_frame
	check(boss.dead and finale.state == finale.State.DONE and get_nodes_in_group("boss_tnt").is_empty(),"Explosion weakness can finish the boss and clears the arena")
	check(not get_nodes_in_group("tnt_explosion_fx").is_empty(),"The killing explosion continues animating after TNT cleanup")
	boss._physics_process(0.55)
	check(boss.sprite.frame == 15 and boss.sprite.rotation == 0,"Boss death reaches the drawn prone pose without rotating the standing sprite")
	boss.age = 0.81
	boss._physics_process(0.001)
	check(boss.sprite.modulate.a < 1,"The prone boss visibly blinks before fading")
	boss.age = 2.93
	boss._physics_process(0.05)
	check(boss.sprite.modulate.a < 0.05,"The blinking boss fades almost completely before disappearing")
	boss._physics_process(0.03)
	check(boss.is_queued_for_deletion(),"The boss is removed after the prone blink-and-fade animation")
	stage._process(1)
	check(camera.zoom == Vector2.ONE,"After victory the normal exploration camera zoom returns")
	print("PASS: " if failures.is_empty() else "FAIL: ",checks," shield / TNT revision checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

