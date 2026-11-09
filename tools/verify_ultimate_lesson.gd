extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.elevator.set_physics_process(false)
	arena.get_node("WakeSequence").play("wake")
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.tutorial.step = 7
	arena.controls_locked = false
	for player in arena.players: player.set_physics_process(false)
	var p = arena.players[0]
	var q = arena.players[1]
	p.equip_weapon("brush")
	q.equip_weapon("bubbles")
	q.ai_controlled = false
	var lesson = arena.encounter
	lesson.unlock_route()
	lesson.arrived = true
	arena.elevator._physics_process(0.1)
	assert(not arena.elevator.available, "Equipment alone must not unlock the elevator")
	lesson.update_ultimate_lesson(1.0)
	assert(lesson.ultimate_stage == 1)
	arena.controls_locked = true
	lesson.update_ultimate_lesson(10.0)
	assert(lesson.ultimate_stage == 1, "Menus must pause the explanation")
	arena.controls_locked = false
	lesson.update_ultimate_lesson(3.0)
	assert(lesson.ultimate_stage == 1, "Explanation must remain readable after four seconds")
	lesson.update_ultimate_lesson(3.0)
	assert(p.energy == 100 and q.energy == 100)
	if "--capture" in OS.get_cmdline_user_args():
		lesson.update_ultimate_lesson(0.1)
		arena.get_node("HUD/Communicator")._process(10.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/previews/ultimate_lesson.png")
	p.energy = 50
	assert(p.specials.try_activate())
	assert(not lesson.ultimate_used[0], "Half-charge specials must not complete ultimate practice")
	p.specials.cancel()
	p.energy = 100
	assert(p.specials.try_activate())
	lesson.update_ultimate_lesson(0.1)
	assert(lesson.ultimate_used[0] and not lesson.ultimate_used[1] and lesson.ultimate_stage == 2)
	assert(arena.get_node("HUD/Communicator/Key").text == "I", "Prompt must show the remaining player's key")
	q.ai_controlled = true
	assert(q.specials.try_activate())
	assert(not lesson.ultimate_used[1], "AI must not complete the human lesson")
	q.specials.cancel()
	q.ai_controlled = false
	q.energy = 100
	assert(q.specials.try_activate())
	lesson.update_ultimate_lesson(0.1)
	assert(lesson.ultimate_stage == 2, "Wait for the abilities to finish")
	p.specials.tick(2.0)
	q.specials.tick(4.0)
	lesson.update_ultimate_lesson(0.1)
	assert(lesson.ultimate_stage == 4, "Praise must have its own reading time after the cast")
	lesson.update_ultimate_lesson(4.0)
	assert(lesson.ultimate_stage == 4 and not lesson.ultimate_done)
	lesson.update_ultimate_lesson(1.0)
	assert(lesson.ultimate_stage == 3)
	lesson.update_ultimate_lesson(3.0)
	assert(not lesson.ultimate_done, "Final instructions must not disappear after three seconds")
	lesson.update_ultimate_lesson(3.0)
	arena.elevator._physics_process(0.1)
	assert(lesson.ultimate_done and arena.elevator.available)
	# Solo requires only the human player's ultimate.
	lesson.ultimate_done = false
	lesson.ultimate_stage = 2
	lesson.ultimate_used = [true,false]
	q.ai_controlled = true
	lesson.update_ultimate_lesson(0.1)
	assert(lesson.ultimate_stage == 4)
	print("PASS: ultimate lesson, modal pause, half/full energy, co-op keys, AI exclusion, solo completion and elevator gate")
	quit()
