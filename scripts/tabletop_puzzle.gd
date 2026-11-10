extends Node2D
## One building spot assembles the authored machine; a fresh lever pull powers it.
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const LAB = preload("res://scripts/lab_sprite_atlas.gd")
const BUILD_POINT := Vector2(2200,298)
const LEVER_POINT := Vector2(2300,278)
const BUILD_DURATION := 5.4
const PART_COUNT := 9
const STARTUP_DURATION := 2.2
const REACH := 48.0
const OFF_ANGLE := -0.65
const ON_ANGLE := 0.65
var started := false
var finished := false
var constructed := false
var activating := false
var build_progress := 0.0
var startup_age := 0.0
var gear_angle := 0.0
var light_levels := [0.0,0.0,0.0]
var used_parts := 0
var snapped_parts := 0
var grace := 0.0
var camera_blend := 0.0
var builder: Node2D
var parts: Array[Node2D] = []
var destinations: Array[Vector2] = []
var snap_ages: Array[float] = []
var loose_textures: Array[Texture2D] = []
var sources: Array[Vector2] = []
@onready var arena = get_parent()
@onready var machine: Node2D = $Machine
@onready var hint: Label = $Hint
@onready var marker: Sprite2D = $BuildMarker
@onready var lever: Node2D = $Machine/Lever/Pivot
@onready var lights: Array = [$Machine/Lights/Blue,$Machine/Lights/Yellow,$Machine/Lights/Green]

func _ready() -> void:
	LAB.apply($Machine/LeftHousing/Sprite,0,0,82)
	LAB.apply($Machine/RightHousing/Sprite,1,0,82)
	$Machine/LeftHousing/Sprite.position.y = -8
	$Machine/RightHousing/Sprite.position.y = -8
	LAB.apply($Machine/Console/Sprite,0,3,35)
	$Machine/Console.position = Vector2(-47,-33)
	$Machine/Console/Screen.hide()
	LAB.gear($Machine/GearLarge/Sprite,0,43)
	LAB.gear($Machine/GearSmall/Sprite,0,28)
	machine.modulate = Color("c5d6df")
	$Machine/Lights.position = Vector2(-44,-55)
	for i in 3:
		LAB.apply_control(lights[i],2,14)
		lights[i].position = Vector2((i-1)*12,0)
	$Machine/Lever.position = Vector2(65,-28)
	LAB.apply_control($Machine/Lever/Sprite,0,46)
	$Machine/Lever/Sprite.offset = Vector2(0,-65)
	lever.position = Vector2.ZERO
	LAB.apply_control($Machine/Lever/Pivot/Handle,1,43)
	$Machine/Lever/Pivot/Handle.offset = Vector2(0,-110)
	for part in machine.get_children():
		parts.append(part)
		destinations.append(part.position)
		snap_ages.append(10.0)
		var sprite: Sprite2D = part.get_node("Sprite") if part.has_node("Sprite") else part.get_child(0)
		loose_textures.append(sprite.texture)
		part.hide()
	hint.add_theme_font_override("font",FONT)
	hint.add_theme_font_size_override("font_size",8)
	hint.add_theme_color_override("font_outline_color",Color("102346"))
	hint.add_theme_constant_override("outline_size",3)
	hint.hide()
	_sync_machine()

func begin() -> void:
	if started: return
	started = true
	# Crates are authored in the level. Combat completion only starts the lesson.
	arena.encounter.start_puzzle_message()

func restore_running() -> void:
	started = true
	constructed = true
	finished = true
	build_progress = 1
	used_parts = PART_COUNT
	snapped_parts = PART_COUNT
	startup_age = STARTUP_DURATION
	light_levels = [1.0,1.0,1.0]
	sources.clear()
	for destination in destinations: sources.append(machine.to_global(destination))
	marker.hide()
	_sync_machine()

func needs_salvage() -> bool:
	return used_parts == 0 and arena.pieces < PART_COUNT

func is_building(player) -> bool:
	if grace <= 0 or constructed: return false
	return player == builder or (player.ai_controlled and player.position.distance_to(BUILD_POINT) < 90)

func interact(player, dt: float) -> void:
	if not started or constructed or arena.controls_locked or player.ai_controlled or player.down: return
	if player.jump_height > 0 or player.specials.active or player.stun > 0 or player.dash > 0: return
	if player.position.distance_to(BUILD_POINT) > REACH: return
	if grace > 0 and is_instance_valid(builder) and builder != player: return
	if used_parts == 0:
		if needs_salvage(): return
		arena.pieces -= PART_COUNT
		used_parts = PART_COUNT
		for i in PART_COUNT: sources.append(arena.part_origins[i])
	builder = player
	grace = 0.18
	build_progress = minf(1.0,build_progress+dt/BUILD_DURATION)
	var count := mini(PART_COUNT,int(build_progress*PART_COUNT+0.0001))
	for i in range(snapped_parts,count):
		snap_ages[i] = 0
		arena.start_camera_shake(1.4 if i < PART_COUNT-1 else 2.4,0.12)
	snapped_parts = count
	if build_progress >= 1:
		constructed = true
		grace = 0
	_sync_machine()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not constructed or activating or finished or arena.controls_locked: return
	for player in arena.players:
		if event.is_action_pressed("p%d_interact" % player.player_id) and pull_lever(player):
			get_viewport().set_input_as_handled()
			return

