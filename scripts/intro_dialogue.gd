extends Control
## Screen-space dialogue with concise opening lines.

signal completed

const PIXEL_FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MAX_PORTRAIT := preload("res://assets/portraits/dr_max_dialogue.png")
const AMANDA_PORTRAIT := preload("res://assets/portraits/amanda_dialogue.png")
const LETTERS_PER_SECOND := 38.0
const BOX_SIZE := Vector2(608, 148)
const BOX_POSITION := Vector2(16, 26)
const LINES := [
	{
		"speaker": "DOUTOR MAX",
		"text": "Os germes estão fora de controle! Não podemos deixar que escapem!",
		"right": false,
		"fill": Color("102346"),
		"edge": Color("5489d6"),
		"accent": Color("b2d9ff"),
	},
	{
		"speaker": "DOUTORA AMANDA",
		"text": "Vamos dormir nas cápsulas. Os microavatares vão combater os germes!",
		"right": true,
		"fill": Color("361b4b"),
		"edge": Color("a774c7"),
		"accent": Color("e6c5ff"),
	},
]

var active := false
var line_index := -1
var line_elapsed := 0.0
var presentation_elapsed := 0.0
var fully_revealed := false
var portrait_on_right := false
var panel_fill := Color("102346")
var panel_edge := Color("5489d6")
var body: Label
var speaker_name: Label
var hint: Label
var portrait: TextureRect
var portraits: Array[Texture2D] = []


func _ready() -> void:
	position = BOX_POSITION
	size = BOX_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var font: FontFile = PIXEL_FONT.duplicate()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.multichannel_signed_distance_field = false
	for source in [MAX_PORTRAIT, AMANDA_PORTRAIT]:
		var crop := AtlasTexture.new()
		crop.atlas = source
		var bounds: Rect2i = source.get_image().get_used_rect()
		# A chest-up portrait has a clean, straight lower crop inside its frame.
		bounds.size.y -= int(bounds.size.y * 0.025)
		crop.region = Rect2(bounds)
		crop.filter_clip = true
		portraits.append(crop)
	portrait = $SpeakingPortrait
	portrait.name = "SpeakingPortrait"
	portrait.size = Vector2(100, 114)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_name = $Speaker
	_style_label(speaker_name, font)
	speaker_name.name = "Speaker"
	body = $Speech
	_style_label(body, font)
	body.name = "Speech"
	body.size = Vector2(462, 90)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 6)
	body.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	hint = $ContinueHint
	_style_label(hint, font)
	hint.name = "ContinueHint"
	reset()


func _style_label(label: Label, font: Font) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.025, 0.06, 0.7))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func begin() -> void:
	if active:
		return
	active = true
	visible = true
	presentation_elapsed = 0.0
	modulate.a = 0.0
	_show_line(0)


func reset() -> void:
	active = false
	visible = false
	line_index = -1
	line_elapsed = 0.0
	presentation_elapsed = 0.0
	fully_revealed = false
	position = BOX_POSITION
	modulate.a = 0.0
	body.text = ""
	body.visible_characters = 0


func _show_line(index: int) -> void:
	line_index = index
	line_elapsed = 0.0
	fully_revealed = false
	var line: Dictionary = LINES[index]
	portrait_on_right = line.right
	panel_fill = line.fill
	panel_edge = line.edge
	portrait.texture = portraits[index]
	portrait.position = Vector2(494 if portrait_on_right else 12, 8)
	var text_x := 18.0 if portrait_on_right else 128.0
	speaker_name.position = Vector2(text_x, 15)
	speaker_name.text = line.speaker
	speaker_name.modulate = line.accent
	body.position = Vector2(text_x, 37)
	body.text = line.text
	body.visible_characters = 0
	hint.position = Vector2(18, 132)
	hint.modulate = line.accent
	_update_hint()
	queue_redraw()


func tick(delta: float) -> void:
	if not active:
		return
	presentation_elapsed += delta
	var appearance := smoothstep(0.0, 0.32, presentation_elapsed)
	modulate.a = appearance
	position.y = BOX_POSITION.y - roundf(4.0 * (1.0 - appearance))
	if not fully_revealed:
		line_elapsed += delta
		body.visible_characters = mini(int(line_elapsed * LETTERS_PER_SECOND), body.text.length())
		fully_revealed = body.visible_characters >= body.text.length()
	_update_hint()


func advance() -> void:
	if not active:
		return
	if not fully_revealed:
		body.visible_characters = -1
		fully_revealed = true
		_update_hint()
	elif line_index + 1 < LINES.size():
		_show_line(line_index + 1)
	else:
		active = false
		visible = false
		completed.emit()


func _update_hint() -> void:
	if not fully_revealed:
		hint.text = ""
	else:
		hint.text = "ENTER  >"


func _draw() -> void:
	draw_rect(Rect2(Vector2(3, 4), BOX_SIZE), Color(0.005, 0.01, 0.025, 0.65))
	draw_rect(Rect2(Vector2.ZERO, BOX_SIZE), Color("080e21"))
	draw_rect(Rect2(Vector2.ONE, BOX_SIZE - Vector2(2, 2)), panel_edge)
	draw_rect(Rect2(Vector2(3, 3), BOX_SIZE - Vector2(6, 6)), panel_fill)
	draw_rect(Rect2(5, 4, 598, 1), Color(panel_edge, 0.5))
	var portrait_x := 492.0 if portrait_on_right else 10.0
	draw_rect(Rect2(portrait_x, 7, 104, 117), Color("080e21"))
	draw_rect(Rect2(portrait_x + 1, 8, 102, 115), Color(panel_edge, 0.12))
	draw_line(Vector2(12, 126), Vector2(596, 126), Color(panel_edge, 0.55), 1.0)
