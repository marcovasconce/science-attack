extends Node2D
## Build, connect water, explore and protect the cleaning machine.
## Explicit IDs preserve checkpoints made before the simpler route.
enum Step { DORMANT=0, POWER=1, PIPES=2, DRAIN=3, STEAM=4, EXPLORE=6, DEFENSE=8, PURIFY=9, SAMPLE=10, EXIT=11, COMPLETE=12 }
const CHECKPOINT_META := "tabletop_checkpoint"
const RETRY_META := "tabletop_retry"
const VALVE_POINTS := [Vector2(2780,292),Vector2(2880,292),Vector2(2980,292)]
const PIPE_POINTS := [Vector2(2780,140),Vector2(2780,210),Vector2(2880,210),Vector2(2980,210),Vector2(2980,140)]
const BASE_PORTS := [[2,1],[3,0],[2,0],[2,3],[1,0]]
const PIPE_CONTROLS := [-1,0,1,2,-1]
const FLOW_ENTRIES := [2,3,2,2,1]
const FLOW_EXITS := [1,0,0,3,0]
const DIRECTIONS := [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]
const PIPE_RADIUS := 35.0
const WATER_SPEED := 85.0
const VENTS := [3540.0,3740.0,3970.0]
const BATTERY_POINTS := [Vector2(3390,293),Vector2(4650,293)]
const SUPPLY_POINTS := [Vector2(3430,216),Vector2(4930,299)]
const RECORD_POINTS := [Vector2(2580,222),Vector2(4160,220),Vector2(6590,242)]
const CONSOLE_POINT := Vector2(5400,290)
const SAMPLE_POINT := Vector2(5600,290)
const EXIT_POINT := Vector2(6900,293)
const WAVE_CHARGE := 10.0
const FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const WATER_SHADER = preload("res://assets/environment/machines/puzzle_tube.gdshader")
const TUBE_SHEET = preload("res://assets/environment/tabletop_props.png")
const STEAM_SHADER = preload("res://assets/environment/machines/steam.gdshader")
const LAB = preload("res://scripts/lab_sprite_atlas.gd")
const COLLECTION_DURATION := 3.0
const CLEAN_DURATION := 3.2
const PUMP_POINT := Vector2(3062,296)
var step := Step.DORMANT
var powered := false
var complete := false
var opening_age := 0.0
var drain_age := 0.0
var drained := false
var valves := [1,1,3]
var valve_angles := [PI*0.5,PI*0.5,PI*1.5]
# Alternating links and pipe interiors: source, pipe 0, link, pipe 1, ... outlet.
var water_fill: Array[float] = [0,0,0,0,0,0,0,0,0,0,0]
var tank_fill := 0.0
var collection_age := 0.0
var suction_started := false
var steam_clock := 0.0
var ambushes := [false,false]
var passage_open := false
var batteries := [false,false]
var supplies := [false,false]
var records := [false,false,false]
var charge := 0.0
var defense_wave := 0
var purify_age := 0.0
var sample_taken := false
var checkpoint_age := 0.0
var checkpoint_name := ""
var pickup_notice_age := 0.0
var result_panel: Control
var tank_material: ShaderMaterial
var inlet_material: ShaderMaterial
var cleaner_materials: Array[ShaderMaterial] = []
var hint_target: Node2D
@onready var arena = get_parent()
@onready var hint: Label = $Inventory/Hint
@onready var controller_prompts = get_node("/root/GameInput")

