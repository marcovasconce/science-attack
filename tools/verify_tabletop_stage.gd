extends SceneTree
var failures: Array[String] = []
var stage: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	root.push_input(event)
func run() -> void:
	set_meta("party_state",[{"weapon":"brush","hp":71,"energy":50,"healing_flasks":2,"ai_controlled":false},{"weapon":"bubbles","hp":62,"energy":90,"healing_flasks":4,"ai_controlled":true}])
	stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	stage.set_process(false)
	stage.route.set_process(false)
	stage.elevator.set_physics_process(false)
	for p in stage.players: p.set_physics_process(false)
	var p = stage.players[0]
	var q = stage.players[1]
	var lift = stage.elevator
	var radio = stage.encounter
	var supply_crates := stage.get_node("Breakables").get_children()
	check(supply_crates.size() == 3,"Supply crates exist when the level loads")
	check(stage.puzzle.machine.z_index+stage.puzzle.z_index < p.z_index,"Machine renders behind players")
	check(stage.controls_locked and not lift.arrived and lift.doors.openness<0.01,"Arrival begins locked behind closed doors")
	check(p.hp==71 and q.hp==62 and p.energy==50 and q.healing_flasks==4,"The arrival keeps health, energy and flasks")
	check(p.equipped_weapon=="brush" and q.equipped_weapon=="bubbles" and q.ai_controlled,"Weapons and the solo companion are restored")
	check(get_nodes_in_group("test_tubes").size()==5 and stage.get_node("WritingTools").get_child_count()==4,"The table contains five liquid tubes, two pens and two pencils")
	p.position = Vector2(149,284)
	await physics_frame
	check(p.move_and_collide(Vector2(0,50))!=null,"Closed elevator doors physically block leaving the cabin")
	p.position = Vector2(149,284)
	Input.action_press("controls")
	Input.action_press("join")
	stage._process(0)
	Input.action_release("controls")
	Input.action_release("join")
	check(stage.controls_locked and q.ai_controlled and not stage.get_node("HUD/ControlsPanel").visible,"Help and join cannot interrupt the arrival")
	await process_frame
	lift.age = 0
	lift._physics_process(1.7)
	check(lift.doors.openness>0.2 and lift.doors.openness<0.8 and stage.controls_locked,"Doors slide open over time before control returns")
	lift._physics_process(0.8)
	await physics_frame
	check(lift.arrived and not stage.controls_locked and not lift.doors.visible,"Fully open doors release player control")
	check(p.move_and_collide(Vector2(0,34))==null,"The player can leave through the open front")
	p.position = Vector2(149,284)
	q.position = Vector2(230,318)
	stage._process(0.5)
	check(not radio.message_started,"The AI leaving alone cannot trigger the player's arrival message")
	p.position.y = 318
	stage._process(0.31)
	check(radio.dialogue.active and not radio.is_modal() and not stage.controls_locked,"Radio appears after arrival without pausing play")
	check(radio.dialogue.get_node("Message").text==radio.ARRIVAL_LINE,"Arrival uses the short story message")
	check(radio.dialogue.get_node("Speaker").text=="TIBÚRCIO","The communicator identifies Tibúrcio")
	var tube = stage.get_node("Glassware/CyanTube")
	tube.set_process(false)
	var time_before: float = tube.liquid_time
	tube._process(0.3)
	check(tube.liquid_time>time_before,"Liquid animation continues during radio messages")
	var held := InputEventKey.new()
	held.physical_keycode = KEY_E
	held.pressed = true
	held.echo = true
	root.push_input(held)
	check(radio.dialogue.active,"Held keyboard repeat cannot dismiss the message")
	press("p1_interact")
	check(radio.dialogue.active,"Companion input cannot skip the radio")
	press("p0_interact")
	check(radio.dialogue.active and radio.dialogue.get_node("Message").visible_characters==-1,"The full short line is readable from the start")
	press("p0_interact")
	check(radio.message_finished and not stage.controls_locked and radio.dialogue.active,"Interaction stays available without closing the radio")
	tube._process(0.3)
	check(tube.liquid_time>time_before and tube.liquid_material.get_shader_parameter("liquid_time")==tube.liquid_time,"Liquid clock drives the wave/bubble shader during gameplay")
	radio.clear()
	radio._process(radio.QUIET_TIME+0.1)
	# Salvage found before the final wave must survive the transition into building.
	supply_crates[0].freeze = true
	supply_crates[0].take_hit(100,1,p)
	supply_crates[0]._process(0.5)
	check(stage.pieces == 3 and not stage.puzzle.started,"Crates can be broken before the construction lesson")
	p.position = Vector2(700,290)
	q.position = Vector2(670,312)
	stage._process(0)
	check(stage.spawn_index==1 and get_nodes_in_group("germs").size()==4,"Moving forward brings the first mixed germ wave")
	if get_nodes_in_group("germs").is_empty():
		print("Diagnostic: locked=",stage.controls_locked," radio=",radio.message_started,"/",radio.message_finished," help=",stage.get_node("HUD/ControlsPanel").visible," p=",p.position," q=",q.position)
		quit(1)
		return
	var germ = get_nodes_in_group("germs")[0]
	for enemy in get_nodes_in_group("germs"): enemy.set_physics_process(false)
	p.position = germ.position-Vector2(70,0)
	p.facing = 1
	var before: int = germ.hp
	stage.strike(p,1,[])
	check(germ.hp<before,"The restored toothbrush can damage enemies in stage two")
	q.position = Vector2(740,310)
	q.facing = 1
	var bubble = stage.spawn_bubble(q)
	bubble.set_physics_process(false)
	await physics_frame
	bubble._physics_process(0.1)
	check(bubble.travelled>0,"The restored bubble weapon fires in the new stage")
	for enemy in get_nodes_in_group("germs"): enemy.take_hit(enemy.hp,0)
	await process_frame
	p.position = Vector2(1460,300)
	q.position = Vector2(1410,310)
	stage._process(0)
	check(stage.spawn_index==2 and get_nodes_in_group("germs").size()==4,"The next section receives its own wave without duplicate spawns")
	for enemy in get_nodes_in_group("germs"):
		var spawn_query := PhysicsShapeQueryParameters2D.new()
		spawn_query.shape = enemy.get_node("CollisionShape2D").shape
		spawn_query.transform = enemy.global_transform
		spawn_query.collision_mask = 17
		check(stage.get_world_2d().direct_space_state.intersect_shape(spawn_query).is_empty(),"Germs must spawn outside pen and tube colliders")
		check(enemy.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING,"Germs must not interpret diagonal pens as platform floors")
	stage._process(0)
	check(get_nodes_in_group("germs").size()==4,"Staying on the trigger does not spawn extra enemies")
	for enemy in get_nodes_in_group("germs"): enemy.free()
	stage._process(0)
	check(stage.combat_cleared and not stage.victory and stage.puzzle.started,"Clearing both groups begins the assembly puzzle before victory")
	check(radio.dialogue.active and not stage.controls_locked,"Tiburcio gives a short build tip while the player keeps moving")
	press("p0_interact")
	press("p0_interact")
	check(radio.puzzle_message_finished and not stage.controls_locked,"Building does not wait for a dialogue confirmation")
	var puzzle = stage.puzzle
	puzzle.set_process(false)
	check(stage.get_node("Breakables").get_children() == supply_crates,"Combat completion must not spawn or replace supply crates")
	p.position = puzzle.BUILD_POINT
	stage.interact(p,0.5)
	check(puzzle.build_progress == 0 and stage.pieces == 3,"Building waits for all nine parts without spending a partial supply")
	stage.pieces += 9
	stage.interact(p,0.5)
	check(puzzle.build_progress == 0 and stage.pieces == 12,"Stock from the previous stage cannot substitute the generator's local salvage")
	stage.pieces -= 9
	for crate in stage.get_node("Breakables").get_children():
		crate.freeze = true
		p.position = crate.position-Vector2(50,0)
		p.facing = 1
		for hit in 4:
			if not crate.broken: stage.strike(p,3,[])
		check(crate.broken,"Existing weapon attacks break the salvage crates")
		crate._process(0.5)
	check(stage.pieces == 9 and stage.get_node("Debris").get_child_count() == 6,"Breaking crates supplies nine parts and persistent textured debris")
	p.position = puzzle.BUILD_POINT+Vector2(-100,0)
	stage.interact(p,1)
	check(puzzle.build_progress == 0,"Assembly requires the single marked building point")
	p.position = puzzle.BUILD_POINT
	arena_pause_build_check(puzzle,p)
	stage.interact(p,0.9)
	check(puzzle.build_progress > 0 and puzzle.snapped_parts == 1 and stage.is_assembling(p),"The marked spot starts sequential assembly and animates the builder")
	check(stage.pieces == 0 and puzzle.used_parts == 9,"Building reserves the nine parts once")
	var held_progress: float = puzzle.build_progress
	Input.action_press("p0_interact")
	p._physics_process(0)
	check(p.sprite.animation == &"build" and p.facing > 0,"The generator uses the construction animation facing the machine")
	Input.action_release("p0_interact")
	p._physics_process(0)
	puzzle._process(0.4)
	check(puzzle.build_progress == held_progress and not stage.is_assembling(p),"Releasing interaction stops construction and preserves progress")
	q.ai_controlled = false
	p.position = puzzle.BUILD_POINT+Vector2(-70,0)
	q.position = puzzle.BUILD_POINT
	stage.interact(q,0.6)
	puzzle._process(0)
	check(puzzle.build_progress > held_progress and stage.pieces == 0,"P2 can resume the same build without a second resource charge")
	puzzle.stop_building(q)
	stage.route._update_hint()
	check("U" in stage.route.hint.text and "E / U" not in stage.route.hint.text,"Only the nearby human receives an interaction key")
	puzzle._process(0.4)
	q.ai_controlled = true
	p.position = puzzle.BUILD_POINT
	stage.interact(p,puzzle.BUILD_DURATION)
	check(puzzle.constructed and puzzle.snapped_parts == 9 and not puzzle.finished,"All nine parts assemble from one point; power still needs the lever")
	stage.interact(p,1)
	check(not puzzle.activating,"Holding build cannot automatically pull the lever")
	check(not puzzle.pull_lever(p),"The lever requires approaching its location")
	p.position = puzzle.LEVER_POINT
	p.jump_height = 10
	check(not puzzle.pull_lever(p),"Airborne players cannot pull the lever")
	p.jump_height = 0
	q.position = puzzle.LEVER_POINT
	check(not puzzle.pull_lever(q),"The AI cannot activate the lever for the player")
	var lever_event := InputEventAction.new()
	lever_event.action = "p0_interact"
	lever_event.pressed = true
	puzzle._unhandled_input(lever_event)
	check(puzzle.activating and not puzzle.finished,"A fresh interaction starts lever activation")
	puzzle._process(0.25)
	check(puzzle.lever.rotation > puzzle.OFF_ANGLE and puzzle.lever.rotation < puzzle.ON_ANGLE,"Lever visibly rotates instead of switching instantly")
	var paused_angle: float = puzzle.lever.rotation
	stage.controls_locked = true
	puzzle._process(2)
	check(puzzle.lever.rotation == paused_angle and not puzzle.finished,"Menus pause machine startup")
	stage.controls_locked = false
	puzzle._process(0.6)
	check(puzzle.light_levels[0] > 0 and puzzle.light_levels[1] == 0,"Lamps switch on in sequence")
	puzzle._process(1.5)
	check(puzzle.finished and puzzle.light_levels[2] == 1,"All lights finish powering on before victory")
	var angle: float = puzzle.gear_angle
	puzzle._process(0.3)
	check(puzzle.gear_angle != angle and not puzzle.pull_lever(p),"Gears keep turning and repeated lever presses cannot restart completion")
	var gear_frames: Dictionary = {}
	var monitor_frames: Dictionary = {}
	for frame in 12:
		puzzle._process(0.05)
		gear_frames[puzzle.get_node("Machine/GearLarge/Sprite").texture] = true
		monitor_frames[puzzle.get_node("Machine/Console/Sprite").texture] = true
	check(gear_frames.size() == 4 and monitor_frames.size() == 4,"Running generator plays all four gear and monitor sprite frames")
	if "--capture" in OS.get_cmdline_user_args():
		p.position = Vector2(2190,314)
		q.position = Vector2(2150,314)
		stage._process(0)
		puzzle._process(0.06)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/previews/tabletop_assembly_puzzle.png")
	stage._process(0)
	check(not stage.victory and puzzle.finished and stage.route.powered,"Powering the machine opens the rest of the chapter without ending the game")
	check(not radio.is_modal(),"Generator completion keeps radio nonblocking")
	p.position = Vector2(750,260)
	p.set_collision_mask_value(5,true)
	await physics_frame
	check(p.move_and_collide(Vector2(120,0)) != null,"Pens block grounded movement")
	p.position = Vector2(750,260)
	p.set_collision_mask_value(5,false)
	check(p.move_and_collide(Vector2(120,0)) == null,"Raised jump collision passes over the pens")
	p.position = Vector2(785,260)
	check(stage.obstacle_ahead(p,Vector2.RIGHT),"AI detects a nearby pen before jumping")
	p.position = Vector2(750,260)
	p.jump_height = 0
	p.jump_speed = 0
	p.set_collision_mask_value(5,true)
	Input.action_press("p0_right")
	Input.action_press("p0_jump")
	p._physics_process(1.0/60.0)
	Input.action_release("p0_jump")
	for frame in 55:
		await physics_frame
		p._physics_process(1.0/60.0)
	Input.action_release("p0_right")
	check(p.position.x > 850 and p.jump_height == 0,"A real jump crosses the pen and lands on the other side")
	for barrier in stage.get_node("JumpObstacles").get_children():
		check(barrier.global_transform.get_scale().is_equal_approx(Vector2.ONE),"Obstacle physics must stay unscaled")
	for prop in stage.get_node("WritingTools").get_children():
		check(is_equal_approx(prop.scale.x,prop.scale.y),"Pens and pencils preserve their texture proportions")
	p.position = Vector2(810,260)
	p.jump_height = 0
	p.jump_speed = 0
	p.set_collision_mask_value(5,false)
	var landed_at: Vector2 = p.position
	for frame in 12:
		await physics_frame
		p._physics_process(1.0/60.0)
	check(p.position.distance_to(landed_at) < 0.1 and not p.get_collision_mask_value(5),"Landing inside a pen footprint must not pull or eject the player")
	p.position = Vector2(880,260)
	stage.update_jump_collision(p)
	check(p.get_collision_mask_value(5),"Ground collision returns after leaving the pen footprint")
	p.hp = 10
	p.healing_flasks = 0
	stage._restore_party()
	check(p.hp==71 and p.healing_flasks==2,"Restart restores the arrival inventory, not depleted combat values")
	check(reload_current_scene()==OK,"F2 can reload the second stage independently")
	for frame in 3: await process_frame
	stage = current_scene
	check(stage.name=="TabletopStage" and stage.controls_locked and not stage.elevator.arrived,"Restart returns to the second-stage arrival")
	check(stage.players[0].hp==71 and stage.players[1].equipped_weapon=="bubbles","Real scene restart preserves the checkpoint loadout and health")
	if failures.is_empty(): print("PASS: authored crates, early salvage, single-point/co-op assembly, resource reservation, lever input/animation, sequential lights, running gears, pause, collision regressions and restart")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func arena_pause_build_check(puzzle, player) -> void:
	stage.controls_locked = true
	stage.interact(player,1)
	check(puzzle.build_progress == 0 and stage.pieces == 9,"Menus block assembly and resource spending")
	stage.controls_locked = false
