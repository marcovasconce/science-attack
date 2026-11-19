extends "res://scripts/micro_arena.gd"
enum Beat { ARRIVAL, EXPLORE, REVEAL, DIALOGUE, ESCAPE, WARNING, WAVE, CLEARED, ZOOM, PUZZLE, RETURN, MIXED, FINISHED }
const ENTRY_META := "lower_lab_entry_state"
const FlyingScene = preload("res://scenes/actors/flying_bacterium.tscn")
const YellowScene = preload("res://scenes/actors/yellow_flying_bacterium.tscn")
const MIXED_ORDER := ["green","yellow","green","red","green","yellow","green","red","green","yellow","green","red"]
var mixed_started := false
var mixed_spawned := 0
var mixed_clock := 0.0
const Party = preload("res://scripts/party_transfer.gd")
const KING_LINE := "Tarde demais! Logo, logo esse laboratório já era! Ninguém poderá me deter!"
const WAVE_SIZES := [48, 80]
const SPAWN_INTERVALS := [0.12, 0.08]
const Corridor = preload("res://scripts/lower_lab_corridor.gd")
const Puzzle = preload("res://scripts/tiburcio_puzzle.gd")
const Finale = preload("res://scripts/lower_lab_finale.gd")
const Hint = preload("res://scripts/amanda_flying_hint.gd")
const SupplyScript = preload("res://scripts/lower_lab_supply.gd")
const RepairLift = preload("res://scripts/repair_exit_elevator.gd")
const Radio = preload("res://scripts/journey_radio.gd")
var exit_lift: Node2D
var journey_radio: Control
var finale: Node2D
var amanda_hint: Control
var swarm_barrier: StaticBody2D
var corridor: Node2D
var puzzle: Control
var puzzle_complete := false
var camera_before_puzzle := Vector2.ZERO
var ai_detour: Array[Vector2] = []
var ai_detour_direction := 1.0
var beat := Beat.ARRIVAL
var beat_age := 0.0
var spawn_clock := 0.0
var spawned := 0
var wave_spawned := 0
var passed := 0
var initiating_player := 0
var cinematic_camera_start := 320.0
@onready var king: Node2D = $Actors/BacteriaKing
@onready var dialogue = $HUD/EncounterDialogue
@onready var warning = $HUD/WaveWarning

func _ready() -> void:
	players = [$Actors/MaxAvatar, $Actors/AmandaAvatar]
	# The temporary swarm barrier uses its own body-only layer; weapon raycasts ignore it.
	for player in players: player.set_collision_mask_value(5,true)
	players[1].sprite.sprite_frames = preload("res://assets/avatars/Pink_Monster.tres")
	world_limit = 5680
	open_limit = 1040
	camera_max_x = 5360
	built = true
	_restore_party()
	bind_team_hud()
	controls_locked = true
	dialogue.closed.connect(_start_escape)
	dialogue.get_node("RadioPortrait").hide()
	elevator.opened.connect(_on_elevator_opened)
	king.hide()
	$HUD/AdvanceArrow.hide()
	$HUD/Goal.hide()
	corridor = Corridor.new()
	corridor.name = "DamagedCorridor"
	add_child(corridor)
	corridor.door.opened.connect(_start_mixed_encounter)
	puzzle = Puzzle.new()
	puzzle.name = "TiburcioPuzzle"
	$HUD.add_child(puzzle)
	puzzle.closed.connect(_close_terminal)
	finale = Finale.new()
	finale.name = "LowerLabFinale"
	add_child(finale)
	swarm_barrier = finale.wall("SwarmBarrier",1056)
	amanda_hint = Hint.new()
	$HUD.add_child(amanda_hint)
	journey_radio = Radio.new()
	$HUD.add_child(journey_radio)
	exit_lift = preload("res://scenes/environment/cooperative_elevator.tscn").instantiate()
	exit_lift.set_script(RepairLift)
	exit_lift.name = "RepairExitElevator"
	exit_lift.position = Vector2(5420,316)
	add_child(exit_lift)
	_spawn_supplies()
	for x in [4920,5060,5190]:
		var crate = preload("res://scenes/actors/cartoon_crate.tscn").instantiate()
		crate.position = Vector2(x,312)
		crate.name = "ElevatorParts%d" % x
		$Breakables.add_child(crate)
	for kind in ["Wall","Floor"]:
		var extension = get_node("Environment/"+kind+"4").duplicate()
		extension.position.x = 5120
		$Environment.add_child(extension)
	$StageBoundaries/East.position.x = world_limit
	for edge in ["North","South"]:
		var boundary = get_node("StageBoundaries/"+edge)
		boundary.position.x = world_limit*0.5
		boundary.shape = boundary.shape.duplicate()
		boundary.shape.size.x = world_limit+40
	if get_tree().has_meta("lower_lab_chapter"):
		_resume_chapter(int(get_tree().get_meta("lower_lab_chapter")))

