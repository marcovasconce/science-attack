extends "res://scripts/cooperative_elevator.gd"
const BROKEN_ART = preload("res://assets/environment/lower_lab/broken_exit_elevator.png")
const DoorPanels = preload("res://scripts/elevator_doors.gd")
const Prompt = preload("res://scripts/interaction_prompt.gd")
const REPAIR_COST := 8
const REPAIR_TIME := 3.2
const MAX_LINE := "Vamos consertar esse elevador e salvar o Tibúrcio!"
var repaired := false
var parts_reserved := false
var repair_progress := 0.0
var repair_grace := 0.0
var repair_player = null
var last_repair_frame := -1
var clock := 0.0
var doors: Control
var repair_prompt: Control
var blockers: StaticBody2D
var announced := false
var repair_overlay: Node2D

func _ready() -> void:
	next_scene_path = "res://scenes/gameplay/shaft_descent.tscn"
	travels_down = true
	$Cabin/Sprite.texture = BROKEN_ART
	$Cabin/Sprite.position = Vector2(-140,-230)
	$Cabin/Sprite.scale = Vector2.ONE
	$Shaft.hide()
	$LeftRail.hide()
	$RightRail.hide()
	$ShaftDetails.show()
	doors = DoorPanels.new()
	doors.position = Vector2(-103,-142)
	doors.size = Vector2(206,129)
	doors.clip_contents = true
	doors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	doors.z_index = 5
	doors.openness = 0.05
	$Cabin.add_child(doors)
	blockers = StaticBody2D.new()
	blockers.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(224,12)
	shape.shape = rect
	shape.position = Vector2(0,-13)
	blockers.add_child(shape)
	add_child(blockers)
	repair_prompt = Prompt.new()
	repair_prompt.position = Vector2(-195,-135)
	repair_prompt.z_index = 10
	add_child(repair_prompt)
	repair_prompt.hide()
	$Hint.hide()
	repair_overlay = Node2D.new()
	repair_overlay.z_index = 2
	$Cabin.add_child(repair_overlay)
	repair_overlay.draw.connect(_draw_repair)

func can_unlock() -> bool:
	return repaired and arena.finale.state == arena.finale.State.DONE

func unlock_route() -> void:
	available = true

func repair_point() -> Vector2:
	return global_position+Vector2(-146,-27)

func can_repair(player) -> bool:
	return arena.finale.state == arena.finale.State.DONE and not repaired and not player.down and not player.ai_controlled and player.position.distance_to(repair_point()) < 68

func is_building(player) -> bool:
	return not arena.controls_locked and repair_grace > 0 and repair_player == player and can_repair(player) and player.can_assemble()

func stop_building(player) -> void:
	if repair_player == player: repair_grace = 0

func has_repair_parts() -> bool:
	return parts_reserved or arena.pieces >= REPAIR_COST

func repair(player, dt: float) -> void:
	if arena.controls_locked or not can_repair(player) or not player.can_assemble() or not has_repair_parts(): return
	if is_instance_valid(repair_player) and repair_player != player and is_building(repair_player): return
	# Two local players holding use cannot spend parts twice or count one frame twice.
	var tick := Engine.get_physics_frames()
	if tick == last_repair_frame: return
	last_repair_frame = tick
	repair_player = player
	if not parts_reserved:
		parts_reserved = true
		arena.pieces -= REPAIR_COST
	repair_grace = 0.16
	repair_progress = minf(REPAIR_TIME,repair_progress+dt)
	if repair_progress >= REPAIR_TIME:
		repaired = true
		blockers.get_child(0).set_deferred("disabled",true)
		repair_prompt.hide()
		available = true
		arena.start_camera_shake(2,0.18)

func prepare_departure_ui() -> void:
	arena.get_node("HUD/AdvanceArrow").hide()
	arena.journey_radio.hide()

func _start_ascent() -> void:
	$ShaftDetails.bottom_y = 260
	$ShaftDetails.queue_redraw()
	doors.show()
	doors.openness = 1
	super._start_ascent()

func _advance_ascent(dt: float) -> void:
	# The rails remain anchored while the entire cabin and its riders descend.
	travel_time += dt
	doors.openness = 1-smoothstep(0,0.9,travel_time)
	var drop := 230*smoothstep(0.9,2.8,travel_time)
	cabin.position.y = drop
	for i in arena.players.size(): arena.players[i].global_position = rider_origins[i]+Vector2(0,drop)
	arena.get_node("Camera2D").position.y = 180+drop*0.55
	SceneFx.paint(black, smoothstep(2.0,2.8,travel_time), SceneFx.WIPE, Vector2.DOWN)
	if travel_time >= 2.8:
		state = State.LOADING
		black.color.a = 1
		loading_label.text = "DESCENDO..."
		loading_label.show()
		load_requested = ResourceLoader.load_threaded_request(next_scene_path) == OK

func _physics_process(dt: float) -> void:
	if state != State.WAITING:
		super._physics_process(dt)
		return
	if arena.controls_locked: return
	clock += dt
	repair_grace = maxf(0,repair_grace-dt)
	var unlocked: bool = arena.finale.state == arena.finale.State.DONE
	if unlocked and not announced:
		for player in arena.players:
			if not player.down and not player.ai_controlled and player.position.x >= global_position.x-270:
				announced = true
				arena.journey_radio.say("repair","MAX",MAX_LINE)
				break
	repair_prompt.hide()
	if not repaired:
		for player in arena.players:
			if can_repair(player) and not (is_instance_valid(repair_player) and is_building(repair_player)):
				repair_prompt.set_player(player.player_id)
				repair_prompt.action_text = "SEGURE PARA CONSERTAR" if has_repair_parts() else "PEÇAS %d/%d" % [arena.pieces,REPAIR_COST]
				repair_prompt.show()
				break
		$Hint.hide()
		repair_overlay.queue_redraw()
		return
	doors.openness = minf(1,doors.openness+dt*1.4)
	if doors.openness < 1: return
	super._physics_process(dt)
	$Hint.visible = absf(arena.camera_center().x-position.x) < 230 and state == State.WAITING
	$Hint.text = boarding_hint()
	repair_overlay.queue_redraw()

func _draw_repair() -> void:
	var plates := [Vector2(54,-217),Vector2(102,-104)]
	var installed := plates.size() if repaired else int(repair_progress / REPAIR_TIME * plates.size())
	for i in installed:
		var at: Vector2 = plates[i]
		repair_overlay.draw_rect(Rect2(at,Vector2(25,19)),Color("527787"))
		repair_overlay.draw_rect(Rect2(at+Vector2(2,2),Vector2(21,2)),Color("b2d4da"))
		for dx in [3,19]: repair_overlay.draw_rect(Rect2(at+Vector2(dx,14),Vector2(3,3)),Color("172c43"))
	if is_instance_valid(repair_player) and is_building(repair_player):
		for i in 9:
			var t := fposmod(clock*3+i*0.11,1)
			repair_overlay.draw_rect(Rect2(Vector2(-132+t*32,-60-t*36+sin(i*7)*12),Vector2(3,3)),Color(1,0.75,0.2,1-t))
	if repair_progress > 0 and not repaired:
		repair_overlay.draw_rect(Rect2(-174,-94,58,7),Color("17232c"))
		repair_overlay.draw_rect(Rect2(-173,-93,56*repair_progress/REPAIR_TIME,5),Color("7aefad"))
