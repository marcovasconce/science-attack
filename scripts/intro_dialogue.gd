extends Control
## Screen-space dialogue with concise opening lines.

signal completed

const PIXEL_FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin := preload("res://scripts/menu_button.gd")
const MAX_PORTRAIT := preload("res://assets/portraits/dr_max_dialogue.png")
const AMANDA_PORTRAIT := preload("res://assets/portraits/amanda_dialogue.png")
const LETTERS_PER_SECOND := 38.0
const BOX_SIZE := Vector2(608, 118)
const BOX_POSITION := Vector2(16, 26)
const LINES := [
	{
		"speaker": "DOUTOR MAX",
		"text": "Amanda, os germes escaparam da bancada!",
		"right": false,
		"edge": Color("5489d6"),
		"accent": Color("b2d9ff"),
	},
	{
		"speaker": "DOUTORA AMANDA",
		"text": "Pras cápsulas! Vamos atrás deles com nossos avatares.",
		"right": true,
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
var panel_edge := Color("5489d6")
var card := MenuSkin.panel(Color(0.22, 0.33, 0.55))
var title_plate := MenuSkin.dialogue_name()
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
	portrait.size = Vector2(82, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_name = $Speaker
	_style_label(speaker_name, font)
	speaker_name.name = "Speaker"
	body = $Speech
	_style_label(body, font)
	body.add_theme_font_size_override("font_size", 10)
	body.name = "Speech"
	body.size = Vector2(486, 56)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 6)
	body.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	hint = $ContinueHint
	_style_label(hint, font)
	hint.name = "ContinueHint"
	GameInput.prompts_changed.connect(_update_hint)
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
	panel_edge = line.edge
	card = MenuSkin.panel(Color(0.42, 0.29, 0.54) if portrait_on_right else Color(0.22, 0.33, 0.55))
	title_plate = MenuSkin.dialogue_name(portrait_on_right)
	portrait.texture = portraits[index]
	portrait.position = Vector2(514 if portrait_on_right else 12, 8)
	var text_x := 18.0 if portrait_on_right else 110.0
	speaker_name.position = Vector2(text_x, 15)
	speaker_name.text = line.speaker
	speaker_name.modulate = line.accent
	body.position = Vector2(text_x, 37)
	body.text = line.text
	body.visible_characters = 0
	hint.position = Vector2(text_x, 98)
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
		GameInput.clear_hint(hint)
	else:
		GameInput.label_hint(hint, -1, "accept", "ENTER  CONTINUAR", "CONTINUAR")


func _draw() -> void:
	draw_rect(Rect2(Vector2(3, 4), BOX_SIZE), Color(0.005, 0.01, 0.025, 0.65))
	draw_style_box(card, Rect2(Vector2.ZERO, BOX_SIZE))
	var title_x := 12.0 if portrait_on_right else 104.0
	draw_style_box(title_plate, Rect2(title_x, 8, 159, 22))
	var portrait_x := 512.0 if portrait_on_right else 10.0
	draw_rect(Rect2(portrait_x, 7, 86, 101), Color("080e21"))
	draw_rect(Rect2(portrait_x + 1, 8, 84, 99), Color(panel_edge, 0.12))
	var divider_start := 12.0 if portrait_on_right else 104.0
	var divider_end := 504.0 if portrait_on_right else 596.0
	draw_line(Vector2(divider_start, 91), Vector2(divider_end, 91), Color(panel_edge, 0.55), 1.0)
