extends SceneTree
const Chapters = preload("res://scripts/chapter_catalog.gd")
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func settle() -> void:
	for i in 5: await process_frame
func run() -> void:
	change_scene_to_file("res://scenes/main_menu.tscn")
	await settle()
	var menu = current_scene
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,"Menu renders at window resolution")
	check(menu.play_button.has_focus() and not menu.chapter_panel.visible,"Menu starts focused on Play")
	menu.chapters_button.pressed.emit()
	check(menu.chapter_panel.visible and menu.chapter_list.has_focus(),"Chapters is an actual interactive panel")
	check(menu.play_button.disabled and menu.coop_button.disabled,"Chapter overlay shields the main menu controls")
	for id in [0,1,2,3,4,5,10,11,12,13,14,15,20,21,22,23,24,25,30]:
		check(id in menu.chapter_ids and ResourceLoader.exists(Chapters.path_for(id)),"Chapter has a valid selectable scene: %d" % id)
	menu.hide_chapters()
	check(not menu.chapter_panel.visible and menu.chapters_button.has_focus(),"Back restores menu focus")
	menu.play_button.pressed.emit()
	await scene_changed
	await settle()
	check(current_scene.scene_file_path == Chapters.PHASES[0],"Play really opens the intro")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,"The intro also renders at window resolution")
	for chapter in 6:
		check(Chapters.open(self,20+chapter) == OK,"Open lower lab subsection %d" % chapter)
		await settle()
		var lab = current_scene
		check(lab.players[0].hp>0 and lab.players[0].equipped_weapon != "none","Shortcut starts equipped and alive")
		if chapter == 0: check(lab.beat == lab.Beat.WARNING,"Swarm chapter starts with warning")
		if chapter == 1: check(not lab.puzzle_complete and lab.beat == lab.Beat.CLEARED,"Puzzle remains unsolved")
		if chapter == 2: check(lab.beat == lab.Beat.MIXED and lab.puzzle_complete,"Mixed chapter opens the door and starts enemies")
		if chapter == 3: check(lab.finale.state == lab.finale.State.READY and not lab.finale.soap_taken,"Soap chapter still needs searching")
		if chapter == 4: check(is_instance_valid(lab.finale.boss) and lab.finale.cleaned,"Boss chapter restores cleaned passage")
		if chapter == 5:
			check(lab.finale.state == lab.finale.State.DONE and not lab.exit_lift.repaired,"Repair chapter still requires parts")
			lab.set_process(false)
			lab.exit_lift.set_physics_process(false)
			lab.pieces = 8
			lab.players[0].position = lab.exit_lift.repair_point()
			lab.exit_lift.repair(lab.players[0],3.3)
			for i in 2:
				lab.players[i].set_physics_process(false)
				lab.players[i].position = lab.exit_lift.pads[i].global_position
			var start: Vector2 = lab.players[0].position
			lab.exit_lift._start_ascent()
			lab.exit_lift._advance_ascent(0.8)
			check(lab.exit_lift.cabin.position.y == 0,"Doors close before cabin moves")
			lab.exit_lift._advance_ascent(0.9)
			check(lab.exit_lift.cabin.position.y>50 and lab.players[0].position.y>start.y+50,"Cabin and riders descend together")
			check(lab.exit_lift.doors.get_parent() == lab.exit_lift.cabin and lab.exit_lift.get_node("ShaftDetails").visible and lab.exit_lift.get_node("ShaftDetails").position == Vector2.ZERO,"Doors descend while long fixed rails remain visible")
	Chapters.open(self,30)
	await settle()
	var hive = current_scene
	check(not hive.controls_locked and hive.clean_sample and hive.world_limit == 4044, "Sewer shortcut starts with the jar")
	check(hive.vents.size() == 12 and hive.arrival_lift.arrived, "Original cabin opens before the combat drains")
	check(not has_meta("lower_lab_chapter"),"Chapter switches clear prior route metadata")
	hive.beat = hive.Beat.ASSAULT
	var vent = hive.vents[0]
	vent.set_process(false)
	vent.state = vent.State.REST
	vent.age = vent.rest_time-0.01
	vent.advance(0.02)
	check(vent.state == vent.State.WARNING and not vent.dangerous(),"A vent warns before it can hurt")
	vent.advance(0.98)
	check(vent.state == vent.State.WARNING,"Warning lasts a full second")
	vent.advance(0.02)
	check(vent.state == vent.State.ERUPTING,"Geyser starts after one second")
	vent.advance(0.4)
	check(vent.dangerous() and vent.frame_index() in [4,5],"Full jet uses animated peak frames")
	check(is_equal_approx(vent.global_position.y - 15.0 - vent.jet_height(),vent.ceiling_y),"Full jet reaches the ceiling")
	var player = hive.players[0]
	var partner = hive.players[1]
	player.set_physics_process(false)
	partner.set_physics_process(false)
	player.position = vent.position
	player.invulnerable = 0
	player.jump_height = 42
	var hp: int = player.hp
	vent._process(0.01)
	vent._process(0.01)
	check(player.hp == hp-12,"Tall geyser hits airborne players once per eruption")
	player.position.y = vent.position.y-50
	player.invulnerable = 0
	vent.hit_players.clear()
	vent._process(0.01)
	check(player.hp == hp-12,"The other floor lane avoids the geyser")
	hive.controls_locked = true
	var age: float = vent.age
	vent._process(5)
	check(vent.age == age,"Help pause freezes geyser timing")
	hive.controls_locked = false
	Chapters.open(self,5)
	await settle()
	check(not has_meta("hive_chapter") and current_scene.players[0].position.x<300,"Selecting arrival clears the hazard shortcut")
	print("PASS" if failures.is_empty() else "FAIL",": ",checks," menu / chapter / rail / hive checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
