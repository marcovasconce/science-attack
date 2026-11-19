extends SceneTree
var stage
var boss
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	boss.state = boss.State.RECOVER
	boss.age = 0
	boss.next_bash_time = 0
	boss.close_times.clear()
func run() -> void:
	stage = load("res://scenes/gameplay/lower_lab_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.elevator._physics_process(3)
	stage.finale.set_process(false)
	for player in stage.players:
		player.set_physics_process(false)
		player.ai_controlled = false
	stage.beat = stage.Beat.FINISHED
	stage.finale.cleaned = true
	stage.finale.state = stage.finale.State.OPEN
	stage.finale.begin_boss()
	boss = stage.finale.boss
	boss.set_physics_process(false)
	stage.finale._process(1.2)
	stage.finale.start_fight()
	await physics_frame
	boss.position = Vector2(4340,280)
	boss.direction = -1
	var p = stage.players[0]
	var q = stage.players[1]
	q.position = Vector2(4550,315)
	p.position = boss.position-Vector2(160,0)
	settle()
	for i in 15: boss.receive_attack(1,p.position,1)
	check(boss.state == boss.State.RECOVER,"Attacks alone never trigger the shield bash")
	for i in 18: boss._physics_process(0.1)
	check(boss.state != boss.State.SHIELD_BASH,"Ranged attackers do not trigger proximity pressure")
	settle()
	p.position = boss.position-Vector2(60,0)
	for i in 12: boss._physics_process(0.1)
	check(boss.state != boss.State.SHIELD_BASH,"Brief contact below 1.5 seconds is tolerated")
	p.position.y += 65
	boss._physics_process(0.01)
	p.position.y -= 65
	# Keep the boss in its stationary recovery to isolate the continuous timer.
	boss.age = 0
	boss.state = boss.State.RECOVER
	for i in 12: boss._physics_process(0.1)
	check(boss.state != boss.State.SHIELD_BASH,"Leaving resets close time rather than accumulating visits")
	for i in 4: boss._physics_process(0.1)
	check(boss.state == boss.State.SHIELD_BASH and boss.sprite.frame == 8,"Staying close causes a drawn shield preparation before damage")
	p.hp = 100
	p.invulnerable = 0
	boss._physics_process(0.25)
	check(p.hp == 100 and p.push_velocity == Vector2.ZERO,"The shield preparation gives time to dodge")
	boss._physics_process(0.13)
	check(p.hp == 94 and p.push_velocity.x < 0,"Shield contact causes low damage and an outward impulse")
	var before: float = p.position.x
	for i in 30:
		await physics_frame
		p._physics_process(1.0/60)
	check(before-p.position.x > 75 and before-p.position.x < 100,"The animated push creates useful space, about 90 pixels")
	boss._physics_process(0.02)
	check(p.hp == 94,"A shield push never hits twice in the same attack")
	# The same push must not shove a player through the sealed arena.
	p.position = Vector2(stage.finale.LEFT+30,280)
	p.invulnerable = 0
	p.receive_shield_push(6,p.position+Vector2(40,0),-1)
	for i in 30:
		await physics_frame
		p._physics_process(1.0/60)
	check(p.position.x > stage.finale.LEFT+10,"Shield knockback stops at the west arena wall")
	p.position = Vector2(stage.finale.RIGHT-30,280)
	p.invulnerable = 0
	p.receive_shield_push(6,p.position-Vector2(40,0),1)
	for i in 30:
		await physics_frame
		p._physics_process(1.0/60)
	check(p.position.x < stage.finale.RIGHT-10,"Shield knockback stops at the east arena wall")
	settle()
	p.position = boss.position+Vector2(60,0)
	for i in 18: boss._physics_process(0.1)
	check(boss.state != boss.State.SHIELD_BASH,"Attacking from behind preserves the boss weakness")
	settle()
	boss.direction = 1
	p.position = boss.position+Vector2(60,0)
	for i in 16: boss._physics_process(0.1)
	check(boss.state == boss.State.SHIELD_BASH and boss.sprite.flip_h,"Close shield attack also faces right correctly")
	p.invulnerable = 0
	p.jump_height = 45
	p.push_velocity = Vector2.ZERO
	var hp: int = p.hp
	boss._physics_process(0.4)
	check(p.hp == hp and p.push_velocity == Vector2.ZERO,"Jumping clear avoids both damage and push")
	p.jump_height = 0
	boss._physics_process(0.5)
	boss.age = 0
	for i in 16: boss._physics_process(0.1)
	check(boss.state != boss.State.SHIELD_BASH,"Cooldown prevents repeated shield pushes from trapping the player")
	boss._apply_damage(boss.MAX_HP)
	var frames: Array[int] = [boss.sprite.frame]
	for i in 3:
		boss._physics_process(0.161)
		frames.append(boss.sprite.frame)
	check(frames == [12,13,14,15],"Defeat plays all four collapse poses in order")
	check(boss.sprite.rotation == 0 and not boss.is_in_group("germs"),"Prone boss stops participating in combat immediately")
	boss._physics_process(0.34)
	check(boss.sprite.modulate.a < 0.2,"The prone sprite blinks only after the collapse")
	boss._physics_process(0.2)
	check(boss.sprite.modulate.a == 1,"Blink restores full visibility before the next pulse")
	boss._physics_process(2)
	check(boss.is_queued_for_deletion(),"The prone boss disappears after three seconds")
	print("PASS: " if failures.is_empty() else "FAIL: ",checks," proximity / shield push / defeat checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
