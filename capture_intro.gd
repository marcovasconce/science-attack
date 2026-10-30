extends SceneTree
## Render actual Godot frames for visual QA. Requires a rendering display driver.
## --script res://tools/capture_intro.gd [-- --sequence]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var scene = load("res://scenes/laboratory_intro.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	DirAccess.make_dir_recursive_absolute("res://art/previews")
	var samples := {"01_empty": 0.1, "02_red_alert": 0.9, "03_running": 4.3, "04_arrived": 6.1}
	for label in samples:
		scene.restart()
		scene.seek(samples[label])
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://art/previews/%s.png" % label)
		assert(result == OK, "Failed to save preview")
		print("Captured ", label)
	scene.restart()
	scene.seek(7.2)
	scene.dialogue.tick(30.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/05_max_dialogue.png")
	scene.dialogue.advance()
	scene.dialogue.tick(30.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/previews/06_amanda_dialogue.png")
	print("Captured both complete dialogue panels.")
	scene.dialogue.advance()
	var start: float = scene.sequence_start
	var machine = scene.shrinking
	var sequence_samples := {
		"07_amanda_stairs": 1.25,
		"08_amanda_waits": 2.9,
		"09_max_stairs": 4.7,
		"10_inside_tubes": machine.POWER_START,
		"11_green_pulse": machine.POWER_START + 0.525,
		"12_shrinking": machine.SHRINK_START + 1.4,
		"13_empty_tubes": machine.SHRINK_END + 0.1,
		"14_fade_out": scene.FADE_START + scene.FADE_DURATION * 0.5,
		"15_black_screen": scene.FADE_START + scene.FADE_DURATION + 0.1,
	}
	for label in sequence_samples:
		scene.seek(start + sequence_samples[label])
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://art/previews/%s.png" % label)
		assert(result == OK, "Failed to save machine sequence preview")
		print("Captured ", label)
	if "--sequence" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://.godot/shrinking_preview_frames")
		scene.restart()
		for frame in range(456):
			scene._process(1.0 / 12.0)
			# Auto-advance ONLY the exported preview, after time to read Max's line.
			if frame == 168:
				scene.dialogue.advance()
			if frame == 264:
				scene.dialogue.advance()
			await process_frame
			await RenderingServer.frame_post_draw
			var result := root.get_texture().get_image().save_png("res://.godot/shrinking_preview_frames/%04d.png" % frame)
			assert(result == OK, "Failed to save animation frame")
		print("Captured 456 animation frames at 12 fps, including the shrinking sequence.")
	quit()
