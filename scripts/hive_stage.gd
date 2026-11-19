extends "res://scripts/journey_arena.gd"

const Chapters = preload("res://scripts/chapter_catalog.gd")
const Impact = preload("res://scripts/hive_impact.gd")
const Flyers = preload("res://scenes/actors/flying_bacterium.tscn")
const YellowFlyer = preload("res://scenes/actors/yellow_flying_bacterium.tscn")
const Layout = preload("res://scripts/hive_layout.gd")
const WorkshopArt = preload("res://scripts/hive_workshop_art.gd")
const Radio = preload("res://scripts/journey_radio.gd")
const Finale = preload("res://scripts/hive_finale.gd")
const EXPLORE_ZOOM := 0.86
const BOSS_CHECKPOINT := "hive_king_checkpoint"
const BOSS_RETRY := "hive_king_retry"

var WAVE_ENTRY := Layout.x(811.0)
var KING_ENTRY := Layout.x(3511.0)
var WAVE_WEST := Layout.x(787.0)
var WAVE_EAST := Layout.x(1125.0)
var SECTORS := [
	[1260.0, 1216.0, 1630.0, 1437.0, "GALERIA DOS DRENOS"],
	[1755.0, 1716.0, 2150.0, 1936.0, "ESTAÇÃO DE PRESSÃO"],
	[2340.0, 2290.0, 2740.0, 2518.0, "TÚNEL DE EXAUSTÃO"],
	[2960.0, 2910.0, 3352.0, 3122.0, "DIQUE DA COLMEIA"],
]
var KING_WEST := Layout.x(3472.0)
const FORGE_SECONDS := 0.85
const ASSAULTS := [
	[Vector2(957, 246), Vector2(1022, 282), Vector2(1089, 314), Vector2(864, 310)],
	[Vector2(1080, 253), Vector2(1055, 313), Vector2(807, 248), Vector2(820, 316), Vector2(974, 282)],
]
enum Beat { WORKSHOP, ASSAULT, APPROACH_KING, KING, CAPTURE, SEAL, END, SEWER_WAVES }

var beat := Beat.WORKSHOP
var sector := 0
var pressure_clock := 0.0
var pressure_step := 0
var hp_trail_hold := 0.0
var camera_kick_left := 0.0
var camera_kick_length := 0.45
var camera_kick_power := 0.0
@onready var boss_hp: ProgressBar = $HUD/TravelProgress
@onready var hp_trail: ProgressBar = $HUD/BossHealthTrail
@onready var pressure_drains: Array = [$Drains/PressureWest, $Drains/PressureOutlet, $Drains/ReturnEast]
@onready var pressure_lamp: Sprite2D = $Scenery/PumpGauge/Lamp
@onready var captive: Node2D = $Scenery/Captive
@onready var sector_gates := [$Scenery/DrainGate, $Scenery/PressureGate, $Scenery/ExhaustGate, $Scenery/DikeGate]
@onready var arrival_lift = $ArrivalElevator
@onready var vents := $Drains.get_children()
var arsenal_claimed := false
var workshop_radio: Control
var forge_clock := 0.0
var forge_weapons: Array[Sprite2D] = []
var forge_starts: Array[Vector2] = []
var assault := 0
var remaining := 0
var spawn_delay := 0.0
var progress_barrier: StaticBody2D
var finale: Node
@onready var arsenal: Node2D = $Arsenal
@onready var bubble_puzzle = $BubblePuzzle
@onready var king = $Actors/King
@onready var capture_hint: Label = $CaptureJar/Hint
@onready var jar: Node2D = $CaptureJar
@onready var west_gate = $Scenery/AssaultEntrance
@onready var east_gate = $Scenery/AssaultExit
@onready var king_gate = $Scenery/KingGate

