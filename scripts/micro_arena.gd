extends Node2D
const GermScene = preload("res://scenes/actors/germ.tscn")
const ImpactScene = preload("res://scenes/effects/impact_burst.tscn")
const BubbleScene = preload("res://scenes/effects/soap_bubble.tscn")
const MenuSkin = preload("res://scripts/menu_button.gd")
const PadHelp = preload("res://scripts/pad_help.gd")
const BUILD_DURATION := 3.2
const BRIDGE_COST := 8
const BRIDGE_POINT := Vector2(540,250)
const BRIDGE_REACH := 62.0
const BRIDGE_ASSIST_REACH := 85.0
var part_origins: Array[Vector2] = []
var part_drop_sources: Array[Vector2] = []
var part_drop_ages: Array[float] = []
var build_grace := 0.0
var bridge_parts_reserved := false
var bridge_builder_frame := -1
var bridge_builder = null
var active_builders: Array = []
var players: Array = []
var controls_locked := true
@onready var tutorial = $Tutorial
var open_limit := 570.0
var world_limit := 2860.0
const OUTPOST_LIMIT := 2230.0
var camera_max_x := 960.0
@onready var encounter = $SupplyEncounter
@onready var elevator = $Elevator
var wave := 0
var defeated := 0
var pieces := 0
var clean_sample := false
var use_arcade_effects := false
var build_progress := 0.0
var built := false
var victory := false
var hitstop := 0.0
var shake_remaining := 0.0
var shake_duration := 0.0
var shake_strength := 0.0
var shake_clock := 0.0
@onready var status: Label = $HUD/Status
func _ready() -> void:
	players=[$Actors/MaxAvatar,$Actors/AmandaAvatar]
	players[1].sprite.sprite_frames=preload("res://assets/avatars/Pink_Monster.tres")
	bind_team_hud()
	tutorial.begin()

func bind_team_hud() -> void:
	$HUD/ControlsPanel.add_theme_stylebox_override("panel", MenuSkin.panel())
	var keys: Label = $HUD/ControlsPanel/Keys
	keys.add_theme_constant_override("line_spacing", 9)
	keys.text = "CONTROLES\n\n" + keys.text.strip_edges(false, true)
	var pad_help := PadHelp.new()
	pad_help.show_player_ids = show_player_ids()
	$HUD/ControlsPanel.add_child(pad_help)
	GameInput.prompts_changed.connect(_refresh_help_prompt)
	_refresh_help_prompt()
	if get_tree().has_meta("local_coop"):
		var partner = players[1]
		partner.ai_controlled = not bool(get_tree().get_meta("local_coop"))
		partner.refresh_player_marker()
		get_tree().remove_meta("local_coop")
	$HUD/TeamHUD.layout_changed.connect(_on_hud_layout_changed)
	$HUD/TeamHUD.bind(players)

func _refresh_help_prompt() -> void:
	GameInput.label_hint($HUD/HelpButton, 0, "controls", "F1  ?", "?")

func restart_with_current_team() -> void:
	get_tree().set_meta("local_coop", not players[1].ai_controlled)
	get_tree().reload_current_scene()
func nearest_enemy(at: Vector2):
	var best=null
	var distance=INF
	for enemy in get_tree().get_nodes_in_group("germs"):
		if not is_instance_valid(enemy) or enemy.dead: continue
		var d: float=at.distance_squared_to(enemy.position)
		if d<distance: best=enemy; distance=d
	return best
func nearest_player(at: Vector2):
	var best=null
	var distance=INF
	for player in players:
		if player.down: continue
		if tutorial.step==5 and player.ai_controlled: continue
		var d: float=at.distance_squared_to(player.position)
		if d<distance: best=player; distance=d
	return best
func spawn_wave() -> void:
	wave+=1
	for i in range(3+wave):
		var enemy=GermScene.instantiate()
		# One tougher red germ supports the more numerous green germs in each wave.
		enemy.variant = "red" if i == 2+wave else "green"
		enemy.position=Vector2(420+i*28 if wave==1 else 900+i*34,205+(i%4)*30)
		enemy.speed=38+wave*6
		$Actors.add_child(enemy)
