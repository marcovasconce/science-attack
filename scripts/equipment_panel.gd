extends Control
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const PixelPose = preload("res://scripts/pixel_equipment_pose.gd")
const CHOICES := ["brush","bubbles"]
var interact_key := "E"
var selected: Array[int] = [0,0]
var solo_focus := 0
@onready var arena = get_tree().get_first_node_in_group("arena")
func open_panel(player_id: int) -> void:
	interact_key = "E" if player_id == 0 else "U"
	solo_focus = player_id
	for i in 2: selected[i] = 1 if arena.players[i].equipped_weapon == "bubbles" else 0
	show()
	queue_redraw()
func select_choice(player_id: int, index: int) -> void:
	selected[player_id] = posmod(index,2)
	queue_redraw()
func confirm_choice(player_id: int) -> bool:
	if not visible: return false
	var applied: bool = arena.players[player_id].equip_weapon(CHOICES[selected[player_id]])
	queue_redraw()
	return applied
func handle_input(event: InputEvent) -> bool:
	if not visible or event.is_echo(): return false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for p in 2:
			for option in 2:
				if _option_rect(p,option).has_point(event.position):
					select_choice(p,option)
					confirm_choice(p)
					return true
	for p in 2:
		if arena.players[p].ai_controlled: continue
		var prefix := "p%d_" % p
		var target: int = solo_focus if p == 0 and arena.players[1].ai_controlled else p
		if p == 0 and arena.players[1].ai_controlled and (event.is_action_pressed(prefix+"left") or event.is_action_pressed(prefix+"right")):
			solo_focus = 1-solo_focus
			queue_redraw()
			return true
		if event.is_action_pressed(prefix+"up"):
			select_choice(target,selected[target]-1)
			return true
		if event.is_action_pressed(prefix+"down"):
			select_choice(target,selected[target]+1)
			return true
		if event.is_action_pressed(prefix+"attack"):
			confirm_choice(target)
			return true
	return false
func _option_rect(player_id: int, index: int) -> Rect2:
	return Rect2(44+player_id*290,190+index*48,262,43)
func _preview(player_id: int, choice: String, foot: Vector2) -> void:
	var frames: SpriteFrames = arena.players[player_id].sprite.sprite_frames
	var animation := choice + "_idle"
	if not frames.has_animation(animation): return
	PixelPose.paint(self,frames,animation,0,foot,player_id == 1)
func _draw() -> void:
	if not is_instance_valid(arena) or arena.players.size() != 2: return
	draw_rect(Rect2(0,0,640,360),Color(0.015,0.025,0.06,0.7))
	draw_rect(Rect2(26,108,588,234),Color("080e21"))
	draw_rect(Rect2(28,110,584,230),Color("5489d6"))
	draw_rect(Rect2(31,113,578,224),Color("102346"))
	draw_string(FONT,Vector2(44,132),"ESCOLHA SEU EQUIPAMENTO",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
	draw_string(FONT,Vector2(468,132),"E/U / ESC SAIR",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
	for p in 2:
		var x := 40 + p*290
		var focused: bool = not arena.players[1].ai_controlled or solo_focus == p
		var accent := Color("55cced") if p == 0 else Color("c391f2")
		draw_rect(Rect2(x,144,270,145),Color("080e21"))
		if focused: draw_rect(Rect2(x,144,270,145),accent,false,1)
		draw_string(FONT,Vector2(x+10,161),"MAX" if p == 0 else "AMANDA"+("  IA" if arena.players[1].ai_controlled else ""),HORIZONTAL_ALIGNMENT_LEFT,-1,8,accent)
		var equipped: String = arena.players[p].equipped_weapon
		draw_string(FONT,Vector2(x+10,178),"ATUAL: "+("ESCOVA" if equipped == "brush" else ("BOLHAS" if equipped == "bubbles" else "SOCO")),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
		for option in 2:
			var rect := _option_rect(p,option)
			draw_rect(rect,Color("1b3354") if selected[p] == option else Color("0b1c32"))
			if selected[p] == option: draw_rect(rect,accent,false,1)
			_preview(p,CHOICES[option],rect.position+Vector2(27,39))
			var label := "ESPADA ESCOVA" if option == 0 else "METRALHADORA"
			var sub := "ALCANCE CURTO" if option == 0 else "BOLHAS DE SABÃO"
			draw_string(FONT,rect.position+Vector2(76,16),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
			draw_string(FONT,rect.position+Vector2(76,31),sub,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
			if equipped == CHOICES[option]: draw_rect(Rect2(rect.position+Vector2(251,17),Vector2(5,8)),Color("85e878"))
	draw_string(FONT,Vector2(44,309),"P1 W/S ESCOLHER | F EQUIPAR",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	if arena.players[1].ai_controlled:
		draw_string(FONT,Vector2(44,326),"A/D TROCAR MAX / AMANDA",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
	else:
		draw_string(FONT,Vector2(334,309),"P2 SETAS | J EQUIPAR",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	draw_string(FONT,Vector2(334,326),"CLIQUE TAMBÉM EQUIPA",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