func _ready() -> void:
	entry_key = "hive_entry_state"
	# Direct editor launches start after the campaign's mandatory sample pickup.
	clean_sample = true
	use_arcade_effects = true
	super._ready()
	Layout.expand(self)
	WorkshopArt.apply(self)
	for room in SECTORS:
		for index in 4: room[index] = Layout.x(room[index])
	workshop_radio = Radio.new()
	$HUD.add_child(workshop_radio)
	bubble_puzzle.burst.connect(_burst)
	king.health_changed.connect(_show_king_hp)
	king.enraged.connect(_king_reinforcements)
	king.exhausted.connect(_ready_capture)
	room_left = 36.0
	room_right = Layout.x(3998.0)
	floor_min = 190.0
	world_limit = Layout.x(4044.0)
	open_limit = west_gate.position.x - 24.0
	camera_max_x = world_limit - 320.0 / EXPLORE_ZOOM
	_configure_boundaries()
	west_gate.openness = 0.0
	king_gate.openness = 1.0
	$HUD/JourneyTitle.text = "A COLMEIA"
	$HUD/JourneyTitle.add_theme_color_override("font_outline_color", Color("09121f"))
	$HUD/TravelTime.text = ""
	$HUD/TravelTime.offset_left = 396
	$HUD/TravelTime.add_theme_constant_override("outline_size", 4)
	boss_hp.hide()
	var no_fill := StyleBoxEmpty.new()
	boss_hp.add_theme_stylebox_override("background", no_fill)
	hp_trail.add_theme_stylebox_override("background", MenuSkin.panel(Color("382842")))
	hp_trail.add_theme_stylebox_override("fill", MenuSkin.panel(Color("ffce90")))
	$HUD/Finale/Panel.add_theme_stylebox_override("panel", MenuSkin.panel())
	var menu: Button = $HUD/Finale/Panel/Content/Menu
	MenuSkin.apply(menu, true)
	menu.pressed.connect(_return_to_menu)
	players[0].position = Vector2(124, 282)
	players[1].position = Vector2(213, 284)
	arrival_lift.opened.connect(_arrival_opened)
	$Transition/Black.hide()
	if get_tree().has_meta(BOSS_RETRY):
		_finish_lift()
		get_tree().remove_meta(BOSS_RETRY)
		_restore_king_checkpoint()
	elif get_tree().has_meta("hive_king_chapter"):
		get_tree().remove_meta("hive_king_chapter")
		_finish_lift()
		_start_king_chapter()
	elif get_tree().has_meta("hive_chapter"):
		_skip_arrival(Layout.point(Vector2(438, 280)), Layout.point(Vector2(474, 306)))
		$Camera2D.position.x = Layout.x(462)
		_finish_lift()

func _finish_lift() -> void:
	arrival_lift._physics_process(2.5)
	arrival_lift.black.hide()

func _arrival_opened() -> void:
	transitioning = false
	arrival_lift.get_node("Hint").hide()

func _configure_boundaries() -> void:
	$StageBoundaries/West.position.x = room_left - 16
	$StageBoundaries/East.position.x = room_right + 16
	$StageBoundaries/North.position.y = floor_min - 16
	for edge in ["North", "South"]:
		var boundary: CollisionShape2D = get_node("StageBoundaries/" + edge)
		boundary.position.x = world_limit * 0.5
		var shape := boundary.shape.duplicate() as RectangleShape2D
		shape.size.x = world_limit
		boundary.shape = shape
	# One invisible collision plane follows the active progression limit.
	for gate in [west_gate, east_gate, king_gate] + sector_gates:
		gate.hide()
		gate.get_node("Body").collision_layer = 0
	progress_barrier = StaticBody2D.new()
	progress_barrier.name = "ProgressBarrier"
	progress_barrier.collision_layer = 1
	progress_barrier.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28,220)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	progress_barrier.add_child(collision)
	add_child(progress_barrier)
	_sync_progress_barrier()

func _sync_progress_barrier() -> void:
	progress_barrier.position = Vector2(open_limit+14,258)
	progress_barrier.collision_layer = 1 if open_limit < room_right else 0

