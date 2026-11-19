extends Control
const PORTRAIT = preload("res://assets/portraits/amanda_dialogue.png")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin = preload("res://scripts/menu_button.gd")
var frame := MenuSkin.panel(Color(0.22, 0.34, 0.39))
var remaining := 0.0
var shown := false

func _ready() -> void:
	position = Vector2(338,12)
	size = Vector2(290,70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 15
	hide()

func announce() -> void:
	if shown: return
	shown = true
	remaining = 4.5
	show()
	queue_redraw()

func _process(dt: float) -> void:
	if remaining <= 0: return
	if get_tree().get_first_node_in_group("arena").controls_locked: return
	remaining = maxf(0,remaining-dt)
	modulate.a = minf(1,remaining/0.3)
	if remaining == 0: hide()

func _draw() -> void:
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
	draw_texture_rect(PORTRAIT,Rect2(4,9,48,54),false)
	draw_string(FONT,Vector2(60,17),"DRA. AMANDA",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b3f8de"))
	draw_string(FONT,Vector2(60,37),"Voadores!",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	draw_string(FONT,Vector2(60,55),"Vamos derrubá-los!",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