func _ready() -> void:
	_build_result()
	inlet_material = _configure_tube($PumpDecor/Inlet,156)
	tank_material = _configure_tube($PumpDecor/Outlet,156)
	for i in 2:
		get_node("PumpDecor/StandTop%d" % i).hide()
		get_node("PumpDecor/StandFoot%d" % i).hide()
		var stand: Sprite2D = get_node("PumpDecor/StandLeg%d" % i)
		LAB.apply(stand,3,0,116)
		stand.position = Vector2(2680 if i == 0 else 3042,202)
		stand.show_behind_parent = true
		stand.z_index = -1
		cleaner_materials.append(_configure_tube(get_node("Sterilizer/Green/Tank%d" % i),142))
		cleaner_materials[i].set_shader_parameter("dip_pipe",true)
		get_node("Sterilizer/Green/Tank%d" % i).position = Vector2(5525+i*80,159)
		var clamp := Sprite2D.new()
		clamp.position = Vector2(5505+i*80,201)
		clamp.z_index = -1
		LAB.apply(clamp,3,0,104)
		$Sterilizer.add_child(clamp)
	$Sterilizer/Blue.hide()
	for child in $StorageDecor.get_children(): child.hide()
	for i in 3:
		var tube := Sprite2D.new()
		tube.name = "DecorTube%d" % i
		tube.position = Vector2(4650+i*75,164+i*2)
		var height := 80+i*7
		var material := _configure_tube(tube,height)
		tube.modulate = Color(0.68,0.81,0.9,0.85)
		material.set_shader_parameter("fill_level",[0.65,0.3,0.8][i])
		$StorageDecor.add_child(tube)
		var shadow := Polygon2D.new()
		shadow.position = tube.position+Vector2(0,height*0.5-2)
		shadow.polygon = PackedVector2Array([Vector2(-18,0),Vector2(-11,-3),Vector2(11,-3),Vector2(18,0),Vector2(11,3),Vector2(-11,3)])
		shadow.color = Color(0.12,0.23,0.31,0.16)
		shadow.z_index = -1
		$StorageDecor.add_child(shadow)
	for child in $Sterilizer.get_children():
		if child.name.begins_with("Foot") or child.name.begins_with("Leg") or child.name in ["Lamp","ConsoleStand","ConsoleFoot"]: child.hide()
	$PumpDecor/Socket0.hide()
	$PumpDecor/Socket1.hide()
	var sample_material := _configure_tube($Sample,30)
	sample_material.set_shader_parameter("fill_level",0.85)
	sample_material.set_shader_parameter("liquid_color",Color("28d9ff"))
	var steam := Node2D.new()
	steam.name = "SteamSprites"
	steam.z_index = -1
	add_child(steam)
	for i in 3:
		var puff := Sprite2D.new()
		puff.texture = LAB.control(i%4,0)
		puff.centered = false
		puff.offset = Vector2(-0.5,-0.95)*Vector2(LAB.CONTROLS.get_width()/4.0,LAB.CONTROLS.get_height()/2.0)
		puff.material = ShaderMaterial.new()
		puff.material.shader = STEAM_SHADER
		steam.add_child(puff)
	$Sterilizer.modulate = Color("c5d6df")
	$CleaningFans.modulate = Color("c5d6df")
	LAB.apply($Sterilizer/Console,0,3,70)
	$Sterilizer/Console.position = Vector2(5420,230)
	LAB.apply($CleaningFans/Case0,1,0,108)
	$CleaningFans/Case0.position = Vector2(5707,196)
	$CleaningFans/Case1.hide()
	$CleaningFans/Case2.hide()
	$CleaningFans/Fan0.position = Vector2(5688,191)
	$CleaningFans/Fan1.position = Vector2(5722,190)
	$CleaningFans/Fan2.position = Vector2(5708,218)
	$MachineProgress.position = Vector2(5492,54)
	_sync_visuals(0)

func cleaning_progress() -> float:
	# The defense fills the receiving tube continuously; final rinse completes the last 10%.
	return clampf(charge/(WAVE_CHARGE*3),0,1)*0.9+smoothstep(0,2.5,purify_age)*0.1

func _configure_tube(sprite: Sprite2D, height: float) -> ShaderMaterial:
	var texture := AtlasTexture.new()
	texture.atlas = TUBE_SHEET
	texture.region = Rect2(214,54,230,576)
	sprite.texture = texture
	sprite.scale = Vector2.ONE*height/576.0
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	sprite.material = material
	return material

func begin_power() -> void:
	if powered: return
	powered = true
	step = Step.POWER
	opening_age = 0

