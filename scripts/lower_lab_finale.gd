extends Node2D
## Post-terminal progression, shared soap item and sealed shield-boss encounter.
enum State { LOCKED, READY, CLEANING, OPEN, RUMBLE, INTRO, FIGHT, DONE }
const Boss = preload("res://scripts/shield_germ.gd")
const TNT = preload("res://scripts/falling_tnt.gd")
const BossHUD = preload("res://scripts/shield_boss_hud.gd")
const Prompt = preload("res://scripts/interaction_prompt.gd")
const SOAP = preload("res://assets/environment/lower_lab/soap_pickup.png")
const SLIME = preload("res://assets/environment/lower_lab/slime_block.png")
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const SOAP_LINE := "Não podemos passar por aqui. Rápido, deve ter um sabonete por algum lugar!"
const SLIME_AT := Vector2(3440,270)
const LEFT := 3940.0
const RIGHT := 4740.0
const CENTER := (LEFT+RIGHT)*0.5
const CAMERA_ZOOM := 0.78
const CLEAN_TIME := 3.0
var state := State.LOCKED
var age := 0.0
var clock := 0.0
var has_soap := false
var soap_taken := false
var soap_search_started := false
var locker_at := Vector2.ZERO
var cleaned := false
var locker: Sprite2D
var locker_material: ShaderMaterial
var prompt: Control
var slime_wall: StaticBody2D
var mixed_wall: StaticBody2D
var left_barrier: StaticBody2D
var right_barrier: StaticBody2D
var boss: Node2D
var boss_hud: Control
var pickup_feedback := 0.0
var impacts := 0
var tnt_drops := 0
var rng := RandomNumberGenerator.new()
@onready var arena = get_parent()

func _ready() -> void:
	z_index = -3
	rng.randomize()
	# Continue the background above and below the usual viewport for the wider shot.
	for index in [3,4]:
		for kind in ["Wall","Floor"]:
			var extra = arena.get_node("Environment/%s%d" % [kind,index]).duplicate()
			extra.position.y += -188 if kind == "Wall" else 172
			arena.get_node("Environment").add_child(extra)
	var candidates: Array[Sprite2D] = []
	for existing in arena.corridor.lockers:
		if existing.position.x == 2910: candidates.append(existing)
	for x in [3060,3180]: candidates.append(arena.corridor.prop("locker",Vector2(x,190),Vector2(104,136)))
	locker = candidates[rng.randi_range(0,candidates.size()-1)]
	locker_at = Vector2(locker.position.x,190)
	locker_material = ShaderMaterial.new()
	locker_material.shader = preload("res://assets/environment/lower_lab/locker_outline.gdshader")
	prompt = Prompt.new()
	prompt.hide()
	add_child(prompt)
	slime_wall = wall("SlimeBarrier",SLIME_AT.x,180)
	mixed_wall = wall("MixedWaveBarrier",3155)
	left_barrier = wall("BossWest",LEFT)
	right_barrier = wall("BossEast",RIGHT)
	set_wall(left_barrier,false)
	set_wall(right_barrier,false)
	boss_hud = BossHUD.new()
	arena.get_node("HUD").add_child(boss_hud)
	for x in [3630,3820,4710]:
		arena.corridor.prop("sign",Vector2(x,76),Vector2(27,29))
	for x in [3690,4790]:
		arena.corridor.prop("locker",Vector2(x,185),Vector2(104,136))

func wall(label: String, x: float, width := 18.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.position = Vector2(x,260)
	# Layer 5 stops players and flyers, while attack rays use the world layer.
	body.collision_layer = 16
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width,220)
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)
	return body

func set_wall(body: StaticBody2D, enabled: bool) -> void:
	body.set_deferred("collision_layer",16 if enabled else 0)
	body.get_child(0).set_deferred("disabled",not enabled)

func is_modal() -> bool:
	return state in [State.CLEANING,State.RUMBLE,State.INTRO]

func camera_locked() -> bool:
	return state in [State.RUMBLE,State.INTRO,State.FIGHT]

func can_take_soap(player) -> bool:
	return state == State.READY and soap_search_started and not soap_taken and not player.down and not player.ai_controlled and player.position.distance_to(locker_at+Vector2(0,52)) < 67

func can_clean(player) -> bool:
	return state == State.READY and not player.down and not player.ai_controlled and player.position.distance_to(Vector2(3325,270)) < 75

