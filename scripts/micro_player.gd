extends CharacterBody2D

@export var player_id := 0
@export var ai_controlled := false
@export var tint := Color("80eaff")
@export_range(1, 1000) var max_hp := 100
@export_range(0, 99) var healing_flasks := 5
@export_range(1, 1000) var flask_heal_amount := 25
var equipped_weapon := "none"
var weapon_upgraded := false
var burst_round := 0
var finisher_pending := false
const PixelVisual = preload("res://scripts/pixel_avatar_visual.gd")
const BrushMotion = preload("res://scripts/brush_motion.gd")
const SpecialAbility = preload("res://scripts/special_ability.gd")
const DashVisual = preload("res://scripts/dash_visual.gd")
const BRUSH_COMBO := ["brush_attack","brush_rise","brush_slam"]
var pixel_visual: Node2D
var specials: Node2D
var dash_visual: Node2D
var airborne_attack := false
var chain_grace := 0.0
const BUBBLE_INTERVAL := 0.28
const OVERCHARGE_INTERVAL := 0.17
const BRUSH_UPGRADE_COLOR := Color("ffb450")
const BUBBLE_UPGRADE_COLOR := Color("e7a2ff")
var bubble_cooldown := 0.0
var hp := 100
var facing := 1.0
var attack_time := 0.0
var attack_duration := 0.0
var combo := 0
const HIT_COMBO_TIMEOUT := 5.0
var hit_combo := 0
var combo_idle_time := 0.0
var buffered := false
var hit_targets: Array = []
var invulnerable := 0.0
var stun := 0.0
var push_velocity := Vector2.ZERO
var jump_height := 0.0
var jump_speed := 0.0
var dash := 0.0
var down := false
var revive_progress := 0.0
var energy := 100.0
var ai_clock := 0.0
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var arena = get_tree().get_first_node_in_group("arena")

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hp = max_hp
	dash_visual = DashVisual.new()
	dash_visual.name = "DashTrail"
	add_child(dash_visual)
	move_child(dash_visual,0)
	specials = SpecialAbility.new()
	specials.name = "SpecialAbility"
	add_child(specials)
	specials.setup(self)
	sprite.frame_changed.connect(update_sprite_alignment)
	sprite.animation_changed.connect(update_sprite_alignment)
	pixel_visual = PixelVisual.new()
	pixel_visual.name = "PixelEquipment"
	$Visual.add_child(pixel_visual)
	pixel_visual.setup(self,sprite)
	refresh_player_marker()