func _process(dt: float) -> void:
	if arena.controls_locked:
		hint.hide()
		return
	if not powered:
		_update_hint()
		return
	checkpoint_age = maxf(0,checkpoint_age-dt)
	pickup_notice_age = maxf(0,pickup_notice_age-dt)
	$PickupNotice.visible = pickup_notice_age > 0
	$PickupNotice.modulate.a = minf(1,pickup_notice_age*2)
	steam_clock += dt
	_update_water(dt)
	match step:
		Step.POWER:
			opening_age += dt
			$PowerGate.openness = smoothstep(0,1.3,opening_age)
			if opening_age >= 1.3:
				step = Step.PIPES
				_set_limit(3090)
				save_checkpoint("CANOS",Vector2(2660,286))
		Step.PIPES:
			if tank_fill >= 1:
				step = Step.DRAIN
				arena.start_camera_shake(1.4,0.15)
		Step.DRAIN:
			drain_age = minf(CLEAN_DURATION,drain_age+dt)
			$DrainGate.openness = smoothstep(CLEAN_DURATION-0.8,CLEAN_DURATION,drain_age)
			if drain_age >= CLEAN_DURATION:
				drained = true
				step = Step.STEAM
				_set_limit(4440)
				save_checkpoint("VAPOR",Vector2(3320,286))
		Step.STEAM:
			_update_ambushes()
			if _human_front() > 3400:
				arena.encounter.say("steam",["Luz acesa? Vem vapor! Esperem ou pulem."],step)
			if ambushes[1] and _enemies_clear():
				passage_open = true
				step = Step.EXPLORE
				_set_limit(6340)
				save_checkpoint("DEPÓSITO",Vector2(4580,291))
		Step.DEFENSE:
			charge = minf(defense_wave*WAVE_CHARGE,charge+dt)
			if charge >= defense_wave*WAVE_CHARGE and _enemies_clear():
				if defense_wave < 3:
					defense_wave += 1
					_spawn_defense_wave()
				else: step = Step.PURIFY
		Step.PURIFY:
			purify_age = minf(2.5,purify_age+dt)
			if purify_age >= 2.5:
				step = Step.SAMPLE
				save_checkpoint("FRASCO LIMPO",Vector2(5500,292))
	if drained and not complete: _update_steam()
	_collect_pickups()
	_sync_visuals(dt)
	_update_hint()

func pipe_ports(index: int) -> Array:
	var turn: int = 0 if PIPE_CONTROLS[index] < 0 else valves[PIPE_CONTROLS[index]]
	var result: Array = []
	for port in BASE_PORTS[index]: result.append((port+turn)%4)
	return result

func pipe_angle(index: int) -> float:
	return 0.0 if PIPE_CONTROLS[index] < 0 else valve_angles[PIPE_CONTROLS[index]]

func _pipe_settled(index: int) -> bool:
	return PIPE_CONTROLS[index] < 0 or absf(angle_difference(pipe_angle(index),valves[PIPE_CONTROLS[index]]*PI*0.5)) < 0.025

func flow_reached() -> Array[bool]:
	var reached: Array[bool] = [true,false,false,false,false]
	for i in 4: reached[i+1] = reached[i] and FLOW_EXITS[i] in pipe_ports(i) and FLOW_ENTRIES[i+1] in pipe_ports(i+1)
	return reached

func link_points(index: int) -> PackedVector2Array:
	if index == 0: return PackedVector2Array([Vector2(2716,140),Vector2(2745,140)])
	var previous: int = index-1
	var start: Vector2 = PIPE_POINTS[previous]+DIRECTIONS[FLOW_EXITS[previous]]*PIPE_RADIUS
	var end: Vector2 = Vector2(3046,140) if index == 5 else PIPE_POINTS[index]+DIRECTIONS[FLOW_ENTRIES[index]]*PIPE_RADIUS
	return PackedVector2Array([start,end])

func water_path(index: int) -> PackedVector2Array:
	var ports := pipe_ports(index)
	var entry: int = ports.find(FLOW_ENTRIES[index])
	if entry < 0: entry = 0
	var at: Vector2 = PIPE_POINTS[index]
	var angle := pipe_angle(index)
	return PackedVector2Array([at+DIRECTIONS[BASE_PORTS[index][entry]].rotated(angle)*PIPE_RADIUS,at,at+DIRECTIONS[BASE_PORTS[index][1-entry]].rotated(angle)*PIPE_RADIUS])