func _resume_chapter(chapter: int) -> void:
	# Restore prerequisites only, leaving the selected encounter playable on F2 too.
	elevator._physics_process(3.0)
	elevator.get_node("Hint").hide()
	controls_locked = false
	king.hide()
	var starts := [650.0,2370.0,2695.0,3270.0,3975.0,5070.0]
	for i in players.size(): players[i].position = Vector2(starts[chapter]+i*42,285+i*20)
	$Camera2D.position.x = clampf(starts[chapter],320,camera_max_x)
	if chapter == 0:
		wave = 0
		_start_wave_warning()
		return
	finale.set_wall(swarm_barrier,false)
	beat = Beat.CLEARED
	victory = true
	open_limit = 3140
	if chapter == 1: return
	puzzle_complete = true
	corridor.door.openness = 1
	corridor.door.collision.set_deferred("disabled",true)
	corridor.door.queue_redraw()
	if chapter == 2:
		_start_mixed_encounter()
		return
	mixed_started = true
	mixed_spawned = MIXED_ORDER.size()
	beat = Beat.FINISHED
	finale.state = finale.State.READY
	finale.set_wall(finale.mixed_wall,false)
	open_limit = 3340
	if chapter == 3: return
	finale.cleaned = true
	finale.soap_taken = true
	finale.state = finale.State.OPEN
	finale.set_wall(finale.slime_wall,false)
	open_limit = world_limit-20
	if chapter == 4:
		finale.begin_boss()
	else:
		finale.state = finale.State.DONE

func _spawn_supplies() -> void:
	var locations := [Vector2(845,315),Vector2(1100,208),Vector2(1275,317),Vector2(1550,318),Vector2(1680,206),Vector2(1920,318),Vector2(2175,206),Vector2(2390,319),Vector2(2850,315),Vector2(3070,211),Vector2(3645,312),Vector2(3850,211)]
	locations.shuffle()
	for i in 9:
		var crate = preload("res://scenes/actors/cartoon_crate.tscn").instantiate()
		crate.set_script(SupplyScript)
		crate.name = "HealingCrate%d" % i
		crate.position = locations[i]+Vector2(randf_range(-18,18),randf_range(-4,4))
		$Breakables.add_child(crate)

func _on_elevator_opened() -> void:
	beat = Beat.EXPLORE
	elevator.get_node("Hint").hide()

func _restore_party() -> void:
	var party: Array = []
	if get_tree().has_meta("party_state"):
		party = get_tree().get_meta("party_state").duplicate(true)
		get_tree().remove_meta("party_state")
		get_tree().set_meta(ENTRY_META, party.duplicate(true))
	elif get_tree().has_meta(ENTRY_META):
		party = get_tree().get_meta(ENTRY_META).duplicate(true)
	Party.apply(self, party)
	if not get_tree().has_meta(ENTRY_META):
		get_tree().set_meta(ENTRY_META, Party.capture(self))

func _on_hud_layout_changed(two_players: bool) -> void:
	$HUD/TeamHUD/Partner.position = Vector2(12,75)
	$HUD/TeamHUD/Primary/HitCombo.position = Vector2(0,132) if two_players else Vector2(130,104)
	$HUD/TeamHUD/Partner/HitCombo.position = Vector2(130,67)

func is_cinematic() -> bool:
	return beat in [Beat.ARRIVAL, Beat.REVEAL, Beat.DIALOGUE, Beat.ESCAPE, Beat.ZOOM, Beat.PUZZLE, Beat.RETURN] or (is_instance_valid(finale) and finale.is_modal()) or (is_instance_valid(exit_lift) and exit_lift.is_transitioning())

func is_assembling(player) -> bool:
	return is_instance_valid(exit_lift) and exit_lift.is_building(player)

func stop_assembling(player) -> void:
	if is_instance_valid(exit_lift): exit_lift.stop_building(player)

