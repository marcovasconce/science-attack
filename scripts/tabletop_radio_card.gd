extends Control
## A short radio message that never captures gameplay input.
signal closed
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
var active := false
var remaining := 0.0
var age := 0.0
var frame: StyleBoxFlat

func _ready() -> void:
	position = Vector2(320,10)
	size = Vector2(308,78)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame = StyleBoxFlat.new()
	frame.bg_color = Color("102346")
	frame.border_color = Color("76cbd3")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(5)
	$Speaker.position = Vector2(43,9)
	$Speaker.add_theme_font_override("font",FONT)
	$Speaker.add_theme_font_size_override("font_size",8)
	$Speaker.modulate = Color("b2eaff")
	$Message.position = Vector2(43,25)
	$Message.size = Vector2(255,46)
	$Message.add_theme_font_size_override("font_size",15)
	$Message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Message.add_theme_constant_override("line_spacing",2)
	$RadioPortrait.position = Vector2(22,43)
	$RadioPortrait.scale = Vector2.ONE
	$Key.hide()
	for label in [$Speaker,$Message,$Key]: label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func open_line(_speaker: String, words: String, _player_id := 0) -> void:
	$Speaker.text = "TIBÚRCIO"
	$Message.text = words
	$Message.visible_characters = -1
	remaining = clampf(3.0+words.split(" ",false).size()*0.65,9.0,15.0)
	age = 0
	active = true
	modulate.a = 1
	show()

func _process(dt: float) -> void:
	if not active: return
	var arena = get_tree().get_first_node_in_group("arena")
	if is_instance_valid(arena) and arena.controls_locked:
		hide()
		return
	show()
	age += dt
	remaining = maxf(0,remaining-dt)
	modulate.a = minf(1,remaining/0.25)
	if remaining <= 0: dismiss()

func dismiss() -> void:
	active = false
	hide()
	closed.emit()

func _draw() -> void:
	if frame != null: draw_style_box(frame,Rect2(Vector2.ZERO,size))