func interact(player) -> bool:
	if arena.controls_locked: return false
	if can_take_soap(player):
		has_soap = true
		soap_taken = true
		pickup_feedback = 2.2
		locker.material = null
		return true
	if can_clean(player) and has_soap:
		state = State.CLEANING
		age = 0
		has_soap = false
		arena.controls_locked = true
		_stop_players()
		prompt.hide()
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	for player in arena.players:
		if player.ai_controlled or not GameInput.event_for(event, player.player_id, "interact"): continue
		if state == State.INTRO and age > 0.4:
			start_fight()
			get_viewport().set_input_as_handled()
		elif interact(player): get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if arena.get_node("HUD/ControlsPanel").visible: return
	if arena.players[0].down and arena.players[1].down: return
	clock += dt
	age += dt
	pickup_feedback = maxf(0,pickup_feedback-dt)
	if state == State.LOCKED and arena.beat == arena.Beat.FINISHED:
		state = State.READY
		set_wall(mixed_wall,false)
		arena.open_limit = 3340
	if state == State.READY:
		if not soap_search_started:
			for player in arena.players:
				if not player.down and not player.ai_controlled and player.position.x >= 3240:
					soap_search_started = true
					locker.material = locker_material
					arena.journey_radio.say("soap","DRA. AMANDA",SOAP_LINE)
					break
		locker_material.set_shader_parameter("pulse",0.75+0.25*sin(clock*4))
	elif state == State.CLEANING and age >= CLEAN_TIME:
		cleaned = true
		state = State.OPEN
		set_wall(slime_wall,false)
		arena.open_limit = arena.world_limit-20
		arena.controls_locked = false
	elif state == State.OPEN:
		for player in arena.players:
			if not player.down and not player.ai_controlled and player.position.x >= LEFT+100:
				begin_boss()
				break
	elif state == State.RUMBLE:
		for i in arena.players.size():
			var player = arena.players[i]
			player.position.x = lerpf(player.position.x,LEFT+145+i*52,minf(1,dt*5))
		if age >= 1.15:
			boss.show()
			boss_hud.show()
			boss_hud.intro = true
			state = State.INTRO
			age = 0
	elif state == State.INTRO and age >= 2.6:
		start_fight()
	elif state == State.FIGHT:
		for player in arena.players:
			player.position.x = clampf(player.position.x,LEFT+22,RIGHT-22)
	_update_prompt()
	queue_redraw()

func _update_prompt() -> void:
	prompt.hide()
	if state != State.READY or arena.controls_locked: return
	for player in arena.players:
		if can_take_soap(player):
			prompt.position = locker_at+Vector2(-58,-15)
			prompt.action_text = "PEGAR SABÃO"
		elif can_clean(player):
			prompt.position = SLIME_AT+Vector2(-158,-118)
			prompt.action_text = "LIMPAR" if has_soap else "BUSQUE SABÃO"
		else: continue
		prompt.set_player(player.player_id)
		prompt.show()
		return

func _stop_players() -> void:
	for player in arena.players:
		player.velocity = Vector2.ZERO
		player.attack_time = 0
		player.buffered = false
		player.dash = 0
		player.jump_height = 0
		player.jump_speed = 0
		player.specials.cancel()
		player.dash_visual.clear()
		player.get_node("Visual").rotation = 0
		player.get_node("Visual").position = Vector2.ZERO
		player.update_sprite_alignment()
	for shot in arena.get_node("Projectiles").get_children(): shot.queue_free()

func begin_boss() -> void:
	if state != State.OPEN or not cleaned: return
	state = State.RUMBLE
	age = 0
	arena.victory = false
	arena.controls_locked = true
	arena.open_limit = RIGHT-22
	arena.amanda_hint.hide()
	arena.journey_radio.hide()
	_stop_players()
	# Pull a lagging/downed partner into the sealed arena before activating walls.
	for i in arena.players.size():
		arena.players[i].position.x = clampf(arena.players[i].position.x,LEFT+60,RIGHT-180)
	set_wall(left_barrier,true)
	set_wall(right_barrier,true)
	arena.start_camera_shake(4,1.1)
	boss = Boss.new()
	boss.name = "ShieldGuardian"
	boss.position = Vector2(RIGHT-100,280)
	boss.left_wall = LEFT
	boss.right_wall = RIGHT
	arena.get_node("Actors").add_child(boss)
	boss.wall_slam.connect(drop_tnt)
	boss.defeated.connect(finish_boss)
	boss.hide()
	boss_hud.boss = boss
	arena.get_node("HUD/TeamHUD").position.y = 48

func start_fight() -> void:
	if state != State.INTRO: return
	state = State.FIGHT
	age = 0
	boss_hud.intro = false
	arena.controls_locked = false
	boss.start_fight()

