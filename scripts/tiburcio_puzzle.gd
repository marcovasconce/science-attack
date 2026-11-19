extends Control
signal closed(completed: bool)
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const MenuSkin = preload("res://scripts/menu_button.gd")
var frame := MenuSkin.panel(Color(0.23, 0.38, 0.39))
const ORIGINAL = preload("res://assets/avatars/Dude_Monster/Dude_Monster_Idle_4.png")
const BOARD := Rect2(118,72,216,216)
const TILE := 72.0
const BOOT_TIME := 1.4
enum State { BOOT, PLAY, SUCCESS }
var state := State.BOOT
var active := false
var elapsed := 0.0
var tiles: Array[int] = [4,1,6,3,0,8,2,7,5]
var cursor := 0
var selected := -1
var moves := 0
var owner_id := 0
var solved := false
var held_axes: Dictionary = {}

func _ready() -> void:
	shuffle_tiles()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 40
	hide()

func shuffle_tiles() -> void:
	# One nine-piece cycle: every tile is displaced and eight swaps are required.
	# Keep this arrangement when closing/reopening the terminal.
	var order: Array[int] = [0,1,2,3,4,5,6,7,8]
	order.shuffle()
	for i in 9: tiles[order[i]] = order[(i+1)%9]

func open(player_id: int) -> void:
	owner_id = player_id
	active = true
	state = State.BOOT
	elapsed = 0
	selected = -1
	held_axes.clear()
	show()
	queue_redraw()

func _process(dt: float) -> void:
	if not active: return
	elapsed += dt
	if state == State.BOOT and elapsed >= BOOT_TIME:
		state = State.PLAY
		elapsed = 0
	elif state == State.SUCCESS and elapsed >= 1.0:
		close(true)
	queue_redraw()

func close(completed: bool) -> void:
	if not active: return
	active = false
	hide()
	closed.emit(completed)

func select_tile(index: int) -> void:
	if not active or state != State.PLAY or index < 0 or index >= 9: return
	cursor = index
	if selected == -1:
		selected = index
	elif selected == index:
		selected = -1
	else:
		var previous := tiles[index]
		tiles[index] = tiles[selected]
		tiles[selected] = previous
		selected = -1
		moves += 1
		solved = true
		for i in 9:
			if tiles[i] != i: solved = false
		if solved:
			state = State.SUCCESS
			elapsed = 0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active: return
	if (event is InputEventKey and event.pressed) or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not GameInput.navigation_step(event, held_axes): return
		if event.is_action_pressed("ui_cancel") and state != State.SUCCESS:
			close(false)
		elif state == State.PLAY:
			if GameInput.event_for(event, 0, "left") or GameInput.event_for(event, 1, "left"): cursor = (cursor / 3) * 3 + (cursor % 3 + 2) % 3
			elif GameInput.event_for(event, 0, "right") or GameInput.event_for(event, 1, "right"): cursor = (cursor / 3) * 3 + (cursor % 3 + 1) % 3
			elif GameInput.event_for(event, 0, "up") or GameInput.event_for(event, 1, "up"): cursor = (cursor + 6) % 9
			elif GameInput.event_for(event, 0, "down") or GameInput.event_for(event, 1, "down"): cursor = (cursor + 3) % 9
			elif GameInput.event_for(event, owner_id, "interact") or event.is_action_pressed("ui_accept"): select_tile(cursor)
			else: return
		else: return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.PLAY and BOARD.has_point(event.position):
			var cell := Vector2i((event.position - BOARD.position) / TILE)
			select_tile(cell.y * 3 + cell.x)
		elif Rect2(541,32,27,23).has_point(event.position) and state != State.SUCCESS: close(false)
		else: return
	else: return
	get_viewport().set_input_as_handled()
	queue_redraw()