func _update_water(dt: float) -> void:
	# Collect the hazardous spill FIRST. The left tube remains full of clean water.
	if step == Step.PIPES and suction_started:
		collection_age = minf(COLLECTION_DURATION,collection_age+dt)
	var before := water_fill.duplicate()
	var connected := powered and collection_age >= COLLECTION_DURATION
	for section in water_fill.size():
		var length := 70.0
		if section%2 == 1:
			var index := int(section/2)
			connected = connected and _pipe_settled(index) and FLOW_ENTRIES[index] in pipe_ports(index)
		else:
			var link := int(section/2)
			var ends := link_points(link)
			length = maxf(1,ends[0].distance_to(ends[1]))
			if link > 0: connected = connected and _pipe_settled(link-1) and FLOW_EXITS[link-1] in pipe_ports(link-1)
		var fed: bool = connected and (section == 0 or before[section-1] >= 0.999)
		water_fill[section] = move_toward(water_fill[section],1 if fed else 0,dt*(WATER_SPEED/length if fed else 4.0))
	var arrived: bool = connected and water_fill[10] >= 0.999
	tank_fill = move_toward(tank_fill,1 if arrived else 0,dt*(0.8 if arrived else 2))

func turn_valve(index: int, player) -> bool:
	if index < 0 or index >= 3 or step != Step.PIPES or not _can_act(player,VALVE_POINTS[index],48): return false
	arena.get_node("/root/GameAudio").effect("lever", VALVE_POINTS[index])
	valves[index] = (valves[index]+1)%4
	return true

func vent_phase(index: int) -> float:
	return fposmod(steam_clock+index*1.35,5.2)

func vent_active(index: int) -> bool:
	var phase := vent_phase(index)
	return drained and phase >= 2.8 and phase < 3.8

func should_jump(player, direction: Vector2) -> bool:
	if not drained or direction.length_squared() < 0.01: return false
	for i in VENTS.size():
		if vent_active(i) and absf(player.position.x-VENTS[i]) < 52 and (VENTS[i]-player.position.x)*direction.x > 0: return true
	return false

func _update_steam() -> void:
	for player in arena.players:
		if player.down or player.jump_height >= 20: continue
		for i in VENTS.size():
			if vent_active(i) and absf(player.position.x-VENTS[i]) < 22: player.take_hit(7,Vector2(VENTS[i],player.position.y+20))

func _update_ambushes() -> void:
	for index in 2:
		if ambushes[index] or _human_front() < [3500,3910][index] or not _enemies_clear(): continue
		ambushes[index] = true
		for i in (3 if index == 1 else 2): _spawn_germ(Vector2([3650,4100][index]+i*57,248+(i%2)*62),index == 1 and i == 2)
		break

func ai_destination(player) -> Variant:
	if step == Step.EXIT: return $ExitElevator.ai_boarding_destination(player)
	return null

func _collect_pickups() -> void:
	for player in arena.players:
		if player.ai_controlled: continue
		for i in 2:
			if not batteries[i] and (drained if i == 0 else passage_open) and _can_act(player,BATTERY_POINTS[i],24):
				batteries[i] = true
				for actor in arena.players: actor.energy = minf(100,actor.energy+30)
				_pickup_feedback("+ Energia",BATTERY_POINTS[i])
		for i in 3:
			if records[i] or not _can_act(player,RECORD_POINTS[i],25): continue
			records[i] = true
			for actor in arena.players: actor.energy = minf(100,actor.energy+20)
			_pickup_feedback("+ Energia",RECORD_POINTS[i])
		if step == Step.SAMPLE and _can_act(player,SAMPLE_POINT,28):
			sample_taken = true
			arena.clean_sample = true
			arena.get_node("/root/GameAudio").effect("jar")
			step = Step.EXIT
			_set_limit(7180)
			save_checkpoint("DESCIDA AO LABORATÓRIO",Vector2(6460,290))
			arena.encounter.say("next_chapter",["Frasco guardado! Desçam pelo elevador e me encontrem lá embaixo!"],step)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or arena.controls_locked or not powered: return
	for player in arena.players:
		if not player.ai_controlled and controller_prompts.event_for(event, player.player_id, "interact") and try_action(player):
			get_viewport().set_input_as_handled()
			return

func try_action(player) -> bool:
	if arena.controls_locked or not powered: return false
	if step == Step.PIPES and not suction_started and _can_act(player,PUMP_POINT,34):
		suction_started = true
		return true
	for i in 3:
		if step == Step.PIPES and _can_act(player,VALVE_POINTS[i],48): return turn_valve(i,player)
	if step == Step.EXPLORE and _can_act(player,CONSOLE_POINT,50):
		save_checkpoint("MÁQUINA DE LIMPEZA",Vector2(5370,292))
		step = Step.DEFENSE
		defense_wave = 1
		charge = 0
		_spawn_defense_wave()
		arena.encounter.say("protect",["Lá vêm os germes! Protejam a máquina."],step)
		return true
	return false

