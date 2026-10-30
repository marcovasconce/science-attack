extends SceneTree
var arena: Node2D
var crate: Node2D
var build: Node2D
var player: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.get_node("WakeSequence").seek(3.6, true)
	arena.get_node("WakeSequence").pause()
	arena.controls_locked = false
	arena.open_limit = 1230
	arena.tutorial.step = 4
	for actor in arena.players: actor.set_physics_process(false)
	for box in arena.get_node("Breakables").get_children():
		box.freeze = true
		box.set_process(false)
	crate = arena.get_node("Breakables/Crate0")
	build = arena.get_node("BuildSite")
	build.set_process(false)
	player = arena.players[0]
	player.position = Vector2(368, 260)
	player.sprite.play("idle")
	arena.players[1].position = Vector2(290, 300)
	arena.players[1].sprite.play("idle")
	arena.tutorial._process(0.0)
	arena._process(0.0)
	arena.get_node("Camera2D").position.x = 320
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	DirAccess.make_dir_recursive_absolute("res://.godot/crate_salvage_frames")
	await capture("res://art/previews/metal_crate_intact.png")
	for frame in 64:
		if frame == 12 or frame == 30:
			crate.take_hit(18, 1.0, player)
			player.sprite.play("attack")
			player.sprite.frame = 2
			player.sprite.pause()
		if frame == 24 or frame == 42: player.sprite.play("idle")
		crate._process(1.0 / 24.0)
		build._process(1.0 / 24.0)
		for burst in arena.get_node("ImpactEffects").get_children():
			burst.set_process(false)
			burst._process(1.0 / 24.0)
		if frame == 26: await capture("res://art/previews/metal_crate_damaged.png")
		if frame == 34: await capture("res://art/previews/metal_crate_breaking.png")
		if frame == 63: await capture("res://art/previews/salvage_dropped.png")
		await capture("res://.godot/crate_salvage_frames/%03d.png" % frame)
	arena.tutorial.step = 7
	arena.get_node("HUD/Communicator").hide()
	arena.get_node("GoalMarker").hide()
	var enemy = arena.GermScene.instantiate()
	enemy.hp = 1000
	enemy.position = Vector2(360, 260)
	arena.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	player.position = Vector2(330, 260)
	player.sprite.play("attack")
	player.sprite.frame = 2
	player.sprite.pause()
	var targets: Array = []
	arena.strike(player, 1, targets)
	var star = arena.get_node("ImpactEffects").get_child(0)
	star.set_process(false)
	star.sample(star.lifetime * 2.1 / 6.0)
	await capture("res://art/previews/enemy_star_impact.png")
	for frame in 20:
		star.sample(minf(star.lifetime, frame / 24.0))
		await capture("res://.godot/crate_salvage_frames/%03d.png" % (frame + 64))
	star.free()
	enemy.free()
	arena.tutorial.step = 6
	for index in [1, 2]:
		arena.get_node("Breakables/Crate%d" % index).take_hit(32, 1.0, player)
	for box in arena.get_node("Breakables").get_children(): box._process(1.0)
	for burst in arena.get_node("ImpactEffects").get_children(): burst.queue_free()
	build._process(1.0)
	player.position = Vector2(525, 266)
	arena.players[1].position = Vector2(485, 291)
	arena.get_node("Camera2D").position.x = 440
	arena.interact(player, 1.4)
	for actor in arena.players:
		actor.sprite.play("build")
		actor.sprite.frame = 3
		actor.sprite.pause()
	await capture("res://art/previews/salvage_construction.png")
	print("Captured metal crate, cracked/breaking states, detailed dropped parts, new star and construction.")
	quit()
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