func _physics_process(dt: float) -> void:
	invulnerable = maxf(0, invulnerable-dt)
	stun = maxf(0, stun-dt)
	ai_clock += dt
	if down:
		if sprite.animation != &"death": _play_death()
		return
	if arena.controls_locked:
		velocity=Vector2.ZERO
		return
	update_hit_combo(dt)
	if attack_time <= 0:
		chain_grace = maxf(0,chain_grace-dt)
	bubble_cooldown = maxf(0,bubble_cooldown-dt)
	var prefix := "p%d_" % player_id
	var direction := Input.get_vector(prefix+"left",prefix+"right",prefix+"up",prefix+"down")
	var attack := Input.is_action_pressed(prefix+"attack") if equipped_weapon == "bubbles" else Input.is_action_just_pressed(prefix+"attack")
	var attack_held := Input.is_action_pressed(prefix+"attack")
	var jump := Input.is_action_just_pressed(prefix+"jump")
	var dodge := Input.is_action_just_pressed(prefix+"dodge")
	var interact := Input.is_action_pressed(prefix+"interact")
	var heal := Input.is_action_just_pressed(prefix+"heal")
	var special := Input.is_action_just_pressed(prefix+"special")
	if ai_controlled:
		special = false
		heal = hp <= maxi(1, int(max_hp * 0.35))
		attack=false
		jump=false
		dodge=false
		var target = arena.nearest_enemy(position)
		if arena.tutorial.step<7: target=null
		var destination: Vector2 = arena.players[0].position + Vector2(-30,20)
		if target != null:
			var distance := 210.0 if equipped_weapon == "bubbles" else (melee_reach() * 0.64 if equipped_weapon == "brush" else 28.0)
			destination = target.position - Vector2(distance * signf(target.position.x-position.x),0)
			if attack_time <= 0: facing = 1.0 if target.position.x >= position.x else -1.0
			var reach := 520.0 if equipped_weapon == "bubbles" else melee_reach() - 5.0
			attack = absf(target.position.x-position.x)<reach and absf(target.position.y-position.y)<18 and arena.tutorial.step>=7
			if target.has_method("requires_air_attack") and target.requires_air_attack():
				jump = attack and jump_height <= 0 and stun <= 0
				attack = attack and jump_height >= 18
			if arena.has_method("ai_combat_destination"):
				destination = arena.ai_combat_destination(self, target, destination)
		var offset := destination-position
		direction = offset.normalized() if offset.length()>12 else Vector2.ZERO
		var boarding = arena.elevator.ai_boarding_destination(self)
		if arena.has_method("ai_puzzle_destination"):
			var puzzle_destination = arena.ai_puzzle_destination(self)
			if puzzle_destination != null: boarding = puzzle_destination
		if boarding != null and target == null:
			var to_plate: Vector2 = boarding-global_position
			direction = to_plate.normalized() if to_plate.length()>3 else Vector2.ZERO
			attack = false
		interact = true
		if arena.players[0].down:
			direction = (arena.players[0].position-position).normalized() if position.distance_to(arena.players[0].position)>26 else Vector2.ZERO
			attack = false
		if arena.has_method("obstacle_ahead") and jump_height <= 0 and arena.obstacle_ahead(self, direction):
			jump = true
		attack_held = attack
	if heal: use_healing_flask()
	if special: specials.try_activate()
	if specials.active:
		attack = false
		attack_held = false
		jump = false
		dodge = false
	if interact:
		arena.interact(self,dt)
	else:
		arena.stop_assembling(self)
	if arena.is_assembling(self):
		jump = false
		dodge = false
	if equipped_weapon == "brush" and attack_time <= 0 and attack_held: attack = true
	if attack and stun<=0 and not arena.is_assembling(self):
		if equipped_weapon == "bubbles":
			if bubble_cooldown <= 0: start_attack()
		elif attack_time>0:
			buffered = true
		else:
			start_attack()
	if jump and jump_height<=0 and stun<=0:
		arena.tutorial.record_action("jump", self)
		GameAudio.effect("jump", global_position)
		jump_speed = 235
	if dodge and dash<=0:
		arena.tutorial.record_action("dodge", self)
		GameAudio.effect("dodge", global_position)
		dash = 0.24

		invulnerable = 0.3
	if not specials.active: energy = minf(100,energy+dt*5)
	jump_height += jump_speed*dt
	jump_speed -= 650*dt
	if jump_height<0:
		jump_height=0
		jump_speed=0
	if specials.locks_aim():
		facing = specials.cast_facing
	elif absf(direction.x)>0.1 and attack_time<=0:
		facing = signf(direction.x)
	var speed := 145.0
	if Input.is_action_pressed(prefix+"run"): speed=185
	if dash>0:
		dash-=dt
		direction=Vector2(facing,0)
		speed=300
	if attack_time>0: speed*=0.25
	if specials.active: speed = 76.0
	if specials.locks_aim(): speed = 0
	if stun>0: speed=0
	if arena.is_assembling(self): speed=0
	velocity = direction * Vector2(speed,speed*0.66)
	var remaining_push := push_velocity.move_toward(Vector2.ZERO,1100*dt)
	velocity += (push_velocity+remaining_push)*0.5
	push_velocity = remaining_push
	if equipped_weapon == "brush" and attack_time > 0 and stun <= 0 and dash <= 0 and not arena.is_assembling(self):
		velocity.x += brush_step_velocity(dt)*facing
	set_collision_mask_value(4,jump_height<20)
	if arena.has_method("update_jump_collision"): arena.update_jump_collision(self)
	move_and_slide()
	var pushing := false
	for index in get_slide_collision_count():
		var body=get_slide_collision(index).get_collider()
		if body is RigidBody2D and not body.freeze:
			body.apply_central_force(direction*450)
			pushing=direction.length()>0.1
	if velocity.length()>5: arena.tutorial.record_action("move", self)
	position.x=clampf(position.x,20,arena.open_limit)
	position.y=clampf(position.y,190,326)
	specials.tick(dt)
	if attack_time>0:
		attack_time-=dt
		if equipped_weapon != "bubbles" and attack_contact_active():
			if finisher_pending:
				finisher_pending = false
				var flash: Node2D = arena.spawn_impact(1, global_position + Vector2(facing * 42, -26), facing)
				flash.scale = Vector2(3.2, 1.45)
				flash.modulate = BRUSH_UPGRADE_COLOR
				arena.start_camera_shake(4, 0.22)
			arena.strike(self,combo,hit_targets)
		var continue_brush := equipped_weapon == "brush" and attack_held
		if attack_time<=0 and (buffered or continue_brush) and stun <= 0 and not arena.controls_locked and not arena.is_assembling(self):
			buffered=false
			start_attack()
	var animation := "idle"
	if velocity.length()>5: animation="run"
	if pushing: animation="push"
	if jump_height>0: animation="jump"
	if attack_time>0: animation="heavy" if combo==3 else "attack"
	if stun>0: animation="hurt"
	if arena.is_assembling(self):
		animation="build"
		var build_direction: float = arena.assembly_facing(self)
		if build_direction != 0: facing = build_direction
	if equipped_weapon != "none" and animation not in ["build","hurt","death"]:
		if specials.active:
			animation = specials.animation_name()
		elif equipped_weapon == "brush" and attack_time > 0:
			animation = brush_animation()
		else:
			var state := "attack" if animation in ["attack","heavy"] else ("jump" if animation == "jump" else ("run" if animation in ["run","push"] else "idle"))
			animation = equipped_weapon + "_" + state
	sprite.play(animation)
	if specials.active and animation == specials.animation_name():
		sprite.pause()
		sprite.frame = specials.animation_frame(sprite.sprite_frames.get_frame_count(animation))
		sprite.speed_scale = 1.0
	elif attack_time > 0 and (animation.begins_with("brush_") or animation == "bubbles_attack"):
		var count := sprite.sprite_frames.get_frame_count(animation)
		# Attack art follows the combat clock, including hit pause and menu pause.
		sprite.pause()
		sprite.frame = clampi(int((1.0-attack_time/attack_duration)*count),0,count-1)
		sprite.speed_scale = 1.0
	else: sprite.speed_scale = 1.4 if dash > 0 else 1.0
	sprite.flip_h=facing<0
	update_sprite_alignment()
	var dashing: bool = dash > 0 and velocity.length() > 40 and stun <= 0 and not specials.active and not arena.is_assembling(self)
	var lean := sin(clampf(dash/0.24,0,1)*PI) if dashing else 0.0
	$Visual.rotation = facing*lean*0.12
	$Visual.position = Vector2(roundf(facing*lean*2),-jump_height+roundf(lean*2))
	dash_visual.tick(dt,self,dashing)
	modulate.a=0.5 if invulnerable>0 and int(ai_clock*20)%2==0 else 1.0