func assembly_facing(player) -> float:
	return signf(exit_lift.position.x-player.position.x)

func interact(player, dt: float) -> void:
	super.interact(player,dt)
	if is_instance_valid(exit_lift): exit_lift.repair(player,dt)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or beat not in [Beat.DIALOGUE,Beat.CLEARED]: return
	for p in players:
		if not p.ai_controlled and GameInput.event_for(event, p.player_id, "interact"):
			if beat == Beat.DIALOGUE:
				dialogue.advance()
			elif not controls_locked and corridor.can_use(p) and not puzzle_complete:
				_open_terminal(p.player_id)
			else: continue
			get_viewport().set_input_as_handled()
			return

func _process(dt: float) -> void:
	if GameInput.retry_requested(self):
		restart_with_current_team()
		return
	if beat in [Beat.ZOOM, Beat.PUZZLE, Beat.RETURN]:
		_update_terminal_camera(dt)
		return
	if not is_cinematic():
		if GameInput.help_requested():
			$HUD/ControlsPanel.visible = not $HUD/ControlsPanel.visible
			controls_locked = $HUD/ControlsPanel.visible
		if Input.is_action_just_pressed("join") and not controls_locked:
			players[1].ai_controlled = not players[1].ai_controlled
	if $HUD/ControlsPanel.visible: return
	if players[0].down and players[1].down:
		_update_objective()
		return
	beat_age += dt
	var camera := $Camera2D
	var center := camera_center()
	if finale.camera_locked():
		camera.position.x = lerpf(camera.position.x,finale.CENTER,minf(1,dt*6))
		camera.zoom = camera.zoom.lerp(Vector2.ONE*finale.CAMERA_ZOOM,minf(1,dt*4))
	elif beat == Beat.REVEAL:
		camera.position.x = lerpf(cinematic_camera_start, 660, smoothstep(0, 0.8, beat_age))
	elif beat not in [Beat.DIALOGUE, Beat.ESCAPE]:
		camera.position.x = lerpf(camera.position.x, clampf(center.x,320,camera_max_x), minf(1,dt * 6))
		camera.zoom = camera.zoom.lerp(Vector2.ONE,minf(1,dt*4))
	if not is_cinematic():
		var visible_half_width: float = 300.0/camera.zoom.x
		keep_living_players_in_view(camera.position.x, visible_half_width)
	update_camera_shake(dt)
	match beat:
		Beat.EXPLORE:
			for p in players:
				if not p.ai_controlled and not p.down and p.position.x >= 510:
					_begin_abduction(p.player_id)
					break
		Beat.REVEAL:
			if beat_age >= 0.85:
				beat = Beat.DIALOGUE
				beat_age = 0
				dialogue.open_line("REI BACTÉRIA", KING_LINE, initiating_player)
		Beat.DIALOGUE:
			# Also progresses without input after the complete line has stayed readable.
			if beat_age >= 7.5:
				dialogue.advance()
		Beat.ESCAPE:
			king.position.x += (240 + beat_age * 650) * dt
			if king.position.x > camera.position.x + 430:
				king.hide()
				controls_locked = false
				_start_wave_warning()
		Beat.WARNING:
			if warning.advance(dt):
				beat = Beat.WAVE
				beat_age = 0
				spawn_clock = 0
		Beat.WAVE:
			spawn_clock -= dt
			while wave_spawned < WAVE_SIZES[wave - 1] and spawn_clock <= 0:
				_spawn_flyer()
				spawn_clock += SPAWN_INTERVALS[wave - 1]
			if wave_spawned == WAVE_SIZES[wave - 1] and get_tree().get_nodes_in_group("germs").is_empty():
				if wave < WAVE_SIZES.size():
					_start_wave_warning()
				else:
					beat = Beat.CLEARED
					victory = true
					open_limit = 3140
					finale.set_wall(swarm_barrier,false)
		Beat.MIXED:
			mixed_clock -= dt
			while mixed_spawned < MIXED_ORDER.size() and mixed_clock <= 0:
				_spawn_mixed_enemy()
				mixed_clock += 0.6
			if mixed_spawned == MIXED_ORDER.size() and get_tree().get_nodes_in_group("germs").is_empty():
				beat = Beat.FINISHED
				victory = true
				for shot in get_tree().get_nodes_in_group("enemy_projectiles"): shot.queue_free()
	_update_objective()
	_update_terminal_prompt()