func _skip_arrival(first: Vector2, second: Vector2) -> void:
	players[0].position = first
	players[1].position = second
	transitioning = false
	controls_locked = false
	$Transition/Black.hide()

func _process(dt: float) -> void:
	if beat == Beat.SEAL:
		_animate_seal(dt)
		return
	if beat == Beat.END: return
	super._process(dt)
	if transitioning: return
	if controls_locked:
		bubble_puzzle.hide_hints()
		capture_hint.hide()
		return
	_update_camera(dt)
	if beat == Beat.WORKSHOP and not arsenal_claimed:
		if players.any(func(p): return not p.down and p.position.x >= bubble_puzzle.position.x - 260):
			workshop_radio.say("workshop", "DRA. AMANDA", "rápido! vamos usar o material de emergencia e melhorar nossos equipamentos!")
	if beat == Beat.KING:
		hp_trail_hold = maxf(0.0, hp_trail_hold - dt)
		if hp_trail_hold <= 0.0:
			hp_trail.value = move_toward(hp_trail.value, boss_hp.value, 2100.0 * dt)
	bubble_puzzle.update_hints(players)
	if beat == Beat.CAPTURE: _update_capture_hint()
	if beat == Beat.WORKSHOP and _team_past(WAVE_ENTRY): _begin_assault()
	if beat == Beat.APPROACH_KING:
		if sector < SECTORS.size():
			if _team_past(SECTORS[sector][0]): _start_sewer_room()
		elif _team_past(KING_ENTRY): _begin_king()

func _physics_process(dt: float) -> void:
	if controls_locked: return
	bubble_puzzle.tick(dt, players)
	_tick_arsenal(dt)
	var exit_open := beat != Beat.WORKSHOP and beat != Beat.ASSAULT
	east_gate.openness = move_toward(east_gate.openness, float(exit_open), dt * 2.6)
	var assault_open := beat != Beat.ASSAULT and _weapons_ready()
	west_gate.openness = move_toward(west_gate.openness, float(assault_open), dt * 2.8)
	king_gate.openness = move_toward(king_gate.openness, float(beat not in [Beat.KING, Beat.CAPTURE, Beat.SEAL, Beat.END]), dt * 2.8)
	for i in sector_gates.size():
		var gate = sector_gates[i]
		gate.openness = move_toward(gate.openness, float(i < sector), dt * 2.6)
	_contain_enemies()
	if beat == Beat.SEWER_WAVES and sector == 1: _tick_pressure_room(dt)
	if beat in [Beat.ASSAULT, Beat.SEWER_WAVES] and remaining == 0:
		spawn_delay = maxf(0.0, spawn_delay - dt)
		if spawn_delay <= 0.0:
			if beat == Beat.ASSAULT: _start_next_assault()
			else: _sewer_wave()
	_sync_progress_barrier()

func ultimate_camera(kind: String) -> void:
	if SceneFx.reduced_motion: return
	camera_kick_length = 0.46 if kind == "solar" else 0.62
	camera_kick_left = camera_kick_length
	camera_kick_power = 0.055 if kind == "solar" else 0.032
	start_camera_shake(5.0 if kind == "solar" else 3.5, 0.25)

func _update_camera(dt: float) -> void:
	var camera: Camera2D = $Camera2D
	camera_kick_left = maxf(0.0, camera_kick_left - dt)
	var progress := 1.0 - camera_kick_left / camera_kick_length
	var zoom := minf(EXPLORE_ZOOM, 600.0 / (room_right - KING_WEST)) if beat in [Beat.KING, Beat.CAPTURE] else EXPLORE_ZOOM
	camera.zoom = Vector2.ONE * zoom * (1.0 + sin(PI * progress) * camera_kick_power)
	var target := clampf(camera_center().x, 320.0 / zoom, world_limit - 320.0 / zoom)
	if beat == Beat.ASSAULT: target = (WAVE_WEST + WAVE_EAST) * 0.5
	elif beat == Beat.SEWER_WAVES: target = SECTORS[sector][3]
	elif beat in [Beat.KING, Beat.CAPTURE]: target = (KING_WEST + room_right) * 0.5
	camera.position.x = lerpf(camera.position.x, target, minf(1.0, dt * 5.0))
	keep_living_players_in_view(camera.position.x, 301.0 / camera.zoom.x)

