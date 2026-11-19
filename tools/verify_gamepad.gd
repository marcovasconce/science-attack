extends SceneTree

const Catalogue = preload("res://scripts/chapter_catalog.gd")
var failures := 0
var router

func _initialize() -> void:
	run.call_deferred()

func require(ok: bool, detail: String) -> void:
	if ok: return
	failures += 1
	push_error(detail)

func button(device: int, control: JoyButton, pressed: bool = true) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = control
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func stick(device: int, amount: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = amount
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	router = root.get_node("GameInput")
	for device in router.devices.duplicate():
		if device >= 0: router._detach_pad(device)
	require(router.classify("DualSense Wireless Controller", "") == &"ps", "DualSense classification")
	require(router.classify("DualShock 4", "") == &"ps", "DualShock classification")
	require(router.classify("Xbox Controller", "") == &"xbox", "Xbox classification")
	require(router.classify("Nintendo Switch Pro Controller", "") == &"switch", "Nintendo classification")
	require(router.classify("USB Gamepad", "") == &"generic", "Generic controller classification")
	router._attach_pad(4, &"ps")
	router._attach_pad(5, &"xbox")
	button(4, JOY_BUTTON_X)
	require(Input.is_action_pressed("p0_attack") and not Input.is_action_pressed("p1_attack"), "PlayStation attacks only for P1")
	button(5, JOY_BUTTON_A)
	require(Input.is_action_pressed("p1_jump") and not Input.is_action_pressed("p0_jump"), "Xbox jumps only for P2")
	require(router.glyph(0, "jump") != router.glyph(1, "jump"), "Both players get different glyph families")
	button(4, JOY_BUTTON_X, false)
	button(5, JOY_BUTTON_A, false)
	stick(4, 1.0)
	require(Input.is_action_pressed("p0_right") and not Input.is_action_pressed("p1_right"), "Left stick moves only the assigned player")
	stick(4, 0.0)
	require(not Input.is_action_pressed("p0_right"), "Stick returns to neutral")
	button(5, JOY_BUTTON_RIGHT_SHOULDER)
	require(Input.is_action_pressed("p1_interact"), "Xbox right bumper performs the shared interaction")
	router._detach_pad(5)
	require(not Input.is_action_pressed("p1_interact") and router.glyph(1, "interact") == null, "Unplug clears actions and restores the keyboard prompt")
	button(5, JOY_BUTTON_RIGHT_SHOULDER, false)

	Catalogue.open(self, 1)
	await scene_changed
	var arena = current_scene
	arena.controls_locked = false
	router._set_source(0, router.KEYBOARD)
	await process_frame
	button(4, JOY_BUTTON_START)
	arena._process(0.0)
	require(router.devices == [-1, 4] and not arena.players[1].ai_controlled, "Start adds P2 when P1 plays on keyboard")
	button(4, JOY_BUTTON_START, false)
	require(router.glyph(1, "interact") != null and router.glyph(0, "interact") == null, "Mixed input retains separate prompts")
	arena.tutorial.step = 2
	arena.tutorial._process(0.0)
	var keys: Label = arena.get_node("HUD/Communicator/Key")
	var mixed := keys.get_node_or_null("PadHints")
	require(mixed != null and mixed.get_child_count() == 2 and mixed.get_child(0) is Label and mixed.get_child(1) is TextureRect, "Mixed tutorial shows the keyboard key and PlayStation icon")

	Catalogue.open(self, 21)
	await scene_changed
	arena = current_scene
	arena.players[1].ai_controlled = false
	arena.puzzle.open(1)
	arena.puzzle._process(2.0)
	button(4, JOY_BUTTON_DPAD_RIGHT)
	button(4, JOY_BUTTON_DPAD_RIGHT, false)
	require(arena.puzzle.cursor == 1, "Controller moves through the puzzle")
	button(4, JOY_BUTTON_A)
	button(4, JOY_BUTTON_A, false)
	require(arena.puzzle.selected == 1, "Controller selects a puzzle tile")
	button(4, JOY_BUTTON_B)
	button(4, JOY_BUTTON_B, false)
	require(not arena.puzzle.active, "Controller closes the puzzle")
	print("Gamepad checks complete. Failures: ", failures)
	quit(1 if failures else 0)
