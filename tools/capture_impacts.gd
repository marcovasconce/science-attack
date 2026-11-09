extends SceneTree
var arena: Node2D
var player: Node2D
var enemy: Node2D
var burst: Node2D
var hud: Control

func _initialize() -> void: call_deferred("run")
func run() -> void:
	arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	arena.tutorial.step = 7
	arena.controls_locked = false
	arena.open_limit = 1230
	arena.get_node("WakeSequence").seek(3.6, true)
	arena.get_node("WakeSequence").pause()
	arena.get_node("HUD/Communicator").hide()
	arena.get_node("GoalMarker").hide()
	for actor in arena.players: actor.set_physics_process(false)
	for crate in arena.get_node("Breakables").get_children(): crate.freeze = true
	hud = arena.get_node("HUD/TeamHUD")
	hud.set_process(false)
	player = arena.players[0]
	player.position = Vector2(378, 260)
	player.sprite.play("attack")
	player.sprite.frame = 2
	player.sprite.pause()
	arena.players[1].position = Vector2(285, 296)
	arena.players[1].sprite.play("idle")
	arena._process(0.0)
	arena.get_node("Camera2D").position.x = 320
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	DirAccess.make_dir_recursive_absolute("res://.godot/impact_frames")
	var targets: Array = []
	arena.strike(player, 1, targets)
	burst = arena.get_node("ImpactEffects").get_child(0)
	burst.set_process(false)
	burst.sample(burst.lifetime * 2.1 / 6.0)
	hud._process(0.2)
	await capture("res://art/previews/impact_crate.png")
	for frame in 18:
		burst.sample(minf(burst.lifetime, frame / 30.0))
		await capture("res://.godot/impact_frames/%03d.png" % frame)
	burst.free()
	enemy = arena.GermScene.instantiate()
	enemy.hp = 1000
	arena.get_node("Actors").add_child(enemy)
	enemy.set_physics_process(false)
	for hit in 8:
		enemy.position = Vector2(365, 265)
		player.position = Vector2(335, 265)
		targets.clear()
		arena.strike(player, 1, targets)
		if hit < 7:
			arena.get_node("ImpactEffects").get_child(0).free()
	burst = arena.get_node("ImpactEffects").get_child(0)
	burst.set_process(false)
	burst.sample(burst.lifetime * 2.1 / 6.0)
	hud._process(0.2)
	await capture("res://art/previews/impact_enemy.png")
	for frame in 24:
		burst.sample(minf(burst.lifetime, frame / 30.0))
		await capture("res://.godot/impact_frames/%03d.png" % (frame + 18))
	arena.players[1].ai_controlled = false
	arena.players[1].register_combo_hit()
	arena.players[1].register_combo_hit()
	arena.players[1].register_combo_hit()
	hud._process(0.2)
	burst.sample(burst.lifetime * 3.1 / 6.0)
	await capture("res://art/previews/impact_coop.png")
	print("Captured crate and enemy animations, yellow combo and compact HUD in both modes.")
	quit()

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
