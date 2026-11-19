@tool
extends Control
## Same font, colors, hard pixel frame and portrait inset as the opening dialogue.
const PIXEL_FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const EDGE := Color("5489d6")
const ACCENT := Color("b2d9ff")
const MenuSkin = preload("res://scripts/menu_button.gd")
var frame := MenuSkin.panel(Color(0.25, 0.35, 0.52))
var name_plate := MenuSkin.dialogue_name()
var previous_text := ""
var reveal := 0.0

func _ready() -> void:
	var font: FontFile = PIXEL_FONT.duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.multichannel_signed_distance_field = false
	for label in [$Message, $Key, $Speaker]:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.06, 0.7))
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Speaker.modulate = ACCENT
	$Key.modulate = ACCENT
	$Message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Message.add_theme_constant_override("line_spacing", 4)
	$Message.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	$Key.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_node_ready(): return
	$Speaker.position = Vector2(70, 10)
	$Speaker.size = Vector2(size.x - 82, 10)
	$Message.position = Vector2(70, 26)
	$Message.size = Vector2(size.x - 82, 25)
	$Key.position = Vector2(70, size.y - 16)
	$Key.size = Vector2(size.x - 82, 12)
	$RadioPortrait.position = Vector2(33, 35)
	$RadioPortrait.scale = Vector2(1.25, 1.25)
	queue_redraw()

func _process(dt: float) -> void:
	if Engine.is_editor_hint(): return
	var arena = get_tree().get_first_node_in_group("arena")
	if is_instance_valid(arena) and arena.controls_locked: return
	if $Message.text != previous_text:
		previous_text = $Message.text
		reveal = 0.0
	reveal += dt * 38.0
	$Message.visible_characters = mini(int(reveal), previous_text.length())

func _draw() -> void:
	draw_rect(Rect2(Vector2(3, 4), size), Color(0.005, 0.01, 0.025, 0.65))
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
	draw_style_box(name_plate, Rect2(64, 4, 150, 17))
	draw_rect(Rect2(10, 7, 46, size.y - 14), Color("080e21"))
	draw_rect(Rect2(11, 8, 44, size.y - 16), Color(EDGE, 0.12))
	draw_line(Vector2(70, size.y - 22), Vector2(size.x - 12, size.y - 22), Color(EDGE, 0.55), 1.0)