func strike(player, combo: int, targets: Array) -> void:
	if player.equipped_weapon == "bubbles": return
	var brush: bool = player.equipped_weapon == "brush"
	var upgraded: bool = brush and player.weapon_upgraded
	var depth := 42.0 if upgraded else (28.0 if brush else 22.0)
	var rear_reach := 68.0 if upgraded and combo == 3 else 12.0
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy in targets or enemy.dead: continue
		if not enemy_can_be_hit(enemy,28.0+player.jump_height): continue
		if player.ai_controlled and tutorial.step<7: continue
		var offset: Vector2=enemy.position-player.position
		if absf(offset.y) < depth and offset.x * player.facing > -rear_reach and offset.x * player.facing < player.melee_reach():
			targets.append(enemy)
			var assisted: bool=players[0].attack_time>0 and players[1].attack_time>0 and players[0].position.distance_to(players[1].position)<100
			var direction: float = signf(offset.x) if upgraded and not is_zero_approx(offset.x) else player.facing
			damage_enemy(player,enemy,player.melee_damage(combo)+(15 if assisted else 0),direction,enemy.global_position+Vector2(-direction*12,-24))
	if tutorial.step<4: return
	for prop in breakable_props():
		if prop.broken or prop in targets: continue
		var offset: Vector2=prop.position-player.position
		if absf(offset.y) < maxf(depth, 24.0) and offset.x * player.facing > -(rear_reach if upgraded else 10.0) and offset.x * player.facing < player.melee_reach():
			targets.append(prop)
			prop.take_hit(player.melee_damage(combo),player.facing,player)
	for dummy in get_tree().get_nodes_in_group("training_dummies"):
		if not encounter.unlocked or dummy in targets: continue
		var offset: Vector2 = dummy.global_position-player.global_position
		if absf(offset.y) < maxf(depth, 28.0) and offset.x * player.facing > -rear_reach and offset.x * player.facing < player.melee_reach():
			targets.append(dummy)
			damage_training(player,dummy,player.melee_damage(combo),player.facing)
func germ_defeated(at: Vector2) -> void:
	defeated+=1
	collect_parts(2,at)
func collect_parts(amount: int, at: Vector2) -> void:
	pieces+=amount
	for i in range(amount):
		part_origins.append(at + Vector2((i - (amount - 1) * 0.5) * 24, 12 + (i % 2) * 12))
		part_drop_sources.append(at + Vector2(0, -18))
		part_drop_ages.append(0.0)
func show_player_ids() -> bool:
	return has_node("BuildSite")

func camera_center() -> Vector2:
	if players[0].down and not players[1].down: return players[1].position
	if players[1].down and not players[0].down: return players[0].position
	return (players[0].position + players[1].position) * 0.5

func keep_living_players_in_view(camera_x: float, half_width: float) -> void:
	for player in players:
		if not player.down:
			player.position.x = clampf(player.position.x, camera_x - half_width, camera_x + half_width)

func bridge_has_parts() -> bool:
	return bridge_parts_reserved or pieces >= BRIDGE_COST

func is_assembling(player) -> bool:
	if controls_locked or built or build_grace <= 0 or player not in active_builders: return false
	if not is_instance_valid(bridge_builder) or not bridge_builder.can_assemble() or bridge_builder.position.distance_to(BRIDGE_POINT) > BRIDGE_REACH:
		return false
	return player.can_assemble() and player.position.distance_to(BRIDGE_POINT) <= BRIDGE_ASSIST_REACH

func assembly_facing(player) -> float:
	return signf(605 - player.position.x)

func stop_assembling(player) -> void:
	if player == bridge_builder:
		build_grace = 0
		active_builders.clear()
	else:
		active_builders.erase(player)

func interact(player, dt: float) -> void:
	if controls_locked or player.down: return
	for other in players:
		if other != player and other.down and player.position.distance_to(other.position) < 40:
			other.revive_progress += dt
			if other.revive_progress >= 2:
				other.down = false
				other.hp = mini(50, other.max_hp)
				other.invulnerable = 2
				other.revive_progress = 0
			return
	if tutorial.step < 6 or built or not bridge_has_parts() or player.ai_controlled or not player.can_assemble(): return
	if player.position.distance_to(BRIDGE_POINT) > BRIDGE_REACH: return
	var partner = players[1] if player == players[0] else players[0]
	var nearby: bool = partner.position.distance_to(BRIDGE_POINT) <= BRIDGE_ASSIST_REACH
	if not nearby and not partner.down: return
	var tick := Engine.get_physics_frames()
	if bridge_builder_frame == tick and bridge_builder != player: return
	bridge_builder_frame = tick
	bridge_builder = player
	if not bridge_parts_reserved:
		bridge_parts_reserved = true
		pieces -= BRIDGE_COST
	active_builders = [player]
	if nearby and partner.can_assemble() and (partner.ai_controlled or Input.is_action_pressed("p%d_interact" % partner.player_id)):
		active_builders.append(partner)
	build_grace = 0.2
	var rate := 1.0 if active_builders.size() == 2 else 0.65
	build_progress = minf(BUILD_DURATION, build_progress + dt * rate)
	$BuildSite.sample(build_progress / BUILD_DURATION)
	if build_progress >= BUILD_DURATION:
		built = true
		open_limit = 1230
		$Bridge.visible = true
		$Gate.visible = false
		$Gate/Collision.set_deferred("disabled", true)
		spawn_wave()