func drop_tnt() -> void:
	if state != State.FIGHT: return
	impacts += 1
	# Only one out of four wall charges calls in the TNT barrage.
	if rng.randf() >= 0.25: return
	tnt_drops += 1
	# Three disjoint horizontal zones guarantee spread while keeping each drop random.
	var zones: Array[int] = [0,1,2]
	zones.shuffle()
	for zone in zones:
		var crate := TNT.new()
		var zone_width := (RIGHT-LEFT-110)/3.0
		crate.position = Vector2(rng.randf_range(LEFT+55+zone*zone_width,LEFT+55+(zone+1)*zone_width-12),rng.randf_range(213,317))
		crate.target_boss = boss
		arena.add_child(crate)

func finish_boss() -> void:
	if state != State.FIGHT: return
	state = State.DONE
	age = 0
	arena.victory = true
	arena.open_limit = arena.world_limit-20
	set_wall(left_barrier,false)
	set_wall(right_barrier,false)
	for crate in get_tree().get_nodes_in_group("boss_tnt"): crate.queue_free()
	boss_hud.hide()
	arena.get_node("HUD/TeamHUD").position.y = 0

func ai_destination(player, ordinary: Vector2) -> Vector2:
	if state != State.FIGHT or not is_instance_valid(boss): return ordinary
	if boss.state in [boss.State.WINDUP,boss.State.CHARGE] and absf(player.position.y-boss.position.y) < 45:
		return Vector2(player.position.x,320 if boss.position.y < 265 else 200)
	for crate in get_tree().get_nodes_in_group("boss_tnt"):
		if not crate.broken and ((player.position-crate.position)/Vector2(85,50)).length_squared() < 1:
			return Vector2(clampf(player.position.x+signf(player.position.x-crate.position.x)*60,LEFT+30,RIGHT-30),200 if crate.position.y > 260 else 322)
	return ordinary

func _bubble(at: Vector2, radius: float, alpha: float) -> void:
	var r := snappedf(radius,2)
	draw_circle(at,r,Color(0.72,0.96,1,alpha),true,-1,false)
	draw_arc(at,r,0,TAU,12,Color(0.98,1,1,alpha),1,false)
	draw_rect(Rect2(at+Vector2(-r*0.5,-r*0.5),Vector2(3,2)),Color(1,1,1,alpha))

func _draw() -> void:
	if not cleaned:
		var progress := clampf(age/CLEAN_TIME,0,1) if state == State.CLEANING else 0.0
		var alpha := 1-smoothstep(0.35,0.95,progress)
		draw_texture_rect(SLIME,Rect2(SLIME_AT+Vector2(-148,-144),Vector2(296,230)),false,Color(1,1,1,alpha))
		if state == State.CLEANING:
			var foam_alpha := 1-smoothstep(0.85,1,progress)
			for i in 100:
				var angle := i*2.39996
				var spread := sqrt(float(i)/100)*minf(1,progress*2.3)
				var at := SLIME_AT+Vector2(cos(angle)*132,sin(angle)*84)*spread
				var radius := 4+fposmod(sin(i*17.3)*81,7)
				_bubble(at+Vector2(2*sin(clock*5+i),2*cos(i*3.2)),radius,foam_alpha)
				_bubble(at+Vector2(5,-5),radius*0.55,foam_alpha)
			for i in 22:
				var t := fmod(age*0.7+i*0.13,1.0)
				_bubble(SLIME_AT+Vector2(sin(i*4.3)*100,-t*150),3+i%5,(1-t)*foam_alpha)
			draw_texture_rect(SOAP,Rect2(SLIME_AT+Vector2(sin(age*16)*70-20,-35),Vector2(40,34)),false)
	if has_soap or pickup_feedback > 0:
		var carrier: Vector2 = arena.players[0].position
		draw_texture_rect(SOAP,Rect2(carrier+Vector2(-14,-90),Vector2(28,24)),false)
		if pickup_feedback > 0: draw_string(FONT,carrier+Vector2(-28,-98),"+ SABÃO",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("f6f7c1"))
	# Floor stripes and pillars make the sealed arena's edges legible without an overlay wall.
	for x in [LEFT,RIGHT]:
		draw_rect(Rect2(x-9,188,18,153),Color("253b3b"))
		for y in range(191,338,12): draw_rect(Rect2(x-7,y,14,5),Color("9b9951"))
		draw_rect(Rect2(x-13,36,26,151),Color("1e373c"))
		draw_rect(Rect2(x-9,39,4,145),Color("62857c"))
		var lamp := Color("ec9251") if camera_locked() else Color("7cd8a4")
		draw_rect(Rect2(x-5,166,10,12),lamp)