func _pickup_feedback(words: String, at: Vector2) -> void:
	$PickupNotice.text = words
	$PickupNotice.position = at+Vector2(-65,-72)
	pickup_notice_age = 1.8
	$PickupNotice.modulate.a = 1
	$PickupNotice.show()

func _finish_chapter() -> void:
	complete = true
	step = Step.COMPLETE
	arena.victory = true
	arena.encounter.clear()
	arena.controls_locked = true
	result_panel.show()
	result_panel.get_node("Explore").grab_focus()

func _spawn_defense_wave() -> void:
	for i in (4 if defense_wave == 3 else 3):
		_spawn_germ(Vector2(5230+i*55 if i%2==0 else 5790+i*40,242+(i%2)*68),i == 2)

func _spawn_germ(at: Vector2, red: bool) -> void:
	var germ = arena.GermScene.instantiate()
	germ.position = at
	germ.variant = "red" if red else "green"
	germ.speed = 43
	arena.get_node("Actors").add_child(germ)

func _can_act(player, at: Vector2, radius: float) -> bool:
	return not arena.controls_locked and not player.ai_controlled and not player.down and player.jump_height <= 0 and player.stun <= 0 and player.dash <= 0 and not player.specials.active and player.position.distance_to(at) <= radius

func _human_front() -> float:
	var front := 0.0
	for player in arena.players:
		if not player.ai_controlled: front = maxf(front,player.position.x)
	return front

func _enemies_clear() -> bool:
	for germ in get_tree().get_nodes_in_group("germs"):
		if not germ.dead: return false
	return true

func _set_limit(value: float) -> void:
	arena.open_limit = value
	arena.camera_max_x = arena.world_limit-320

func target_x() -> float:
	match step:
		Step.POWER,Step.DRAIN: return 2880
		Step.PIPES: return PUMP_POINT.x if not suction_started else 2880
		Step.STEAM: return 4260
		Step.EXPLORE,Step.DEFENSE,Step.PURIFY: return CONSOLE_POINT.x
		Step.SAMPLE: return SAMPLE_POINT.x
		Step.EXIT: return EXIT_POINT.x
	return _human_front()

func wants_arrow() -> bool:
	return not complete and _enemies_clear() and absf(_human_front()-target_x()) > 220

func objective_text() -> String:
	match step:
		Step.POWER: return "LIGOU!"
		Step.PIPES: return "LIGUE OS\nCANOS"
		Step.DRAIN: return "ÁGUA\nPASSANDO!"
		Step.STEAM: return "SIGA EM\nFRENTE" if _enemies_clear() else "VENÇA OS\nGERMES"
		Step.EXPLORE: return "LIGUE A\nMÁQUINA"
		Step.DEFENSE: return "PROTEJA A\nMÁQUINA"
		Step.PURIFY: return "LIMPANDO\nO FRASCO"
		Step.SAMPLE: return "PEGUE O\nFRASCO"
		Step.EXIT: return "SUBAM NO\nELEVADOR"
		Step.COMPLETE: return "BOA,\nEQUIPE!"
	return ""

func _update_hint() -> void:
	hint.hide()
	hint_target = null
	$Inventory/Label.text = "Salvo" if checkpoint_age > 0 else ""
	$Inventory/Label.position.y = 120 if arena.players[1].ai_controlled else 174
	var nearest := INF
	for player in arena.players:
		var options: Array = []
		if not powered and is_instance_valid(arena.puzzle) and arena.puzzle.started:
			var puzzle = arena.puzzle
			if puzzle.constructed and not puzzle.activating and not puzzle.finished: options.append([puzzle.LEVER_POINT,48,"Puxar"])
			elif not puzzle.constructed and not puzzle.needs_salvage() and not puzzle.is_building(puzzle.builder):
				options.append([puzzle.BUILD_POINT,48,"Montar"])
		if step == Step.PIPES:
			for point in VALVE_POINTS: options.append([point,48,"Girar"])
			if not suction_started: options.append([PUMP_POINT,34,""])
		if step == Step.EXPLORE: options.append([CONSOLE_POINT,50,"Ligar"])
		for option in options:
			if not _can_act(player,option[0],option[1]): continue
			var distance: float = player.position.distance_to(option[0])
			if distance >= nearest: continue
			nearest = distance
			hint_target = player
			var key := "E" if player.player_id == 0 else "U"
			var caption: String = "Segure para montar" if option[2] == "Montar" else option[2]
			var keyboard := ("Segure %s para montar" % key if option[2] == "Montar" else "%s  %s" % [key, option[2]]).strip_edges()
			controller_prompts.label_hint(hint, player.player_id, "interact", keyboard, caption)
	if hint_target != null: hint.show()

