extends RefCounted

const BLUE = preload("res://assets/third_party/kenney_pixel_ui/blue.png")
const BLUE_PRESSED = preload("res://assets/third_party/kenney_pixel_ui/blue_pressed.png")
const GREEN = preload("res://assets/third_party/kenney_pixel_ui/green.png")
const GREEN_PRESSED = preload("res://assets/third_party/kenney_pixel_ui/green_pressed.png")
const CHECK_ON = preload("res://assets/third_party/kenney_pixel_ui/check_on.png")
const CHECK_OFF = preload("res://assets/third_party/kenney_pixel_ui/check_off.png")
const PANEL = preload("res://assets/third_party/kenney_pixel_ui/panel.png")
const DIALOGUE_BLUE = preload("res://assets/third_party/kenney_pixel_ui/dialogue_blue.png")
const DIALOGUE_RED = preload("res://assets/third_party/kenney_pixel_ui/dialogue_red.png")

static func apply(button: Button, primary := false, variation := "") -> void:
	var normal := GREEN if primary else BLUE
	var pressed := GREEN_PRESSED if primary else BLUE_PRESSED
	var tint := Color("c9fbb1") if primary else Color(0.82, 0.50, 0.67)
	var hover_tint := Color.WHITE if primary else Color(0.95, 0.65, 0.79)
	if variation in ["violet", "rose"]:
		normal = PANEL
		pressed = PANEL
		tint = Color(0.79, 0.44, 1.03) if variation == "violet" else Color(1.10, 0.43, 0.56)
		hover_tint = tint.lightened(0.17)
	elif variation in ["teal", "cyan"]:
		tint = Color(0.73, 0.54, 0.51) if variation == "teal" else Color(0.70, 0.59, 0.82)
		hover_tint = tint.lightened(0.14)
	button.add_theme_stylebox_override("normal", _surface(normal, tint))
	button.add_theme_stylebox_override("hover", _surface(normal, hover_tint))
	button.add_theme_stylebox_override("pressed", _surface(pressed, tint, true))
	button.add_theme_stylebox_override("hover_pressed", _surface(pressed, hover_tint, true))
	button.add_theme_stylebox_override("disabled", _surface(normal, tint.darkened(0.34)))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("fff0a0") if primary else Color("a9eaff")
	focus.set_border_width_all(1)
	focus.set_expand_margin_all(2.0)
	button.add_theme_stylebox_override("focus", focus)
	var ink := Color("102917") if primary else Color("f5f9ff")
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", ink.darkened(0.12))
	button.add_theme_font_size_override("font_size", 14 if primary else 11)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if button is CheckButton:
		button.add_theme_icon_override("checked", CHECK_ON)
		button.add_theme_icon_override("unchecked", CHECK_OFF)
		button.add_theme_icon_override("checked_disabled", CHECK_ON)
		button.add_theme_icon_override("unchecked_disabled", CHECK_OFF)

static func panel(tint := Color(0.32, 0.40, 0.62)) -> StyleBoxTexture:
	return _surface(PANEL, tint)

static func dialogue_name(warm := false) -> StyleBoxTexture:
	return _surface(DIALOGUE_RED if warm else DIALOGUE_BLUE, Color(0.39, 0.21, 0.48) if warm else Color(0.20, 0.31, 0.47))

static func _surface(texture: Texture2D, tint: Color, is_pressed := false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 8.0)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 3.0 if is_pressed else 1.0
	style.content_margin_bottom = 1.0 if is_pressed else 3.0
	return style