func label_at(at: Vector2, text: String, color := Color("b9ded2"), size := 8) -> void:
	draw_string(FONT,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
	if not active: return
	draw_rect(Rect2(0,0,640,360),Color(0.015,0.035,0.03,0.86))
	draw_style_box(frame, Rect2(52, 22, 536, 316))
	draw_rect(Rect2(62,31,516,23),Color("1b353b"))
	label_at(Vector2(76,47),"TERMINAL DE SEGURANÇA",Color("9deed0"))
	label_at(Vector2(550,47),"X")
	if state == State.BOOT:
		var orange := Color("ffa443")
		for y in range(72,285,13):
			var count := 5 + ((y * 7 + int(elapsed * 18)) % 15)
			for i in count:
				draw_rect(Rect2(77+i*5,y,3,2),Color(0.8,0.3,0.08,0.25))
				draw_rect(Rect2(460+i*4,y,2,2),Color(0.8,0.3,0.08,0.25))
		var triangle := PackedVector2Array([Vector2(320,88),Vector2(272,167),Vector2(368,167),Vector2(320,88)])
		draw_polyline(triangle,orange,4)
		label_at(Vector2(309,151),"!",orange,22)
		label_at(Vector2(222,197),"ABRINDO PAINEL",orange,12)
		draw_rect(Rect2(170,251,300,10),Color("3f2a20"))
		draw_rect(Rect2(172,253,296*minf(1,elapsed/BOOT_TIME),6),orange)
	else:
		for slot in 9:
			var cell := Rect2(BOARD.position + Vector2(slot%3,slot/3)*TILE,Vector2.ONE*TILE)
			var piece := tiles[slot]
			var source := Rect2(Vector2(piece%3,piece/3)*Vector2(32.0/3,32.0/3),Vector2.ONE*(32.0/3))
			draw_rect(cell,Color("24444b").lerp(Color("153039"),float(piece)/12))
			draw_texture_rect_region(ORIGINAL,cell,source)
			draw_rect(cell,Color("608d88"),false,1)
			if slot == piece: draw_rect(cell.grow(-2),Color("7de8ac"),false,2)
			if slot == cursor and state == State.PLAY: draw_rect(cell.grow(-5),Color.WHITE,false,2)
			if slot == selected: draw_rect(cell.grow(-2),Color("ffd570"),false,3)
		label_at(Vector2(385,90),"MODELO",Color("81b7ad"))
		draw_rect(Rect2(387,104,120,120),Color("1c333b"))
		draw_texture_rect_region(ORIGINAL,Rect2(399,116,96,96),Rect2(0,0,32,32))
		label_at(Vector2(402,241),"TIBÚRCIO",Color("a3e9e0"))
		label_at(Vector2(385,269),"TROCAS: %d" % moves)
		if state == State.SUCCESS:
			label_at(Vector2(152,313),"ACESSO LIBERADO!",Color("a5ffc8"),12)
		else:
			label_at(Vector2(91,311),"ESCOLHA DUAS PEÇAS PARA TROCAR",Color("c3e4d9"))
			if GameInput.glyph(owner_id, "move") != null:
				draw_texture_rect(GameInput.glyph(owner_id, "move"), Rect2(91, 316, 14, 14), false)
				label_at(Vector2(110,327),"MOVER",Color("a4d8cc"),7)
				draw_texture_rect(GameInput.glyph(owner_id, "accept"), Rect2(159, 316, 14, 14), false)
				label_at(Vector2(178,327),"ESCOLHER",Color("a4d8cc"),7)
				draw_texture_rect(GameInput.glyph(owner_id, "cancel"), Rect2(246, 316, 14, 14), false)
				label_at(Vector2(265,327),"VOLTAR",Color("a4d8cc"),7)
			else:
				label_at(Vector2(91,327),"SETAS + %s   |   ESC: VOLTAR" % ("E" if owner_id == 0 else "U"),Color("a4d8cc"),7)
	# Subtle CRT scanlines are part of the terminal, not an image overlay.
	for y in range(58,299,4): draw_rect(Rect2(63,y,514,1),Color(0,0,0,0.12))