func _team_past(at: float) -> bool:
	return players.all(func(p): return p.down or p.position.x >= at)

func _contain_enemies() -> void:
	if beat not in [Beat.ASSAULT, Beat.SEWER_WAVES, Beat.KING]: return
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy == king or enemy.dead or enemy.is_in_group("royal_bubbles") or enemy.is_in_group("swarm_flyers"): continue
		enemy.position.x = clampf(enemy.position.x, room_left + 8.0, open_limit - 8.0)
		enemy.position.y = maxf(enemy.position.y, floor_min + 4.0)

func _begin_assault() -> void:
	if not _weapons_ready(): return
	beat = Beat.ASSAULT
	room_left = WAVE_WEST
	spawn_delay = 0.65
	$HUD/TravelTime.text = "1/2"
	start_camera_shake(2, 0.18)

func _start_next_assault() -> void:
	if assault == ASSAULTS.size():
		beat = Beat.APPROACH_KING
		room_left = 36.0
		open_limit = SECTORS[0][2]
		$HUD/TravelTime.text = ""
		_burst(Layout.point(Vector2(1141, 228)), Color("94ffe6"), 1.6)
		return
	var positions: Array = ASSAULTS[assault]
	for i in positions.size():
		_spawn_germ(Layout.point(positions[i]), i == 1 or (assault == 1 and i == 4), assault == 1)
	assault += 1
	remaining = positions.size()
	$HUD/TravelTime.text = "%d/%d" % [assault, ASSAULTS.size()]

func _start_sewer_room() -> void:
	beat = Beat.SEWER_WAVES
	var room: Array = SECTORS[sector]
	room_left = room[1]
	open_limit = room[2]
	$HUD/JourneyTitle.text = room[4]
	$HUD/TravelTime.text = "1/2"
	spawn_delay = 0.52
	assault = 0
	remaining = 0
	GameAudio.effect("lever")

func _sewer_wave() -> void:
	if assault == 2:
		_open_next_sector()
		return
	var center: float = SECTORS[sector][3]
	var slots := [Vector2(-246, 218), Vector2(244, 308), Vector2(202, 240), Vector2(-235, 312)]
	if assault == 1 or sector == 1: slots.append(Vector2(63, 273))
	for i in slots.size():
		_spawn_germ(Vector2(center, 0) + slots[i], i == (2 if assault == 0 else 0), assault == 1)
	remaining = slots.size()
	if sector in [0, 2, 3]: _spawn_flyers(center)
	assault += 1
	if sector == 1:
		pressure_clock = 0.85
		pressure_step = 0
	$HUD/TravelTime.text = "%d/2" % assault

func _tick_pressure_room(dt: float) -> void:
	if remaining == 0:
		pressure_lamp.modulate = Color("a8ff82")
		return
	pressure_clock -= dt
	pressure_lamp.modulate = Color("ffc975") if pressure_clock < 0.55 else Color.WHITE
	if pressure_clock > 0.0: return
	# The middle drain is on the opposite lane. Reverse the sweep in wave two.
	var index := pressure_step % pressure_drains.size()
	if assault == 2: index = pressure_drains.size() - 1 - index
	pressure_drains[index].trigger()
	pressure_step += 1
	pressure_clock = 2.38 if assault == 1 else 1.92

