extends SceneTree
var checks := 0
var failures: Array[String] = []
var stage: Node2D
var route: Node2D
var p: CharacterBody2D
var q: CharacterBody2D

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func freeze() -> void:
	stage.set_process(false)
	stage.elevator.set_physics_process(false)
	stage.puzzle.set_process(false)
	stage.route.set_process(false)
	stage.route.get_node("ExitElevator").set_physics_process(false)
	stage.encounter.set_process(false)
	stage.encounter.dialogue.set_process(false)
	for actor in stage.players: actor.set_physics_process(false)

func tick(seconds: float) -> void:
	for frame in int(ceil(seconds*60)):
		route._process(1.0/60)
		stage.encounter.dialogue._process(1.0/60)
		stage.encounter._process(1.0/60)
		for germ in get_nodes_in_group("germs"): germ.set_physics_process(false)

func clear_enemies() -> void:
	for germ in get_nodes_in_group("germs"): germ.free()

func turn(index: int, target: int) -> void:
	p.position = route.VALVE_POINTS[index]
	for attempt in 4:
		if route.valves[index] == target: return
		check(route.turn_valve(index,p),"A nearby player can turn one wheel")

func run() -> void:
	stage = load("res://scenes/gameplay/tabletop_stage.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await process_frame
	freeze()
	route = stage.route
	p = stage.players[0]
	q = stage.players[1]
	stage.elevator._physics_process(3)
	stage.encounter.start_message(0)
	var card = stage.encounter.dialogue
	check(card.active and not stage.controls_locked and not stage.encounter.is_modal(),"Radio never pauses gameplay")
	check(card.get_node("Message").visible_characters == -1 and card.remaining >= 9,"A complete short sentence has at least nine seconds to read")
	check(not card.get_node("Key").visible,"Radio does not ask the child to press a key")
	check(card.size == Vector2(308,78) and card.get_node("Message").get_line_count() <= 2,"Compact radio keeps the short message readable in two lines")
	check(stage.encounter.QUIET_TIME >= 12,"Radio leaves a quiet interval between messages")
	p.position = Vector2(400,290)
	await physics_frame
	Input.action_press("p0_right")
	p._physics_process(1.0/60)
	Input.action_release("p0_right")
	check(p.position.x > 400 and card.active,"Real movement continues while Tiburcio talks")
	card._process(6)
	check(card.active,"A short hint does not disappear after a few seconds")
	var read_time: float = card.remaining
	stage.controls_locked = true
	card._process(10)
	check(card.remaining == read_time,"Explicit help pauses reading time")
	stage.controls_locked = false
	stage.puzzle.restore_running()
	stage.spawn_index = 2
	stage.combat_cleared = true
	for prop in stage.get_node("WritingTools").get_children():
		for tube in stage.get_node("Glassware").get_children():
			var sprite: Sprite2D = tube.get_node("Sprite")
			check(not (prop.global_transform*prop.get_rect()).intersects(sprite.global_transform*sprite.get_rect()),"Writing tools and tube silhouettes stay separate")
	p.position = Vector2(2390,270)
	await physics_frame
	check(p.move_and_collide(Vector2(70,0)) != null,"Closed gate blocks the route")
	route.begin_power()
	tick(1.5)
	await physics_frame
	check(route.step == route.Step.PIPES and stage.open_limit == 3090 and not stage.victory,"Generator opens the water challenge, not the ending")
	p.position = Vector2(2390,270)
	check(p.move_and_collide(Vector2(70,0)) == null,"Powered gate releases its collision")
	check(route.tank_material.get_shader_parameter("fill_level") == 0.0 and route.inlet_material.get_shader_parameter("fill_level") > 0.9,"Right tube starts empty, left tube starts with water")
	p.position = Vector2(2700,286)
	tick(4)
	check(route.collection_age == 0 and not route.suction_started,"Approaching the puzzle never starts suction automatically")
	check(not route.try_action(p),"A player away from the pump cannot start suction")
	p.position = route.PUMP_POINT
	q.position = route.PUMP_POINT
	check(not route.try_action(q),"AI companion cannot start suction")
	stage.controls_locked = true
	check(not route.try_action(p),"Help blocks the pump button")
	stage.controls_locked = false
	p.jump_height = 12
	check(not route.try_action(p),"Airborne player cannot press the pump")
	p.jump_height = 0
	route._update_hint()
	check(route.hint.text == "E","Pump shows only the nearby player's interaction key")
	var pump_event := InputEventAction.new()
	pump_event.action = "p0_interact"
	pump_event.pressed = true
	root.push_input(pump_event)
	check(route.suction_started,"A fresh interaction at the button starts suction")
	check(not route.try_action(p),"Repeated presses cannot restart suction")
	check(stage.camera_max_x == stage.world_limit-320,"Camera is no longer clamped to the current gate")
	stage.players[1].position = Vector2(3000,286)
	stage._process(0)
	check(stage.get_node("Camera2D").position.x+320 > 3300,"Camera can show the spill beyond the closed puzzle gate")
	tick(1.5)
	check(route.collection_age > 1.4 and route.collection_age < 1.6 and route.water_fill[0] == 0,"Suction collects the spill before clean water can flow")
	check(route.get_node("Spill").modulate.a > 0.4 and route.get_node("Spill").modulate.a < 0.6 and route.tank_material.get_shader_parameter("fill_level") > 0.3,"Spill shrinks as the right tube fills with hazardous liquid")
	var collection_before: float = route.collection_age
	stage.controls_locked = true
	tick(2)
	check(route.collection_age == collection_before,"Help pauses suction as well as water")
	stage.controls_locked = false
	tick(3.2)
	check(route.collection_age == route.COLLECTION_DURATION and route.get_node("Spill").modulate.a == 0 and not route.drained,"Collected spill stays locked until the tube is cleaned")
	check(route.water_fill[1] > 0.9 and route.water_fill[3] == 0 and route.tank_fill == 0,"Water fills the fixed inlet and stops at the first disconnected piece")
	var before: Array = route.water_fill.duplicate()
	stage.controls_locked = true
	route._process(3)
	check(route.water_fill == before,"Help freezes the fluid animation")
	stage.controls_locked = false
	p.position = route.VALVE_POINTS[0]
	stage.encounter.clear()
	stage.encounter.gap = 0
	stage.encounter.say("test_radio",["Girem a roda para a água passar."])
	var event := InputEventAction.new()
	event.action = "p0_interact"
	event.pressed = true
	root.push_input(event)
	check(route.valves[0] == 2 and card.active and not stage.controls_locked,"A real E event turns the wheel while the radio stays open")
	check(route.valves[1] == 1 and route.valves[2] == 3,"Each wheel changes only its own piece")
	turn(0,0)
	tick(1.6)
	check(route.water_fill[3] > 0.99 and route.water_fill[5] == 0,"Water visibly advances through the first new connection before the next piece")
	turn(1,2)
	tick(2.6)
	check(route.water_fill[5] > 0.99 and route.water_fill[7] > 0.5 and route.water_fill[9] == 0,"A wrong outlet can fill but cannot feed the next tube")
	turn(0,1)
	tick(0.5)
	check(route.water_fill[3] == 0 and route.water_fill[5] == 0 and route.water_fill[7] == 0,"Disconnecting an upstream joint drains downstream water")
	turn(0,0)
	turn(2,0)
	tick(0.1)
	check(route.step == route.Step.PIPES and route.tank_fill == 0,"Correct rotation alone cannot finish before the water arrives")
	tick(6)
	check(route.tank_fill == 1 and route.step == route.Step.DRAIN,"Water reaches and fills the receiving tank before drainage begins")
	for i in 5:
		var path: PackedVector2Array = route.water_path(i)
		var inlet: PackedVector2Array = route.link_points(i)
		var outlet: PackedVector2Array = route.link_points(i+1)
		check(path[0].distance_to(inlet[1]) < 0.1 and path[2].distance_to(outlet[0]) < 0.1,"Filled pipe and connector endpoints match physically")
	tick(route.CLEAN_DURATION+0.1)
	check(route.drained and stage.open_limit == 4440,"The cleaned spill opens the next passage")
	check(route.tank_material.get_shader_parameter("liquid_color").is_equal_approx(Color("28d9ff")) and route.inlet_material.get_shader_parameter("fill_level") < 0.3,"Water from the left tube cleans the right tube and consumes its reservoir")
	check(not route.turn_valve(0,p),"A completed pipe puzzle cannot be accidentally undone")
	p.position = route.BATTERY_POINTS[0]
	p.energy = 10
	route._collect_pickups()
	check(route.batteries[0] and p.energy == 40,"Walking over an optional battery collects it without another key")
	route._collect_pickups()
	check(p.energy == 40,"Pickups cannot duplicate energy")
	p.position = route.RECORD_POINTS[0]
	route._collect_pickups()
	check(route.records[0] and p.energy == 60,"Optional clues are collected on approach")
	route._sync_visuals(0)
	check(not route.get_node("Record0").visible and route.get_node("PickupNotice").text == "+ Energia","Energy pickups disappear with an explicit reward instead of changing color")
	p.position = route.SUPPLY_POINTS[0]
	p.hp = 40
	var flasks: int = p.healing_flasks
	var box = route.get_node("Supply0")
	box.set_process(false)
	check(not box.get_node("Contents").visible,"Sealed box hides its contents")
	p.position = box.position-Vector2(50,0)
	p.facing = 1
	stage.strike(p,3,[])
	check(box.broken and box.fragments.size() == 4,"Real weapon strike breaks the medical box into textured pieces")
	check(not route.supplies[0] and p.healing_flasks == flasks,"Breaking the box does not grant loot early")
	box._process(0.3)
	check(box.get_node("Contents").position.y < -50,"Loot pops up out of the broken box")
	p.position = box.position+Vector2(30,0)
	box._process(0.2)
	check(not box.collected,"Airborne loot cannot be collected")
	box._process(0.31)
	check(box.collected and p.hp == 70 and p.healing_flasks == flasks+1,"Landed loot is collected on approach")
	box.take_hit(100,1,p)
	box._process(1)
	check(p.healing_flasks == flasks+1,"Broken box cannot duplicate its reward")
	var gate = route.get_node("PassageGate")
	gate.openness = 0.5
	check(gate.get_node("Well").clip_contents and gate.get_node("Well/Barrier").position == Vector2(22,183) and gate.get_node("Well/Barrier").modulate.a == 1,"Barrier descends into a clipped well without sideways motion or fading")
	gate.openness = 0
	check(not route.has_node("StorageDecor/Clue0") and not route.has_node("StorageDecor/Drawer"),"Removed battery pattern leaves no fake clue or terminal")
	check(route.get_node("MachineProgress").z_index > route.get_node("Sterilizer").z_index,"Cleaning progress renders in front of tank sprites")
	p.position = Vector2(route.VENTS[0],280)
	p.invulnerable = 0
	route.steam_clock = 3.0
	route._sync_visuals(0)
	var steam_sprite: Sprite2D = route.get_node("SteamSprites").get_child(0)
	var steam_texture: Texture2D = steam_sprite.texture
	var steam_position: Vector2 = steam_sprite.position
	check(steam_sprite.visible and steam_sprite.modulate.a > 0.7,"Active steam uses dense visible sprite frames")
	route.steam_clock += 0.14
	route._sync_visuals(0)
	check(steam_sprite.texture != steam_texture and steam_sprite.position == steam_position and route.get_node("SteamSprites").get_child_count() == 3,"Each outlet uses one anchored animated jet, without stacked puffs")
	stage.controls_locked = true
	steam_position = steam_sprite.position
	var steam_time: float = route.steam_clock
	route._process(1)
	check(route.steam_clock == steam_time and steam_sprite.position == steam_position,"Help pauses smoke frames and motion")
	stage.controls_locked = false
	route.steam_clock = 3.8
	route._sync_visuals(0)
	check(not steam_sprite.visible and not route.vent_active(0),"Steam sprites disappear with the damage window")
	route.steam_clock = 3.0
	var hp: int = p.hp
	route._update_steam()
	check(p.hp == hp-7,"The active jet still damages grounded characters")
	p.invulnerable = 0
	p.jump_height = 25
	route._update_steam()
	check(p.hp == hp-7,"Jumping over the jet avoids damage")
	p.jump_height = 0
	p.stun = 0
	q.position = Vector2(route.VENTS[0]-35,290)
	check(route.should_jump(q,Vector2.RIGHT),"Companion detects the jet ahead")
	p.position = Vector2(3510,292)
	tick(0.02)
	check(get_nodes_in_group("germs").size() == 2,"First passage encounter starts once")
	clear_enemies()
	p.position.x = 3930
	tick(0.02)
	check(get_nodes_in_group("germs").size() == 3,"Second encounter retains the varied combat")
	clear_enemies()
	tick(0.8)
	check(route.step == route.Step.EXPLORE and route.passage_open and route.get_node("PassageGate").openness == 1,"Clearing the path opens storage without another pressure-plate puzzle")
	check(not route.has_node("CoopPads") and not route.has_node("Filters"),"Removed puzzles do not leave interactive props behind")
	p.position = Vector2(4800,290)
	route._update_hint()
	check(not route.hint.visible,"No generic control instructions float over the storage scenery")
	p.position = route.CONSOLE_POINT+Vector2(-120,0)
	q.position = route.CONSOLE_POINT
	q.ai_controlled = false
	stage.get_node("HUD/TeamHUD")._apply_mode()
	route._update_hint()
	check(route.hint.visible and route.hint.text == "U  Ligar","Only the nearby player's own key is shown")
	check(not stage.encounter.dialogue.get_global_rect().intersects(stage.get_node("HUD/TeamHUD/Partner").get_global_rect()),"Radio does not hide the second human player's health panel")
	route.batteries = [false,false]
	check(route.try_action(q) and route.step == route.Step.DEFENSE,"One press starts the cleaner without fuses, shelf codes or pressure settings")
	q.ai_controlled = true
	check(not stage.is_assembling(q),"Starting the cleaner leaves both players free to fight")
	tick(3)
	check(route.charge > 2.9,"Cleaning progresses without holding interaction")
	var early_fill: float = route.cleaner_materials[1].get_shader_parameter("fill_level")
	check(early_fill > 0.06 and early_fill < 0.12,"Clean output starts filling during the first defense wave")
	check(route.cleaner_materials[0].get_shader_parameter("fill_level") < 0.82,"Contaminated input drains gradually during defense")
	var progress: float = route.charge
	stage.controls_locked = true
	tick(3)
	check(route.charge == progress,"Help pauses the defense timer")
	check(route.cleaner_materials[1].get_shader_parameter("fill_level") == early_fill,"Help also pauses the gradual cleaning visual")
	stage.controls_locked = false
	tick(20)
	check(route.charge == route.WAVE_CHARGE and route.defense_wave == 1,"Cleaning cannot skip a living enemy wave")
	check(route.cleaner_materials[1].get_shader_parameter("fill_level") > early_fill and route.cleaning_progress() < 0.31,"Visible cleaning advances with charge but waits for uncleared waves")
	for wave in [1,2,3]:
		clear_enemies()
		tick(0.02)
		if wave < 3: tick(10.1)
	check(route.step == route.Step.PURIFY,"Three cleared encounters finish the cleaning task")
	check(route.cleaning_progress() >= 0.9 and route.cleaner_materials[1].get_shader_parameter("fill_level") > 0.76,"Most transfer is already visible before the final rinse")
	p.position = route.CONSOLE_POINT
	tick(2.6)
	check(route.step == route.Step.SAMPLE,"The clean blue bottle becomes available")
	p.position = route.SAMPLE_POINT
	route._collect_pickups()
	check(route.sample_taken and route.step == route.Step.EXIT and not stage.victory,"The bottle is collected by walking up to it")
	# Loading a real checkpoint must still work after removing the old objectives.
	var previous_id := stage.get_instance_id()
	p.hp = 1
	await process_frame
	Input.action_press("restart")
	stage._process(0)
	Input.action_release("restart")
	for frame in 4: await process_frame
	stage = current_scene
	freeze()
	route = stage.route
	p = stage.players[0]
	q = stage.players[1]
	check(stage.get_instance_id() != previous_id and route.step == route.Step.EXIT,"F2 performs a real reload at the last checkpoint")
	check(p.hp >= 40 and route.sample_taken and route.records[0] and route.supplies[0],"Checkpoint restores health, bottle and optional rewards")
	check(route.tank_fill == 1 and route.water_fill[10] == 1 and route.get_node("PassageGate").openness == 1,"Checkpoint restores filled pipes and open doors")
	var current_checkpoint: Dictionary = get_meta(route.CHECKPOINT_META).duplicate(true)
	var legacy: Dictionary = current_checkpoint.duplicate(true)
	legacy.erase("passage")
	legacy.erase("batteries")
	legacy["plates"] = true
	legacy["fuses"] = [true,false]
	legacy["sample"] = false
	legacy["step"] = 7
	route.restore_checkpoint(legacy)
	check(route.step == route.Step.EXPLORE and route.passage_open and route.batteries == [true,false],"Old filter checkpoints migrate to free exploration")
	legacy["step"] = 5
	legacy["plates"] = false
	route.restore_checkpoint(legacy)
	tick(0.02)
	check(route.step == route.Step.EXPLORE and route.passage_open,"Old plate checkpoints open after the already-cleared encounter")
	route.restore_checkpoint(current_checkpoint)
	stage.encounter.clear()
	# A fast transition discards obsolete queued hints without cutting the active line.
	stage.encounter.gap = 0
	stage.encounter.say("current_test",["Vamos juntos até a estufa."])
	stage.encounter.say("stale_test",["Girem a roda."],route.Step.PIPES)
	stage.encounter.dialogue._process(20)
	stage.encounter._process(stage.encounter.QUIET_TIME+0.1)
	check(stage.encounter.current_message != "stale_test" and stage.encounter.pending.is_empty(),"A stale queued puzzle hint is not shown later")
	var lift = route.get_node("ExitElevator")
	lift._physics_process(0)
	check(lift.available and lift.next_scene_path.is_empty(),"Sample unlocks the reused elevator without a nonexistent destination")
	p.position = lift.pads[0].global_position
	q.position = lift.pads[0].global_position
	lift._physics_process(0.5)
	check(not lift.is_transitioning(),"Two players on the same lift mark cannot depart")
	q.position = lift.pads[1].global_position
	q.jump_height = 10
	lift._physics_process(0.5)
	check(not lift.is_transitioning(),"Jumping cannot activate a lift mark")
	q.jump_height = 0
	stage.controls_locked = true
	lift._physics_process(0.5)
	check(not lift.is_transitioning(),"Help cannot start departure")
	stage.controls_locked = false
	q.position = Vector2(6700,280)
	for frame in 360:
		await physics_frame
		q._physics_process(1.0/60)
		if lift.plate_for(q) == 1: break
	check(lift.plate_for(q) == 1,"Companion enters through the front and reaches the free lift mark")
	lift._physics_process(0.41)
	check(lift.state == lift.State.ASCENDING and stage.controls_locked and not route.complete,"Both riders start the shared ascent before chapter completion")
	var feet: Vector2 = p.position
	lift._physics_process(0.7)
	check(p.position.y < feet.y and lift.cabin.position.y < 0,"Cabin and riders rise together")
	lift._physics_process(2.0)
	check(lift.state == lift.State.LOADING and lift.black.color.a == 1,"Ride finishes its fade before the chapter summary")
	lift._physics_process(0.7)
	check(route.complete and route.result_panel.visible and lift.black.color.a == 0,"Missing greenhouse ends this chapter cleanly after the ride")
	check(p.position == feet and lift.cabin.position == Vector2.ZERO,"Returning to explore retains a usable cabin and grounded riders")
	if failures.is_empty(): print("PASS: ",checks," checks: nonblocking readable radio, live input, sequential connected water, disconnection, pause, simpler progression, contextual keys, optional pickups, automatic cleaning, real F2 restore and companion exit")
	quit(0 if failures.is_empty() else 1)