func _sync_visuals(dt: float) -> void:
	if passage_open: $PassageGate.openness = move_toward($PassageGate.openness,1,dt*1.7)
	if sample_taken: $ExitGate.openness = move_toward($ExitGate.openness,1,dt*1.7)
	for i in 3:
		valve_angles[i] = lerp_angle(valve_angles[i],valves[i]*PI*0.5,minf(1,dt*12))
		LAB.gear(get_node("ValveWheels/Wheel%d" % i),valve_angles[i],42)
		get_node("Record%d" % i).visible = not records[i]
		LAB.gear(get_node("CleaningFans/Fan%d" % i),steam_clock*(2.0 if step >= Step.DEFENSE else 0.0)*(1 if i == 0 else -1)+i,[42,36,30][i])
	for i in 2:
		get_node("Battery%d" % i).visible = not batteries[i]
		var box = get_node("Supply%d" % i)
		if supplies[i] and not box.collected: box.restore_collected()
	LAB.gear($VentMachinery/Fan,steam_clock*1.8 if powered else 0.0,62)
	$Spill.modulate.a = 1.0-smoothstep(0,COLLECTION_DURATION,collection_age)
	$Spill.scale = Vector2(3.25,1.7)*lerpf(1,0.35,collection_age/COLLECTION_DURATION)
	var cleaned := smoothstep(0,CLEAN_DURATION,drain_age)
	var purified := cleaning_progress()
	for i in 2:
		cleaner_materials[i].set_shader_parameter("fill_level",lerpf(0.86,0.18,purified) if i == 0 else purified*(0.25 if sample_taken else 0.85))
		cleaner_materials[i].set_shader_parameter("liquid_color",Color("82e31d").lerp(Color("28d9ff"),purified) if i == 0 else Color("28d9ff"))
		cleaner_materials[i].set_shader_parameter("liquid_time",steam_clock)
	$Sterilizer/Console.texture = LAB.cell(int(steam_clock*6)%4 if step >= Step.DEFENSE else 0,3)
	$Sterilizer/Console.modulate = Color.WHITE if step >= Step.DEFENSE else Color("748a9a")
	for tube in $StorageDecor.get_children():
		if tube.visible and tube.material != null: tube.material.set_shader_parameter("liquid_time",steam_clock)
	$Sample.visible = step == Step.SAMPLE
	$Sample.material.set_shader_parameter("liquid_time",steam_clock)
	_sync_steam_sprites()
	if tank_material != null:
		tank_material.set_shader_parameter("fill_level",0.65*collection_age/COLLECTION_DURATION+0.2*cleaned)
		tank_material.set_shader_parameter("liquid_color",Color("82e31d").lerp(Color("28d9ff"),cleaned))
		tank_material.set_shader_parameter("liquid_time",steam_clock)
		inlet_material.set_shader_parameter("fill_level",lerpf(0.95,0.25,cleaned))
		inlet_material.set_shader_parameter("liquid_time",steam_clock)
	$Art.queue_redraw()
	$MachineProgress.queue_redraw()

func _sync_steam_sprites() -> void:
	# One anchored, frame-animated jet per outlet.
	for vent in 3:
		var phase := vent_phase(vent)
		var strength := clampf(minf((phase-2.8)/0.08,(3.8-phase)/0.08),0,1)
		var puff: Sprite2D = $SteamSprites.get_child(vent)
		puff.visible = vent_active(vent)
		var frame := posmod(int(steam_clock*8),4)
		puff.texture = LAB.control(frame,0)
		puff.material.set_shader_parameter("frame_index",float(frame))
		puff.position = Vector2(VENTS[vent],316)
		puff.scale = Vector2(74,148)/Vector2(LAB.CONTROLS.get_width()/4.0,LAB.CONTROLS.get_height()/2.0)
		puff.modulate.a = strength

