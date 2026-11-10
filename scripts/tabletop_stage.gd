extends "res://scripts/micro_arena.gd"
const ENTRY_META := "tabletop_entry_state"
const CHECKPOINT_META := "tabletop_checkpoint"
const RETRY_META := "tabletop_retry"
var spawn_index := 0
var exit_message_delay := 0.0
var combat_cleared := false
var puzzle: Node2D
var route: Node2D

func _ready() -> void:
	players = [$Actors/MaxAvatar,$Actors/AmandaAvatar]
	players[1].sprite.sprite_frames = preload("res://assets/avatars/Pink_Monster.tres")
	world_limit = 7180
	open_limit = 2390
	camera_max_x = world_limit-320
	built = true
	_restore_party()
	$HUD/TeamHUD.layout_changed.connect(_on_hud_layout_changed)
	$HUD/TeamHUD.bind(players)
	controls_locked = true
	$HUD/AdvanceArrow.hide()
	_setup_jump_obstacles()
	puzzle = $AssemblyPuzzle
	route = $Route
	if get_tree().has_meta(RETRY_META) and get_tree().has_meta(CHECKPOINT_META):
		_resume_checkpoint(get_tree().get_meta(CHECKPOINT_META))
	elif get_tree().has_meta(CHECKPOINT_META):
		get_tree().remove_meta(CHECKPOINT_META)
	if get_tree().has_meta(RETRY_META): get_tree().remove_meta(RETRY_META)

func _on_hud_layout_changed(two_players: bool) -> void:
	# Both health panels stay visible beside the nonblocking radio.
	$HUD/TeamHUD/Partner.position = Vector2(12,75)
	$HUD/TeamHUD/Primary/HitCombo.position = Vector2(0,132) if two_players else Vector2(130,104)
	$HUD/TeamHUD/Partner/HitCombo.position = Vector2(130,67)

func _resume_checkpoint(saved: Dictionary) -> void:
	elevator._physics_process(3.0)
	elevator.get_node("Hint").hide()
	encounter.message_started = true
	encounter.message_finished = true
	encounter.puzzle_message_started = true
	encounter.puzzle_message_finished = true
	spawn_index = 2
	combat_cleared = true
	controls_locked = false
	for crate in $Breakables.get_children():
		crate.broken = true
		crate.hide()
		crate.collision_layer = 0
		crate.set_process(false)
	puzzle.restore_running()
	route.restore_checkpoint(saved)

func _setup_jump_obstacles() -> void:
	for player in players: player.set_collision_mask_value(5, true)
	var obstacles := Node2D.new()
	obstacles.name = "JumpObstacles"
	add_child(obstacles)
	for prop in $WritingTools.get_children():
		var body := StaticBody2D.new()
		body.name = "JumpBarrier"
		body.collision_layer = 16
		body.collision_mask = 0
		body.add_to_group("jump_obstacles")
		# Physics stays unscaled and follows the uniformly scaled artwork.
		obstacles.add_child(body)
		var flip := -1.0 if prop.flip_h else 1.0
		var start: Vector2 = prop.to_global(Vector2(-235 * flip, -55))
		var end: Vector2 = prop.to_global(Vector2(235 * flip, 55))
		body.global_position = (start + end) * 0.5
		body.rotation = (end - start).angle() + PI * 0.5
		var shape := CapsuleShape2D.new()
		shape.radius = 9.0
		shape.height = start.distance_to(end) + 12.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)

func update_jump_collision(player) -> void:
	if player.jump_height >= 20:
		player.set_collision_mask_value(5, false)
	elif not player.get_collision_mask_value(5):
		# Landing within the footprint must not trigger penetration recovery.
		# Let the feet leave the object before restoring the ground collision.
		var feet: CollisionShape2D = player.get_node("FeetCollision")
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = feet.shape
		query.transform = feet.global_transform
		query.collision_mask = 16
		query.margin = player.safe_margin + 0.1
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			player.set_collision_mask_value(5, true)

func obstacle_ahead(player, direction: Vector2) -> bool:
	if direction.length_squared() < 0.01: return false
	if is_instance_valid(route) and route.should_jump(player,direction): return true
	var query := PhysicsRayQueryParameters2D.create(player.global_position, player.global_position + direction.normalized() * 34, 16)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func is_assembling(player) -> bool:
	return is_instance_valid(puzzle) and puzzle.is_building(player)

func ai_puzzle_destination(player) -> Variant:
	return route.ai_destination(player) if is_instance_valid(route) else null

func interact(player, dt: float) -> void:
	# Keep the shared revive interaction; this stage uses its own assembly puzzle.
	super.interact(player, dt)
	if is_instance_valid(puzzle): puzzle.interact(player, dt)

