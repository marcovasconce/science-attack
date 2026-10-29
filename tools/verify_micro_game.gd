extends SceneTree
var failures: Array[String]=[]
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var intro=load("res://scenes/laboratory_intro.tscn").instantiate()
	root.add_child(intro)
	intro.set_process(false)
	intro.seek(4.0)
	check(intro.doctor_max.current_pose==&"run" and intro.scientist.current_pose==&"run","Both scientists must run together")
	intro.seek(7.2)
	for i in range(4): intro.dialogue.advance()
	intro.seek(intro.sequence_start+intro.shrinking.SHRINK_START+1)
	check(intro.shrinking.shrink_factor==1.0,"Sleeping bodies must stay full size")
	check(intro.shrinking.tube_bodies[0].visible and intro.shrinking.tube_bodies[1].visible,"Both sleeping bodies remain visible")
	intro.queue_free()
	await process_frame
	var arena=load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	for player in arena.players: player.set_physics_process(false)
	var player=arena.players[0]
	var enemy=arena.nearest_enemy(player.position)
	player.position=enemy.position-Vector2(30,0)
	var targets: Array=[]
	var health=enemy.hp
	arena.strike(player,1,targets)
	check(enemy.hp<health,"An aligned attack must damage a germ")
	var after=enemy.hp
	arena.strike(player,1,targets)
	check(enemy.hp==after,"One swing must not hit the same germ repeatedly")
	player.invulnerable=0
	player.take_hit(100,enemy.position)
	check(player.down,"Zero HP must down the avatar")
	var partner=arena.players[1]
	partner.position=player.position
	arena.interact(partner,2.1)
	check(not player.down and player.hp==50,"Partner must revive a downed avatar")
	arena.pieces=8
	player.position=Vector2(530,250)
	partner.position=Vector2(550,250)
	arena.interact(player,2.1)
	check(arena.built and arena.open_limit>1000,"Cooperative building must open the next area")
	if "--capture" in OS.get_cmdline_user_args():
		arena.set_process(true)
		arena.players[0].position=Vector2(310,250)
		arena.players[1].position=Vector2(365,285)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/previews/micro_gameplay.png")
	if failures.is_empty(): print("PASS: joint running, sleep, combat, one hit per swing, down/revive, cooperative bridge")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
