extends Node

signal prompts_changed

const KEYBOARD := -1
const BUTTONS := {
	"attack": JOY_BUTTON_X, "jump": JOY_BUTTON_A, "dodge": JOY_BUTTON_B,
	"special": JOY_BUTTON_Y, "interact": JOY_BUTTON_RIGHT_SHOULDER,
	"heal": JOY_BUTTON_LEFT_SHOULDER,
	"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
	"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN,
	"accept": JOY_BUTTON_A, "cancel": JOY_BUTTON_B, "controls": JOY_BUTTON_START,
	"join": JOY_BUTTON_START, "move": JOY_BUTTON_DPAD_UP,
}
const DIRECTIONS := {
	"left": Vector2(JOY_AXIS_LEFT_X, -1), "right": Vector2(JOY_AXIS_LEFT_X, 1),
	"up": Vector2(JOY_AXIS_LEFT_Y, -1), "down": Vector2(JOY_AXIS_LEFT_Y, 1),
}
const GLYPHS := preload("res://scripts/pad_glyphs.gd")
const FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")

var devices: Array[int] = [KEYBOARD, KEYBOARD]
var sources: Array[int] = [KEYBOARD, KEYBOARD]
var families: Dictionary = {}
var menu_source := KEYBOARD
var consumed_start_frame := -1

func _ready() -> void:
	InputMap.add_action("pad_retry")
	Input.joy_connection_changed.connect(_connection_changed)
	for device in Input.get_connected_joypads(): _connection_changed(device, true)
	_add_button("ui_accept", -1, JOY_BUTTON_A)
	_add_button("ui_cancel", -1, JOY_BUTTON_B)
	for action in DIRECTIONS:
		_add_button("ui_" + action, -1, BUTTONS[action])
		_add_axis("ui_" + action, -1, DIRECTIONS[action])

func _connection_changed(device: int, connected: bool) -> void:
	if connected:
		var info := Input.get_joy_info(device)
		_attach_pad(device, classify(str(info.get("raw_name", "")) + " " + Input.get_joy_name(device), Input.get_joy_guid(device)))
	else:
		_detach_pad(device)

func classify(device_name: String, guid: String) -> StringName:
	var name := device_name.to_lower()
	if "dualshock" in name or "dualsense" in name or "playstation" in name or "ps4" in name or "ps5" in name or "sony" in name or guid.substr(8, 4) == "4c05":
		return &"ps"
	if "switch" in name or "joy-con" in name or "nintendo" in name or guid.substr(8, 4) == "7e05":
		return &"switch"
	if "xbox" in name or "xinput" in name or guid.substr(8, 4) == "5e04":
		return &"xbox"
	if name.begins_with("wireless controller"): return &"ps"
	return &"generic"

func _attach_pad(device: int, family: StringName) -> void:
	families[device] = family
	var vacant := devices.find(KEYBOARD)
	if vacant >= 0 and device not in devices:
		_set_slot(vacant, device)
		prompts_changed.emit()

func _detach_pad(device: int) -> void:
	families.erase(device)
	var slot := devices.find(device)
	if slot >= 0:
		_set_slot(slot, KEYBOARD)
		sources[slot] = KEYBOARD
		for spare in families:
			if spare not in devices:
				_set_slot(slot, spare)
				break
	if menu_source == device: menu_source = KEYBOARD
	prompts_changed.emit()

func _add_button(action: StringName, device: int, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	InputMap.action_add_event(action, event)

func _add_axis(action: StringName, device: int, axis: Vector2) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = int(axis.x) as JoyAxis
	event.axis_value = axis.y
	InputMap.action_add_event(action, event)

func _set_slot(slot: int, device: int) -> void:
	var old := devices[slot]
	var prefix := "p%d_" % slot
	var common := &"controls" if slot == 0 else &"join"
	for action in InputMap.get_actions():
		if not str(action).begins_with(prefix) and action != common and action != &"pad_retry": continue
		for event in InputMap.action_get_events(action):
			if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.device == old:
				InputMap.action_erase_event(action, event)
				Input.action_release(action)
	devices[slot] = device
	if device == KEYBOARD: return
	for name in BUTTONS:
		var action := StringName(prefix + name)
		if not InputMap.has_action(action): continue
		_add_button(action, device, BUTTONS[name])
		if DIRECTIONS.has(name): _add_axis(action, device, DIRECTIONS[name])
	_add_button(common, device, JOY_BUTTON_START)
	_add_button("pad_retry", device, JOY_BUTTON_BACK)

func choose_party(coop: bool) -> void:
	# One pad started from the keyboard can serve as the second seat.
	if coop and menu_source == KEYBOARD and devices[0] != KEYBOARD and devices[1] == KEYBOARD:
		var device := devices[0]
		_set_slot(0, KEYBOARD)
		sources[0] = KEYBOARD
		_set_slot(1, device)
	elif not coop and devices[0] == KEYBOARD and devices[1] != KEYBOARD:
		var device := devices[1]
		_set_slot(1, KEYBOARD)
		sources[1] = KEYBOARD
		_set_slot(0, device)
		if menu_source == device: sources[0] = device
	if coop and devices[1] != KEYBOARD:
		sources[1] = devices[1]
	prompts_changed.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_set_menu_source(KEYBOARD)
		for slot in 2:
			for action in ["left", "right", "up", "down", "attack", "jump", "dodge", "interact", "heal", "special"]:
				if event.is_action_pressed("p%d_%s" % [slot, action]):
					_set_source(slot, KEYBOARD)
					break
		return
	if event is InputEventMouseButton and event.pressed:
		_set_menu_source(KEYBOARD)
		return
	if event is InputEventJoypadButton and event.pressed:
		var arena := get_tree().current_scene
		if event.button_index == JOY_BUTTON_START and event.device == devices[0] and devices[1] == KEYBOARD and sources[0] == KEYBOARD and is_instance_valid(arena) and arena.is_in_group("arena") and not arena.controls_locked and arena.players[1].ai_controlled:
			_set_slot(0, KEYBOARD)
			_set_slot(1, event.device)
			Input.action_release("controls")
			Input.action_release("join")
			arena.players[1].ai_controlled = false
			consumed_start_frame = Engine.get_process_frames()
			get_viewport().set_input_as_handled()
	elif not (event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] and absf(event.axis_value) > 0.32):
		return

	if not families.has(event.device): return
	_set_menu_source(event.device)
	var slot := devices.find(event.device)
	if slot >= 0: _set_source(slot, event.device)

