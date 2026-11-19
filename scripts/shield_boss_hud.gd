extends Control
const ART = preload("res://assets/enemies/shield_germ_v2.png")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin = preload("res://scripts/menu_button.gd")
var frame := MenuSkin.panel(Color(0.38, 0.35, 0.25))
var boss: Node2D
var intro := false
var defeated := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	hide()

func _process(_dt: float) -> void:
	if visible: queue_redraw()

func _draw() -> void:
	if not is_instance_valid(boss): return
	draw_style_box(frame, Rect2(150, 6, 340, 43))
	draw_rect(Rect2(154,10,36,35),Color("244437"))
	draw_texture_rect_region(ART,Rect2(151,5,43,43),Rect2(0,0,112,112))
	draw_string(FONT,Vector2(199,18),"GUARDIÃO DO REI",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("e8e6b7"))
	var orange := clampf(float(boss.hp-boss.LAYER_HP)/boss.LAYER_HP,0,1)
	var red := clampf(float(boss.hp)/boss.LAYER_HP,0,1)
	draw_rect(Rect2(198,23,284,17),Color("352624"))
	# Red is underneath orange in the same bar; empty space appears only in phase two.
	draw_rect(Rect2(199,24,282*red,15),Color("e83f40"))
	draw_rect(Rect2(199,24,282*red,3),Color("ff9181"))
	draw_rect(Rect2(199,24,282*orange,15),Color("f29a27"))
	draw_rect(Rect2(199,24,282*orange,3),Color("ffdc70"))
	if intro:
		draw_rect(Rect2(140,278,360,52),Color("101c22"))
		draw_rect(Rect2(140,278,360,52),Color("a7ce53"),false,2)
		draw_string(FONT,Vector2(140,311),"Eu vou proteger o rei!",HORIZONTAL_ALIGNMENT_CENTER,360,10,Color.WHITE)