func _begin_abduction(player_id: int) -> void:
	if beat != Beat.EXPLORE: return
	initiating_player = player_id
	beat = Beat.REVEAL
	beat_age = 0
	controls_locked = true
	cinematic_camera_start = $Camera2D.position.x
	elevator.get_node("Hint").hide()
	king.show()
	# Resolve active movement/attacks before taking cinematic control.
	for p in players:
		p.velocity = Vector2.ZERO
		p.attack_time = 0
		p.buffered = false
		p.dash = 0
		p.jump_height = 0
		p.jump_speed = 0
		p.specials.cancel()
		p.dash_visual.clear()
		p.get_node("Visual").rotation = 0
		p.get_node("Visual").position = Vector2.ZERO
		p.facing = 1
		if not p.down: p.sprite.play(p.equipped_weapon + "_idle")
		p.update_sprite_alignment()
	for projectile in $Projectiles.get_children(): projectile.queue_free()

func _start_escape() -> void:
	if beat != Beat.DIALOGUE: return
	beat = Beat.ESCAPE
	beat_age = 0

func _start_wave_warning() -> void:
	GameAudio.effect("warn")
	wave += 1
	wave_spawned = 0
	beat = Beat.WARNING
	beat_age = 0
	warning.start()

func _spawn_flyer() -> void:
	if beat != Beat.WAVE or wave_spawned >= WAVE_SIZES[wave - 1]: return
	var enemy = FlyingScene.instantiate()
	var camera_x: float = $Camera2D.position.x
	var lane := 203.0 + (wave_spawned % 6) * 23.0
	# Some lanes aim at the party's current depth; the flight never turns back.
	var target = players[wave_spawned % players.size()]
	if not target.down and wave_spawned % 3 == 0:
		lane = clampf(target.position.y, 203, 320)
	# Spawn on the playable side so incoming flies never have to cross a sealed wall.
	enemy.position = Vector2(minf(camera_x+374,swarm_barrier.position.x-42),lane)
	enemy.speed = 170 + wave * 35 + (wave_spawned % 4) * 12
	$Actors.add_child(enemy)
	spawned += 1
	wave_spawned += 1

func germ_defeated(_at: Vector2) -> void:
	defeated += 1

func flyer_passed() -> void:
	passed += 1

func _update_objective() -> void:
	$HUD/Goal.hide()
	$HUD/AdvanceArrow.visible = beat == Beat.EXPLORE or (beat == Beat.CLEARED and not puzzle_complete and camera_center().x < 2360) or (beat == Beat.FINISHED and finale.state in [finale.State.OPEN,finale.State.DONE] and not finale.is_modal() and not finale.camera_locked() and camera_center().x < 5340)
	GameInput.defeat_hint(status, "F2  TENTAR DE NOVO", players[0].down and players[1].down)

func nearest_enemy(at: Vector2):
	var observer = nearest_player(at)
	var best = null
	var score := INF
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy.dead: continue
		var candidate: float = at.distance_to(enemy.position)
		if enemy.is_in_group("swarm_flyers"):
			if enemy.position.x <= at.x: continue
			if observer != null and observer.player_id in enemy.passed_players: continue
			# Only the initial fly-through swarm must never be pursued backwards.
			candidate = enemy.position.x - at.x + absf(enemy.position.y-at.y)*1.5
		if candidate < score:
			score = candidate
			best = enemy
	return best

func ai_combat_destination(player, target, ordinary: Vector2) -> Vector2:
	if target.is_in_group("shield_boss"): return finale.ai_destination(player,ordinary)
	if not target.is_in_group("swarm_flyers"): return ordinary
	# Incoming flyers will reach us: hold formation instead of pursuing them.
	var line_x: float = players[0].position.x - 32
	return Vector2(clampf(line_x,player.position.x-60,player.position.x+60),clampf(target.position.y,200,320))

