extends SceneTree
var arena: Node2D
var serial := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.encounter.set_process(false)
	arena.get_node("WakeSequence").seek(3.6,true)
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	arena.open_limit = 2230
	for player in arena.players: player.set_physics_process(false)
	for crate in arena.get_node("Breakables").get_children():
		crate.freeze = true
		crate.broken = true
		crate.hide()
	arena.get_node("HUD/Communicator").hide()
	arena.get_node("GoalMarker").hide()
	arena.get_node("HUD/Goal").hide()
	arena.get_node("BuildSite").set_process(false)
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	DirAccess.make_dir_recursive_absolute("res://.godot/equipment_frames")
	arena.tutorial.step = 6
	arena.collect_parts(3,Vector2(410,260))
	arena.collect_parts(3,Vector2(460,310))
	arena.collect_parts(2,Vector2(510,210))
	arena.get_node("BuildSite")._process(1)
	arena.players[0].position = Vector2(530,250)
	arena.players[1].position = Vector2(492,290)
	arena.get_node("Camera2D").position.x = 590
	for frame in 24:
		arena.get_node("BuildSite").sample(frame/30.0)
		for p in arena.players: pose(p,"build",frame%12)
		if frame == 10: await capture("res://art/previews/assembly_empty_hands.png")
		await sequence()
	arena.get_node("BuildSite").sample(1)
	arena.built = true
	arena.tutorial.step = 7
	arena.encounter.unlock_route()
	arena.encounter.talked = true
	arena.get_node("Gate/Collision").disabled = true
	arena.players[0].position = Vector2(1860,260)
	arena.players[1].position = Vector2(1920,317)
	arena.get_node("Camera2D").position.x = 1920
	for p in arena.players: p.equip_weapon("brush")
	for anim in ["brush_attack","brush_rise","brush_slam"]:
		var count: int = arena.players[0].sprite.sprite_frames.get_frame_count(anim)
		for frame in count:
			for p in arena.players: pose(p,anim,frame)
			if frame == 4:
				await capture("res://art/previews/%s.png" % anim)
				if anim == "brush_attack": await capture("res://art/previews/toothbrush_swords.png")
			await sequence()
	var air_count: int = arena.players[0].sprite.sprite_frames.get_frame_count("brush_air")
	for frame in air_count:
		for p in arena.players:
			p.get_node("Visual").position.y = -sin(frame/float(air_count-1)*PI)*34
			pose(p,"brush_air",frame)
		if frame == 4: await capture("res://art/previews/brush_air.png")
		await sequence()
	for p in arena.players: p.get_node("Visual").position.y = 0
	for p in arena.players: p.equip_weapon("bubbles")
	for frame in 32:
		for p in arena.players:
			pose(p,"bubbles_attack",frame%4)
			if frame%4 == 0: arena.spawn_bubble(p)
		for shot in arena.get_node("Projectiles").get_children():
			shot.set_physics_process(false)
			shot._physics_process(0.06)
		if frame == 20: await capture("res://art/previews/soap_bubble_fire.png")
		await sequence()
	for shot in arena.get_node("Projectiles").get_children(): shot.queue_free()
	arena.players[0].equip_weapon("brush")
	arena.encounter.equipment.open_panel(0)
	arena.controls_locked = true
	await capture("res://art/previews/equipment_selection.png")
	print("Captured original-pixel assembly, all three brush combo swings, airborne swing, both soap guns and equipment choice.")
	quit()
func pose(player, animation: String, frame: int) -> void:
	player.sprite.play(animation)
	player.sprite.frame = frame
	player.sprite.pause()
	player.sprite.flip_h = false
	player.update_sprite_alignment()
func sequence() -> void:
	await capture("res://.godot/equipment_frames/%03d.png" % serial)
	serial += 1
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