func _restore_party() -> void:
	var party: Array = []
	if get_tree().has_meta(RETRY_META) and get_tree().has_meta(CHECKPOINT_META):
		party = get_tree().get_meta(CHECKPOINT_META)["party"].duplicate(true)
	elif get_tree().has_meta("party_state"):
		party = get_tree().get_meta("party_state").duplicate(true)
		get_tree().remove_meta("party_state")
		get_tree().set_meta(ENTRY_META,party.duplicate(true))
	elif get_tree().has_meta(ENTRY_META):
		party = get_tree().get_meta(ENTRY_META).duplicate(true)
	for i in players.size():
		var player = players[i]
		var saved: Dictionary = party[i] if i<party.size() else {}
		player.max_hp = maxi(1,int(saved.get("max_hp",100)))
		player.hp = clampi(int(saved.get("hp",player.max_hp)),1,player.max_hp)
		player.energy = clampf(float(saved.get("energy",100)),0,100)
		player.healing_flasks = maxi(0,int(saved.get("healing_flasks",5)))
		player.flask_heal_amount = maxi(1,int(saved.get("flask_heal_amount",25)))
		player.ai_controlled = bool(saved.get("ai_controlled",i==1))
		var weapon: String = saved.get("weapon","brush" if i==0 else "bubbles")
		if not player.equip_weapon(weapon): player.equip_weapon("brush" if i==0 else "bubbles")
		player.get_node("PlayerMarker").text = "IA" if player.ai_controlled else "P%d" % (i+1)

func _process(dt: float) -> void:
	if Input.is_action_just_pressed("restart"):
		if get_tree().has_meta(CHECKPOINT_META): get_tree().set_meta(RETRY_META,true)
		get_tree().reload_current_scene()
		return
	var departing: bool = route.step == route.Step.EXIT and route.get_node("ExitElevator").is_transitioning()
	if not elevator.is_transitioning() and not departing and not encounter.is_modal() and not route.result_panel.visible:
		if Input.is_action_just_pressed("controls"):
			$HUD/ControlsPanel.visible = not $HUD/ControlsPanel.visible
			controls_locked = $HUD/ControlsPanel.visible
		if Input.is_action_just_pressed("join"):
			players[1].ai_controlled = not players[1].ai_controlled
	var center: Vector2 = (players[0].position+players[1].position)*0.5
	$Camera2D.position.x = clampf(center.x,320,camera_max_x)
	for player in players:
		player.position.x = clampf(player.position.x,$Camera2D.position.x-300,$Camera2D.position.x+300)
	update_camera_shake(dt)
	$Environment.follow_camera($Camera2D.position.x)
	if not controls_locked and not encounter.message_started and elevator.arrived:
		for player in players:
			if player.ai_controlled or player.down: continue
			if player.position.y>306 or player.position.x>350:
				exit_message_delay += dt
				if exit_message_delay>=0.3: encounter.start_message(player.player_id)
				break
	if not controls_locked and encounter.message_finished:
		var front: float = maxf(players[0].position.x,players[1].position.x)
		if spawn_index==0 and front>640: _spawn_tabletop_wave(0)
		elif spawn_index==1 and front>1430 and get_tree().get_nodes_in_group("germs").is_empty(): _spawn_tabletop_wave(1)
		if spawn_index==2 and get_tree().get_nodes_in_group("germs").is_empty(): combat_cleared = true
		if combat_cleared and not puzzle.started:
			puzzle.begin()
		if puzzle.finished and not route.powered: route.begin_power()
		victory = route.complete
	$HUD/AdvanceArrow.visible = not controls_locked and encounter.message_finished and not victory and get_tree().get_nodes_in_group("germs").is_empty()
	$HUD/Goal.text = "BOA,\nEQUIPE!" if victory else ("VENÇA OS\nGERMES" if not get_tree().get_nodes_in_group("germs").is_empty() else "SIGA EM\nFRENTE")
	if not encounter.message_finished: $HUD/Goal.text = "SAIA DO\nELEVADOR" if elevator.arrived else "BANCADA DO\nLABORATÓRIO"
	if combat_cleared and not victory:
		$HUD/Goal.text = ("QUEBRE AS\nCAIXAS" if puzzle.needs_salvage() else "MONTE A\nMÁQUINA") if not puzzle.constructed else ("LIGANDO..." if puzzle.activating else "PUXE A\nALAVANCA")
		$HUD/AdvanceArrow.visible = not controls_locked and maxf(players[0].position.x, players[1].position.x) < 2080
	if is_instance_valid(puzzle): puzzle.update_camera(dt)
	if route.powered:
		$HUD/Goal.text = route.objective_text()
		$HUD/AdvanceArrow.visible = route.wants_arrow() and not controls_locked
		var backwards: bool = route.target_x() < center.x
		$HUD/AdvanceArrow.position.x = 18 if backwards else 554
		$HUD/AdvanceArrow.direction = -1 if backwards else 1
		puzzle.hint.hide()
	$HUD/Goal.visible = not encounter.dialogue.active and not departing
	status.text = "F2  TENTAR DE NOVO" if players[0].down and players[1].down else ""

func _spawn_tabletop_wave(index: int) -> void:
	spawn_index += 1
	for i in 4:
		var germ = GermScene.instantiate()
		germ.variant = "red" if i==3 else "green"
		germ.position = Vector2((980 if index==0 else 1810)+i*64,260+(i%2)*50)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = germ.get_node("CollisionShape2D").shape
		query.collision_mask = 25
		query.margin = 1.0
		# Never spawn inside a pen or a tube: recovery would eject the enemy.
		for attempt in 10:
			query.transform = Transform2D(0, germ.position)
			if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(): break
			germ.position.x += 32
		germ.speed = 45+index*3
		$Actors.add_child(germ)

func germ_defeated(_at: Vector2) -> void:
	defeated += 1
