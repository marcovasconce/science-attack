extends Control
## Short portrait messages share one slot and never take control away from players.
const AMANDA = preload("res://assets/portraits/amanda_dialogue.png")
const MAX = preload("res://assets/portraits/dr_max_dialogue.png")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin = preload("res://scripts/menu_button.gd")
var frame := MenuSkin.panel(Color(0.22, 0.34, 0.39))
var seen: Dictionary = {}
var remaining := 0.0
var speaker := ""
var words := ""
var portrait: TextureRect
var title: Label
var message: Label
func _ready() -> void:
	position = Vector2(324,10)
	size = Vector2(304,102)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 16
	portrait = TextureRect.new()
	portrait.position = Vector2(8,25)
	portrait.size = Vector2(46,60)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	title = Label.new()
	title.position = Vector2(62,9)
	title.add_theme_font_override("font",FONT)
	title.add_theme_font_size_override("font_size",8)
	add_child(title)
	message = Label.new()
	message.position = Vector2(62,26)
	message.size = Vector2(232,71)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size",8)
	add_child(message)
	hide()
func say(key: String, who: String, line: String) -> void:
	if seen.has(key): return
	seen[key] = true
	speaker = who
	words = line
	title.text = who
	message.text = line
	portrait.texture = AMANDA if who == "DRA. AMANDA" else MAX
	remaining = 8.0
	modulate.a = 1
	show()
func _process(dt: float) -> void:
	if remaining <= 0 or get_tree().get_first_node_in_group("arena").controls_locked: return
	remaining = maxf(0,remaining-dt)
	modulate.a = minf(1,remaining/0.3)
	if remaining == 0: hide()
func _draw() -> void:
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
