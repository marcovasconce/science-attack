extends SceneTree
## Captures the real scene at its 640x360 logical resolution.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/gameplay/micro_arena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	arena.set_process(false)
	arena.tutorial.set_process(false)
	for actor in arena.players:
		actor.set_physics_process(false)
		actor.sprite.play("idle")
	var wake: AnimationPlayer = arena.get_node("WakeSequence")
	wake.play("wake")
	wake.seek(3.6, true)
	wake.pause()
	arena.controls_locked = false
	arena.players[0].position = Vector2(250, 260)
	arena.players[1].position = Vector2(200, 295)
	arena.tutorial.step = 1
	arena.tutorial._process(0.0)
	arena._process(0.0)
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	await capture("hud_solo")
	arena.players[1].ai_controlled = false
	arena.players[0].hp = 76
	arena.players[1].hp = 58
	arena.tutorial._process(0.0)
	await capture("hud_coop")
	arena.players[1].use_healing_flask()
	await capture("hud_healing")
	arena.players[0].hp = 0
	arena.players[0].down = true
	arena.players[1].healing_flasks = 0
	await capture("hud_empty_downed")
	print("Captured solo, co-op, healing and downed HUD views.")
	quit()

func capture(file_name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/" + file_name + ".png")