func _set_source(slot: int, device: int) -> void:
	if sources[slot] == device: return
	sources[slot] = device
	prompts_changed.emit()

func _set_menu_source(device: int) -> void:
	if menu_source == device: return
	menu_source = device
	prompts_changed.emit()

func glyph(player: int, action: String) -> Texture2D:
	var device := menu_source if player < 0 else sources[player]
	if device == KEYBOARD: return null
	return GLYPHS.icon(families.get(device, &"generic"), action)

func draw_hint(canvas: CanvasItem, at: Vector2, player: int, action: String, keyboard: String, caption: String) -> void:
	var texture := glyph(player, action)
	if texture != null:
		canvas.draw_texture_rect(texture, Rect2(at - Vector2(0, 12), Vector2(16, 16)), false)
		canvas.draw_string(FONT, at + Vector2(20, 0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("b2eaff"))
	else:
		canvas.draw_string(FONT, at, keyboard, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("b2eaff"))

func event_for(event: InputEvent, player: int, action: String) -> bool:
	if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.device != devices[player]: return false
	return event.is_action_pressed("p%d_%s" % [player, action])

func retry_requested(arena) -> bool:
	if Input.is_action_just_pressed("restart"): return true
	return Input.is_action_just_pressed("pad_retry") and (arena.get_node("HUD/ControlsPanel").visible or (arena.players[0].down and arena.players[1].down))

func help_requested() -> bool:
	return consumed_start_frame != Engine.get_process_frames() and Input.is_action_just_pressed("controls")

func navigation_step(event: InputEvent, held_axes: Dictionary) -> bool:
	if not event is InputEventJoypadMotion: return not event.is_echo()
	if not event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]: return false
	var channel := Vector2i(event.device, event.axis)
	var direction := signf(event.axis_value) if absf(event.axis_value) >= 0.55 else 0.0
	if held_axes.get(channel, 0.0) == direction: return false
	held_axes[channel] = direction
	return direction != 0.0

func label_hint(label: Label, player: int, action: String, keyboard: String, caption := "") -> void:
	multi_hint(label, [player], action, [keyboard], keyboard, caption)

func clear_hint(label: Label) -> void:
	var row := label.get_node_or_null("PadHints") as HBoxContainer
	if row != null: row.hide()

func defeat_hint(label: Label, keyboard: String, defeated: bool) -> void:
	if defeated:
		var player := 0 if glyph(0, "restart") != null else 1
		label_hint(label, player, "restart", keyboard, "TENTAR DE NOVO")
	else:
		clear_hint(label)
		label.text = ""

func multi_hint(label: Label, players: Array, action: String, keys: Array, keyboard: String, caption := "") -> void:
	var textures: Array[Texture2D] = []
	for player in players: textures.append(glyph(player, action))
	if textures.all(func(texture): return texture == null):
		clear_hint(label)
		label.text = keyboard
		return
	label.text = ""
	var row := label.get_node_or_null("PadHints") as HBoxContainer
	if row == null:
		row = HBoxContainer.new()
		row.name = "PadHints"
		row.position.y = -2
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 5)
		label.add_child(row)
	row.show()
	var signature := [textures, keys, caption]
	if row.get_meta("signature", []) == signature: return
	row.set_meta("signature", signature)
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for i in players.size():
		if textures[i] != null:
			var badge := TextureRect.new()
			badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			badge.texture = textures[i]
			badge.custom_minimum_size = Vector2(16, 16)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(badge)
		else:
			_append_prompt_text(row, label, keys[i])
	if not caption.is_empty(): _append_prompt_text(row, label, caption)

func _append_prompt_text(row: Control, source: Label, value: String) -> void:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = value
	label.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
	label.add_theme_color_override("font_color", source.get_theme_color("font_color"))
	row.add_child(label)
