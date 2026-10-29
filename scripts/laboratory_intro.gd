extends Node2D
## Opening: alarm -> entrance -> dialogue -> stairs -> shrinking machine.
## intro_finished fires after the final fade to black.

signal intro_finished
signal actors_arrived
signal dialogue_finished

const Actor := preload("res://scripts/cutscene_actor.gd")
const Dialogue := preload("res://scripts/intro_dialogue.gd")
const Shrinking := preload("res://scripts/sleep_sequence.gd")
const Foreground := preload("res://scripts/laboratory_foreground.gd")
const MAX_SHEET := preload("res://assets/characters/dr_max.png")
const SCIENTIST_SHEET := preload("res://assets/characters/scientist.png")
const VIEW := Vector2(640, 360)
const ALARM_PERIOD := 1.8
const MAX_ENTRANCE := 3.0
const SCIENTIST_ENTRANCE := 3.0
const MAX_ARRIVAL := 5.70
const SCIENTIST_ARRIVAL := 5.70
const MAX_START := Vector2(-36, 337)
const MAX_STOP := Vector2(232, 337)
const SCIENTIST_START := Vector2(16, 340)
const SCIENTIST_STOP := Vector2(284, 340)
const CAMERA_ZOOM := 1.28
const CAMERA_DURATION := 1.35
const DIALOGUE_START := 6.18
const FADE_START := Shrinking.SHRINK_END + 0.3
const FADE_DURATION := 1.5

var elapsed := 0.0
var paused := false
var finished := false
var arrived := false
var dialogue_started := false
var doctor_max: Node2D
var scientist: Node2D
var ambience: Node2D
var alarm_tint: ColorRect
var pause_label: Label
var camera: Camera2D
var dialogue: Control
var shrinking: Node2D
var sequence_start := -1.0
var sequence_camera_position := VIEW * 0.5
var sequence_camera_zoom := 1.0
var ending_black: ColorRect


func _ready() -> void:
	var background: Sprite2D = $Laboratory
	background.scale = VIEW / Vector2(background.texture.get_size())
	ambience = $AnimatedMonitors
	ambience.name = "AnimatedMonitors"
	ambience.draw.connect(_draw_ambience)
	doctor_max = $DrMax
	doctor_max.name = "DrMax"
	doctor_max.configure(MAX_SHEET, 74.0, true)
	scientist = $DrAmanda
	scientist.name = "DrAmanda"
	scientist.configure(SCIENTIST_SHEET, 72.0)
	var foreground := $ForegroundRailings
	foreground.name = "ForegroundRailings"
	shrinking = $SleepSequence
	shrinking.name = "SleepSequence"
	shrinking.configure(doctor_max, scientist)
	camera = $ConversationCamera
	camera.name = "ConversationCamera"
	camera.position = VIEW * 0.5
	camera.make_current()
	_build_overlay()
	dialogue = $DialogueLayer/IntroDialogue
	dialogue.completed.connect(_on_dialogue_completed)
	ending_black = $EndingFade/Black
	seek(0.0)


func _build_overlay() -> void:
	alarm_tint = $CinematicOverlay/RedAlarm
	pause_label = $CinematicOverlay/Pause