func _process(dt: float) -> void:
	if not controls_locked: build_grace=maxf(0,build_grace-dt)
	if GameInput.help_requested() and not encounter.is_modal() and not elevator.is_transitioning():
		$HUD/ControlsPanel.visible=not $HUD/ControlsPanel.visible
		controls_locked=$HUD/ControlsPanel.visible or tutorial.step==0
	if Input.is_action_just_pressed("join") and not $HUD/ControlsPanel.visible and not encounter.is_modal() and not elevator.is_transitioning():
		players[1].ai_controlled=not players[1].ai_controlled
		players[1].refresh_player_marker()
	if GameInput.retry_requested(self):
		restart_with_current_team()
		return
	var center := camera_center()
	$Camera2D.position.x=clampf(center.x,320,camera_max_x)
	$BuildSite.update_camera(dt, center)
	update_camera_shake(dt)
	keep_living_players_in_view($Camera2D.position.x, 300)
	if defeated>=6 and built and get_tree().get_nodes_in_group("germs").is_empty(): victory=true
	GameInput.defeat_hint(status, "F2  ↻", players[0].down and players[1].down)
	$HUD/Pieces.text="%02d" % pieces
	$HUD/Pieces.visible=tutorial.step>=4
	$HUD/BoltIcon.visible=tutorial.step>=4
	$HUD/Goal.visible=tutorial.step==6 and not built
	if encounter.unlocked:
		$HUD/Goal.text=encounter.objective_text()
		$HUD/Goal.visible=not elevator.is_transitioning()

func _on_hud_layout_changed(two_players: bool) -> void:
	var radio: Control = $HUD/Communicator
	radio.position = Vector2(312, 105) if two_players else Vector2(272, 88)
	radio.size = Vector2(312, 68) if two_players else Vector2(352, 76)
	radio._layout()

func spawn_impact(kind: int, contact: Vector2, direction: float) -> Node2D:
	var burst = ImpactScene.instantiate()
	burst.kind = kind
	burst.facing = direction
	$ImpactEffects.add_child(burst)
	burst.global_position = contact
	return burst

func enemy_can_be_hit(enemy, attack_height: float) -> bool:
	return not enemy.has_method("can_be_hit") or enemy.can_be_hit(attack_height)

func damage_enemy(player, enemy, amount: int, direction: float, contact: Vector2, gain_energy := true, attack_height := -1.0, hit_origin: Variant = null) -> void:
	if not is_instance_valid(enemy) or enemy.dead: return
	if attack_height < 0: attack_height = 28.0+player.jump_height
	if not enemy_can_be_hit(enemy,attack_height): return
	if enemy.has_method("can_be_hit"): contact = enemy.global_position+Vector2(0,-enemy.flight_height)
	tutorial.record_action("germ",player)
	var shielded := false
	if enemy.has_method("receive_attack"):
		var origin: Vector2 = player.global_position if hit_origin == null else hit_origin
		shielded = enemy.receive_attack(amount,origin,direction)
	else:
		enemy.take_hit(amount,direction)
	GameAudio.effect("lever" if shielded else "hit", contact)
	if not shielded: spawn_impact(1,contact,direction)
	player.register_combo_hit()
	if gain_energy and not player.specials.active: player.energy = minf(100,player.energy+8)
	_set_camera_shake_offset(Vector2(3, -2))

func spawn_bubble(player, upgraded := false, explosive := false) -> Node2D:
	var bubble = BubbleScene.instantiate()
	bubble.shooter = player
	bubble.direction = player.facing
	bubble.height = 28.0 + player.jump_height
	if upgraded:
		bubble.overcharged = true
		bubble.modulate = player.BUBBLE_UPGRADE_COLOR
		bubble.speed = 390.0 if explosive else 470.0
		bubble.radius = 14.0 if explosive else 10.0
		bubble.damage = 52 if explosive else 24
		bubble.blast_radius = 88.0 if explosive else 0.0
	$Projectiles.add_child(bubble)
	bubble.global_position = player.global_position + Vector2(player.facing * (48 if upgraded else 34), 0)
	return bubble

func damage_training(player, dummy, amount: int, direction: float, gain_energy := true) -> void:
	if not encounter.unlocked: return
	dummy.take_hit(amount,direction)
	spawn_impact(1,dummy.global_position+Vector2(-direction*12,-30),direction)
	player.register_combo_hit()
	if gain_energy and not player.specials.active: player.energy = minf(100,player.energy+8)

