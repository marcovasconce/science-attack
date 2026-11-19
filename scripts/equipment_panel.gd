extends Control
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin = preload("res://scripts/menu_button.gd")
var frame := MenuSkin.panel()
var idle_option := MenuSkin.panel(Color(0.16, 0.25, 0.43))
var chosen_option := MenuSkin.panel(Color(0.32, 0.52, 0.77))
const PixelPose = preload("res://scripts/pixel_equipment_pose.gd")
const CHOICES := ["brush","bubbles"]
var interact_key := "E"
var selected: Array[int] = [0,0]
var solo_focus := 0
var held_axes: Dictionary = {}
@onready var arena = get_tree().get_first_node_in_group("arena")
func _ready() -> void:
	GameInput.prompts_changed.connect(queue_redraw)

func open_panel(player_id: int) -> void:
	interact_key = "E" if player_id == 0 else "U"
	solo_focus = player_id
	held_axes.clear()
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
	if not visible or not GameInput.navigation_step(event, held_axes): return false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for p in 2:
			for option in 2:
				if _option_rect(p,option).has_point(event.position):
					select_choice(p,option)
					confirm_choice(p)
					return true
	for p in 2:
		if arena.players[p].ai_controlled: continue
		var target: int = solo_focus if p == 0 and arena.players[1].ai_controlled else p
		if p == 0 and arena.players[1].ai_controlled and (GameInput.event_for(event, p, "left") or GameInput.event_for(event, p, "right")):
			solo_focus = 1-solo_focus
			queue_redraw()
			return true
		if GameInput.event_for(event, p, "up"):
			select_choice(target,selected[target]-1)
			return true
		if GameInput.event_for(event, p, "down"):
			select_choice(target,selected[target]+1)
			return true
		if GameInput.event_for(event, p, "attack"):
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
	draw_style_box(frame, Rect2(26, 108, 588, 234))
	draw_string(FONT,Vector2(44,132),"ESCOLHA SEU EQUIPAMENTO",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
	GameInput.draw_hint(self, Vector2(468,132), 0, "cancel", "E/U / ESC SAIR", "VOLTAR")
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
			draw_style_box(chosen_option if selected[p] == option else idle_option, rect)
			if selected[p] == option: draw_rect(rect,accent,false,1)
			_preview(p,CHOICES[option],rect.position+Vector2(27,39))
			var label := "ESPADA ESCOVA" if option == 0 else "METRALHADORA"
			var sub := "ALCANCE CURTO" if option == 0 else "BOLHAS DE SABÃO"
			draw_string(FONT,rect.position+Vector2(76,16),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
			draw_string(FONT,rect.position+Vector2(76,31),sub,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
			if equipped == CHOICES[option]: draw_rect(Rect2(rect.position+Vector2(251,17),Vector2(5,8)),Color("85e878"))
	if GameInput.glyph(0, "move") != null:
		GameInput.draw_hint(self, Vector2(44,309), 0, "move", "", "MOVER")
		GameInput.draw_hint(self, Vector2(122,309), 0, "attack", "", "EQUIPAR")
	else:
		draw_string(FONT,Vector2(44,309),"P1 W/S ESCOLHER | F EQUIPAR",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	if arena.players[1].ai_controlled:
		GameInput.draw_hint(self, Vector2(44,326), 0, "move", "A/D TROCAR MAX / AMANDA", "TROCAR MAX / AMANDA")
	else:
		if GameInput.glyph(1, "move") != null:
			GameInput.draw_hint(self, Vector2(334,309), 1, "move", "", "MOVER")
			GameInput.draw_hint(self, Vector2(412,309), 1, "attack", "", "EQUIPAR")
		else:
			draw_string(FONT,Vector2(334,309),"P2 SETAS | J EQUIPAR",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
	draw_string(FONT,Vector2(334,326),"CLIQUE TAMBÉM EQUIPA",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b2d9ff"))