func _label(value: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.04, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _process(delta: float) -> void:
	if not paused:
		seek(elapsed + delta)
		dialogue.tick(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_R:
		restart()
	elif event.keycode == KEY_SPACE:
		set_paused(not paused)
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER] and not paused:
		dialogue.advance()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not paused and dialogue.active:
			dialogue.advance()
			get_viewport().set_input_as_handled()


func set_paused(value: bool) -> void:
	paused = value
	pause_label.visible = paused


func restart() -> void:
	finished = false
	arrived = false
	dialogue_started = false
	sequence_start = -1.0
	shrinking.reset()
	dialogue.reset()
	set_paused(false)
	seek(0.0)


func seek(time: float) -> void:
	elapsed = maxf(0.0, time)
	if sequence_start < 0.0:
		_stage_actor(doctor_max, MAX_ENTRANCE, MAX_ARRIVAL, MAX_START, MAX_STOP, false)
		_stage_actor(scientist, SCIENTIST_ENTRANCE, SCIENTIST_ARRIVAL,
			SCIENTIST_START, SCIENTIST_STOP, true)
	else:
		shrinking.sample(elapsed - sequence_start)
	_update_camera()
	var pulse := alarm_strength()
	var alarm_level := 1.0
	if shrinking.active:
		alarm_level = lerpf(1.0, 0.2, smoothstep(Shrinking.ENTRY_START, Shrinking.POWER_START, shrinking.elapsed))
	alarm_tint.color = Color(0.91, 0.018, 0.045, (0.025 + pulse * 0.22) * alarm_level)
	ambience.queue_redraw()
	if elapsed >= SCIENTIST_ARRIVAL and not arrived:
		arrived = true
		actors_arrived.emit()
	if elapsed >= DIALOGUE_START and not dialogue_started:
		dialogue_started = true
		dialogue.begin()
	_update_ending()


func _update_camera() -> void:
	if sequence_start >= 0.0:
		_update_machine_camera()
		return
	var progress := smoothstep(0.0, CAMERA_DURATION, elapsed - SCIENTIST_ARRIVAL)
	camera.zoom = Vector2.ONE * lerpf(1.0, CAMERA_ZOOM, progress)
	# Keep both actors centered and the bottom edge of the room inside the frame.
	var destination := Vector2((MAX_STOP.x + SCIENTIST_STOP.x) * 0.5,
		VIEW.y - VIEW.y / (2.0 * CAMERA_ZOOM))
	camera.position = (VIEW * 0.5).lerp(destination, progress)
	camera.force_update_scroll()


func _on_dialogue_completed() -> void:
	if sequence_start >= 0.0:
		return
	sequence_start = elapsed
	sequence_camera_position = camera.position
	sequence_camera_zoom = camera.zoom.x
	shrinking.begin()
	dialogue_finished.emit()


func _update_machine_camera() -> void:
	var time := maxf(0.0, elapsed - sequence_start)
	var opening := smoothstep(0.0, 1.1, time)
	var wide_center := VIEW * 0.5
	var focus := smoothstep(Shrinking.MAX_ARRIVAL, Shrinking.MAX_ARRIVAL + 1.6, time)
	camera.zoom = Vector2.ONE * lerpf(lerpf(sequence_camera_zoom, 1.0, opening), 1.65, focus)
	camera.position = sequence_camera_position.lerp(wide_center, opening).lerp(Vector2(371, 182), focus)
	camera.force_update_scroll()


func _update_ending() -> void:
	if sequence_start < 0.0:
		ending_black.color.a = 0.0
		return
	var time := elapsed - sequence_start
	ending_black.color.a = smoothstep(FADE_START, FADE_START + FADE_DURATION, time)
	if time >= FADE_START + FADE_DURATION and not finished:
		finished = true
		intro_finished.emit()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/gameplay/micro_arena.tscn")


func _stage_actor(actor: Node2D, start_time: float, end_time: float,
		start: Vector2, destination: Vector2, turn_left: bool) -> void:
	actor.visible = elapsed >= start_time
	if not actor.visible:
		actor.position = start
		return
	var running := elapsed < end_time
	var travel := clampf((elapsed - start_time) / (end_time - start_time), 0.0, 1.0)
	# Linear travel matches the run cycle; a short deceleration settles the last step.
	var distance := travel / 0.94 if travel < 0.88 else 1.0 - pow(1.0 - travel, 2.0) / 0.2256
	actor.position = start.lerp(destination, clampf(distance, 0.0, 1.0)).round()
	actor.show_pose(&"run" if running else &"idle",
		elapsed - (start_time if running else end_time), turn_left and not running)


func alarm_strength() -> float:
	# A smooth 1.8-second pulse, never a rapid strobe.
	return pow((sin(elapsed * TAU / ALARM_PERIOD - PI * 0.5) + 1.0) * 0.5, 1.3)


func _draw_ambience() -> void:
	var cyan := Color(0.22, 0.94, 1.0, 0.85)
	var teal := Color(0.16, 0.8, 0.91, 0.5)
	# Main wall display. Animated traces stay inside the original glass panel.
	ambience.draw_rect(Rect2(86, 145, 107, 43), Color(0.01, 0.10, 0.29, 0.78))
	for y in range(150, 187, 8):
		ambience.draw_line(Vector2(89, y), Vector2(190, y), Color(0.1, 0.55, 0.85, 0.2))
	for x in range(91, 191, 10):
		ambience.draw_line(Vector2(x, 148), Vector2(x, 186), Color(0.1, 0.55, 0.85, 0.2))
	var wave := PackedVector2Array()
	for x in range(100):
		var phase := float(x) * 0.15 + elapsed * 2.5
		wave.append(Vector2(90 + x, roundf(166 + sin(phase) * 8.0 + sin(phase * 2.3) * 3.0)))
	ambience.draw_polyline(wave, cyan, 1.0)
	var sweep := 90.0 + fmod(elapsed * 25.0, 99.0)
	ambience.draw_line(Vector2(sweep, 148), Vector2(sweep, 185), Color(0.55, 1.0, 1.0, 0.55))
	# Scrolling data on the side of the main monitor.
	for line in range(8):
		var row := (line + int(elapsed * 3.0)) % 8
		ambience.draw_rect(Rect2(65, 146 + line * 3, 5 + (row * 7) % 15, 1), teal)
	for bar in range(7):
		var height := roundf(3.0 + (sin(elapsed * 2.0 + bar * 0.9) + 1.0) * 7.0)
		ambience.draw_rect(Rect2(199 + bar * 2, 189 - height, 1, height), cyan)
	# The lower workstation is where Dr. Max stops.
	ambience.draw_rect(Rect2(240, 282, 20, 15), Color("071e31"))
	for line in range(4):
		var width := 5 + (line * 3 + int(elapsed * 2.0)) % 12
		ambience.draw_rect(Rect2(242, 284 + line * 3, width, 1), teal)
	if int(elapsed * 2.0) % 2 == 0:
		ambience.draw_rect(Rect2(255, 294, 2, 1), cyan)
	# Small pulses on the other desktop displays.
	for screen_x in [192, 214]:
		for index in range(4):
			var lit := (int(elapsed * 4.0) + index) % 4
			ambience.draw_rect(Rect2(screen_x + index * 3, 296 - lit, 2, 1 + lit), teal)
	# Slow bubbles in the three empty specimen tanks.
	for tank in range(3):
		for bubble in range(5):
			var x := 285.0 + tank * 55.0 + fmod(bubble * 7.0, 26.0)
			var y := 194.0 - fmod(elapsed * (5.0 + bubble) + bubble * 10.0, 49.0)
			ambience.draw_rect(Rect2(roundf(x), roundf(y), 1, 2), Color(0.6, 1.0, 0.85, 0.65))
	# Alarm lamps pulse with the red screen wash.
	var intensity := alarm_strength()
	for x in [90, 188, 309, 411, 518]:
		ambience.draw_rect(Rect2(x, 6, 12, 3), Color(1.0, 0.12, 0.10, intensity * 0.92))