func special_area(player, center: Vector2, radius: float, depth: float, damage: int, attack_height := -1.0) -> void:
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy.dead or (player.ai_controlled and tutorial.step < 7): continue
		var d: Vector2 = enemy.global_position-center
		if absf(d.x) <= radius and absf(d.y) <= depth:
			var origin: Vector2 = center if absf(d.x) > 1 else player.global_position
			damage_enemy(player,enemy,damage,1 if d.x >= 0 else -1,enemy.global_position+Vector2(0,-24),false,attack_height,origin)
	if encounter.unlocked:
		for dummy in get_tree().get_nodes_in_group("training_dummies"):
			var d: Vector2 = dummy.global_position-center
			if absf(d.x) <= radius and absf(d.y) <= depth: damage_training(player,dummy,damage,1 if d.x >= 0 else -1,false)
	if tutorial.step >= 4:
		for crate in breakable_props():
			var d: Vector2 = crate.global_position-center
			if not crate.broken and absf(d.x) <= radius and absf(d.y) <= depth:
				crate.take_hit(damage,1 if d.x >= 0 else -1,player)

func spawn_special_bubble(player, lane: int, giant: bool) -> Node2D:
	var bubble = spawn_bubble(player)
	bubble.position.y += lane
	bubble.damage = 140 if giant else 14
	bubble.radius = 28 if giant else 9
	bubble.speed = 200 if giant else 340
	bubble.max_distance = 900 if giant else 780
	bubble.giant = giant
	bubble.special_shot = true
	return bubble

func start_camera_shake(strength: float, seconds: float) -> void:
	shake_strength = maxf(shake_strength,strength)
	shake_remaining = maxf(shake_remaining,seconds)
	shake_duration = shake_remaining
	shake_clock = 0

func update_camera_shake(dt: float) -> void:
	if controls_locked: return
	if shake_remaining > 0:
		shake_remaining = maxf(0,shake_remaining-dt)
		shake_clock += dt
		var strength := shake_strength*shake_remaining/maxf(shake_duration,0.001)
		_set_camera_shake_offset(Vector2(roundf(sin(shake_clock*103)*strength),roundf(cos(shake_clock*137)*strength*0.65)))
		if shake_remaining <= 0:
			shake_strength = 0
			$Camera2D.offset = Vector2.ZERO
	else:
		_set_camera_shake_offset($Camera2D.offset.lerp(Vector2.ZERO,minf(1,dt*20)))

func _set_camera_shake_offset(wanted: Vector2) -> void:
	var camera: Camera2D = $Camera2D
	var half_view := Vector2(320, 180) / camera.zoom
	var lower := (half_view - camera.position).min(Vector2.ZERO)
	var upper := (Vector2(camera_max_x + 320, 360) - half_view - camera.position).max(Vector2.ZERO)
	# Reflect the nudge off the edge so impacts still move the camera there.
	if wanted.x < lower.x or wanted.x > upper.x:
		wanted.x = -wanted.x
	camera.offset = wanted.clamp(lower, upper)

func water_beam_length(player, direction: float) -> float:
	var start: Vector2 = player.global_position
	var end_x := clampf(start.x+direction*(48+560),8,world_limit)
	var finish := Vector2(end_x,start.y)
	var query := PhysicsRayQueryParameters2D.create(start,finish,1)
	query.hit_from_inside = true
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): finish = wall.position
	return clampf((finish.x-start.x)*direction-48,0,560)

func water_beam_damage(player, direction: float, length: float, amount: int) -> void:
	if length <= 0: return
	var candidates := get_tree().get_nodes_in_group("germs")
	if encounter.unlocked: candidates.append_array(get_tree().get_nodes_in_group("training_dummies"))
	if tutorial.step >= 4: candidates.append_array(breakable_props())
	for body in candidates:
		if not is_instance_valid(body) or body.is_queued_for_deletion(): continue
		var enemy := body.is_in_group("germs")
		var dummy := body.is_in_group("training_dummies")
		if enemy and (body.dead or (player.ai_controlled and tutorial.step < 7)): continue
		if not enemy and not dummy and body.broken: continue
		var offset: Vector2 = body.global_position-player.global_position
		if offset.x*direction < 0 or offset.x*direction > 48+length or absf(offset.y) > 32: continue
		if enemy: damage_enemy(player,body,amount,direction,body.global_position+Vector2(0,-22),false)
		elif dummy: damage_training(player,body,amount,direction,false)
		else: body.take_hit(amount,direction,player)

func breakable_props() -> Array:
	var props: Array = $Breakables.get_children()
	props.append_array(get_tree().get_nodes_in_group("medical_supplies"))
	return props