func ai_puzzle_destination(player):
	if is_instance_valid(exit_lift) and exit_lift.repaired:
		var boarding = exit_lift.ai_boarding_destination(player)
		if boarding != null: return boarding
	if beat in [Beat.WARNING,Beat.WAVE]:
		return players[0].position + Vector2(-32,20)
	if beat not in [Beat.CLEARED,Beat.MIXED,Beat.FINISHED]: return null
	var destination: Vector2 = players[0].position + Vector2(-30,20)
	var travel := signf(destination.x - player.position.x)
	if travel != ai_detour_direction and absf(destination.x-player.position.x) > 40: ai_detour.clear()
	if not ai_detour.is_empty():
		if player.position.distance_to(ai_detour[0]) < 10: ai_detour.pop_front()
		if not ai_detour.is_empty(): return ai_detour[0]
	for puddle in corridor.puddles:
		if travel == 0: continue
		if (puddle.position.x-player.position.x)*travel < -60 or (puddle.position.x-destination.x)*travel > 40: continue
		var a: Vector2 = (player.position-puddle.position)/Vector2(75,33)
		var b: Vector2 = (destination-puddle.position)/Vector2(75,33)
		if Geometry2D.get_closest_point_to_segment(Vector2.ZERO,a,b).length_squared() > 1: continue
		var safe_y: float = 312 if puddle.position.y < 267 else 215
		var approach_x: float = minf(player.position.x,puddle.position.x-80) if travel > 0 else maxf(player.position.x,puddle.position.x+80)
		ai_detour_direction = travel
		ai_detour = [Vector2(approach_x,safe_y),Vector2(puddle.position.x+85*travel,safe_y)]
		return ai_detour[0]
	return null

func _update_terminal_prompt() -> void:
	corridor.prompt.hide()
	if beat != Beat.CLEARED or puzzle_complete or controls_locked: return
	for p in players:
		if corridor.can_use(p):
			corridor.prompt.set_player(p.player_id)
			corridor.prompt.show()
			return

func _open_terminal(player_id: int) -> void:
	if beat != Beat.CLEARED or puzzle_complete or not corridor.can_use(players[player_id]): return
	initiating_player = player_id
	beat = Beat.ZOOM
	beat_age = 0
	controls_locked = true
	camera_before_puzzle = $Camera2D.position
	corridor.prompt.hide()
	$HUD/TeamHUD.hide()
	$HUD/HelpButton.hide()
	$HUD/AdvanceArrow.hide()
	for p in players:
		p.velocity = Vector2.ZERO
		p.attack_time = 0
		p.dash = 0
		p.specials.cancel()
		p.dash_visual.clear()

func _update_terminal_camera(dt: float) -> void:
	beat_age += dt
	var terminal_focus: Vector2 = corridor.TERMINAL_AT + Vector2(0,-65)
	if beat == Beat.ZOOM:
		var t := smoothstep(0,0.6,beat_age)
		$Camera2D.position = camera_before_puzzle.lerp(terminal_focus,t)
		$Camera2D.zoom = Vector2.ONE.lerp(Vector2(2.6,2.6),t)
		if beat_age >= 0.6:
			beat = Beat.PUZZLE
			puzzle.open(initiating_player)
	elif beat == Beat.RETURN:
		var t := smoothstep(0,0.5,beat_age)
		$Camera2D.position = terminal_focus.lerp(camera_before_puzzle,t)
		$Camera2D.zoom = Vector2(2.6,2.6).lerp(Vector2.ONE,t)
		if beat_age >= 0.5:
			beat = Beat.CLEARED
			controls_locked = false
			$HUD/TeamHUD.show()
			$HUD/HelpButton.show()
			if puzzle_complete: corridor.door.unlock()
			_update_objective()

func _close_terminal(completed: bool) -> void:
	if beat != Beat.PUZZLE: return
	puzzle_complete = completed
	beat = Beat.RETURN
	beat_age = 0

func _start_mixed_encounter() -> void:
	if mixed_started or not puzzle_complete: return
	mixed_started = true
	beat = Beat.MIXED
	beat_age = 0
	mixed_clock = 0
	victory = false
	_update_objective()

func _spawn_mixed_enemy() -> void:
	if beat != Beat.MIXED or mixed_spawned >= MIXED_ORDER.size(): return
	var kind: String = MIXED_ORDER[mixed_spawned]
	var enemy = YellowScene.instantiate() if kind == "yellow" else GermScene.instantiate()
	if kind != "yellow": enemy.variant = kind
	else: amanda_hint.announce()
	var spawn_x: float = clampf($Camera2D.position.x+365,2810,3090)
	enemy.position = Vector2(spawn_x,211+(mixed_spawned%4)*33)
	$Actors.add_child(enemy)
	mixed_spawned += 1