func _open_next_sector() -> void:
	sector += 1
	beat = Beat.APPROACH_KING
	room_left = 36.0
	open_limit = SECTORS[sector][2] if sector < SECTORS.size() else room_right
	$HUD/TravelTime.text = ""
	GameAudio.effect("confirm")

func _spawn_flyers(center: float) -> void:
	if sector != 0:
		var diver = YellowFlyer.instantiate()
		diver.position = Vector2(center + 228, 221 if assault == 0 else 302)
		diver.dive_after = 3.2
		$Actors.add_child(diver)
		remaining += 1
	if sector == 0 and assault == 0: return
	for i in 2:
		var flyer = Flyers.instantiate()
		flyer.position = Vector2(center + 264 - i * 215, 224 + i * 83)
		flyer.speed = 166 + assault * 19
		$Actors.add_child(flyer)
		remaining += 1

func flyer_passed() -> void:
	_count_wave_enemy()

func _spawn_germ(at: Vector2, red: bool, quick: bool) -> void:
	var enemy = GermScene.instantiate()
	enemy.variant = "red" if red else "green"
	enemy.speed = 67.0 if red else (103.0 if quick else 83.0)
	enemy.position = at
	var closest = nearest_player(at)
	if closest != null and closest.position.distance_to(at) < 48.0:
		enemy.position.y = 315.0 if closest.position.y < 276.0 else 241.0
	$Actors.add_child(enemy)
	_burst(enemy.position - Vector2(0, 29), Color("cfffac"), 1.05)

func germ_defeated(at: Vector2) -> void:
	super.germ_defeated(at)
	_count_wave_enemy()

func _count_wave_enemy() -> void:
	if beat in [Beat.ASSAULT, Beat.SEWER_WAVES]:
		remaining = maxi(0, remaining - 1)
		if remaining == 0: spawn_delay = 0.62

func _begin_king(save_checkpoint := true) -> void:
	beat = Beat.KING
	room_left = KING_WEST
	sector = SECTORS.size()
	captive.show()
	hp_trail.max_value = king.MAX_HP
	hp_trail.value = king.MAX_HP
	hp_trail.show()
	for player in players:
		if player.down: continue
		player.hp = maxi(player.hp, mini(72, player.max_hp))
		player.healing_flasks = maxi(player.healing_flasks, 2)
	if save_checkpoint:
		get_tree().set_meta(BOSS_CHECKPOINT, {"party": Party.capture(self), "upgraded": arsenal_claimed})
	king.begin()
	$HUD/JourneyTitle.hide()
	$HUD/BossTitle.show()
	boss_hp.show()
	GameAudio.music("king")
	_burst(king.position - Vector2(0, 39), Color("ffe8a1"), 2.0)
	start_camera_shake(4, 0.25)

func _start_king_chapter() -> void:
	arsenal_claimed = true
	bubble_puzzle.solved = true
	bubble_puzzle.hide_hints()
	clean_sample = true
	for i in players.size():
		var player = players[i]
		if player.equipped_weapon == "none": player.equip_weapon("brush" if i == 0 else "bubbles")
		player.weapon_upgraded = true
		player.hp = player.max_hp
		player.energy = 100.0
		player.down = false
		player.healing_flasks = maxi(player.healing_flasks,5)
	_skip_arrival(Layout.point(Vector2(3554,268)),Layout.point(Vector2(3589,307)))
	$Camera2D.position.x = (KING_WEST+room_right)*0.5
	$Camera2D.zoom = Vector2.ONE*minf(EXPLORE_ZOOM,600.0/(room_right-KING_WEST))
	open_limit = room_right
	_sync_progress_barrier()
	_begin_king()