func start_attack() -> void:
	GameAudio.effect("bubble" if equipped_weapon == "bubbles" else "brush", global_position)
	combo_idle_time = 0.0
	arena.tutorial.record_action("attack", self)
	if equipped_weapon == "brush" and chain_grace <= 0: combo = 0
	combo=combo%3+1
	attack_duration=0.43 if combo<3 else 0.55
	airborne_attack = equipped_weapon == "brush" and jump_height > 0
	if equipped_weapon == "brush":
		attack_duration = float(BrushMotion.DURATION[brush_animation()])
	if weapon_upgraded and equipped_weapon == "brush":
		attack_duration *= 0.82
	finisher_pending = weapon_upgraded and equipped_weapon == "brush" and combo == 3
	chain_grace = 0.42
	attack_time=attack_duration
	hit_targets.clear()
	sprite.stop()
	if equipped_weapon == "bubbles":
		attack_duration = OVERCHARGE_INTERVAL if weapon_upgraded else BUBBLE_INTERVAL
		attack_time = attack_duration
		bubble_cooldown = attack_duration
		buffered = false
		if weapon_upgraded:
			burst_round = (burst_round + 1) % 3
		arena.spawn_bubble(self, weapon_upgraded, weapon_upgraded and burst_round == 0)

func attack_contact_active() -> bool:
	var progress := 1.0-attack_time/maxf(attack_duration,0.01)
	if equipped_weapon == "brush":
		return BrushMotion.contact_active(brush_animation(),progress)
	return progress > 0.35 and progress < 0.85