func save_checkpoint(label: String, at: Vector2) -> void:
	var party: Array = []
	for player in arena.players:
		party.append({"weapon":player.equipped_weapon,"hp":maxi(40,player.hp),"max_hp":player.max_hp,"energy":player.energy,"healing_flasks":maxi(1,player.healing_flasks),"flask_heal_amount":player.flask_heal_amount,"ai_controlled":player.ai_controlled,"pieces":arena.pieces})
	get_tree().set_meta(CHECKPOINT_META,{"name":label,"at":at,"party":party,"step":step,"drained":drained,"passage":passage_open,"batteries":batteries.duplicate(),"supplies":supplies.duplicate(),"records":records.duplicate(),"sample":sample_taken,"ambushes":ambushes.duplicate(),"seen":arena.encounter.seen.duplicate()})
	checkpoint_name = label
	checkpoint_age = 3

func restore_checkpoint(data: Dictionary) -> void:
	powered = true
	step = data["step"]
	if step == 5: step = Step.STEAM # Old pressure-plate objective.
	if step == 7: step = Step.EXPLORE # Old filter calibration.
	drained = data["drained"]
	passage_open = data.get("passage",data.get("plates",false))
	batteries.assign(data.get("batteries",data.get("fuses",[false,false])))
	supplies.assign(data["supplies"])
	ambushes.assign(data["ambushes"])
	sample_taken = data["sample"]
	arena.clean_sample = sample_taken
	records.assign(data.get("records",[false,false,false]))
	arena.encounter.seen = data["seen"].duplicate()
	opening_age = 2
	drain_age = CLEAN_DURATION if drained else 0
	collection_age = COLLECTION_DURATION if drained else 0
	suction_started = drained
	valves = [0,0,0] if drained else [1,1,3]
	water_fill.fill(1.0 if drained else 0.0)
	tank_fill = 1 if drained else 0
	purify_age = 2.5 if step >= Step.SAMPLE else 0
	$PowerGate.openness = 1
	$DrainGate.openness = 1 if drained else 0
	$PassageGate.openness = 1 if passage_open else 0
	$ExitGate.openness = 1 if sample_taken else 0
	if step >= Step.SAMPLE: charge = WAVE_CHARGE*3
	_set_limit(7180 if sample_taken else (6340 if passage_open else (4440 if drained else 3090)))
	for i in 2: arena.players[i].position = data["at"]+Vector2(-20+i*40,i*10)
	checkpoint_name = data["name"]
	checkpoint_age = 3
	_sync_visuals(1)

func _build_result() -> void:
	var skin = preload("res://scripts/menu_button.gd")
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	result_panel = Panel.new()
	result_panel.position = Vector2(90,78)
	result_panel.size = Vector2(460,220)
	result_panel.add_theme_stylebox_override("panel", skin.panel())
	layer.add_child(result_panel)
	var label := Label.new()
	label.position = Vector2(24,22)
	label.text = "BOA, EQUIPE!\n\nO frasco está limpo.\nTibúrcio espera lá embaixo!\n\nSigam para o elevador."
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_constant_override("line_spacing",7)
	result_panel.add_child(label)
	var explore := Button.new()
	explore.name = "Explore"
	explore.text = "EXPLORAR MAIS"
	explore.position = Vector2(24,170)
	explore.pressed.connect(func(): result_panel.hide(); arena.controls_locked = false)
	result_panel.add_child(explore)
	var replay := Button.new()
	replay.text = "JOGAR DE NOVO"
	replay.position = Vector2(260,170)
	replay.pressed.connect(_replay)
	result_panel.add_child(replay)
	for button in [explore,replay]:
		skin.apply(button)
		button.add_theme_font_override("font",FONT)
		button.add_theme_font_size_override("font_size",8)
		button.custom_minimum_size = Vector2(185,30)
	result_panel.hide()

func _replay() -> void:
	for key in [CHECKPOINT_META,RETRY_META]:
		if get_tree().has_meta(key): get_tree().remove_meta(key)
	get_tree().reload_current_scene()

