extends Node2D
const GermScene = preload("res://scenes/actors/germ.tscn")
const ImpactScene = preload("res://scenes/effects/impact_burst.tscn")
const BubbleScene = preload("res://scenes/effects/soap_bubble.tscn")
const BUILD_DURATION := 3.2
var part_origins: Array[Vector2] = []
var part_drop_sources: Array[Vector2] = []
var part_drop_ages: Array[float] = []
var build_grace := 0.0
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
	$HUD/TeamHUD.layout_changed.connect(_on_hud_layout_changed)
	$HUD/TeamHUD.bind(players)
	tutorial.begin()
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
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy in targets or enemy.dead: continue
		if player.ai_controlled and tutorial.step<7: continue
		var offset: Vector2=enemy.position-player.position
		if absf(offset.y)<(28 if player.equipped_weapon == "brush" else 22) and offset.x*player.facing>-12 and offset.x*player.facing<player.melee_reach():
			targets.append(enemy)
			var assisted: bool=players[0].attack_time>0 and players[1].attack_time>0 and players[0].position.distance_to(players[1].position)<100
			damage_enemy(player,enemy,player.melee_damage(combo)+(15 if assisted else 0),player.facing,enemy.global_position+Vector2(-player.facing*12,-24))
	if tutorial.step<4: return
	for prop in breakable_props():
		if prop.broken or prop in targets: continue
		var offset: Vector2=prop.position-player.position
		if absf(offset.y)<(28 if player.equipped_weapon == "brush" else 24) and offset.x*player.facing>-10 and offset.x*player.facing<player.melee_reach():
			targets.append(prop)
			prop.take_hit(player.melee_damage(combo),player.facing,player)
	for dummy in get_tree().get_nodes_in_group("training_dummies"):
		if not encounter.unlocked or dummy in targets: continue
		var offset: Vector2 = dummy.global_position-player.global_position
		if absf(offset.y)<28 and offset.x*player.facing>-12 and offset.x*player.facing<player.melee_reach():
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
func is_assembling(player) -> bool:
	return not built and build_grace>0 and player in active_builders
func interact(player, dt: float) -> void:
	for other in players:
		if other!=player and other.down and player.position.distance_to(other.position)<40:
			other.revive_progress+=dt
			if other.revive_progress>2:
				other.down=false
				other.hp=50
				other.invulnerable=2
				other.revive_progress=0
	if tutorial.step<6: return
	if player.ai_controlled: return
	if built or pieces<8 or player.position.distance_to(Vector2(540,250))>62: return
	var partner=players[1] if player==players[0] else players[0]
	if partner.position.distance_to(Vector2(540,250))<85 and not partner.down:
		active_builders=[player,partner] if partner.ai_controlled else [player]
		if not partner.ai_controlled and Input.is_action_pressed("p%d_interact"%partner.player_id):
			active_builders.append(partner)
		build_grace=0.2
		var rate=1.0 if active_builders.size()==2 else 0.65
		build_progress=minf(BUILD_DURATION,build_progress+dt*rate)
		$BuildSite.sample(build_progress/BUILD_DURATION)
		if build_progress>=BUILD_DURATION:
			built=true
			pieces-=8
			open_limit=1230
			$Bridge.visible=true
			$Gate.visible=false
			$Gate/Collision.set_deferred("disabled",true)
			spawn_wave()
func _process(dt: float) -> void:
	if not controls_locked: build_grace=maxf(0,build_grace-dt)
	if Input.is_action_just_pressed("controls") and not encounter.is_modal() and not elevator.is_transitioning():
		$HUD/ControlsPanel.visible=not $HUD/ControlsPanel.visible
		controls_locked=$HUD/ControlsPanel.visible or tutorial.step==0
	if Input.is_action_just_pressed("join") and not encounter.is_modal() and not elevator.is_transitioning():
		players[1].ai_controlled=not players[1].ai_controlled
	if Input.is_action_just_pressed("restart"): get_tree().reload_current_scene()
	var center: Vector2=(players[0].position+players[1].position)*0.5
	$Camera2D.position.x=clampf(center.x,320,camera_max_x)
	$BuildSite.update_camera(dt, center)
	update_camera_shake(dt)
	for player in players:
		player.position.x=clampf(player.position.x,$Camera2D.position.x-300,$Camera2D.position.x+300)
	if defeated>=6 and built and get_tree().get_nodes_in_group("germs").is_empty(): victory=true
	status.text=""
	if players[0].down and players[1].down: status.text="F2  ↻"
	$HUD/Pieces.text="%02d" % pieces
	$HUD/Pieces.visible=tutorial.step>=4
	$HUD/BoltIcon.visible=tutorial.step>=4
	$HUD/Goal.visible=tutorial.step>0 and not built
	if encounter.unlocked:
		$HUD/Goal.text=encounter.objective_text()
		$HUD/Goal.visible=not elevator.is_transitioning()

func _on_hud_layout_changed(two_players: bool) -> void:
	var radio: Control = $HUD/Communicator
	radio.position = Vector2(164, 108) if two_players else Vector2(272, 88)
	radio.size = Vector2(312, 76) if two_players else Vector2(352, 76)
	radio._layout()

func spawn_impact(kind: int, contact: Vector2, direction: float) -> Node2D:
	var burst = ImpactScene.instantiate()
	burst.kind = kind
	burst.facing = direction
	$ImpactEffects.add_child(burst)
	burst.global_position = contact
	return burst

func damage_enemy(player, enemy, amount: int, direction: float, contact: Vector2, gain_energy := true) -> void:
	if not is_instance_valid(enemy) or enemy.dead: return
	tutorial.record_action("germ",player)
	spawn_impact(1,contact,direction)
	enemy.take_hit(amount,direction)
	player.register_combo_hit()
	if gain_energy and not player.specials.active: player.energy = minf(100,player.energy+8)
	$Camera2D.offset = Vector2(3,-2)

func spawn_bubble(player) -> Node2D:
	var bubble = BubbleScene.instantiate()
	bubble.shooter = player
	bubble.direction = player.facing
	bubble.height = 28.0 + player.jump_height
	$Projectiles.add_child(bubble)
	bubble.global_position = player.global_position + Vector2(player.facing*34,0)
	return bubble

func damage_training(player, dummy, amount: int, direction: float, gain_energy := true) -> void:
	if not encounter.unlocked: return
	dummy.take_hit(amount,direction)
	spawn_impact(1,dummy.global_position+Vector2(-direction*12,-30),direction)
	player.register_combo_hit()
	if gain_energy and not player.specials.active: player.energy = minf(100,player.energy+8)

func special_area(player, center: Vector2, radius: float, depth: float, damage: int) -> void:
	for enemy in get_tree().get_nodes_in_group("germs"):
		if enemy.dead or (player.ai_controlled and tutorial.step < 7): continue
		var d: Vector2 = enemy.global_position-center
		if absf(d.x) <= radius and absf(d.y) <= depth:
			damage_enemy(player,enemy,damage,1 if d.x >= 0 else -1,enemy.global_position+Vector2(0,-24),false)
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
		$Camera2D.offset = Vector2(roundf(sin(shake_clock*103)*strength),roundf(cos(shake_clock*137)*strength*0.65))
		if shake_remaining <= 0:
			shake_strength = 0
			$Camera2D.offset = Vector2.ZERO
	else:
		$Camera2D.offset = $Camera2D.offset.lerp(Vector2.ZERO,minf(1,dt*20))

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
