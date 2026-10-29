extends SceneTree
var failures: Array[String]=[]
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var arena=load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	var guide=arena.tutorial
	guide.set_process(false)
	for player in arena.players: player.set_physics_process(false)
	var player=arena.players[0]
	var partner=arena.players[1]
	check(arena.controls_locked and guide.step==0,"Wake cutscene must lock gameplay")
	check(not arena.has_node("Actors/BlueAssistant") and arena.has_node("HUD/Communicator"),"Assistant must only exist in the communicator")
	check(arena.get_node("Breakables/Crate0") is RigidBody2D,"Crates must be real physics bodies")
	for x in range(40):
		for y in range(5,12):
			check(arena.get_node("LaboratoryTiles").get_cell_source_id(Vector2i(x,y))>=0,"Walkable floor must have no holes")
	check(arena.get_node("WakeSequence").has_animation("wake"),"Wake animation must be serialized")
	check(arena.get_node("LaboratoryTiles").get_used_cells().size()>300,"Imported tilemap must be authored in the scene")
	check(InputMap.action_get_events("p0_jump")[0].physical_keycode==KEY_SPACE,"P1 jumps with Space")
	check(InputMap.action_get_events("p1_jump")[0].physical_keycode==KEY_K,"P2 jumps with K")
	guide._process(3.7)
	check(guide.step==1 and not arena.controls_locked,"Wake must hand off to movement tutorial")
	guide.record_action("jump",player)
	guide._process(0.1)
	check(guide.step==1,"Wrong action must not skip a lesson")
	player.position.x+=100
	guide._process(0.8)
	check(guide.step==2,"Movement lesson must wait for travel")
	guide.record_action("jump",partner)
	check(not guide.action_done,"AI companion must not complete a child's lesson")
	guide.record_action("jump",player)
	player.jump_height=20
	guide._process(0.8)
	check(guide.step==2,"Jump lesson waits for landing")
	player.jump_height=0
	guide._process(0.8)
	check(guide.step==3,"Landing completes jump lesson")
	guide.record_action("dodge",player)
	guide._process(0.8)
	check(guide.step==4,"Dodge lesson must advance on dodge")
	player.position=Vector2(380,260)
	player.facing=1
	var targets: Array=[]
	arena.strike(player,1,targets)
	check(not arena.get_node("Breakables/Crate0").broken,"Crate survives the first light hit")
	await physics_frame
	await physics_frame
	check(arena.get_node("Breakables/Crate0").linear_velocity.x>0,"Crate reacts to hit with an impulse")
	targets.clear()
	arena.strike(player,1,targets)
	await process_frame
	check(arena.get_node("Breakables/Crate0").collision_layer==0,"Broken crates release their collision")
	check(arena.get_node("Debris").get_child_count()==2,"Breaking releases physical fragments")
	guide._process(0.8)
	check(guide.step==5 and arena.pieces==3,"Real crate break must grant pieces and unlock combat")
	var enemy=arena.nearest_enemy(player.position)
	player.position=enemy.position-Vector2(30,0)
	var before=enemy.hp
	arena.strike(player,1,targets)
	check(enemy.hp<before,"Aligned attack damages tutorial germ")
	var after=enemy.hp
	arena.strike(player,1,targets)
	check(enemy.hp==after,"Same swing must not damage twice")
	targets.clear()
	arena.strike(player,3,targets)
	await process_frame
	guide._process(0.8)
	check(guide.step==6,"Combat lesson requires the child's hit and germ defeat")
	arena.pieces=8
	player.position=Vector2(530,250)
	partner.position=Vector2(550,250)
	arena.interact(player,2.1)
	guide._process(0.8)
	check(guide.step==7 and arena.built,"Cooperative building completes tutorial")
	player.invulnerable=0
	player.take_hit(100,Vector2.ZERO)
	partner.position=player.position
	arena.interact(partner,2.1)
	check(not player.down and player.hp==50,"Companion revival remains functional")
	if "--capture" in OS.get_cmdline_user_args():
		arena.queue_free()
		await process_frame
		arena=load("res://scenes/gameplay/micro_arena.tscn").instantiate()
		root.add_child(arena)
		await process_frame
		arena.set_process(false)
		guide=arena.tutorial
		guide.set_process(false)
		for avatar in arena.players: avatar.set_physics_process(false)
		player=arena.players[0]
		partner=arena.players[1]
		player.position=Vector2(250,260)
		partner.position=Vector2(200,295)
		var wake: AnimationPlayer=arena.get_node("WakeSequence")
		wake.play("wake")
		wake.seek(0.9,true)
		wake.pause()
		guide.bubble.visible=false
		await capture("awakening_asleep")
		wake.play("wake")
		wake.seek(3.6,true)
		wake.pause()
		arena.controls_locked=false
		guide.step=2
		guide.age=0
		guide.action_done=false
		guide._process(0.01)
		arena.get_node("Camera2D").zoom=Vector2.ONE
		await capture("tutorial_jump")
		guide.step=4
		guide.advance()
		guide._process(0.01)
		for captured_enemy in get_nodes_in_group("germs"): captured_enemy.set_physics_process(false)
		await capture("cartoon_communicator")
	if failures.is_empty(): print("PASS: complete cartoon floor, remote communicator, crate physics, impulses, fragments, collision release, wake and tutorial")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/"+name+".png")