func _restore_king_checkpoint() -> void:
	var checkpoint: Dictionary = get_tree().get_meta(BOSS_CHECKPOINT, {})
	if checkpoint.is_empty(): return
	var coop: bool = not players[1].ai_controlled
	Party.apply(self, checkpoint.party)
	players[1].ai_controlled = not coop
	arsenal_claimed = bool(checkpoint.upgraded)
	bubble_puzzle.solved = true
	for player in players: player.weapon_upgraded = arsenal_claimed
	_skip_arrival(Layout.point(Vector2(3554, 268)), Layout.point(Vector2(3589, 307)))
	$Camera2D.position.x = (KING_WEST + room_right) * 0.5
	open_limit = room_right
	east_gate.openness = 1.0
	king_gate.openness = 0.0
	_begin_king(false)

func restart_with_current_team() -> void:
	if beat in [Beat.KING, Beat.CAPTURE] and get_tree().has_meta(BOSS_CHECKPOINT):
		get_tree().set_meta(BOSS_RETRY, true)
	super.restart_with_current_team()

func king_floor(at: Vector2) -> Vector2:
	return Vector2(clampf(at.x, KING_WEST + 38.0, room_right - 30.0), clampf(at.y, floor_min + 12, 316.0))

func ai_combat_destination(player, target, destination: Vector2) -> Vector2:
	var detour = _avoid_jet(player, destination)
	if detour != null: return detour
	var escape: Variant = king.escape_point(player.position) if beat == Beat.KING else null
	if escape != null: return escape
	var limited := Vector2(clampf(destination.x, room_left + 15, open_limit - 15), clampf(destination.y, floor_min + 9.0, 322.0))
	if target == king and absf(limited.x - target.position.x) < 52.0:
		limited.x = target.position.x + (95.0 if target.position.x < (room_left + room_right) * 0.5 else -95.0)
	return limited

func _show_king_hp(amount: int, maximum: int) -> void:
	boss_hp.max_value = maximum
	boss_hp.value = amount
	hp_trail_hold = 0.20
	$HUD/BossTitle.text = "%s   •   %d / %d" % ["REI BACTÉRIA II" if king.phase == 2 else "REI BACTÉRIA", amount, maximum]
	if amount <= king.PHASE_MARK: boss_hp.modulate = Color("ffb765")

func _king_reinforcements() -> void:
	GameAudio.effect("roar", king.position)
	$Scenery/ColetorDoRei.modulate = Color("db8062")
	ultimate_camera("solar")
	_burst(king.position - Vector2(0, 54), Color("ffb871"), 3.4)
	start_camera_shake(6, 0.31)
	_spawn_germ(Layout.point(Vector2(3554, 307)), false, true)
	_spawn_germ(Layout.point(Vector2(3942, 242)), false, true)

func _ready_capture() -> void:
	beat = Beat.CAPTURE
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy != king: enemy.queue_free()
	for orb in get_tree().get_nodes_in_group("royal_bubbles"): orb.queue_free()
	boss_hp.hide()
	hp_trail.hide()
	$HUD/BossTitle.hide()
	jar.position = king_floor(king.position + Vector2(-42.0 if king.position.x > KING_WEST + 282 else 42.0, 4))
	jar.show()
	_burst(king.position - Vector2(0, 40), Color("fff4b9"), 2.0)

func _close_enough(player) -> bool:
	return not player.down and not player.ai_controlled and player.position.distance_to(jar.position) <= 76.0

func _update_capture_hint() -> void:
	for player in players:
		if _close_enough(player):
			var key := "E" if player.player_id == 0 else "U"
			GameInput.label_hint(capture_hint, player.player_id, "interact", key)
			capture_hint.show()
			return
	capture_hint.hide()

func interact(player, dt: float) -> void:
	super.interact(player, dt)
	if controls_locked or player.ai_controlled or player.down: return
	if not Input.is_action_just_pressed("p%d_interact" % player.player_id): return
	if beat == Beat.CAPTURE:
		if _close_enough(player) and clean_sample: _seal_king(player)
	elif player.can_assemble() and not bubble_puzzle.solved:
		bubble_puzzle.adjust(bubble_puzzle.nearby_spring(player.global_position))