func pull_lever(player) -> bool:
	if not constructed or activating or finished or arena.controls_locked: return false
	if player.ai_controlled or player.down or player.jump_height > 0 or player.specials.active or player.stun > 0: return false
	if player.position.distance_to(LEVER_POINT) > REACH: return false
	activating = true
	startup_age = 0
	return true

func _process(dt: float) -> void:
	if arena.controls_locked:
		hint.hide()
		return
	grace = maxf(0,grace-dt)
	for i in PART_COUNT: snap_ages[i] += dt
	if activating or finished:
		startup_age += dt
		var ramp := smoothstep(0.55,1.8,startup_age)
		gear_angle = fposmod(gear_angle+dt*2.2*ramp,TAU)
		for i in 3:
			light_levels[i] = smoothstep(0.65+i*0.3,0.9+i*0.3,startup_age)
		if activating and startup_age >= STARTUP_DURATION:
			activating = false
			finished = true
			arena.start_camera_shake(2,0.18)
	_update_hint()
	_sync_machine()
	queue_redraw()

func _update_hint() -> void:
	hint.hide()
	if not started: return
	var action_point := LEVER_POINT if constructed else BUILD_POINT
	marker.position = action_point
	marker.visible = started and not finished and not activating
	marker.modulate.a = 0.65

func _sync_machine() -> void:
	for i in PART_COUNT:
		var part := parts[i]
		var travel := clampf(build_progress*PART_COUNT-i,0,1)
		part.visible = travel > 0
		if not part.visible: continue
		var flight := smoothstep(0,0.88,travel)
		var origin := machine.to_local(sources[i])
		part.position = origin.lerp(destinations[i]+Vector2(0,-7),flight)
		part.position.y += -sin(flight*PI)*35 + smoothstep(0.88,1,travel)*7
		part.scale = Vector2.ONE*lerpf(0.28,1,smoothstep(0,0.85,travel))
		part.rotation = sin(flight*PI)*(0.3 if i%2==0 else -0.3)
		if travel >= 1:
			var age := snap_ages[i]
			part.position.y -= sin(age*23)*3*exp(-age*12)
	LAB.gear($Machine/GearLarge/Sprite,gear_angle,43)
	LAB.gear($Machine/GearSmall/Sprite,-gear_angle*1.65,28)
	$Machine/Console/Sprite.texture = LAB.cell(int(startup_age*7)%4,3)
	lever.rotation = lerpf(OFF_ANGLE,ON_ANGLE,smoothstep(0,0.55,startup_age))
	$Machine/Console/Sprite.modulate = Color("607e8c").lerp(Color.WHITE,smoothstep(0.6,1.2,startup_age))
	for i in 3:
		lights[i].modulate = Color(0.28,0.34,0.4).lerp(Color.WHITE,light_levels[i])

func update_camera(dt: float) -> void:
	if arena.controls_locked: return
	var target := 1.0 if grace > 0 or activating else 0.0
	camera_blend = move_toward(camera_blend,target,dt*1.8)
	var weight := smoothstep(0,1,camera_blend)
	var camera: Camera2D = arena.get_node("Camera2D")
	camera.position.y = lerpf(180,194,weight)
	camera.position.x = lerpf(camera.position.x,2080,weight*0.8)
	camera.zoom = Vector2.ONE*lerpf(1,1.06,weight)

func _draw() -> void:
	# Salvage is visible even if a crate was broken before combat ended.
	for i in arena.part_origins.size():
		if used_parts > 0 and build_progress*PART_COUNT > i: continue
		var texture := loose_textures[i%PART_COUNT]
		var size := texture.get_size()*(18.0/maxf(texture.get_width(),texture.get_height()))
		draw_texture_rect(texture,Rect2(arena.part_origins[i]-size*0.5,size),false)
	for i in PART_COUNT:
		var age := snap_ages[i]
		if age >= 0.45: continue
		var at := machine.position+destinations[i]
		for spark in 6:
			var point := at+Vector2.from_angle(spark*TAU/6)*age*48
			draw_rect(Rect2(point,Vector2(2,2)),Color(0.65,1,0.87,1-age/0.45))
	for i in 3:
		if light_levels[i] <= 0: continue
		var at := to_local(lights[i].global_position)
		for radius in [3.0,5.0]:
			draw_circle(at,radius,Color(0.5,1,0.8,0.035*light_levels[i]))