func brush_animation() -> String:
	return "brush_air" if airborne_attack else BRUSH_COMBO[clampi(combo-1,0,2)]

func brush_step_velocity(dt: float) -> float:
	if dt <= 0: return 0
	var animation := brush_animation()
	var before := 1.0-attack_time/attack_duration
	var after := 1.0-maxf(0,attack_time-dt)/attack_duration
	# Integrate the step through CharacterBody2D so walls, crates and the gap block it.
	return (BrushMotion.displacement(animation,after)-BrushMotion.displacement(animation,before))/dt

func take_hit(amount: int, source: Vector2, hits_airborne := false) -> void:
	if amount <= 0 or invulnerable>0 or down or (jump_height>30 and not hits_airborne): return
	reset_hit_combo()
	GameAudio.effect("hurt", global_position)
	hp=maxi(0,hp-amount)
	invulnerable=0.8
	stun=0.25
	if specials.active: stun = 0
	if equipped_weapon == "brush":
		attack_time = 0
		buffered = false
		chain_grace = 0
	move_and_collide(Vector2(signf(position.x-source.x)*12,0))
	if hp==0:
		down = true
		_play_death()

func _play_death() -> void:
	arena.stop_assembling(self)
	specials.cancel()
	dash = 0
	attack_time = 0
	chain_grace = 0
	buffered = false
	jump_height = 0
	jump_speed = 0
	velocity = Vector2.ZERO
	push_velocity = Vector2.ZERO
	dash_visual.clear()
	$Visual.rotation = 0
	$Visual.position = Vector2.ZERO
	modulate.a = 1.0
	sprite.speed_scale = 1.0
	sprite.play("death")

func can_assemble() -> bool:
	return not down and jump_height <= 0 and dash <= 0 and stun <= 0 and attack_time <= 0 and not specials.active

func refresh_player_marker() -> void:
	$PlayerMarker.visible = arena.show_player_ids()
	$PlayerMarker.text = "IA" if ai_controlled else "P%d" % (player_id + 1)

func receive_shield_push(amount: int, source: Vector2, push_direction: float) -> void:
	if invulnerable > 0 or down or jump_height > 30: return
	take_hit(amount,source)
	if down: return
	push_velocity = Vector2(push_direction*440,0)
	stun = maxf(stun,0.4)
	dash = 0

func use_healing_flask() -> bool:
	if arena.controls_locked or down or hp <= 0 or hp >= max_hp or healing_flasks <= 0:
		return false
	GameAudio.effect("jar", global_position)
	healing_flasks -= 1
	hp = mini(max_hp, hp + flask_heal_amount)
	return true

func register_combo_hit() -> void:
	hit_combo += 1
	combo_idle_time = 0.0

func reset_hit_combo() -> void:
	hit_combo = 0
	combo_idle_time = 0.0

func update_hit_combo(dt: float) -> void:
	if arena.controls_locked or hit_combo == 0: return
	combo_idle_time += dt
	if combo_idle_time > HIT_COMBO_TIMEOUT: reset_hit_combo()

func equip_weapon(choice: String) -> bool:
	if choice not in ["brush","bubbles"]: return false
	if is_instance_valid(specials): specials.cancel()
	equipped_weapon = choice
	burst_round = 0
	finisher_pending = false
	combo = 0
	chain_grace = 0
	airborne_attack = false
	attack_time = 0
	buffered = false
	bubble_cooldown = 0
	sprite.play(choice + "_idle")
	sprite.speed_scale = 1.0
	update_sprite_alignment()
	return true

func melee_reach() -> float:
	if equipped_weapon != "brush": return 65.0
	if weapon_upgraded: return 188.0 if combo == 3 else 150.0
	return 112.0

func melee_damage(combo_index: int) -> int:
	if equipped_weapon == "brush":
		if weapon_upgraded: return 102 if combo_index == 3 else 62
		return 40 if combo_index == 3 else 28
	return 28 if combo_index == 3 else 18

func update_sprite_alignment() -> void:
	if not is_instance_valid(sprite): return
	# The wake cutscene owns this transform until it hands control to the tutorial.
	if is_instance_valid(arena) and is_instance_valid(arena.tutorial) and arena.tutorial.step == 0: return
	sprite.scale = Vector2(2,2)
	sprite.position = Vector2(0,-30)
	if is_instance_valid(pixel_visual): pixel_visual.sync()