func _seal_king(player) -> void:
	if beat != Beat.CAPTURE or not clean_sample: return
	clean_sample = false
	GameAudio.effect("jar", player.global_position)
	beat = Beat.SEAL
	controls_locked = true
	capture_hint.hide()
	bubble_puzzle.hide_hints()
	finale = Finale.new()
	add_child(finale)
	finale.begin(self,player)

func _animate_seal(dt: float) -> void:
	if finale != null: finale.advance(dt)

func _return_to_menu() -> void:
	Chapters.reset(get_tree())
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _weapons_ready() -> bool:
	return arsenal_claimed and players.all(func(p): return p.weapon_upgraded)

func _tick_arsenal(dt: float) -> void:
	if beat >= Beat.KING or arsenal_claimed or not bubble_puzzle.solved: return
	if forge_clock <= 0.0:
		$Arsenal/Terminal.modulate = Color("a9ffd1")
		_burst(arsenal.position + Vector2(0, -47), Color("bfffe6"), 1.6)
		for avatar in players:
			var template: Sprite2D = $Arsenal/Brush if avatar.equipped_weapon == "brush" else $Arsenal/Blaster
			var icon := template.duplicate() as Sprite2D
			arsenal.add_child(icon)
			icon.position.x = -20.0 if avatar.player_id == 0 else 20.0
			icon.show()
			forge_weapons.append(icon)
			forge_starts.append(icon.global_position)
	forge_clock += dt
	var progress := clampf(forge_clock / FORGE_SECONDS, 0.0, 1.0)
	for i in forge_weapons.size():
		var icon := forge_weapons[i]
		var avatar = players[i]
		var target: Vector2 = avatar.global_position - Vector2(0, 25 + avatar.jump_height)
		icon.global_position = forge_starts[i].lerp(target, smoothstep(0.16, 1.0, progress))
		if not SceneFx.reduced_motion: icon.position.y -= sin(progress * PI) * 45.0
	if progress < 1.0: return
	GameAudio.effect("nova", arsenal.global_position)
	arsenal_claimed = true
	for i in players.size():
		var avatar = players[i]
		var glow: Color = avatar.BRUSH_UPGRADE_COLOR if avatar.equipped_weapon == "brush" else avatar.BUBBLE_UPGRADE_COLOR
		avatar.weapon_upgraded = true
		avatar.energy = 100.0
		forge_weapons[i].queue_free()
		_burst(avatar.global_position + Vector2(0, -28 - avatar.jump_height), glow, 1.35)
	open_limit = WAVE_EAST
	start_camera_shake(2, 0.16)

func spawn_impact(_kind: int, contact: Vector2, direction: float) -> Node2D:
	var effect := Impact.new()
	$ImpactEffects.add_child(effect)
	effect.global_position = contact
	effect.flip_h = direction < 0.0
	return effect

func _burst(at: Vector2, tint: Color, size: float) -> void:
	var effect := spawn_impact(1, at, 1)
	effect.modulate = tint
	effect.scale = Vector2.ONE * size

func royal_vents() -> Array:
	return [$Drains/RoyalWest, $Drains/RoyalValve, $Drains/RoyalEast]

func drain_active(vent) -> bool:
	if vent.position.x > KING_WEST: return beat == Beat.KING and king.phase == 2
	if vent.position.x < Layout.x(1160): return beat == Beat.ASSAULT
	return beat == Beat.SEWER_WAVES and vent.position.x > room_left and vent.position.x < open_limit

func _avoid_jet(player, destination: Vector2) -> Variant:
	for vent in vents:
		if not drain_active(vent) or vent.state == vent.State.REST: continue
		if absf(player.position.x - vent.position.x) > 62: continue
		if absf(player.position.y - vent.position.y) < 29:
			return Vector2(player.position.x, vent.position.y + (46 if vent.position.y < 277 else -46))
		if absf(destination.y - vent.position.y) < 29:
			return Vector2(destination.x, player.position.y)
	return null
